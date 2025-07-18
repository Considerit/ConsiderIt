env :MAILTO, '""' 
env :PATH, ENV['PATH']

set :output, 'log/cron_log.log'

job_type :envcommand, '. ~/.profile; cd :path && RAILS_ENV=:environment :task'

# on some systems, need to source rvm before running standard rake command
job_type :rake, '. ~/.profile; cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output'

every 30.minutes do
  rake 'compute_metrics'
end

every :reboot do
  envcommand 'bundle exec bin/delayed_job restart'
end

every :day, :at => '1:30 am' do
  envcommand 'bundle exec bin/delayed_job restart'
end

every 1.hour do
  rake 'clear_null_inclusions'
end

every 60.minutes do 
  rake 'send_email_notifications'
end

every 45.minutes do 
  rake 'animate_avatars'
end
