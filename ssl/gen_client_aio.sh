#!/bin/bash
echo -e "Checking for \"carbonsphere/dock-easy-rsa\" docker image\n"

IMG=`docker images |grep carbonsphere/dock-easy-rsa`

if [ "$?" == "1" ]; then
  echo "please download \"carbonsphere/dock-easy-rsa\" first! ex: docker pull carbonsphere/dock-easy-rsa"
  exit
fi

if ! [ -d "keys" ]; then
  echo -e "Create keys directory"
  mkdir keys
fi

DCONTAIN=`docker ps -a |grep carbonsphere/dock-easy-rsa`
if [ "$?" != "1" ]; then
  echo "A copy of dock-easy-rsa is in process. Please terminate it before running EX: docker rm easy-rsa"
  exit
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

CONF=$srvname.ovpn

echo -e "\nCreate Client ovpn file  $CONF\n"

echo "client" > $CONF
echo "nobind" >> $CONF
echo "dev tun" >> $CONF
echo "resolv-retry infinite" >> $CONF
echo "persist-key" >> $CONF
echo "persist-tun" >> $CONF
echo "comp-lzo" >> $CONF
echo "verb 3" >> $CONF

read -p "Please enter remote host name or ip: " remote
read -p "Please enter remote host port: " port

echo "remote $remote $port tcp" >> $CONF
echo "<ca>" >> $CONF
cat ./keys/ca.crt >> $CONF
echo "</ca>" >> $CONF
echo "<dh>" >> $CONF
cat ./keys/dh2048.pem >> $CONF
echo "</dh>" >> $CONF
echo "<key>" >> $CONF
cat ./keys/$srvname.key >> $CONF
echo "</key>" >> $CONF
echo "<cert>" >> $CONF
cat ./keys/$srvname.crt >> $CONF
echo "</cert>" >> $CONF

read -p "Enable TLS Auth? [y/N] " tlsauth
if [[ ($tlsauth == 'y' ) || ( $tlsauth == 'Y') ]]; then
echo "#For tls-auth. " >> $CONF
echo "<tls-auth>" >> $CONF
  if ! [ -e "ta.key" ]; then
    echo "Warning: ta.key doesn't exist."
  else
    cat ta.key >> $CONF
  fi
echo "</tls-auth>" >> $CONF
echo "key-direction 1" >> $CONF
fi

echo "#For user PAM auth" >> $CONF
echo "#Besure auth_pam plugin is enabled in server.conf" >> $CONF
echo "#auth-user-pass" >> $CONF
echo "#redirect-gateway def1" >> $CONF
echo "auth-nocache" >> $CONF

