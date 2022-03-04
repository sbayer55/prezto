#!/bin/bash

java_dir=($(echo "$JAVA_HOME" | tr / " "))
echo "Java Version: ${java_dir[5]}"
