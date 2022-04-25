

task :prep_deathstar => :environment do
  for user in ['oprah@gmail.com', 'test@test.dev.ghost']
    u = User.find_by_email(user)

    if u
      u.points.destroy_all
      u.comments.destroy_all
      u.opinions.destroy_all
      u.inclusions.destroy_all
      u.proposals.destroy_all
    end  

    if user == 'oprah@mail.com'
      u.destroy
    end

  end 

  subdomain = Subdomain.find_by_name('galacticfederation')
  subdomain.proposals.update_all(:moderation_status => nil)

  Moderation.where(subdomain_id: subdomain.id).where(moderatable_type: 'Proposal').destroy_all

  puts "Should be ready to go."


  subdomain = Subdomain.find_by_name('internethealthreport')
  subdomain.proposals.update_all(:active => true)

  c = subdomain.comments.find(6009)
  c.body = "Here's a resource on the commonly-understood different types of misinformation: https://firstdraftnews.com/fake-news-complicated/"
  c.save


  subdomain = Subdomain.find_by_name('denverclimateaction')
  subdomain.proposals.update_all(:active => true)

end