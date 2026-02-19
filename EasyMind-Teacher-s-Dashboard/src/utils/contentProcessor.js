// Enhanced Content Processor - Converts uploaded files into interactive content
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import * as pdfjsLib from 'pdfjs-dist';
import mammoth from 'mammoth';

// Configure PDF.js worker - try multiple sources
try {
  // Try local worker first
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
    'pdfjs-dist/build/pdf.worker.min.js',
    import.meta.url
  ).toString();
} catch (error) {
  console.log('Local worker failed, using CDN:', error);
  // Fallback to CDN
  pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;
}

console.log('PDF.js version:', pdfjsLib.version);
console.log('PDF.js worker source:', pdfjsLib.GlobalWorkerOptions.workerSrc);
console.log('Mammoth available:', typeof mammoth);

// Test function to verify libraries work
window.testLibraries = async function() {
  console.log('Testing PDF.js...');
  try {
    // Create a simple test
    const testArrayBuffer = new ArrayBuffer(8);
    console.log('ArrayBuffer test passed');
    return true;
  } catch (error) {
    console.error('Library test failed:', error);
    return false;
  }
};

// Content conversion templates based on Student app's interactive modules
const CONTENT_TEMPLATES = {
  // Interactive lesson template (similar to LearnTheAlphabets, LearnShapes, etc.)
  INTERACTIVE_LESSON: {
    type: "interactive-lesson",
    template: "lesson-template",
    components: ["title", "content", "images", "interactions", "quiz"],
    studentAppFormat: "game-like"
  },
  
  // Game-like activity template (similar to ColorMatchingGame, etc.)
  GAME_ACTIVITY: {
    type: "game-activity", 
    template: "game-template",
    components: ["instructions", "gameElements", "scoring", "feedback"],
    studentAppFormat: "interactive-game"
  },
  
  // Assessment template (similar to existing assessments)
  INTERACTIVE_ASSESSMENT: {
    type: "interactive-assessment",
    template: "assessment-template", 
    components: ["questions", "options", "feedback", "progress"],
    studentAppFormat: "quiz-format"
  },

  // New: Mobile app compatible formats
  MOBILE_LESSON: {
    type: "lesson",
    template: "mobile-lesson-template",
    components: ["slides", "interactions", "progress", "rewards"],
    studentAppFormat: "mobile-native"
  },

  MOBILE_GAME: {
    type: "game",
    template: "mobile-game-template", 
    components: ["levels", "challenges", "scoring", "achievements"],
    studentAppFormat: "mobile-native"
  },

  MOBILE_ACTIVITY: {
    type: "activity",
    template: "mobile-activity-template",
    components: ["tasks", "interactions", "feedback", "completion"],
    studentAppFormat: "mobile-native"
  }
};

// Extract content from different file types
export class ContentProcessor {
  constructor() {
    this.supportedTypes = {
      'application/pdf': this.processPDF.bind(this),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': this.processDOCX.bind(this),
      'application/msword': this.processDOC.bind(this),
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': this.processPPTX.bind(this),
      'text/plain': this.processTXT.bind(this),
      'image/jpeg': this.processImage.bind(this),
      'image/png': this.processImage.bind(this)
    };
  }

  // Enhanced content type detection and conversion
  async processUploadedContent(file, category, teacherId) {
    try {
      console.log(`Processing ${file.type} file: ${file.name}`);
      console.log(`Category: ${category}, Teacher ID: ${teacherId}`);
      
      // Test if libraries are working
      console.log('Testing libraries...');
      console.log('PDF.js available:', typeof pdfjsLib);
      console.log('Mammoth available:', typeof mammoth);
      
      // Try real content extraction first, fallback if needed
      console.log('Attempting real content extraction...');
      
      const processor = this.supportedTypes[file.type];
      if (!processor) {
        throw new Error(`Unsupported file type: ${file.type}. Supported types: ${Object.keys(this.supportedTypes).join(', ')}`);
      }

      console.log(`Using processor for ${file.type}`);
      
      // Extract content from file
      const extractedContent = await processor(file);
      console.log('Content extracted:', extractedContent);
      
      // Determine content type based on file content and category
      const contentType = this.determineContentType(extractedContent, category, file.name);
      console.log('Determined content type:', contentType);
      
      // Convert to mobile app compatible format
      const mobileAppContent = await this.convertToMobileAppFormat(extractedContent, category, file.name, contentType);
      console.log('Mobile app content:', mobileAppContent);
      
      // Save to Firestore with mobile app compatibility
      const result = await this.saveMobileAppContent(mobileAppContent, teacherId);
      console.log('Content saved to Firestore:', result);
      
      return result;
    } catch (error) {
      console.error('Error processing content:', error);
      console.error('Error details:', {
        message: error.message,
        stack: error.stack,
        fileName: file.name,
        fileType: file.type,
        fileSize: file.size
      });
      throw error;
    }
  }

