#!/bin/bash
export BASEDIR="$(dirname "$(readlink -f "$0")")"
echo "$BASEDIR"
usage() { 
 echo "Usage: $0 [ -f filename for test results ] [ -i number of states ] [ -v version of test node  client ]" 1>&2
}
exit_abnormal() {
 usage
 exit 1
}
function new_node {
echo "making node char$i"
mkdir $BASEDIR/$param/char$i
cd $BASEDIR/
envsubst  < "node_template.conf" > $BASEDIR/$param/char$i/node.conf
echo "$SSHPORT" > $BASEDIR/$param/temp/sshport$i
echo "$RPCPORT" > $BASEDIR/$param/temp/rpcport$i
echo "$NDNAME" > $BASEDIR/$param/temp/ndname$i
cp $BASEDIR/corda-$param.jar $BASEDIR/$param/char$i/
echo "Initial registration of node char$i"
cd $BASEDIR/$param/char$i
$BASEDIR/zulu8.44.0.11-ca-jdk8.0.242-linux_x64/bin/java -jar corda-$param.jar initial-registration --network-root-truststore-password password --network-root-truststore $BASEDIR/$cert #>> /dev/null
 sleep 1
cd $BASEDIR
cp corda-finance-contracts-$param.jar $BASEDIR/$param/char$i/cordapps/
cp corda-finance-workflows-$param.jar $BASEDIR/$param/char$i/cordapps/
cd $HOME/ishamrai/ponomarev/distr/$param
cd $BASEDIR
}
function node_start {
   cd $BASEDIR/$param/char$e
    rm -R $BASEDIR/$param/char$e/logs/ # remove the log
   rm $BASEDIR/$param/char$e/persistence.mv.db # remove the base
   rm $BASEDIR/$param/char$e/persistence.trace.db # remove the base
   echo "step1: starting the node char$e"
   cd $BASEDIR/$param/char$e
   $BASEDIR/zulu8.44.0.11-ca-jdk8.0.242-linux_x64/bin/java -jar corda-$param.jar & #>> /dev/null # start in background the node
   echo "step1_1: wait for the ssh open port"
   while ! nc -z localhost $(cat $BASEDIR/$param/temp/sshport$e); do
   sleep 1
   done
   while
   a=$(grep -c 'P2PMessaging' $BASEDIR/$param/char$e/logs/node-r3-exposed-srv07.log)
   b=0
   [[ "$a" -eq "$b" ]]
   do
   sleep 1
   echo "$a" >> /dev/null
   done
   echo "ssh port is open"
  sleep 10
 }
if [[ $# -eq 0 ]] ; then
    exit_abnormal
    exit 0
fi
FILE=$BASEDIR/temp.txt
 if [ -f "$FILE" ]; then
    echo "$FILE exists."
 rm $BASEDIR/temp.txt
 else
    echo "$FILE does not exist."
fi
while getopts ":f:v:i:m:" arg; do
case $arg in
f)newfile="${OPTARG}"
echo "Found the -f option with $newfile name for the test result file"
 ;;
i)state="${OPTARG}"
echo "$state" >> $BASEDIR/temp.txt
echo "Found the -i option with $state states test value"
 ;;
v) param="${OPTARG}"
echo "Found the -v option, with node client version $param"
 ;;
m) meter="${OPTARG}"
echo "Found the -m option with $meter metering finctionality mode"
 ;;
--) shift
break ;;
*) exit_abnormal
;;
esac
done
 if [[ "$meter" == "on" ]]
  then
sed -i '/nonMeteredLicense/s/^/#/' $BASEDIR/node_template.conf
 echo "metering is ON"
 else
 sed -i '/nonMeteredLicense/s/^#\+//' $BASEDIR/node_template.conf
 echo "metering is OFF"
fi
if ! curl http://night4-netmap.cordaconnect.io:10001/network-map >> /dev/null
then echo "Got error downloading network"
doormanUrl=$(echo "http://day3-doorman.cordaconnect.io")
mapUrl=$(echo "http://day3-netmap.cordaconnect.io")
curcert="network-root-truststore.jks"
else echo "All OK"
doormanUrl=$(echo "http://night4-doorman.cordaconnect.io:10001")
mapUrl=$(echo "http://night4-netmap.cordaconnect.io:10001")
curcert="nightwatchv4-network-root-truststore.jks"
fi
rm -R $BASEDIR/$param
mkdir $BASEDIR/$param
mkdir $BASEDIR/$param/temp
cd $BASEDIR
wget https://cdn.azul.com/zulu/bin/zulu8.44.0.11-ca-jdk8.0.242-linux_x64.tar.gz
tar -x -f zulu8.44.0.11-ca-jdk8.0.242-linux_x64.tar.gz
rm network-root-*
wget http://day3-doorman.cordaconnect.io/certificates/network-root-truststore.jks
cd $BASEDIR/$param
for i in $( seq 4 )
do
export SSHPORT="1173$i"
export P2PPORT="1172$i"
export RPCPORT="1171$i"
export ADMPORT="1170$i"
export NDNAME="Char$RANDOM$RANDOM$i"
export H2PORT="1174$i"
export currentDoorman="$doormanUrl"
export currentNetmap="$mapUrl"
export cert="$curcert"
new_node
done
 file="$BASEDIR/temp.txt"
for val in $(cat $file)
 do
 for e in $( seq 4 )
  do
 node_start
  done
 echo "step3: starting the test $val states"
 teststart=$('date')
 echo "Test started at $teststart"
 export BEHAVE_GRAPHITE_FILE=${HOME}/ishamrai/ponomarev/reports/$newfile
 echo "making money on char1 and char2"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char1/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char1/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-issue-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --timeout=18000 "1 RUB" "0 RUB" --ntimes=$val --ltimes=1 --delay=0 --duration=0 --notracked=true & >> /dev/null
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-issue-nft localhost:$(cat $BASEDIR/$param/temp/rpcport2) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname2) --timeout=18000 "1 RUB" "0 RUB" --ntimes=$val --ltimes=1 --delay=0 --duration=0 --notracked=true
 echo "transfer money from Char1 and Char2 and back"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char1/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char1/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --notary="R3 HoldCo LLC" --timeout=18000 "1 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname2), L=Saratov, C=RU" --ntimes=$val --ltimes=1 --delay=0 --anonymous=false &
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport2) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname2) --notary="R3 HoldCo LLC" --timeout=18000 "1 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname1), L=Saratov, C=RU" --ntimes=$val --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char1 to Char3"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char1/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char1/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname3), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char2 to Char4"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport2) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname2) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname4), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char3 to Char4"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char3/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char3/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport3) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname3) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname4), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 testend=$('date')
 echo "Total test duration: ${SECONDS}"
 echo "Test completed at ${testend}"
 echo "step6: shutdown the nodes"
 for g in $( seq 4 )
  do
  a=`cat $BASEDIR/$param/char$g/process-id`
  echo ${a}
  kill ${a}
  done
cd $BASEDIR/
   sleep 5
 done
rm $BASEDIR/temp.txt zulu8.44.0.11-ca* network-root-truststore*
rm -R $BASEDIR/$param/temp
rm -R -f $BASEDIR/zulu8.44.0.11-ca-jdk8.0.242-linux_x64
echo "temp files deleted"
