#!/bin/bash

if [ $# -eq 0 ]
then
    echo "usage: chrom-cli new NAME"
    echo "usage: chrom-cli build"
    echo "usage: chrom-cli dev"
    exit 1
fi

if [ $1 = "build" ]
then
    if [ ! -f meta.json ]; then
        echo "meta.json file missing. Not a chromstahl project?"
        exit 1
    fi

    NAME=$(cat meta.json | jq -r ".name")

    if [ -d backend ]; then
        cd backend/ && ./gradlew build && cd ../ && mv backend/build/libs/*.jar plugin.jar
    else
        echo "no backend present, skipping";
    fi

    if [ -d frontend ]; then
        cd frontend/ && npm install && npm run build && npm pack && cd ../ && mv frontend/*.tgz frontend.tgz
    else
        echo "no frontend present, skipping";
    fi

    tar -zcvf $NAME.tar.gz meta.json plugin.jar frontend.tgz
fi

if [ $1 = "new" ]
then
    NAME=$2
    echo $PWD


    mkdir $NAME && cd $NAME && git init
    mkdir frontend/
    mkdir backend/
    cat << EOF >> meta.json
{
    "name": "$NAME",
    "author": "example",
    "version": 1
}
EOF
fi

if [ $1 = "dev" ]
then
    echo "Setting up mock enviroment"
    DIR="$(pwd)"

    # the temp directory used, within $DIR
    # omit the -p parameter to create a temporal directory in the default location
    WORK_DIR=`mktemp -d -p "$DIR"`

    # check if tmp dir was created
    if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
        echo "Could not create temp dir"
        exit 1
    fi

    # deletes the temp directory
    function cleanup {
        cd "$WORK_DIR" && docker-compose down
        cd ../
        rm -rf "$WORK_DIR"
        echo "Deleted temp working directory $WORK_DIR"
    }

    # register the cleanup function to be called on the EXIT signal
    trap cleanup EXIT
    PKG_NAME=$(jq -r ".name" frontend/package.json)

    echo "Setting up npm link... this may require sudo"
    cd frontend && sudo npm link

    cd $WORK_DIR

    git clone https://github.com/chromstahl-cms/frontend.git && cd frontend/

    npm install
    npm link $PKG_NAME

    FRONTEND="$(pwd)"

    cd $WORK_DIR

    function dockerCompose {
        cat << EOF >> docker-compose.yml
version: "3"

services:
  db:
    environment:
      MYSQL_ROOT_PASSWORD: kloudfile
      MYSQL_DATABASE: kms
    image: mysql:5.7
    ports:
      - 3306:3306
    volumes:
      - ./mysql/lib:/var/lib/mysql
      - ./mysql/cnf:/etc/mysql/conf.d
      - ./mysql/log:/var/log/mysql
EOF
    }

    dockerCompose

    docker-compose up -d

    cd $DIR && cd backend/ && ./gradlew install

fi
