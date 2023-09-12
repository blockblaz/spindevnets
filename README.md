# Utility to spin local devnet for debugging and integration testing
  
NETWORK_DIR=kaustinen [full path to this repo]/./spin-node.sh


## Test scenarios:
lets say you exported full repo path as 
```bash
export REPO_PATH=[full path to this repo]
```
now from anywhere in your system you can run the folowing scenarios
(you don't have to leave your dev work dir)

### Single node run with an optional peer node which just syncs and tracks


1. start a single node cl<>el local network
```bash
NETWORK_DIR=kaustinen $REPO_PATH/./spin-node.sh
```
2. (optional) start a `syncpeer` node that just syncs off the first node and then tracks it staying synced
```bash
NETWORK_DIR=kaustinen MULTIPEER=syncpeer $REPO_PATH/./spin-node.sh
```

you can start/restart `syncpeer` at any time (before or after or much much after)

You can also combine both commands and launch them together (using & etc) but stopping them will require process killing

### Two node run with an optional peer node which just syncs and tracks


1. start the bootnode cl<>el
```bash
NETWORK_DIR=kaustinen MULTIPEER=peer1 $REPO_PATH/./spin-node.sh
```
make sure you run the bootnode first because it looks for `fork-scheduler.sh` in `$NETWORK_DIR` and runs the script to `sed` fork scheduling values in the `genesis.json` and `fork.vars` for this network session.

other peers in the following steps will read and use those values.

2. in a different shell start peer2
```bash
NETWORK_DIR=kaustinen MULTIPEER=peer2 $REPO_PATH/./spin-node.sh
```
2. (optional) start a `syncpeer` node that just syncs off the first node and then tracks it staying synced
```bash
NETWORK_DIR=kaustinen MULTIPEER=syncpeer $REPO_PATH/./spin-node.sh
```