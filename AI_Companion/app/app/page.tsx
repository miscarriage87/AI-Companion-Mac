"use client";

import { motion } from "framer-motion";
import { ArrowRight, Brain, FileText, Layers } from "lucide-react";
import Link from "next/link";
import { useInView } from "react-intersection-observer";

export default function Home() {
  const [heroRef, heroInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [featuresRef, featuresInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [architectureRef, architectureInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  return (
    <div className="space-y-20 pb-20">
      {/* Hero Section */}
      <motion.section
        ref={heroRef}
        initial={{ opacity: 0, y: 50 }}
        animate={heroInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7 }}
        className="text-center py-20 px-4"
      >
        <div className="max-w-3xl mx-auto">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={heroInView ? { opacity: 1, scale: 1 } : {}}
            transition={{ delay: 0.2, duration: 0.5 }}
          >
            <h1 className="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              AI Companion App for macOS
            </h1>
          </motion.div>
          <motion.p
            initial={{ opacity: 0 }}
            animate={heroInView ? { opacity: 1 } : {}}
            transition={{ delay: 0.4, duration: 0.5 }}
            className="text-xl text-gray-600 dark:text-gray-300 mb-8"
          >
            A full-featured macOS AI Companion with multimodal capabilities,
            multi-provider AI routing, and knowledge base integration.
          </motion.p>
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={heroInView ? { opacity: 1, y: 0 } : {}}
            transition={{ delay: 0.6, duration: 0.5 }}
            className="flex flex-col sm:flex-row gap-4 justify-center"
          >
            <Link
              href="/architecture"
              className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-6 rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg hover:shadow-xl"
            >
              <Layers size={20} />
              View Architecture
            </Link>
            <Link
              href="/tasks"
              className="bg-purple-600 hover:bg-purple-700 text-white font-medium py-3 px-6 rounded-lg transition-all flex items-center justify-center gap-2 shadow-lg hover:shadow-xl"
            >
              <FileText size={20} />
              View Tasks
            </Link>
          </motion.div>
        </div>
      </motion.section>

      {/* Features Section */}
      <motion.section
        ref={featuresRef}
        initial={{ opacity: 0, y: 50 }}
        animate={featuresInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7 }}
        className="py-16 bg-gray-100 dark:bg-gray-800 rounded-3xl max-w-6xl mx-auto"
      >
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">
            Key Features
          </h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                title: "Multimodal I/O",
                description:
                  "Text and voice input/output for natural interactions",
                icon: <Brain className="h-8 w-8 text-blue-500" />,
              },
              {
                title: "Multi-Provider AI",
                description:
                  "OpenAI GPT-4o, Claude.AI, and Google Gemini integration",
                icon: <Brain className="h-8 w-8 text-purple-500" />,
              },
              {
                title: "Knowledge Base",
                description:
                  "Document processing from PDF, PPT, Excel, and more",
                icon: <FileText className="h-8 w-8 text-green-500" />,
              },
              {
                title: "Supabase Backend",
                description: "Authentication and database with vector storage",
                icon: <Layers className="h-8 w-8 text-orange-500" />,
              },
              {
                title: "Next.js Frontend",
                description: "Modern React-based UI with TypeScript",
                icon: <Layers className="h-8 w-8 text-red-500" />,
              },
              {
                title: "Real-time Processing",
                description:
                  "Asynchronous data processing for responsive experience",
                icon: <Brain className="h-8 w-8 text-indigo-500" />,
              },
            ].map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={
                  featuresInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }
                }
                transition={{ delay: index * 0.1, duration: 0.5 }}
                className="bg-white dark:bg-gray-700 p-6 rounded-xl shadow-md hover:shadow-xl transition-all"
              >
                <div className="mb-4">{feature.icon}</div>
                <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                <p className="text-gray-600 dark:text-gray-300">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </motion.section>

      {/* Architecture Preview */}
      <motion.section
        ref={architectureRef}
        initial={{ opacity: 0, y: 50 }}
        animate={architectureInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7 }}
        className="max-w-5xl mx-auto px-4"
      >
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold mb-4">Architecture Overview</h2>
          <p className="text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            The AI Companion is built with a modern tech stack including Next.js,
            Supabase, and multiple AI providers. Explore the complete
            architecture to understand the technical blueprint.
          </p>
        </div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={
            architectureInView ? { opacity: 1, scale: 1 } : { opacity: 0 }
          }
          transition={{ delay: 0.3, duration: 0.5 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-lg"
        >
          <div className="prose dark:prose-invert max-w-none">
            <h3>Folder Structure Preview</h3>
            <div className="code-block">
              <pre>
                <code>
                  {`ai-companion/
├── app/                       # Next.js app routes
│   ├── page.tsx              # Main UI (chat interface)
│   ├── settings/             # User settings
│   ├── upload/               # Document upload logic
│   └── api/                  # Custom serverless API endpoints
├── components/               # Reusable React components
│   ├── ChatWindow.tsx
│   ├── VoiceInput.tsx
│   └── ...
└── ...`}
                </code>
              </pre>
            </div>
          </div>

          <div className="mt-6 text-center">
            <Link
              href="/architecture"
              className="inline-flex items-center text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 font-medium"
            >
              View complete architecture
              <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </div>
        </motion.div>
      </motion.section>
    </div>
  );
}