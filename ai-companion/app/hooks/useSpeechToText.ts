"use client";

import { useState, useEffect } from "react";

// Define the SpeechRecognition types that TypeScript doesn't know about
interface SpeechRecognitionEvent {
  resultIndex: number;
  results: {
    [index: number]: {
      [index: number]: {
        transcript: string;
      };
      isFinal: boolean;
    };
  };
}

interface SpeechRecognitionErrorEvent {
  error: string;
}

interface SpeechRecognition extends EventTarget {
  continuous: boolean;
  interimResults: boolean;
  start(): void;
  stop(): void;
  onresult: (event: SpeechRecognitionEvent) => void;
  onend: () => void;
  onerror: (event: SpeechRecognitionErrorEvent) => void;
}

// Extend the Window interface to include SpeechRecognition
declare global {
  interface Window {
    SpeechRecognition?: {
      new (): SpeechRecognition;
    };
    webkitSpeechRecognition?: {
      new (): SpeechRecognition;
    };
  }
}

interface SpeechToTextHook {
  transcript: string;
  listening: boolean;
  hasRecognitionSupport: boolean;
  startListening: () => void;
  stopListening: () => void;
}

export function useSpeechToText(): SpeechToTextHook {
  const [transcript, setTranscript] = useState("");
  const [listening, setListening] = useState(false);
  const [hasRecognitionSupport, setHasRecognitionSupport] = useState(false);
  const [recognition, setRecognition] = useState<SpeechRecognition | null>(null);

  useEffect(() => {
    // Check if browser supports speech recognition
    if (typeof window !== "undefined") {
      const SpeechRecognitionAPI = window.SpeechRecognition || window.webkitSpeechRecognition;
      
      if (SpeechRecognitionAPI) {
        setHasRecognitionSupport(true);
        const recognitionInstance = new SpeechRecognitionAPI();
        recognitionInstance.continuous = false;
        recognitionInstance.interimResults = true;
        
        recognitionInstance.onresult = (event) => {
          const current = event.resultIndex;
          const result = event.results[current];
          const transcriptValue = result[0].transcript;
          
          if (result.isFinal) {
            setTranscript(transcriptValue);
          }
        };
        
        recognitionInstance.onend = () => {
          setListening(false);
        };
        
        recognitionInstance.onerror = (event) => {
          console.error("Speech recognition error", event.error);
          setListening(false);
        };
        
        setRecognition(recognitionInstance);
      }
    }
  }, []);

  const startListening = () => {
    if (recognition && !listening) {
      try {
        setTranscript("");
        recognition.start();
        setListening(true);
      } catch (error) {
        console.error("Error starting speech recognition:", error);
      }
    }
  };

  const stopListening = () => {
    if (recognition && listening) {
      recognition.stop();
      setListening(false);
    }
  };

  return {
    transcript,
    listening,
    hasRecognitionSupport,
    startListening,
    stopListening,
  };
}