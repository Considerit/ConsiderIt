

task :prep_deathstar => :environment do
  for user in ['oprah@gmail.com', 'test@test.dev.ghost']
    u = User.find_by_email(user)

    if u
      u.points.destroy_all
      u.comments.destroy_all
      u.opinions.destroy_all
      u.inclusions.destroy_all
    end  

    if user == 'oprah@mail.com'
      u.destroy
    end

  end 


  puts "Should be ready to go."
end