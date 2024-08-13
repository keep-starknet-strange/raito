<div align="center">
    <img src="./docs/img/raito_logo.png" alt="raito-logo" height="260"/>

   ***Bitcoin ZK client written in Cairo.***

<a href="https://github.com/keep-starknet-strange/raito/actions/workflows/check.yaml"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/keep-starknet-strange/raito/check.yml?style=for-the-badge" height=30></a>
<a href="https://bitcoin.org/"> <img alt="Bitcoin" src="https://img.shields.io/badge/Bitcoin-000?style=for-the-badge&logo=bitcoin&logoColor=white" height=30></a>
<a href="https://www.cairo-lang.org/"> <img alt="Cairo" src="https://img.shields.io/badge/Cairo-000?style=for-the-badge" height=30></a>
<a href="https://exploration.starkware.co/"><img src="https://img.shields.io/badge/Exploration Team-000.svg?&style=for-the-badge&logo=data:image/svg%2bxml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIGlkPSJhIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxODEgMTgxIj48ZGVmcz48c3R5bGU+LmJ7ZmlsbDojZmZmO308L3N0eWxlPjwvZGVmcz48cGF0aCBjbGFzcz0iYiIgZD0iTTE3Ni43Niw4OC4xOGwtMzYtMzcuNDNjLTEuMzMtMS40OC0zLjQxLTIuMDQtNS4zMS0xLjQybC0xMC42MiwyLjk4LTEyLjk1LDMuNjNoLjc4YzUuMTQtNC41Nyw5LjktOS41NSwxNC4yNS0xNC44OSwxLjY4LTEuNjgsMS44MS0yLjcyLDAtNC4yN0w5Mi40NSwuNzZxLTEuOTQtMS4wNC00LjAxLC4xM2MtMTIuMDQsMTIuNDMtMjMuODMsMjQuNzQtMzYsMzcuNjktMS4yLDEuNDUtMS41LDMuNDQtLjc4LDUuMThsNC4yNywxNi41OGMwLDIuNzIsMS40Miw1LjU3LDIuMDcsOC4yOS00LjczLTUuNjEtOS43NC0xMC45Ny0xNS4wMi0xNi4wNi0xLjY4LTEuODEtMi41OS0xLjgxLTQuNCwwTDQuMzksODguMDVjLTEuNjgsMi4zMy0xLjgxLDIuMzMsMCw0LjUzbDM1Ljg3LDM3LjNjMS4zNiwxLjUzLDMuNSwyLjEsNS40NCwxLjQybDExLjQtMy4xMSwxMi45NS0zLjYzdi45MWMtNS4yOSw0LjE3LTEwLjIyLDguNzYtMTQuNzYsMTMuNzNxLTMuNjMsMi45OC0uNzgsNS4zMWwzMy40MSwzNC44NGMyLjIsMi4yLDIuOTgsMi4yLDUuMTgsMGwzNS40OC0zNy4xN2MxLjU5LTEuMzgsMi4xNi0zLjYsMS40Mi01LjU3LTEuNjgtNi4wOS0zLjI0LTEyLjMtNC43OS0xOC4zOS0uNzQtMi4yNy0xLjIyLTQuNjItMS40Mi02Ljk5LDQuMyw1LjkzLDkuMDcsMTEuNTIsMTQuMjUsMTYuNzEsMS42OCwxLjY4LDIuNzIsMS42OCw0LjQsMGwzNC4zMi0zNS43NHExLjU1LTEuODEsMC00LjAxWm0tNzIuMjYsMTUuMTVjLTMuMTEtLjc4LTYuMDktMS41NS05LjE5LTIuNTktMS43OC0uMzQtMy42MSwuMy00Ljc5LDEuNjhsLTEyLjk1LDEzLjg2Yy0uNzYsLjg1LTEuNDUsMS43Ni0yLjA3LDIuNzJoLS42NWMxLjMtNS4zMSwyLjcyLTEwLjYyLDQuMDEtMTUuOGwxLjY4LTYuNzNjLjg0LTIuMTgsLjE1LTQuNjUtMS42OC02LjA5bC0xMi45NS0xNC4xMmMtLjY0LS40NS0xLjE0LTEuMDgtMS40Mi0xLjgxbDE5LjA0LDUuMTgsMi41OSwuNzhjMi4wNCwuNzYsNC4zMywuMTQsNS43LTEuNTVsMTIuOTUtMTQuMzhzLjc4LTEuMDQsMS42OC0xLjE3Yy0xLjgxLDYuNi0yLjk4LDE0LjEyLTUuNDQsMjAuNDYtMS4wOCwyLjk2LS4wOCw2LjI4LDIuNDYsOC4xNiw0LjI3LDQuMTQsOC4yOSw4LjU1LDEyLjk1LDEyLjk1LDAsMCwxLjMsLjkxLDEuNDIsMi4wN2wtMTMuMzQtMy42M1oiLz48L3N2Zz4=" alt="Exploration Team" height="30"></a>
</div>

