
namespace :user_test do

  task :overwrite_data_from_existing_proposal => :environment do
    
    overwrite_proposal_id = 1584
    # find this proposal at /wash_i_517

    proposal = Proposal.find(1584)

    proposal.name = "Should Facebook stop doing business with advertisers and charge $10 a year per user?"
    proposal.description = "<p>Facebook currently makes money by selling ad space throughout Facebook, and selling user data to advertisers.  Under this new model, Facebook would turn into a subscription service.  Facebook would stop all advertisements in Facebook and would also stop selling user data to advertisers.</p><p>This initiative would require facebook to stop selling user data, and replace it with a user fee.</p>"
    proposal.category = 'Facebook Community Outreach'
    proposal.designator = ''

    proposal.save

    pros = [
      ['If I want to see a business in my newsfeed, I would follow that business!', ''],
      ['Facebook ads are always so offensive:  Liposuction?  Plastic Surgery? Spanx?  Is Facebook telling me I\'m Fat and Ugly?', 'I am not fat. Humans are not built like what advertisers want you to believe. They are a plague. I applaud Facebook even considering this. It woudl be a big step forward for big tech!!'],
      ['$10 isn’t much to pay to make sure data about me isn\'t tracked and sold to big companies', ''],
    ]

    cons = [
      ['I’ve never paid for internet services in my life and don’t think I should have to anyway.', ''],
      ['Facebook should be free, like a public utility', ''],
      ['$10 would keep young people from joining. This is the group that will make the Facebook of tomorrow.', ''],
      ['Facebook would delete my page if I forgot to pay!', ''],
      ['$10 is too much money to pay for a silly website.', ''],
      ['Facebook gives a place for struggling students to vent about teachers who are do bad work.', ''],
      ['They\'ll just raise the price.', 'Once they have our credit cards on file, they\'ll be able to jack the prices up.' ],
      ['Credit card payment will probably be done automatically, opt out style.', ''],
      ['Will drive away some of my friends and I won\'t have as much fun.', 'Bye bye friends :-('],
      ['I like the advertisements. I learn about which medications and political theories I should believe in.', 'Better than school.'],
    ]

    for params in [ [proposal.points.pros.published, pros], [proposal.points.cons.published, cons]  ]
      points = params[0]
      new_points = params[1]
      for i in 0..points.count-1
        point = points[i]
        point.nutshell = new_points[i][0]
        point.text = new_points[i][1]
        point.save
      end
    end



  end

end