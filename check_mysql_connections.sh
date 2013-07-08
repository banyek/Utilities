#!/bin/bash
# Just a small script that shows how many connections are on a mysql server
# You can run it with watch, and then you can see the connection number
# changing.
hostname
netstat | grep mysql | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c
