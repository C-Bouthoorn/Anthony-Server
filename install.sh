#!/bin/bash

sudo apt-get install nodejs npm ruby gem curl

chmod +x ./setupnode.sh
./setupnode.sh

sudo npm install -g coffee-script
sudo gem install sass

sudo npm install
