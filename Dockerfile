############################################################
# Dockerfile: CentOS6/MySQL
# Pure MySQL DB Application with default user
# Set application attribue with environment variable
############################################################
FROM centos:centos6

MAINTAINER CarbonSphere <CarbonSphere@gmail.com>

# Add Environment Variables
ENV MYSQL_USER				carbon
ENV MYSQL_PASS 				carbon
ENV MYSQL_ROOT_PASSWORD 	carbon
ENV MYSQL_PORT				3306

# Add create user & db script to root
ADD createUserDb.sh /

# Install MySQL
RUN yum -y install mysql-server mysql-client && \
	yum -y clean all && \
	chmod +x /createUserDb.sh && \
	# Modify my.cfg
	echo -e "\nsocket=/var/lib/mysql/mysql.sock" >> /etc/my.cfg

# MySQL : $MYSQL_PORT
EXPOSE $MYSQL_PORT

# Start MySQL
RUN service mysqld start && \
	sleep 5 && \
    /usr/bin/mysqladmin -u root password ${MYSQL_ROOT_PASSWORD} && \
    # Move MySQL script to run command in docker file \
	mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER '${MYSQL_USER}' IDENTIFIED BY '${MYSQL_PASS}'; \
		REVOKE ALL PRIVILEGES,GRANT OPTION from ${MYSQL_USER}; \
		GRANT USAGE ON *.* to '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}'; \
		GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION; \
		FLUSH PRIVILEGES;"

CMD ["/usr/bin/mysqld_safe"]
