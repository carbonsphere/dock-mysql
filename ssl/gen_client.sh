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
  echo -e "Error: Please create vars or you can use default vars by \"cp vars.example vars\" then run gen_ca_init.sh"
  echo -e "Edit vars to enter your default certificate generation variable."
  exit
fi

if ! [ -e "keys/ca.crt" ]; then
  echo "Error: CA certificate and key not found. Please run gen_init.sh first"
  exit
fi

echo -e "\nGenerating client certificate and keys.\n"
read -p "Please enter client name[client1]: " srvname

if [ "$srvname" == "" ]; then
  srvname="client1";
fi

echo -e "\nCreating $srvname"

docker run -it --rm --name easy-rsa -v $(pwd)/keys:/easy-rsa --env-file vars carbonsphere/dock-easy-rsa /er/build-key $srvname

echo -e "\nCreate Client directory and moving necessary files\n"

mkdir $srvname
cp ./keys/ca.crt ./$srvname
cp ./keys/$srvname.crt ./$srvname
cp ./keys/$srvname.key ./$srvname

ls -l ./$srvname
