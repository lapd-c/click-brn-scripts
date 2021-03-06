#! /bin/bash

cp multibox3/flooding.ctl flooding.ctl;
cp multibox3/flooding.des flooding.des;
cp multibox3/flooding.mes flooding.mes;
cp multibox3/multibox3.plm multibox3.plm;

sed 's/circles1_1/multibox3_5_75_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_5_75_5000_bd;
echo "5_75_5000 done";
sed 's/circles1_1/multibox3_10_75_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_10_75_5000_bd;
echo "10_75_5000 done";
sed 's/circles1_1/multibox3_15_75_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_15_75_5000_bd;
echo "15_75_5000 done";
sed 's/circles1_1/multibox3_20_75_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_20_75_5000_bd;
echo "20_75_5000 done";
sed 's/circles1_1/multibox3_5_85_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_5_85_5000_bd;
echo "5_85_5000 done";
sed 's/circles1_1/multibox3_10_85_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_10_85_5000_bd;
echo "10_85_5000 done";
sed 's/circles1_1/multibox3_15_85_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_15_85_5000_bd;
echo "15_85_5000 done";
sed 's/circles1_1/multibox3_20_85_5000/g' < multibox3/flooding_bd.click > flooding.click;
run_sim.sh ns flooding.des multibox3_20_85_5000_bd;
echo "20_85_5000 done";

tar -czvf multibox3bd.tgz multibox3_*;
rm -rf multibox3_*;
