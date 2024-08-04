def block:
"fn test_data_btc_block() -> Block {
	Block {
		header : Header {	
			version: \(.version),
			prev_block_hash: 0x\(.previousblockhash),
			merkle_root_hash: 0x\(.merkle_root),
			time: \(.timestamp),
			bits: \(.bits),
			nonce: \(.nonce)
		},"

;

block
