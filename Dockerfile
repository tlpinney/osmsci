FROM ubuntu:16.04


RUN apt-get update 
RUN apt-get install -y less tmux curl python lsof wget openjdk-8-jdk openssh-client openssh-server vim mlocate

ENV APACHE_MIRROR https://apache.claz.org

# TODO - switch to hdfs user from root
#RUN useradd hdfs
#RUN mkdir -p /opt && chown hdfs.hdfs /opt
#USER hdfs:hdfs
#WORKDIR /opt



# Install hadoop
RUN wget -q ${APACHE_MIRROR}/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz \
  && tar xf hadoop-3.1.2.tar.gz \
  && rm hadoop-3.1.2.tar.gz

COPY hadoop/hadoop-env.sh /hadoop-3.1.2/etc/hadoop/hadoop-env.sh
COPY hadoop/hdfs-site.xml /hadoop-3.1.2/etc/hadoop/hdfs-site.xml
COPY hadoop/core-site.xml /hadoop-3.1.2/etc/hadoop/core-site.xml
COPY hadoop/mapred-site.xml /hadoop-3.1.2/etc/hadoop/mapred-site.xml
COPY hadoop/yarn-site.xml /hadoop-3.1.2/etc/hadoop/yarn-site.xml

# format a namenode

ENV HDFS_NAMENODE_USER root 
ENV HDFS_SECONDARYNAMENODE_USER root
ENV HDFS_DATANODE_USER root
ENV HADOOP_HOME /hadoop-3.1.2
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

WORKDIR /root
RUN mkdir -p /var/run/sshd
RUN mkdir -p .ssh
RUN cd .ssh && ssh-keygen -f id_rsa -t rsa -N ''
RUN cd .ssh && cat id_rsa.pub > authorized_keys


#RUN /usr/sbin/sshd -p 22 && ./sbin/start-dfs.sh 

# install hive 
WORKDIR /
RUN wget -q ${APACHE_MIRROR}/hive/hive-3.1.1/apache-hive-3.1.1-bin.tar.gz \
  && tar xf apache-hive-3.1.1-bin.tar.gz \
  && rm apache-hive-3.1.1-bin.tar.gz  
COPY hive/hive-site.xml /apache-hive-3.1.1-bin/conf/hive-site.xml

# install presto 
WORKDIR /
RUN wget -q https://repo1.maven.org/maven2/com/facebook/presto/presto-server/0.218/presto-server-0.218.tar.gz \
  && tar xf presto-server-0.218.tar.gz \
  && rm presto-server-0.218.tar.gz \
  && cd presto-server-0.218/bin \
  && wget -q https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.218/presto-cli-0.218-executable.jar \
  && mv presto-cli-0.218-executable.jar presto \
  && chmod +x presto

COPY presto/hive.properties /presto-server-0.218/etc/catalog/hive.properties
COPY presto/jmx.properties /presto-server-0.218/etc/catalog/jmx.properties
COPY presto/memory.properties /presto-server-0.218/etc/catalog/memory.properties
COPY presto/config.properties /presto-server-0.218/etc/config.properties
COPY presto/jvm.config /presto-server-0.218/etc/jvm.config
COPY presto/node.properties /presto-server-0.218/etc/node.properties

RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /usr/local/bin/dumb-init

# install mysql
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install libmysql-java mysql-server -yq
RUN ln -s /usr/share/java/mysql-connector-java.jar /apache-hive-3.1.1-bin/lib/mysql-connector-java.jar
COPY mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

#COPY entrypoint.sh /entrypoint.sh 
#RUN chmod +x /entrypoint.sh 

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
#CMD ["/entrypoint.sh"]

#  ./bin/hdfs --daemon start httpfs
# curl "http://localhost:14000/webhdfs/v1/user?op=LISTSTATUS&user.name=root"

# curl -i -X PUT "http://127.0.0.1:14000/webhdfs/v1/user/root/planet-latest.osm.fixedtile.orc?op=CREATE&overwrite=true&user.name=root"
# curl -i -X PUT -H "Content-Type: application/octet-stream" -T ../planet-latest.osm.fixedtile.orc "http://127.0.0.1:14000/webhdfs/v1/user/root/planet-latest.osm.fixedtile.orc?op=CREATE&data=true&user.name=root&overwrite=true"

# apt-get install libmysql-java mysql-server -yq
# needs to automate creation of password
# mysql -uroot -proot -e'CREATE DATABASE hcatalog;'
# ln -s /usr/share/java/mysql-connector-java.jar /apache-hive-3.1.1-bin/lib/mysql-connector-java.jar
# /etc/mysql/mysql.conf.d/mysqld.cnf
# datadir         = /tank/mysql
# mkdir -p /tank/mysql
# chown mysql /tank/mysql
# mysqld --initialize-insecure --user=root
# /etc/init.d/mysql start
# mysql -u root --skip-password
#  ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
# mysql -uroot -proot
# ./bin/schematool -initSchema -dbType mysql
#  echo 'CREATE DATABASE IF NOT EXISTS metastore_db;' | hive
# ./bin/presto --server localhost:8080 --catalog hive --schema default
