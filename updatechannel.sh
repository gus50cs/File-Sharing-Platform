#!/bin/bash

ORG=$1
PEER=$2
ORD=$3
ORDERER_NAME=$4
PORT=$5
ORD_PORT=$6
CHANNEL_NAME=$7 
ADDORG=$8


. $PWD/configUpdate.sh ${ORG} $ORD $ORDERER_NAME
. $PWD/envar.sh ${ORG} ${ORD} ${ORDERER_NAME} 
. $PWD/channel-config.sh 

#inside CLI
ConfigUpdate() {    

    #fetchChannelConfig $CHANNEL_NAME config.json $ORD $ORDERER_NAME ${PORT} $ORD_PORT
    export FABRIC_CFG_PATH=${PWD}/organizations/${ADDORG}
    #config_channeladd $ADDORG $PWD
    #configtxgen -printOrg ${ADDORG}MSP > $PWD/organizations/${ADDORG}/${ADDORG}.json

    #jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Application\":{\"groups\": {\"${ADDORG}MSP\":.[1]}}}}}" config.json "$PWD/organizations/${ADDORG}/${ADDORG}.json" > modified_config.json

    #createConfigUpdate $CHANNEL_NAME config.json modified_config.json ${ADDORG}_update_in_envelope.pb
}   

#ConfigUpdate

#inside CLI
Updatechannel() {
  #export FABRIC_CFG_PATH=${PWD}/organizations/${ORG}/peers/${PEER}
  signConfigtxAsPeerOrg org1 ${ADDORG}_update_in_envelope.pb >&log.txt 1012
  setGlobals $PORT
  peer channel update -o ${ORDERER_NAME}.${ORD}:${ORD_PORT} --ordererTLSHostnameOverride ${ORDERER_NAME}.${ORD} -c $CHANNEL_NAME -f ${ADDORG}_update_in_envelope.pb --tls --cafile "$ORDERER_CA" >&log.txt
  cat log.txt
}

Updatechannel


