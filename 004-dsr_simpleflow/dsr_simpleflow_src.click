#define DEBUGLEVEL 2

//#define WIFIDEV_LINKSTAT_DEBUG
//#define ENABLE_DSR_DEBUG

#define CST cst
#define CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#include "brn/brn.click"
#include "device/wifidev_linkstat.click"
#include "routing/dsr.click"

BRNAddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(wireless);

rc::Brn2RouteCache(DEBUG 0, ACTIVE true, DROP /* 1/20 = 5% */ 0, SLICE /* 100ms */ 0, TTL /* 4*100ms */4);
lt::Brn2LinkTable(NODEIDENTITY id, ROUTECACHE rc, STALE 500,  SIMULATE false, CONSTMETRIC 1, MIN_LINK_METRIC_IN_ROUTE 9998);

device_wifi::WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);

dsr::DSR(id,lt,rc);

#ifndef SIMULATION
sys_info::SystemInfo(NODEIDENTITY id);
#endif

device_wifi
  -> Label_brnether::Null()
  -> BRN2EtherDecap()
  -> brn_clf::Classifier(    0/BRN_PORT_DSR,  //BrnDSR
                             0/BRN_PORT_FLOW, //SimpleFlow
                               -  );//other

brn_clf[0]
//-> Print("DSR-Packet")
  -> [1]dsr;

device_wifi[1]
//-> Print("BRN-In")
  -> BRN2EtherDecap()
  -> brn_clf;
  
device_wifi[2]
  -> Discard;

Idle
  -> [2]dsr;

brn_clf[1]
//-> Print("rx")
  -> BRN2Decap()
  -> sf::BRN2SimpleFlow(SRCADDRESS deviceaddress, DSTADDRESS 00:00:00:00:00:0c,
                        RATE 1000 , SIZE 100, MODE 0, DURATION 20000,ACTIVE 0, HEADROOM 144)
  -> BRN2EtherEncap()
//-> Print("Raus damit")
  -> [0]dsr;

brn_clf[2]
  -> Discard;

dsr[0]
  -> toMeAfterDsr::BRN2ToThisNode(NODEIDENTITY id);

dsr[1]
//-> Print("DSR[1]-out")
  -> BRN2EtherEncap()
  -> SetEtherAddr(SRC deviceaddress)
//-> Print("DSR-Ether-OUT")
  -> [0]device_wifi;

toMeAfterDsr[0]
  -> Print("DSR-out: For ME")
  -> Label_brnether; 
  
toMeAfterDsr[1]
  -> Print("DSR-out: Broadcast")
  -> Discard;

toMeAfterDsr[2]
  -> Print("DSR-out: Foreign/Client")
  -> [1]device_wifi;

Script(
#ifdef ENABLE_DSR_DEBUG
  write dsr/querier.debug 4,
  write dsr/req_forwarder.debug 4,
  write dsr/rep_forwarder.debug 4,
#endif
  wait  100,
  read  lt.links,
  write sf.active 1,
  wait  19,
  read  sf.txflows,
  read  sf.rxflows,
  read  lt.routes
);
