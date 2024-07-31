import Link from "next/link";
import Image from "next/image";

const Header = () => {
  return (
    <header className="bg-black text-yellow-500 p-4 border-b border-yellow-500">
      <nav className="container mx-auto flex justify-between items-center">
        <Link href="/" className="flex items-center">
          <Image
            src="/raito_logo_no_bg.png"
            alt="Raito Logo"
            width={100}
            height={100}
          />
        </Link>
        <div className="flex items-center space-x-4">
          <Link
            href="#demo"
            className="hover:text-yellow-600 transition-colors duration-200"
          >
            Demo
          </Link>
          <a
            href="https://github.com/keep-starknet-strange/raito"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              src="/github-mark-white.svg"
              alt="GitHub"
              width={24}
              height={24}
            />
          </a>
        </div>
      </nav>
    </header>
  );
};

export default Header;
