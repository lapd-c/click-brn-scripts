#define DEBUGLEVEL 2

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/rawwifidev.click"

AddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

wifidevice::RAWWIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless);

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

ps::BRN2PacketSource(SIZE 2200, INTERVAL 12, MAXSEQ 500000, BURST 1, ACTIVE true)
  -> EtherEncap(0x8086, deviceaddress, ff:ff:ff:ff:ff:ff)
  -> WifiEncap(0x00, 0:0:0:0:0:0)
  -> SetTXRates(RATE0 12, TRIES0 1, TRIES1 0, TRIES2 0, TRIES3 0)
  -> SetTXPower(12)
  -> wifioutq::NotifierQueue(1000)
  -> wifidevice
  -> discard::Discard