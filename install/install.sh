#!/bin/bash
# This file is part of IXP Watch
#
# IXP Watch is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, version v2.0 of the License.
#
# IXP Watch is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License v2.0
# along with IXP Watch If not, see:
#
# http://www.gnu.org/licenses/gpl-2.0.html

clear

REPO_URL="https://github.com/euro-ix/IXP-Watch.git"

DEF_INSTALL_DIR="/usr/local/ixpwatch"
DEF_LINK_DIR="/usr/local/bin"
DEF_DATA_DIR="/var/ixpwatch"
DEF_CONF_DIR="/etc/ixpwatch"

DEF_PURGE_SAMPLE_DAYS=10
DEF_ZIP_REPORTS_DAYS=30
DEF_PURGE_REPORTS_DAYS=0

DEF_LOGGER="/usr/bin/logger"
DEF_LOGHOSTS="192.168.100.10 192.168.200.20"

DEF_LOCAL_FACIL="local4.debug"
DEF_LOG_FACILITY="local4.debug"

DEF_PREFIX_IPV4="5.57.80.0/22"
DEF_CAP_INTERFACE="eth1"
DEF_NETWORK="IXP-LAN"

# install these packages on debian/ubuntu by default:
DEF_PACKAGES="tshark sipcalc"

DEF_USER="ixpwatch"

RUNNING_USER=$(whoami)

echo "IXP-Watch Install Script"
echo "========================"
echo ""
echo "This script will attempt to install a working IXP-Watch with some"
echo "default settings to get started."
echo ""
echo "Please read INSTALL.TXT to understand the config options in more detail."
echo ""
echo ""

if [ $RUNNING_USER != "root" ] ; then
	echo " *** This script needs to run as root, because it needs to install packages"
	echo "     and to set the correct permissions."
	exit 1
fi

if [ -f /etc/debian_version ] ; then
 DEBIAN=$(cat /etc/debian_version)
 echo "** Debian/Ubuntu $DEBIAN found. Will ask to install apt packages."
else
 echo "** Not Debian / Ubuntu. You may need to install extra packages for tshark, rrdtool etc."
fi
echo ""

GIT=$(which git)

if [ -z "$GIT" ] ; then

    echo "*** git not found! "

	if [ -n "$DEBIAN" ] ; then
	 printf "...will install git with apt"
	 DEF_PACKAGES="git ${DEF_PACKAGES}"

	else

	 exit 1

	fi

echo ""

fi

# Get prompt to variable and make it look nice
get_prompt () {

	local PROMPT_TEXT=$1
	local PROMPT_DEFAULT=$2

	local prompt_len=${#PROMPT_DEFAULT}

	if [ $prompt_len -le 1 ] ; then
	 local OPTS="-n 1"
    else
	 local OPTS="-e -i ${PROMPT_DEFAULT}"
	fi

    local ten="          "
    local pad="$ten$ten$ten"

	if [ -n "$PROMPT_DEFAULT" ] ; then
	    local prompt="${PROMPT_TEXT}"
		prompt="${prompt:0:40}${pad:0:$((40 - ${#prompt}))} : "
        read -p "$prompt" ${OPTS}
	else
    	read -p "${PROMPT_TEXT}" ${OPTS}
	fi

	echo "${REPLY}"
}

function yes_or_no {
	local default=$2
	local defprompt="[y/n]"

	 if [ "$default" = "y" ] ; then defprompt="[Y/n]" ; local retval="1" ; fi
	 if [ "$default" = "n" ] ; then defprompt="[y/N]" ; local retval="0" ; fi

    while true; do
	    yn=$( get_prompt "$1 $defprompt" "$default" )
        case $yn in
            [Yy]*) echo "1" ; return 1 ;;  
            [Nn]*) echo "0" ; return 0 ;;
			*) echo "${retval}" ; return $retval ;;
        esac
    done
}


INSTALLDIR=$( get_prompt "Script install directory" ${DEF_INSTALL_DIR} )

echo ""
echo "Data directory setup. Must be a location with sufficient space"
echo "for example 15-20G for sample and report storage."
echo ""

DATA_DIR=$( get_prompt "Data directory"          "${DEF_DATA_DIR}" )
CONF_DIR=$( get_prompt "Config directory"        "${DEF_CONF_DIR}" )

SAMPLE_ROOT="${DATA_DIR}/samples"
LOG_ROOT="${DATA_DIR}/watch"
TEMP_DIR="${DATA_DIR}/tmp"

DEF_HTML_DIR="${DATA_DIR}/www"

PURGE_SAMPLE_DAYS=$( get_prompt "Days to keep capture sample files"   "${DEF_PURGE_SAMPLE_DAYS}" )
ZIP_REPORTS_DAYS=$( get_prompt  "Compress reports older than (days)"  "${DEF_ZIP_REPORTS_DAYS}" )

