#!/bin/bash

ssh -tt nsroot@172.16.124.10 <<EOF
disable ntp sync
shell
ntpdate 172.16.124.50
rm -rf /var/krb/*
exit
enable ntp sync
save ns config
exit
EOF
