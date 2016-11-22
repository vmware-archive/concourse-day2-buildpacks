#!/bin/bash

set -e

echo "C0 Day 2 Pipeline has triggered for $(cat pipeline-triggered-buildpack/buildpack-*.id)" > run-info/subject
echo "NULL" > run-info/body
