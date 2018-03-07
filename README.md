# IXP-Watch

IXP-watch script - is a tool for IXPs to continuously monitor layer 2 traffic on the exchange.

As well as storing a regular traffic sample, it will generate alerts for the following:-

- Excessive ARP
- Excessive traffic captured
- Spanning Tree
- Non-IP/IPv6 Traffic (for example CDP)
- Multicast/Traffic directed to 255.255.255.255 - DHCP/OSPF/IGP etc.
- Stray SNMP

The report contains stats on:

- ARP Queries / ARPs per min
- ICMP/ICMPv6 Packets
- ARPs Sponged
- Dead BGP Peers (bgp open attempts to sponged addresses)
- IPv6: Multicast Listener Query / Router Advertisement / Neighbor Advertisement
- IPv6:  Multicast Listener Discovery (MLDv2)

- Top 30 Arpers
- Top 30 ARP destinations requested
- ARP sponge reply activity
- Non-Unicast IP traffic
- Non-IP Traffic
- ICMP messages

Optionally, metrics can be fed to a monitoring system or grapher.
(Script includes some examples for mrtg.)

See: http://stats.lonap.net/ixpwatch/

