install-cairo-prove:
	cargo install --git https://github.com/starkware-libs/stwo-cairo cairo-prove

install-cairo-execute:
	cargo install --git https://github.com/m-kus/cairo --rev 9117214e4a3509870c6a6db8e61ddcdaf9ade561 cairo-execute

client-build:
	scarb --profile proving build --package client --target-kinds executable

client-build-with-shinigami:
	sed -i '' 's/default = \[\]/default = ["shinigami"]/' packages/consensus/Scarb.toml
	scarb --profile proving build --package client --target-kinds executable
	sed -i '' 's/default = \["shinigami"\]/default = []/' packages/consensus/Scarb.toml

assumevalid-build:
	sed -i '' 's/default = \["syscalls"\]/default = \[\]/' packages/utils/Scarb.toml
	scarb --profile proving build --package assumevalid
	sed -i '' 's/default = \[\]/default = \["syscalls"\]/' packages/utils/Scarb.toml

assumevalid-execute:
	scripts/data/format_args.py --input_file packages/assumevalid/tests/data/light_169.json > target/execute/assumevalid/args.json
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
