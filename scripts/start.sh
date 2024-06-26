#!/bin/bash
bundle exec rake db:create
bundle exec rake db:prepare
bundle exec rails db:migrate
bundle exec rails signup:seed_organization
bundle exec rails s -b ::
