# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

ConsiderIt::Application.load_tasks


##########################
## Acceptance testing with Casper. 
### Rake tasks adapted from 
### http://www.jrubyonrails.de/2013/03/continuous-integration-for-jasmine--and-casperjs-tests.html
##########################

test_server_pid_file = "tmp/pids/test_server.pid"
app_port             = 8787
desc "Start Testing Server"
task :start_test_server do
  counter = 0

  Thread.new {
    command_line = "bundle exec rails server -p #{app_port} -e test -P #{test_server_pid_file} 1> /dev/null"
    puts "Starting: #{command_line}"
    system command_line
  }

  while (not File.exist?(test_server_pid_file)) && counter < 90 do
    counter += 1
    sleep 2
  end
  if counter >= 30
    STDERR.puts "Start took too long!"
  else
    puts "Test server running ..."
  end
end

desc "Stop Testing Server"
task :stop_test_server do

  puts "Stopping test server ..."
  pid = IO.read(test_server_pid_file).to_i rescue nil

  if pid.present?
    system("kill -9 #{pid}")
    FileUtils.rm(test_server_pid_file)
    puts "... Test server stopped"
  else
    STDERR.puts "Cannot stop server - no pid file found!"
  end
end


desc "run Casper JS Tests, starts rails server,run the tests and then stop the server "
task :run_acceptance_tests do
  
  if Rails.env.test?
    begin
      Rake::Task["start_test_server"].invoke

      results_path = Rails.root.join("public", "test", "results")

      Dir.mkdir(results_path) unless File.exists?(results_path.to_s)

      date = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      results_directory = results_path.join date

      Dir.mkdir results_directory.to_s
      Dir.mkdir results_directory.join("screen_captures").to_s


      html_out = results_directory.join("index.html").to_s

      File.open(html_out,'w+') do |f|
        html = File.read(Rails.root.join("public","test", "files", "header.html"))
        html = html.gsub('{{date}}', date)
        f.puts html  
      end

      spec_path = Rails.root.join("spec/acceptance/")
      for test in Dir["#{spec_path}/**/*.coffee"]

        system "bundle exec rake load_test_data"


        system("casperjs test \
                --testhost=http://localhost:#{app_port} \
                --includes=spec/lib/casperjs.coffee \
                --htmlout=#{results_directory} \
                #{File.join(test)}")
      end

      File.open(html_out,'a') do |f|
        f.puts File.read Rails.root.join("public","test", "files", "footer.html")
      end

      latest_path = Rails.root.join('public', 'test', 'results', 'latest')
      FileUtils.rm(latest_path.to_s) if File.exists?(latest_path.to_s)
      FileUtils.ln_s results_directory.to_s, latest_path.to_s


    ensure
      Rake::Task["stop_test_server"].invoke
    end
  else
    puts "Need to run in test environment"
  end
end

desc "load test data into database"
task :load_test_data do 

  if Rails.env.test?
    filename = "spec/data/test.sql"
    t = Time.now

    Rake::Task["db:drop"].invoke  
    Rake::Task["db:create"].invoke

    db = Rails.configuration.database_configuration['test']

    system "mysql -u#{db['username']} -p#{db['password']} #{db['database']} < #{Rails.root}/#{filename}"
    
    system "bundle exec rake db:migrate > /dev/null 2>&1"
    #puts "...Test data loaded in #{Time.now - t} seconds"

  end
end


desc "remove all past tests"
task :clean_out_test_results do 

  if Rails.env.test?
    begin
      results_path = Rails.root.join("public", "test", "results")
      FileUtils.rm_rf results_path
    end
  end
end

