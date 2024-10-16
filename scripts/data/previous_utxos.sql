EXPORT DATA OPTIONS(
  uri='gs://shinigami-consensus/utxos/*.json',
  format='JSON',
  overwrite=true) AS
select 
  inputs.block_number block_number,
  array_agg(
    struct(
      outputs.block_hash,
      outputs.block_number as block_height,
      unix_seconds(outputs.block_timestamp) as block_time, 
      outputs.transaction_hash as txid, 
      outputs.index as vout,
      outputs.value,
      outputs.script_hex as pk_script,
      outputs.block_number as block_height,
      blocks.median_timestamp,
      txs.is_coinbase
    )
  ) as outputs
FROM `bigquery-public-data.crypto_bitcoin.inputs` as inputs
JOIN `bigquery-public-data.crypto_bitcoin.outputs` as outputs 
  ON outputs.transaction_hash = inputs.spent_transaction_hash
  AND outputs.index = inputs.spent_output_index
JOIN `bigquery-public-data.crypto_bitcoin.transactions` as txs
  ON txs.hash = inputs.spent_transaction_hash
-- JOIN `bigquery-public-data.crypto_bitcoin.blocks` as blocks
--   ON blocks.number = outputs.block_number
JOIN (
  select
    block_number,
    array(
      select * from unnest(previous_timestamps) as timestamp order by timestamp asc
    )[6] as median_timestamp,
  from (
    select
    bn___.number block_number,
    [
      unix_seconds(bn_10.timestamp),
      unix_seconds(bn_09.timestamp),
      unix_seconds(bn_08.timestamp),
      unix_seconds(bn_07.timestamp),
      unix_seconds(bn_06.timestamp),
      unix_seconds(bn_05.timestamp),
      unix_seconds(bn_04.timestamp),
      unix_seconds(bn_03.timestamp),
      unix_seconds(bn_02.timestamp),
      unix_seconds(bn_01.timestamp),
      unix_seconds(bn___.timestamp)
    ] as previous_timestamps,
    from `bigquery-public-data.crypto_bitcoin.blocks` as bn___
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_01 on (bn___.number - 1) = bn_01.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_02 on (bn_01.number - 1) = bn_02.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_03 on (bn_02.number - 1) = bn_03.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_04 on (bn_03.number - 1) = bn_04.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_05 on (bn_04.number - 1) = bn_05.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_06 on (bn_05.number - 1) = bn_06.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_07 on (bn_06.number - 1) = bn_07.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_08 on (bn_07.number - 1) = bn_08.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_09 on (bn_08.number - 1) = bn_09.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_10 on (bn_09.number - 1) = bn_10.number
    join `bigquery-public-data.crypto_bitcoin.blocks` as bn_11 on (bn_10.number - 1) = bn_11.number
  )) as blocks
  ON blocks.block_number = outputs.block_number - 1
-- WHERE inputs.block_number = 97821
group by block_number
order by block_number; -- to make number of files smaller