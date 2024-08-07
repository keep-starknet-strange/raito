use super::utils::double_sha256;

pub fn merkle_root(ref txids: Array<u256>) -> u256 {
    let len = txids.len();
    if len % 2 == 1 {
        txids.append(*txids.at(len - 1));
    } else {
        // CVE-2012-2459 bug fix
        assert!(
            txids.at(len - 1) != txids.at(len - 2), "unexpected node duplication in merkle tree"
        );
    }

    let mut next_txids = ArrayTrait::new();
    let mut i = 0;
    while i < len {
        next_txids.append(double_sha256(*txids.at(i), *txids.at(i + 1)));
        i += 2;
    };

    merkle_root(ref next_txids)
}
