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
if [[ $# -eq 0 ]] ; then
    exit_abnormal
    exit 0
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
sed -i '/nonMeteredLicense/s/^/#/' $BASEDIR/node_distr.conf
 echo "metering is ON"
 else
 sed -i '/nonMeteredLicense/s/^#\+//' $BASEDIR/node_distr.conf
 echo "metering is OFF"
fi
rm -R $BASEDIR/$param
mkdir $BASEDIR/$param
mkdir $BASEDIR/$param/temp
cd $BASEDIR
wget https://cdn.azul.com/zulu/bin/zulu8.44.0.11-ca-jdk8.0.242-linux_x64.tar.gz
tar -x -f zulu8.44.0.11-ca-jdk8.0.242-linux_x64.tar.gz
wget http://day3-doorman.cordaconnect.io/certificates/network-root-truststore.jks
cd $BASEDIR/$param
#mkdir -p ~/bin ; wget https://raw.githubusercontent.com/IShamraI/cam/master/cam.py -O ~/bin/cam
#chmod +x ~/bin/cam ; [[ `grep -Fxq 'export PATH="$HOME/bin:$PATH"' ~/.bashrc` ]] || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc ; source ~/.bashrc
#python ~/bin/cam -t $param -u iosif.itkin -p Welcome123\$ -s $BASEDIR corda-finance-workflows
cd $BASEDIR/$param
for i in 1 2 3 4
do
echo "making node char$i"
export SSHPORT="1173$i"
export P2PPORT="1172$i"
export RPCPORT="1171$i"
export ADMPORT="1170$i"
export NDNAME="Char0207111i"
export H2PORT="1174$i"
mkdir $BASEDIR/$param/char$i
cd $BASEDIR/
envsubst  < "node_distr.conf" > $BASEDIR/$param/char$i/node.conf
echo "$SSHPORT" > $BASEDIR/$param/temp/sshport$i
echo "$RPCPORT" > $BASEDIR/$param/temp/rpcport$i
echo "$NDNAME" > $BASEDIR/$param/temp/ndname$i
cp $BASEDIR/corda-$param.jar $BASEDIR/$param/char$i/
echo "Initial registration of node char$i"
cd $BASEDIR/$param/char$i
$BASEDIR/zulu8.44.0.11-ca-jdk8.0.242-linux_x64/bin/java -jar corda-$param.jar initial-registration --network-root-truststore-password password --network-root-truststore $BASEDIR/network-root-truststore.jks #>> /dev/null
 sleep 1
cd $BASEDIR
cp corda-finance-contracts-$param.jar $BASEDIR/$param/char$i/cordapps/
cp corda-finance-workflows-$param.jar $BASEDIR/$param/char$i/cordapps/
cd $HOME/ishamrai/ponomarev/distr/$param
done
cd $BASEDIR
 file="$BASEDIR/temp.txt"
for val in $(cat $file)
 do
for e in 1 2
  do
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
  done
 sllep 20
 echo "step3: starting the test"
 teststart=$('date')
 echo "Test started at $teststart"
 export BEHAVE_GRAPHITE_FILE=${HOME}/ishamrai/ponomarev/reports/$newfile
 echo "making money on char1"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char1/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char1/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-issue-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --timeout=18000 "1 RUB" "0 RUB" --ntimes=$val --ltimes=1 --delay=0 --duration=0
 echo "transfer money from Char1 and Char2 and back"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char1/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char1/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --notary="R3 HoldCo LLC" --timeout=18000 "1 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname2), L=Saratov, C=RU" --ntimes=$val --ltimes=1 --delay=0 --anonymous=false
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport2) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname2) --notary="R3 HoldCo LLC" --timeout=18000 "1 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname1), L=Saratov, C=RU" --ntimes=$val --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char1 to Char3"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport1) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname1) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname3), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char2 to Char4"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport2) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname2) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname4), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 echo "transfer money from Char3 to Char4"
 java -Xmx4096m -cp $HOME/ishamrai/ponomarev/rpc-client/rpc-client-ent-v45.jar:$BASEDIR/$param/char2/cordapps/corda-finance-workflows-$param.jar:$BASEDIR/$param/char2/cordapps/corda-finance-contracts-$param.jar net.corda.behave.tools.rpcClient.MainKt cash-payment-nft localhost:$(cat $BASEDIR/$param/temp/rpcport3) corda 12345678 --nodename $(cat $BASEDIR/$param/temp/ndname3) --notary="R3 HoldCo LLC" --timeout=18000 "59 RUB" "0 RUB" "O=$(cat $BASEDIR/$param/temp/ndname4), L=Saratov, C=RU" --ntimes=1 --ltimes=1 --delay=0 --anonymous=false
 testend=$('date')
 echo "Total test duration: ${SECONDS}"
 echo "Test completed at ${testend}"
 echo "step6: shutdown the node char1"
 a=`cat $BASEDIR/$param/char1/process-id`
 b=`cat $BASEDIR/$param/char2/process-id`
 c=`cat $HOME/ishamrai/ponomarev/test/$param/char3/process-id`
 d=`cat $HOME/ishamrai/ponomarev/test/$param/char4/process-id`
  echo $a
  echo $b
  echo $c
  echo $d
   kill $a
   kill $b
   kill $c
   kill $d
cd $BASEDIR/
   sleep 3
 done
rm $BASEDIR/temp.txt zulu8.44.0.11-ca-jdk8.0.242-linux_x64.tar.gz
rm -R $BASEDIR/$param/temp
rm -R -f $BASEDIR/zulu8.44.0.11-ca-jdk8.0.242-linux_x64
echo "temp files deleted"
