build:
	scarb --profile proving build --target-kinds executable

build-with-shinigami:
	sed -i '' 's/default = \[\]/default = ["shinigami"]/' packages/consensus/Scarb.toml
	scarb --profile proving build --target-kinds executable
	sed -i '' 's/default = \["shinigami"\]/default = []/' packages/consensus/Scarb.toml

install-stwo:
	# NOTE: rust-toolchain.toml must be the same as the one in the stwo-cairo repo
	RUSTFLAGS="-C target-cpu=native -C opt-level=3" \
		cargo install \
		--git https://github.com/starkware-libs/stwo-cairo \
		--rev 61d338ee93f11a735eb5cd86f024f7a73d59d420 \
		adapted_stwo

install-cairo-prove:
	cargo install --git https://github.com/starkware-libs/stwo-cairo cairo-prove

install-cairo-execute:
	cargo install --git https://github.com/m-kus/cairo --rev 9117214e4a3509870c6a6db8e61ddcdaf9ade561 cairo-execute

assumevalid-build:
	scarb --profile proving build --package assumevalid

assumevalid-execute:
	rm -rf target/execute \
		&& mkdir -p target/execute/assumevalid/execution1 \
		&& scripts/data/format_args.py --input_file packages/assumevalid/tests/data/light_169.json > target/execute/assumevalid/execution1/args.json \
		&& cairo-execute \
		--layout all_cairo_stwo \
		--args-file target/execute/assumevalid/execution1/args.json \
		--standalone \
		--disable-trace-padding true \
		--prebuilt \
		--trace-file target/execute/assumevalid/execution1/trace.bin \
		--memory-file target/execute/assumevalid/execution1/memory.bin \
		--air-public-input target/execute/assumevalid/execution1/air_public_input.json \
		--air-private-input target/execute/assumevalid/execution1/air_private_input.json \
		target/proving/assumevalid.executable.json

assumevalid-prove:
	adapted_stwo \
		--priv_json target/execute/assumevalid/execution1/air_private_input.json \
		--pub_json target/execute/assumevalid/execution1/air_public_input.json \
		--params_json packages/assumevalid/prover_params.json \
		--proof_path target/execute/assumevalid/proof.json \
		--proof-format cairo-serde \
		--verify

assumevalid-cairo-prove:
	rm -rf target/execute
	mkdir -p target/execute/assumevalid
	scripts/data/format_args.py --input_file packages/assumevalid/tests/data/light_169.json > target/execute/assumevalid/args.json
	scarb --profile proving build --package assumevalid
	cairo-prove prove \
		target/proving/assumevalid.executable.json \
		target/execute/assumevalid/proof.json \
		--arguments-file target/execute/assumevalid/args.json \

assumevalid:
	$(MAKE) assumevalid-build
	$(MAKE) assumevalid-execute
	$(MAKE) assumevalid-prove
