#!/usr/bin/env bash


total=${1:-10}

i=0

while [ ${i} -lt ${total} ] ; do

	i=$(($i+1))

	echo "Fetching data $i..."

	sleep 1

done

echo "Done : All fetched"




