#!/bin/sh

CHANNEL="1 2 3 4 5 6 7 8 9 10 11"
#CHANNEL="1 2"

REPETITIONS=15

MEASUREMENT_NUM=1

for r in `seq $REPETITIONS`; do

 for p_c in $CHANNEL; do

  if [ ! -e MEASUREMENT_NUM ]; then

    cp monitor.cfg.tmpl monitor.cfg
    echo "CHANNEL=$p_c" >> monitor.cfg

    if [ "x$SIM" = "x" ]; then
      RUNMODE=REBOOT run_measurement.sh sender_and_receiver.des $MEASUREMENT_NUM
    else
      run_sim.sh ns sender_and_receiver.des $MEASUREMENT_NUM
    fi

    echo "CHANNEL=$p_c" > $MEASUREMENT_NUM/params
    echo "REPETITION=$r" >> $MEASUREMENT_NUM/params
    echo "NUM=$MEASUREMENT_NUM" >> $MEASUREMENT_NUM/params

    MEASUREMENT_NUM=`expr $MEASUREMENT_NUM + 1`

    if [ -f finish ]; then
      exit 0;
    fi

  fi

 done
done
