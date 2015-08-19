Author  : CarbonSphere <br>
Email   : carbonsphere@gmail.com<br>

## Dockerfile for building MySQL Application. This Base image uses CentOS6

### This image provides a MySQL DB Application on port 3306 and a default user is created at build time. Application attributes are moved into environment variable for others to link and interact with this DB application. Additional shell script included in image to aid user creation.

#### Steps for creating image from Dockerfile and running procedure:

**1 :** Clone dock-mysql.git

> git clone https://github.com/carbonsphere/dock-mysql.git


**2 :** Build docker image from Dockerfile
Change Directory

> cd dock-mysql

	- Build Image

> sudo docker build -t #YOUR_IMAGE_NAME# .

	- ex:  sudo docker build -t youraccount/dock-mysql .


**3 :** Run image

> sudo docker run -d -P youraccount/dock-mysql


**4 :** Run image

> sudo docker run -d -P --name db youraccount/dock-mysql 

- docker_daemon_ip#:#image_port#

docker_daemon_ip can be found using "boot2docker ip" or you can check your environment variable "echo $DOCKER_HOST"
image_port can be found using "docker port db"

# Updates
--------
This is an automatic MySQL replication container. It automatically chains linked containers as you start it.

For security consideration - Default remote and slave accounts will now have a randomly generated passwords. Passwords can be obtained by using "docker logs" command.

- Single docker host environment startup procedure.

1. Start first MySQL container and name it "mysql".

> docker run -d --name mysql -p 3306:3306 carbonsphere/dock-mysql


2. Obtain remote & slave keys in logs

> docker logs mysql


	Log Example:
	------------
	Default password detected. Generating new slave account password
	Default remote user password detected. Generating new remote account password
	New Remote password = aaaaaaaaa
	Slave account password = bbbbbbbb8da6092db237
	Starting mysqld:  [  OK  ]
	Setting mysql slave account password

3. Start second MySQL Container and create link to first container

> docker run -d --name mysql2 -p 3307:3306 -e MYSQL_ID=2 -e MYSQL_MASTER_HOST="db" -e MYSQL_MASTER_PASS="bbbbbbbb8da6092db237" --link mysql:db carbonsphere/dock-mysql

```
	Required Environment variables:
	-------------------------------
	MYSQL_ID   				- Server ID (all servers must have different id)
	MYSQL_MASTER_HOST 		- Server IP or linked name
	MYSQL_MASTER_USER		- (Optional) default 'carbonSlave'
	MYSQL_MASTER_PASS		- Slave account password from first container
```
	Note: If you would like to create more replication container, you must obtain "mysql2" slave account password for the thrid container.


4. Check slave server (mysql2) status.

> mysql>  show slave status;


	If no error is present, then it is synced up with first container.

5. For creating round robin replication or Master-Master Replication.

	Run the following mysql command on first (mysql) container.
```
	mysql> slave stop;
	mysql> CHANGE MASTER TO MASTER_HOST='mysql2_ip',MASTER_USER='mysql2_slave_user',MASTER_PASSWORD='mysql2_slave_password';
	mysql> slave start;
	mysql> show slave status;
```

	If no errors are present, then it is setup properly.

