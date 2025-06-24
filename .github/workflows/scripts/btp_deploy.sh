#!/bin/bash
set -e

# ====== Environment Variables Required ======
# You must export/set these before running:
# cf_api_url, cf_user, cf_password, cf_org, cf_space

APP_NAME=bookshop

# echo '############## Initialize CAPM Project ##############'
# cds init --add tiny-sample $APP_NAME
# cd $APP_NAME

# echo '############## Set Up SQLite as Database ##############'
# npm install sqlite3 --save
# # Overwrite cds.requires in package.json
# npx cds add sqlite

echo '############## Install Dependencies ##############'
npm install

echo '############## Install CF CLI ##############'
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install -y cf8-cli

echo '############## Check CF CLI Installation ##############'
cf -v

echo '############## Install CF Plugins ##############'
cf add-plugin-repo CF-Community https://plugins.cloudfoundry.org
cf install-plugin multiapps -f
cf install-plugin html5-plugin -f

echo '############## Build CAPM Project ##############'
npx cds build --production --for nodejs

echo '############## Create MTA Project File if missing ##############'
[ -f mta.yaml ] || cds add mta

echo '############## Build MTA Archive ##############'
npm install --save-dev mbt
npx mbt build -p cf -t gen

echo '############## Authenticate with Cloud Foundry ##############'
cf api $cf_api_url
cf auth $cf_user "$cf_password"

echo '############## Target CF Org and Space ##############'
cf target -o $cf_org -s $cf_space

echo '############## Set Application Env to NODE_ENV=testing ##############'
cf push $APP_NAME --no-start
cf set-env $APP_NAME NODE_ENV testing
cf restage $APP_NAME

echo '############## Deploy MTA Archive to CF ##############'
cf deploy gen/mta_archives/*.mtar -f

echo '✅ Deployment complete for '$APP_NAME
