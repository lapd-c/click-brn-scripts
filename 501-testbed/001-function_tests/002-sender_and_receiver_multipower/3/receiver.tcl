#
# Set some general simulation parameters
#

#
# Unity gain, omnidirectional antennas, centered 1.5m above each node.
# These values are lifted from the ns-2 sample files.
#
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0

# Propagation model
# first set values of shadowing model
Propagation/Shadowing set pathlossExp_ 2.0  ;# path loss exponent
Propagation/Shadowing set std_db_ 4.0       ;# shadowing deviation (dB)
Propagation/Shadowing set dist0_ 1.0        ;# reference distance (m)
Propagation/Shadowing set seed_ 0           ;# seed for RNG

# Physical Layer
Phy/WirelessPhy set Pt_ 0.281838     ;# transmission power
Phy/WirelessPhy set freq_ 2.472e9    ;# for broadcast packets channel-13.2.472GHz
Phy/WirelessPhy set RXThresh_ 3.28984e-09   ;# communication radius

# Mac Layer
Mac/802_11 set dataRate_ 11Mb
Mac/802_11 set basicRate_ 1Mb 
Mac/802_11 set RTSThreshold_ 3000
Mac/802_11 set TXFeedback_ 1
Mac/802_11 set Promisc_ 1
Mac/802_11 set FilterDub_ 0


#
# The network channel, physical layer, MAC, propagation model,
# and antenna model are all standard ns-2.
#  
set netchan	Channel/WirelessChannel
set netphy	Phy/WirelessPhy
set netmac	Mac/802_11
set netprop     Propagation/Shadowing
set antenna     Antenna/OmniAntenna

set xsize 80
set ysize 65
set nodecount 2
set stoptime 30
set wtopo	[new Topography]
$wtopo load_flatgrid $xsize $ysize

#
# We have to use a special queue and link layer. This is so that
# Click can have control over the network interface packet queue,
# which is vital if we want to play with, e.g. QoS algorithms.
#
set netifq	Queue/ClickQueue
set netll	LL/Ext
LL set delay_			1ms

#
# With nsclick, we have to worry about details like which network
# port to use for communication. This sets the default ports to 5000.
#
Agent/Null set sport_		5000
Agent/Null set dport_		5000

Agent/CBR set sport_		5000
Agent/CBR set dport_		5000

#
# Standard ns-2 stuff here - create the simulator object.
#
Simulator set MacTrace_ ON
set ns_		[new Simulator]

#
# Create and activate trace files.
#
set tracefd     [open "/home/aureliano/Uni/METRIK/repository2/click-brn-scripts/501-testbed/001-function_tests/002-sender_and_receiver_multipower/3/receiver.tr" w]
set namtrace    [open "/home/aureliano/Uni/METRIK/repository2/click-brn-scripts/501-testbed/001-function_tests/002-sender_and_receiver_multipower/3/receiver.nam" w]
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $xsize $ysize
$ns_ use-newtrace


#
# Create the "god" object. This is another artifact of using
# the mobile node type. We have to have this even though
# we never use it.
#
set god_ [create-god $nodecount]

#
# Tell the simulator to create Click nodes.
#
Simulator set node_factory_ Node/MobileNode/ClickNode

#
# Create a network Channel for the nodes to use. One channel
# per LAN. Also set the propagation model to be used.
#
set chan_1_ [new $netchan]
set prop_ [new $netprop]

#
# In nsclick we have to worry about assigning IP and MAC addresses
# to out network interfaces. Here we generate a list of IP and MAC
# addresses, one per node since we've only got one network interface
# per node in this case. Also note that this scheme only works for
# fewer than 255 nodes, and we aren't worrying about subnet masks.
#

set iptemplate "10.0.%d.%d"
set mactemplate "00:00:00:00:%0x:%0x"
for {set i 0} {$i < $nodecount} {incr i} {
    set node_ip($i) [format $iptemplate [expr ($i+1)/256] [expr ($i+1)%256] ]
    set node_mac($i) [format $mactemplate [expr ($i+1)/256] [expr ($i+1)%256] ]
}

