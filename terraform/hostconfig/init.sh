# patch the system
sudo yum update -y
sudo yum install epel-release -y

# enable auto updates
sudo yum install -y yum-cron
sudo systemctl stop yum-cron
sudo systemctl enable yum-cron.service
sudo mv /etc/yum/yum-cron-hourly.conf /etc/yum/yum-cron-hourly.conf.org
sudo mv yum-cron-hourly.conf /etc/yum/yum-cron-hourly.conf
sudo chown root:root /etc/yum/yum-cron-hourly.*
sudo systemctl start yum-cron

# Python3
sudo yum install -y centos-release-scl
sudo yum groupinstall -y 'Development Tools'
sudo yum install -y rh-python36

# App
sudo mkdir -p /usr/local/mcspaas/consumption/
sudo mv collector /usr/local/mcspaas/consumption/
sudo cd /usr/local/mcspaas/consumption/collector
sudo /opt/rh/rh-python36/root/usr/bin/pip install --upgrade pip
sudo /opt/rh/rh-python36/root/usr/bin/pip install -r /usr/local/mcspaas/consumption/collector/requirements.txt
sudo chmod u+x /usr/local/mcspaas/consumption/collector/collect.py