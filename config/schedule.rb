#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

env :MAILTO, '""' 
env :PATH, ENV['PATH']

set :output, 'log/cron_log.log'

job_type :envcommand, 'source ~/.rvm/scripts/rvm; cd :path && RAILS_ENV=:environment :task'

# on some systems, need to source rvm before running standard rake command
job_type :rake, 'source ~/.rvm/scripts/rvm; cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output'

every 5.minutes do
  rake 'compute_metrics'
end

# backup database
every :week do
  envcommand 'backup perform --trigger my_backup'
end

every :reboot do
  envcommand 'bundle exec script/delayed_job restart'
end

every :day, :at => '1:30 am' do
  envcommand 'bundle exec script/delayed_job restart'
end

#every 1.minute do
#  envcommand 'bundle exec script/delayed_job restart'
#end

# Learn more: http://github.com/javan/whenever