#
# We set the routing protocol to "Empty" so that ns-2 doesn't do
# any packet routing. All of the routing will be done by the
# Click script.
#
$ns_ rtproto Empty

#
# Here is where we actually create all of the nodes.
#
for {set i 0} {$i < $nodecount } {incr i} {
    set node_($i) [$ns_ node]

    #
    # After creating the node, we add one wireless network interface to
    # it. By default, this interface will be named "eth0". If we
    # added a second interface it would be named "eth1", a third
    # "eth2" and so on.
    #
    $node_($i) add-interface $chan_1_ $prop_ $netll $netmac \
	  $netifq 1 $netphy $antenna $wtopo

    #
    # Now configure the interface eth0
    #
    #$node_($i) setip "eth0" $node_ip($i)
    $node_($i) setmac "eth0" $node_mac($i)

    #
    # Set some node properties
    #
    $node_($i) random-motion 0
    $node_($i) topography $wtopo
    $node_($i) nodetrace $tracefd

    #
    # The node name is used by Click to distinguish information
    # coming from different nodes. For example, a "Print" element
    # prepends this to the printed string so it's clear exactly
    # which node is doing the printing.
    #
    [$node_($i) set classifier_] setnodename "node$i"
    
    #
    # Load the appropriate Click router script for the node.
    # All nodes in this simulation are using the same script,
    # but there's no reason why each node couldn't use a different
    # script.
    #
}

# 
# Define node network traffic. There isn't a whole lot going on
# in this simple test case, we're just going to have the first node
# send packets to the last node, starting at 1 second, and ending at 10.
# There are Perl scripts available to automatically generate network
# traffic.
#


#
# Start transmitting at $startxmittime, $xmitrate packets per second.
#
set startxmittime 0
set xmitrate 4
set xmitinterval 0.25
set packetsize 64

[$node_(0) entry] loadclick "/home/aureliano/Uni/METRIK/repository2/click-brn-scripts/501-testbed/001-function_tests/002-sender_and_receiver_multipower/3/receiver.click.wgt79.eth0"
[$node_(1) entry] loadclick "/home/aureliano/Uni/METRIK/repository2/click-brn-scripts/501-testbed/001-function_tests/002-sender_and_receiver_multipower/3/sender.click.wgt44.eth0"
for {set i 0} {$i < $nodecount} {incr i} {
     $ns_ at 0.0 "[$node_($i) entry] runclick"
 }
$node_(0) set X_ 0
$node_(0) set Y_ 15
$node_(0) set Z_ 0
$node_(0) label wgt79.eth0
$node_(1) set X_ 30
$node_(1) set Y_ 15
$node_(1) set Z_ 0
$node_(1) label wgt44.eth0
#
# This sizes the nodes for use in nam. Currently, the trace files
# produced by nsclick don't really work in nam.
#
for {set i 0} {$i < $nodecount} {incr i} {
    $ns_ initial_node_pos $node_($i) 20
}

$ns_ at 10 "set result \[\[$node_(1) entry\] writehandler setpower power \"10\" \]"
$ns_ at 20 "set result \[\[$node_(1) entry\] writehandler setpower power \"20\" \]"
$ns_ at 30 "set result \[\[$node_(1) entry\] writehandler setpower power \"30\" \]"
$ns_ at 40 "set result \[\[$node_(1) entry\] writehandler setpower power \"40\" \]"
$ns_ at 50 "set result \[\[$node_(1) entry\] writehandler setpower power \"50\" \]"

#
# Stop the simulation
#
$ns_ at  $stoptime.000000001 "puts \"NS EXITING...\" ; $ns_ halt"

#
# Let nam know that the simulation is done.
#
$ns_ at  $stoptime	"$ns_ nam-end-wireless $stoptime"


puts "Starting Simulation..."
$ns_ run




