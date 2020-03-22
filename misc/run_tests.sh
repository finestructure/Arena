#!/bin/sh

swift build

for cmd in "arena https://github.com/pointfreeco/swift-gen.git"
do
    echo "-------------------------"
    echo $cmd
    swift run ${cmd} -f --skip-open
    echo
done
echo "-------------------------"
