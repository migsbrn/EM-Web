import React, { useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  FileText,
  Settings,
  X,
  GraduationCap,
  CheckCircle,
} from "lucide-react"; // Using lucide-react for modern icons

const navItems = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/teacher-approval", label: "Teacher Approval", icon: CheckCircle },
  { to: "/manage-teacher", label: "Manage Teacher", icon: Users },
  { to: "/view-students", label: "View Students", icon: GraduationCap },
  { to: "/reports-logs", label: "Reports/Logs", icon: FileText },
  { to: "/settings", label: "Settings", icon: Settings },
];

const Sidebar = ({ isSidebarOpen, setIsSidebarOpen }) => {
  const location = useLocation();
  const sidebarRef = useRef(null);

  // Close sidebar when clicking outside on mobile
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (
        isSidebarOpen &&
        sidebarRef.current &&
        !sidebarRef.current.contains(event.target) &&
        window.innerWidth < 768 // Only apply on mobile/small screens (below md breakpoint)
      ) {
        setIsSidebarOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isSidebarOpen, setIsSidebarOpen]);

  return (
    <>
      {/* Mobile Overlay (Darkens background when drawer is open) */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 z-20 bg-black bg-opacity-50 md:hidden transition-opacity duration-300"
          onClick={() => setIsSidebarOpen(false)}
        ></div>
      )}

      {/* Sidebar/Drawer Content */}
      <div
        ref={sidebarRef}
        className={`fixed inset-y-0 left-0 z-30 w-64 bg-indigo-800 shadow-2xl transition-transform duration-300 ease-in-out
          ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"} 
          md:translate-x-0 md:static md:flex-shrink-0
        `}
      >
        {/* Logo/Header */}
        <div className="p-6 flex justify-between items-center h-16 border-b border-indigo-700">
          <span className="text-2xl font-extrabold text-white tracking-wider">
            Admin Panel
          </span>
          {/* Close button for mobile */}
          <button
            className="text-indigo-200 hover:text-white md:hidden p-1 rounded-full hover:bg-indigo-700"
            onClick={() => setIsSidebarOpen(false)}
            aria-label="Close menu"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Navigation Links */}
        <nav className="p-4 space-y-2">
          {navItems.map((item) => {
            const isActive = location.pathname === item.to;
            return (
              <Link
                key={item.to}
                to={item.to}
                className={`flex items-center px-4 py-3 rounded-lg transition duration-150 ease-in-out
                  ${
                    isActive
                      ? "bg-indigo-700 text-white font-semibold shadow-lg"
                      : "text-indigo-200 hover:bg-indigo-700 hover:text-white"
                  } w-full
                `}
                onClick={() => setIsSidebarOpen(false)} // Close on click for mobile
              >
                <item.icon className="w-5 h-5 mr-3" />
                <span className="truncate">{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>
    </>
  );
};

export default Sidebar;
