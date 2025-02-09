#!/bin/sh

git config --global user.name "Arno Dirlam"
git config --global user.email "arnodirlam@googlemail.com"
git config --global user.signingkey 87970B680299992D
git config --global commit.gpgsign true

git config --global push.default simple
git config --global --bool pull.rebase true

gpg --list-secret-keys --keyid-format LONG
