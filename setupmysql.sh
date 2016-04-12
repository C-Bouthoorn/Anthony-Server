#!/bin/bash


query() {
  qq=$1

  mysql --user="root" --password="root" --execute="$qq"
}

querydb() {
  qq=$1

  mysql --user="root" --password="root" --database="chat_dev" --execute="$qq"
}

# Create Database
query 'CREATE DATABASE chat_dev;'


# Create users table
querydb 'CREATE TABLE `users` (
  `id` int(16) AUTO_INCREMENT,
  `username` varchar(512),
  `password` varchar(512),
  `channel_perms` varchar(256) DEFAULT "",
  `type` varchar(32) DEFAULT "",
  PRIMARY KEY (`id`)
)'

# Create channels table
querydb 'CREATE TABLE `channels` (
  `id` int(8) AUTO_INCREMENT,
  `name` varchar(64),
  `joined` varchar(512) DEFAULT "",
  PRIMARY KEY (`id`)
)'
