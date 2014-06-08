#!/usr/bin/env bash

sudo yum install -y ntp ntpdate ntp-doc
# looks like we already had ntpd and ntpupdate installed
sudo chkconfig ntpd on
sudo service ntpd restart
cd /etc/yum.repos.d/
sudo wget http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.6.0/ambari.repo
cd
sudo yum -y install ambari-server ambari-agent

# fix  "message" : "Attempted to add unknown hosts to a cluster.  These hosts have not been registered with the server: ip-10-233-132-184.us-west-2.compute.internal"
#sudo mkdir -p /etc/ambari-agent/conf/
# need to write hostname=ip-10-233-132-184.us-west-2.compute.internal to /etc/ambari-agent/conf/ambari-agent.ini
#echo 'hostname=ip-10-253-35-49.us-west-2.compute.internal' >> /etc/ambari-agent/conf/ambari-agent.ini  # this is the value for ambp2

sudo ambari-agent restart
sudo ambari-server setup -v -s
sudo ambari-server restart



# POST /api/v1/blueprints/single-node-hdfs-yarn
#works
#curl -v -X POST -d @blueprint-1.json http://admin:admin@localhost:8080/api/v1/blueprints/ethan-bp-1 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'

#curl -v -X POST -d @create-cluster-1.json http://admin:admin@localhost:8080/api/v1/blueprints/single-node-hdfs-yarn --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'

# create cluster
#/api/v1/clusters/MySingleNodeCluster
# in the docs, default-password field should be default_password
#curl -v -X POST -d @cluster-creation-template-1.json http://admin:admin@amb:8080/api/v1/clusters/cl2 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'

#issues:
#ambari-server start -s is awesome. but it assigns default password to PostGres 'bigdata'. I don't like having predictable default passwords.
#so, i also made the default passwords for Hive (mysql metastore), Oozie (Derby) and Nagios be 'bigdata'.
#weird, gotta enclose the json file in quotes

# need to try the create cluster json with localhost in place of ip-10-253-35-49.us-west-2.compute.internal

#curl -v -X POST -d @simple-blueprint.json http://admin:admin@amb-bp-target-simple-1:8080/api/v1/blueprints/blueprint-exemplarcluster --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'
#curl -v -X POST -d @simple-cluster-creation.json http://admin:admin@amb-bp-target-simple-1:8080/api/v1/clusters/cl1 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'




#note: bug in making blueprints - it isn't giving me a nagios password in 'configurations' section. in fact it isn't making such a section.

# actually working!
curl -v -X POST -d @blueprint-big-1.json http://admin:admin@localhost:8080/api/v1/blueprints/bp-all-services --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'

my_fqdn=$(hostname -f)
sed s/FQDN_GOES_HERE/$my_fqdn/ cluster-creation-raw.json > echo cluster-creation.json

curl -v -X POST -d @cluster-creation.json http://admin:admin@localhost:8080/api/v1/clusters/cl1 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'