echo ""
CAP_INTERFACE=$( get_prompt "Peering LAN capture interface"  ${DEF_CAP_INTERFACE} )
PREFIX_IPV4=$( get_prompt "Peering LAN IPv4 prefix"  ${DEF_PREFIX_IPV4} )
NETWORK=$( get_prompt "Name for this peering LAN (1 word)"   ${DEF_NETWORK}       )
NETWORK=$(echo "${NETWORK}" | sed s/[^\.a-zA-Z0-9_\-]//g)

echo ""
CONFIG=$( get_prompt "Config file (will be created)"       ${CONF_DIR}/${NETWORK}.conf )
echo ""

USER=$( get_prompt "user/group to add for ixpwatch"        ${DEF_USER}   )
GROUP=${USER}

echo ""
echo "Email settings"
echo "=============="
echo ""
echo "Email for alerts notification: Address to receive IXP-Watch notifications (must be set)"
echo "Email for SMS/pager: for urgent alerts (STP and ARP storms) (optional)"
echo "You may also enable REPORT_EMAIL in the config to receive a copy of every report"
echo ""

ALARM_EMAIL=$( get_prompt "Email for alerts"  ${USER} )
ALARM_PAGER=$( get_prompt "Email for SMS/urgent alerts" ${ALARM_EMAIL} )

echo ""
echo "SYSLOG settings"
echo "==============="
echo ""
echo "IXP-Watch supports local and/or remote syslog"
echo ""

LOGGER=$( get_prompt "Location of logger" ${DEF_LOGGER} )

DO_LOCAL_SYSLOG=$( yes_or_no "Enable syslog to LOCAL host? [yes]" y) ; echo ""

if [ $DO_LOCAL_SYSLOG = 1 ] ; then

 LOCAL_FACIL=$( get_prompt "- LOCAL Syslog facility"  "${DEF_LOCAL_FACIL}" )

fi

DO_REMOTE_SYSLOG=$( yes_or_no "Enable syslog to REMOTE host(s)? [yes]" y) ; echo ""

if [ $DO_REMOTE_SYSLOG = 1 ] ; then

 LOG_FACILITY=$( get_prompt "- REMOTE Syslog facility"  "${DEF_LOG_FACILITY}" )
 LOGHOSTS=$( get_prompt "- REMOTE Syslog host(s)"       "${DEF_LOGHOSTS}" )

fi


echo ""
echo "Optional extras"
echo "==============="
DO_RRD=$( yes_or_no "Set up RRD graphs? [yes]" y) ; echo ""

if [ $DO_RRD = 1 ] ; then

 DEF_PACKAGES="${DEF_PACKAGES} rrdtool"

 HTML_DIR=$( get_prompt "- Directory for html output"       ${DEF_HTML_DIR}  )
 RRD_DIR=$( get_prompt "- Directory for RRD files"          "${DEF_HTML_DIR}/graphs" )
 GRAPH_DIR=$( get_prompt "- Directory for graph png files"  "${DEF_HTML_DIR}/graphs" )
else
 HTML_DIR=${DEF_HTML_DIR}
 RRD_DIR=${DEF_HTML_DIR}/graphs
 GRAPH_DIR=${DEF_HTML_DIR}/graphs
fi
echo ""
echo "== Creating directories:"

CREATE_DIRS="$INSTALLDIR $DATA_DIR $CONF_DIR $SAMPLE_ROOT $LOG_ROOT $TEMP_DIR $HTML_DIR $RRD_DIR $GRAPH_DIR"

for dir in ${CREATE_DIRS}

  do 

    echo "- $dir"

	if [ -d "$dir" ] ; then

	    if [ "$dir" = "$INSTALLDIR" ] ; then

		  clobber=$( yes_or_no "dir exists! replace? [yes]" y)

		  if [ "$clobber" = "1" ] ; then
		    rm -rf $dir
          else
		    echo "not replacing. Install may not work correctly!"
         fi
    echo ""
  	    fi
	fi

done

for dir in ${CREATE_DIRS}

  do 
  mkdir -p $dir || exit 1

done


if [ -n "$DEBIAN" ] ; then
  echo ""
  DO_ARPWATCH=$( yes_or_no "Install arpwatch tool? [yes]" y)
 if [ $DO_ARPWATCH = 1 ] ; then
   DEF_PACKAGES="${DEF_PACKAGES} arpwatch"
 fi
 echo ""
 echo "== Preparing apt selections..."
 echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
 echo ""
 echo "== Installing apt packages..."
 
  for package in ${DEF_PACKAGES}
  do 
    echo "-->> installing: $package : "
    apt-get -y install $package
  done
fi

GIT=$(which git)
if [ -z "$GIT" ] ; then
 echo "** git not found! please install to continue!"
 echo ""
 exit 1
fi

echo ""
echo "== Fetching from repository into ${INSTALLDIR}"

git clone ${REPO_URL} ${INSTALLDIR} || exit 1

echo "== Create user for ixpwatch: ${USER}"
useradd -c "IXP-Watch" -d ${DEF_DATA_DIR} -s /bin/bash --no-create-home --system ${USER}
usermod -a -G wireshark ${USER}

echo ""
echo "== Setting up files:"

mkdir -p ${DEF_LINK_DIR}
for file in ${INSTALLDIR}/bin/*
do
        if [ ! -e "${DEF_LINK_DIR}/${file}" ] ; then
        ln -s $file ${DEF_LINK_DIR}
		fi
done

for file in ${INSTALLDIR}/html_example/*
do
	    if [ ! -e "${HTML_DIR}/${file}" ] ; then
		  cp ${INSTALLDIR}/html_example/* ${HTML_DIR}
		fi
done

MY_NET=$(echo "${PREFIX_IPV4}" | cut -f1 -d/)
MASK=$(echo "${PREFIX_IPV4}" | cut -f2 -d/)
SANITY_CHECK=$(echo ${MY_NET} | cut -c 1-6 )

echo "== Writing configuration to ${CONFIG}"
echo "s|^ALARM_EMAIL=.*|ALARM_EMAIL=\'${ALARM_EMAIL}\'|g" | tee /tmp/sed_cmd.$$
echo "s|^ALARM_PAGER=.*|ALARM_PAGER=\'${ALARM_PAGER}\'|g" | tee -a /tmp/sed_cmd.$$
echo "s|^NETWORK.*|NETWORK=\'${NETWORK}\'|g"              | tee -a /tmp/sed_cmd.$$
echo "s|^CAP_INTERFACE=.*|CAP_INTERFACE=${CAP_INTERFACE}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^DO_RRD=.*|DO_RRD=${DO_RRD}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^SAMPLE_ROOT=.*|SAMPLE_ROOT=${SAMPLE_ROOT}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^LOG_ROOT=.*|LOG_ROOT=${LOG_ROOT}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^TEMP_DIR=.*|TEMP_DIR=${TEMP_DIR}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^HTML_DIR=.*|HTML_DIR=${HTML_DIR}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^RRD_DIR=.*|RRD_DIR=${RRD_DIR}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^GRAPH_DIR=.*|GRAPH_DIR=${GRAPH_DIR}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^MY_NET=.*|MY_NET=${MY_NET}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^MASK=.*|MASK=${MASK}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^SANITY_CHECK=.*|SANITY_CHECK=${SANITY_CHECK}|g" | tee -a /tmp/sed_cmd.$$
echo "s|^LOGGER=.*|LOGGER=${LOGGER}|g" | tee -a /tmp/sed_cmd.$$

if [ $DO_LOCAL_SYSLOG = 1 ] ; then
 echo "s|^# LOCAL_FACIL=.*|LOCAL_FACIL=${LOCAL_FACIL}|g" | tee -a /tmp/sed_cmd.$$
fi

if [ $DO_REMOTE_SYSLOG = 1 ] ; then

 echo "s|^# LOGHOSTS=.*|LOGHOSTS=\'${LOGHOSTS}\'|g" | tee -a /tmp/sed_cmd.$$
 echo "s|^LOG_FACILITY=.*|LOG_FACILITY=${LOG_FACILITY}|g" | tee -a /tmp/sed_cmd.$$

fi

sed -f /tmp/sed_cmd.$$ ${INSTALLDIR}/conf/config.dist > ${CONFIG}
rm -f /tmp/sed_cmd.$$

# CONFIG var needs setting in scripts:
for file in ${INSTALLDIR}/bin/*
  do
        sed s^CONFIG=.*^CONFIG=${CONFIG}^ -i ${file}
  done

id -u ${USER} > /dev/null
USER_OK=$?
if [ "$USER_OK" = "0" ] ; then

# fix up permissions:
echo ""
echo "== Setting owner/permissions"
chown -R ${USER}:${GROUP} ${INSTALLDIR}
chown -R ${USER}:${GROUP} ${DATA_DIR}
chown -R ${USER}:${GROUP} ${CONF_DIR}
chmod a+x ${INSTALLDIR}/bin/*

	if [ -d "/etc/cron.d" ] ; then
		echo ""
		echo "== Setting up cron tasks"
		echo "*/15 * * * * ${USER} ${INSTALLDIR}/bin/ixp-watch >/dev/null 2>&1" | tee /etc/cron.d/ixp-watch
		echo "5 7 * * * ${USER} ${INSTALLDIR}/bin/ixp-watch-tidy > /dev/null 2>&1" | tee /etc/cron.d/ixp-watch-tidy

        echo "Note: sample interval is 15 minutes (900 seconds). If you change this in the IXP-Watch config,"
		echo "remember also to change the cron task /etc/cron.d/ixp-watch."

	fi

else

echo "** Warning: User ${USER} could not be created! You will need to:"
echo "  - create the user and group for ${USER}"
echo "  - fix up permissions/ownerships on the directories (see INSTALL.TXT)"
echo "  - add user to the wireshark group as required"
echo "  - install cron tasks"

fi

echo "== Setup complete!"
echo ""
echo "Further actions:"
echo "Please read INSTALL.TXT to understand the config options in more detail."
echo ""
echo "1. Review the config file ${CONFIG} and edit any further settings as needed."
echo "    - you may also need to check the ixp-watch script itself."
echo "2. If you installed arpwatch, you may want to edit the config: /etc/default/arpwatch on debian."
echo "3. Set up bin/sponge or IXP-Manager/auto_sponge tools. (optional)"
echo "4. Edit web pages in ${HTML_DIR} / set up web location."
echo ""
