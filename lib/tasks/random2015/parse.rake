require 'rubygems'
require 'mechanize'

#require 'JSON'

conference_id = '8265468'
easy_chair_url = "https://www.easychair.org/conferences/conference_change_yes.cgi?a=#{conference_id}"
easy_chair_review_url = "https://www.easychair.org/conferences/review_list.cgi?a=#{conference_id}"



u = ARGV[1] || ENV["RANDOM2015_username"]
pass = ARGV[2] || ENV["RANDOM2015_password"]


task :import_from_easychair => :environment do

  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }
  a.pluggable_parser.default = Mechanize::Download

  a.get(easy_chair_url) do |page|

    # Submit the login form
    my_page = page.form_with(:action => 'verify.cgi') do |f|
      f['name']  = u
      f['password'] = pass
    end.submit

    review_page = a.get(easy_chair_review_url) do |review_page|
      form = review_page.form_with(:action => 'review_list.cgi')
      form.checkbox_with(:name => 'download').check
      response = form.submit
      papers = parse_papers(response.body)
      import_into_considerit(papers)
    end
  end
end

def import_into_considerit(papers)
  subdomain = Subdomain.find_by_name('RANDOM2015')
  user = User.find(210277) #find_by_email('anup.rao@gmail.com')

  for paper in papers

    is_new = false

    proposal = subdomain.proposals.find_by(slug: paper['url'])
    if !proposal
      proposal = Proposal.new(
        subdomain_id: subdomain.id,
        slug: paper['url'],
        user_id: user.id,
        published: true,
        cluster: 'Under Review'
      )
      is_new = true
    end

    fields = paper['description_fields']

    proposal.name = paper['topic']
    proposal.description = paper['description']
    proposal.description_fields = JSON.dump(fields)

    #pp paper
    if proposal.changed? || is_new
      if proposal.description_changed? || proposal.description_fields_changed?
        # TODO: send notification!! new review (probably)!!
        pp "#{proposal.slug} CHANGED!"
      end
      proposal.save
    end

  end


end


# divide into papers
def parse_papers(papers)

  data = []

  papers = papers.split('***********************')

  # first line is garbage
  papers = papers[1..papers.length]

  number = ''
  papers.each_with_index do |p, idx|
    # if this is a title line, grab it
    if idx % 2 == 0 
      number = p.strip
    else
      # otherwise, this is the paper content
      data.push parse_paper number, p.strip
    end
  end  

  data.compact!
  data
end

def parse_paper(number, text)

  paper = text.split('==================')

  title = paper[0].split(/\r?\n/)[1].strip
  title = title[7..title.length]

  url = number.gsub(' ', '_').downcase

  if title.index('WITHDRAWN') || ['paper_51','paper_52'].include?(url)
    return nil
  end

  description, fields, num_r = parse_reviews(url, paper[1].split('=================')[1])

  data = {
    'url' => url,
    'topic' => title + " [#{num_r or 0}_reviews]", 
    'description' => description,
    'description_fields' => fields
  }

  data

end

def parse_reviews(url, reviews)


  link = pdfs[url].gsub('?dl=0', '?dl=1')

  description = link.length > 0 ? "<p>Read the full paper <a target='_blank' href='#{link}'>here</a></p>" : ""

  fields = [{'label' => 'Abstract', 'html' => '(TODO: parse abstract)' }]

  # some papers might not have any reviews yet
  return [description, fields, 0] if !reviews

  data = []

  for review in reviews.split('++++++++++')
    if review.index('+++++++++')
      rev = parse_review review     
      if rev 
        data.push rev
      end
    end
  end


  for review in data
    html = """
        <div><strong>#{review['score']}</strong></div>
        <div><strong>#{review['confidence']}</strong></div>
        <br/>
        #{review['review']}
        #{!review['confidential'] ? '' : "<div><h3>Confidential for PC</h3>#{review['confidential']}</div>"}
        """

    fields.push({
          'label' => review['title'],
          'html' => html
        })
  end

  [description, fields, data.length]
end

