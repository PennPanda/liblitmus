#!/bin/bash

file=$1

awk '$3>x{x=$3};END{print x}' ${file} 
