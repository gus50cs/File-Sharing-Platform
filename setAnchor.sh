#!/bin/bash

ORG=$1
ORD=$2
CHANNEL_NAME=$3
PEER=$4
ORDERER_NAME=$5
PORT=$6
ORD_PORT=$7
FILE=$8


. $FILE/envar.sh $ORG $ORD $ORDERER_NAME
echo $FILE
. $FILE/configUpdate.sh $ORG $ORD $ORDERER_NAME


# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  echo "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json $ORD $ORDERER_NAME $PORT $ORD_PORT

  echo "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

  HOST="${PEER}.${ORG}"
  PORT=${PORT}

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o ${ORDERER_NAME}.${ORD}:${ORD_PORT} --ordererTLSHostnameOverride ${ORDERER_NAME}.${ORD} -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  #verifyResult $res "Anchor peer update failed"
  echo "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}


setGlobalsCLI $PORT $PEER

createAnchorPeerUpdate 

updateAnchorPeer 
