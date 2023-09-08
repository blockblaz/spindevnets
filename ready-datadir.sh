mkdir $DATADIR
if [ ! -n "$DATADIR" ] || (touch $DATADIR/shandong.txt) && [ ! -n "$(ls -A $DATADIR)" ]
then
  echo "provide a valid DATADIR, currently DATADIR=$DATADIR, exiting ... "
  exit;
fi;
# clean these folders as old data can cause issues
sudo rm -rf $DATADIR/ethereumjs
sudo rm -rf $DATADIR/geth
sudo rm -rf $DATADIR/lodestar
# these two commands will harmlessly fail if folders exists
mkdir $DATADIR/ethereumjs
mkdir $DATADIR/geth
mkdir $DATADIR/lodestar
echo "$JWT_SECRET" > $DATADIR/jwtsecret
