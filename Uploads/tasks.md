# AI Companion MVP – Step-by-Step Build Tasks

All tasks below are atomic, testable units of work. Each has a clear single concern, clear start/finish, and is designed to enable interleaved human QA/testing.

---

## ✅ PHASE 1 – ENV SETUP & BASELINE

### 1. Create Next.js App

* **Start**: New Next.js app with TypeScript
* **End**: Running `localhost:3000` with default page

### 2. Setup Supabase Project

* **Start**: Create project on supabase.io
* **End**: Save project URL and API key in `.env`

### 3. Add Supabase Client Config

* **Start**: Create `supabase/client.ts`
* **End**: Export `createClient()` bound to env vars

### 4. Enable Auth in Supabase

* **Start**: Enable email/password & Google login in Supabase Auth settings
* **End**: Auth providers activated

### 5. Install TailwindCSS

* **Start**: Add Tailwind to project
* **End**: One custom-styled component renders

### 6. Setup `.env` file

* **Start**: Add keys for Supabase, OpenAI, Anthropic, Gemini
* **End**: `process.env.OPENAI_API_KEY` etc. are readable

---

## 🧑‍💻 PHASE 2 – AUTH + UI SHELL

### 7. Build Auth Form (Email Login)

* **Start**: New `Login.tsx` page
* **End**: Login flow tested with Supabase

### 8. Build Auth Provider + Guard Hook

* **Start**: Create auth context
* **End**: `useUser()` hook returns session state

### 9. Create Chat Shell Layout

* **Start**: Create layout with sidebar + chat area
* **End**: Renders static text and button in each region

---

## 🎤 PHASE 3 – INPUT / OUTPUT PIPELINE

### 10. Create Text Chat Input Component

* **Start**: Simple `<textarea>` and submit button
* **End**: `onSend()` fires and input clears

### 11. Create Message Bubble Renderer

* **Start**: Accepts string prop
* **End**: Displays user/AI bubble w/ className logic

### 12. Add Voice Input Button

* **Start**: Mic icon triggers Web Speech API
* **End**: Transcribed text appears in input field

### 13. Add Voice Output Toggle + Player

* **Start**: Toggle switch + audio element
* **End**: If active, text gets read aloud via SpeechSynthesis

---

## 🧠 PHASE 4 – AI ROUTING LAYER

### 14. Create `/api/aiRouter.ts` API Route

* **Start**: Basic Next.js API route scaffold
* **End**: Receives `req.body.message`, returns `{text: "..."}`

### 15. Integrate OpenAI GPT-4o

* **Start**: Add fetch logic to OpenAI `/v1/chat/completions`
* **End**: Returns reply to client from GPT

### 16. Integrate Claude API

* **Start**: Add call to Anthropic Claude endpoint
* **End**: Claude-generated text returned if selected

### 17. Integrate Gemini Flash API

* **Start**: Add call to Gemini model
* **End**: Text reply returned from Google API

### 18. Add Model Switch UI

* **Start**: Dropdown or tabs in ChatWindow
* **End**: Model choice respected in backend routing

---

## 📁 PHASE 5 – DOCUMENT INGESTION + PARSING

### 19. Build File Upload UI

* **Start**: Dropzone component with file type check
* **End**: Upload hits `/api/process-doc.ts`

### 20. Create `/api/process-doc.ts` Endpoint

* **Start**: Accept uploaded file and type
* **End**: Returns dummy parsed content

### 21. Parse PDF via `pdf-parse`

* **Start**: Read uploaded PDF buffer
* **End**: Return plain text of doc

### 22. Parse Excel via `sheetjs`

* **Start**: Read uploaded `.xlsx`
* **End**: Extracted values returned as text

### 23. Parse PPTX via `pptx2json` or LibreOffice

* **Start**: Convert slides to text
* **End**: Slide text structured as outline JSON

### 24. Store Extracted Content in Vector DB

* **Start**: Take parsed text, embed, store in pgvector
* **End**: Entry stored and searchable

---

## 🧩 PHASE 6 – KNOWLEDGE GRAPH & MEMORY

### 25. Setup pgvector Extension in Supabase

* **Start**: Enable extension via SQL console
* **End**: Can insert/query vectors in Supabase

### 26. Create `knowledgeGraph.ts` Interface

* **Start**: Utility function with `storeText()`
* **End**: `storeText(text, userId)` inserts embedding vector

### 27. Query Closest Knowledge Chunks

* **Start**: Add `queryRelevantChunks(prompt)`
* **End**: Returns list of relevant knowledge entries

### 28. Inject Knowledge into Prompt

* **Start**: Modify `aiRouter` to add retrieved context
* **End**: AI gets `system + retrieved + user` prompt

---

## 📦 FINAL TASKS – POLISH + QA

### 29. Add Logout + AuthGuard Redirect

* **Start**: Add `signOut()` + redirect on logout
* **End**: App redirects to login if unauthenticated

### 30. Mobile Responsiveness Check

* **Start**: Open on small screen
* **End**: All elements usable

### 31. Add Daily Sync Scheduler

* **Start**: Cron job calls knowledge base updater
* **End**: Old files re-embedded

### 32. Deploy to Vercel + Supabase

* **Start**: Push to Git, connect Vercel
* **End**: `https://yourapp.vercel.app` running
