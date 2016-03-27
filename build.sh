#!/bin/bash

cd www
for f in *.coffee; do
	echo "Building $f"
	coffee -cb "$f"
done
cd ..
