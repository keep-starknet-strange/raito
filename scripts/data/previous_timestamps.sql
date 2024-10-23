EXPORT DATA OPTIONS(
  uri='gs://shinigami-consensus/timestamps/*.json',
  format='JSON',
  overwrite=true) AS
select
  block_number,
  epoch_start_time,
  previous_timestamps,
from (
  select
  bn___.number block_number,
  unix_seconds(epoch.timestamp) epoch_start_time,
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
  join `bigquery-public-data.crypto_bitcoin.blocks` as epoch on div(bn___.number, 2016) * 2016 = epoch.number 
)
-- where block_number = 116928
order by block_number;