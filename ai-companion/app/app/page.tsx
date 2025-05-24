"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { ArrowRight, Bot, FileText, Mic, Settings } from "lucide-react";
import { useUser } from "@/hooks/useUser";

export default function Home() {
  const router = useRouter();
  const { user, loading } = useUser();

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
  }, [user, loading, router]);

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
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 to-blue-100 dark:from-gray-900 dark:to-gray-800">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-center mb-12"
        >
          <h1 className="text-4xl font-bold text-gray-800 dark:text-white mb-4">
            AI Companion <span className="text-indigo-600 dark:text-indigo-400">MVP</span>
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Your intelligent assistant powered by multiple AI models. Chat, upload documents, and get smart responses.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            whileHover={{ scale: 1.03 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-md hover:shadow-lg transition-all p-6"
            onClick={() => router.push("/chat")}
          >
            <div className="flex items-center mb-4">
              <div className="bg-indigo-100 dark:bg-indigo-900 p-3 rounded-lg">
                <Bot className="h-6 w-6 text-indigo-600 dark:text-indigo-400" />
              </div>
              <h2 className="text-xl font-semibold ml-3 text-gray-800 dark:text-white">Start Chatting</h2>
            </div>
            <p className="text-gray-600 dark:text-gray-300 mb-4">
              Begin a conversation with your AI companion using text or voice.
            </p>
            <div className="flex justify-end">
              <ArrowRight className="h-5 w-5 text-indigo-600 dark:text-indigo-400" />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            whileHover={{ scale: 1.03 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-md hover:shadow-lg transition-all p-6"
            onClick={() => router.push("/upload")}
          >
            <div className="flex items-center mb-4">
              <div className="bg-green-100 dark:bg-green-900 p-3 rounded-lg">
                <FileText className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
              <h2 className="text-xl font-semibold ml-3 text-gray-800 dark:text-white">Upload Documents</h2>
            </div>
            <p className="text-gray-600 dark:text-gray-300 mb-4">
              Upload PDFs, Excel files, or presentations to enhance your AI's knowledge.
            </p>
            <div className="flex justify-end">
              <ArrowRight className="h-5 w-5 text-green-600 dark:text-green-400" />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            whileHover={{ scale: 1.03 }}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-md hover:shadow-lg transition-all p-6"
            onClick={() => router.push("/settings")}
          >
            <div className="flex items-center mb-4">
              <div className="bg-purple-100 dark:bg-purple-900 p-3 rounded-lg">
                <Settings className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
              <h2 className="text-xl font-semibold ml-3 text-gray-800 dark:text-white">Settings</h2>
            </div>
            <p className="text-gray-600 dark:text-gray-300 mb-4">
              Configure your AI companion preferences and manage your account.
            </p>
            <div className="flex justify-end">
              <ArrowRight className="h-5 w-5 text-purple-600 dark:text-purple-400" />
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}