#!/bin/sh

if [ "${MYSQL_SLAVE_PASS}" == "DEFAULT" ]; then
  echo "Default password detected. Generating new slave account password"
  MYSQL_SLAVE_PASS=$(uuidgen -t | md5sum | cut -c 1-20)
fi

if [ "${MYSQL_PASS}" == "carbon" ]; then
  echo "Default remote user password detected. Generating new remote account password"
  MYSQL_PASS=$(uuidgen -t | md5sum | cut -c 1-10)
  echo "New Remote password = ${MYSQL_PASS}"
fi


echo "Slave account password = ${MYSQL_SLAVE_PASS}"

if [ "${MYSQL_ID}" != "1" ]; then
  echo "Server ID = ${MYSQL_ID}"
  sed -i "/server-id =/c\server-id = ${MYSQL_ID}" /etc/my.cnf
fi

if [ "${MYSQL_MASTER_HOST}" != "DEFAULT" ]; then
  echo "Setting master username and passwords ${MYSQL_MASTER_USER}:${MYSQL_MASTER_PASS}@${MYSQL_MASTER_HOST}"
  sed -i "/master-host/c\master-host = ${MYSQL_MASTER_HOST}" /etc/my.cnf
  sed -i "/master-user/c\master-user = ${MYSQL_MASTER_USER}" /etc/my.cnf
  sed -i "/master-password/c\master-password = ${MYSQL_MASTER_PASS} " /etc/my.cnf
  sed -i "/master-connect-retry/c\master-connect-retry = 60" /etc/my.cnf
fi

service mysqld start
sleep 5

echo "Setting mysql slave account password"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "grant replication slave on *.* TO ${MYSQL_SLAVE_USER}@'%' identified by '${MYSQL_SLAVE_PASS}'; GRANT USAGE ON *.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}'; FLUSH PRIVILEGES;"

service mysqld stop
sleep 5

/usr/bin/mysqld_safe
