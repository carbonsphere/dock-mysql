#!/bin/bash
if ! [ -d "keys" ]; then
  echo -e "Create keys directory"
  mkdir keys
fi

touch ./keys/index.txt
echo "00" > ./keys/serial
