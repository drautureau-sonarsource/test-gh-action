#!/bin/bash

set -euo pipefail

# Set committer identity
github_user="drautureau-sonarsource"
git config --global user.email "${github_user}@sonarsource.com"
git config --global user.name "${github_user}"

echo "DEBUG get log on master"
git log --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ar)%Creset' -5

echo "Checkout the branch 'check-update-of-sq-plugin-api'"
git fetch origin check-update-of-sq-plugin-api
git checkout check-update-of-sq-plugin-api

echo "DEBUG get log on check-update-of-sq-plugin-api"
git log --graph --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ar)%Creset' -5

echo "Rebase on master"
git rebase master

echo "Get the lastest master version of the SQ plugin API"
group_id="org.sonarsource.sonarqube"
artifact_id="sonar-plugin-api"
version=$(curl -s -u"${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
          "${ARTIFACTORY_URL}/api/search/latestVersion?g=${group_id}&a=${artifact_id}&repos=sonarsource-builds")
echo "Lastest master version of the SQ plugin API is ${version}"

if grep -Fq "${group_id}:${artifact_id}:${version}" build.gradle
then
  echo "Lastest master version of the SQ plugin API is already used. Nothing to do then!"
  exit 0
else
  echo "Upgrade the dependency with the new version"
  sed -i "s/${group_id}:${artifact_id}:.*'/${group_id}:${artifact_id}:${version}'/g" build.gradle

  echo "Commit and push the change"
  git commit -am "Upgrade SQ plugin API to version $version"

  echo "Push force (kindly)"
  git push --force-with-lease
fi
