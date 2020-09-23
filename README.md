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
- IPv6: Multicast Listener Discovery (MLDv2)

- Top 30 Arpers
- Top 30 ARP destinations requested
- ARP sponge reply activity
- Non-Unicast IP traffic
- Non-IP Traffic
- ICMP messages

Optionally, metrics can be fed to a monitoring system or grapher.
(Script includes some examples for rrd.)

If you are using IXP Manager, ARP sponges can be automated instead of using the manual
sponge tool included. See the directory ./IXP-Manager for example scripts.

# Installation

- See the file INSTALL.TXT for more installation details.
- INTRO.TXT provides more background info on the original ixpwatch tool

# Manual Installation (Debuan/Ubuntu)

- Install dependencies:     apt-get install sipcalc jq wget tshark rrdtool
- Optional arpwatch tool:   apt-get install arpwatch
- Install `./bin/ixp-watch-lonap` into `/usr/local/bin`
- Install `./bin/ixp-watch-tidy` into `/usr/local/bin`
- Install `./bin/update_ethers.sh` into `/usr/local/bin`
- Install `./bin/sponge`  or `./IXP-Manager/auto_sponge` into  `/usr/local/bin`
- Make sure all these scripts have execute bit set.
- Run `dpkg-reconfigure wireshark-common` and select **Yes** to the question asking if non-root users should be permitted.
- Create a user called `ixpwatch`. Add it to group `wireshark` (create this group if it doesn't exist)
- Make directories:
  - `/var/ixpwatch`
  - `/var/ixpwatch/samples`
  - `/var/ixpwatch/watch`
  - `/var/ixpwatch/www`
- (For html reports, decide output directory. Default is /var/ixpwatch/www)
- The included html_example uses server side includes, but this could be changed to
  rsync the files somewhere etc.
- Set permissions / owner so that ixpwatch can write files: `chown -R ixpwatch /var/ixpwatch`
- Set up cron jobs:
  - `10 */3 * * *        root        /usr/local/bin/update_ethers.sh`
  - `*/15 * * * *        ixpwatch    /usr/local/bin/ixp-watch >/dev/null 2>&1`
  - `3 9 * * *           ixpwatch    /usr/local/bin/ixp-watch-tidy > /dev/null 2>&1`

  - If using the auto_sponge tool for automating sponges from IXP Manager:
     - `*/5 * * * *         root        /usr/local/bin/auto_sponge update`
