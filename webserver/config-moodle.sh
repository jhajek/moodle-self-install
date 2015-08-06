#!/bin/bash

set -x

##########################
# Moosh - moodle shell
##########################

 sudo apt-add-repository 'deb http://ppa.launchpad.net/zabuch/ppa/ubuntu trusty main'
 sudo apt-get update
 sudo apt-get install moosh
 
# moosh plugin-fetchinfo -p /mnt/vol-01/moodle > ~/plugins.json
# (run it first to get plugin shortnames -- takes a while) 
 
# make sure this directory exists to save 3 days of head scratching why the plugin-install fails
 mkdir -p /root/.moosh/moodleplugins

 moosh -n -p /mnt/vol-01/moodle plugin-list | grep theme_essential
 moosh -n -p /mnt/vol-01/moodle plugin-install theme_essential 2.8

# All done