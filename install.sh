#!/bin/bash

sudo apt-get install -y nodejs npm ruby gem curl mysql-client mysql-server

chmod +x ./setupnode.sh
./setupnode.sh

sudo npm install -g coffee-script
sudo gem install sass

sudo npm install

./setupmysql.sh
