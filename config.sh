#!/bin/bash

################################################################################
#### Local configuration. Things you WILL need to check                        #
################################################################################

# REPORT_EMAIL='SOMETHING@YOUR.DOMAIN.HERE' # E-mail to send regular reports to
# (or leave REPORT_EMAIL undefined if you don't want reports)

ALARM_EMAIL='YOU@YOUR.DOMAIN.HERE' # E-mail to send bad thing alarms to

ALARM_PAGER='YOU@YOUR.DOMAIN.HERE' # E-Mail to page things out

MAILPROG=/usr/bin/mail   # command to send e-mails
# (redhat this is /bin/mail by default)

GZIP='nice -n 10 /bin/gzip'       # Location of gzip prog

CAP_INTERFACE=eth0        # Interface that we run the capture on

SAMPLE_TIME=900           # Capture time in seconds (default 15 minutes)

NETWORK='YOUR_NETWORK_HERE'   # Network Name. - some name

# Local syslog facility. Leave blank to turn off.
# (facility must be set up in your syslog.conf of course.)
LOCAL_FACIL=local4.debug


# Remote syslog option. Comment out to disable it.
LOGHOST=                  # optional syslog host to send alerts to
                          # leave blank to log locally instead.
                          # Check the below "/usr/bin/logger" commands to ensure
                          # You are using "-n" or "-h" accordingly for Linux or BSD.

LOG_FACILITY=local4.debug # Facility to send logs to
                          # leave both blank to not log anywhere.

ARP_WARNLEVEL=4000        # Alert when number of ARPS Per Minute reaches this.
                          # You may not know this now, but you can use the reports
                          # to work out what is a reasonable level.

SPANNING_TREE_BAD=1       # Do you want STP frames reported? 1=Yes 0=No.

WRITE_COUNTS=0            # Write counts to /tmp/ixpwatch.$NETWORK.counts?
                          # (useful if you want to plot graphs etc) 1=Yes 0=No.
                          # (See also COUNTSFILE below - you may need to change it!)

MAX_SAMPLE_SIZE=52428800  # Maximum sensible file size to try and process (50M)

ENORMOUS_SAMPLE=`expr $MAX_SAMPLE_SIZE \* 25`  # If the file is too enormous, just delete it.

# Disk space usage for disk where samples are stored.
# (Comment this out to disable auto sample purge based on free disk space)
DISK_PERCENT_PROG='/bin/df -h --output=pcent /'
DISK_PERCENT_MAX=95   # Max disk use before deleting samples.

DO_RRD=0                  # Plot RRT?
RRDTOOL=/usr/bin/rrdtool  # If so, where is RRDtool?

# As of 1.14, we try to make the list of dead BGP sessions more helpful by resolving
# the IP address, rather than just a big list of IP addresses. If you want to use
# the old format (no resolving), set BGPOPENS_OLD_FORMAT=1.
BGPOPENS_OLD_FORMAT=0

# Directories to put things in:
# *** These need to exist for this to work properly! ***

SAMPLE_ROOT=/var/ixpwatch/samples
LOG_ROOT=/var/ixpwatch/watch
TEMP_DIR=/var/ixpwatch/tmp

# Where to put RRD files and HTML files if DO_RRD is enabled:

HTML_DIR=/var/ixpwatch/www
RRD_DIR=${HTML_DIR}/graphs
GRAPH_DIR=${HTML_DIR}/graphs

# Where to find tshark:
# (I'm going to trust this as correct.)
TSHARK=/usr/bin/tshark
