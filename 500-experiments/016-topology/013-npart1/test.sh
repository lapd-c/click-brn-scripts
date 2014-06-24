#!/bin/bash

if [ $# -le 0 ]
then
	echo "usage: $0 number_of_runs"
	exit -1
fi

# Settings
PLACEMENT_PATH="placementfile.plm"
RESULT_PATH="test-result.csv"
RUNS=$1
ETXLIMIT=$2
export ETXLIMIT


echo "overwrite placement file ${PLACEMENT_PATH}"
echo "overwrite result file ${RESULT_PATH}"
echo "simulate ${RUNS} runs"
if [ "x${ETXLIMIT}" == "x" ]
then
	echo "don't use ETX-metric limit"
else
	echo "use ETX-metric limit max(${ETXLIMIT})"
fi
read -p "Do you want start a test with these settings?   ....(Ctrl+C to abort)"


for RUN in $(seq ${RUNS})
do
	i=1
	while [ -e "./$i" ]; do i=$((i+1)); done;
	SIM_RESULT_DIR=${i}
	echo "next simulation result dir: ${SIM_RESULT_DIR}"

	#
	# Create NPart placement
	#
	echo "create NPart placement..."
	echo "  output file: ${PLACEMENT_PATH}"
	OPWD=$(pwd)
	cd ../../../../helper/src/Npart
	NUM_OF_NODES=100
	RXRANGE=230  ./gen_topo.sh ${NUM_OF_NODES}  2>/dev/null > /tmp/${PLACEMENT_PATH}
	RESULT=$?
	cd ${OPWD}
	cat /tmp/${PLACEMENT_PATH} | awk -F " " '{print "sk"NR,$2,$3,$4}' > ${PLACEMENT_PATH}
	
	if [ "${RESULT}" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	
	
	#
	# Update mes
	#
	echo "update .mes file..."
	NODE_COUNT=$(wc -l ${PLACEMENT_PATH} | awk -F " " '{ print $1}')
	echo "  new node count: ${NODE_COUNT}"
	mv simpleflow.mes simpleflow-orig.mes
	cat simpleflow-orig.mes | sed "s/:[0-9]*/:${NODE_COUNT}/" > simpleflow.mes
	if [ "$?" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	
	#
	# simulate placement
	#
	echo "run simulation to get link-graph..."
	run_sim.sh
	RESULT=$?
	if [ "${RESULT}" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	
	
	#
	# extract largest component of link-graph and save this as new placement
	#
	echo "extract larges component of link-graph as new placement..."
	cd ${SIM_RESULT_DIR}
	../../common_evaluation/extract_largest_component_of_graph.R 1>/dev/null
	if [ "$?" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	../../common_evaluation/sub_placement.py --nodes=nodes.csv --list=nodes_of_largest_component.csv --rename > ../${PLACEMENT_PATH}
	if [ "$?" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	cd ..
	mv ${i} "${i}-pre"
	
	#
	# Update mes
	#
	echo "update .mes file..."
	NODE_COUNT=$(wc -l ${PLACEMENT_PATH} | awk -F " " '{ print $1}')
	echo "  new node count: ${NODE_COUNT}"
	mv simpleflow.mes simpleflow-orig.mes
	cat simpleflow-orig.mes | sed "s/:[0-9]*/:${NODE_COUNT}/" > simpleflow.mes
	if [ "$?" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
	
	#
	# simulate placement
	#
	echo "run simulation..."
	run_sim.sh
	RESULT=$?
	if [ "${RESULT}" -ne 0 ] 
	then
		echo "result: failed"
		exit -1
	fi
done

#
# Process results
#
echo "process results..."
echo "  ...write ${RESULT_PATH}"
../common_evaluation/collect_results.sh > ${RESULT_PATH}

echo "Done"