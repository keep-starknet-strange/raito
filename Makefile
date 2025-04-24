install-stwo:
	# NOTE: rust-toolchain.toml must be the same as the one in the stwo-cairo repo
	RUSTFLAGS="-C target-cpu=native -C opt-level=3" \
		cargo install \
		--git https://github.com/starkware-libs/stwo-cairo \
		--rev b1ff665569140b0701b34c9d965fe9da9246c086 \
		adapted_stwo

install-cairo-execute:
	cargo install --git https://github.com/m-kus/cairo --rev 00d11e0fd87581bd67da676eba7ffb43a9018aa5 cairo-execute

build-light-client:
	scarb --profile release build --package light_client

exec-light-client:
	rm -rf target/execute \
		&& mkdir -p target/execute/light_client/execution1 \
		&& scripts/data/format_args.py --input_file packages/light_client/tests/data/light_169.json > target/execute/light_client/execution1/args.json \
		&& cairo-execute \
		--layout all_cairo_stwo \
		--args-file target/execute/light_client/execution1/args.json \
		--standalone \
		--disable-trace-padding true \
		--prebuilt \
		--trace-file target/execute/light_client/execution1/trace.bin \
		--memory-file target/execute/light_client/execution1/memory.bin \
		--air-public-input target/execute/light_client/execution1/air_public_input.json \
		--air-private-input target/execute/light_client/execution1/air_private_input.json \
		target/release/light_client.executable.json

prove-light-client:
	adapted_stwo \
		--priv_json target/execute/light_client/execution1/air_private_input.json \
		--pub_json target/execute/light_client/execution1/air_public_input.json \
		--params_json packages/light_client/prover_params.json \
		--proof_path target/proof.json \
		--proof-format cairo-serde \
		--verify
