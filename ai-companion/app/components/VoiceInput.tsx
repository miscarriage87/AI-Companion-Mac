"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Mic, MicOff } from "lucide-react";
import { useSpeechToText } from "@/hooks/useSpeechToText";

interface VoiceInputProps {
  onTranscript: (transcript: string) => void;
}

export default function VoiceInput({ onTranscript }: VoiceInputProps) {
  const { transcript, listening, hasRecognitionSupport, startListening, stopListening } = useSpeechToText();
  const [pulseAnimation, setPulseAnimation] = useState(false);

  useEffect(() => {
    if (transcript) {
      onTranscript(transcript);
    }
  }, [transcript, onTranscript]);

  useEffect(() => {
    setPulseAnimation(listening);
  }, [listening]);

  if (!hasRecognitionSupport) {
    return (
      <button
        disabled
        className="p-2 rounded-full bg-gray-200 text-gray-400 dark:bg-gray-700 cursor-not-allowed"
        title="Speech recognition not supported in this browser"
      >
        <MicOff className="h-5 w-5" />
      </button>
    );
  }

  return (
    <motion.button
      whileTap={{ scale: 0.95 }}
      onClick={listening ? stopListening : startListening}
      className={`p-2 rounded-full ${
        listening
          ? "bg-red-100 text-red-600 dark:bg-red-900 dark:text-red-400"
          : "bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600"
      }`}
    >
      <div className="relative">
        <Mic className="h-5 w-5" />
        {pulseAnimation && (
          <motion.div
            initial={{ opacity: 0.5, scale: 1 }}
            animate={{ opacity: 0, scale: 2 }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="absolute inset-0 rounded-full bg-red-400 dark:bg-red-700 -z-10"
          />
        )}
      </div>
    </motion.button>
  );
}