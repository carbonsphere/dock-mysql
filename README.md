Author  : CarbonSphere <br>
Email   : carbonsphere@gmail.com<br>


<h2>Dockerfile for building MySQL Application. This Base image uses CentOS6</h2>

<h3> This image provides a MySQL DB Application on port 3306 and a default user is created at build time. Application attributes are moved into environment variable for others to link and interact with this DB application. Additional shell script included in image to aid user creation.</h3>

<h4>Steps for creating image from Dockerfile and running procedure:</h4>

<b>1 :</b> Clone dock-mysql.git
<pre>
<b>Command: </b>
git clone https://github.com/carbonsphere/dock-mysql.git
</pre>

<b>2 :</b> Build docker image from Dockerfile
<pre>
<b>Command: </b>
#Change Directory
cd Docker-Mysql-PHPMyAdmin

#Build Image
sudo docker build -t #YOUR_IMAGE_NAME# .
#ex:  sudo docker build -t youraccount/docker-mysql-phpmyadmin .
</pre>

<b>3 :</b> Run image
<pre>
<b>Command: </b>
sudo docker run -d -P youraccount/docker-mysql-phpmyadmin 

</pre>

<b>4 :</b> Run image
<pre>
<b>Command: </b>
sudo docker run -d -P --name db youraccount/docker-mysql-phpmyadmin 

#docker_daemon_ip#:#image_port#
docker_daemon_ip can be found using "boot2docker ip" or you can check your environment variable "echo $DOCKER_HOST"
image_port can be found using "docker port db"

</pre>
