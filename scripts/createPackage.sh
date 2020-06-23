#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

echo "List existing package versions"
sfdx force:package:version:list -p apex-domainbuilder -v DevHubPrivate

echo "Create new package version"
PACKAGE_VERSION="$(execute sfdx force:package:version:create --package $PACKAGENAME --installationkeybypass --wait 10 --json | jq '.result.SubscriberPackageVersionId' | tr -d '"')"
echo $PACKAGE_VERSION

if [ "$QA_URL" ]; then
  echo "Authenticate and install in QA Org"

  echo $QA_URL > qaURLFile
  sfdx force:auth:sfdxurl:store -f qaURLFile -a $QA_ORG_ALIAS
  rm qaURLFile

  sfdx force:package:install -p $PACKAGE_VERSION -u $QA_ORG_ALIAS --publishwait 3 --wait 10 -r
fi
