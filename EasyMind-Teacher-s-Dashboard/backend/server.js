// server.js - Backend API Server
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
require('dotenv').config();

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Server is running',
    openaiConfigured: !!process.env.OPENAI_API_KEY
  });
});

// Process document endpoint
app.post('/api/process-document', upload.single('file'), async (req, res) => {
  try {
    console.log('📥 Received file upload request');
    
    if (!req.file) {
      console.log('❌ No file uploaded');
      return res.status(400).json({ error: 'No file uploaded' });
    }

    console.log('📄 Processing file:', req.file.originalname);
    console.log('📊 File type:', req.file.mimetype);
    console.log('📏 File size:', req.file.size, 'bytes');

    // Check if OpenAI API key is configured
    if (!process.env.OPENAI_API_KEY) {
      console.log('❌ OpenAI API key not configured');
      return res.status(500).json({ 
        error: 'Server configuration error',
        details: 'OpenAI API key is not configured. Please add OPENAI_API_KEY to your .env file'
      });
    }

    // Extract text based on file type
    let extractedText = '';
    
    if (req.file.mimetype === 'application/pdf') {
      console.log('📖 Parsing PDF...');
      const pdfData = await pdfParse(req.file.buffer);
      extractedText = pdfData.text;
      console.log('✅ PDF parsed, text length:', extractedText.length);
    } else if (req.file.mimetype === 'text/plain') {
      console.log('📝 Reading text file...');
      extractedText = req.file.buffer.toString('utf-8');
      console.log('✅ Text file read, length:', extractedText.length);
    } else if (
      req.file.mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      req.file.mimetype === 'application/msword'
    ) {
      console.log('📑 Parsing Word document...');
      const result = await mammoth.extractRawText({ buffer: req.file.buffer });
      extractedText = result.value;
      console.log('✅ Word document parsed, text length:', extractedText.length);
    } else {
      console.log('❌ Unsupported file type:', req.file.mimetype);
      return res.status(400).json({ 
        error: 'Unsupported file type',
        details: `File type ${req.file.mimetype} is not supported. Please use PDF, Word, or text files.`
      });
    }

    if (!extractedText || extractedText.trim().length === 0) {
      console.log('❌ No text extracted from document');
      return res.status(400).json({ 
        error: 'No text could be extracted from the document',
        details: 'The document appears to be empty or the text could not be extracted'
      });
    }

    console.log('🤖 Calling OpenAI API...');

    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: `You are an educational content expert. Extract learning items from the provided text and structure them into a JSON format suitable for a special education lesson. Each item should have:
            - name: A short title/name for the concept
            - description: A clear, simple explanation suitable for special education students
            - examples: Real-world examples (if applicable)
            
            Return ONLY valid JSON in this format:
            {
              "title": "Lesson title based on content",
              "description": "Brief description of what the lesson teaches",
              "suggestedCategory": "One of: FUNCTIONAL_ACADEMICS, COMMUNICATION_SKILLS, SOCIAL_SKILLS, PRE-VOCATIONAL_SKILLS, SELF_HELP, NUMBER_SKILLS",
              "items": [
                {
                  "name": "Item name",
                  "description": "Simple explanation",
                  "examples": "Example 1, Example 2, Example 3"
                }
              ]
            }`
          },
          {
            role: 'user',
            content: `Extract and structure learning content from this text:\n\n${extractedText.substring(0, 10000)}`
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })
    });

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.json();
      console.error('❌ OpenAI API error:', errorData);
      return res.status(500).json({ 
        error: 'OpenAI API error', 
        details: errorData.error?.message || 'Unknown error from OpenAI API'
      });
    }

    const data = await openaiResponse.json();
    const aiResponse = data.choices[0].message.content;

    console.log('✅ AI response received');

    // Parse the AI response
    let extractedContent;
    try {
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        extractedContent = JSON.parse(jsonMatch[0]);
        console.log('✅ Successfully parsed AI response');
        console.log('📚 Extracted', extractedContent.items?.length || 0, 'items');
      } else {
        throw new Error('No valid JSON found in response');
      }
    } catch (parseError) {
      console.error('❌ Error parsing AI response:', parseError);
      console.log('AI Response:', aiResponse);
      return res.status(500).json({ 
        error: 'Failed to parse AI response',
        details: parseError.message
      });
    }

    // Return the structured content
    console.log('✅ Sending success response');
    res.json({
      success: true,
      data: extractedContent
    });

  } catch (error) {
    console.error('❌ Error processing document:', error);
    res.status(500).json({ 
      error: 'Error processing document', 
      details: error.message 
    });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log('');
  console.log('🚀 ================================');
  console.log('🚀 Server Status: RUNNING');
  console.log('🚀 Port:', PORT);
  console.log('🚀 Health Check: http://localhost:' + PORT + '/api/health');
  console.log('🚀 OpenAI API Key:', process.env.OPENAI_API_KEY ? '✅ Configured' : '❌ Not configured');
  console.log('🚀 ================================');
  console.log('');
});