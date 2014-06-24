#!/bin/bash

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

#
# Create nodes.csv
#
$DIR/../../bin/extract_nodes.py -p ${RESULTDIR}

xsltproc -o ${RESULTDIR}/links.csv ${DIR}/extract_links.xslt ${RESULTDIR}/measurement.xml 


$DIR/../../bin/extract_nodes.py -p ${RESULTDIR}

PYTHONPATH=$DIR/../../lib/
export PYTHONPATH
$DIR/eval.py 
echo "Mein Result: $?"

exit 2
