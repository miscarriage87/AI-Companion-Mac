"use client";

import { useState, useEffect } from "react";
import { textToSpeech, stopSpeech, isSpeechSynthesisSupported } from "@/lib/voiceUtils";

interface TextToSpeechHook {
  speak: (text: string) => Promise<void>;
  stop: () => void;
  speaking: boolean;
  supported: boolean;
}

export function useTextToSpeech(): TextToSpeechHook {
  const [speaking, setSpeaking] = useState(false);
  const [supported, setSupported] = useState(false);

  useEffect(() => {
    setSupported(isSpeechSynthesisSupported());
  }, []);

  const speak = async (text: string): Promise<void> => {
    if (!supported) {
      throw new Error("Speech synthesis not supported in this browser");
    }

    try {
      setSpeaking(true);
      await textToSpeech(text);
    } finally {
      setSpeaking(false);
    }
  };

  const stop = (): void => {
    stopSpeech();
    setSpeaking(false);
  };

  return {
    speak,
    stop,
    speaking,
    supported,
  };
}