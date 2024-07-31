<div align="center">
    <h1>Raito ⚡</h1>
    <h2>Bitcoin ZK client written in Cairo.</h2>

<a href="https://github.com/keep-starknet-strange/raito/actions/workflows/check.yaml"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/keep-starknet-strange/raito/check.yml?style=for-the-badge" height=30></a>
<a href="https://bitcoin.org/"> <img alt="Bitcoin" src="https://img.shields.io/badge/Bitcoin-000?style=for-the-badge&logo=bitcoin&logoColor=white" height=30></a>
<a href="https://www.cairo-lang.org/"> <img alt="Cairo" src="https://img.shields.io/badge/Cairo-000?style=for-the-badge" height=30></a>

</div>

## About

Raito is a zero-knowledge Bitcoin client implemented in Cairo. It aims to provide trustless validation of the Bitcoin blockchain through STARK proof verification. It is heavily inspired by [ZeroSync](https://github.com/ZeroSync/ZeroSynchttps://github.com/ZeroSync/ZeroSync) project.

> **Disclaimer:** This project is in the early stages of development and should not be used in production. It will evolve rapidly, expect breaking changes.

Design goals:

- **Usability:** One-click install and run. WebAssembly compatibility for browser-based execution.
- **Maintainability:** Emphasis on simplicity and clean code structure.
- **Performance:** Optimized for speed and efficiency, leveraging STWO's next-generation prover.

## Name reference

Raito is a reference to Light Yagami (夜神月, Yagami Raito) from the manga/anime Death Note.

Why ?

- Raito in Japanese means "Light", which in turns can refer to Lightning ⚡ (and hence both a reference to speed of verification of the Bitcoin blockchain using a ZKP and a reference to the Lightning Network)
- Raito can work in tandem with [Shinigami](https://github.com/keep-starknet-strange/shinigami) that enables verification of Bitcoin Script programs. Raito = Consensus and Shinigami = Execution.

![Raito and Shinigami](./docs/img/memes/raito_shinigami_fusion.jpg)

### Running

```bash
scarb cairo-run --available-gas=200000000
```

This will run the provided Bitcoin Script in Cairo.

### Building

```bash
scarb build
```

This will compile all the components.

### Testing

```bash
scarb test
```

This will run the test-suite for all op-codes, integration, and test Bitcoin Scripts.

## References

- [STWO](https://github.com/starkware-libs/stwo)
- [Cairo](https://www.cairo-lang.org/)
- [Circle STARK paper](https://eprint.iacr.org/2024/278)
- [ZeroSync](https://github.com/ZeroSync/ZeroSync)
