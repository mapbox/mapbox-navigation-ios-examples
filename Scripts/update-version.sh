#!/usr/bin/env bash

set -e
set -o pipefail
set -u

VERSION=$1

BASE_BRANCH_NAME="main"
BRANCH_NAME="update-version-${VERSION}"
git checkout -b $BRANCH_NAME
git add .
git commit -m "Update version ${VERSION}"
git push origin $BRANCH_NAME

brew install gh
GITHUB_TOKEN=$GITHUB_WRITER_TOKEN gh pr create \
    --title "Navigation v${VERSION}" \
    --body "Update to Mapbox Navigation ${VERSION}" \
    --base $BASE_BRANCH_NAME \
    --head $BRANCH_NAME
