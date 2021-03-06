#include "wifi/access_point.click"
#include "device/wep.click"

//output:
//  0: To me and BRN
//  1: Broadcast and BRN
//  2: Foreign and BRN
//  3: To me and NO BRN
//  4: BROADCAST and NO BRN
//  5: Foreign and NO BRN
//
//  6: to underlying layer
//
//input::
//  0: brn
//  1: client
//  2: high priority stuff
//
//  3: from underlying layer

/*
 * Dieses Device besitzt aus historischen Gründen mehrere Funktionen. Es behandelt Pakete
 * aus den unterschiedlichsten Netzwerkschichten, um z. B. das Leistungsverhalten zu verbessern
 * oder besondere Informationen (z. B. Statistik, Analyse) zu erhalten. Daher sind die
 * Herkunftsort von Paketen, die über das Device transportiert werden sollen, aus 5
 * verschiedenen Quellen:
 * 1. Linkstat: Linkprobing-Pakete
 * 2. Interferenzgraph: Pakete werden erzeugt, um die Stärke von Interferenz auszumessen
 * 		// todo: mittels 3. realisieren
 * 3. UpperLayer-Wififrames: Hier kommen wififrames von oben
 * 4. Mesh: Pakete, die für das Maschennetzwerk sind.
 * 5. Client: Pakete für Clienten.
 */



elementclass WIFIDEV_AP { DEVICE $device, ETHERADDRESS $etheraddress, SSID $ssid,
#ifdef VLAN_ENABLE
                          CHANNEL $channel, LT $lt, VLANTABLE $vlt |
#else
                          CHANNEL $channel, LT $lt |
#endif

//#warning Fix NBList in wifidev_ap
//  nblist::BRN2NBList(NODEID );  //stores all neighbors (known (friend) and unknown (foreign))
//  nbdetect::NeighborDetect(NBLIST nblist);

  rates::BrnAvailableRates(DEFAULT 2 4 11 12 18 22 24 36 48 72 96 108);

#ifdef LINKSTAT_ENABLE
  proberates::BrnAvailableRates(DEFAULT 2 22);
  etx_metric :: BRN2ETXMetric($lt);
  
  link_stat :: BRN2LinkStat(ETHTYPE          0x0a04,
                            DEVICE          $device,
                            PERIOD             3000,
                            TAU               30000,
                            METRIC     "etx_metric",
//                          PROBES  "2 250 24 22 1000 24",
                            PROBES  "2 250 24",
                            RT           proberates);
#endif

#ifdef VLAN_ENABLE
  ap::ACCESS_POINT(DEVICE $device, ETHERADDRESS $etheraddress, SSID $ssid, CHANNEL $channel, BEACON_INTERVAL 100, LT $lt, RATES rates, VLANTABLE $vlt);
#else
  ap::ACCESS_POINT(DEVICE $device, ETHERADDRESS $etheraddress, SSID $ssid, CHANNEL $channel, BEACON_INTERVAL 100, LT $lt, RATES rates);
#endif

  toStation::BRN2ToStations(ASSOCLIST ap/assoclist);
  toAP::BRN2ToThisNode(NODEIDENTITY id);
  toMe::BRN2ToThisNode(NODEIDENTITY id);


  wep					:: Wep(KEY "weizenbaum", ACTIVE true, DEBUG true);
  //is_TLS 				:: Classifier(25/aa,-);



  to_underlying_layer::Null()
  -> [6]output; 


  input[0] 
  -> WifiEncap(0x00, 0:0:0:0:0:0)
  -> wep
  -> to_underlying_layer;
  
  input[2]
  -> filter_tx :: FilterTX()
#if WIFITYPE == 805
  -> error_clf :: WifiErrorClassifier()
#else
  -> error_clf :: FilterPhyErr()
#endif
#ifndef DISABLE_WIFIDUBFILTER
  -> WifiDupeFilter()
#endif
  -> [1]wep[1]
   -> wififrame_clf :: Classifier(0/00%0f,  // management frames
                                   1/01%03,  //tods
                                       - );

  wififrame_clf[0]
    -> fb::FilterBSSID(ACTIVE true, DEBUG 1, WIRELESS_INFO ap/winfo)
    -> ap

    -> to_underlying_layer;

  fb[1]
    -> Classifier( 16/ffffffffffff )
    -> ap;

  wififrame_clf[1]
    //-> Print("Filter",TIMESTAMP true)
    -> fbssid::FilterBSSID(ACTIVE true, DEBUG 1, WIRELESS_INFO ap/winfo)
    -> WifiDecap()
//  -> nbdetect
    //-> Print("Data",TIMESTAMP true)
    -> toStation[2]    //no station, no broadcast
    -> toAP[0]         //it's me
    -> brn_ap_clf :: Classifier( 12/8086, - )
    -> [0]output;


  toStation[0]
    //-> Print("For a Station",TIMESTAMP true)
    -> clientwifi::WifiEncap(0x02, WIRELESS_INFO ap/winfo)
    //-> Print("Und wieder raus",TIMESTAMP true)
    -> to_underlying_layer;

  toStation[1]                
    //-> Print("Broadcast",TIMESTAMP true)
    -> brn_ap_clf;
    
    toAP[1] 
    //-> Print("a")
    -> brn_ap_clf;
    
    toAP[2]
    //-> Print("b")
    -> [2]output;
    
    brn_ap_clf[1] -> [3]output;
        
  wififrame_clf[2]
    -> WifiDecap()
    -> toMe[1]          //it's broadcast
    -> brn_bc_clf :: Classifier( 12/8086, - );
  
  brn_bc_clf[0]
    -> lp_clf :: Classifier( 14/BRN_PORT_LINK_PROBE, - )
#ifdef LINKSTAT_ENABLE
    -> BRN2EtherDecap()
    -> link_stat
    -> EtherEncap(0x8086, deviceaddress, ff:ff:ff:ff:ff:ff)
    -> power::SetTXPower(15)
    -> WifiEncap(0x00, 0:0:0:0:0:0)
    -> to_underlying_layer;
#else
    -> Discard;
#endif

  lp_clf[1]
  -> [1]output;
  
  brn_bc_clf[1]
  -> [4]output;

  toMe[0]         //it's me
  -> brn_ether_clf :: Classifier( 12/8086, - )
  -> [0]output;
  
  brn_ether_clf[1]                        //For  me or broadcast and no BRN
  -> Discard;
  
  
  toMe[2]         //Foreign
  -> foreign_brn_ether_clf :: Classifier( 12/8086, - )
  //-> Print("BRN for a foreign station")
  -> Discard;//[2]output;
     
  foreign_brn_ether_clf[1]
  //-> Print("For a foreign station")
  -> Discard; //-> [5]output;
    
                          
  input[1] /*-> Print("TO STATIOM")*/ -> fromNodetoStation::BRN2ToStations(ASSOCLIST ap/assoclist);
  
  fromNodetoStation[0]  //For Station
  //-> Print("for station")
  -> clientwifi;
  
  fromNodetoStation[1]  //Broadcast
  //-> Print("broadcast")
  -> clientwifi;
  
  fromNodetoStation[2]  //For Unknown
  //-> Print("for unknown")
  -> Discard;

  Idle -> [1]ap[1] -> Discard;
  Idle -> [2]ap[2] -> Discard;
 
  Idle -> [5]output;
} 

