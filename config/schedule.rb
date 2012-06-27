# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

env :MAILTO, '""' 
env :PATH, ENV['PATH']

set :output, 'log/cron_log.log'

job_type :envcommand, 'cd :path && RAILS_ENV=:environment :task'

# on some systems, need to source rvm before running standard rake command
#job_type :rake, 'source ~/.rvm/scripts/rvm; cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output'

every 5.minutes do
  rake 'compute_metrics'
end

# backup database
every :week do
  envcommand 'backup perform --trigger my_backup'
end

every :reboot do
  envcommand 'script/delayed_job restart'
end

every :day, :at => '1:30 am' do
  envcommand 'script/delayed_job restart'
end

# Learn more: http://github.com/javan/whenever
