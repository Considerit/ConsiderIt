

task :prep_deathstar => :environment do
  for user in ['oprah@gmail.com', 'test@test.dev.ghost', 'denver@denver.com']
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


  subdomain = Subdomain.find_by_name('denver-climate-action')
  if !subdomain
    subdomain = Subdomain.find_by_name('denverclimateaction')
    subdomain.rename('denver-climate-action')
  end 

  subdomain.customizations["list/transp-innovate"]["list_title"] = "What would help you reduce personal vehicle trips?"
  subdomain.customizations["list/transp-innovate"]["list_description"] = nil

  subdomain.customizations["homepage_tabs"][3]["lists"] = ["list/transp-innovate"]
  subdomain.customizations["homepage_tabs"][3]["page_preamble"] = ""
  subdomain.save
  subdomain.proposals.update_all(:active => true)



  subdomain = Subdomain.find_by_name('denverclimateaction')
  if subdomain
    subdomain.destroy!
  end



  subdomain = Subdomain.find_by_name('denverclimateaction-seed')
  sub2 = Subdomain.find_by_name('denver-climate-action')

  if subdomain
    subdomain.customizations = sub2.customizations
    subdomain.logo = sub2.logo
    subdomain.masthead = sub2.masthead
    subdomain.save 


    subdomain.customizations['banner']['title'] = "Denver wants to take bold action on climate change."
    subdomain.customizations['banner']['description'] = "In this forum, you can let us know what you think about our recommendations for climate action, as well as make recommendations of your own!"
    subdomain.customizations['homepage_tabs'] = [
      {
        "name": "Background",
        "lists": []
      },
      {
        "name": "Goals",
        "lists": [],
      },
      {
        "name": "Electricity",
        "lists": []
      },
      {
        "name": "Transportation",
        "lists": []
      },
      {
        "name": "Buildings",
        "lists": [],
      },
      {
        "name": "Funding",
        "lists": []
      }
    ]
    subdomain.save


  end

end

