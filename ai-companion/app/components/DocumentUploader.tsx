"use client";

import { useState, useRef } from "react";
import { motion } from "framer-motion";
import { FileText, Upload, X, Check, AlertCircle } from "lucide-react";

interface DocumentUploaderProps {
  onFileUploaded: (fileName: string) => void;
}

export default function DocumentUploader({ onFileUploaded }: DocumentUploaderProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<"idle" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  };

  const handleFile = (file: File) => {
    // Check file type
    const validTypes = [
      "application/pdf", 
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    ];
    
    if (!validTypes.includes(file.type)) {
      setErrorMessage("Invalid file type. Please upload PDF, Excel, or PowerPoint files.");
      setUploadStatus("error");
      return;
    }
    
    // Check file size (10MB max)
    if (file.size > 10 * 1024 * 1024) {
      setErrorMessage("File too large. Maximum size is 10MB.");
      setUploadStatus("error");
      return;
    }
    
    setFile(file);
    setUploadStatus("idle");
    setErrorMessage("");
  };

  const handleUpload = async () => {
    if (!file) return;
    
    setUploading(true);
    setUploadStatus("idle");
    
    try {
      // Create form data
      const formData = new FormData();
      formData.append("file", file);
      
      // Send to API
      const response = await fetch("/api/process-doc", {
        method: "POST",
        body: formData,
      });
      
      if (!response.ok) {
        throw new Error("Failed to upload document");
      }
      
      setUploadStatus("success");
      onFileUploaded(file.name);
    } catch (error) {
      console.error("Error uploading document:", error);
      setUploadStatus("error");
      setErrorMessage("Failed to upload document. Please try again.");
    } finally {
      setUploading(false);
    }
  };

  const resetUpload = () => {
    setFile(null);
    setUploadStatus("idle");
    setErrorMessage("");
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  return (
    <div className="space-y-4">
      <div
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
        className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
          isDragging
            ? "border-indigo-500 bg-indigo-50 dark:bg-indigo-900/20"
            : "border-gray-300 dark:border-gray-700 hover:border-indigo-400 dark:hover:border-indigo-600"
        }`}
      >
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleFileChange}
          accept=".pdf,.xlsx,.pptx"
          className="hidden"
        />
        <div className="flex flex-col items-center">
          <Upload className="h-10 w-10 text-indigo-500 dark:text-indigo-400 mb-3" />
          <p className="text-gray-700 dark:text-gray-300 mb-1">
            Drag and drop your document here, or click to browse
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Supports PDF, Excel, and PowerPoint files (max 10MB)
          </p>
        </div>
      </div>

      {file && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <FileText className="h-6 w-6 text-indigo-600 dark:text-indigo-400" />
              <div>
                <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{file.name}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {(file.size / 1024 / 1024).toFixed(2)} MB
                </p>
              </div>
            </div>
            <button
              onClick={(e) => {
                e.stopPropagation();
                resetUpload();
              }}
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </motion.div>
      )}

      {uploadStatus === "error" && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 p-3 rounded-lg text-sm flex items-start"
        >
          <AlertCircle className="h-5 w-5 mr-2 flex-shrink-0 mt-0.5" />
          <span>{errorMessage}</span>
        </motion.div>
      )}

      {uploadStatus === "success" && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-300 p-3 rounded-lg text-sm flex items-center"
        >
          <Check className="h-5 w-5 mr-2" />
          <span>Document uploaded and processed successfully!</span>
        </motion.div>
      )}

      {file && uploadStatus !== "success" && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex justify-end"
        >
          <button
            onClick={handleUpload}
            disabled={uploading}
            className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {uploading ? (
              <>
                <span className="inline-block animate-spin mr-2">⟳</span>
                Processing...
              </>
            ) : (
              "Upload Document"
            )}
          </button>
        </motion.div>
      )}
    </div>
  );
}