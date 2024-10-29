
#!/bin/bash


WORKING_DIR=$PWD

function yaml_channel {
    sed -e "s|FILE|$1|g" \
        -e "s/\${ORD}/$2/g" \
        $WORKING_DIR/yamlfiles/configtx.yaml | sed -e $'s/\\\\n/\\\n          /g'
}



function config_channel() {    
        mkdir -p $WORKING_DIR/configtx/${CHANNEL_NAME}
        > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(yaml_channel ${FILE} $ORD)" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(sed "460d" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml)" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        echo "$(sed "72,97d" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml)" > $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
        
}

function config_orderpeer() {
        new_txt=$(sed -n "63{s/\${NAME}/$1/g;s/\${ORD_PORT}/$2/g;s/\${ORD}/$4/g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num1=$3
        sed -i "${line_num1} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
        new_txt=$(sed -n "290{s/\${NAME}/$1/g;s/\${ORD_PORT}/$2/g;s/\${ORD}/$4/g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num2=$5
        sed -i "${line_num2} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
        new_txt=$(sed -n "340,344{s/\${NAME}/$1/g;s/\${ORD_PORT}/$2/g;s/\${ORD}/$4/g;s|FILE|$6|g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num3=$7
        sed -i "${line_num3} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
} 

function yaml_org {
        new_txt=$(sed -n "72,97{s/\${ORG}/$1/g;s|FILE|$2|g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num1=$3
        sed -i "${line_num1} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
        new_txt=$(sed -n "456{s/\${ORG}/$1/g;p}" $WORKING_DIR/yamlfiles/configtx.yaml)
        line_num2=$4
        sed -i "${line_num2} r /dev/stdin" $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml <<< "${new_txt}"
}

function org_channel() {    
        yaml_org ${org,,} $FILE ${line_num1} ${line_num2}
}

function yaml_channeladd {
    sed -e "s/\${ORG}/$1/g" \
        -e "s|FILE|$2|g" \
        $WORKING_DIR/yamlfiles/configtxaddorg.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function config_channeladd() {   
        ORG=$1
        FILE=$2 
        > $WORKING_DIR/organizations/${ORG}/configtx.yaml
        echo "$(yaml_channeladd ${ORG} ${FILE})" > $WORKING_DIR/organizations/${ORG}/configtx.yaml
}

function cleanup_org_placeholder {
    sed -i '/\${ORG}/d' $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
}

function cleanup_orderer_placeholder {
    sed -i '339d;338d;337d;332d;331d;330d;325d;270d;268d;63d' $WORKING_DIR/configtx/${CHANNEL_NAME}/configtx.yaml
}

