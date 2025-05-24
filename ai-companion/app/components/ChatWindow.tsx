"use client";

import { useEffect, useRef } from "react";
import { motion } from "framer-motion";
import { Bot, User } from "lucide-react";

interface Message {
  role: string;
  content: string;
}

interface ChatWindowProps {
  messages: Message[];
}

export default function ChatWindow({ messages }: ChatWindowProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  return (
    <div className="space-y-4">
      {messages.map((message, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}
        >
          <div
            className={`flex max-w-[80%] ${
              message.role === "user"
                ? "bg-indigo-600 text-white rounded-2xl rounded-tr-none"
                : "bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-2xl rounded-tl-none border border-gray-200 dark:border-gray-700"
            } px-4 py-3 shadow-sm`}
          >
            <div className="flex">
              <div className="mr-2 mt-1">
                {message.role === "user" ? (
                  <User className="h-5 w-5 text-indigo-200" />
                ) : (
                  <Bot className="h-5 w-5 text-indigo-600 dark:text-indigo-400" />
                )}
              </div>
              <div>
                <p className="whitespace-pre-wrap">{message.content}</p>
              </div>
            </div>
          </div>
        </motion.div>
      ))}
      <div ref={messagesEndRef} />
    </div>
  );
}