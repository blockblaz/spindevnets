#!/bin/bash
# set -e

run_cmd(){
  echo ""
  echo ""
  echo "--------------------------------------------------------------------------------------"
  echo "--------------------------------------------------------------------------------------"
  execCmd=$1;
  if [ -n "$DETACHED" ]
  then
    echo "running detached: $execCmd"
    eval "$execCmd"
  else
    if [ -n "$WITH_TERMINAL" ]
    then
      execCmd="$WITH_TERMINAL $execCmd"
    fi;
    echo "running: $execCmd &"
    eval "$execCmd" &
  fi;
  echo "--------------------------------------------------------------------------------------"
  echo ""
  echo ""
  echo ""
}

cleanup() {
  echo "cleaning up"
  if [ -n "$ejsPid" ] 
  then
    case $ELCLIENT in 
      ethereumjs)
        ejsPidBySearch=$(ps x | grep "ts-node bin/cli.ts --dataDir $DATADIR/ethereumjs" | grep -v grep | awk '{print $1}')
        ;;
      geth)
        ejsPidBySearch=$(ps x | grep "$elDataDirSource/geth" | grep -v grep | awk '{print $1}')
        ;;
      *)
        echo "ELCLIENT=$ELCLIENT not implemented"
    esac
    
    echo "cleaning ethereumjs pid:${ejsPid} ejsPidBySearch:${ejsPidBySearch}..."
    if [ -n "$ELCLIENT_IMAGE" ]
    then
      docker rm execution${MULTIPEER} -f
    else
      kill $ejsPidBySearch
    fi;
  fi;

  if [ -n "$lodePid" ]
  then
    lodePidBySearch=$(ps x | grep "$DATADIR/lodestar" | grep -v grep | awk '{print $1}')
    echo "cleaning lodestar pid:${lodePid} lodePidBySearch:${lodePidBySearch}..."
    if [ ! -n "$LODE_BINARY" ]
    then
      docker rm beacon${MULTIPEER} -f
    else
      kill $lodePidBySearch
    fi;
  fi;

  if [ -n "$postPid" ]
  then
    postPidBySearch=$(ps x | grep "tx-post.sh" | grep -v grep | awk '{print $1}')
  	kill $postPidBySearch
  fi;

  ejsPid=""
  lodePid=""
  postPid=""

}
