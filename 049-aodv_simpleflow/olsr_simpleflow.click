#define 	DEBUGLEVEL 2
//#define 	DSR_ID_CACHE
//#define 	WIFIDEV_LINKSTAT_DEBUG
#define 	ENABLE_OLSR_DEBUG
//#define 	SETCHANNEL
#define 	BRNFEEDBACK
#define 	CST cst
#define 	CST_PROCFILE "/proc/net/madwifi/NODEDEVICE/channel_utility"

#include "brn/helper.inc"
#include "brn/brn.click"
#include "device/wifidev_linkstat.click"
#include "routing/routing.click"
//#include "routing/olsr.click"


AddressInfo(deviceaddress NODEDEVICE:eth);

wireless	:: BRN2Device(DEVICENAME "NODEDEVICE", ETHERADDRESS deviceaddress, DEVICETYPE "WIRELESS");
id		:: BRN2NodeIdentity(NAME NODENAME, DEVICES wireless);
lt		:: Brn2LinkTable(NODEIDENTITY id, STALE 500, DEBUG 2);
device_wifi	:: WIFIDEV(DEVNAME NODEDEVICE, DEVICE wireless, ETHERADDRESS deviceaddress, LT lt);
routing		:: ROUTING(ID id, ETHERADDRESS deviceaddress, LT lt, METRIC device_wifi/etx_metric, LINKSTAT device_wifi/link_stat);

#ifndef SIMULATION
sys_info	:: SystemInfo(NODEIDENTITY id, CPUTIMERINTERVAL 1000);
#endif

device_wifi
	-> Label_brnether::Null()
	-> BRN2EtherDecap()
	//-> Print("Foo",100)
	-> brn_clf::Classifier(	0/BRN_PORT_OLSR,    //BrnDSR
				0/BRN_PORT_FLOW );  //Simpleflow

	brn_clf[0] 
		-> [1]routing;
		
	brn_clf[1]
		//-> Print("rx")
		-> BRN2Decap()
		-> sf::BRN2SimpleFlow(HEADROOM 192, DEBUG DEBUGLEVEL)
		-> BRN2EtherEncap(USEANNO true, DEBUG DEBUGLEVEL)
		//-> Print("Out")
		-> [0]routing;

Idle -> [3]routing;
Idle -> [4]routing;

device_wifi[1]
	//-> Print("BRN-In")
	-> BRN2EtherDecap()
	-> brn_clf;
device_wifi[2] 
	-> Discard;
device_wifi[3] 
	-> ff::FilterFailures() -> Discard;

	ff[1]
		-> BRN2EtherDecap()
		-> Print("NODENAME: ERROR")
		-> [2]routing;

routing[0] -> [0]device_wifi;
routing[1] -> [1]device_wifi;
routing[2] -> Discard;
routing[3] -> Discard;

Script(
  wait 100
);

Script(
#ifdef ENABLE_OLSR_DEBUG

#endif
);
