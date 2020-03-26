#!/bin/bash
#
# pcapture-filter.sh: Converts a set of files from DSTDIR into filtered PCAPs (compressed) with a pattern
#
# 2019 ICANN DNS Engineering

PATH=/usr/local/bin:/usr/bin:/bin

XZ="/usr/bin/xz --compress"
UNXZ="/usr/bin/unxz --keep --stdout"
TCPDUMP="/usr/sbin/tcpdump"
LOG_ALLFILES="allfiles.log"
LOG_LASTFILE="lastfile.log"
#HOST=$(hostname -f | cut -c -11 | tr "." "-" )

### Parameters
while getopts "s:d:r:f:" opt; do
	case $opt in
		s ) SRCDIR=${OPTARG} ;;
		d ) DSTDIR=${OPTARG} ;;
		r ) REGEXF=${OPTARG} ;;
		f ) FILTER=${OPTARG} ;;
	esac
done

if [ -z ${SRCDIR} ] ; then
	SRCDIR="/opt/pcap"
fi

if [ -z ${DSTDIR} ] ; then
	DSTDIR="/opt/pcap-filtered"
fi

if [ -z ${REGEXF} ] ; then
	#File like 20190213-205630_300.ignored.pcap.xz
	REGEXF='*.ignored.pcap.xz'
fi

if [ -z "${FILTER}" ] ; then
	FILTER="((dst host 199.7.83.42 or dst host 2001:500:9f::42) and (icmp or icmp6))"
fi

### Main
mkdir -p ${DSTDIR}
cd ${SRCDIR}
find . -maxdepth 1 -type f -name "${REGEXF}" -printf '%P\n' 2>/dev/null|sort > ${DSTDIR}/${LOG_ALLFILES}
if [ -f ${DSTDIR}/${LOG_LASTFILE} ] ; then
	LAST=$(tail -n 1 ${DSTDIR}/${LOG_LASTFILE} 2>/dev/null)
	NUM=$(grep -n ${LAST} ${DSTDIR}/${LOG_ALLFILES} 2>/dev/null| cut -d ":" -f1)
else
	NUM=0
fi

NUM=$((NUM+1))

if [ $NUM -le 0 ] ; then
	echo "Weird number (${NUM}) caught in ${DSTDIR}/${LOG_LASTFILE}"
	exit 1
fi

for FILE in $(tail -n +${NUM} ${DSTDIR}/${LOG_ALLFILES}) ; do
	if [ ! -e ${DSTDIR}/${FILE} ] ; then
		# unxz -k -c /opt/pcap/20190401-000403_300.ignored.pcap.xz | tcpdump -n -r -
		# Original filename like: 20190423-201634_300.ignored.pcap.xz
		# New file name (filtered): 20190423-201634_300.filtered.pcap.xz
		newFILE="$(echo ${FILE} | cut -d '.' -f1)"
		${UNXZ} ${SRCDIR}/${FILE} | ${TCPDUMP} -r - -w ${DSTDIR}/${newFILE}.temp "${FILTER}" 2>/dev/null
		if [ $? -eq 0 ] ; then
			# We are only interested on files with usual info (> 24bytes)
			FILESIZE=$(stat -c%s ${DSTDIR}/${newFILE}.temp 2>/dev/null)
			if [ ! -z $FILESIZE ] && [ $FILESIZE -gt 24 ] ; then
				# First we compress the temp file
				${XZ} ${DSTDIR}/${newFILE}.temp
				# After it's compressed we renamed it (to avoid to transfer a file in the middle of compression process)
				mv ${DSTDIR}/${newFILE}.temp.xz ${DSTDIR}/${newFILE}.filtered.pcap.xz
			elif [ -f ${DSTDIR}/${newFILE}.temp ] ; then
				rm ${DSTDIR}/${newFILE}.temp
			fi
			echo ${FILE} > ${DSTDIR}/${LOG_LASTFILE}
		fi
	fi
done
