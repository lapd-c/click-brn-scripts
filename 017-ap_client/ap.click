#define DEBUGLEVEL 2

#include "brn/brn.click"
#include "device/wifidev_ap.click"

AddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

lt::Brn2LinkTable(NODEIDENTITY id, STALE 500);

device_wifi::WIFIDEV_AP(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, SSID "brn", CHANNEL 5, LT lt);

device_wifi
-> BRN2EtherDecap()
-> Discard;

device_wifi[1] -> BRN2EtherDecap() -> Discard;
device_wifi[2] -> Discard;
device_wifi[3] -> Discard;
device_wifi[4] -> Discard;
device_wifi[5] -> Discard;

Idle
-> [0]device_wifi;

Idle
-> [1]device_wifi;

Script(
  wait 5,
  read device_wifi/ap/assoclist.stations,
  read lt.links,
  wait 12,
  read device_wifi/ap/assoclist.stations,
  read lt.links
);
