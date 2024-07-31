import Demo from "./components/Demo";

export default function Home() {
  return (
    <div className="container mx-auto px-4 py-8">
      <section className="mb-12 text-center">
        <h1 className="text-5xl font-bold mb-4 text-yellow-500">
          Raito - Bitcoin ZK Client
        </h1>
        <p className="text-xl mb-4">
          Instantly sync and verify the Bitcoin blockchain using Zero Knowledge
          Proof technology.
        </p>
        <div className="bg-gray-900 p-6 rounded-lg shadow-lg border border-yellow-500 inline-block text-left">
          <p className="mb-4">With Raito, you can:</p>
          <ul className="list-disc list-inside mb-4 space-y-2">
            <li>Sync the entire Bitcoin blockchain in seconds</li>
            <li>Verify the entire Bitcoin blockchain validity trustlessly</li>
            <li>
              Enhance your Bitcoin experience with lightning-fast performance
            </li>
          </ul>
        </div>
      </section>

      <section className="mb-12">
        <Demo />
      </section>
    </div>
  );
}
