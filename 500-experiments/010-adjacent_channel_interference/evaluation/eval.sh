#!/bin/sh

dir=$(dirname "$0")
pwd=$(pwd)

SIGN=`echo $dir | cut -b 1`

case "$SIGN" in
  "/")
      DIR=$dir
      ;;
  ".")
      DIR=$pwd/$dir
      ;;
    *)
      echo "Error while getting directory"
      exit -1
      ;;
esac


$DIR/process_raw_data.sh $1 > result.dat
cat result.dat | sed -e "s#_##g" -e "s#GHz##g" -e "s#HT20#20#g" -e "s#HT40#40#g" -e "s#true#1#g" -e "s#false#0#g" -e "s#wndr##g" > result.mat

exit 0