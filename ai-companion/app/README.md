# AI Companion MVP

This is a Next.js application that serves as an AI Companion MVP, integrating multiple AI models (OpenAI GPT-4o, Claude, and Google Gemini) with voice capabilities and document processing.

## Features

- Authentication with Supabase
- Chat interface with multiple AI models
- Voice input and output
- Document upload and processing (PDF, Excel, PowerPoint)
- Knowledge graph for enhanced AI responses
- Responsive design for all devices

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Supabase account
- API keys for OpenAI, Anthropic Claude, and Google Gemini

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ai-companion-mvp
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env.local` file in the root directory with the following variables:
```
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project-url.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# AI Provider API Keys
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key
GOOGLE_API_KEY=your-google-api-key
```

4. Start the development server:
```bash
npm run dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Supabase Setup

1. Create a new project on [Supabase](https://supabase.io)
2. Enable Email/Password and Google authentication in the Auth settings
3. Get your project URL and anon key from the API settings
4. Add them to your `.env.local` file

## Project Structure

- `app/` - Next.js app router pages and API routes
- `components/` - Reusable React components
- `hooks/` - Custom React hooks
- `supabase/` - Supabase client configuration
- `lib/` - Utility functions and helpers

## Deployment

The application can be deployed to Vercel:

1. Push your code to GitHub
2. Connect your repository to Vercel
3. Add your environment variables in the Vercel dashboard
4. Deploy

## License

This project is licensed under the MIT License.