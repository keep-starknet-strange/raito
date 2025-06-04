install-cairo-prove:
	RUSTFLAGS="-C target-cpu=native -C opt-level=3" \
		cargo install \
			--git https://github.com/starkware-libs/stwo-cairo \
			--rev adc68829b0e913d5a8bdf14932a45fde27a2e335 \
			cairo-prove

client-build:
	scarb --profile proving build --package client --target-kinds executable

client-build-with-shinigami:
	sed -i.bak 's/default = \[\]/default = ["shinigami"]/' packages/consensus/Scarb.toml && rm packages/consensus/Scarb.toml.bak
	scarb --profile proving build --package client --target-kinds executable
	sed -i.bak 's/default = \["shinigami"\]/default = []/' packages/consensus/Scarb.toml && rm packages/consensus/Scarb.toml.bak

assumevalid-build:
	sed -i.bak 's/default = \["syscalls"\]/default = \[\]/' packages/utils/Scarb.toml && rm packages/utils/Scarb.toml.bak
	scarb --profile proving build --package assumevalid
	sed -i.bak 's/default = \[\]/default = \["syscalls"\]/' packages/utils/Scarb.toml && rm packages/utils/Scarb.toml.bak

assumevalid-execute:
	scripts/data/format_args.py --input_file packages/assumevalid/tests/data/batch_100.json > target/execute/assumevalid/args.json
	scarb --profile proving execute \
		--no-build \
		--package assumevalid \
		--executable-name main \
		--arguments-file target/execute/assumevalid/args.json \
		--print-resource-usage

assumevalid-execute-rec:
	scarb --profile proving execute \
		--no-build \
		--package assumevalid \
		--executable-name agg \
		--arguments-file target/execute/assumevalid/proof.json \
		--print-resource-usage

assumevalid-prove:
	rm -rf target/execute/assumevalid
	mkdir -p target/execute/assumevalid
	scripts/data/format_args.py --input_file packages/assumevalid/tests/data/light_169.json > target/execute/assumevalid/args.json
	cairo-prove prove \
		target/proving/main.executable.json \
		target/execute/assumevalid/proof.json \
		--arguments-file target/execute/assumevalid/args.json \
		--proof-format cairo-serde

assumevalid-prove-rec:
	cairo-prove prove \
		target/proving/agg.executable.json \
		target/execute/assumevalid/proof-rec.json \
		--arguments-file target/execute/assumevalid/proof.json \
		--proof-format cairo-serde

assumevalid:
	$(MAKE) assumevalid-build
	$(MAKE) assumevalid-prove
	$(MAKE) assumevalid-execute-rec
