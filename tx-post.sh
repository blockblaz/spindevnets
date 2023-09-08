#!/bin/bash
# set -e

ejsId=0
# wait for the block formation to start check for block 1 to be build
# We should curl and get genesis hash, but for now lets assume it will be provided
BLOCK1_HASH=""
while  [ ! -n "$BLOCK1_HASH" ] || [  "$BLOCK1_HASH" == "null" ]
do
  sleep 6
  echo "Checking if block 0x01 has been build ..."
  ejsId=$(( ejsId +1 ))
  responseCmd="curl --location --request POST 'http://localhost:8545' --header 'Content-Type: application/json' --data-raw '{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_getBlockByNumber\",
    \"params\": [
        \"0x1\",
        true
    ],
    \"id\": $ejsId
  }' 2>/dev/null | jq \".result.hash\""
  # echo "$responseCmd"
  BLOCK1_HASH=$(eval "$responseCmd")
done;
echo "BLOCK1_HASH=$BLOCK1_HASH"

# run txs
rawTxs=$(cat $1 | jq ".[].serialized")
rawTxs=($rawTxs)

for rawTx in "${rawTxs[@]}"
do
	echo "Raw tx is $rawTx"
	TX_HASH=""
	TX_RECEIPT=""

	while [ ! -n "$TX_HASH" ] || [  "$TX_HASH" == "null" ]
	do
	  sleep 6
	  echo "Post tx to EL ..."
	  ejsId=$(( ejsId +1 ))
	  txResponseCmd="curl --location --request POST 'http://127.0.0.1:8545' --header 'Content-Type: application/json' --data-raw '{
	    \"jsonrpc\": \"2.0\",
	    \"method\": \"eth_sendRawTransaction\",
	    \"params\": [$rawTx],
	    \"id\": $ejsId
	  }' 2>/dev/null | jq \".result\""
	  TX_HASH=$(eval "$txResponseCmd")
	done;
    echo "tx: $TX_HASH"

	while [ ! -n "$TX_RECEIPT" ] || [  "$TX_RECEIPT" == "null" ]
	do
	  sleep 6
	  echo "Fetching tx receipt from EL ..."
	  ejsId=$(( ejsId +1 ))
	  txResponseCmd="curl --location --request POST 'http://127.0.0.1:8545' --header 'Content-Type: application/json' --data-raw '{
	    \"jsonrpc\": \"2.0\",
	    \"method\": \"eth_getTransactionReceipt\",
	    \"params\": [$TX_HASH],
	    \"id\": $ejsId
	  }' 2>/dev/null | jq \".result.blockHash\""
	  TX_RECEIPT=$(eval "$txResponseCmd")
	done;
	echo "tx included in block: $TX_RECEIPT"
done

	