#!/bin/bash

build() {
	for f in *.coffee; do
		if [ -e $f ]; then
			echo "Building $f"
			coffee -cb "$f"
		fi
	done

	for f in *.scss; do
		if [ -e $f ]; then
			echo "Building $f"
			sass --update -q "$f"
		fi
	done
}

build

cd www
	build
	cd ..
