#!/bin/bash

./scripts/generate.rsa.sh

rm -f ./tmp/pids/server.pid
bundle install

rake db:create
rake db:migrate:all
bundle exec rails signup:seed_organization
rails s -b 0.0.0.0
