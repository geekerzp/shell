#!/bin/sh 
# 功能:无密码登陆远程主机

scp ~/.ssh/id_dsa.pub $1@$2:~/ 
ssh $1@$2 " touch ~/.ssh/authorized_keys ; cat ~/id_dsa.pub >> ~/.ssh/authorized_keys ; chmod 0644 ~/.ssh/authorized_keys; exit ;"
