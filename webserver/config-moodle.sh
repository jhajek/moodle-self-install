#!/bin/bash

set -x

##########################
# Moosh - moodle shell
##########################

 sudo apt-add-repository 'deb http://ppa.launchpad.net/zabuch/ppa/ubuntu trusty main'
 sudo apt-get update
 sudo apt-get install moosh
 
moosh plugin-fetchinfo > ~/plugins.json
# (run it first to get plugin shortnames -- takes a while) 
 
# make sure this directory exists to save 3 days of head scratching why the plugin-install fails
 mkdir -p /root/.moosh/moodleplugins

 moosh plugin-list theme_essential
 moosh plugin-install theme_essential 19

# All done