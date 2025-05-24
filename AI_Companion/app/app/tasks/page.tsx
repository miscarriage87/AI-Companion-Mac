"use client";

import { motion } from "framer-motion";
import { useInView } from "react-intersection-observer";
import { ArrowLeft, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { useState } from "react";

export default function TasksPage() {
  const [headerRef, headerInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase1Ref, phase1InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase2Ref, phase2InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase3Ref, phase3InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase4Ref, phase4InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase5Ref, phase5InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [phase6Ref, phase6InView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [activePhase, setActivePhase] = useState<number | null>(null);

  const handlePhaseClick = (phase: number) => {
    setActivePhase(activePhase === phase ? null : phase);
  };

  return (
    <div className="max-w-4xl mx-auto">
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
          AI Companion MVP – Step-by-Step Build Tasks
        </h1>
        <p className="text-gray-600 dark:text-gray-300 text-lg">
          All tasks below are atomic, testable units of work. Each has a clear
          single concern, clear start/finish, and is designed to enable
          interleaved human QA/testing.
        </p>
      </motion.div>

      {/* Phase 1 */}
      <motion.div
        ref={phase1Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase1InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-blue-50 dark:bg-blue-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 1 ? "ring-2 ring-blue-500" : ""
          }`}
          onClick={() => handlePhaseClick(1)}
        >
          <h2 className="text-2xl font-bold text-blue-700 dark:text-blue-300 mb-2 flex items-center">
            <span className="bg-blue-100 dark:bg-blue-800 text-blue-700 dark:text-blue-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              1
            </span>
            PHASE 1 – ENV SETUP & BASELINE
          </h2>
          {(activePhase === 1 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Create Next.js App",
                  start: "New Next.js app with TypeScript",
                  end: "Running localhost:3000 with default page",
                },
                {
                  title: "Setup Supabase Project",
                  start: "Create project on supabase.io",
                  end: "Save project URL and API key in .env",
                },
                {
                  title: "Add Supabase Client Config",
                  start: "Create supabase/client.ts",
                  end: "Export createClient() bound to env vars",
                },
                {
                  title: "Enable Auth in Supabase",
                  start:
                    "Enable email/password & Google login in Supabase Auth settings",
                  end: "Auth providers activated",
                },
                {
                  title: "Install TailwindCSS",
                  start: "Add Tailwind to project",
                  end: "One custom-styled component renders",
                },
                {
                  title: "Setup .env file",
                  start: "Add keys for Supabase, OpenAI, Anthropic, Gemini",
                  end: "process.env.OPENAI_API_KEY etc. are readable",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase1InView && (activePhase === 1 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-blue-600 dark:text-blue-400 mr-2">
                      {index + 1}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Phase 2 */}
      <motion.div
        ref={phase2Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase2InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-purple-50 dark:bg-purple-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 2 ? "ring-2 ring-purple-500" : ""
          }`}
          onClick={() => handlePhaseClick(2)}
        >
          <h2 className="text-2xl font-bold text-purple-700 dark:text-purple-300 mb-2 flex items-center">
            <span className="bg-purple-100 dark:bg-purple-800 text-purple-700 dark:text-purple-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              2
            </span>
            PHASE 2 – AUTH + UI SHELL
          </h2>
          {(activePhase === 2 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Build Auth Form (Email Login)",
                  start: "New Login.tsx page",
                  end: "Login flow tested with Supabase",
                },
                {
                  title: "Build Auth Provider + Guard Hook",
                  start: "Create auth context",
                  end: "useUser() hook returns session state",
                },
                {
                  title: "Create Chat Shell Layout",
                  start: "Create layout with sidebar + chat area",
                  end: "Renders static text and button in each region",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase2InView && (activePhase === 2 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-purple-600 dark:text-purple-400 mr-2">
                      {index + 7}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Phase 3 */}
      <motion.div
        ref={phase3Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase3InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-green-50 dark:bg-green-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 3 ? "ring-2 ring-green-500" : ""
          }`}
          onClick={() => handlePhaseClick(3)}
        >
          <h2 className="text-2xl font-bold text-green-700 dark:text-green-300 mb-2 flex items-center">
            <span className="bg-green-100 dark:bg-green-800 text-green-700 dark:text-green-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              3
            </span>
            PHASE 3 – INPUT / OUTPUT PIPELINE
          </h2>
          {(activePhase === 3 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Create Text Chat Input Component",
                  start: "Simple <textarea> and submit button",
                  end: "onSend() fires and input clears",
                },
                {
                  title: "Create Message Bubble Renderer",
                  start: "Accepts string prop",
                  end: "Displays user/AI bubble w/ className logic",
                },
                {
                  title: "Add Voice Input Button",
                  start: "Mic icon triggers Web Speech API",
                  end: "Transcribed text appears in input field",
                },
                {
                  title: "Add Voice Output Toggle + Player",
                  start: "Toggle switch + audio element",
                  end: "If active, text gets read aloud via SpeechSynthesis",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase3InView && (activePhase === 3 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-green-600 dark:text-green-400 mr-2">
                      {index + 10}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Phase 4 */}
      <motion.div
        ref={phase4Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase4InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-orange-50 dark:bg-orange-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 4 ? "ring-2 ring-orange-500" : ""
          }`}
          onClick={() => handlePhaseClick(4)}
        >
          <h2 className="text-2xl font-bold text-orange-700 dark:text-orange-300 mb-2 flex items-center">
            <span className="bg-orange-100 dark:bg-orange-800 text-orange-700 dark:text-orange-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              4
            </span>
            PHASE 4 – AI ROUTING LAYER
          </h2>
          {(activePhase === 4 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Create /api/aiRouter.ts API Route",
                  start: "Basic Next.js API route scaffold",
                  end: 'Receives req.body.message, returns {text: "..."}',
                },
                {
                  title: "Integrate OpenAI GPT-4o",
                  start: "Add fetch logic to OpenAI /v1/chat/completions",
                  end: "Returns reply to client from GPT",
                },
                {
                  title: "Integrate Claude API",
                  start: "Add call to Anthropic Claude endpoint",
                  end: "Claude-generated text returned if selected",
                },
                {
                  title: "Integrate Gemini Flash API",
                  start: "Add call to Gemini model",
                  end: "Text reply returned from Google API",
                },
                {
                  title: "Add Model Switch UI",
                  start: "Dropdown or tabs in ChatWindow",
                  end: "Model choice respected in backend routing",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase4InView && (activePhase === 4 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-orange-600 dark:text-orange-400 mr-2">
                      {index + 14}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Phase 5 */}
      <motion.div
        ref={phase5Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase5InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-red-50 dark:bg-red-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 5 ? "ring-2 ring-red-500" : ""
          }`}
          onClick={() => handlePhaseClick(5)}
        >
          <h2 className="text-2xl font-bold text-red-700 dark:text-red-300 mb-2 flex items-center">
            <span className="bg-red-100 dark:bg-red-800 text-red-700 dark:text-red-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              5
            </span>
            PHASE 5 – DOCUMENT INGESTION + PARSING
          </h2>
          {(activePhase === 5 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Build File Upload UI",
                  start: "Dropzone component with file type check",
                  end: "Upload hits /api/process-doc.ts",
                },
                {
                  title: "Create /api/process-doc.ts Endpoint",
                  start: "Accept uploaded file and type",
                  end: "Returns dummy parsed content",
                },
                {
                  title: "Parse PDF via pdf-parse",
                  start: "Read uploaded PDF buffer",
                  end: "Return plain text of doc",
                },
                {
                  title: "Parse Excel via sheetjs",
                  start: "Read uploaded .xlsx",
                  end: "Extracted values returned as text",
                },
                {
                  title: "Parse PPTX via pptx2json or LibreOffice",
                  start: "Convert slides to text",
                  end: "Slide text structured as outline JSON",
                },
                {
                  title: "Store Extracted Content in Vector DB",
                  start: "Take parsed text, embed, store in pgvector",
                  end: "Entry stored and searchable",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase5InView && (activePhase === 5 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-red-600 dark:text-red-400 mr-2">
                      {index + 19}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Phase 6 */}
      <motion.div
        ref={phase6Ref}
        initial={{ opacity: 0, y: 30 }}
        animate={phase6InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-10"
      >
        <div
          className={`bg-indigo-50 dark:bg-indigo-900/30 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 6 ? "ring-2 ring-indigo-500" : ""
          }`}
          onClick={() => handlePhaseClick(6)}
        >
          <h2 className="text-2xl font-bold text-indigo-700 dark:text-indigo-300 mb-2 flex items-center">
            <span className="bg-indigo-100 dark:bg-indigo-800 text-indigo-700 dark:text-indigo-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              6
            </span>
            PHASE 6 – KNOWLEDGE GRAPH & MEMORY
          </h2>
          {(activePhase === 6 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Setup pgvector Extension in Supabase",
                  start: "Enable extension via SQL console",
                  end: "Can insert/query vectors in Supabase",
                },
                {
                  title: "Create knowledgeGraph.ts Interface",
                  start: "Utility function with storeText()",
                  end: "storeText(text, userId) inserts embedding vector",
                },
                {
                  title: "Query Closest Knowledge Chunks",
                  start: "Add queryRelevantChunks(prompt)",
                  end: "Returns list of relevant knowledge entries",
                },
                {
                  title: "Inject Knowledge into Prompt",
                  start: "Modify aiRouter to add retrieved context",
                  end: "AI gets system + retrieved + user prompt",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase6InView && (activePhase === 6 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1, duration: 0.5 }}
                  className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-indigo-600 dark:text-indigo-400 mr-2">
                      {index + 25}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-700 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      {/* Final Tasks */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={phase6InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.3 }}
        className="mb-10"
      >
        <div
          className={`bg-gray-50 dark:bg-gray-800 p-6 rounded-xl shadow-md cursor-pointer transition-all ${
            activePhase === 7 ? "ring-2 ring-gray-500" : ""
          }`}
          onClick={() => handlePhaseClick(7)}
        >
          <h2 className="text-2xl font-bold text-gray-700 dark:text-gray-300 mb-2 flex items-center">
            <span className="bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-full w-8 h-8 inline-flex items-center justify-center mr-3 text-sm">
              7
            </span>
            FINAL TASKS – POLISH + QA
          </h2>
          {(activePhase === 7 || activePhase === null) && (
            <div className="mt-4 space-y-4">
              {[
                {
                  title: "Add Logout + AuthGuard Redirect",
                  start: "Add signOut() + redirect on logout",
                  end: "App redirects to login if unauthenticated",
                },
                {
                  title: "Mobile Responsiveness Check",
                  start: "Open on small screen",
                  end: "All elements usable",
                },
                {
                  title: "Add Daily Sync Scheduler",
                  start: "Cron job calls knowledge base updater",
                  end: "Old files re-embedded",
                },
                {
                  title: "Deploy to Vercel + Supabase",
                  start: "Push to Git, connect Vercel",
                  end: "https://yourapp.vercel.app running",
                },
              ].map((task, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={
                    phase6InView && (activePhase === 7 || activePhase === null)
                      ? { opacity: 1, x: 0 }
                      : {}
                  }
                  transition={{ delay: index * 0.1 + 0.4, duration: 0.5 }}
                  className="bg-white dark:bg-gray-700 p-4 rounded-lg shadow task-item"
                >
                  <h3 className="font-semibold text-lg mb-2 flex items-center">
                    <span className="text-gray-600 dark:text-gray-400 mr-2">
                      {index + 29}.
                    </span>{" "}
                    {task.title}
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-gray-50 dark:bg-gray-600 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        Start:
                      </span>{" "}
                      {task.start}
                    </div>
                    <div className="bg-gray-50 dark:bg-gray-600 p-3 rounded">
                      <span className="font-medium text-gray-700 dark:text-gray-300">
                        End:
                      </span>{" "}
                      {task.end}
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={phase6InView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.5, delay: 0.5 }}
        className="bg-green-50 dark:bg-green-900/20 p-6 rounded-xl shadow-md mb-8"
      >
        <div className="flex items-start">
          <CheckCircle2 className="h-6 w-6 text-green-600 dark:text-green-400 mr-3 mt-1 flex-shrink-0" />
          <div>
            <h3 className="font-semibold text-lg mb-2">
              Development Protocol
            </h3>
            <p className="text-gray-700 dark:text-gray-300">
              Each task is designed to be atomic and testable. After completing
              each task, pause for testing. If the task works as intended,
              commit the changes to GitHub before proceeding to the next task.
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  );
}