#!/bin/bash

CLUSTERFILE=$(mktemp)

clusters(){
  COUNTER=1
  MENULIST=""
  for instance in $(aws rds describe-db-clusters | jq '.DBClusters[]| select(.DBSubnetGroup | contains("prod")) |.Endpoint' | tr -d '"')
  do
    MENULIST="$MENULIST $COUNTER $instance"
    COUNTER=$(($COUNTER+1))
    echo $instance >> $CLUSTERFILE
  done
}

instances(){
  COUNTER=1
  MENULIST=""
  for instance in $(aws rds describe-db-clusters | jq '.DBClusters[] | select(.DBSubnetGroup | contains("prod")) | .DBClusterMembers[].DBInstanceIdentifier' | tr -d '"')
  do
    HOST=$(aws rds describe-db-instances | jq --arg INSTANCE "$instance" '.DBInstances[] | select (.DBInstanceIdentifier==$INSTANCE) | .Endpoint.Address' | tr -d '"')
    MENULIST="$MENULIST $COUNTER $HOST"
    COUNTER=$(($COUNTER+1))
    echo $HOST >> $CLUSTERFILE
  done
}

OPTION=$(dialog --menu "Aurora connection helper" 20 100 2 \
	"1" "Connect to database cluster writer endpoint"\
        "2" "Connect to individual host"\
	 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus -eq 0 ]; then
    if [ $OPTION -eq 1 ]; then
      clusters
    else
      instances
    fi
else
    exit 1
fi

OPTION=$(dialog --menu "Select Endpoint" 20 100 $COUNTER $MENULIST 3>&1 1>&2 2>&3)
HOST_TO_CONNECT=$(awk -v linenum="$OPTION" 'NR==linenum {print}' $CLUSTERFILE)
rm $CLUSTERFILE
if [ $HOST_TO_CONNECT != '' ];
then
	clear
	mysql -h $HOST_TO_CONNECT
else
	echo "Something went wrong"
	exit 1
fi
