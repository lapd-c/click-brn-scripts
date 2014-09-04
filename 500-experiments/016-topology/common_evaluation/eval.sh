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
$DIR/extract_nodes.py -p ${RESULTDIR}


#
# Create links_filtered.csv
# Create links_raw.csv
# Create articulation_points.csv
# Create runs.csv
# Create bridges.csv
#

LINKS_EXTRACED_PATH=${RESULTDIR}/links_extract.xml
${DIR}/extract_dibadawn_links.py -f ${RESULTDIR}/measurement.xml > ${LINKS_EXTRACED_PATH}
LINKS_RAW_PATH=${RESULTDIR}/links_raw.csv
xsltproc -o ${LINKS_RAW_PATH} ${DIR}/dibadawn_links_to_csv.xslt ${LINKS_EXTRACED_PATH}
LINKS_PATH=${RESULTDIR}/links_filtered.csv
$DIR/filter_links.py -f ${LINKS_RAW_PATH} -e 100 > ${LINKS_PATH}
DISTANCES_PATH=${RESULTDIR}/links_distances.csv
$DIR/link_distances.py -n ${RESULTDIR}/nodes.csv -l ${LINKS_PATH} > ${DISTANCES_PATH}


SEARCHES=${RESULTDIR}/searches.xml
TOPO_PATH=${RESULTDIR}/topo_info.xml
$DIR/extract_topology_info.py -f ${RESULTDIR}/measurement.xml > ${TOPO_PATH}
xsltproc -o ${SEARCHES} ${DIR}/group_searches.xslt ${TOPO_PATH}

xsltproc -o ${RESULTDIR}/articulation_points.csv ${DIR}/dibadawn_articulation_points.xslt ${SEARCHES}
xsltproc -o ${RESULTDIR}/bridges_all.csv ${DIR}/dibadawn_all_bridges.xslt ${SEARCHES}
xsltproc -o ${RESULTDIR}/bridges_unique_per_search.csv ${DIR}/dibadawn_unique_bridges_per_search.xslt ${SEARCHES}

# Count runs
COUNT_OF_RUNS=$(grep -e "^<DibadawnStartSearch" ${RESULTDIR}/measurement.xml | wc -l)
echo -e "\"num_of_runs\"\n${COUNT_OF_RUNS}" > ${RESULTDIR}/runs.csv

grep -e "simpleflow>" -e "<CrossEdge" ${RESULTDIR}/measurement.xml > ${RESULTDIR}/crossedge_extract.xml
xsltproc -o ${RESULTDIR}/cycles.csv ${DIR}/dibadawn_asym_cycle_ration.xslt ${RESULTDIR}/crossedge_extract.xml
 
cd ${RESULTDIR}
../../common_evaluation/calc_articulation_points.R ${LINKS_PATH} > ${RESULTDIR}/theoretical_articulation_points.csv
../../common_evaluation/calc_bridges.R ${LINKS_PATH} > ${RESULTDIR}/theoretical_bridges.csv
../../common_evaluation/calc_f1_measure.R

../../common_evaluation/plot_distances.R 

exit 2

