#!/bin/bash

# Check if in the correct directory
api_dir="$HOME/code/productive/api"

if [[ ! -d $api_dir ]]; then
  echo "🤖 Directory $api_dir does not exist!"
  return 1
fi

echo "🤖 Changing directory to $api_dir"
cd "$api_dir" || return 1

# Step 1: git pull
echo '🤖 Pulling latest changes from remote repository...'
pull_output=$(git pull)

# Check if Gemfile or Gemfile.lock was mentioned in the output
if echo "$pull_output" | grep -q -E "(Gemfile|Gemfile.lock)"; then
  # Step 2: bundle install
  echo '🤖 Installing gem dependencies...'
  bundle install
fi

# Step 3: run schema migrations
echo '🤖 Running schema migrations...'
migrate_command="bundle exec rails db:migrate"
eval "${migrate_command}"

# Step 4: run data migrations
echo '🤖 Running data migrations...'
migrate_command="bundle exec rails data:migrate"
eval "${migrate_command}"

# Step 5: git restore .
echo '🤖 Cleaning up...'
git restore .
echo '🤖 Done!'

# Step 6: bundle exec sidekiq
read -p "🤖 Run Sidekiq? [y/n] " -n 1 -r
echo
if [[ $REPLY = "y" ]]; then
  sidekiq_command="bundle exec sidekiq"
  eval "${sidekiq_command}"
fi
