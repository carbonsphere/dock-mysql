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
  sed -i "/log-slave-updates/c\log-slave-updates = 1 " /etc/my.cnf
  sed -i "/master-connect-retry/c\master-connect-retry = 60" /etc/my.cnf
fi

if [ -d "${MYSQL_SSL_PATH}" ]; then
  echo "SSL Path Detected. Enabling SSL Certificates in configuration file."
  sed -i "/ssl-ca/c\ssl-ca = ${MYSQL_SSL_PATH}/${MYSQL_SSL_CA}" /etc/my.cnf
  sed -i "/ssl-cert/c\ssl-cert = ${MYSQL_SSL_PATH}/${MYSQL_SSL_CERT}" /etc/my.cnf
  sed -i "/ssl-key/c\ssl-key = ${MYSQL_SSL_PATH}/${MYSQL_SSL_KEY}" /etc/my.cnf
fi

service mysqld start
sleep 5

echo "Setting mysql slave account password"

if [ -d "${MYSQL_SSL_PATH}" ]; then
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "grant replication slave on *.* TO ${MYSQL_SLAVE_USER}@'%' identified by '${MYSQL_SLAVE_PASS}' REQUIRE SSL; GRANT USAGE ON *.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}' REQUIRE SSL; FLUSH PRIVILEGES;STOP SLAVE;CHANGE MASTER TO MASTER_SSL=1,MASTER_SSL_CA='${MYSQL_SSL_PATH}/ca.pem',MASTER_SSL_CERT='${MYSQL_SSL_PATH}/client1/client1.pem',MASTER_SSL_KEY='${MYSQL_SSL_PATH}/client1/client1-key.pem';START SLAVE;"
else 
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "grant replication slave on *.* TO ${MYSQL_SLAVE_USER}@'%' identified by '${MYSQL_SLAVE_PASS}'; GRANT USAGE ON *.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}'; FLUSH PRIVILEGES;"
fi


service mysqld stop
sleep 5

/usr/bin/mysqld_safe
