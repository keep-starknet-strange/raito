use super::utils::double_sha256;

pub fn merkle_root(ref txids: Array<u256>) -> u256 {
    if txids.len() % 2 == 1 {
        txids.append(*txids.at(txids.len() - 1));
    }

    let mut next_txids = ArrayTrait::new();
    let mut i = 0;
    let len = txids.len();
    while i < len {
        next_txids.append(double_sha256(*txids.at(i), *txids.at(i + 1)));
        i += 2;
    };

    merkle_root(ref next_txids)
}
