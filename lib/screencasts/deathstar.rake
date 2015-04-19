task :prep_deathstar => :environment do
  u = User.find_by_email('test@test.dev.ghost')

  if u
    u.points.destroy_all
    u.comments.destroy_all
    u.opinions.destroy_all
    u.inclusions.destroy_all
  end  

  puts "Should be ready to go."
end