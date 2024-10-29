
#!/bin/bash

FILE=$PWD
CHANNEL_NAME=channel1.channel
ORD_PORT=519
ORD=orderer
ORDERER_NAME=ord3


. $PWD/channel-config.sh $CHANNEL_NAME

config_channel ${ORD_PORT} ${FILE} ${ORD,,} $ORDERER_NAME
createChannelGenesisBlock() {
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock $PWD/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
}

export FABRIC_CFG_PATH=$FILE/configtx/${CHANNEL_NAME}/

BLOCKFILE=$FILE/channel-artifacts/${CHANNEL_NAME}.block


createChannel() {
    set -x
	osnadmin channel join --channelID $CHANNEL_NAME --config-block $PWD/channel-artifacts/${CHANNEL_NAME}.block -o localhost:${Listen_PORT} --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	let rc=$res
    cat log.txt

}
export ORDERER_CA=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/tlscacerts/ca.crt
export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/signcerts/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/keystore/server.key
Listen_PORT=$((ORD_PORT+50))
createChannel $Listen_PORT $CHANNEL_NAME



joinChannel() {
    PORT=$1
    PEER=$2
    ORG=$3
    DELAY=3
    export FABRIC_CFG_PATH=$FILE/organizations/$ORG/peers/$PEER/
    MAX_RETRY=5
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
        set -x
        peer channel join -b $BLOCKFILE >&log.txt
        res=$?
        { set +x; } 2>/dev/null
		    let rc=$res
		    COUNTER=$(expr $COUNTER + 1)
	done
	    cat log.txt
}

setAnchorPeer() { 
    docker exec cli /bin/bash -c "$FILE/setAnchor.sh $i $ORD $CHANNEL_NAME $PEER $ORDERER_NAME $PORT $ORD_PORT"   
}
declare -a PEERS=()
declare -a PORTS=()

for i in ${ORGS[@]}  
do
    input="$FILE/peers-$i.txt"
    peers=$(awk 'NR>1{print $2}' $input)
    read -p "For $i what peers do you want to add? ($peers) :" PEER_NAME
    for k in $PEER_NAME
    do  
        PEER="$k"
        if echo $peers | grep -wq "$PEER"; then
            result=$(grep -n "${PEER}" $input | cut -d':' -f1)
            PORT=$(awk -v line=$result 'NR==line{print $4}' $input)
            PORTS+=("$PORT")
            PEERS+=("$PEER")
            . $PWD/envar.sh $i $ORD $ORDERER_NAME
            setGlobals $PORT $ORD
            echo $PORT $PEER $i
            joinChannel $PORT $PEER $i
        fi
    done
    setAnchorPeer
done

> $FILE/configtx/${CHANNEL_NAME}/${CHANNEL}_data.sh
ORGS_STRING=$(printf '%s ' "${ORGS[@]}")
PEERS_STRING=$(printf '%s ' "${PEERS[@]}")
PORTS_STRING=$(printf '%s ' "${PORTS[@]}")
echo -e "#!/bin/bash

export CHANNEL_NAME="$CHANNEL_NAME"
export ORGS='$ORGS_STRING'
export ORD="$ORD"
export ORDERER_NAME="$ORDERER_NAME"
export ORD_PORT="$ORD_PORT"
export PEERS='${PEERS_STRING}'
export PORTS='${PORTS_STRING}'" > $FILE/configtx/${CHANNEL_NAME}/${CHANNEL}_data.sh
