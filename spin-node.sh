#!/bin/bash
# set -e

# parse env and set defaults
source "$(dirname $0)/parse-env.sh"
# build static client input args
source "$scriptDir/client-args.sh"
# ready datadir
source "$scriptDir/ready-datadir.sh"

# additional step for setting geth genesis now that we have datadir
if [ "$ELCLIENT" == "geth" ]
then
  if [ -n "$ELCLIENT_IMAGE" ]
  then
    setupCmd="docker run --rm -v $configDir:/config -v $DATADIR:/data $ELCLIENT_IMAGE --datadir $argDataDirSource/geth $EXTRA_EL_SETUP_PARAMS init /config/genesis.json"
  else
    setupCmd="$ELCLIENT_BINARY --datadir $argDataDirSource/geth $EXTRA_EL_SETUP_PARAMS init $configDir/genesis.json"
  fi;
  
  echo ""
  echo ""
  echo "--------------------------------------------------------------------------------------"
  echo "--------------------------------------------------------------------------------------"
  echo "$setupCmd"
  echo "--------------------------------------------------------------------------------------"
  echo ""
  echo ""
  echo ""
  $setupCmd
fi;

# util for running docker or direct cmds or cleanup
source "$scriptDir/util-fns.sh"

EL_PORT_ARGS="$EL_PORT_ARGS $EXTRA_EL_PARAMS"
if [ "$MULTIPEER" == "peer1" ]
then
  case $ELCLIENT in 
    ethereumjs)
      ejsCmd="npm run client:start:ts -- --dataDir $DATADIR/ethereumjs --gethGenesis $configDir/$NETWORK.json --rpc --rpcEngine --rpcEngineAuth false $EL_PORT_ARGS"
      ;;
    geth)
      if [ -n "$ELCLIENT_IMAGE" ]
      then
        # geth will be mounted in docker with DATADIR to /data
        ejsCmd="docker run --rm --name execution${MULTIPEER} -v $DATADIR:/data --network host $ELCLIENT_IMAGE $EL_PORT_ARGS"
      else
        ejsCmd="$ELCLIENT_BINARY $EL_PORT_ARGS"
      fi;
      ;;
    *)
      echo "ELCLIENT=$ELCLIENT not implemented"
      exit;
  esac

  run_cmd "$ejsCmd"
  ejsPid=$!
  echo "ejsPid: $ejsPid"

  # generate the genesis hash and time
  ejsId=0
  if [ ! -n "$GENESIS_HASH" ]
  then
    # We should curl and get genesis hash, but for now lets assume it will be provided
    while [ ! -n "$GENESIS_HASH" ]
    do
      sleep 3
      echo "Fetching genesis hash from ethereumjs ..."
      ejsId=$(( ejsId +1 ))
      responseCmd="curl --location --request POST 'http://localhost:8545' --header 'Content-Type: application/json' --data-raw '{
        \"jsonrpc\": \"2.0\",
        \"method\": \"eth_getBlockByNumber\",
        \"params\": [
            \"0x0\",
            true
        ],
        \"id\": $ejsId
      }' 2>/dev/null | jq \".result.hash\""
      # echo "$responseCmd"
      GENESIS_HASH=$(eval "$responseCmd")
    done;
  fi

  genTime="$(date +%s)"
  genTime=$((genTime + 30))
  echo $genTime > "$origDataDir/genesisTime"
  echo $GENESIS_HASH > "$origDataDir/genesisHash"
