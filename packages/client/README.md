# Bitcoin client in Cairo

This package is a standalone Cairo program (outside of Starknet context) that implements a Bitcoin client which can work in two modes:
- Light mode: block header validation only
- Full mode: full Bitcoin consensus validation

## Usage

```sh
# You have to be in the "packages/client" directory
scarb run client START_HEIGHT END_HEIGHT BATCH_SIZE MODE STRATEGY
```

Client expects the following arguments:
* `START_HEIGHT` height of the initial chain state
* `END_HEIGHT` height of the final (resulting) chain state
* `BATCH_SIZE` number of blocks applied per single program run
* `MODE` either `light` or `full` (default is light)
* `STRATEGY` either `sequential` or `random` (default is sequential)

## Integration tests

In order to run integration tests:

```sh
scarb test
```

Run a specific test file (or several files):

```sh
# You have to be in the "packages/client" directory
scarb test tests/data/light_481823.json
```

Show output for a specific test:

```sh
scarb test tests/data/light_481823.json --nocapture
```

Re-generate integration test data:

```sh
# You have to be in the "packages/client" directory
scarb run regenerate_tests --force
```

If you want to just add a new test case, edit `scripts/data/regenerate_tests.sh` and run without `--force` flag.

You can also add/remove ignored scenarios, check out `scripts/data/regenerate_tests.sh` as well.
