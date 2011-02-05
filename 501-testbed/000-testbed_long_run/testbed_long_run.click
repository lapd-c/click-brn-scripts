#define DEBUGLEVEL 2

//#define WIFIDEV_LINKSTAT_DEBUG
//#define ENABLE_DSR_DEBUG

//#define SETCHANNEL

#define CST cst
#define CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/wifidev_linkstat.click"
#include "routing/dsr.click"
#include "dht/routing/dht_dart.click"
#include "dht/routing/dht_falcon.click"
#include "dht/routing/dht_klibs.click"
#include "dht/routing/dht_omni.click"
#include "dht/storage/dht_storage.click"

BRNAddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

rc::Brn2RouteCache(DEBUG 0, ACTIVE true, DROP /* 1/20 = 5% */ 0, SLICE /* 100ms */ 0, TTL /* 4*100ms */4);
lt::Brn2LinkTable(NODEIDENTITY id, ROUTECACHE rc, STALE 500,  SIMULATE false, CONSTMETRIC 1, MIN_LINK_METRIC_IN_ROUTE 9998);

device_wifi::WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);

//lpr::LPRLinkProbeHandler(LINKSTAT device_wifi/link_stat, ETXMETRIC device_wifi/etx_metric);

routing::DSR(id,lt,rc,device_wifi/etx_metric);

dht::DHT_FALCON(ETHERADDRESS deviceaddress, LINKSTAT device_wifi/link_stat, STARTTIME 100000, UPDATEINT 3000, DEBUG 2);
//dht::DHT_OMNI(ETHERADDRESS deviceaddress, LINKSTAT device_wifi/link_stat, STARTTIME 10000, UPDATEINT 1000, DEBUG 2);
//dht::DHT_KLIBS(ETHERADDRESS deviceaddress, LINKSTAT device_wifi/link_stat, STARTTIME 10000, UPDATEINT 1000, DEBUG 2);
//dht::DHT_DART(ETHERADDRESS deviceaddress, LINKSTAT device_wifi/link_stat, STARTTIME 10000, UPDATEINT 1000, DEBUG 2);

dhtstorage :: DHT_STORAGE( DHTROUTING dht/dhtrouting, DEBUG 2);
//dhtstoragetest :: DHTStorageTest( DHTSTORAGE dhtstorage/dhtstorage, STARTTIME 175000, INTERVAL 1000, COUNTKEYS 10, WRITE false, RETRIES 1, REPLICA 0, DEBUG 2);

#ifndef SIMULATION
sys_info::SystemInfo(NODEIDENTITY id);
#endif

device_wifi
  -> Label_brnether::Null()
  -> BRN2EtherDecap()
//-> Print("Foo",100)
  -> brn_clf::Classifier(    0/BRN_PORT_DSR,  //BrnDSR
                             0/BRN_PORT_FLOW, //Simpleflow
                             0/BRN_PORT_DHTROUTING,  //DHT-Routing
                             0/BRN_PORT_DHTSTORAGE,  //DHT-Storage
                               -  );//other

brn_clf[0]
//-> Print("DSR-Packet")
  ->  [1]routing;

device_wifi[1] -> /*Print("BRN-In") -> */ BRN2EtherDecap() -> brn_clf;
device_wifi[2] -> Discard;

Idle -> [2]routing;

brn_clf[1]
//-> Print("rx")
-> BRN2Decap()
-> sf::BRN2SimpleFlow(HEADROOM 192, DEBUG 4)
-> BRN2EtherEncap(USEANNO true)
-> [0]routing;

brn_clf[2]
-> BRN2Decap()
-> [0]dht[0]
-> [0]routing;

brn_clf[3]
-> BRN2Decap()
-> dhtstorage
-> [0]routing;

brn_clf[4] -> Discard;

dht[1] -> [0]device_wifi;

routing[0] -> toMeAfterRouting::BRN2ToThisNode(NODEIDENTITY id);
routing[1] /*-> Print("Routing[1]-out")*/ -> BRN2EtherEncap() -> SetEtherAddr(SRC deviceaddress) /*-> Print("Routing-Ether-OUT")*/ -> [0]device_wifi;

toMeAfterRouting[0] -> /*Print("Routing-out: For ME",100) ->*/ Label_brnether; 
toMeAfterRouting[1] -> /*Print("Routing-out: Broadcast") ->*/ Discard;
toMeAfterRouting[2] -> /*Print("Routing-out: Foreign/Client") ->*/ [1]device_wifi;

Script(
 wait 120,
 read  dht/dhtrouting.routing_info
);
