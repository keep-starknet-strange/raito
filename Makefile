build:
	scarb --profile proving build --target-kinds executable

build-with-shinigami:
	sed -i '' 's/default = \[\]/default = ["shinigami"]/' packages/consensus/Scarb.toml
	scarb --profile proving build --target-kinds executable
	sed -i '' 's/default = \["shinigami"\]/default = []/' packages/consensus/Scarb.toml
