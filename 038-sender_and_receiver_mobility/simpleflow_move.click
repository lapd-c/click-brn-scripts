#define DEBUGLEVEL 2

//#define WIFIDEV_LINKSTAT_DEBUG
#define ENABLE_DSR_DEBUG

#define CST cst
#define CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/wifidev_linkstat.click"

AddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

lt::Brn2LinkTable(NODEIDENTITY id, STALE 500);

device_wifi::WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);

sys_info::SystemInfo(NODEIDENTITY id, CPUTIMERINTERVAL 1000);

device_wifi
  -> Label_brnether::Null()
  -> BRN2EtherDecap()
  -> brn_clf::Classifier( 0/BRN_PORT_FLOW, //Simpleflow
                               -  );//other

brn_clf[0]
-> BRN2Decap()
-> sf::BRN2SimpleFlow(DEBUG 2)
//-> SetTimestamp()
//-> Print(TIMESTAMP true)
-> BRN2EtherEncap(USEANNO true)
-> [0]device_wifi;

brn_clf[1] -> Discard;

device_wifi[1] -> BRN2EtherDecap() -> brn_clf;
device_wifi[2] -> Discard;

Idle -> [1]device_wifi;

gps::GPS();
mob::Mobility();

Script(
  wait 1,
  read gps.cart_coord,
  loop
 );

Script(
  wait 5,
  write mob.move 199 99 0 10
 );


  