#!/bin/bash

build() {
	for f in *.coffee; do
		# Check if file exists and is readable
		if [ -f $f ]; then
			echo "Building $f"
			coffee -cb "$f"
		fi
	done

	for f in *.scss; do
		# Check if file exists and is readable
		if [ -f $f ]; then
			echo "Building $f"
			sass --update -flq "$f"
		fi
	done
}

build

cd www
	build
	cd ..