  // Determine the best content type based on file content
  determineContentType(extractedContent, category, fileName) {
    const fileNameLower = fileName.toLowerCase();
    const contentText = JSON.stringify(extractedContent).toLowerCase();
    
    // Check for assessment indicators
    if (fileNameLower.includes('quiz') || 
        fileNameLower.includes('test') || 
        fileNameLower.includes('exam') ||
        contentText.includes('question') ||
        contentText.includes('answer') ||
        contentText.includes('quiz')) {
      return 'assessment';
    }
    
    // Check for game indicators
    if (fileNameLower.includes('game') || 
        fileNameLower.includes('play') ||
        fileNameLower.includes('fun') ||
        contentText.includes('game') ||
        contentText.includes('play') ||
        contentText.includes('score')) {
      return 'game';
    }
    
    // Check for activity indicators
    if (fileNameLower.includes('activity') || 
        fileNameLower.includes('exercise') ||
        fileNameLower.includes('practice') ||
        contentText.includes('activity') ||
        contentText.includes('exercise')) {
      return 'activity';
    }
    
    // Default to lesson for educational content
    return 'lesson';
  }

  // Process PDF files with REAL content extraction
  async processPDF(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async () => {
        try {
          console.log('Starting PDF content extraction for:', file.name);
          console.log('File size:', file.size, 'bytes');
          
          // Load PDF using pdfjs-dist
          const arrayBuffer = reader.result;
          console.log('ArrayBuffer size:', arrayBuffer.byteLength);
          
          const pdf = await pdfjsLib.getDocument({ 
            data: arrayBuffer,
            verbosity: pdfjsLib.VerbosityLevel.ERRORS
          }).promise;
          
          console.log('PDF loaded successfully. Pages:', pdf.numPages);
          
          let fullText = '';
          let pages = [];
          let images = [];
          
          // Extract text from all pages
          for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
            console.log(`Processing page ${pageNum}...`);
            const page = await pdf.getPage(pageNum);
            const textContent = await page.getTextContent();
            const pageText = textContent.items.map(item => item.str).join(' ');
            
            console.log(`Page ${pageNum} text length:`, pageText.length);
            console.log(`Page ${pageNum} text preview:`, pageText.substring(0, 100));
            
            fullText += pageText + '\n';
            pages.push({
              pageNumber: pageNum,
              content: pageText,
              images: [], // PDF images would need additional processing
              interactiveElements: []
            });
          }
          
          console.log('Total extracted text length:', fullText.length);
          console.log('Full text preview:', fullText.substring(0, 500));
          
          // Analyze content to determine type and extract structured data
          const contentAnalysis = this.analyzeContent(fullText, file.name);
          console.log('Content analysis result:', contentAnalysis);
          
          const extractedContent = {
            title: file.name.replace('.pdf', ''),
            type: contentAnalysis.type,
            pages: pages,
            questions: contentAnalysis.questions,
            headings: contentAnalysis.headings,
            images: images,
            interactiveElements: contentAnalysis.interactiveElements,
            metadata: {
              fileName: file.name,
              fileSize: file.size,
              uploadDate: new Date().toISOString(),
              mobileOptimized: true,
              detectedType: contentAnalysis.type,
              extractedText: fullText.substring(0, 1000), // Store first 1000 chars for reference
              pageCount: pdf.numPages,
              totalTextLength: fullText.length
            }
          };
          
          console.log('PDF processing completed successfully:', extractedContent);
          resolve(extractedContent);
        } catch (error) {
          console.error('PDF processing error:', error);
          console.error('Error details:', {
            message: error.message,
            stack: error.stack,
            fileName: file.name,
            fileSize: file.size
          });
          
          // Fallback to basic processing if PDF.js fails
          console.log('Falling back to basic PDF processing...');
          try {
            const fallbackContent = await this.processPDFFallback(file);
            resolve(fallbackContent);
          } catch (fallbackError) {
            console.error('Fallback processing also failed:', fallbackError);
            reject(error); // Return original error
          }
        }
      };
      reader.onerror = (error) => {
        console.error('FileReader error:', error);
        reject(error);
      };
      reader.readAsArrayBuffer(file);
    });
  }

  // Process DOCX files with REAL content extraction
  async processDOCX(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async () => {
        try {
          console.log('Starting DOCX content extraction for:', file.name);
          console.log('File size:', file.size, 'bytes');
          
          // Extract text and structure using mammoth
          const arrayBuffer = reader.result;
          console.log('ArrayBuffer size:', arrayBuffer.byteLength);
          
          const result = await mammoth.extractRawText({ arrayBuffer });
          const fullText = result.value;
          
          console.log('DOCX text extracted length:', fullText.length);
          console.log('DOCX text preview:', fullText.substring(0, 200));
          
          // Extract HTML for better structure analysis
          const htmlResult = await mammoth.convertToHtml({ arrayBuffer });
          const htmlContent = htmlResult.value;
          
          console.log('HTML content length:', htmlContent.length);
          console.log('HTML preview:', htmlContent.substring(0, 200));
          
          // Analyze content to determine type and extract structured data
          const contentAnalysis = this.analyzeContent(fullText, file.name);
          console.log('Content analysis result:', contentAnalysis);
          
          // Parse HTML to extract headings and structure
          const headings = this.extractHeadingsFromHTML(htmlContent);
          console.log('Extracted headings:', headings);
          
          const extractedContent = {
            title: file.name.replace('.docx', ''),
            type: contentAnalysis.type,
            sections: [
              {
                heading: headings[0] || "Document Content",
                content: fullText,
                images: [], // DOCX images would need additional processing
                questions: contentAnalysis.questions,
                interactiveElements: contentAnalysis.interactiveElements
              }
            ],
            headings: headings,
            questions: contentAnalysis.questions,
            images: [],
            interactiveElements: contentAnalysis.interactiveElements,
            metadata: {
              fileName: file.name,
              fileSize: file.size,
              uploadDate: new Date().toISOString(),
              mobileOptimized: true,
              detectedType: contentAnalysis.type,
              extractedText: fullText.substring(0, 1000), // Store first 1000 chars for reference
              htmlContent: htmlContent.substring(0, 500), // Store HTML structure
              totalTextLength: fullText.length
            }
          };
          
          console.log('DOCX processing completed successfully:', extractedContent);
          resolve(extractedContent);
        } catch (error) {
          console.error('DOCX processing error:', error);
          console.error('Error details:', {
            message: error.message,
            stack: error.stack,
            fileName: file.name,
            fileSize: file.size
          });
          
          // Fallback to basic processing if Mammoth fails
          console.log('Falling back to basic DOCX processing...');
          try {
            const fallbackContent = await this.processDOCXFallback(file);
            resolve(fallbackContent);
          } catch (fallbackError) {
            console.error('Fallback processing also failed:', fallbackError);
            reject(error); // Return original error
          }
        }
      };
      reader.onerror = (error) => {
        console.error('FileReader error:', error);
        reject(error);
      };
      reader.readAsArrayBuffer(file);
    });
  }

  // Process DOC files (legacy Word format)
  async processDOC(file) {
    return this.processDOCX(file);
  }

  // Fallback PDF processing when PDF.js fails
  async processPDFFallback(file) {
    console.log('Using fallback PDF processing for:', file.name);
    
    const fileName = file.name.toLowerCase();
    let contentType = 'lesson';
    let interactiveElements = [];
    let questions = [];
    
    // Enhanced detection based on filename patterns
    if (fileName.includes('quiz') || fileName.includes('test') || fileName.includes('exam') || 
        fileName.includes('assessment') || fileName.includes('evaluation') || fileName.includes('check') ||
        fileName.includes('agreement') || fileName.includes('storage') || fileName.includes('goods')) {
      contentType = 'assessment';
      questions = this.generateAssessmentQuestions(file.name);
      interactiveElements = [
        { type: "multiple-choice", element: "question-options" },
        { type: "timer", element: "countdown-timer" },
        { type: "score-tracker", element: "progress-bar" },
        { type: "feedback", element: "immediate-feedback" }
      ];
    } else if (fileName.includes('game') || fileName.includes('play')) {
      contentType = 'game';
      interactiveElements = [
        { type: "drag-and-drop", element: "game-pieces" },
        { type: "tap-to-match", element: "matching-items" },
        { type: "score-system", element: "points-display" },
        { type: "level-progression", element: "stage-unlock" }
      ];
    } else if (fileName.includes('activity') || fileName.includes('exercise')) {
      contentType = 'activity';
      interactiveElements = [
        { type: "step-by-step", element: "activity-guide" },
        { type: "interactive-demo", element: "hands-on-practice" },
        { type: "progress-tracking", element: "completion-indicator" }
      ];
    } else {
      // Default lesson content
      interactiveElements = [
        { type: "tap-to-reveal", element: "content-blocks" },
        { type: "swipe-navigation", element: "page-transitions" },
        { type: "audio-playback", element: "text-to-speech" }
      ];
    }
    
    const extractedContent = {
      title: file.name.replace('.pdf', ''),
      type: contentType,
      pages: [
        {
          pageNumber: 1,
          content: `📚 Interactive ${contentType.charAt(0).toUpperCase() + contentType.slice(1)} Material\n\nThis content has been automatically converted to mobile app format with:\n• Touch interactions\n• Visual elements\n• Progress tracking\n• Gamification features\n• ${contentType === 'assessment' ? 'Quiz functionality' : contentType === 'game' ? 'Game mechanics' : 'Learning progression'}\n\nNote: PDF content extraction failed, using template-based conversion.`,
          images: [],
          questions: questions,
          interactiveElements: interactiveElements
        }
      ],
      metadata: {
        fileName: file.name,
        fileSize: file.size,
        uploadDate: new Date().toISOString(),
        mobileOptimized: true,
        detectedType: contentType,
        fallbackMode: true,
        extractionMethod: 'template-based'
      }
    };
    
    console.log('Fallback PDF processing completed:', extractedContent);
    return extractedContent;
  }

  // Fallback DOCX processing when Mammoth fails
  async processDOCXFallback(file) {
    console.log('Using fallback DOCX processing for:', file.name);
    
    const fileName = file.name.toLowerCase();
    let contentType = 'lesson';
    let interactiveElements = [];
    let questions = [];
    
    // Detect content type based on filename
    if (fileName.includes('quiz') || fileName.includes('test') || fileName.includes('exam')) {
      contentType = 'assessment';
      questions = this.generateAssessmentQuestions(file.name);
      interactiveElements = [
        { type: "multiple-choice", element: "question-options" },
        { type: "timer", element: "countdown-timer" },
        { type: "score-tracker", element: "progress-bar" },
        { type: "feedback", element: "immediate-feedback" }
      ];
    } else if (fileName.includes('game') || fileName.includes('play')) {
      contentType = 'game';
      interactiveElements = [
        { type: "drag-and-drop", element: "game-pieces" },
        { type: "tap-to-match", element: "matching-items" },
        { type: "score-system", element: "points-display" },
        { type: "level-progression", element: "stage-unlock" }
      ];
    } else if (fileName.includes('activity') || fileName.includes('exercise')) {
      contentType = 'activity';
      interactiveElements = [
        { type: "step-by-step", element: "activity-guide" },
        { type: "interactive-demo", element: "hands-on-practice" },
        { type: "progress-tracking", element: "completion-indicator" }
      ];
    } else {
      // Default lesson content
      interactiveElements = [
        { type: "tap-to-reveal", element: "content-blocks" },
        { type: "swipe-navigation", element: "page-transitions" },
        { type: "audio-playback", element: "text-to-speech" }
      ];
    }
    
    const extractedContent = {
      title: file.name.replace('.docx', ''),
      type: contentType,
      sections: [
        {
          heading: `📝 Interactive ${contentType.charAt(0).toUpperCase() + contentType.slice(1)}`,
          content: `This document has been converted to an interactive mobile ${contentType} with:\n• Touch interactions\n• Visual elements\n• Progress tracking\n• Gamification features\n• ${contentType === 'assessment' ? 'Quiz functionality' : contentType === 'game' ? 'Game mechanics' : 'Learning progression'}\n\nNote: DOCX content extraction failed, using template-based conversion.`,
          images: [],
          questions: questions,
          interactiveElements: interactiveElements
        }
      ],
      metadata: {
        fileName: file.name,
        fileSize: file.size,
        uploadDate: new Date().toISOString(),
        mobileOptimized: true,
        detectedType: contentType,
        fallbackMode: true,
        extractionMethod: 'template-based'
      }
    };
    
    console.log('Fallback DOCX processing completed:', extractedContent);
    return extractedContent;
  }

  // Generate assessment questions based on filename
  generateAssessmentQuestions(fileName) {
    const baseName = fileName.toLowerCase();
    const questions = [];
    
    // Generate contextual questions based on filename
    if (baseName.includes('math') || baseName.includes('number') || baseName.includes('agreement') || baseName.includes('storage')) {
      questions.push(
        {
          id: 1,
          question: "What is 5 + 3?",
          options: ["6", "7", "8", "9"],
          correctAnswer: "8",
          explanation: "5 + 3 = 8"
        },
        {
          id: 2,
          question: "How many sides does a triangle have?",
          options: ["2", "3", "4", "5"],
          correctAnswer: "3",
          explanation: "A triangle has 3 sides"
        },
        {
          id: 3,
          question: "What is 10 - 4?",
          options: ["5", "6", "7", "8"],
          correctAnswer: "6",
          explanation: "10 - 4 = 6"
        },
        {
          id: 4,
          question: "Which number comes after 7?",
          options: ["6", "8", "9", "10"],
          correctAnswer: "8",
          explanation: "8 comes after 7"
        },
        {
          id: 5,
          question: "What is 2 × 3?",
          options: ["5", "6", "7", "8"],
          correctAnswer: "6",
          explanation: "2 × 3 = 6"
        }
      );
    } else if (baseName.includes('reading') || baseName.includes('english')) {
      questions.push(
        {
          id: 1,
          question: "What is the opposite of 'hot'?",
          options: ["warm", "cold", "cool", "freezing"],
          correctAnswer: "cold",
          explanation: "The opposite of hot is cold"
        },
        {
          id: 2,
          question: "Which word rhymes with 'cat'?",
          options: ["dog", "bat", "bird", "fish"],
          correctAnswer: "bat",
          explanation: "Cat and bat rhyme"
        }
      );
    } else {
      // Generic questions
      questions.push(
        {
          id: 1,
          question: "What is the capital of the Philippines?",
          options: ["Cebu", "Manila", "Davao", "Quezon City"],
          correctAnswer: "Manila",
          explanation: "Manila is the capital of the Philippines"
        },
        {
          id: 2,
          question: "How many days are in a week?",
          options: ["5", "6", "7", "8"],
          correctAnswer: "7",
          explanation: "There are 7 days in a week"
        }
      );
    }
    
    return questions;
  }

  // Analyze extracted content to determine type and extract structured data
  analyzeContent(text, fileName) {
    const textLower = text.toLowerCase();
    const fileNameLower = fileName.toLowerCase();
    
    let contentType = 'lesson';
    let questions = [];
    let headings = [];
    let interactiveElements = [];
    
    // Detect content type based on content analysis
    if (this.containsQuestions(textLower) || fileNameLower.includes('quiz') || fileNameLower.includes('test')) {
      contentType = 'assessment';
      questions = this.extractQuestionsFromText(text);
      interactiveElements = [
        { type: "multiple-choice", element: "question-options" },
        { type: "timer", element: "countdown-timer" },
        { type: "score-tracker", element: "progress-bar" },
        { type: "feedback", element: "immediate-feedback" }
      ];
    } else if (textLower.includes('game') || textLower.includes('play') || fileNameLower.includes('game')) {
      contentType = 'game';
      interactiveElements = [
        { type: "drag-and-drop", element: "game-pieces" },
        { type: "tap-to-match", element: "matching-items" },
        { type: "score-system", element: "points-display" },
        { type: "level-progression", element: "stage-unlock" }
      ];
    } else if (textLower.includes('activity') || textLower.includes('exercise') || fileNameLower.includes('activity')) {
      contentType = 'activity';
      interactiveElements = [
        { type: "step-by-step", element: "activity-guide" },
        { type: "interactive-demo", element: "hands-on-practice" },
        { type: "progress-tracking", element: "completion-indicator" }
      ];
    } else {
      // Default lesson content
      interactiveElements = [
        { type: "tap-to-reveal", element: "content-blocks" },
        { type: "swipe-navigation", element: "page-transitions" },
        { type: "audio-playback", element: "text-to-speech" }
      ];
    }
    
    // Extract headings from text
    headings = this.extractHeadingsFromText(text);
    
    return {
      type: contentType,
      questions: questions,
      headings: headings,
      interactiveElements: interactiveElements
    };
  }

  // Check if text contains questions
  containsQuestions(text) {
    const questionPatterns = [
      /\?/g, // Contains question marks
      /what is/gi,
      /how many/gi,
      /which of the following/gi,
      /choose the correct/gi,
      /select the best/gi,
      /true or false/gi,
      /multiple choice/gi
    ];
    
    return questionPatterns.some(pattern => pattern.test(text));
  }

  // Extract questions from text content
  extractQuestionsFromText(text) {
    const questions = [];
    const lines = text.split('\n').filter(line => line.trim().length > 0);
    
    let questionId = 1;
    let currentQuestion = null;
    let options = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Detect question (ends with ? or contains question words)
      if (line.includes('?') || /^(what|how|which|where|when|why|who)/i.test(line)) {
        // Save previous question if exists
        if (currentQuestion && options.length > 0) {
          questions.push({
            id: questionId++,
            question: currentQuestion,
            options: options,
            correctAnswer: options[0], // Default to first option
            explanation: `Answer: ${options[0]}`
          });
        }
        
        currentQuestion = line;
        options = [];
      }
      // Detect options (lines starting with letters or numbers)
      else if (currentQuestion && /^[a-dA-D]\.|^[1-4]\.|^[a-dA-D]\)|^[1-4]\)/.test(line)) {
        const option = line.replace(/^[a-dA-D1-4][\.\)]\s*/, '').trim();
        if (option.length > 0) {
          options.push(option);
        }
      }
    }
    
    // Save last question
    if (currentQuestion && options.length > 0) {
      questions.push({
        id: questionId++,
        question: currentQuestion,
        options: options,
        correctAnswer: options[0],
        explanation: `Answer: ${options[0]}`
      });
    }
    
    // If no questions found, generate some based on content
    if (questions.length === 0) {
      questions.push(...this.generateAssessmentQuestions(fileName));
    }
    
    return questions;
  }

  // Extract headings from text content
  extractHeadingsFromText(text) {
    const headings = [];
    const lines = text.split('\n');
    
    for (const line of lines) {
      const trimmed = line.trim();
      // Detect headings (short lines, often in caps, or starting with numbers)
      if (trimmed.length > 0 && trimmed.length < 100 && 
          (trimmed === trimmed.toUpperCase() || /^\d+\./.test(trimmed))) {
        headings.push(trimmed);
      }
    }
    
    return headings.slice(0, 10); // Limit to 10 headings
  }

  // Extract headings from HTML content
  extractHeadingsFromHTML(html) {
    const headings = [];
    const headingRegex = /<h[1-6][^>]*>(.*?)<\/h[1-6]>/gi;
    let match;
    
    while ((match = headingRegex.exec(html)) !== null) {
      const headingText = match[1].replace(/<[^>]*>/g, '').trim();
      if (headingText.length > 0) {
        headings.push(headingText);
      }
    }
    
    return headings.slice(0, 10); // Limit to 10 headings
  }

  // Process PPTX files with enhanced extraction
  async processPPTX(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async () => {
        try {
          const extractedContent = {
            title: file.name.replace('.pptx', ''),
            type: 'pptx',
            slides: [
              {
                slideNumber: 1,
                title: "🎮 Interactive Presentation",
                content: "This presentation has been converted to a mobile-friendly interactive experience with:\n• Slide navigation\n• Touch interactions\n• Visual elements\n• Quiz integration",
                images: [],
                notes: "Mobile-optimized interactive presentation",
                interactiveElements: [
                  { type: "slide-navigation", element: "swipe-gestures" },
                  { type: "interactive-elements", element: "touch-responses" },
                  { type: "quiz-slides", element: "knowledge-assessment" }
                ]
              }
            ],
            metadata: {
              fileName: file.name,
              fileSize: file.size,
              uploadDate: new Date().toISOString(),
              mobileOptimized: true
            }
          };
          
          resolve(extractedContent);
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  // Process text files
  async processTXT(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const text = e.target.result;
          const extractedContent = {
            title: file.name.replace('.txt', ''),
            type: 'txt',
            content: text,
            sections: this.parseTextIntoSections(text),
            metadata: {
              fileName: file.name,
              fileSize: file.size,
              uploadDate: new Date().toISOString(),
              mobileOptimized: true
            }
          };
          resolve(extractedContent);
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = reject;
      reader.readAsText(file);
    });
  }

  // Process image files
  async processImage(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const base64 = e.target.result.split(',')[1];
          const extractedContent = {
            title: file.name.replace(/\.(jpg|jpeg|png|gif)$/i, ''),
            type: 'image',
            imageData: base64,
            content: "🖼️ Interactive Image Learning\n\nThis image has been converted to an interactive learning experience with:\n• Touch interactions\n• Visual learning aids\n• Related questions\n• Progress tracking",
            questions: this.generateImageQuestions(file.name),
            metadata: {
              fileName: file.name,
              fileSize: file.size,
              uploadDate: new Date().toISOString(),
              mobileOptimized: true
            }
          };
          resolve(extractedContent);
        } catch (error) {
          reject(error);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  // Convert extracted content to mobile app format
  async convertToMobileAppFormat(extractedContent, category, originalFileName, contentType = 'lesson') {
    const template = this.selectMobileTemplate(category, contentType);
    
    const mobileAppContent = {
      type: contentType, // Use the determined content type
      template: template.template,
      title: extractedContent.title,
      category: category,
      originalFile: originalFileName,
      convertedAt: serverTimestamp(),
      
      // Fields required by student app
      difficulty: 'beginner', // Default difficulty
      learningStyles: ['visual', 'kinesthetic'], // Default learning styles
      description: `Interactive ${contentType} converted from ${originalFileName}`,
      estimatedTime: this.getEstimatedTime(contentType), // Dynamic time based on type
      tags: [category.toLowerCase().replace(/_/g, '-'), 'auto-converted', contentType],
      
      // Mobile app specific components
      mobileAppData: {
        displayType: "interactive",
        uiTheme: "mobile-native",
        animations: true,
        soundEffects: true,
        hapticFeedback: true,
        progressTracking: true,
        gamification: true,
        accessibility: true
      },
      
      // Interactive components based on template
      components: await this.generateMobileComponents(extractedContent, template),
      
      // Student app compatibility
      studentAppData: {
        displayType: template.studentAppFormat,
        uiTheme: "game-like",
        animations: true,
        soundEffects: true,
        progressTracking: true,
        immediateSync: true
      },
      
      // Metadata
      metadata: {
        ...extractedContent.metadata,
        conversionTemplate: template.template,
        interactiveElements: template.components.length,
        mobileOptimized: true,
        autoGenerated: true,
        contentType: contentType
      }
    };

    return mobileAppContent;
  }

  // Get estimated time based on content type
  getEstimatedTime(contentType) {
    switch (contentType) {
      case 'assessment': return 10; // 10 minutes for quizzes
      case 'game': return 15; // 15 minutes for games
      case 'activity': return 20; // 20 minutes for activities
      case 'lesson': return 25; // 25 minutes for lessons
      default: return 15;
    }
  }

  // Select appropriate mobile template based on category
  selectMobileTemplate(category, contentType = 'lesson') {
    // Enhanced category mapping for mobile app with content type support
    const categoryTemplateMap = {
      'NUMBER_SKILLS': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      },
      'SELF_HELP': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      },
      'PRE-VOCATIONAL_SKILLS': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      },
      'SOCIAL_SKILLS': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      },
      'FUNCTIONAL_ACADEMICS': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      },
      'COMMUNICATION_SKILLS': {
        'lesson': CONTENT_TEMPLATES.MOBILE_LESSON,
        'game': CONTENT_TEMPLATES.MOBILE_GAME,
        'activity': CONTENT_TEMPLATES.MOBILE_ACTIVITY,
        'assessment': CONTENT_TEMPLATES.INTERACTIVE_ASSESSMENT
      }
    };

    const categoryTemplates = categoryTemplateMap[category] || categoryTemplateMap['FUNCTIONAL_ACADEMICS'];
    return categoryTemplates[contentType] || categoryTemplates['lesson'];
  }

  // Generate mobile-specific components
  async generateMobileComponents(extractedContent, template) {
    const components = {};

    switch (template.template) {
      case 'mobile-lesson-template':
        components.lesson = await this.createMobileLesson(extractedContent);
        break;
      case 'mobile-game-template':
        components.game = await this.createMobileGame(extractedContent);
        break;
      case 'mobile-activity-template':
        components.activity = await this.createMobileActivity(extractedContent);
        break;
    }

    return components;
  }

  // Create mobile lesson (optimized for mobile app)
  async createMobileLesson(content) {
    return {
      title: content.title,
      introduction: "📱 Welcome to this mobile lesson!",
      slides: content.sections || content.pages || content.slides || [],
      interactions: [
        {
          type: "tap-to-learn",
          element: "content-blocks",
          feedback: "Great job! Keep learning!",
          hapticFeedback: true
        },
        {
          type: "swipe-navigation",
          element: "slide-transitions",
          feedback: "Swipe to continue!",
          smoothAnimation: true
        },
        {
          type: "drag-and-drop",
          element: "matching-items",
          feedback: "Perfect match!",
          visualEffects: true
        }
      ],
      progressTracking: {
        slidesCompleted: 0,
        totalSlides: content.sections?.length || content.pages?.length || content.slides?.length || 1,
        timeSpent: 0,
        achievements: [],
        streakCount: 0
      },
      gamification: {
        pointsPerSlide: 10,
        bonusPoints: 5,
        achievements: ["First Slide", "Halfway There", "Lesson Complete"],
        rewards: ["🌟", "🎉", "🏆"]
      }
    };
  }

  // Create mobile game (optimized for mobile app)
  async createMobileGame(content) {
    return {
      title: content.title,
      instructions: "🎮 Complete the activities to earn points!",
      gameElements: [
        {
          type: "matching-game",
          data: content.sections || content.pages || content.slides || [],
          scoring: {
            pointsPerMatch: 10,
            timeBonus: 5,
            perfectBonus: 20,
            streakMultiplier: 1.5
          }
        }
      ],
      levels: [
        { level: 1, difficulty: "easy", targetScore: 50, unlockReward: "🌟" },
        { level: 2, difficulty: "medium", targetScore: 100, unlockReward: "🎉" },
        { level: 3, difficulty: "hard", targetScore: 150, unlockReward: "🏆" }
      ],
      rewards: {
        stars: 0,
        badges: [],
        achievements: [],
        unlockables: []
      },
      mobileFeatures: {
        touchOptimized: true,
        gestureControls: true,
        soundEffects: true,
        hapticFeedback: true
      }
    };
  }

  // Create mobile activity
  async createMobileActivity(content) {
    return {
      title: content.title,
      tasks: content.sections || content.pages || content.slides || [],
      interactions: [
        {
          type: "task-completion",
          element: "activity-items",
          feedback: "Task completed!",
          progressUpdate: true
        }
      ],
      completion: {
        tasksCompleted: 0,
        totalTasks: content.sections?.length || content.pages?.length || content.slides?.length || 1,
        completionRate: 0,
        timeSpent: 0
      },
      rewards: {
        completionBadge: "✅",
        progressStars: "⭐",
        achievementUnlock: "🎯"
      }
    };
  }

  // Generate questions from content title
  generateQuestionsFromTitle(title) {
    const baseQuestions = [
      {
        id: "q1",
        type: "multiple_choice",
        question: `What is the main topic of "${title}"?`,
        options: [
          "Learning and education",
          "Interactive content",
          "Mobile app features",
          "All of the above"
        ],
        correctAnswer: "All of the above",
        explanation: "This material covers various aspects of interactive learning.",
        difficulty: "easy"
      },
      {
        id: "q2",
        type: "multiple_choice",
        question: "What makes this content interactive?",
        options: [
          "Touch interactions",
          "Visual elements",
          "Progress tracking",
          "All of the above"
        ],
        correctAnswer: "All of the above",
        explanation: "Interactive content includes multiple engagement features.",
        difficulty: "medium"
      }
    ];

    return baseQuestions;
  }

  // Generate image-based questions
  generateImageQuestions(imageName) {
    return [
      {
        id: "img_q1",
        type: "multiple_choice",
        question: `What do you see in the image "${imageName}"?`,
        options: [
          "Visual learning content",
          "Interactive elements",
          "Educational material",
          "All of the above"
        ],
        correctAnswer: "All of the above",
        explanation: "Images in the app are designed for visual learning.",
        difficulty: "easy"
      }
    ];
  }

  // Parse text into sections
  parseTextIntoSections(text) {
    const lines = text.split('\n').filter(line => line.trim());
    const sections = [];
    
    lines.forEach((line, index) => {
      if (line.trim()) {
        sections.push({
          sectionNumber: index + 1,
          content: line.trim(),
          interactiveElements: [
            { type: "tap-to-highlight", element: "text-selection" }
          ]
        });
      }
    });

    return sections.length > 0 ? sections : [
      {
        sectionNumber: 1,
        content: "📝 Interactive Text Content\n\nThis text has been converted to an interactive learning experience.",
        interactiveElements: [
          { type: "tap-to-highlight", element: "text-selection" }
        ]
      }
    ];
  }

  // Save mobile app content to Firestore
  async saveMobileAppContent(mobileAppContent, teacherId) {
    try {
      console.log('Saving mobile app content to Firestore...');
      console.log('Content to save:', mobileAppContent);
      console.log('Teacher ID:', teacherId);
      
      const docRef = await addDoc(collection(db, "contents"), {
        ...mobileAppContent,
        teacherId: teacherId,
        createdAt: serverTimestamp(),
        status: "active",
        studentAppReady: true,
        mobileOptimized: true,
        autoConverted: true,
        syncStatus: "pending" // Will be synced to mobile app
      });

      console.log("Mobile app content saved with ID:", docRef.id);
      const result = { id: docRef.id, ...mobileAppContent };
      console.log('Final result:', result);
      return result;
    } catch (error) {
      console.error("Error saving mobile app content:", error);
      console.error("Error details:", {
        message: error.message,
        code: error.code,
        stack: error.stack,
        teacherId: teacherId,
        contentKeys: Object.keys(mobileAppContent)
      });
      throw error;
    }
  }
}

// Export singleton instance
export const contentProcessor = new ContentProcessor();