"use client";

import { motion } from "framer-motion";
import { useInView } from "react-intersection-observer";
import { ArrowLeft, Bot, FileText, Mic, Settings, Upload } from "lucide-react";
import Link from "next/link";

export default function DashboardPage() {
  const [headerRef, headerInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [contentRef, contentInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  return (
    <div className="max-w-6xl mx-auto">
      <motion.div
        ref={headerRef}
        initial={{ opacity: 0, y: 20 }}
        animate={headerInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.5 }}
        className="mb-8"
      >
        <Link
          href="/"
          className="inline-flex items-center text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 mb-4"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Home
        </Link>
        <h1 className="text-3xl md:text-4xl font-bold mb-4">
          AI Companion Dashboard
        </h1>
        <p className="text-gray-600 dark:text-gray-300 text-lg">
          This dashboard will be the central hub for interacting with your AI
          companion. Currently in development.
        </p>
      </motion.div>

      <motion.div
        ref={contentRef}
        initial={{ opacity: 0, y: 30 }}
        animate={contentInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.2 }}
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      >
        {[
          {
            title: "Chat Interface",
            description:
              "Interact with your AI companion through text and voice",
            icon: <Bot className="h-8 w-8 text-blue-500" />,
            color: "bg-blue-50 dark:bg-blue-900/30",
            textColor: "text-blue-700 dark:text-blue-300",
            iconBg: "bg-blue-100 dark:bg-blue-800",
            iconColor: "text-blue-600 dark:text-blue-300",
            delay: 0,
          },
          {
            title: "Voice Input",
            description: "Speak to your AI companion using voice commands",
            icon: <Mic className="h-8 w-8 text-purple-500" />,
            color: "bg-purple-50 dark:bg-purple-900/30",
            textColor: "text-purple-700 dark:text-purple-300",
            iconBg: "bg-purple-100 dark:bg-purple-800",
            iconColor: "text-purple-600 dark:text-purple-300",
            delay: 0.1,
          },
          {
            title: "Document Upload",
            description: "Upload documents to enhance your AI's knowledge base",
            icon: <Upload className="h-8 w-8 text-green-500" />,
            color: "bg-green-50 dark:bg-green-900/30",
            textColor: "text-green-700 dark:text-green-300",
            iconBg: "bg-green-100 dark:bg-green-800",
            iconColor: "text-green-600 dark:text-green-300",
            delay: 0.2,
          },
          {
            title: "Knowledge Base",
            description: "View and manage your AI's knowledge repository",
            icon: <FileText className="h-8 w-8 text-orange-500" />,
            color: "bg-orange-50 dark:bg-orange-900/30",
            textColor: "text-orange-700 dark:text-orange-300",
            iconBg: "bg-orange-100 dark:bg-orange-800",
            iconColor: "text-orange-600 dark:text-orange-300",
            delay: 0.3,
          },
          {
            title: "Settings",
            description: "Configure your AI companion preferences",
            icon: <Settings className="h-8 w-8 text-gray-500" />,
            color: "bg-gray-50 dark:bg-gray-800",
            textColor: "text-gray-700 dark:text-gray-300",
            iconBg: "bg-gray-100 dark:bg-gray-700",
            iconColor: "text-gray-600 dark:text-gray-300",
            delay: 0.4,
          },
          {
            title: "Coming Soon",
            description: "More features are being developed",
            icon: <Bot className="h-8 w-8 text-indigo-500" />,
            color: "bg-indigo-50 dark:bg-indigo-900/30",
            textColor: "text-indigo-700 dark:text-indigo-300",
            iconBg: "bg-indigo-100 dark:bg-indigo-800",
            iconColor: "text-indigo-600 dark:text-indigo-300",
            delay: 0.5,
          },
        ].map((feature, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, y: 20 }}
            animate={contentInView ? { opacity: 1, y: 0 } : {}}
            transition={{ delay: feature.delay, duration: 0.5 }}
            className={`${feature.color} p-6 rounded-xl shadow-md hover:shadow-xl transition-all cursor-pointer`}
          >
            <div className="flex items-center mb-4">
              <div
                className={`${feature.iconBg} ${feature.iconColor} p-3 rounded-lg mr-4`}
              >
                {feature.icon}
              </div>
              <h2 className={`text-xl font-semibold ${feature.textColor}`}>
                {feature.title}
              </h2>
            </div>
            <p className="text-gray-600 dark:text-gray-300">
              {feature.description}
            </p>
          </motion.div>
        ))}
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={contentInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.6 }}
        className="mt-12 bg-gray-50 dark:bg-gray-800 p-6 rounded-xl shadow-md"
      >
        <h2 className="text-2xl font-bold mb-4">Development Status</h2>
        <p className="text-gray-600 dark:text-gray-300 mb-6">
          This dashboard is currently under development. Check back soon for
          updates or visit the Tasks page to see the development roadmap.
        </p>
        <Link
          href="/tasks"
          className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-all inline-flex items-center"
        >
          <FileText className="mr-2 h-4 w-4" />
          View Development Tasks
        </Link>
      </motion.div>
    </div>
  );
}