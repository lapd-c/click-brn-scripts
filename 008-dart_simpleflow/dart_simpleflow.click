#define DEBUGLEVEL 2

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/wifidev_linkstat.click"
#include "dht/routing/dht_dart.click"
#include "dht/storage/dht_storage.click"
#include "routing/dart.click"

BRNAddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

rc::Brn2RouteCache(DEBUG 0, ACTIVE false, DROP /* 1/20 = 5% */ 0, SLICE /* 100ms */ 0, TTL /* 4*100ms */4);
lt::Brn2LinkTable(NODEIDENTITY id, ROUTECACHE rc, STALE 500,  SIMULATE false, CONSTMETRIC 1, MIN_LINK_METRIC_IN_ROUTE 15000);

device_wifi::WIFIDEV(DEVNAME eth0, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);


dht::DHT_DART(ETHERADDRESS deviceaddress, LINKSTAT device_wifi/link_stat, STARTTIME 10000, UPDATEINT 3000, DEBUG 4);
dhtstorage::DHT_STORAGE( DHTROUTING dht/dhtrouting, DEBUG 4 );
dart::DART(id, dht/dhtroutingtable, dhtstorage/dhtstorage, dht/dhtrouting);

device_wifi
-> Label_brnether::Null()
-> BRN2EtherDecap()
-> brn_clf::Classifier(    0/BRN_PORT_DHTROUTING,  //DHT-Routing
                           0/BRN_PORT_DHTSTORAGE,  //DHT-Storage
                           0/BRN_PORT_DART,        //DART
                           0/BRN_PORT_FLOW,        //SimpleFlow
                             -  );//other
                                    

device_wifi[1] -> /*Print("BRN-In") -> */ BRN2EtherDecap() -> brn_clf;
device_wifi[2] -> Discard;

brn_clf[0]
//-> Print("Routing-Packet",100)
-> BRN2Decap()
-> [0]dht[0]
-> dht_r_all::Counter()
//-> Print("out Routing-Packet")
-> [0]dart;

brn_clf[1]
//-> Print("Storage-Packet")
-> BRN2Decap()
-> dhtstorage
-> dht_s::Counter()
//-> Print("Storage-Packet-out")
-> [0]dart;

brn_clf[2] -> [1]dart;

brn_clf[4] -> Discard;

dht[1]
//-> Print("routing-Packet-out")
-> dht_r_neighbour::Counter()
-> [0]device_wifi;

brn_clf[3]
-> BRN2Decap()
-> sf::BRN2SimpleFlow()
-> BRN2EtherEncap(USEANNO true)
-> Print("Foo")
-> [0]dart;

dart[0] /*-> Print("Dart out")*/ -> BRN2EtherEncap() /*-> Print("Dart out ether")*/ -> [0]device_wifi;
dart[1] -> Label_brnether;

Idle 
->[1]device_wifi;

Idle
-> [2]dart;

Script(
  wait 30,
  read lt.links,
  wait 30, 
  read dht/dhtrouting.routing_info,
  wait 20, 
  //read  dhtstorage.db_size,
  //read  dhtstoragetest.stats,
  read  dht/dhtrouting.routing_info,
  wait 10,
  //read  dhtstorage/dhtstorage.db_size,
  //read  dhtstoragetest.stats,
  //read  dht/dhtrouting.routing_info
  //read dht_r_all.count,
  //read dht_r_all.byte_count,
  //read dht_r_neighbour.count,
  //read dht_r_neighbour.byte_count,
  //read dht_s.count,
  //read dht_s.byte_count,
  read  sf.stats
);