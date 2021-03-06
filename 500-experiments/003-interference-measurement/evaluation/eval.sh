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

if [ "x$RESULTDIR" = "x" ]; then
  if [ "x$1" = "x" ]; then
    echo "Use: \"RESULTDIR=dir $0\" or \"$0 dir\""
    exit 0
  else
    RESULTDIR=$1
  fi
fi

SIGN=`echo $RESULTDIR | cut -b 1`

case "$SIGN" in
  "/")
	;;
    *)
        RESULTDIR="$PWD/$RESULTDIR"
        ;;
esac

#echo $RESULTDIR
#echo $PWD
#echo $DIR

$DIR/merge_xml.sh $RESULTDIR/ > $PWD/interference_exp.xml
xsltproc $DIR/interference2mat.xslt $PWD/interference_exp.xml > $PWD/interference_exp.mat.tmp

SEDARG=`cat $PWD/interference_exp.mat.tmp | sed "s#,# #g" | awk '{print $2}' | uniq | awk '{print "-e s#"$1"#"NR"#g"}' | tr '\012' ' '`

cat $PWD/interference_exp.mat.tmp | sed $SEDARG -e "s#none#0#g" > $PWD/interference_exp.mat

rm -rf $PWD/interference_exp.mat.tmp


