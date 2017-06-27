#!/bin/sh
NODES=5

INDEX=1
AINDEX=$INDEX
IMAGENAME='carbonsphere/dock-mysql'
STARTPORT=3307
TIMEOUT=100

while [ $AINDEX -le $NODES ]
  do 
    docker stop mysql$AINDEX; docker rm mysql$AINDEX
    echo Stop and remove mysql$AINDEX
    ((AINDEX++))
  done

docker run -d --name mysql$INDEX -p $STARTPORT:3306 $IMAGENAME; 

LOGA=$(docker logs mysql$INDEX |grep "Slave account password" | cut -d' ' -f 5)

echo Slave password = $LOGA

if [ "$LOGA" == '' ]; then
  echo "Error: empty password"
  exit
fi

AINDEX=$INDEX

while [ $AINDEX -lt $NODES ]
  do 
    PREINDEX=$AINDEX
    ((AINDEX++))
    ((STARTPORT++))

    docker run -d --name mysql${AINDEX} -p ${STARTPORT}:3306 -e MYSQL_ID=${AINDEX} -e MYSQL_MASTER_HOST="db${PREINDEX}" -e MYSQL_MASTER_PASS="${LOGA}" --link mysql${PREINDEX}:db${PREINDEX} ${IMAGENAME};
    
    LOG=$(docker logs mysql$AINDEX |grep "Slave account password" | cut -d' ' -f 5)
    
    echo "mysql${AINDEX} container's slave password = $LOG" 
 done

HOSTIP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' mysql${NODES})

if [ "$HOSTIP" == '' ]; then
  echo "Error: Host IP should not be empty."
  exit
fi
echo "Host IP = $HOSTIP"

echo "Show all node's slave status"
echo "Waiting on last node service to start"

while [ $TIMEOUT -gt 1 ]
  do
  sleep 2
  RET=$(docker logs mysql${NODES} |grep "mysqld_safe Starting mysqld")
  if [ "$RET" != '' ]; then
    echo "Service started."
    break
  fi
  ((TIMEOUT--))
  echo "Retrying..."
  done

if [ "$TIMEOUT" -eq 1 ]; then
  echo "Error: Timeout due to service undetected"
  exit
fi

echo "Linking last node to first node"

docker exec -it mysql${INDEX} mysql -uroot -pcarbon -e "slave stop; CHANGE MASTER TO MASTER_HOST='${HOSTIP}',MASTER_USER='carbonSlave',MASTER_PASSWORD='${LOGA}';slave start;"

AINDEX=$INDEX
while [ $AINDEX -le $NODES ]
  do
    echo "------------------ mysql${AINDEX} error status --------------------------"
    docker exec -it mysql${AINDEX} mysql -uroot -pcarbon -e "show slave status\G" |grep "Last_IO"
    echo "================== mysql${AINDEX} error status =========================="
    ((AINDEX++))
  done

AINDEX=$INDEX

while [ $AINDEX -le $NODES ]
  do
    echo "Create Test Database db${AINDEX} in mysql${AINDEX}"
    docker exec -it mysql${AINDEX} mysql -uroot -pcarbon -e "create database db${AINDEX};"
    ((AINDEX++)) 
  done

AINDEX=$INDEX

while [ $AINDEX -le $NODES ]
  do
    echo "Show mysql${AINDEX} database"
    docker exec -it mysql${AINDEX} mysql -uroot -pcarbon -e "show databases;"
    ((AINDEX++)) 
  done
