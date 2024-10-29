#!/bin/bash

FILE=$PWD
CHANNEL_NAME=$1.channel
. $PWD/configtx/$CHANNEL_NAME/${1}_data.sh
ORG=$(echo $ORGS | awk '{print $1}')
PEER=$(echo $PEERS | awk '{print $1}')
PORT=$(echo $PORTS | awk '{print $1}')
. $PWD/channel-config.sh 
ADDORG=$2
ADDPEER=$3
ADDPORT=$4
export FABRIC_CFG_PATH=$PWD/organizations/${ADDORG}/peers/${ADDPEER}





#docker exec cli /bin/bash -c "$PWD/updatechannel.sh $ORG $PEER $ORD ${ORDERER_NAME} $PORT $ORD_PORT $CHANNEL_NAME $ADDORG"  

#sleep 1

. $PWD/envar.sh $ORG ${ORD} ${ORDERER_NAME} 

setGlobals $PORT

#peer channel fetch 0 ${CHANNEL_NAME}.block -o localhost:${ORD_PORT} --ordererTLSHostnameOverride ${ORDERER_NAME}.${ORD} -c ${CHANNEL_NAME} --tls --cafile "$ORDERER_CA">&log.txt

. $PWD/envar.sh $ADDORG ${ORD} ${ORDERER_NAME} 

setGlobals $ADDPORT

#peer channel join -b ${CHANNEL_NAME}.block



setAnchorPeer() { 
    docker exec cli /bin/bash -c "$FILE/setAnchor.sh $ADDORG $ORD $CHANNEL_NAME $ADDPEER $ORDERER_NAME $ADDPORT $ORD_PORT $FILE"   
}

setAnchorPeer
