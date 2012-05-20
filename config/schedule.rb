# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
env :MAILTO, '""' 

every 5.minutes do
  rake "cache:points"
  rake "cache:proposals"
end

# backup database
every 1.week do
  command "backup perform --trigger my_backup"
end

# Learn more: http://github.com/javan/whenever
