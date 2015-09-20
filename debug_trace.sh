#!/bin/bash

FILE=debug_log_$1
cat /dev/litmus/log > $FILE

