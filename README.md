# bash_scripts

# apipull.sh
A script to ease the pain of pulling the api repo (and running scheme and data migrations afterwards) locally. Before use, you must:
- set correct directory on line 4 (where your api folder clone is)

It will:
1. pull latest changes from remote repo
2. check if "Gemfile" was mentioned in the output (and run bundle install if it was)
3. run db:migrate (schema migration)
4. check for new data migrations and offer to run them
5. clean up after schema migration
6. offer to run sidekiq

It's worth mentioning that it saves data migration state to `~/.productive_api_migration_state` file.
