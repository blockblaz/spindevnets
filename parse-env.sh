#!/bin/bash
# set -e

if [ -n "$NETWORK_DIR" ]
then
  echo "sourcing $scriptDir/$NETWORK_DIR/env.vars"
  configDir="$scriptDir/$NETWORK_DIR"
else
  echo "set NETWORK_DIR env variable to run"
  exit;
fi;

# if there is a fork scheduler then run that first only if this is bootnode
if [ -n "$(ls -A $configDir/fork-scheduler.sh)" ] && ( [ ! -n "$MULTIPEER" ] || [ "$MULTIPEER" == "peer1" ] )
then
  source $configDir/fork-scheduler.sh
fi;

echo "network config dir: $configDir"
source "$configDir/fork.vars"
source "$configDir/env.vars"

if [ ! -n "$DATADIR" ]
then
  DATADIR="$scriptDir/data"
fi;
mkdir $DATADIR
origDataDir=$DATADIR

elDataDirSource="/data"
clDataDirSource="/data"

# Check if network arg is provided as the name of the geth genesis json file to use to start
# the custom network
if [ ! -n "$NETWORK" ]
then
  echo "network not provided via NETWORK env variable, exiting..."
  exit;
fi;

if [ ! -n "$JWT_SECRET" ]
then
  JWT_SECRET="0xdc6457099f127cf0bac78de8b297df04951281909db4f58b43def7c7151e765d"
fi;

if [ -n "$ELCLIENT" ]
then
  if [ ! -n "$ELCLIENT_IMAGE" ] && [ ! -n  ELCLIENT_BINARY ]
  then
    case $ELCLIENT in 
      ethereumjs)
        echo "ELCLIENT=$ELCLIENT using local ethereumjs binary from packages/client"
        ;;
      geth)
        if [ ! -n "$NETWORKID" ]
        then
          echo "geth requires NETWORKID to be passed in env, exiting..."
          exit;
        fi;
        ELCLIENT_IMAGE="ethereum/client-go:stable"
        echo "ELCLIENT=$ELCLIENT using ELCLIENT_IMAGE=$ELCLIENT_IMAGE NETWORKID=$NETWORKID"
        ;;
      *)
        echo "ELCLIENT=$ELCLIENT not implemented"
    esac
  fi
else
  ELCLIENT="ethereumjs"
  echo "ELCLIENT=$ELCLIENT using local ethereumjs binary from packages/client"
fi;


if [ -n ELCLIENT_IMAGE ]
then
  echo "pulling latest ELCLIENT_IMAGE=$ELCLIENT_IMAGE"
  docker pull $ELCLIENT_IMAGE
fi;
