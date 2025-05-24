export const dynamic = "force-dynamic";

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/supabase/client";

// Define the response structure for different AI models
type AIResponse = {
  text: string;
};

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    // Get the current user session
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      return NextResponse.json(
        { error: "Unauthorized" },
        { status: 401 }
      );
    }

    // Parse the request body
    const body = await req.json();
    const { messages, model } = body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return NextResponse.json(
        { error: "Invalid messages format" },
        { status: 400 }
      );
    }

    // Get the last user message
    const lastUserMessage = messages.filter(m => m.role === "user").pop()?.content || "";

    // Check if there are any relevant knowledge chunks
    const relevantKnowledge = await queryRelevantKnowledge(lastUserMessage, session.user.id);
    
    // Route to the appropriate AI model
    let response: AIResponse;
    
    switch (model) {
      case "gpt-4o":
        response = await callOpenAI(messages, relevantKnowledge);
        break;
      case "claude":
        response = await callClaude(messages, relevantKnowledge);
        break;
      case "gemini":
        response = await callGemini(messages, relevantKnowledge);
        break;
      default:
        // Default to OpenAI if model not specified
        response = await callOpenAI(messages, relevantKnowledge);
    }

    return NextResponse.json(response);
  } catch (error: any) {
    console.error("Error in AI router:", error);
    return NextResponse.json(
      { error: error.message || "An error occurred" },
      { status: 500 }
    );
  }
}

// Function to query relevant knowledge from the vector database
async function queryRelevantKnowledge(query: string, userId: string): Promise<string> {
  // This would normally query the vector database
  // For now, return an empty string as we haven't set up the vector DB yet
  return "";
}

// Function to call OpenAI API
async function callOpenAI(messages: any[], relevantKnowledge: string): Promise<AIResponse> {
  try {
    // If we have relevant knowledge, add it to the system message
    const systemMessage = relevantKnowledge 
      ? { role: "system", content: `Use the following information to help answer the user's question: ${relevantKnowledge}` }
      : { role: "system", content: "You are a helpful AI assistant." };
    
    // Add system message if not already present
    if (!messages.some(m => m.role === "system")) {
      messages.unshift(systemMessage);
    }

    // For now, simulate a response since we don't have actual API keys
    // In a real implementation, this would call the OpenAI API
    return {
      text: "This is a simulated response from GPT-4o. In a production environment, this would be a real response from the OpenAI API."
    };
  } catch (error) {
    console.error("Error calling OpenAI:", error);
    throw error;
  }
}

// Function to call Claude API
async function callClaude(messages: any[], relevantKnowledge: string): Promise<AIResponse> {
  try {
    // Simulate Claude response
    return {
      text: "This is a simulated response from Claude. In a production environment, this would be a real response from the Anthropic API."
    };
  } catch (error) {
    console.error("Error calling Claude:", error);
    throw error;
  }
}

// Function to call Gemini API
async function callGemini(messages: any[], relevantKnowledge: string): Promise<AIResponse> {
  try {
    // Simulate Gemini response
    return {
      text: "This is a simulated response from Gemini. In a production environment, this would be a real response from the Google Gemini API."
    };
  } catch (error) {
    console.error("Error calling Gemini:", error);
    throw error;
  }
}