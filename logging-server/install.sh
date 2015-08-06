#!/bin/bash

set -x

# http://www.ubuntugeek.com/install-ganglia-on-ubuntu-14-04-server-trusty-tahr.html
sudo apt-get install ganglia-monitor rrdtool gmetad ganglia-webfrontend

cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf



