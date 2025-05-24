"use client";

import { motion } from "framer-motion";
import { useInView } from "react-intersection-observer";
import { ArrowLeft, ExternalLink } from "lucide-react";
import Link from "next/link";

export default function ArchitecturePage() {
  const [headerRef, headerInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const [contentRef, contentInView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

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
          AI Companion App for macOS — Architecture Overview
        </h1>
        <p className="text-gray-600 dark:text-gray-300 text-lg">
          This architecture document defines the complete technical blueprint for
          building a full-featured macOS AI Companion.
        </p>
      </motion.div>

      <motion.div
        ref={contentRef}
        initial={{ opacity: 0, y: 30 }}
        animate={contentInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, delay: 0.2 }}
        className="prose dark:prose-invert max-w-none"
      >
        <h2>Overview</h2>
        <p>
          This architecture document defines the complete technical blueprint for
          building a full-featured macOS AI Companion using:
        </p>
        <ul>
          <li>
            <strong>Frontend</strong>: Next.js (React-based framework)
          </li>
          <li>
            <strong>Backend Services</strong>: Supabase (for DB + Auth),
            Serverless API layer
          </li>
          <li>
            <strong>AI Providers</strong>: OpenAI GPT-4o, Claude.AI, Google
            Gemini 2.5 Flash
          </li>
          <li>
            <strong>Features</strong>:
            <ul>
              <li>Multimodal Input/Output (text & voice)</li>
              <li>Multi-provider AI routing</li>
              <li>
                Knowledge base from documents (PDF, PPT, Excel, etc.)
              </li>
              <li>Real-time and asynchronous data processing</li>
            </ul>
          </li>
        </ul>

        <hr className="my-8" />

        <h2>🔁 Folder Structure</h2>
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
│   ├── VoiceOutput.tsx
│   └── DocumentViewer.tsx
├── lib/                      # Utility libraries
│   ├── aiRouter.ts           # Routes to GPT/Claude/Gemini based on criteria
│   ├── knowledgeGraph.ts     # Interface with the vector DB
│   ├── documentParser.ts     # Extracts content from PDF, Excel, etc.
│   └── voiceUtils.ts         # Voice processing helpers
├── hooks/                    # Custom React hooks
│   ├── useSpeechToText.ts
│   └── useTextToSpeech.ts
├── styles/                   # Tailwind or custom CSS
├── supabase/                 # Supabase client and config
│   ├── client.ts
│   └── auth.ts
├── types/                    # TypeScript types
├── public/                   # Static assets
└── .env                      # API keys & secrets`}
            </code>
          </pre>
        </div>

        <hr className="my-8" />

        <h2>🧠 Feature Breakdown</h2>

        <h3>1. Multimodal Input</h3>
        <ul>
          <li>
            <strong>Text</strong>: From ChatWindow
          </li>
          <li>
            <strong>Voice</strong>: Via <code>VoiceInput.tsx</code> and{" "}
            <code>useSpeechToText.ts</code>
          </li>
          <li>
            <strong>Tech</strong>: <code>Web Speech API</code> (browser) or
            native macOS input
          </li>
        </ul>

        <h3>2. Multimodal Output</h3>
        <ul>
          <li>
            <strong>Text</strong>: Rendered in UI (ChatWindow)
          </li>
          <li>
            <strong>Voice</strong>: <code>VoiceOutput.tsx</code> using{" "}
            <code>useTextToSpeech.ts</code>
          </li>
          <li>
            <strong>Switch</strong>: UI toggle to switch between text/voice
            response
          </li>
        </ul>

        <h3>3. Knowledge Graph / DB</h3>
        <ul>
          <li>
            <strong>Supabase</strong>:
            <ul>
              <li>Auth (email, social)</li>
              <li>Postgres DB for metadata</li>
            </ul>
          </li>
          <li>
            <strong>Vector DB (e.g., Weaviate or pgvector)</strong>:
            <ul>
              <li>Store embeddings from documents</li>
            </ul>
          </li>
          <li>
            <strong>
              <code>knowledgeGraph.ts</code>
            </strong>{" "}
            handles querying & updates
          </li>
        </ul>

        <h3>4. Document Processing</h3>
        <ul>
          <li>
            <code>upload/</code> route handles uploads
          </li>
          <li>
            <code>documentParser.ts</code> extracts text from:
            <ul>
              <li>PDF: pdf-parse</li>
              <li>PPTX: pptx2json / libreoffice</li>
              <li>Excel: sheetjs</li>
            </ul>
          </li>
          <li>
            Parsed content converted to embeddings → stored in vector DB
          </li>
        </ul>

        <h3>5. Multi-AI Integration</h3>
        <ul>
          <li>
            <code>aiRouter.ts</code> handles routing requests to:
            <ul>
              <li>
                <strong>OpenAI</strong> (via GPT-4o)
              </li>
              <li>
                <strong>Claude.ai</strong> (Anthropic API)
              </li>
              <li>
                <strong>Gemini Flash</strong> (Google PaLM/Gemini API)
              </li>
            </ul>
          </li>
          <li>
            Criteria-based routing:
            <ul>
              <li>Model availability</li>
              <li>Task type (vision, summarization, chat)</li>
              <li>User preference</li>
            </ul>
          </li>
        </ul>

        <hr className="my-8" />

        <h2>⚙️ Services & State Management</h2>

        <h3>State</h3>
        <ul>
          <li>
            <strong>Client-side state</strong>: <code>useState</code>,{" "}
            <code>useReducer</code>, or <code>zustand</code> for UI/UX
          </li>
          <li>
            <strong>Server state</strong>:
            <ul>
              <li>
                Supabase for persistent storage (user sessions, history)
              </li>
              <li>
                LocalStorage or IndexedDB for temporary client caching
              </li>
            </ul>
          </li>
        </ul>

        <h3>API Services</h3>
        <ul>
          <li>
            All calls to AI providers via <code>/api/aiRouter.ts</code>
          </li>
          <li>Supabase REST/GraphQL endpoints via client SDK</li>
          <li>
            Document uploads → <code>/api/process-doc.ts</code>
          </li>
          <li>
            Authentication → <code>supabase/auth.ts</code>
          </li>
        </ul>

        <hr className="my-8" />

        <h2>🔐 Authentication</h2>
        <ul>
          <li>
            <strong>Supabase Auth</strong> with:
            <ul>
              <li>Email/Password</li>
              <li>OAuth (Google, Apple)</li>
            </ul>
          </li>
          <li>Session tokens managed via cookies or JWTs</li>
          <li>
            <code>getUser()</code> middleware in API endpoints
          </li>
        </ul>

        <hr className="my-8" />

        <h2>📡 External API Integration</h2>
        <ul>
          <li>
            <strong>OpenAI GPT-4o</strong>: <code>/v1/chat/completions</code>
          </li>
          <li>
            <strong>Claude AI</strong>:{" "}
            <code>https://api.anthropic.com/v1/complete</code>
          </li>
          <li>
            <strong>Google Gemini</strong>:{" "}
            <code>https://generativelanguage.googleapis.com/...</code>
          </li>
        </ul>
        <p>All API keys are stored securely in <code>.env</code></p>

        <hr className="my-8" />

        <h2>🔄 Data Flow Example</h2>
        <div className="code-block">
          <pre>
            <code>
              {`User -->|Speaks| VoiceInput -->|Transcribed| ChatWindow
ChatWindow --> aiRouter
aiRouter -->|Summarization| Claude
aiRouter -->|Vision| Gemini
aiRouter -->|Chat| OpenAI
aiRouter --> ChatWindow
ChatWindow --> VoiceOutput`}
            </code>
          </pre>
        </div>

        <hr className="my-8" />

        <h2>🛠 Development Notes</h2>
        <ul>
          <li>Use Vercel for deployment of Next.js</li>
          <li>
            Use Supabase hosted Postgres with <code>pgvector</code> extension
          </li>
          <li>
            Build audio pipelines using <code>ffmpeg</code>,{" "}
            <code>Web Audio API</code>, <code>whisper.js</code>
          </li>
          <li>Schedule daily sync for knowledge base updates via CRON</li>
        </ul>

        <hr className="my-8" />

        <h2>🧪 Testing</h2>
        <ul>
          <li>
            Unit tests: <code>Jest</code>
          </li>
          <li>
            Integration: <code>Playwright</code>
          </li>
          <li>
            Linting: <code>ESLint + Prettier</code>
          </li>
        </ul>

        <hr className="my-8" />

        <h2>✅ Next Steps</h2>
        <ul className="list-none pl-0">
          <li className="flex items-start mb-2">
            <input
              type="checkbox"
              className="mt-1 mr-2"
              disabled
              checked={false}
            />
            <span>Set up Supabase project & vector DB</span>
          </li>
          <li className="flex items-start mb-2">
            <input
              type="checkbox"
              className="mt-1 mr-2"
              disabled
              checked={false}
            />
            <span>Configure API keys</span>
          </li>
          <li className="flex items-start mb-2">
            <input
              type="checkbox"
              className="mt-1 mr-2"
              disabled
              checked={false}
            />
            <span>Build basic ChatWindow with routing</span>
          </li>
          <li className="flex items-start mb-2">
            <input
              type="checkbox"
              className="mt-1 mr-2"
              disabled
              checked={false}
            />
            <span>Implement voice input/output components</span>
          </li>
          <li className="flex items-start mb-2">
            <input
              type="checkbox"
              className="mt-1 mr-2"
              disabled
              checked={false}
            />
            <span>Integrate document parser + upload UI</span>
          </li>
        </ul>
      </motion.div>
    </div>
  );
}