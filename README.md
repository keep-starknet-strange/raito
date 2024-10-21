<div align="center">
    <img src="./docs/img/raito_logo.png" alt="raito-logo" height="260"/>

   ***Bitcoin ZK client written in Cairo.***

<a href="https://github.com/keep-starknet-strange/raito/actions/workflows/check.yaml"><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/keep-starknet-strange/raito/check.yml?style=for-the-badge" height=30></a>
<a href="https://bitcoin.org/"> <img alt="Bitcoin" src="https://img.shields.io/badge/Bitcoin-000?style=for-the-badge&logo=bitcoin&logoColor=white" height=30></a>
<a href="https://www.cairo-lang.org/"> <img alt="Cairo" src="https://img.shields.io/badge/Cairo-000?style=for-the-badge" height=30></a>
<a href="https://exploration.starkware.co/"><img src="https://img.shields.io/badge/Exploration Team-000.svg?&style=for-the-badge&logo=data:image/svg%2bxml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIGlkPSJhIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxODEgMTgxIj48ZGVmcz48c3R5bGU+LmJ7ZmlsbDojZmZmO308L3N0eWxlPjwvZGVmcz48cGF0aCBjbGFzcz0iYiIgZD0iTTE3Ni43Niw4OC4xOGwtMzYtMzcuNDNjLTEuMzMtMS40OC0zLjQxLTIuMDQtNS4zMS0xLjQybC0xMC42MiwyLjk4LTEyLjk1LDMuNjNoLjc4YzUuMTQtNC41Nyw5LjktOS41NSwxNC4yNS0xNC44OSwxLjY4LTEuNjgsMS44MS0yLjcyLDAtNC4yN0w5Mi40NSwuNzZxLTEuOTQtMS4wNC00LjAxLC4xM2MtMTIuMDQsMTIuNDMtMjMuODMsMjQuNzQtMzYsMzcuNjktMS4yLDEuNDUtMS41LDMuNDQtLjc4LDUuMThsNC4yNywxNi41OGMwLDIuNzIsMS40Miw1LjU3LDIuMDcsOC4yOS00LjczLTUuNjEtOS43NC0xMC45Ny0xNS4wMi0xNi4wNi0xLjY4LTEuODEtMi41OS0xLjgxLTQuNCwwTDQuMzksODguMDVjLTEuNjgsMi4zMy0xLjgxLDIuMzMsMCw0LjUzbDM1Ljg3LDM3LjNjMS4zNiwxLjUzLDMuNSwyLjEsNS40NCwxLjQybDExLjQtMy4xMSwxMi45NS0zLjYzdi45MWMtNS4yOSw0LjE3LTEwLjIyLDguNzYtMTQuNzYsMTMuNzNxLTMuNjMsMi45OC0uNzgsNS4zMWwzMy40MSwzNC44NGMyLjIsMi4yLDIuOTgsMi4yLDUuMTgsMGwzNS40OC0zNy4xN2MxLjU5LTEuMzgsMi4xNi0zLjYsMS40Mi01LjU3LTEuNjgtNi4wOS0zLjI0LTEyLjMtNC43OS0xOC4zOS0uNzQtMi4yNy0xLjIyLTQuNjItMS40Mi02Ljk5LDQuMyw1LjkzLDkuMDcsMTEuNTIsMTQuMjUsMTYuNzEsMS42OCwxLjY4LDIuNzIsMS42OCw0LjQsMGwzNC4zMi0zNS43NHExLjU1LTEuODEsMC00LjAxWm0tNzIuMjYsMTUuMTVjLTMuMTEtLjc4LTYuMDktMS41NS05LjE5LTIuNTktMS43OC0uMzQtMy42MSwuMy00Ljc5LDEuNjhsLTEyLjk1LDEzLjg2Yy0uNzYsLjg1LTEuNDUsMS43Ni0yLjA3LDIuNzJoLS42NWMxLjMtNS4zMSwyLjcyLTEwLjYyLDQuMDEtMTUuOGwxLjY4LTYuNzNjLjg0LTIuMTgsLjE1LTQuNjUtMS42OC02LjA5bC0xMi45NS0xNC4xMmMtLjY0LS40NS0xLjE0LTEuMDgtMS40Mi0xLjgxbDE5LjA0LDUuMTgsMi41OSwuNzhjMi4wNCwuNzYsNC4zMywuMTQsNS43LTEuNTVsMTIuOTUtMTQuMzhzLjc4LTEuMDQsMS42OC0xLjE3Yy0xLjgxLDYuNi0yLjk4LDE0LjEyLTUuNDQsMjAuNDYtMS4wOCwyLjk2LS4wOCw2LjI4LDIuNDYsOC4xNiw0LjI3LDQuMTQsOC4yOSw4LjU1LDEyLjk1LDEyLjk1LDAsMCwxLjMsLjkxLDEuNDIsMi4wN2wtMTMuMzQtMy42M1oiLz48L3N2Zz4=" alt="Exploration Team" height="30"></a>
</div>

