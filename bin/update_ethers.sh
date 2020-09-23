#!/bin/bash

# <rob@lonap.net> - 2020-08-24
# Script to update /etc/ethers with LONAP member details to make
# IXP-Watch reports and tcpdump more useful.

DESTFILE=/etc/ethers
TMPFILE=/tmp/ethers.$$

umask 002

  if [ ! -f "${DESTFILE}" ] ; then
    touch ${DESTFILE} || echo "ERROR: could not write to ${DESTFILE}" >&2 ; exit 1
  fi

# get updated ethers from IXP Manager:
/usr/bin/wget -qO - https://portal.lonap.net/cgi-bin/json_ethers?vlanid=1 | jq -r '.ethers[] | [.mac,.ethersdesc] | @tsv' > ${TMPFILE}

  COUNTLINES=`grep -c "__" ${TMPFILE}`

   if [ $COUNTLINES -lt 20 ] ; then
     echo "Hmm. file for ${DESTFILE} seems a bit short to me. Not using." >&2
     mv ${TMPFILE} ${TMPFILE}.err

   else 

    cat ${TMPFILE} > ${DESTFILE}

   fi

# clean up tmp file:
if [ -f "${TMPFILE}" ] ; then
	rm ${TMPFILE}
fi

