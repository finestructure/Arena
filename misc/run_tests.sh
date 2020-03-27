#!/bin/sh

swift build

for dep in "finestructure/Gala" \
           "finestructure/Parser" \
           "alamofire/alamofire" \
           "pointfreeco/swift-gen" \
           "~/Projects/Parser" \
           "git@github.com:finestructure/parser"
do
    echo "-------------------------"
    echo Test: $dep
    swift run arena ${dep} -f --skip-open
    echo
done
echo "-------------------------"
