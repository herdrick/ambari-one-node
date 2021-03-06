#!/usr/bin/env bash

function wait_until_some_http_status () {
    url=$1
    target_status=$2
    s=0
    while [ $s != $target_status ]; do
        s=$(curl -o /dev/null -s -w %{http_code} $url)
        if [ $s == "000" ]
        then
            echo "<no response from server>"
        else
            echo "HTTP status: $s"
        fi
        sleep 2
    done
}

echo "First install and start needed services"
sudo yum install -y ntp ntpdate ntp-doc  # in many installs, ex. RHEL EC2 AMI, we already have ntpd and ntpupdate installed
sudo chkconfig ntpd on
sudo service ntpd restart
echo "To get ambari with yum we need the Hortonworks repo"
sudo wget -P /etc/yum.repos.d/ http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.6.0/ambari.repo
sudo yum -y install ambari-server ambari-agent

sudo ambari-agent restart
sudo ambari-server setup -v -s
sudo ambari-server restart

echo "Trying http://localhost:8080/api/v1/blueprints to confirm Ambari server is up..."
wait_until_some_http_status "http://admin:admin@localhost:8080/api/v1/blueprints" "200"
sleep 2 # wait a few moments longer just to let the server settle down

echo "Add the blueprint-big-1.json blueprint file to our Ambari server's available blueprints"
curl -v -X POST -d @blueprint-big-1.json http://admin:admin@localhost:8080/api/v1/blueprints/bp-all-services --header "Content-Type:application/json" --header "X-Requested-By:mycompany"

echo "Trying http://localhost:8080/api/v1/clusters to confirm Ambari server is still up..."
wait_until_some_http_status "http://admin:admin@localhost:8080/api/v1/clusters" "200"

echo "Replace the dummy hostname in the cluster creation JSON file with this host's fully qualified domain name"
my_fqdn=$(hostname -f)
sed s/FQDN_GOES_HERE/$my_fqdn/ cluster-creation-raw.json > cluster-creation.json

echo ""
echo "Pausing for 15 seconds to let Ambari server settle down"
sleep 15
echo "Now cause a cluster to be created with our loaded blueprint"
curl -v -X POST -d @cluster-creation.json http://admin:admin@localhost:8080/api/v1/clusters/cl1 --header "Content-Type:application/json" --header "X-Requested-By:mycompany"
echo ""
echo "Single node Ambari setup finished. Point browser to localhost:8080 and log in as admin:admin to use Ambari."
