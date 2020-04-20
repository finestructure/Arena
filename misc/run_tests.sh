#!/bin/sh

set -euo pipefail

swift build

for dep in "finestructure/Gala" \
           "finestructure/Parser" \
           "alamofire/alamofire" \
           "pointfreeco/swift-gen" \
           "~/Projects/Parser" \
           "git@github.com:finestructure/parser" \
           "Peter-Schorn/Swift_Utilities"
do
    echo "-------------------------"
    echo Test: $dep
    swift run arena ${dep} -f --skip-open
    echo
done
echo "-------------------------"
