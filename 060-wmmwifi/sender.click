#define DEBUGLEVEL 2

#define CST cst
#define CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#define RAWDUMP

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/rawwifidev.click"

AddressInfo(deviceaddress NODEDEVICE:eth);
wireless::BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");

wifidevice::RAWWIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless);

id::BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);

Idle()
  -> sf::BRN2SimpleFlow(FLOW "deviceaddress 00:00:00:00:00:01 1000 1500 0 5000 true 1 0", DEBUG 0)  //VAR_RATE VAR_PSIZE
  -> BRN2EtherEncap(USEANNO true)
  -> WMMWifiEncap(0x00, 0:0:0:0:0:0, 57, 16)
  //-> WifiEncap(0x00, 0:0:0:0:0:0)
  -> SetTimestamp()
  -> SetTXRate(RATE 2, TRIES 3)
  -> SetTXPower(24)
  -> wifioutq::NotifierQueue(10)
  -> SetTimestamp()
  -> BRN2PrintWifi("Sender (NODENAME)", TIMESTAMP true)
  -> wifidevice
  -> filter_tx :: FilterTX()
  -> Print("Sender (NODENAME) RX", TIMESTAMP true)
  -> Discard;

  filter_tx[1]
  -> BRN2PrintWifi("TXFeedback (S)", TIMESTAMP true)
  -> discard::Discard;

sys_info::SystemInfo(NODEIDENTITY id, CPUTIMERINTERVAL 1000);
