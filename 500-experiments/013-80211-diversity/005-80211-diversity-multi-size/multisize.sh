#!/bin/sh

PACKETSIZE="10 30 50 60 70 80 90 110"
#PACKETSIZE="68 58 48 38 33 32 28 18 10"
#PACKETSIZE="10 18 28 32 33 38 48 58 68"
#PACKETSIZE="18 68 168 468 968 1468 1968 2168"
INTERVAL="25"
PACKETCOUNT="10000"
#RATES="g1 n1 n2 n3 n4 n5 n6 n7 n8"
RATES="n4"

CHANNEL="44"

REPEAT=1

CURRENT_RUNMODE=REBOOT
CURRENT_RUNMODE=CLICK

MEASUREMENT_NUM=1

for p_repeat in `seq $REPEAT`; do

 for p_c in $CHANNEL; do

#  for p_node in `cat nodes.all | grep -v "#"`; do
  for p_node in wndr233; do

    if [ ! -e $MEASUREMENT_NUM ]; then

      cat nodes.all | grep -v "$p_node" | grep -v "#" > nodes

      RUNTIME=`expr $INTERVAL \* $PACKETCOUNT`
      RUNTIME=`expr $RUNTIME / 800`

      cat sender_and_receiver.des.tmpl | sed -e "s#PARAMS_TIME#$RUNTIME#g" > sender_and_receiver.des

      cp  probe_sender.click.tmpl probe_sender.click

      if [ $p_c -lt 15 ]; then
        POWER=27
        cat monitor.802.tmpl |  sed -e "s#PARAMS_CHANNEL#$p_c#g" -e "s#PARAMS_POWER#$POWER#g" > monitor.802
        cat sender_and_receiver.mes.tmpl | sed -e "s#PARAMS_DEVICE#wlan0#g" -e "s#SENDERNODE#$p_node#g" > sender_and_receiver.mes
#	echo "Idle() -> ee_b1;" >> probe_sender.click
      else
        POWER=30
        cat monitor.802.tmpl |  sed -e "s#PARAMS_CHANNEL#$p_c#g" -e "s#PARAMS_POWER#$POWER#g" > monitor.802
        cat sender_and_receiver.mes.tmpl | sed -e "s#PARAMS_DEVICE#wlan1#g" -e "s#SENDERNODE#$p_node#g" > sender_and_receiver.mes
#	echo "Idle() -> ee_b1;" >> probe_sender.click
      fi

      PSID=0

      for p_s in $PACKETSIZE; do
        for p_rate in $RATES; do
      
          if [ $p_c -gt 15 ] && [ "$p_rate" = "b1" ]; then
	    echo "//disable 1MBIT" >> probe_sender.click
	  else
            echo "ps_$PSID::BRN2PacketSource(SIZE $p_s, INTERVAL $INTERVAL, MAXSEQ 500000, BURST 1, PACKETCOUNT $PACKETCOUNT, ACTIVE true) -> ee_$p_rate;" >> probe_sender.click
	    PSID=`expr $PSID + 1`
          fi

        done
      done

      #TESTONLY=0 
      RUNMODE=$CURRENT_RUNMODE run_measurement.sh sender_and_receiver.des $MEASUREMENT_NUM

      echo "PARAMS_CHANNEL=$p_c" > $MEASUREMENT_NUM/params
      echo "PARAMS_REPEAT=$p_repeat" >> $MEASUREMENT_NUM/params
      echo "PARAMS_INTERVAL=$INTERVAL" >> $MEASUREMENT_NUM/params
      echo "PARAMS_SENDER=$p_node" >> $MEASUREMENT_NUM/params
      echo "PARAMS_PACKETCOUNT=$PACKETCOUNT" >> $MEASUREMENT_NUM/params

 
      rm -f monitor.802 probe_sender.click sender_and_receiver.des sender_and_receiver.mes nodes
#      rm -f monitor.802 sender_and_receiver.des sender_and_receiver.mes nodes

      if [ -f finish ]; then
        exit 0;
      fi

      CURRENT_RUNMODE=CLICK
    fi

    MEASUREMENT_NUM=`expr $MEASUREMENT_NUM + 1`

   done
  CURRENT_RUNMODE=REBOOT
 done
done
