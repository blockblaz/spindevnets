# Utility to spin local devnet for debugging and integration testing
  
NETWORK_DIR=kaustinen [full path to this repo]/./spin-node.sh


## Test scenarios:
lets say you exported full repo path as 
```bash
export REPO_PATH=[full path to this repo]
```

### Single node run with an optional peer node which syncs and tracks

now from anywhere in your system (you don't have to leave your dev work dir)

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