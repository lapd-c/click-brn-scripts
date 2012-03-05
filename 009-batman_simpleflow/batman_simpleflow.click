#define DEBUGLEVEL 2

//#define WIFIDEV_LINKSTAT_DEBUG
#define ENABLE_BATMAN_DEBUG

//#define CST cst
//#define CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#define BRNFEEDBACK

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/wifidev_linkstat.click"
#include "routing/batman.click"

BRNAddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

lt::Brn2LinkTable(NODEIDENTITY id, STALE 500);

device_wifi::WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);

batman::BATMAN(id,lt);

#ifndef SIMULATION
sys_info::SystemInfo(NODEIDENTITY id, CPUTIMERINTERVAL 1000);
#endif

device_wifi
  -> Label_brnether::Null()
  -> BRN2EtherDecap()
  -> brn_clf::Classifier(    0/BRN_PORT_BATMAN,  //BATMAN
                             0/BRN_PORT_FLOW,    //SimpleFlow
                               -  );//other
                                    
brn_clf[0]
//  -> Print("NODENAME: Batman-Packet", TIMESTAMP true)
  -> [1]batman;

device_wifi[1] -> /*Print("BRN-In") -> */ BRN2EtherDecap() -> brn_clf;
device_wifi[2] -> Discard;
device_wifi[3] -> ff::FilterFailures() -> Discard;
ff[1] /*-> Print("TxFailed")*/ -> BRN2EtherDecap() -> [2]batman;

brn_clf[1]
//-> Print("rx")
-> BRN2Decap()
-> sf::BRN2SimpleFlow(HEADROOM 192)
-> BRN2EtherEncap(USEANNO true)
-> [0]batman;

brn_clf[2]
  -> Discard;

batman[0]
  -> toMeAfterDsr::BRN2ToThisNode(NODEIDENTITY id);

batman[1]
//-> Print("DSR-Ether-OUT")
  -> [0]device_wifi;

toMeAfterDsr[0]
//-> Print("DSR-out: For ME")
  -> Label_brnether; 
  
toMeAfterDsr[1]
//-> Print("DSR-out: Broadcast")
  -> Discard;

toMeAfterDsr[2]
//-> Print("DSR-out: Foreign/Client")
  -> [1]device_wifi;

Idle
-> [3]batman;

Script(
//  write sf.debug 4,
#ifdef ENABLE_BATMAN_DEBUG
  write batman/bofwd.debug 4,
  write batman/bf.debug 4,
  write batman/br.debug 4,
#endif
//  wait 40,
//  read batman/brt.nodes,
    wait 200,
    read batman/brt.nodes,
    wait 17,
    read batman/bfd.info,    
    wait 1,
    read batman/bofwd.links,    
    wait 1,
    stop
);
