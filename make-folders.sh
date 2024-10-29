#!/bin/bash 

. $PWD/create-server-config.sh

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Assign the directory to the FILE variable
export FILE="$DIR"

# Assign the directory to the FILE variable
export WORKING_DIR="$DIR"

PORT=${1}
ORG=${2}
USERNAME=tls-${ORG}
PASSWORD=tls-${ORG}pw
declare -i LISTENINGPORT=$PORT+10000
HOSTS=0.0.0.0


FILE=$FILE/servers
FILE=$FILE/tls-ca-${ORG}
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT ${WORKING_DIR}

cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2

cd ../..

. $PWD/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD $ORG
register_tls

declare -i PORT=$PORT+10
USERNAME=ca-${ORG}
PASSWORD=ca-${ORG}pw
declare -i LISTENINGPORT=$PORT+10000

FILE=$PWD/servers
FILE=${FILE}/ca-${ORG} 
NAME=$(basename ${FILE,,})
config $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT $HOSTS
docker $PORT $NAME $USERNAME $PASSWORD $LISTENINGPORT ${WORKING_DIR}

cd $FILE
docker-compose -f ${NAME}.yaml up -d 2>&1
sleep 2

cd ../..

. $PWD/enroll-tls.sh $PORT $ORG $USERNAME $PASSWORD $ORG 


register_ca

enroll_nodes