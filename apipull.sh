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

# Step 3: bundle exec rails db:migrate
echo '🤖 Running database migrations...'
migrate_command="bundle exec rails db:migrate"
eval "${migrate_command}"

# Step 4: offer data migrations (if any new)
migration_dir="lib/tasks/migrations"
migration_state_file="$HOME/.productive_api_migration_state"
if [[ -f "$migration_state_file" ]]; then
  IFS=$'\n'
  migration_state=($(cat "$migration_state_file"))
  unset IFS
else
  touch "$migration_state_file"
  migration_state=()
fi

for migration_file in "$migration_dir"/**/*.rake; do
  file_name=$(basename "$migration_file")
  file_path=$(dirname "$migration_file" | sed "s|$migration_dir/||")
  migration_file_name="$file_path/$file_name"
  migration_tasks=$(grep -E '^ *task [^:]+:' "$migration_file" | sed -E 's/^ *task ([^:]+):.*/\1/')

  for migration_task in $migration_tasks; do
    migration_identifier="$migration_file_name - $migration_task"

    if [[ ! " ${migration_state[*]} " =~ " ${migration_identifier} " ]]; then
      echo
      echo "🤖 New migration detected: $migration_identifier"
      read -p "🤖 Run it, never run it or just skip it for now? [y/n/*] " -n 1 -r
      echo
      if [[ $REPLY = "y" ]]; then
        migration_command="bundle exec rails migrations:$migration_task"
        echo "🤖 Running migration..."
        if eval "${migration_command}"; then
          echo "$migration_identifier" >> "$migration_state_file"
          echo "🤖 Migration successful: $migration_task"
        else
          echo "🤖 Migration failed: $migration_task"
          read -p "🤖 Ignore it? [y/n] " -n 1 -r
          echo
          if [[ $REPLY = "y" ]]; then
            echo "🤖 Ignoring migration..."
            echo "$migration_identifier" >> "$migration_state_file"
          fi
        fi
      elif [[ $REPLY = "n" ]]; then
        echo "🤖 Ignoring migration..."
        echo "$migration_identifier" >> "$migration_state_file"
      else
        echo "🤖 Skipping migration for now..."
      fi
    fi
  done

done

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
