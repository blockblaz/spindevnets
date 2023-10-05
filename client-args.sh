#!/bin/bash
# set -e

case $MULTIPEER in
  syncpeer)
    echo "setting up to run as a sync only peer to peer1 (bootnode)..."
    DATADIR="$DATADIR/syncpeer"

    if [ -n "$ELCLIENT_BINARY" ]
    then

      elDataDirSource="$DATADIR"
    fi;
    if [ -n "$LODE_BINARY" ]
    then
      clDataDirSource="$DATADIR"
    fi;


    case $ELCLIENT in 
      ethereumjs)
        EL_PORT_ARGS="--port 30305 --rpcEnginePort 8553 --rpcPort 8947 --multiaddrs /ip4/127.0.0.1/tcp/50582/ws --logLevel debug"
        ;;
      geth)
        EL_PORT_ARGS="--datadir $elDataDirSource/geth --authrpc.jwtsecret $elDataDirSource/jwtsecret --http --http.api engine,net,eth,web3,debug,admin --http.corsdomain \"*\" --http.port 8947 --http.addr 0.0.0.0 --http.vhosts \"*\" --authrpc.addr 0.0.0.0 --authrpc.vhosts \"*\" --authrpc.port=8553 --port=30305  --syncmode full --networkid $NETWORKID --nodiscover"
        ;;
      *)
        echo "ELCLIENT=$ELCLIENT not implemented"
    esac
    
    CL_PORT_ARGS="--genesisValidators 8 --enr.tcp 9002 --port 9002 --execution.urls http://localhost:8553  --rest.port 9598 --server http://localhost:9598 --network.connectToDiscv5Bootnodes true"
    ;;

  peer2)
    echo "setting up peer2 to run with peer1 (bootnode)..."
    DATADIR="$DATADIR/peer2"

    if [ -n "$ELCLIENT_BINARY" ]
    then
      elDataDirSource="$DATADIR"
    fi;
    if [ -n "$LODE_BINARY" ]
    then
      clDataDirSource="$DATADIR"
    fi;


    case $ELCLIENT in 
      ethereumjs)
        EL_PORT_ARGS="--port 30304 --rpcEnginePort 8552 --rpcPort 8946 --multiaddrs /ip4/127.0.0.1/tcp/50581/ws --bootnodes $elBootnode --logLevel debug"
        ;;
      geth)
        EL_PORT_ARGS="--datadir $elDataDirSource/geth --authrpc.jwtsecret $elDataDirSource/jwtsecret --http --http.api engine,net,eth,web3,debug,admin --http.corsdomain \"*\" --http.port 8946 --http.addr 0.0.0.0 --http.vhosts \"*\" --authrpc.addr 0.0.0.0 --authrpc.vhosts \"*\" --authrpc.port=8552 --port=30304  --syncmode full --networkid $NETWORKID --nodiscover"
        ;;
      *)
        echo "ELCLIENT=$ELCLIENT not implemented"
        exit;
    esac

    CL_PORT_ARGS="--genesisValidators 8 --startValidators 4..7 --enr.tcp 9001 --port 9001 --execution.urls http://localhost:8552  --rest.port 9597 --server http://127.0.0.1:9597 --network.connectToDiscv5Bootnodes true --bootnodes $bootEnrs"
    ;;

  * )
    DATADIR="$DATADIR/peer1"
    if [ -n "$ELCLIENT_BINARY" ]
    then
      elDataDirSource="$DATADIR"
    fi;
    if [ -n "$LODE_BINARY" ]
    then
      clDataDirSource="$DATADIR"
    fi;


    case $ELCLIENT in 
      ethereumjs)
        EL_PORT_ARGS="--isSingleNode --extIP 127.0.0.1 --logLevel debug"
        ;;
      geth)
        # geth will be mounted in docker with DATADIR to /data
        EL_PORT_ARGS="--datadir $elDataDirSource/geth --authrpc.jwtsecret $elDataDirSource/jwtsecret --http --http.api engine,net,eth,web3,debug,admin --http.corsdomain \"*\" --http.port 8545 --http.addr 0.0.0.0 --http.vhosts \"*\" --authrpc.addr 0.0.0.0 --authrpc.vhosts \"*\" --authrpc.port=8551 --syncmode full --networkid $NETWORKID --nodiscover"
        ;;
      *)
        echo "ELCLIENT=$ELCLIENT not implemented"
    esac

    CL_PORT_ARGS="--sync.isSingleNode --enr.ip 127.0.0.1 --enr.tcp 9000 --enr.udp 9000 --rest.namespace '*'"
    if [ ! -n "$MULTIPEER" ]
    then
      echo "setting up to run as a solo node..."
      CL_PORT_ARGS="$CL_PORT_ARGS --genesisValidators 8 --startValidators 0..7"
    else
      echo "setting up to run as peer1 (bootnode)..."
      CL_PORT_ARGS="$CL_PORT_ARGS --genesisValidators 8 --startValidators 0..3"
    fi;
    MULTIPEER="peer1"
esac

echo "EL_PORT_ARGS=$EL_PORT_ARGS"
echo "CL_PORT_ARGS=$CL_PORT_ARGS"
