#!/bin/bash
echo -e "Checking for \"carbonsphere/dock-easy-rsa\" docker image\n"

IMG=`docker images |grep carbonsphere/dock-easy-rsa`

if [ "$?" == "1" ]; then
  echo "please download \"carbonsphere/dock-easy-rsa\" first! ex: docker pull carbonsphere/dock-easy-rsa"
  exit
fi

DCONTAIN=`docker ps -a |grep carbonsphere/dock-easy-rsa`
if [ "$?" != "1" ]; then
  echo "A copy of dock-easy-rsa is in process. Please terminate it before running EX: docker rm easy-rsa"
  exit
fi

if ! [ -d "keys" ]; then
  echo -e "Create keys directory"
  mkdir keys
fi

if ! [ -e "vars" ]; then
  echo "Error: Please create vars or you can use default vars by \"cp vars.example vars\""
  exit
fi

read -p "Press [Enter] key to start clearing. or Ctrl+c to abort"

rm ./keys/*

echo -e "Old keys and certificate cleared\n"

echo -e "Initialize Key index\n"
sh gen_index.sh

echo -e "Generating CA certificate and key. Note: Default variables can be edit in vars.example\n"

docker run -it --rm --name easy-rsa -v $(pwd)/keys:/easy-rsa --env-file vars carbonsphere/dock-easy-rsa /er/build-ca

echo -e "\nGenerating server certificate and keys.\n"

read -p "Please enter server name[server]: " srvname

if [ "$srvname" == "" ]; then
  srvname="server";
fi

echo -e "\nCreating $srvname"

docker run -it --rm --name easy-rsa -v $(pwd)/keys:/easy-rsa --env-file vars carbonsphere/dock-easy-rsa /er/build-key-server $srvname

echo -e "\nGenerating DH\n"
docker run -it --rm --name easy-rsa -v $(pwd)/keys:/easy-rsa --env-file vars carbonsphere/dock-easy-rsa /er/build-dh

echo -e "Moving necessary files to openvpn directory\n"

cp ./keys/ca.crt .
cp ./keys/$srvname.crt .
cp ./keys/$srvname.key .
cp ./keys/dh2048.pem .

ls -l
