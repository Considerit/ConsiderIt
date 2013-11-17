env :MAILTO, '""' 
env :PATH, ENV['PATH']

set :output, 'log/cron_log.log'

job_type :envcommand, '. ~/.profile; cd :path && RAILS_ENV=:environment :task'

# on some systems, need to source rvm before running standard rake command
job_type :rake, '. ~/.profile; cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output'

every 5.minutes do
  rake 'compute_metrics'
end

every 12.hours do
  rake 'alerts:check_moderation'
end

#TODO: check to make sure this is working
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
