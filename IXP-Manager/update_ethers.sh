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
#
# <rob@lonap.net> - 2020-08-24
# Script to update /etc/ethers with member details to make
# IXP-Watch reports and tcpdump more useful.
# Set this up as a cron task to periodically update /etc/ethers e.g:
#
# 15 */2 * * * root /usr/local/bin/update_ethers.sh


# Where is config vars file:
CONFIG=/etc/ixpwatch/config.sh

# default ethers file (set in CONFIG if different)
ETHERSFILE=/etc/ethers

# Config file can also be specified from the command line with -c <filename>:
optstring=":c:"

while getopts ${optstring} arg; do
  case "${arg}" in
    c)
            # Set config file:
            CONFIG=${OPTARG}
    ;;
  esac
done


if [ ! -f $CONFIG ] ; then
 echo "Could not open config file $CONFIG!"
 exit 1
fi

source $CONFIG

TMPFILE=/tmp/ethers.$$

umask 002

  if [ ! -f "${ETHERSFILE}" ] ; then
    touch ${ETHERSFILE} || echo "ERROR: could not write to ${ETHERSFILE}" >&2 ; exit 1
  fi

# get updated ethers from IXP Manager:
$WGET $WGET_OPTS $URL_ETHERS | $JQ -r '.ethers[] | [.mac,.ethersdesc] | @tsv' > ${TMPFILE}

  COUNTLINES=$(grep -c "__" ${TMPFILE})

   if [ $COUNTLINES -lt 20 ] ; then
     echo "Hmm. file for ${ETHERSFILE} seems a bit short to me. Not using." >&2
     mv ${TMPFILE} ${TMPFILE}.err

   else 

    cat ${TMPFILE} > ${ETHERSFILE}

   fi

# clean up tmp file:
if [ -f "${TMPFILE}" ] ; then
	rm ${TMPFILE}
fi
