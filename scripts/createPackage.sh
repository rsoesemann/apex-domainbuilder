#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

echo "List existing package versions"
sfdx force:package:version:list -p apex-domainbuilder -v $DEV_HUB_ALIAS

echo "Create new package version"
PACKAGE_VERSION="$(execute sfdx force:package:version:create -p $PACKAGENAME -v $DEV_HUB_ALIAS -x -w 10 --json | jq '.result.SubscriberPackageVersionId' | tr -d '"')"
echo $PACKAGE_VERSION

execute sfdx force:package:version:promote -p $PACKAGE_VERSION -v $DEV_HUB_ALIAS -n

if [ $secrets.QA_URL ]; then
  echo "Authenticate QA Org"
  echo $secrets.QA_URL > qaURLFile
  execute sfdx force:auth:sfdxurl:store -f qaURLFile -a $QA_ORG_ALIAS
  rm qaURLFile
fi

if [ $QA_ORG_ALIAS ]; then
  echo "Install in QA Org"
  execute sfdx force:package:install -p $PACKAGE_VERSION -u $QA_ORG_ALIAS -b 10 -w 10 -r
fi