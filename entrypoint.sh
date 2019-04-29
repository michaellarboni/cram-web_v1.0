#!/bin/bash
set -e

rm node_modules/* -Rf
rm public/libs/* -Rf

rm public/less/bootstrap/*.css -Rf

npm install
gulp

cd public/less/bootstrap/
make
cd ../../..

chmod 777 * -Rf

supervisord