def parse_review(review)

  review = review.split('+++++++++')
  field_title = review[0].strip.downcase.capitalize

  review = review[1].split('---- REVIEW ----')

  eval = review[0].split(/\r?\n/)
  eval.shift 

  if eval[0].match('SUBREVIEWER')
    subreviewer = eval.shift.downcase
    field_title += " (#{subreviewer})"
  end

  body = review[1]
  if body.index("---- CONFIDENTIAL REMARKS FOR THE PROGRAM COMMITTEE ----")
    body, confidential = body.split("---- CONFIDENTIAL REMARKS FOR THE PROGRAM COMMITTEE ----")
    confidential.strip!
    if confidential.index '(missing)'
      confidential = nil
    end
  end

  data = {
    'title' => field_title,
    'score' => eval[0].downcase.capitalize,    
    'confidence' => eval[1].downcase.capitalize,
    'review' => "<p>#{body.strip.gsub(/\r?\n\r?\n/, '<p/><p>').gsub(/\r?\n/, '<br />')}</p>"
  }


  if confidential
    data['confidential'] = confidential
  end

  data
end


def pdfs
  {
  'paper_1' => 'https://www.dropbox.com/s/8iuw0gf0kagepmt/RANDOM_2015_submission_1.pdf?dl=0',
  'paper_2' => 'https://www.dropbox.com/s/qgt1ml15863h0so/RANDOM_2015_submission_2.pdf?dl=0',
  'paper_3' => 'https://www.dropbox.com/s/8y76atgntkvopy0/RANDOM_2015_submission_3.pdf?dl=0',
  'paper_4' => 'https://www.dropbox.com/s/mkh05uox318p0lt/RANDOM_2015_submission_4.pdf?dl=0',
  'paper_5' => 'https://www.dropbox.com/s/t4t39m3vx0ky4wq/RANDOM_2015_submission_5.pdf?dl=0',
  'paper_6' => 'https://www.dropbox.com/s/e8d22sfflqzvjq7/RANDOM_2015_submission_6.pdf?dl=0',
  'paper_7' => 'https://www.dropbox.com/s/v5qqit5lgwigd8n/RANDOM_2015_submission_7.pdf?dl=0',
  'paper_8' => 'https://www.dropbox.com/s/hzub2tmo6nvm333/RANDOM_2015_submission_8.pdf?dl=0',
  'paper_9' => 'https://www.dropbox.com/s/ca2mbc98ul1rqze/RANDOM_2015_submission_9.pdf?dl=0',
  'paper_10' => 'https://www.dropbox.com/s/vh2cet3h64z00mc/RANDOM_2015_submission_10.pdf?dl=0',
  'paper_12' => 'https://www.dropbox.com/s/nzw2d0fsccwmsgp/RANDOM_2015_submission_12.pdf?dl=0',
  'paper_13' => 'https://www.dropbox.com/s/9hr3qtniyf29grs/RANDOM_2015_submission_13.pdf?dl=0',
  'paper_14' => 'https://www.dropbox.com/s/bciv28z7ee8khlx/RANDOM_2015_submission_14.pdf?dl=0',
  'paper_15' => 'https://www.dropbox.com/s/33u2xw4xnp653k9/RANDOM_2015_submission_15.pdf?dl=0',
  'paper_16' => 'https://www.dropbox.com/s/q42j21phrr98x9w/RANDOM_2015_submission_16.pdf?dl=0',
  'paper_17' => 'https://www.dropbox.com/s/4w3qa7yps95teg8/RANDOM_2015_submission_17.pdf?dl=0',
  'paper_18' => 'https://www.dropbox.com/s/q7lg0xr393ic0f2/RANDOM_2015_submission_18.pdf?dl=0',
  'paper_19' => 'https://www.dropbox.com/s/qcu0nprdha0f4q1/RANDOM_2015_submission_19.pdf?dl=0',
  'paper_20' => 'https://www.dropbox.com/s/m6ojc1ts1g2un2v/RANDOM_2015_submission_20.pdf?dl=0',
  'paper_21' => 'https://www.dropbox.com/s/xb4q1wi9pmlr44q/RANDOM_2015_submission_21.pdf?dl=0',
  'paper_22' => 'https://www.dropbox.com/s/5pozwggj2flv69i/RANDOM_2015_submission_22.pdf?dl=0',
  'paper_23' => 'https://www.dropbox.com/s/qwfw185bp3l4n8i/RANDOM_2015_submission_23.pdf?dl=0',
  'paper_24' => 'https://www.dropbox.com/s/n81g59hatfwkkim/RANDOM_2015_submission_24.pdf?dl=0',
  'paper_25' => 'https://www.dropbox.com/s/igc6p8vr9i96me1/RANDOM_2015_submission_25.pdf?dl=0',
  'paper_26' => 'https://www.dropbox.com/s/ybmb6vr7znpwgvz/RANDOM_2015_submission_26.pdf?dl=0',
  'paper_27' => 'https://www.dropbox.com/s/du2brlwdkdwhv3z/RANDOM_2015_submission_27.pdf?dl=0',
  'paper_28' => 'https://www.dropbox.com/s/bly9hxnsliy7b99/RANDOM_2015_submission_28.pdf?dl=0',
  'paper_29' => 'https://www.dropbox.com/s/cc7mvsvu75ol3iy/RANDOM_2015_submission_29.pdf?dl=0',
  'paper_30' => 'https://www.dropbox.com/s/6oyhrh1dou9oeal/RANDOM_2015_submission_30.pdf?dl=0',
  'paper_31' => 'https://www.dropbox.com/s/5z65rcdoib7w1ez/RANDOM_2015_submission_31.pdf?dl=0',
  'paper_32' => 'https://www.dropbox.com/s/ee525y3tbbsvhx7/RANDOM_2015_submission_32.pdf?dl=0',
  'paper_33' => 'https://www.dropbox.com/s/r6yvhpggigvkwqk/RANDOM_2015_submission_33.pdf?dl=0',
  'paper_34' => 'https://www.dropbox.com/s/5p8zsgci2842kyb/RANDOM_2015_submission_34.pdf?dl=0',
  'paper_35' => 'https://www.dropbox.com/s/yrtuge6bthl9d08/RANDOM_2015_submission_35.pdf?dl=0',
  'paper_36' => 'https://www.dropbox.com/s/468o6d56s376jox/RANDOM_2015_submission_36.pdf?dl=0',
  'paper_37' => 'https://www.dropbox.com/s/fr56dar6os8t3or/RANDOM_2015_submission_37.pdf?dl=0',
  'paper_38' => 'https://www.dropbox.com/s/vxm3c3g72zx61sq/RANDOM_2015_submission_38.pdf?dl=0',
  'paper_39' => 'https://www.dropbox.com/s/na27y4ujr7r7hdv/RANDOM_2015_submission_39.pdf?dl=0',
  'paper_40' => 'https://www.dropbox.com/s/7xf8q8b4qi1h0mm/RANDOM_2015_submission_40.pdf?dl=0',
  'paper_41' => 'https://www.dropbox.com/s/8mmjel4jgwfska1/RANDOM_2015_submission_41.pdf?dl=0',
  'paper_42' => 'https://www.dropbox.com/s/beodp7q95mpwt48/RANDOM_2015_submission_42.pdf?dl=0',
  'paper_43' => 'https://www.dropbox.com/s/ahpau93q4rmu1h5/RANDOM_2015_submission_43.pdf?dl=0',
  'paper_44' => 'https://www.dropbox.com/s/xvoqwrh5ynismb2/RANDOM_2015_submission_44.pdf?dl=0',
  'paper_45' => 'https://www.dropbox.com/s/3seh9fru4vu5o1i/RANDOM_2015_submission_45.pdf?dl=0',
  'paper_46' => 'https://www.dropbox.com/s/6686v30x6r4px55/RANDOM_2015_submission_46.pdf?dl=0',
  'paper_47' => 'https://www.dropbox.com/s/hcvwef9oup265vc/RANDOM_2015_submission_47.pdf?dl=0',
  'paper_48' => 'https://www.dropbox.com/s/hl4z3s904vj837g/RANDOM_2015_submission_48.pdf?dl=0',
  'paper_49' => 'https://www.dropbox.com/s/4khsohwqsdg78gw/RANDOM_2015_submission_49.pdf?dl=0',
  'paper_50' => 'https://www.dropbox.com/s/82jyxivv46kaxk9/RANDOM_2015_submission_50.pdf?dl=0',
  'paper_51' => '',
  'paper_52' => '',
  'paper_53' => 'https://www.dropbox.com/s/c619e2csfb15pmh/RANDOM_2015_submission_53.pdf?dl=0',
  'paper_54' => 'https://www.dropbox.com/s/mg4es11mcb1drom/RANDOM_2015_submission_54.pdf?dl=0',
  'paper_55' => 'https://www.dropbox.com/s/3x9l6grmfwd2bzi/RANDOM_2015_submission_55.pdf?dl=0',
  'paper_56' => 'https://www.dropbox.com/s/ihqctt0sqoe2vmy/RANDOM_2015_submission_56.pdf?dl=0',
  'paper_57' => 'https://www.dropbox.com/s/tjcz7ktpxvy1ofi/RANDOM_2015_submission_57.pdf?dl=0',
  'paper_58' => 'https://www.dropbox.com/s/qvw9riuvfzui4d8/RANDOM_2015_submission_58.pdf?dl=0',
  'paper_59' => 'https://www.dropbox.com/s/4jcjoetmpgf93j4/RANDOM_2015_submission_59.pdf?dl=0',
  'paper_60' => 'https://www.dropbox.com/s/jxixo4iiuwntz4g/RANDOM_2015_submission_60.pdf?dl=0',
  'paper_61' => 'https://www.dropbox.com/s/mpxelsmaxzj1c7x/RANDOM_2015_submission_61.pdf?dl=0',
  'paper_62' => 'https://www.dropbox.com/s/e3v10brfkuirp8y/RANDOM_2015_submission_62.pdf?dl=0',
  'paper_63' => 'https://www.dropbox.com/s/o2lpmf7spb5dbps/RANDOM_2015_submission_63.pdf?dl=0',
  'paper_64' => 'https://www.dropbox.com/s/pddoyf129xdjyi4/RANDOM_2015_submission_64.pdf?dl=0',
  'paper_65' => 'https://www.dropbox.com/s/oopt02b9zdfzvmf/RANDOM_2015_submission_65.pdf?dl=0',
  'paper_66' => 'https://www.dropbox.com/s/zg6sli2rkdayqov/RANDOM_2015_submission_66.pdf?dl=0',
  'paper_67' => 'https://www.dropbox.com/s/99in3txhm895asg/RANDOM_2015_submission_67.pdf?dl=0',
  'paper_68' => 'https://www.dropbox.com/s/i3kjghecb27p81y/RANDOM_2015_submission_68.pdf?dl=0',
  'paper_69' => 'https://www.dropbox.com/s/vdrm2i0pbda5url/RANDOM_2015_submission_69.pdf?dl=0',
  'paper_70' => 'https://www.dropbox.com/s/64mhbve8wy87lau/RANDOM_2015_submission_70.pdf?dl=0',
  'paper_71' => 'https://www.dropbox.com/s/zwblb2byo5wby52/RANDOM_2015_submission_71.pdf?dl=0',
  'paper_72' => 'https://www.dropbox.com/s/78b20vaxr83f4t0/RANDOM_2015_submission_72.pdf?dl=0',
  'paper_73' => 'https://www.dropbox.com/s/x6pwxyjacd8pyi0/RANDOM_2015_submission_73.pdf?dl=0',
  'paper_74' => 'https://www.dropbox.com/s/lgs7ekunt7inq7c/RANDOM_2015_submission_74.pdf?dl=0',
  'paper_75' => 'https://www.dropbox.com/s/k2dhwxk2e4gzc2o/RANDOM_2015_submission_75.pdf?dl=0',
  'paper_76' => 'https://www.dropbox.com/s/0hio4sbrt7mvv8q/RANDOM_2015_submission_76.pdf?dl=0',
  'paper_77' => 'https://www.dropbox.com/s/d5bve0xpbqscwh3/RANDOM_2015_submission_77.pdf?dl=0',
  'paper_78' => 'https://www.dropbox.com/s/ttdz2nkr898k1v2/RANDOM_2015_submission_78.pdf?dl=0',
  'paper_79' => 'https://www.dropbox.com/s/h1kfdweryfb9696/RANDOM_2015_submission_79.pdf?dl=0',
  'paper_80' => 'https://www.dropbox.com/s/rx0u2yrr9ftvdtn/RANDOM_2015_submission_80.pdf?dl=0',
  'paper_81' => 'https://www.dropbox.com/s/a9cfx8ifvgjqyaw/RANDOM_2015_submission_81.pdf?dl=0',
  'paper_82' => 'https://www.dropbox.com/s/8m4tv5zmm37b6mx/RANDOM_2015_submission_82.pdf?dl=0',
  'paper_83' => 'https://www.dropbox.com/s/7hdmn1j0k1zgrqd/RANDOM_2015_submission_83.pdf?dl=0',
  }
end
