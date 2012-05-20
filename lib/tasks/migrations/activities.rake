namespace :activities do
  desc "Based on existing data, initialize the activities table"

  task :initialize_from_data => :environment do
    Activity.delete_all

    Reflect::ReflectBulletRevision.all.each do |brev|
      action = Activity.build_from!(brev)
    end    
    Proposal.all.each do |proposal|
      action = Activity.build_from!(proposal)
    end
    Position.where(:published=>1).each do |pos|
      action = Activity.build_from!(pos)
    end
    Point.where(:published=>1).each do |point|
      action = Activity.build_from!(point)
    end
    Comment.all.each do |comment|
      action = Activity.build_from!(comment)
    end
    User.all.each do |user|
      action = Activity.build_from!(user)
    end    
    Inclusion.all.each do |inc|
      action = Activity.build_from!(inc)
    end        
  end

end