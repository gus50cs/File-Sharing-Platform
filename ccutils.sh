#!/bin/bash
PACKAGE_ID=$1

# installChaincode PEER ORG
function installChaincode() {
  PORT=$1
  setGlobals $PORT
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  if test $? -ne 0; then
    peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
    res=$?
  fi
  { set +x; } 2>/dev/null
  cat log.txt
  #verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has failed"
  #successln "Chaincode is installed on peer${PEER}.org${ORG}"
}

# queryInstalled PEER ORG
function queryInstalled() {
  PORT=$1
  setGlobals $PORT
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  #echo "$res "Query installed on ${ORG} has failed""
  #successln "Query installed successful on ${ORG} on channel"
}

# approveForMyOrg VERSION PEER ORG
function approveForMyOrg() {
  PORT=$1
  ORD_POR=$2
  ORD=$3
  ORDERER_NAME=$4
  setGlobals $PORT
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:${ORD_PORT} --ordererTLSHostnameOverride ${ORDERER_NAME}.${ORD} --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  #verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  #successln "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION PEER ORG
function checkCommitReadiness() {
  PORT=$1
  setGlobals $PORT
  set -x
  peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
  { set +x; } 2>/dev/null
  cat log.txt
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
function commitChaincodeDefinition() {
  parsePeerConnectionParameters 
  ORD_POR=$1
  ORDERER_NAME=$2
  ORD=$3
  res=$?


  set -x
  peer lifecycle chaincode commit -o localhost:${ORD_POR} --ordererTLSHostnameOverride ${ORDERER_NAME}.${ORD} --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} "${PEER_CONN_PARMS[@]}" --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  #verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  #successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
function queryCommitted() {
  PORT=$1
  setGlobals $PORT
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  set -x
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
  { set +x; } 2>/dev/null
  echo $EXPECTED_RESULT
  cat log.txt
}

