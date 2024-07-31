"use client";

import { useState } from "react";

const Demo = () => {
  const [isVerifying, setIsVerifying] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const steps = [
    "Synchronising latest chain header proofs",
    "Verifying proofs",
    "Proof verified successfully",
    "You are now synced with Bitcoin chain, trustlessly",
  ];

  const startVerification = () => {
    setIsVerifying(true);
    setCurrentStep(0);

    const interval = setInterval(() => {
      setCurrentStep((prev) => {
        if (prev < steps.length - 1) {
          return prev + 1;
        } else {
          clearInterval(interval);
          setIsVerifying(false);
          return prev;
        }
      });
    }, 1000);
  };

  return (
    <div className="bg-gray-900 p-6 rounded-lg shadow-lg border border-yellow-500">
      <h2 className="text-2xl font-bold mb-4 text-yellow-500">
        Demo: Instant Bitcoin Blockchain Sync
      </h2>
      <button
        onClick={startVerification}
        disabled={isVerifying}
        className="bg-yellow-500 text-black px-4 py-2 rounded hover:bg-yellow-600 disabled:bg-gray-700 disabled:text-gray-500 transition-colors duration-200"
      >
        {isVerifying ? "Verifying..." : "Start Verification"}
      </button>
      <div className="mt-4">
        {steps.map((step, index) => (
          <div key={index} className="flex items-center mb-2">
            <div
              className={`w-4 h-4 rounded-full mr-2 ${
                index <= currentStep ? "bg-yellow-500" : "bg-gray-700"
              }`}
            ></div>
            <span
              className={
                index <= currentStep ? "text-yellow-500" : "text-gray-500"
              }
            >
              {step}
            </span>
          </div>
        ))}
      </div>
      <p className="mt-4 text-sm text-gray-400">
        Disclaimer: This demo is a simulation and does not represent actual
        blockchain synchronization. It aims to showcase the intended user
        experience of Raito.
      </p>
    </div>
  );
};

export default Demo;
