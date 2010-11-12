#define DEBUGLEVEL 2

#include "brn/brn.click"
#include "device/wifidev.click"

BRNAddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

wifidevice::WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless);

wifidevice
  -> PrintWifi("Feedback", TIMESTAMP true)
//  -> Print("Feedback")
  -> Discard;

rate::SetTXRates(RATE0 22, RATE1 11, RATE2 4, RATE3 2, TRIES0 3, TRIES1 2, TRIES2 3, TRIES3 2)
-> wifioutq::NotifierQueue(50)
  -> PrintWifi("Sender", TIMESTAMP true)
-> wifidevice;

BRN2PacketSource(SIZE 100, INTERVAL 1000, MAXSEQ 500000, BURST 1)
  -> SetTimestamp()
  -> EtherEncap(0x8086, deviceaddress, ff:ff:ff:ff:ff:ff)
  -> WifiEncap(0x00, 0:0:0:0:0:0)
//  -> PrintWifi("Sender", TIMESTAMP true)
//  -> rate;
-> Discard;

BRN2PacketSource(SIZE 100, INTERVAL 1000, MAXSEQ 500000, BURST 1)
  -> SetTimestamp()
  -> EtherEncap(0x8086, deviceaddress, 00:00:00:00:00:02)
  -> WifiEncap(0x00, 0:0:0:0:0:0)
//  -> PrintWifi("Sender", TIMESTAMP true)
//  -> rate;
-> Discard;

BRN2PacketSource(SIZE 100, INTERVAL 1000, MAXSEQ 500000, BURST 1)
  -> SetTimestamp()
  -> EtherEncap(0x8086, deviceaddress, 00:00:00:00:00:03)
  -> WifiEncap(0x00, 0:0:0:0:0:0)
//  -> PrintWifi("Sender", TIMESTAMP true)
  -> rate;
//-> Discard;
