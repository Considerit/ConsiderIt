namespace :activities do
  desc "Based on existing data, initialize the activities table"

  task :initialize_from_data => :environment do
    Activity.delete_all

    Proposal.find_each do |proposal|
      action = Activity.build_from!(proposal)
    end
    Opinion.where(:published=>1).each do |pos|
      action = Activity.build_from!(pos)
    end
    Point.where(:published=>1).each do |point|
      action = Activity.build_from!(point)
    end
    Comment.find_each do |comment|
      action = Activity.build_from!(comment)
    end
    User.find_each do |user|
      action = Activity.build_from!(user)
    end    
    Inclusion.find_each do |inc|
      action = Activity.build_from!(inc)
    end        
  end

end