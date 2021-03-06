#define DEBUGLEVEL 2
#define LINKSTAT_ENABLE

#include "brn/brn.click"
#include "device/wifidev_ap.click"
#include "routing/dsr.click"

AddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME "NODENAME", DEVICES wireless);

lt::Brn2LinkTable(NODEIDENTITY id, STALE 500, DEBUG 2);
routingtable::BrnRoutingTable(DEBUG 0, ACTIVE false, DROP /* 1/20 = 5% */ 0, SLICE /* 100ms */ 0, TTL /* 4*100ms */4);
routingalgo::Dijkstra(NODEIDENTITY id, LINKTABLE lt, MIN_LINK_METRIC_IN_ROUTE 6000, MAXGRAPHAGE 30000, DEBUG 2);
routingmaint::RoutingMaintenance(NODEIDENTITY id, LINKTABLE lt, ROUTETABLE routingtable, ROUTINGALGORITHM routingalgo, DEBUG 2);

device_wifi::WIFIDEV_AP(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, SSID "brn", CHANNEL 5, LT lt);

dsr::DSR(id, lt, device_wifi/etx_metric,routingmaint);

device_wifi
  -> Label_brnether::Null()
  -> BRN2EtherDecap()
//-> Print("Foo",100)
  -> brn_clf::Classifier(    0/BRN_PORT_DSR,  //BrnDSR
                               -  );//other
                               
device_wifi[1]       //broadcast and brn
//-> Print("BRN-In")
  -> BRN2EtherDecap()
  -> brn_clf;

device_wifi[2] /*-> Print("NODENAME: For and brn", TIMESTAMP true)*/ -> [0]dsr;  //foreign and brn

device_wifi[3] -> Discard;  //to me no brn
device_wifi[4] -> Discard;  //broadcast and no brn

device_wifi[5] //foreign and no brn
 -> [0]dsr;

brn_clf[0]
  //-> Print("DSR-Packet")
  -> [1]dsr;

dsr[0]
  -> toMeAfterDsr::BRN2ToThisNode(NODEIDENTITY id);

dsr[1]
  //-> Print("DSR[1]-out")
  -> BRN2EtherEncap(SRC deviceaddress, PUSHHEADER false)
  //-> Print("DSR-Ether-OUT")
  -> [0]device_wifi;

toMeAfterDsr[0] 
  //-> Print("DSR-out: For ME",100)
  -> Label_brnether; 
  
toMeAfterDsr[1]
  //-> Print("DSR-out: Broadcast")
  -> Discard;

toMeAfterDsr[2]
  //-> Print("DSR-out: Foreign/Client")
  -> [1]device_wifi;

Idle -> [2]dsr;
brn_clf[1] -> Discard;

Idle -> [3]dsr;
Idle -> [4]dsr;

Script(
  wait 10,
  read device_wifi/ap/assoclist.stations,
  read lt.links
);

//#define ENABLE_DSR_DEBUG
Script(
#ifdef ENABLE_DSR_DEBUG
  write dsr/querier.debug 4,
  write dsr/req_forwarder.debug 4,
  write dsr/rep_forwarder.debug 4,
  write dsr/err_forwarder.debug 4
#endif
);
	
