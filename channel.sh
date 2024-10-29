
#!/bin/bash



read -p "How many orgs do you want to add to the channel? :" NUMBER
declare -a ORGS=()
for (( i=1; i<=$NUMBER; i++ ))
do
    read -p "What org do you want to add to the channel? :" org
    ORGS+=("$org")
done
read -p "What ord do you want to add to the channel? :" ORD 
read -p "What will be the channel name? :" CHANNEL

FILE=$PWD
CHANNEL_NAME=$CHANNEL.channel


. $PWD/channel-config.sh $CHANNEL_NAME

input="$PWD/orderer-${ORD,,}.txt"
orderers=$(awk 'NR>1{print $2}' $input)
ports=$(awk 'NR>1{print $4}' $input)

config_channel ${FILE} $ORD


orderers_array=($orderers)
ports_array=($ports)



x=1
for i in "${!orderers_array[@]}"; 
do
    orderer="${orderers_array[$i]}"
    port="${ports_array[$i]}"
    line_num1=$((63+(x-1)))
    line_num2=$((266+(x-1)))
    line_num3=$((317+(x-1)))
    config_orderpeer $orderer $port $line_num1 $ORD $line_num2 $FILE $line_num3
done


cleanup_orderer_placeholder



y=1
for i in "${ORGS[@]}" 
do
    org=$i
    line_num1=$((71+(y-1)*26))
    line_num2=$((467+(y-1)*26))
    y=$((y+1))
    org_channel $org $FILE $line_num1 
done
cleanup_org_placeholder

createChannelGenesisBlock() {
	set -x
	configtxgen -profile ApplicationGenesis -outputBlock $PWD/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
}

export FABRIC_CFG_PATH=$FILE/configtx/${CHANNEL_NAME}/
createChannelGenesisBlock $CHANNEL_NAME
BLOCKFILE=$FILE/channel-artifacts/${CHANNEL_NAME}.block



createChannel() {
    set -x
	osnadmin channel join --channelID $CHANNEL_NAME --config-block $PWD/channel-artifacts/${CHANNEL_NAME}.block -o localhost:${Listen_PORT} --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
	res=$?
	{ set +x; } 2>/dev/null
	let rc=$res
    cat log.txt

}

for i in "${!orderers_array[@]}"; 
do
    ORDERER_NAME=${orderers_array[i]}
    ORD_PORT=${ports_array[i]}
    export ORDERER_CA=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/tlscacerts/ca.crt
    export ORDERER_ADMIN_TLS_SIGN_CERT=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/signcerts/server.crt
    export ORDERER_ADMIN_TLS_PRIVATE_KEY=$FILE/organizations/${ORD}-orderer/orderers/${ORDERER_NAME}/tls-msp/keystore/server.key
    Listen_PORT=$((ORD_PORT+50))
    createChannel $Listen_PORT $CHANNEL_NAME    
done


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
    docker exec cli /bin/bash -c "$FILE/setAnchor.sh $i $ORD $CHANNEL_NAME $PEER $ORDERER_NAME $PORT $ORD_PORT $FILE"   
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
            echo $PEER
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