else
  # We should curl and get genesis hash, but for now lets assume it will be provided
  while [ ! -n "$CL_GENESIS_HASH" ]
  do
    sleep 3
    echo "Fetching genesis block from peer1/cl ..."
    ejsId=$(( ejsId +1 ))
    responseCmd="curl --location --request GET 'http://localhost:9596/eth/v1/beacon/headers/genesis' --header 'Content-Type: application/json'  2>/dev/null | jq \".data.root\""
    CL_GENESIS_HASH=$(eval "$responseCmd")
  done;

  # We should curl and get boot enr
  while [ ! -n "$bootEnrs" ]
  do
    sleep 3
    echo "Fetching bootEnrs block from peer1/cl ..."
    ejsId=$(( ejsId +1 ))
    responseCmd="curl --location --request GET 'http://localhost:9596/eth/v1/node/identity' --header 'Content-Type: application/json'  2>/dev/null | jq \".data.enr\""
    bootEnrs=$(eval "$responseCmd")
  done;

  # We should curl and get boot enr
  while [ ! -n "$elBootnode" ]
  do
    sleep 3
    echo "Fetching elBootnode block from peer1/el ..."
    ejsId=$(( ejsId +1 ))
    responseCmd="curl -X POST -H 'Content-Type: application/json' http://localhost:8545 --data '{\"jsonrpc\": \"2.0\", \"id\": 42, \"method\": \"admin_nodeInfo\", \"params\": []}' | jq \".result.enode\""
    elBootnode=$(eval "$responseCmd")
  done;

  EL_PORT_ARGS="$EL_PORT_ARGS --bootnodes $elBootnode"
  CL_PORT_ARGS="$CL_PORT_ARGS --bootnodes $bootEnrs"

  GENESIS_HASH=$(cat "$origDataDir/genesisHash")
  genTime=$(cat "$origDataDir/genesisTime")

  if [ ! -n "$GENESIS_HASH" ] || [ ! -n "$genTime" ]
  then
    echo "missing GENESIS_HASH=$GENESIS_HASH or genTime=$genTime in origDataDir=$origDataDir"
    exit;
  fi;

  case $ELCLIENT in 
    ethereumjs)
      ejsCmd="npm run client:start -- --dataDir $DATADIR/ethereumjs --gethGenesis $configDir/$NETWORK.json --rpc --rpcEngine --rpcEngineAuth false $EL_PORT_ARGS"
      ;;
    geth)
      if [ -n "$ELCLIENT_IMAGE" ]
      then
        # geth will be mounted in docker with DATADIR to /data
        ejsCmd="docker run --rm --name execution${MULTIPEER} -v $DATADIR:/data --network host $ELCLIENT_IMAGE $EL_PORT_ARGS"
      else
        ejsCmd="$ELCLIENT_BINARY $EL_PORT_ARGS"
      fi;
      ;;
    *)
      echo "ELCLIENT=$ELCLIENT not implemented"
  esac

  run_cmd "$ejsCmd"
  ejsPid=$!
  echo "ejsPid: $ejsPid"
fi;

echo "genesisHash=${GENESIS_HASH}"
echo "genTime=${genTime}"

CL_PORT_ARGS="--genesisEth1Hash $GENESIS_HASH --params.ALTAIR_FORK_EPOCH 0 --params.BELLATRIX_FORK_EPOCH 0 $EXTRA_CL_PARAMS --params.TERMINAL_TOTAL_DIFFICULTY 0x01 --genesisTime $genTime ${CL_PORT_ARGS} --suggestedFeeRecipient 0xcccccccccccccccccccccccccccccccccccccccc --network.maxPeers 55 --targetPeers 50"
if [ ! -n "$LODE_BINARY" ]
then
  if [ ! -n "$LODE_IMAGE" ]
  then
    LODE_IMAGE="chainsafe/lodestar:latest"
  fi;
  lodeCmd="docker run --rm --name beacon${MULTIPEER} -v $DATADIR:/data --network host $LODE_IMAGE dev --dataDir $clDataDirSource/lodestar --jwt-secret $clDataDirSource/jwtsecret  $CL_PORT_ARGS"
else
  lodeCmd="$LODE_BINARY dev --dataDir $clDataDirSource/lodestar --jwt-secret $clDataDirSource/jwtsecret  $CL_PORT_ARGS"
fi;


if [ -n LODE_IMAGE ]
then
  echo "pulling latest LODE_IMAGE=$LODE_IMAGE"
  docker pull $LODE_IMAGE
fi;
run_cmd "$lodeCmd"
lodePid=$!
echo "lodePid: $lodePid"

trap "echo exit signal received;cleanup" SIGINT SIGTERM

if [ -n "$ejsPid" ] && [ -n "$lodePid" ] && [ -n "$RUN_SCENARIOS" ] && [ ! -n "$MULTIPEER" ]
then
  # currently we only run 1 scenario, can be later parsed as "," separated array
  postCmd="$scriptDir/./tx-post.sh $scriptDir/testscenarios/$RUN_SCENARIOS.json"
  run_cmd "$postCmd"
  postPid=$!
  echo "postPid: $postPid"
fi;

if [ ! -n "$DETACHED" ] && [ -n "$ejsPid" ] && [ -n "$lodePid" ]
then
    echo "launched ejsPid=$ejsPid lodePid=$lodePid"
    echo "use ctl + c on any of these (including this) terminals to stop the process"
    wait -n $ejsPid $lodePid
fi

# if its not detached and is here, it means one of the processes exited/didn't launch
if [ ! -n "$DETACHED" ] && [ -n "$ejsPid$lodePid" ]
then
  echo "cleaning up ejsPid=$ejsPid lodePid=$lodePid "
  cleanup
fi;

echo "Script run finished, exiting ..."
