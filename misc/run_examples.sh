#!/bin/sh

set -euo pipefail

swift build

for cmd in "arena --version"\
           "arena https://github.com/finestructure/Gala" \
           "arena finestructure/Gala" \
           "arena ~/Projects/Parser" \
           "arena ~/Projects/Parser finestructure/Gala"
do
    echo "-------------------------"
    echo $cmd
    swift run ${cmd} -f --skip-open
    echo
done
echo "-------------------------"
