#!/usr/bin/env bash

sudo yum install -y ntp ntpdate ntp-doc
# looks like we already had ntpd and ntpupdate installed
sudo chkconfig ntpd on
sudo service ntpd restart
cd /etc/yum.repos.d/
sudo wget http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.6.0/ambari.repo
cd
sudo yum -y install ambari-server ambari-agent

#sudo mkdir -p /etc/ambari-agent/conf/
#echo "hostname=ip-10-233-132-184.us-west-2.compute.internal" > /etc/ambari-agent/conf/ambari-agent.ini   # not needed for RHEL

sudo ambari-agent restart
sudo ambari-server setup -v -s
sudo ambari-server restart

#issues:
# in the docs, default-password field should be default_password
# ambari-server start -s is awesome. but it assigns default password to PostGres 'bigdata'.
# weird, gotta enclose the json file in quotes
# note: bug in making blueprints - it isn't giving me a nagios contact email in 'configurations' section, which is required. in fact it isn't making such a section.


v=0
while [ $v != '200' ]; do
    v=$(curl -o /dev/null -s -w %{http_code} http://admin:admin@localhost:8080/api/v1/blueprints)
    echo "v = $v"
    path=''
    sleep 1
done

curl -v -X POST -d @blueprint-big-1.json http://admin:admin@localhost:8080/api/v1/blueprints/bp-all-services --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'
my_fqdn=$(hostname -f)
sed s/FQDN_GOES_HERE/$my_fqdn/ cluster-creation-raw.json > cluster-creation.json
curl -v -X POST -d @cluster-creation.json http://admin:admin@localhost:8080/api/v1/clusters/cl1 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'
