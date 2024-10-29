#!/bin/bash

FILE=$PWD
CHANNEL=$1
CHANNEL_NAME=${CHANNEL}.channel
. $FILE/configtx/${CHANNEL_NAME}/${CHANNEL}_data.sh
tmp1=$(echo $ORGS | cut -d " " -f 1)
tmp2=$(echo $PEERS | cut -d " " -f 1)
export FABRIC_CFG_PATH=$FILE/organizations/$tmp1/peers/$tmp2
CC_NAME=${2}
CC_SRC_PATH=$PWD/chaincode-go2.0
ORGS=${3}
PEERS=${4}
CC_SRC_LANGUAGE="go"
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="NA"
CC_END_POLICY="NA"
CC_COLL_CONFIG="NA"






CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  #infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  #successln "Finished vendoring Go dependencies"
fi


INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  { set +x; } 2>/dev/null
  cat log.txt
  #verifyResult $res "Chaincode packaging has failed"
  #successln "Chaincode is packaged"
}

## package the chaincode
packageChaincode

#sleep 5


. $FILE/ccutils.sh $PACKAGE_ID

input="$FILE/peers-${ORGS}.txt"
peers=$(awk 'NR>1{print $2}' $input)
for k in ${PEERS[@]}
do  
    PEER="$k"
    if echo $peers | grep -wq "$PEER"; then
        result=$(grep -n "${PEER}" $input | cut -d':' -f1)  
        PORT=$(awk -v line=$result 'NR==line{print $4}' $input)
        . $PWD/envar.sh $ORGS $ORD $ORDERER_NAME
        installChaincode $PORT
        queryInstalled $PORT
    fi
done

. $PWD/envar.sh $ORGS $ORD $ORDERER_NAME
approveForMyOrg $PORT $ORD_PORT $ORD $ORDERER_NAME $CC_SEQUENCE $INIT_REQUIRED $CC_END_POLICY $CC_COLL_CONFIG
queryCommitted $PORT
