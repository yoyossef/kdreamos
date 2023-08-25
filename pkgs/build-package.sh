#!/bin/bash

set -x

sudo chown -R build:build /workdir/pkgs

PIKAUR_CMD="PKGDEST=/workdir/pkgs pikaur --noconfirm -S -P /workdir/${1}/PKGBUILD"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
"${PIKAUR_RUN[@]}"
# remove any epoch (:) in name, replace with -- since not allowed in artifacts
for i in $(seq 1 1000);
do
    sleep 1
    echo ${1}
done

#find /workdir/pkgs/*.pkg.tar* -type f -name '*:*' -execdir bash -c 'mv "$1" "${1//:/--}"' bash {} \;