## Overview

Raito is a zero-knowledge Bitcoin client implemented in Cairo. It aims to provide trustless validation of the Bitcoin blockchain through STARK proof verification. It is heavily inspired by [ZeroSync](https://github.com/ZeroSync/ZeroSynchttps://github.com/ZeroSync/ZeroSync) project.

> **Disclaimer:** This project is in the early stages of development and should not be used in production. It will evolve rapidly, expect breaking changes.

```mermaid
flowchart TB
Pnm1(STARK proof of the chain state<br>up to the block <i>n - 1</i>,<br> including utxo accumulator) --> Vp(zk verifier)
Bn(blocks <i>n..m</i>) ----> Vb

subgraph Cairo
    Vp{{STARK verifier}}-->ChS(verified chain state)
    ChS --> Vb{{validate block<br>against the chain state}}
    Vb --> ChS
end

Vb --> Pn(STARK proof of the chain state<br>up to the block <i>m</i>,<br> including utxo accumulator)

style Bn fill:pink
style Pn fill:lightgreen
style Pnm1 fill:lightgreen
style ChS fill:greenyellow
style Vp fill:gold
style Vb fill:gold
```

Raito, at its core, accepts two inputs: a batch of consecutive blocks <i>n</i> to <i>m</i> and a STARK proof of the state of the chain up to block <i>n−1</i>. It ensures that the historical chain state is valid by verifying the STARK proof. Then, it produces a new chain state by applying the new blocks on top of the historical state. As a result, a proof of the new state is generated.

## Applications

Although this is a highly experimental project without immediate plans for deployment, there are many potential applications:

* light clients
* IBD speedup
* non custodial bridges
* layer 2s

## Roadmap

### Milestone 1 - Block Verification

* header verification
   * [ ] block hash
   * [ ] proof-of-work
   * [ ] median time
   * [ ] difficulty adjustment
* transaction verification
   * [ ] tx hash
   * [ ] tx merkle root
   * [ ] verify transaction fee
* block verification
   * [ ] verify coinbase tx
* verify scripts
   * integration with Shinigami, tbd
* integration testing
   * [ ] test on individual historical blocks

### Milestone 2 - Utreexo

* [ ] fetch utreexo from some kind of bridge node, tbd
* [ ] use utreexo to verify tx inputs

### Milestone 3 - Real Data

* [ ] feed it with real data
* [ ] test that you can produce and verify proofs of individual blocks

### Milestone 4 - Recursive Verification

* verify chain proofs with cairo verifier, tbd

## Name reference

Raito is a reference to Light Yagami (夜神月, Yagami Raito) from the manga/anime Death Note.

* Raito in Japanese means "Light", which in turns can refer to Lightning ⚡ (and hence both a reference to speed of verification of the Bitcoin blockchain using a ZKP and a reference to the Lightning Network)
* Raito can work in tandem with [Shinigami](https://github.com/keep-starknet-strange/shinigami) that enables verification of Bitcoin Script programs. Raito = Consensus and Shinigami = Execution. Since Shinigami was named after Ryuk (Shinigami in Death Note), Raito was named after Light (Raito in Death Note).
* What Raito writes in the Death Note always happen, so you can see it as a source of truth, similarly to how you use a Zero-Knowledge Proof to verify the integrity of a computation.

![Raito and Raito](./docs/img/memes/raito_shinigami_fusion.jpg)

# Contact

* [Raito Telegram](https://t.me/RaitoStarknet)
* [Raito OnlyDust](https://app.onlydust.com/p/raito---bitcoin-zk-client)

## Usage

This will compile all the components:

```bash
scarb build

```

This will run the test-suite:

```bash
scarb test
```

## References

* [STWO](https://github.com/starkware-libs/stwo)
* [Cairo](https://www.cairo-lang.org/)
* [Circle STARK paper](https://eprint.iacr.org/2024/278)
* [ZeroSync](https://github.com/ZeroSync/ZeroSync)
* [Shinigami](https://github.com/keep-starknet-strange/shinigami)

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/AbdelStark"><img src="https://avatars.githubusercontent.com/u/45264458?v=4?s=100" width="100px;" alt="A₿del ∞/21M 🐺 - 🐱"/><br /><sub><b>A₿del ∞/21M 🐺 - 🐱</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=AbdelStark" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/maciejka"><img src="https://avatars.githubusercontent.com/u/190855?v=4?s=100" width="100px;" alt="Maciej Kamiński @ StarkWare"/><br /><sub><b>Maciej Kamiński @ StarkWare</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=maciejka" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/b-j-roberts"><img src="https://avatars.githubusercontent.com/u/54774639?v=4?s=100" width="100px;" alt="Brandon R"/><br /><sub><b>Brandon R</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=b-j-roberts" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://nodeguardians.io/character/tadev-guardian"><img src="https://avatars.githubusercontent.com/u/122918260?v=4?s=100" width="100px;" alt="Tristan"/><br /><sub><b>Tristan</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=TAdev0" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Jeanmichel7"><img src="https://avatars.githubusercontent.com/u/59661788?v=4?s=100" width="100px;" alt="Jean-Michel"/><br /><sub><b>Jean-Michel</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=Jeanmichel7" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lomasson"><img src="https://avatars.githubusercontent.com/u/97454276?v=4?s=100" width="100px;" alt="lomasson"/><br /><sub><b>lomasson</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=lomasson" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://nodeguardians.io/character/m-kus"><img src="https://avatars.githubusercontent.com/u/44951260?v=4?s=100" width="100px;" alt="Michael Zaikin"/><br /><sub><b>Michael Zaikin</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=m-kus" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/harsh-ps-2003"><img src="https://avatars.githubusercontent.com/u/119954739?v=4?s=100" width="100px;" alt="Harsh Pratap Singh"/><br /><sub><b>Harsh Pratap Singh</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=harsh-ps-2003" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Xavek"><img src="https://avatars.githubusercontent.com/u/61218841?v=4?s=100" width="100px;" alt="Xavek"/><br /><sub><b>Xavek</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=Xavek" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.heyfemi.com/home"><img src="https://avatars.githubusercontent.com/u/53274579?v=4?s=100" width="100px;" alt="Olufemi Olumaiyegun"/><br /><sub><b>Olufemi Olumaiyegun</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=olufemi-olumaiyegun" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/MSghais"><img src="https://avatars.githubusercontent.com/u/59928086?v=4?s=100" width="100px;" alt="MSG"/><br /><sub><b>MSG</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=MSghais" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://mubarak23.github.io/"><img src="https://avatars.githubusercontent.com/u/7858376?v=4?s=100" width="100px;" alt="Mubarak Muhammad Aminu"/><br /><sub><b>Mubarak Muhammad Aminu</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=mubarak23" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
