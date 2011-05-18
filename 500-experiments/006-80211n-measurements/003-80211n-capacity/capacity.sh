#!/bin/sh

#ps::BRN2PacketSource(SIZE PARAMS_PACKETSIZE, INTERVAL 10, MAXSEQ 500000, BURST PARAMS_BURST, ACTIVE false)
#rate::SetTXRates( RATE0 PARAMS_RATEINDEX, TRIES0 PARAMS_RETRIES, MCS0 PARAMS_MCS, BW0 PARAMS_BANDWIDTH, SGI0 PARAMS_SGI, GF0 PARAMS_GF, FEC0 0, SP0 true, STBC0 false, DEBUG false )

function get_rate() {
 SHIFT=`expr $1 + 1`

 shift $SHIFT
 echo $1
}

#DST="ff-ff-ff-ff-ff-ff"
#RETRIES="1"
#SENDER="1 3 5"
#CHANNEL="6 153"
#BANDWIDTH="0 1"
#RATEINDEX="0 3 7 8 11 15"
#SGI="false true"
#GF="false true"
#PACKET_SIZE="1500 2200 3800"

DST="ff-ff-ff-ff-ff-ff"
RETRIES="1"
SENDER="1 3 5"
CHANNEL="153"
BANDWIDTH="0 1"
RATEINDEX="0 3 7 8 11 15"
SGI="false true"
GF="true"
PACKET_SIZE="500 1500 2200 3800"

MCS="true"

CURRENT_RUNMODE=REBOOT

MEASUREMENT_NUM=1

for p_c in $CHANNEL; do

 for p_s in $SENDER; do

  for p_bw in $BANDWIDTH; do

   for p_dst in $DST; do

    for p_r in $RETRIES; do

     for p_ri in $RATEINDEX; do

      for p_sg in $SGI; do

       for p_gf in $GF; do

        for p_ps in $PACKET_SIZE; do

        # don't use sg with ht40
        if [ "x$p_sg" == "xfalse" ] || [ "x$p_bw" == "x1" ]; then
         if [ "x$p_dst" != "xff-ff-ff-ff-ff-ff" ] || [ "x$p_r" == "x1" ]; then

          if [ ! -e $MEASUREMENT_NUM ]; then

           SHIFT=4
           INDEX=`expr $p_ri + 1`
           baserate=`cat ratetable | head -n $INDEX | tail -n 1`

           if [ $p_bw -eq 1 ]; then
             SHIFT=`expr $SHIFT + 2`
           fi

           if [ "x$p_sg" == "xtrue" ]; then
             SHIFT=`expr $SHIFT + 1`
           fi

           p_datarate=`get_rate $SHIFT $baserate`
           p_burst=`calc "round($p_datarate * 1250 / ( $p_ps * $p_s * $p_r ) )" | awk '{print $1}'`

           #echo "$baserate $p_datarate $p_ps $p_burst"

           SEDARG=" -e s#PARAMS_RATEINDEX#$p_ri#g -e s#PARAMS_BANDWIDTH#$p_bw#g -e s#PARAMS_SGI#$p_sg#g -e s#PARAMS_GF#$p_gf#g"
	   SEDARG=" $SEDARG -e s#PARAMS_PACKETSIZE#$p_ps#g -e s#PARAMS_BURST#$p_burst#g -e s#PARAMS_DST#$p_dst#g -e s#PARAMS_RETRIES#$p_r#g"
	   SEDARG=" $SEDARG -e s#PARAMS_MCS#$MCS#g"

           if [ $p_c -lt 15 ]; then
             cat monitor.802.tmpl |  sed -e "s#PARAMS_CHANNEL#6#g" -e "s#PARAMS_POWER#27#g" > monitor.802
	     cat sender_and_receiver.mes.tmpl | sed -e "s#PARAMS_DEVICE#wlan0#g" > sender_and_receiver.mes
	   else
             cat monitor.802.tmpl |  sed -e "s#PARAMS_CHANNEL#153#g" -e "s#PARAMS_POWER#30#g" > monitor.802
	     cat sender_and_receiver.mes.tmpl | sed -e "s#PARAMS_DEVICE#wlan1#g" > sender_and_receiver.mes
           fi

           if [ $p_bw -eq 1 ]; then
             echo "HTMODE=\"HT40-\"" >> monitor.802
           fi

	   cat sender.click.tmpl | sed $SEDARG > sender.click

           RECEIVER=`cat receiver`
	   
	   cat all_nodes | grep -v "#" | grep -v $RECEIVER | head -n $p_s > sender

           #rm -rf $MEASUREMENT_NUM
	   #mkdir $MEASUREMENT_NUM
	   RUNMODE=$CURRENT_RUNMODE run_measurement.sh sender_and_receiver.des $MEASUREMENT_NUM

	   echo "PARAMS_RATEINDEX=$p_ri" > $MEASUREMENT_NUM/params
	   echo "PARAMS_BANDWIDTH=$p_bw" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_SGI=$p_sg" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_GF=$p_gf" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_CHANNEL=$p_c" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_PACKETSIZE=$p_ps" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_DATARATE=$p_datarate" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_NO_SENDER=$p_s" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_BURST=$p_burst" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_RETRIES=$p_r" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_DST=$p_dst" >> $MEASUREMENT_NUM/params
	   echo "PARAMS_MCS=$MCS" >> $MEASUREMENT_NUM/params

	
  	   CURRENT_RUNMODE=CLICK
	  fi
        
          MEASUREMENT_NUM=`expr $MEASUREMENT_NUM + 1`

	  if [ -f finish ]; then
	    exit 0;
	  fi
	 
         fi
        fi
        done
       done
      done
     done
    done
   done

   CURRENT_RUNMODE=REBOOT

  done
 done
done


