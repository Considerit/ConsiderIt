namespace :users do
  desc "Add unique token for each user"

  task :add_unique_token => :environment do
    User.add_token
  end

end