"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Bot, FileText, FileUp, LogOut, Menu, Settings, Upload } from "lucide-react";
import { useUser } from "@/hooks/useUser";
import DocumentUploader from "@/components/DocumentUploader";

export default function UploadPage() {
  const router = useRouter();
  const { user, loading, signOut } = useUser();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [uploadedFiles, setUploadedFiles] = useState<string[]>([]);

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
  }, [user, loading, router]);

  const handleFileUploaded = (fileName: string) => {
    setUploadedFiles((prev) => [...prev, fileName]);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-indigo-50 to-blue-100 dark:from-gray-900 dark:to-gray-800">
        <div className="text-center">
          <div className="animate-spin h-12 w-12 border-4 border-indigo-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600 dark:text-gray-300">Loading your AI companion...</p>
        </div>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900">
      {/* Sidebar */}
      <motion.div
        initial={{ x: -300 }}
        animate={{ x: sidebarOpen ? 0 : -300 }}
        transition={{ duration: 0.3 }}
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-800 shadow-lg transform lg:translate-x-0 lg:static lg:inset-auto lg:h-screen`}
      >
        <div className="flex items-center justify-between h-16 px-4 border-b dark:border-gray-700">
          <div className="flex items-center">
            <Bot className="h-6 w-6 text-indigo-600 dark:text-indigo-400" />
            <h1 className="ml-2 text-xl font-semibold text-gray-800 dark:text-white">AI Companion</h1>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            <Menu className="h-6 w-6" />
          </button>
        </div>
        <nav className="mt-5 px-2 space-y-1">
          <a
            href="/chat"
            className="flex items-center px-4 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
          >
            <Bot className="mr-3 h-5 w-5" />
            Chat
          </a>
          <a
            href="/upload"
            className="flex items-center px-4 py-2 text-sm font-medium rounded-md bg-indigo-100 dark:bg-indigo-900 text-indigo-700 dark:text-indigo-200"
          >
            <FileText className="mr-3 h-5 w-5" />
            Documents
          </a>
          <a
            href="/settings"
            className="flex items-center px-4 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
          >
            <Settings className="mr-3 h-5 w-5" />
            Settings
          </a>
        </nav>
        <div className="absolute bottom-0 w-full p-4 border-t dark:border-gray-700">
          <button
            onClick={signOut}
            className="flex items-center justify-center w-full px-4 py-2 text-sm font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-md"
          >
            <LogOut className="mr-2 h-5 w-5" />
            Sign out
          </button>
        </div>
      </motion.div>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="bg-white dark:bg-gray-800 shadow-sm z-10 sticky top-0">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16 items-center">
              <div className="flex items-center">
                <button
                  onClick={() => setSidebarOpen(true)}
                  className="lg:hidden text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  <Menu className="h-6 w-6" />
                </button>
                <h1 className="ml-2 lg:ml-0 text-xl font-semibold text-gray-800 dark:text-white">Document Upload</h1>
              </div>
            </div>
          </div>
        </header>

        {/* Upload area */}
        <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900 p-4">
          <div className="max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 mb-6"
            >
              <div className="flex items-center mb-4">
                <FileUp className="h-6 w-6 text-indigo-600 dark:text-indigo-400 mr-2" />
                <h2 className="text-xl font-semibold text-gray-800 dark:text-white">Upload Documents</h2>
              </div>
              <p className="text-gray-600 dark:text-gray-300 mb-6">
                Upload PDF, Excel, or PowerPoint files to enhance your AI companion's knowledge.
                These documents will be processed and made available for reference during your conversations.
              </p>
              
              <DocumentUploader onFileUploaded={handleFileUploaded} />
            </motion.div>

            {uploadedFiles.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.2 }}
                className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6"
              >
                <div className="flex items-center mb-4">
                  <FileText className="h-6 w-6 text-green-600 dark:text-green-400 mr-2" />
                  <h2 className="text-xl font-semibold text-gray-800 dark:text-white">Uploaded Documents</h2>
                </div>
                <ul className="divide-y divide-gray-200 dark:divide-gray-700">
                  {uploadedFiles.map((file, index) => (
                    <motion.li
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ duration: 0.3, delay: index * 0.1 }}
                      className="py-3 flex items-center"
                    >
                      <FileText className="h-5 w-5 text-gray-500 dark:text-gray-400 mr-3" />
                      <span className="text-gray-800 dark:text-gray-200">{file}</span>
                      <span className="ml-auto text-xs bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 py-1 px-2 rounded-full">
                        Processed
                      </span>
                    </motion.li>
                  ))}
                </ul>
              </motion.div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}