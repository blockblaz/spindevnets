#!/bin/bash
# set -e

VERGE_EPOCH=1


# configDir=/home/gajinder/spindevnets/kaustinen
if [ ! -n "$configDir" ]
then
	echo "missing configDir=$configDir for fork-scheduler"
	exit;
fi;
echo ""
echo ""
echo ""
echo "---------------------fork-scheduler-----------"
echo "configDir=$configDir"

# minimal CL settings for relevant to scheduling forks
# do not change unless you apply the change in CL settings
SECONDS_PER_SLOT=6
SLOTS_PER_EPOCH=8

GENESIS_TIME="$(date +%s)"
GENESIS_TIME=$((GENESIS_TIME + 30))
PRAGUE_TIME=$((GENESIS_TIME + SECONDS_PER_SLOT*SLOTS_PER_EPOCH*VERGE_EPOCH))

# if there is no transition set PRAGUE_TIME 1 hour back so that we don't
# encounter pre image caching issue for now
if [ "$VERGE_EPOCH" == "0" ]
then
  PRAGUE_TIME=$((PRAGUE_TIME - 1*3600))
  echo "since VERGE_EPOCH=$VERGE_EPOCH setting pragueTime to 1 hour back to avoid pre image caching issue"
fi;

echo "GENESIS_TIME=$GENESIS_TIME PRAGUE_TIME=$PRAGUE_TIME"

sedPatten="/pragueTime/c\    \"pragueTime\":$PRAGUE_TIME,"
echo $sedPatten
sed -i "$sedPatten" "$configDir/genesis.json"

sedPatten="/ELECTRA_FORK_EPOCH/c\ELECTRA_FORK_EPOCH=$VERGE_EPOCH"
echo $sedPatten
sed -i "$sedPatten" "$configDir/fork.vars"

echo "----------------------------------------------"
echo ""
echo ""
