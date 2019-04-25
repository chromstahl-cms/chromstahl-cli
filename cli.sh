#!/bin/bash

if [ $# -eq 0 ]
then
    echo "usage: chrom-cli new NAME"
    echo "usage: chrom-cli build"
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


    mkdir test && cd test && git init
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
