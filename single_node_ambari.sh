#!/usr/bin/env bash

function wait_until_some_http_status () {
    url=$1
    target_status=$2
    s=0
    while [ $s != $target_status ]; do
        s=$(curl -o /dev/null -s -w %{http_code} $url)
        if [ $s == '000' ]
        then
            echo "<no response from server>"
        else
            echo "HTTP status: $s"
        fi
        sleep 1
    done
}

sudo yum install -y ntp ntpdate ntp-doc
# looks like we already had ntpd and ntpupdate installed
sudo chkconfig ntpd on
sudo service ntpd restart
sudo wget -P /etc/yum.repos.d/ http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.6.0/ambari.repo
sudo yum -y install ambari-server ambari-agent

sudo ambari-agent restart
sudo ambari-server setup -v -s
sudo ambari-server restart

echo "trying http://localhost:8080/api/v1/blueprints to confirm Ambari server is up..."
wait_until_some_http_status "http://admin:admin@localhost:8080/api/v1/blueprints" "200"
sleep 2

curl -v -X POST -d @blueprint-big-1.json http://admin:admin@localhost:8080/api/v1/blueprints/bp-all-services --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'

echo "trying http://localhost:8080/api/v1/clusters to confirm Ambari server is still up..."
wait_until_some_http_status "http://admin:admin@localhost:8080/api/v1/clusters" "200"

my_fqdn=$(hostname -f)
sed s/FQDN_GOES_HERE/$my_fqdn/ cluster-creation-raw.json > cluster-creation.json

curl http://admin:admin@localhost:8080/api/v1/hosts

echo 'pausing for 15 seconds to let Ambari server settle down'
sleep 15
curl -v -X POST -d @cluster-creation.json http://admin:admin@localhost:8080/api/v1/clusters/cl1 --header "Content-Type:application/json" --header 'X-Requested-By:mycompany'