## Overview

Shinigami is a zero-knowledge Bitcoin client implemented in Cairo. It aims to provide trustless validation of the Bitcoin blockchain through STARK proof verification. It is heavily inspired by [ZeroSync](https://github.com/ZeroSync/ZeroSync) project.

> **Disclaimer:** This project is in the early stages of development and should not be used in production. It will evolve rapidly, expect breaking changes.

<p align="center" width="100%">
  <img src="./docs/img/client.svg" alt="client"/>
</p>

At its core, consensus client accepts two inputs: a batch of consecutive blocks <i>n</i> to <i>m</i> and a STARK proof of the state of the chain up to block <i>n−1</i>. It ensures that the historical chain state is valid by verifying the STARK proof. Then, it produces a new chain state by applying the new blocks on top of the historical state. As a result, a proof of the new state is generated.

## Applications

Although this is a highly experimental project without immediate plans for deployment, there are many potential applications:

* light clients
* IBD speedup
* non custodial bridges
* layer 2s

## Roadmap

<p align="center" width="100%">
  <img src="./docs/img/components.svg" alt="components"/>
</p>

### Milestone 1 - Block header validation

Implement a reduced light client that can verify a range of blocks starting at genesis.  
It does not have to validate execution, just check that the block header fields follow the protocol.

Tasks:

* [x] block hash computation
* [x] proof-of-work validation/computation
* [x] block time validation/computation
* [x] block difficulty adjustment
* [x] script for fetching arbitrary block data
* [x] script for preparing program arguments
* [x] script for running the program e2e for multiple blocks

### Milestone 2 - Partial transaction validation

Extend light client with partial transaction validation, but without UTXO checks.

Tasks:

* [x] reassess validation check list (analyze Bitcoin core codebase)
* [x] generate & run integration tests e2e instead of Cairo codegen
* [x] transaction ID calculation
* [x] transaction root computation
* [x] validate transaction fee
* [x] validate coinbase transaction
* [x] validate that transaction can be mined (locktime, sequence, coinbase maturity)
* [x] validate segwit specific data (wtxid commitment)
* [x] validate block weight
* [x] script that fetches blocks extended with references UTXOs
* [x] script that runs the program e2e for a span of blocks

### Milestone 3 - Bitcoin script validation

Try to run script validation with external Cairo crate.

Tasks:

* [ ] Integrate Shinigami-script

### Milestone 4 - UTXO set verification

Add inclusion proofs for the UTXOs included in the block.

Tasks:

* [ ] isolate unspendable outputs (OP_RETURN, etc)
* [ ] implement cache for UTXOs spent in the same block they are created (*)
* [ ] implement transaction outpoint hashing
* [ ] implement Utreexo accumulator (addition)
* [ ] Utreexo backend that maintains utxo set and Utreexo roots
* [ ] implement Utreexo single inclusion proof verification
* [ ] implement Utreexo single output removal
* [ ] implement Utreexo bridge node that generates individual inclusion proofs
* [ ] implement script that runs the program e2e for a span of blocks

### Milestone 5 - Full consensus validation

Validate full block execution, including the Bitcoin scripts checks and Utreexo.

### Milestone 6 - Optimizations

* [ ] identify Cairo code botlenecks
* [ ] consider using garaga msm to batch signature verifications

### Milestone 7 - Proving the validation

Recursively verify STARK proofs of chain state updates. Still largely tbd.

* [ ] use garaga to implement signature verifications

# Contact

* [Telegram](https://t.me/ShinigamiStarknet)
* [OnlyDust](https://app.onlydust.com/p/raito---bitcoin-zk-client)

## Usage

This will compile all the packages:

```bash
scarb build
```

This will run tests for all the packages:

```bash
scarb test
```

## Build dependencies

Install necessary packages required by Python scripts:

```bash
pip install -r scripts/data/requirements.txt
```

## References

* [Data processing notes](./docs/data.md)
* [ZeroSync](https://github.com/ZeroSync/ZeroSync)
* [Shinigami Script](https://github.com/keep-starknet-strange/shinigami)
* [STWO](https://github.com/starkware-libs/stwo)
* [Cairo](https://www.cairo-lang.org/)
* [Circle STARK paper](https://eprint.iacr.org/2024/278)

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
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/oluwa-peski"><img src="https://avatars.githubusercontent.com/u/53274579?v=4?s=100" width="100px;" alt="oluwapeski"/><br /><sub><b>oluwapeski</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=oluwa-peski" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/stevencartavia"><img src="https://avatars.githubusercontent.com/u/112043913?v=4?s=100" width="100px;" alt="Steven"/><br /><sub><b>Steven</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=stevencartavia" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/manlikeHB"><img src="https://avatars.githubusercontent.com/u/109147010?v=4?s=100" width="100px;" alt="Yusuf Habib"/><br /><sub><b>Yusuf Habib</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=manlikeHB" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Gerson2102"><img src="https://avatars.githubusercontent.com/u/71728860?v=4?s=100" width="100px;" alt="Gerson"/><br /><sub><b>Gerson</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=Gerson2102" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/PavitraAgarwal21"><img src="https://avatars.githubusercontent.com/u/85789615?v=4?s=100" width="100px;" alt="PavitraAgarwal21"/><br /><sub><b>PavitraAgarwal21</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=PavitraAgarwal21" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bloomingpeach"><img src="https://avatars.githubusercontent.com/u/177087057?v=4?s=100" width="100px;" alt="Nguyen Dao"/><br /><sub><b>Nguyen Dao</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=bloomingpeach" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/od-hunter"><img src="https://avatars.githubusercontent.com/u/146340502?v=4?s=100" width="100px;" alt="Hunter001"/><br /><sub><b>Hunter001</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=od-hunter" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/feltroidprime"><img src="https://avatars.githubusercontent.com/u/96737978?v=4?s=100" width="100px;" alt="feltroid Prime"/><br /><sub><b>feltroid Prime</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=feltroidprime" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mexes20"><img src="https://avatars.githubusercontent.com/u/127276944?v=4?s=100" width="100px;" alt="Mexes"/><br /><sub><b>Mexes</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=mexes20" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/JoE11-y"><img src="https://avatars.githubusercontent.com/u/55321462?v=4?s=100" width="100px;" alt="BlockyJ"/><br /><sub><b>BlockyJ</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=JoE11-y" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Groxan"><img src="https://avatars.githubusercontent.com/u/7966898?v=4?s=100" width="100px;" alt="Maksim Strebkov"/><br /><sub><b>Maksim Strebkov</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=Groxan" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hwildwood"><img src="https://avatars.githubusercontent.com/u/9042313?v=4?s=100" width="100px;" alt="Herbie Wildwood"/><br /><sub><b>Herbie Wildwood</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=hwildwood" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fishonamos"><img src="https://avatars.githubusercontent.com/u/43862685?v=4?s=100" width="100px;" alt="Fishon Amos"/><br /><sub><b>Fishon Amos</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=fishonamos" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/raizo07"><img src="https://avatars.githubusercontent.com/u/81079370?v=4?s=100" width="100px;" alt="Wolf"/><br /><sub><b>Wolf</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=raizo07" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/baitcode"><img src="https://avatars.githubusercontent.com/u/801611?v=4?s=100" width="100px;" alt="Ilia Batii"/><br /><sub><b>Ilia Batii</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=baitcode" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Th0rgal"><img src="https://avatars.githubusercontent.com/u/41830259?v=4?s=100" width="100px;" alt="Thomas Marchand"/><br /><sub><b>Thomas Marchand</b></sub></a><br /><a href="https://github.com/keep-starknet-strange/raito/commits?author=Th0rgal" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
