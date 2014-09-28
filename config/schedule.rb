env :MAILTO, '""' 
env :PATH, ENV['PATH']

set :output, 'log/cron_log.log'

job_type :envcommand, '. ~/.profile; cd :path && RAILS_ENV=:environment :task'

# on some systems, need to source rvm before running standard rake command
job_type :rake, '. ~/.profile; cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output'

every 30.minutes do
  rake 'compute_metrics'
end

every 1.day, :at => '6:30 am' do
  rake 'alerts:check_moderation'
end

every :reboot do
  envcommand 'bundle exec bin/delayed_job restart'
end

every :day, :at => '1:30 am' do
  envcommand 'bundle exec bin/delayed_job restart'
end

#every 1.minute do
#  envcommand 'bundle exec bin/delayed_job restart'
#end

# Learn more: http://github.com/javan/whenever
