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
  user = User.find(311595) #210277) #find_by_email('anup.rao@gmail.com')

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
    #proposal.description = paper['description']
    proposal.description_fields = JSON.dump(fields)

    #pp paper
    if proposal.changed? || is_new
      #text_updated = proposal.description_changed? || proposal.description_fields_changed?

      text_updated = proposal.description_fields_changed?
      proposal.save

      if text_updated
        Notifier.create_notification 'edited', proposal, protagonist: user, subdomain: subdomain
        pp "#{proposal.slug} CHANGED!"
      end
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

  if title.index('WITHDRAWN') || ['paper_51', 'paper_3'].include?(url)
    return nil
  end

  description, fields, num_r = parse_reviews(url, paper[1].split('=================')[1])

  data = {
    'url' => url,
    'topic' => title, #+ " [#{num_r or 0}_reviews]", 
    'description' => description,
    'description_fields' => fields
  }

  data

end

def parse_reviews(url, reviews)


  link = pdfs[url].gsub('?dl=0', '?dl=1')

  description = link.length > 0 ? "<p>Read the full paper <a target='_blank' href='#{link}'>here</a></p>" : ""

  fields = [{'label' => 'Abstract', 'html' => abstracts[url]}]

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

def abstracts
  {
    'paper_1' => 'One of the fundamental open questions in computational complexity is whether the class of problems solvable by use of stochasticity under the Random Polynomial time (RP) model is larger than the class of those solvable in deterministic polynomial time (P). However, this question is only open for Turing machines, not for Random Access Machines (RAMs). Simon (1981) was able to show that for a sufficiently equipped Random Access Machine, the ability to switch states nondeterministically entails no computational advantage. However, in the same paper, Simon describes a different (and arguably more natural) scenario for stochasticity under the RAM model. According to Simon\'s proposal, instead of receiving a new random bit at each execution step, the RAM program is able to execute the pseudofunction RAND(y), which returns a uniformly distributed random integer in the range [0, y). Whether the ability to allot a random integer in this fashion is more powerful than the ability to allot a random bit remained an open question for the last 30 years. In this paper, we close Simon\'s open problem by fully characterising the class of languages recognisable in polynomial time by each of the RAMs regarding which the question was posed. We show that for some of these, stochasticity does not entail any advantage, but, more interestingly, we show that for others it does. These results
  carry over also to BPP-like acceptance criteria.',
    'paper_2' => 'A recent model for property testing of probability distributions enables tremendous savings in the sample complexity of testing algorithms, by allowing them to condition the sampling on subsets of the domain.

  In particular, Canonne, Ron, and Servedio showed that, in this setting, testing identity of an unknown distribution $D$ (i.e., whether $D=D^*$ for an explicitly known $D^*$) can be done with a constant number of samples, independent of the support size $n$ -- in contrast to the required $\sqrt{n}$ in the standard sampling model. However, it was unclear whether the same held for the case of testing equivalence, where both distributions are unknown. Indeed, while the best known upper bound for equivalence testing is $polylog(n)$, whether a dependence on the domain size $n$ is necessary was still open, and explicitly posed at the Bertinoro Workshop on Sublinear Algorithms. In this work, we answer the question in the positive, showing that any testing algorithm for equivalence must make $\Omega(\sqrt{\log\log n})$ queries in the conditional sampling model. Interestingly, this demonstrates an intrinsic qualitative gap between identity and equivalence testing, absent in the standard sampling model (where both problems have sampling complexity $n^{\Theta(1)}$).

  Turning to another question, we investigate the complexity of support size estimation. We provide a doubly-logarithmic upper bound for the adaptive version of this problem, generalizing related work of Ron and Tsur to our weaker model. We also establish a logarithmic lower bound for the non-adaptive version of this problem. This latter result carries on to the related problem of non-adaptive uniformity testing, an exponential improvement over previous results.',
    'paper_4' => 'With double hashing, for a key $x$, one generates two hash values $f(x)$ and $g(x)$, and then uses combinations $(f(x) +i g(x)) \bmod n$ for $i=0,1,2,\ldots$ to generate multiple hash values in the range $[0,n-1]$ from the initial two. For balanced allocations, keys are hashed into a hash table where each bucket can hold multiple keys, and each key is placed in the least loaded of $d$ choices. It has been shown previously that asymptotically the performance of double hashing and fully random hashing is the same in the balanced allocation paradigm using fluid 
  limit methods. Here we extend a coupling argument used by Lueker and Molodowitch to show that double hashing and ideal uniform hashing are asymptotically equivalent in the setting of open address hash tables to the balanced allocation setting, providing further insight into this phenomenon. We also discuss the potential for and bottlenecks limiting the use this approach for other multiple choice hashing schemes.',
    'paper_5' => 'We analyse the cover time of a random walk on a random graph of a given degree sequence. Weights are assigned to the edges of the graph using a certain type of scheme that uses only local degree knowledge. This biases the transitions of the walk towards lower degree vertices. We demonstrate that, with high probability, the cover time is at most $(1+o(1))\frac{d-1}{d-2}8n\log n$, where $d$ is the minimum degree. 
  This is in contrast to the precise cover time of $(1+o(1))\frac{d-1}{d-2}\frac{\theta}{d} n\log n$ (with high probability) given in \cite{CovDS} for a simple (i.e., unbiased) random walk on the same graph model. Here $\theta$ is the average degree and since the ratio $\theta/d$ can be arbitrarily large, or go to infinity with $n$, we see that the scheme 
  can give an unbounded speed up for sparse graphs.',
    'paper_6' => 'We present two results in structural complexity theory concerned with the following interrelated topics: computation with postselection/restarting, closed timelike curves (CTCs), and approximate counting. The first result is a new characterization of the lesser known complexity class BPP_path in terms of more familiar concepts. Precisely, BPP path is the class of problems that can be efficiently solved with a nonadaptive oracle for the Approximate Counting problem. Our second result is concerned with the computational power conferred by CTCs; or equivalently, the computational complexity of finding stationary distributions for quantum channels. We show that any poly(n)-time quantum computation using a CTC of O(logn) qubits may as well just use a CTC of 1 classical bit. This result essentially amounts to showing that one can find a stationary distribution for a poly(n)-dimensional quantum channel in PP.',
    'paper_7' => 'In 1986, Jerrum, Valiant, and Vazirani (JVV) gave a simple scheme for using (nearly) uniform samples from a set to approximate the size of the set. This method (and variants) has been used give fully polynomial randomized approximation schemes (fpras) for the partition function of the Ising model, the number of linear extensions of a poset, the permanent of a nonnegative matrix, the volume of convex sets, and many others. A fundamental subproblem in their technique is the following. Given and independent, identically distributed sequence of random variables X_1,X_2,... with mean mu and standard deviation at most c*mu, where c is a known constant, and mu > 0, create an estimate a for mu such that for fixed epsilon and delta, Prob(|(a - mu)/mu| > epsilon) < delta. Originally, JVV used a result they called the Powering lemma to handle this, giving a technique that used (to first order) 48*(c/epsilon)^(-2)*ln(delta^(-1)) samples. This is the best possible number of samples up to the constant factor, but it is still an open question what the best constant possible is. A lower bound on the constant is already known, moreover, Central Limit Theorem considerations give a conjectured best constant of 2. This paper contains three results. First, the Powering lemma is generalized and tightened to bound the probabilities of certain events within a factor of 2. Second, this tighter result is used to optimize the JVV approach to reduce the constant down to 19.35. Third, an entirely new technique is introduced that is simple to implement but which reduces this constant further to 6.96.',
    'paper_8' => 'The average distance from a node to all other nodes in a graph, or from a query point in a metric space to a set of points, is a fundamental quantity in data analysis. The inverse of the average distance, known as the (classic) closeness centrality of a node, is a popular importance measure in the study of social networks. We show that the average distance (and hence centrality) of all nodes in a network can be estimated in time $O(\epsilon^{-2}m\log n)$, where $n$ and $m$ are the number of nodes and edges in a graph. For a set of $n$ point in a general metric space, we show that using preprocessing that uses $O(n)$ distance computations we can compute a weighted sample of only $O(\epsilon^{-2})$ points such that the average distance from any query point to our points can be estimated using distance computations to the sampled points. Our estimates are unbiased with normalized mean square error (NRMSE) of at most $\epsilon$. Increasing the sample size by a $\log n$ factor ensures a very high probability of relative error at most $\epsilon$ for all nodes.',
    'paper_9' => 'Given a discrete random walk on a finite graph, 
  the vacant set is the set of vertices 
  which have not yet been visited by the walk. 
  The vacant net is similarly defined as the set of unvisited edges. 
  These sets induce subgraphs whose component structure changes 
  as the walk explores the graph. 

  For a simple random walk on random r-regular graphs, 
  it was previously established that 
  the graph of the vacant set undergoes 
  a phase transition in the sense of the 
  phase transition on Erdos-Renyi graphs G_{n,p}. 

  We establish the threshold value for a 
  phase transition in the graph of the vacant net. 

  We also obtain the corresponding results for non-backtracking random walks, 
  both for the vacant set and for the vacant net, and also give various related quantities such as the vertex and edge cover times for this walk. 

  This allows a direct comparison of thresholds and cover times between 
  simple and non-backtracking walks on random r-regular graphs.',
    'paper_10' => 'Many randomized algorithms can be derandomized efficiently using either the method of conditional expectations or probability spaces with low independence. A series of papers, beginning with work by Luby (1988), showed that in many cases these techniques can be combined to give deterministic parallel (NC) algorithms for a variety of combinatorial optimization problems, with low time and processor complexity. 

  We extend and generalize a technique of Luby for efficiently handling bilinear objective functions. One noteworthy application is an NC algorithm for maximal independent set (MIS) with $\tilde O(\log^2 n)$ time and $(m + n) n^{o(1)}$ processors; this is nearly the same as the best randomized parallel algorithms. Previous NC algorithms required either $\log^{2.5} n$ time or $mn$ processors. Other applications of our technique include algorithms of Berger (1997) for maximum acyclic subgraph and Gale-Berlekamp switching games. 

  This bilinear factorization also gives better algorithms for problems involving discrepancy. An important application of this is to automata-fooling probability spaces, which are the basis of a notable derandomization technique of Sivakumar (2002). Previous algorithms have had very high processor complexity. We are able to greatly reduce this, with applications to set balancing and the Johnson-Lindenstrauss Lemma.',
    'paper_12' => 'Researchers in artificial intelligence usually adopt the constraint satisfaction problem and the Satisfiability paradigms as their preferred methods when solving various real worlds decision making problems. Local search algorithms used to tackle different optimization problems that arise in various fields 
  aim at finding a tactical interplay between diversification and 
  intensification to overcome local optimality while the time consumption should remain acceptable. The WalkSATa algorithm for the Maximum Satisfiability Problem (MAX-SAT) is considered to be the main skeleton underlying almost all local search algorithms for MAX-SAT. This paper introduces an enhanced variant of Walksat 
  using Finite Learning Automata. A benchmark composed of industrial and random instances is used to compare the effectiveness of the proposed algorithm against state-of-the-art algorithms.',
    'paper_13' => 'In Arithmetic Circuit Complexity the standard operations are $\{+,\times\}$. 
  Yet, in some scenarios exponentiation gates are considered as well (see e.g. \cite{BshoutyBshouty98,ASSS12,Kayal12,KSS14}). 
  In this paper we study the question of efficiently evaluating a polynomial given an oracle access to its power. 
  That is, beyond an exponentiation gate. As applications, we show that: 

  <ul> 
  <li> A reconstruction algorithm for a circuit class $\C$ can be extended to handle $f^e$ for $f \in \C$.</li> 

  <li> There exists an efficient algorithm for factoring sparse multiquadratic polynomials. </li>

  <li> There exists an efficient algorithm for testing whether two powers of sparse polynomials are equal.
  That is, $f^d \equiv g^e$ when $f$ and $g$ are sparse. </li>
  </ul>',
    'paper_14' => 'We study internal compression of communication protocols to their internal entropy, which is the entropy of the transcript from the players\' perspective. We provide two internal compression schemes with error. 
  One of a protocol of Fiege et al.\ for finding the first difference between two strings. The second and main one is an internal compression with error $\eps > 0$ of a protocol with internal entropy $H^{int}$ and communication complexity $C$ to a protocol with communication at most order $(H^{int}/\eps)^2\log(\log(C))$. 

  This immediately implies a similar compression to the internal information of public coin protocols, which provides an exponential improvement over previously known public coin compressions in the dependence on $C$. Due to a recent result of Ganor, Kol and Raz our result implies an exponential separation between the information complexity of public versus private protocols. No such example was previously known.',
    'paper_15' => 'Covering all edges of a graph by a minimum number of cliques is a well known NP-hard problem. For the parameter k being the maximal number of cliques to be used, the problem becomes fixed parameter tractable. However, assuming the Exponential Time Hypothesis, there is no kernel of subexponential size in the worst-case. 

  We study the average kernel size for random intersection graphs with n vertices, edge proba- bility p, and clique covers of size k. We consider the well-known set of reduction rules of Gramm, Guo, Hüffner, and Niedermeier (ACM J. Exp. Algor. 13, 2.2, 2009) and show that with high probability they reduce the graph completely if p is bounded away from 1 and k < clogn for some constant c > 0. This shows that for large probabilistic graph classes like random intersec- tion graphs the expected kernel size can be substantially smaller than the known exponential worst-case bounds.',
    'paper_16' => 'The noise model of deletions poses significant challenges in coding theory, with basic questions like the capacity of the binary deletion channel still being open. In this paper, we study the harder model of worst-case deletions, with a focus on constructing efficiently decodable codes for the two extreme regimes of high-noise and high-rate. Specifically, we construct polynomial-time decodable codes with the following trade-offs (for any eps > 0): 

  (1) Codes that can correct a fraction 1-eps of deletions with rate poly(eps) over an alphabet of size poly(1/eps); 
  (2) Binary codes of rate 1-O~(sqrt(eps)) that can correct a fraction eps of deletions; and 
  (3) Binary codes that can be list decoded from a fraction (1/2-eps) of deletions with rate poly(eps) 

  Our work is the first to achieve the qualitative goals of correcting a deletion fraction approaching 1 over bounded alphabets, and correcting a constant fraction of bit deletions with rate aproaching 1. The above results bring our understanding of deletion code constructions in these regimes to a similar level as worst-case errors.',
    'paper_17' => 'An emerging theory of "linear-algebraic pseudorandomness" aims to understand the linear-algebraic analogs of fundamental Boolean pseudorandom objects where the rank of subspaces plays the role of the size of subsets. In this work, we study and highlight the interrelationships between several such algebraic objects such as subspace designs, dimension expanders, seeded rank condensers, two-source rank condensers, and rank-metric codes. In particular, with the recent construction of near-optimal subspace designs by Guruswami and Kopparty as a starting point, we construct good (seeded) rank condensers (both lossless and lossy versions), which are a small collection of linear maps $\mathbb{F}^n \to \mathbb{F}^t$ for $t \ll n$ such that for every subset of $\mathbb{F}^n$ of small rank, its rank is preserved (up to a constant factor in the lossy case) by at least one of the maps. 

  We then compose a tensoring operation with our lossy rank condenser to construct constant-degree dimension expanders over polynomially large fields. That is, we give $O(1)$ explicit linear maps $A_i:\mathbb{F}^n\to \mathbb{F}^n$ such that for any subspace $V \subseteq \mathbb{F}^n$ of dimension at most $n/2$, $\dim( \sum_i A_i(V)) \ge (1+\Omega(1)) \dim(V)$. Previous constructions of such constant-degree dimension expanders were based on Kazhdan\'s property $T$ (for the case when $\mathbb{F}$ has characteristic zero) or monotone expanders (for every field $\mathbb{F}$); in either case the construction was harder than that of usual vertex expanders. Our construction, on the other hand, is simpler. 

  For two-source rank condensers, we observe that the lossless variant (where the output rank is the product of the ranks of the two sources) is equivalent to the notion of a linear rank-metric code. For the lossy case, using our seeded rank condensers, we give a reduction of the general problem to the case when the sources have high ($n^{\Omega(1)}$) rank. When the sources have $O(1)$ rank, combining this with an "inner condenser" found by brute-force leads to a two-source rank condenser with output length nearly matching the probabilistic constructions.',
    'paper_18' => 'We initiate a study of a relaxed version of the standard Erdos-Renyi random graph model, where each edge may depend on a few other edges. We call such graphs dependent random graphs. Our main result in this direction is a thorough understanding of the clique number of dependent random graphs. We also obtain bounds for the chromatic number. Surprisingly, many of the standard properties of random graphs also hold in this relaxed setting. We show that with high probability, a dependent random graph will contain a clique of size (1-o(1))log(n)/log(1/p), and the chromatic number will be at most nlog(1/(1-p))/log(n). We expect these results to be of independent interest. As an application and second main result, we give a new communication protocol for the k-player Multiparty Pointer Jumping (MPJ_k) problem in the number-on-the-forehead (NOF) model. Multiparty Pointer Jumping is one of the canonical NOF communication problems, yet even for three players, its communication complexity is not well understood. Our protocol for MPJ3 costs O(nlog(log(n))/log(n)) communication, improving on a bound from [8]. We extend our protocol to the non-Boolean pointer jumping problem \hat{MPJ}_k, achieving an upper bound which is o(n) for any k >= 4 players. This is the first o(n) protocol for \hat{MPJ}_k and improves on a bound of Damm, Jukna, and Sgall [10], which has stood for almost twenty years.',
    'paper_19' => 'We exhibit ε-biased distributions D on n bits and functions f: {0,1}^n → {0,1} such that the xor of two independent copies (D+D) does not fool f, for any of the following choices: 

  1. ε = 2^{-Ω(n)} and f is in P/poly; 
  2. ε = 2^{-Ω(n/log n)} and f is in NC^2; 
  3. ε = n^{-log^{Ω(1)} n} and f is in AC^0; 
  4. ε = n^{-c} and f is a one-way space O(c log n) algorithm, for any c; 
  5. ε = n^{-0.029} and f is a mod 3 linear function. 

  All the results give one-sided distinguishers, and extend to the xor of more copies for suitable ε. 

  Meka and Zuckerman (RANDOM 2009) prove 5 with ε = O(1). Bogdanov, Dvir, Verbin, and Yehudayoff (Theory Of Computing 2013) prove 2 with ε = 2^{-O(√n)}. Chen and Zuckerman (personal communication) give an alternative proof of 4. 

  1-4 are obtained via a new and simple connection between small-bias distributions and error-correcting codes. 5 is obtained from bounding the mod 3 dimension of small bias spaces. Either technique is candidate to yield stronger negative results, in particular answering negatively Reingold and Vadhan\'s question of whether D+D fools logarithmic space for any ε = 1/n^{Ω(1)}. We also show that k=5-wise independence does not hit mod 3 linear functions, and conjecture it holds for k = Ω(n).',
    'paper_20' => 'We introduce a simple model illustrating the role of context in communication and the challenge posed by uncertainty of knowledge of context. We consider a variant of distributional communication complexity where Alice gets some information x and Bob gets y, where (x,y) is drawn from a known distribution, and Bob wishes to compute some function g(x,y) (with high probability over (x,y)). In our variant Alice does not know g, but only knows some function f which is an approximation of g. Thus, the function being computed forms the context for the communication, and knowing it imperfectly models (mild) uncertainty in this context. 

  A naive solution would be for Alice and Bob to first agree on some common function $h$ that is close to both f and g and then use a protocol for h to compute h(x,y). We show that any such agreement leads to a large overhead in communication ruling out such a universal solution. In contrast, we show that if g has a one-way communication protocol with low complexity in the standard setting, then it has a low communication protocol (with a constant factor blowup in communication and error) in the uncertain setting as well. We pose the possibility of a two-way version of this theorem as an open question. ',
    'paper_21' => 'Monotone Boolean functions, and the monotone Boolean circuits that compute them, have been intensively studied in complexity theory. In this paper we study the structure of Boolean functions in terms of the minimum number of negations in any circuit computing them, a complexity measure that interpolates between monotone functions and the class of all functions. We study this generalization of monotonicity from the vantage point of learning theory, establishing nearly matching upper and lower bounds on the uniform-distribution learnability of circuits in terms of the number of negations they contain. Our upper bounds are based on a new structural characterization of negation-limited circuits that extends a classical result of A. A. Markov. Our lower bounds, which employ Fourier-analytic tools from hardness amplification, give new results even for circuits with no negations (i.e. monotone functions).',
    'paper_22' => 'We study \emph{resistance sparsification} of graphs, in which the goal is to find a sparse subgraph (with reweighted edges) that approximately preserves the effective resistances between every pair of nodes. 
  We show that every dense regular expander admits 
  a $(1+\epsilon)$-resistance sparsifier of size $\tilde O(n/\epsilon)$, 
  and conjecture this bound holds for all graphs on $n$ nodes. 
  In comparison, spectral sparsification is a strictly stronger notion 
  and requires $\Omega(n/\epsilon^2)$ edges even on the complete graph. 

  Our approach leads to the following structural question on graphs: Does every dense regular expander contain a sparse regular expander as a subgraph? Our main technical contribution, which may of independent interest, is a positive answer to this question in a certain setting of parameters. Combining this with a recent result of von Luxburg, Radl, and Hein~(JMLR, 2014) leads to the aforementioned resistance sparsifiers.',
    'paper_23' => 'Given a stream with frequencies $f_d$, for $d\in[n]$, we characterize the space necessary for approximating the frequency negative moments~$F_p=\sum |f_d|^p$, where $p<0$ and the sum is taken over all items $d\in[n]$ with nonzero frequency, in terms of $n$, $\epsilon$, and $m=\sum |f_d|$. 
  To accomplish this, we actually prove a much more general result. 
  Given any nonnegative and nonincreasing function $g$, we characterize the space necessary for any streaming algorithm that outputs a $(1\pm\epsilon)$-approximation to $\sum g(|f_d|)$, where again the sum is over items with nonzero frequency. 
  The storage required is expressed in the form of the solution to a relatively simple nonlinear optimization problem, and the algorithm is universal for $(1\pm\epsilon)$-approximations to any such sum where the applied function is nonnegative, nonincreasing, and has the same or smaller space complexity as $g$. 
  This partially answers an open question of Nelson~(IITK Workshop Kanpur, 2009).',
    'paper_24' => 'When we try to solve a system of linear equations, we can consider a simple iterative algorithm in which an equation including only one variable is chosen at each step, and the variable is fixed to the value satisfying the 
  equation. The dynamics of this algorithm is captured by the peeling algorithm. Analyses of the peeling algorithm on 
  random hypergraphs are required for many problems, e.g., the decoding threshold of low-density parity check codes, 
  the inverting threshold of Goldreich’s pseudorandom generator, the load threshold of cuckoo hashing, etc. In this 
  work, we deal with random hypergraphs including superlinear number of hyperedges, and derive the tight threshold 
  for the succeeding of the peeling algorithm. For the analysis, Wormald’s method of differential equations, which 
  is commonly used for analyses of the peeling algorithm on random hypergraph with linear number of hyperedges, 
  cannot be used due to the superlinear number of hyperedges. A new method called the evolution of the moment 
  generating function is proposed in this work.',
    'paper_25' => 'The random-cluster model has been widely studied as a unifying framework for random graphs, spin systems and random spanning trees, but its dynamics have so far largely resisted analysis. In this paper we study a natural non-local Markov chain known as the Chayes-Machta dynamics for the mean-field case of the random-cluster model, and identify a critical regime $(\lambda_s,\lambda_S)$ of the model parameter $\lambda$ in which the dynamics undergoes an exponential slowdown. Namely, we prove that the mixing time is $\Theta(\log n)$ if $\lambda \not\in [\lambda_s,\lambda_S]$, and $\exp(\Omega(\sqrt{n}))$ when $\lambda \in (\lambda_s,\lambda_S)$. These results hold for all values of the second model parameter $q > 1$. In addition, we prove that the local heat-bath dynamics undergoes a similar exponential slowdown in $(\lambda_s,\lambda_S)$.',
    'paper_26' => 'We consider the \emph{black-box} polynomial identity testing ($\pit$) problem for a sub-class of 
  depth-4 $\depthfour(k,r)$ circuits. Such circuits compute polynomials of the following type: 
  \[ 
  C(\ex) = \sum_{i=1}^k \prod_{j=1}^{d_i} Q_{i,j}, 
  \] 
  where $k$ is the fan-in of the top $\Sigma$ gate and $r$ is the maximum degree of the polynomials 
  $\{Q_{i,j}\}_{i\in [k], j\in[d_i]}$, and $k,r=O(1)$. We consider a sub-class of such circuits satisfying a \emph{generic} algebraic-geometric restriction, and we give a deterministic polynomial-time black-box $\pit$ algorithm for such circuits. 

  Our study is motivated by two recent results of Mulmuley (FOCS 2012, \cite{Mul2013}), and Gupta (ECCC 2014, \cite{Gupta2014}). In particular, we obtain the derandomization by solving a particular instance of derandomization problem of Noether\'s Normalization Lemma ($\nnl$). Our result can also be considered as a unified way of viewing the depth-4 $\pit$ problems closely related to the work of 
  Gupta \cite{Gupta2014}, and the approach suggested by Mulmuley \cite{Mul2013}. The importance of unifying $\pit$ results is already exhibited by Agrawal et al. via the Jacobian approach (STOC 2012, \cite{ASSS12}). To the best of our knowledge, the only known result that shows a derandomization of restricted $\nnl$ in the context of $\pit$ problem, is the work of Forbes and Shpilka (RANDOM 2013, \cite{FS13}, and FOCS 2013, \cite{FrS13}). Forbes and Shpilka considered the black-box identity testing of noncommutative algebraic branching programs (ABPs). ',
    'paper_27' => 'This paper shows that the logarithm of the number of solutions of a random planted $k$-SAT formula concentrates around a deterministic $n$-independent threshold. 
  Specifically, if $F^*_{k}(\alpha,n)$ is a random $k$-SAT formula on $n$ variables, with clause density $\alpha$ and with a uniformly drawn planted solution, there exists a function $\phi_k(\cdot)$ such that, besides for some $\alpha$ in a set of Lesbegue measure zero, we have 
  $ \frac{1}{n}\log Z(F^*_{k}(\alpha,n)) \to \phi_k(\alpha)$ in probability, where $Z(F)$ is the number of solutions of the formula $F$. This settles a problem left open in Abbe-Montanari RANDOM 2013, where the concentration is obtained only for the expected logarithm over the clause distribution. The result is also extended to a more general class of random planted CSPs; in particular, it is shown that the number of pre-images for the Goldreich one-way function model concentrates for some choices of the predicates.',
    'paper_28' => 'Numerical linear algebra plays an important role in computer science. In this paper, we initiate the study of performing linear algebraic tasks while preserving privacy when the data is streamed online. Our main focus is the space requirement of the privacy-preserving data-structures. We give the first {\em sketch-based} algorithm for differential privacy. We give optimal, up to logarithmic factor, space data-structures that can compute low rank approximation, linear regression, and matrix multiplication, while preserving differential privacy with better additive error bounds compared to the known results. Notably, we match the best known space bound in the non-private setting by Kane and Nelson (J. ACM, 61(1):4). 

  Our mechanism for differentially private low-rank approximation {\em reuses} the random Gaussian matrix in a specific way to provide a single-pass mechanism. We prove that the resulting distribution also preserve differential privacy. This can be of independent interest. We do not make any assumptions, like singular value separation or normalized row assumption, as made in the earlier works. The mechanisms for matrix multiplication and linear regression can be seen as the private analogues of the known non-private algorithms. All our mechanisms, in the form presented, can also be computed in the distributed setting. ',
    'paper_29' => 'We tighten the connections between circuit lower bounds and 
  derandomization for each of the following three types of 
  derandomization: 

  - general derandomization of promiseBPP (connected to Boolean 
  circuits), 
  - derandomization of Polynomial Identity Testing (PIT) over 
  fixed finite fields (connected to arithmetic circuit lower bounds 
  over the same field), and 
  - derandomization of PIT over the integers (connected to 
  arithmetic circuit lower bounds over the integers). 

  We show how to make these connections uniform equivalences, 
  although at the expense of using somewhat less 
  common versions of complexity classes and for a less studied notion of 
  inclusion. 

  Our main results are as follows: 

  1. We give the first proof that a non-trivial 
  (nondeterministic subexponential-time) algorithm for PIT over a 
  fixed finite field yields arithmetic circuit lower bounds. 

  2. We get a similar result for the case of PIT over the integers, strengthening 
  a result of Jansen and Santhanam (by removing the need for 
  advice). 

  3. We derive a Boolean circuit lower bound for NEXP intersect coNEXP from the 
  assumption of sufficiently strong non-deterministic 
  derandomization of promiseBPP (without advice), as well as from the assumed existence of an P-computable non-empty property of Boolean functions useful for proving superpolynomial circuit lower bounds (in the sense of natural proofs of (Razborov,Rudich 97)); this strengthens 
  the related results of [IKW02]. 

  4. Finally, we turn all of these implications into equivalences for the appropriately defined promise classes and for the notion of robust inclusion/separation (in the spirit of Fortnow and Santhanam\'s definitions [FS11]) that lies between the classical "almost everywhere" and "infinitely often" notions.',
    'paper_30' => 'The subcube partition model of computation is at least as powerful as decision trees but no separation between these models was known. We show that there exists a function whose deterministic subcube partition complexity is asymptotically smaller than its randomized decision tree complexity, resolving an open problem of Friedgut, Kahn, and Wigderson (2002). Our lower bound is based on the information-theoretic techniques first introduced to lower bound the randomized decision tree complexity of the recursive majority function. 

  We also show that the public-coin partition bound, the best known lower bound method for randomized decision tree complexity subsuming other general techniques such as block sensitivity, approximate degree, randomized certificate complexity, and the classical adversary bound, also lower bounds randomized subcube partition complexity. This shows that all these lower bound techniques cannot prove optimal lower bounds for randomized decision tree complexity, which answers an open question of Jain and Klauck (2010) and Jain, Lee, and Vishnoi (2014).',
    'paper_31' => 'We present the first efficient deterministic algorithm for factoring sparse polynomials that split into multilinear factors and sums of univariate polynomials. 
  Our result makes partial progress towards the resolution of the classical question posed by von zur Gathen and Kaltofen in \cite{GathenKaltofen85} to devise an efficient deterministic algorithm for factoring (general) sparse polynomials. 
  We achieve our goal by introducing \emph{essential factorization schemes} which can be thought of a relaxation of the regular factorization notion.',
    'paper_33' => 'The problem of cumulative response due to random processes triggered at random instants of time is formulated in terms of stochastic point process. The object of this contribution is to demonstrate the possibility of using certain correlation functions known as product densities, to deal with non stationary problems. Product densities are defined so as to apply them in a wider context. An example is provided to explicitly obtain the moments of the cumulative response using product densities for time dependent arrival rate. We demonstrate the use of product densities to evaluate two important parameters in a broadband communication network viz.,, cumulative bandwidth and total revenue earned, at any given time. Broadband communication networks offer multiple services like voice, data, streaming video, 
  interactive gaming etc. The cumulative bandwidth usage as well as the service provider’s revenue at any given time depends on random instants of time of arrival followed by random usage time, thus exhibiting the stochastic point process model under study. Using product densities, the expected cumulative bandwidth and revenue are estimated for time dependent arrival rates. For packet networks, we define multiple product densities to accommodate the batch arrivals of packets.',
    'paper_34' => 'Let $G(n,\, M)$ be the uniform random graph with $n$ vertices and $M$ edges. 
  Let $\circ$ be the circumference of $G(n,\, M)$ or the maximum length of its cycles. We determine the expectation of $\circ$ near the critical point $M=n/2$. As $n-2M \gg n^{2/3}$, we find a constant $c_1$ such that 
  \[ c_1 = \lim_{n \rightarrow \infty} \left( 1 - \frac{2M}{n} \right) \, \qE{(\circ)} \, . \] 
  Inside the window of transition of $G(n,\, M)$ with $M=\frac{n}{2}(1+\lambda n^{-1/3})$, 
  where $\lambda$ is any real number, we find an exact analytic expression for 
  \[ c_2(\lambda) = \lim_{n \rightarrow \infty} \frac{\qE{\l(\circarg{\frac{n}{2}(1+\lambda n^{-1/3})}\r)}} {n^{1/3}} \, . \] 
  This study relies on the symbolic method and analytical tools coming from generating function theory which enable us 
  to describe the evolution of $n^{-1/3} \, \qE{\l(\circarg{\frac{n}{2}(1+\lambda n^{-1/3})}\r)}$ as a function of $\lambda$. 
  Our results complete previously obtained informations about circumferences of random graphs and 
  their tightness points out the benefit one could get in developping generating function methods to investigate 
  extremal parameters of the critical random graphs.',
    'paper_35' => 'For a set $\Pi$ in a metric space and $\delta>0$, denote by $\mathcal{F}_\delta(\Pi)$ the set of elements that are $\delta$-far from $\Pi$. In property testing, a $\delta$-tester for $\Pi$ is required to accept inputs from $\Pi$ and reject inputs from $\mathcal{F}_\delta(\Pi)$. A natural \emph{dual problem} is the problem of $\delta$-testing the set of "no\'\' instances, that is $\mathcal{F}_\delta(\Pi)$: A $\delta$-tester for $\mathcal{F}_\delta(\Pi)$ needs to accept inputs from $\mathcal{F}_\delta(\Pi)$ and reject inputs that are $\delta$-far from $\mathcal{F}_\delta(\Pi)$, that is reject inputs from $\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$. When $\Pi=\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$ the two problems are essentially equivalent, but this equality does not hold in general. 

  In this work we study sets of the form $\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$, and apply this study to investigate dual problems in property testing. In particular, we present conditions on a metric space, on $\delta$, and on a set $\Pi$ that are sufficient and/or necessary in order for the equality $\Pi=\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$ to hold. Using these conditions, we derive bounds on the query complexity of several classes of natural dual problems in property testing. These include the dual problems of testing \emph{codes with constant relative distance}, testing \emph{monotone functions}, testing whether a \emph{distribution is identical} to a known distribution, and testing several \emph{graphs properties in the dense graph model}. In some cases, our results are obtained by showing that $\Pi=\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$; in other cases, the results follow by showing that inputs in $\mathcal{F}_\delta(\mathcal{F}_\delta(\Pi))$ are sufficiently close to $\Pi$. We also show that testing any dual problem with \emph{one-sided error} is either trivial or requires a linear number of queries.',
    'paper_36' => 'We introduce a new framework for proving the time hierarchy theorem for heuristic classes.
  The main ingredient of our proof is a hierarchy theorem for sampling 
  distributions recently proved by Watson [W13]. Class $Heur_{\epsilon}FBPP$ consists of functions with distributions on their inputs that can be computed in randomized polynomial time with bounded error on all except $\epsilon$ fraction of inputs.
  We prove that for every $a$, $\delta$ and integer $k$ there exists a function 
  $F:\{0,1\}^*\to \{0,1, \dots, k-1\}$ such that $(F,U)\in Heur_{\epsilon}FBPP$ for all $\epsilon>0$ and for every ensemble of distributions $D_n$ samplable in $n^a$ steps, $(F,D) \not\in Heur_{1 - \frac{1}{k}-\delta}FBPTime[n^b]$.
  This extends a previously known result for languages with uniform distributions 
  proved by Pervyshev [P7].

  We also prove that $P \not\subseteq Heur[\frac12-\epsilon]BPTime[n^k]$ if one-way functions exist.

  We also show that our technique may be extended for time hierarchies in some other heuristic classes.',
    'paper_37' => 'We study the q-state ferromagnetic Potts model on the n-vertex complete graph known as the mean-field (Curie-Weiss) model. We analyze the Swendsen-Wang algorithm which is a Markov chain that utilizes the random cluster representation for the ferromagnetic Potts model to recolor large sets of vertices in one step and potentially overcomes obstacles that inhibit single-site Glauber dynamics. The case q=2 (the Swendsen-Wang algorithm for the ferromagnetic Ising model) undergoes a slow-down at the uniqueness/non-uniqueness critical temperature for the infinite \Delta-regular tree (Long et al., 2014) but yet still has polynomial mixing time at all (inverse) temperatures \beta>0 (Cooper et al., 2000). In contrast for q\geq 3 there are two critical temperatures 0<\betau<\betarc that are relevant, these two critical points relate to phase transitions in the infinite tree. We prove that the mixing time of the 
  Swendsen-Wang algorithm for the ferromagnetic Potts model on the n-vertex complete graph satisfies: (i) O(\log{n}) for \beta<\betau, (ii) O(n^{1/3}) for \beta=\betau, (iii) \exp(n^{\Omega(1)}) for \betau<\beta<\betarc, and (iv) O(\log{n}) for \beta\geq\betarc. These results complement refined results of Cuff et al. (2012) on the mixing time of the Glauber dynamics for the ferromagnetic Potts model. The most interesting aspect of our analysis is at the critical temperature \beta=\betau, which requires a delicate choice of a potential function to balance the conflating factors for the slow drift away from a fixed point (which is repulsive but not Jacobian repulsive): close to the fixed point the variance from the percolation step dominates and sufficiently far from the fixed point the dynamics of the size of the dominant color class takes over.',
    'paper_38' => 'Hardcore and Ising models are two most important families of two state spin systems in statistic physics. Partition function of spin systems is the center concept in statistic physics which connects microscopic particles and their interactions with their macroscopic and statistical properties of materials such as energy, entropy, 
  ferromagnetism, etc. If each local interaction of the system involves only two particles, the system can be described by a graph. In this case, fully polynomial-time approximation scheme (FPTAS) for computing the partition function of both hardcore and anti-ferromagnetic Ising model was designed up to the uniqueness 
  condition of the system. These result are the best possible since approximately computing the partition function beyond this threshold is NP-hard. In this paper, we generalize these results to general physics systems, where each local interaction may involves multiple particles. Such systems are described by hypergraphs. For hardcore model, we also provide FPTAS up to the uniqueness condition, and for anti-ferromagnetic Ising model, we obtain FPTAS where a slightly stronger condition holds.',
    'paper_39' => 'We give an efficient structural decomposition theorem for formulas that depends
  on their negation complexity and demonstrate its power with the following
  applications:
  <ul>
  <li> We prove that every formula that contains $t$ negation gates can be shrunk
  using a random restriction to a formula of size $O(t)$ with the shrinkage
  exponent of monotone formulas. As a result, the shrinkage exponent of formulas
  that contain a constant number of negation gates is equal to the shrinkage
  exponent of monotone formulas.</li>
  <li> We give an efficient transformation from formulas with $t$ negations to circuits with $\log{t}$ negations. This transformation provides a generic way to cast results for negation-limited circuits to the setting of negation-limited formulas.</li></ul>',
    'paper_40' => 'Schubert polynomials were discovered by A. Lascoux and M. Sch\"utzenberger in the study of cohomology rings of flag manifolds in 1980\'s. These polynomials form a linear basis of multivariate polynomials, and yield a natural generalization of the classical Newton interpolation formula to the multivariate case. 

  In this paper we first show that evaluating Schubert polynomials over nonnegative integral inputs is in #P. Our main result is a deterministic algorithm that computes the expansion of a polynomial f of degree d in Z[x_1, \dots, x_n] in the basis of Schubert polynomials, assuming an oracle computing Schubert polynomials. This algorithm runs in time polynomial in n, d, and the bit size of the expansion. This generalizes, and derandomizes, the sparse interpolation algorithm of symmetric polynomials in the Schur basis by Barvinok and Fomin (Advances in Applied Mathematics, 18(3):271--285). It is achieved by combining the structure of the Barvinok-Fomin algorithm with several ingredients from the deterministic interpolation algorithm for sparse polynomials by Klivans and Spielman (STOC 2001). In fact, our interpolation algorithm is general enough to accommodate any linear basis satisfying certain natural properties. 

  The algorithms developed can be used to compute the generalized Littlewood-Richardson coefficients, Kostka numbers, and irreducible characters of the symmetric group.',
    'paper_41' => 'The Hamming and the edit metrics are two common notions of measuring distances between pairs of strings x,y lying in the Boolean hypercube. The edit distance between x and y is defined as the minimum number of character insertion, deletion, and bit flips needed for converting x into y. Whereas, the Hamming distance between x and y is the number of bit flips needed for converting x to y. 

  In this paper we study a randomized injective embedding of the edit distance into the Hamming distance with a small distortion. This question was studied by Jowhari (ESA 2012) and is mainly motivated by two questions in communication complexity: the document exchange problem and deciding edit distance using a 
  sketching protocol. 

  We show a randomized embedding with quadratic distortion. Namely, for any x,y satisfying that their edit distance equals k, the Hamming distance between the embedding of x and y is O(k^2) with high probability. This improves over the distortion ratio of O(\log n \log^* n) obtained by Jowhari for small values of k. Moreover, the embedding output size is linear in the input size and the embedding can be computed using a single pass over the input. ',
    'paper_42' => 'A recent result of Moshkovitz~\cite{Moshkovitz14} presented an ingenious method to provide a completely elementary proof of the \emph{Parallel Repetition Theorem} for certain projection games via a construction called \emph{fortification}. However, the construction used in \cite{Moshkovitz14} to fortify arbitrary label cover instances using an arbitrary extractor is insufficient to prove parallel repetition. In this paper, we provide a fix by using a stronger graph that we call \emph{fortifiers}. Fortifiers are graphs that have both $\ell_1$ and $\ell_2$ guarantees on induced distributions from large subsets. 

  We then show that an expander with sufficient spectral gap, or a bi-regular extractor with stronger parameters (the latter is also the construction used in an independent update \cite{Moshkovitz15} of \cite{Moshkovitz14} with an alternate argument), is a good fortifier. We also show that using a fortifier (in particular $\ell_2$ guarantees) is necessary for obtaining the robustness required for fortification. 

  Furthermore, we show that this can yield a similar parallel repetition theorem for robust general games and not just robust projection games on bi-regular graphs.',
    'paper_43' => 'Gibbs measures induced by random factor graphs play a prominent role in computer science, combinatorics and physics. A key problem is to calculate the typical value of the partition function. According to the "replica symmetric cavity method", a heuristic that rests on non-rigorous considerations from statistical mechanics, in many cases this problem can be tackled by way of maximising a functional called the "Bethe free energy". In this paper we prove that the Bethe free energy upper-bounds the partition function in a broad class of models. Additionally, we provide a handy sufficient condition for this upper bound to be tight.',
    'paper_44' => 'Given a stream of data, a typical approach in streaming algorithms is to design a sophisticated algorithm with small memory that computes a specific statistic over the streaming data. Usually, if one wants to compute a different statistic after the stream is gone, it is impossible. But what if we want to compute a different statistic after the fact? In this paper, we consider the following fascinating possibility: can we collect some small amount of specific data during the stream that is "universal," i.e., where we do not know anything about the statistics we will want to later compute, other than the guarantee that had we known the statistic ahead of time, it would have been possible to do so with small memory? This is indeed what we introduce (and show) in this paper with matching upper and lower bounds: we show that it is possible to collect universal statistics of polylogarithmic size, and prove that these universal statistics allow us after the fact to compute all other statistics that are computable with similar amounts of memory. We show that this is indeed possible, both for the standard unbounded streaming model and the sliding window streaming model.',
    'paper_45' => 'Kernel methods are an extremely popular set of techniques used for many important machine learning and data analysis applications. In addition to having good practical performance, these methods are supported by a well-developed theory. Kernel methods use an implicit mapping of the input data into a high dimensional feature space defined by a kernel function, i.e., a function returning the inner product between the images of two data points in the feature space. Central to any kernel method is the kernel matrix, which is built by evaluating the kernel function on a given sample dataset. 

  In this paper, we initiate the study of non-asymptotic spectral theory of random kernel matrices. These are n x n random matrices whose (i,j)th entry is obtained by evaluating the kernel function on x_i and x_j, where x_1,...,x_n are a set of n independent random high-dimensional vectors. Our main contribution is to obtain tight upper bounds on the spectral norm (largest eigenvalue) of random kernel matrices constructed by commonly used kernel functions based on polynomials and Gaussian radial basis. 

  As an application of these results, we provide lower bounds on the distortion needed for releasing the coefficients of kernel ridge regression under attribute privacy, a general privacy notion which captures a large class of privacy definitions. Kernel ridge regression is standard method for performing non-parametric regression that regularly outperforms traditional regression approaches in various domains. Our privacy distortion lower bounds are the first for any kernel technique, and our analysis assumes realistic scenarios for the input, unlike all previous lower bounds for other release problems which only hold under very restrictive input settings.',
    'paper_46' => 'In the planted bisection model a random graph G(n,p₊,p₋) with n vertices is created by partitioning the vertices randomly into two classes of equal size (up to ±1). Any two vertices that belong to the same class are linked by an edge with probability p₊ and any two that belong to different classes with probability p₋<p₊ independently. The planted bisection model has been used extensively to benchmark graph partitioning algorithms. If p₊=d₊/n and p₋=d₋/n for numbers 0<=d₋<d₊ that remain fixed as n tends to infinity, then whp the "planted bisection (the one used to construct the graph) will not be a minimum bisection. In this paper we derive an asymptotic formula for the minimum bisection width under the assumption that d₊ -d₋ > c √(d₊ ln(d₊)) 
  for a certain constant c>0. ',
    'paper_47' => 'We study the effect that the amount of correlation in a bipartite distribution has on the communication complexity of a problem under that distribution. We introduce a new family of complexity measures that interpolates between the two previously studied extreme cases: the (standard) randomised communication complexity and the case of distributional complexity under product distributions. 

  We have 3 main applications. First, we closely investigate the case of the Disjointness problem. Second, we show that a certain problem exhibits a threshold behaviour, i.e., only with almost maximal correlation can a tight lower bound be proved, and this correlation can also be larger than the actual communication complexity of the problem. Third, we investigate the dependence of one-way communication complexity under product distributions on the allowed error.',
    'paper_48' => 'We give a deterministic algorithm that counts the number of satisfying assignments for any De Morgan formula $F$ of size at most $n^{3-16\varepsilon}$ in $2^{n-n^{\varepsilon}}\cdot \mathrm{poly}(n)$ time, for any constant $\varepsilon$. We do so by derandomizing the randomized algorithm mentioned by Komargodski et al. (FOCS, 2013) and Chen et al. (CCC, 2014). Our result uses the tight "shrinkage in expectation" result of De Morgan formulas by H{\aa}stad (SICOMP, 1998) as a black-box, and improves upon the result of Chen et al. (MFCS, 2014) that gave deterministic counting algorithms for De Morgan formulas of size at most $n^{2.63}$. 

  Our algorithm generalizes to other bases of Boolean gates, giving a $2^{n-n^{\varepsilon}}\cdot \mathrm{poly}(n)$ time counting algorithm for formulas of size at most $n^{\Gamma +1 - O(\varepsilon)}$, where $\Gamma$ is the shrinkage exponent for formulas using gates from the basis. ',
    'paper_49' => 'In this paper, we consider the planted partition model, in which $n = ks$ vertices of a random graph are partitioned into $k$ "clusters," each of size $s$. Edges between vertices in the same cluster and different clusters are included with constant probability $p$ and $q$, respectively (where $0 \le q < p \le 1$). 
  We give an efficient algorithm that, with high probability, recovers the clustering as long as the cluster sizes are are least $\Omega(\sqrt{n})$. Our algorithm is based on projecting the graph\'s adjacency matrix onto the space spanned by its largest eigenvalues and using the result to recover one cluster at a time. While certainly not the first to use the spectral approach, our algorithm has the advantage of being simple, and we use a novel application of the Cauchy integral formula to prove its correctness.',
    'paper_50' => 'The perfect matching problem has a randomized NC algorithm, using the celebrated
  Isolation Lemma of Mulmuley, Vazirani and Vazirani. The Isolation Lemma states that 
  giving a random weight assignment to the edges of a graph, ensures that it has a 
  unique minimum weight perfect matching, with a good probability. 
  We derandomize this lemma for K_{3,3}-free and K_5-free bipartite graphs, i.e.
  we give a deterministic log-space construction of such a weight assignment for these 
  graphs. Such a construction was known previously for planar bipartite graphs. 
  Our result implies that the perfect matching problem for K_{3,3}-free and K_5-free 
  bipartite graphs is in SPL. It also gives an alternate proof for an already known 
  result -- reachability for K_{3,3}-free and K_5-free graphs is in UL.',
    'paper_52' => 'Let $D(n,r)$ be a random $r$-out regular directed multigraph on the set of vertices $\{1,\ldots,n\}$. In this work, we study different properties of such graphs, for fixed $r$ and large $n$. Our main result is a tight bound on the diameter: for every $r \ge 2$, there exists $\eta_r>0$ such that $\diam(D(n,r))=(1+\eta_r+o_p(1))\log_r{n}$. Our techniques also allow us to study the stationary distribution of a simple random walk in the unique attractive component of $D(n,r)$. We are able to determine the asymptotic behaviour of $\pi_{\max}$ and $\pi_{\min}$, the maximum and the minimum values of the stationary distribution. In contrast to the undirected case, we determine that $\pi_{\min}=n^{-(1+\eta_r)+o_p(1)}$.',
    'paper_53' => 'Let G be a graph G=(V,E) with maximum degree d. The k-disc of a vertex v is defined as the rooted subgraph that is induced by all vertices whose distance to v is at most k. The k-disc frequency vector of G, freq(G), is a vector indexed by all isomorphism types of k-discs. For each such isomorphism type Gamma, the k-disc frequency vector counts the fraction of vertices that have k-disc isomorphic to Gamma. Thus, the frequency vector freq(G) of G captures the local structure of G. A natural question is whether one can construct a much smaller graph H such that H has a similar local structure. Noga Alon proved that there always exists a graph H whose size is independent of n and whose frequency vector satisfies ||freq(G) - freq(G)||_1 <= eps. However, his proof is only existential and neither gives an explicit bound on the size of H nor an efficient algorithm. He gave the open problem to find such explicit bounds. In this paper, we solve this problem for the special case of high girth graphs. We show how to efficiently compute a graph H with the above properties when G has girth at least 2k+2 and we give explicit bounds on the size of H.',
    'paper_54' => 'Consider n nodes connected to a single coordinator. 
  Each node receives a data stream of numbers and the coordinator is supposed to continuously keep track of the $k$ nodes currently observing the largest values, for a given k between 1 and n. 
  We design randomized online algorithms that solve (a relaxation of) this problem while bounding the amount of messages exchanged between the nodes and the coordinator for a model in which the coordinator can utilize a broadcast-channel. 
  Our algorithms employ the idea of using filters which, intuitively speaking, leads to few messages to be sent, if the new input is "similar" to the previous ones. 
  We analyze the amount of communication of the online algorithms and compare it to offline algorithms that set filters in an optimal way to prove bounds on the competitiveness.',
    'paper_55' => 'We consider the problem of identifying a subset of nodes in a 
  network that will enable the fastest spread of information in a decentral- 
  ized communication environment. For a model of communication based 
  on a random walk on a connected undirected graph, the optimal set over 
  all sets A of the same or smaller cardinality, minimizes F(A)-the sum 
  of the mean first arrival times to the set by random walkers starting at 
  nodes outside of A. This problem was originally posed by Borkar, Nair 
  and Sanketh (2010) who proved that the set function F is supermodular. 
  Unfortunately, the problem as stated is probably NP-complete. In this 
  paper, we introduce an extension of the greedy algorithm that leverages 
  the properties of the underlying graph to produce exact and approximate 
  solutions of pre-defined quality . The method requires the evaluation of 
  F for sets of some fixed cardinality m, where m is much smaller than the 
  cardinality of the optimal set. When F has forward elemental curvature 
  k, we can provide a rough description of the trade-off between solution 
  quality and computational effort m in terms of k .',
    'paper_56' => 'The rectangle covering number of an n by n Boolean matrix M is the smallest number of 1-rectangles which are needed to cover all the 1-entries of M. Its binary logarithm is the Nondeterministic Communication Complexity, and it equals the chromatic number of a graph obtained from M by a construction of Lov\'asz & Saks. 

  We study the rectangle covering number and related parameters (clique size, independence ratio, fractional chromatic number) of random Boolean matrices, where each entry is 1 with probability p=p(n), and the entries are independent. ',
    'paper_57' => 'We consider the reconstruction of a phylogeny
  from multiple genes under the multispecies coalescent.
  We establish a connection with the sparse signal detection
  problem, where one seeks to distinguish between
  a distribution and a mixture of the distribution 
  and a sparse signal. Using this connection,
  we derive an information-theoretic trade-off
  between the number of genes, $m$, needed for an accurate
  reconstruction and the sequence length, $k$, of the
  genes. Specifically, we show that to detect
  a branch of length $f$, one needs $m = \Theta(1/[f^{2} \sqrt{k}])$.',
    'paper_58' => 'Computational notions of entropy have recently found many applications, including 
  leakage-resilient cryptography, deterministic encryption or memory delegation. 
  The two main types of results which make computational notions so useful are 
  (1) Chain rules, which quantify by how much the computational entropy of a variable decreases if conditioned on some other variable (2) Transformations, which quantify to which extend one type of entropy implies another. 

  Such chain rules and transformations typically lose a significant amount in 
  quality of the entropy, and are the reason why applying these results one gets rather weak 
  quantitative security bounds. In this paper we prove lower bounds, showing that existing 
  results for transformations are, unfortunately, basically optimal when using black-box reductions (and it\'s hard 
  to imagine how non black-box reductions could be useful in this context.) 

  A variable $X$ has $k$ bits of HILL entropy of quality $(\epsilon,s)$ if there exists a variable $Y$ with 
  $k$ bits min-entropy which cannot be distinguished from $X$ with advantage $\epsilon$ by 
  distinguishing circuits of size $s$. A weaker notion 
  is Metric entropy, where we switch quantifiers, and only require that 
  for every distinguisher of size $s$, such a $Y$ exists. 


  We first describe our result concerning transformations. By definition, HILL implies Metric without any loss in quality. 
  Metric entropy often comes up in applications, but must be transformed to HILL for meaningful security guarantees. 
  The best known result states that if a variable $X$ has $k$ bits of Metric entropy of quality $(\epsilon,s)$, then 
  it has $k$ bits of HILL with quality $(2\epsilon,s\cdot\epsilon^2)$. 
  We show that this loss of a factor $\Omega(\epsilon^{-2})$ in circuit size is necessary. In fact, we show the stronger result that this loss is already necessary when transforming so called deterministic real valued Metric entropy to randomised boolean Metric (both these variants of Metric entropy are implied by HILL without loss in quality). 

  The chain rule for HILL entropy states that if $X$ has $k$ bits of HILL entropy of quality $(\epsilon,s)$, then for any 
  variable $Z$ of length $m$, $X$ conditioned on $Z$ has $k-m$ bits of HILL entropy with quality $(\epsilon,s\cdot \epsilon^2/ 2^{m})$. We show that a loss of $\Omega(2^m/\epsilon)$ in circuit size necessary here. 
  Note that this still leaves a gap of $\epsilon$ between the known bound and our lower bound.',
    'paper_59' => 'We consider the problem of tracking with small relative error an integer function $f(n)$ defined by a distributed update stream $f\'(n)$. Existing streaming algorithms with worst-case guarantees for this problem assume $f(n)$ to be monotone; there are very large lower bounds on the space requirements for summarizing a distributed non-monotonic stream, often linear in the size $n$ of the stream. 

  Input streams that give rise to large space requirements are highly variable, making relatively large jumps from one timestep to the next. However, in practice the impact on $f(n)$ of any single update $f\'(n)$ is usually small. What has heretofore been lacking is a framework for non-monotonic streams that admits algorithms whose worst-case performance is as good as existing algorithms for monotone streams and degrades gracefully for non-monotonic streams as those streams vary more quickly. 

  In this paper we propose such a framework. We introduce a new stream parameter, the "variability" $v$, deriving its definition in a way that shows it to be a natural parameter to consider for non-monotonic streams. It is also a useful parameter. From a theoretical perspective, we can adapt existing algorithms for monotone streams to work for non-monotonic streams, with only minor modifications, in such a way that they reduce to the monotone case when the stream happens to be monotone, and in such a way that we can refine the worst-case communication bounds from $\Theta(n)$ to $\tilde{O}(v)$. From a practical perspective, we demonstrate that $v$ can be small in practice by proving that $v$ is $O(\log f(n))$ for monotone streams and $o(n)$ for streams that are "nearly" monotone or that are generated by random walks. We expect $v$ to be $o(n)$ for many other interesting input classes as well.',
    'paper_60' => 'A quantile summary is a data structure that approximates to $\ep$-relative error the order statistics of a much larger underlying dataset. 

  In this paper we develop a randomized online quantile summary for the cash register data input model and comparison data domain model that uses $\OO{\frac{1}{\ep} \log \frac{1}{\ep}}$ words of memory. This improves upon the previous best upper bound of $\OO{\frac{1}{\ep} \log^{3/2} \frac{1}{\ep}}$ by Agarwal et. al. (PODS 2012). Further, by a lower bound of Hung and Ting (FAW 2010) no deterministic summary for the comparison model can outperform our randomized summary in terms of space complexity. Lastly, our summary has the nice property that $\OO{\frac{1}{\ep} \log \frac{1}{\ep}}$ words suffice to ensure that the success probability is $1 - e^{-\poly{1/\ep}}$.',
    'paper_61' => 'Tensor rank and low-rank tensor decompositions have many applications in learning and complexity theory. Most known algorithms use unfoldings of tensors and can only handle rank up to $n^{\lfloor p/2 \rfloor}$ for a $p$-th order tensor in $\R^{n^p}$. Previously no efficient algorithm can decompose 3rd order tensors when the rank is super-linear in the dimension. Using ideas from sum-of-squares hierarchy, we give the first quasi-polynomial time algorithm that can decompose a random 3rd order tensor decomposition when the rank is as large as $n^{3/2}/\poly\log n$. 

  We also give a polynomial time algorithm for certifying the injective norm of random low rank tensors. Our tensor decomposition algorithm exploits the relationship between injective norm and the tensor components. The proof relies on interesting tools for decoupling random variables to prove better matrix concentration bounds, which can be useful in other settings.',
    'paper_62' => 'We give a fully explicit construction of hitting set generators for low-degree polynomials, with close to optimal parameters. Unlike the fully explicit construction by Lu (CCC’12), that achieves slightly better parameters, our construction is purely algebraic, which is the nature of the problem at hand, and we believe it to be conceptually simpler. Further, our construction is direct and does not rely on previous constructions – an approach taken by Guruswami and Xing (CCC’14), who used an alphabet reduction technique and obtained a weakly explicit construction with optimal parameters. Our analysis relies on the Riemann-Roch theorem and on the isolation lemma.',
    'paper_63' => 'The broadcasting models on trees arise in many contexts such as discrete mathematics, biology, information theory, statistical physics and computer science. In this work, we consider the k-colouring model. A basic question here is whether the root\'s assignment affects the distribution of the colourings at the vertices at distance h from the root. This is the so-called reconstruction problem. For the case where the underlying tree is d-ary it is well known that d/ln(d) is the reconstruction threshold. That is, for k=(1+\eps)d/ln(d) we have non-reconstruction while for k=(1-eps)d/ln (d) we have reconstruction. 

  Here, we consider the largely unstudied case where the underlying tree is chosen according to a predefined distribution. In particular, our focus is on the well-known Galton-Watson trees. This model arises naturally in many contexts, e.g. the theory of spin-glasses and its applications on random Constraint Satisfaction Problems (rCSP). The aforementioned study focuses on Galton-Watson trees with offspring distribution B(n,d/n),
  i.e. the binomial with parameters n and d/n, where d is fixed. Here we consider a broader version of the problem, as we assume a general offspring distribution, which includes B(n,d/n) as a special case. 

  Our approach relates the corresponding bounds for (non)reconstruction to certain concentration properties of the offspring distribution. This allows to derive reconstruction thresholds for a very wide family of offspring distributions, which includes B(n,d/n). A very interesting corollary is that for distributions with expected offspring d, we get reconstruction threshold d/ln(d) under weaker concentration conditions than what we have in B(n,d/n). 

  Furthermore, our reconstruction threshold for the random colorings of Galton-Watson with offspring 
  B(n,d/n), implies the reconstruction threshold for the random colourings of G(n,d/n).',
    'paper_64' => 'We consider the problem of learning k-parities in the on-line mistake-bound model: given a hidden vector x in {0,1}^n with |x|=k and a sequence of "questions" a_1, a_2, ... in {0,1}^n, where the algorithm must reply to each question with <a_i, x> (mod 2), what is the best tradeoff between the number of mistakes made by the algorithm and its time complexity? We improve the previous best result of Buhrman et. al. by an exp(k) factor in the time complexity. We also observe that even in the presence of classification noise of non-trivial rate, it is possible to learn k-parities in time better than (n choose k/2), whereas the current best algorithm for learning noisy k-parities, due to Grigorescu et al., inherently requires time (n \choose k/2) even when the noise rate is polynomially small.',
    'paper_65' => 'In this paper, two structural results concerning low degree polynomials over finite fields are given. The first states that over any finite field F, for any polynomial $f$ on $n$ variables with degree $d \le \log(n)/10$, there exists a subspace of $F^n$ with dimension $\Omega(d n^{1/(d-1)})$ on which $f$ is constant. This result is shown to be tight. Stated differently, a degree $d$ polynomial cannot compute an affine disperser for dimension smaller than $\Omega(d \cdot n^{1/(d-1)})$. Using a recursive argument, we obtain our second structural result, showing that any degree $d$ polynomial $f$ induces a partition of $F^n$ to affine subspaces of dimension $\Omega(n^{1/(d-1)!})$, such that $f$ is constant on each part. 

  We extend both structural results to more than one polynomial. We further prove an analog of the first structural result to sparse polynomials (with no restriction on the degree) and to functions that are close to low degree polynomials. We also consider the algorithmic aspect of the two structural results. 

  Our structural results have various applications, two of which are: 
  * Dvir [CC 2012] introduced the notion of extractors for varieties, and gave explicit constructions of such extractors over large fields. We show that over any finite field any affine extractor is also an extractor for varieties with related parameters. Our reduction also holds for dispersers, and we conclude that Shaltiel\'s affine disperser [FOCS 2011] is a disperser for varieties over the binary field. 

  * Ben-Sasson and Kopparty [SIAM J. C 2012] proved that any degree 3 affine disperser over a prime field is also an affine extractor with related parameters. Using our structural results, and based on the work of Kaufman and Lovett [FOCS 2008] and Haramaty and Shpilka [STOC 2010], we generalize this result to any constant degree.',
    'paper_66' => 'Low-degree polynomial approximations to the sign function underly pseudorandom generators for halfspaces, as well as algorithms for agnostically learning halfspaces. We study the limits of these constructions by proving inapproximability results for the sign function. First, we investigate the derandomization of Chernoff-type concentration inequalities. Schmidt et al. (SIAM J. Discrete Math. 1995) showed that a tail bound of delta can be established for sums of Bernoulli random variables with only O(log(1/delta))-wise independence. We show that their results are tight up to constant factors. Secondly, the “polynomial regression” algorithm of Kalai et al. (SIAM J. Comput. 2008) shows that halfspaces can be efficiently learned with respect to log-concave distributions on R^n in the challenging agnostic learning model. The power of this algorithm relies on the fact that under log-concave distributions, halfspaces can be approximated arbitrarily well by low-degree polynomials. In contrast, we exhibit a large class of non-log-concave distributions under which polynomials of any degree cannot approximate the sign function to within arbitrarily low error.',
    'paper_67' => 'In 2013, Courtade and Kumar posed the following problem: Let $x \in \{-1,1\}^n$ be uniformly random, and form $y$ by negating each bit of $x$ independently with probability $\alpha$. Is it true that the mutual information $I(f(x) ; y)$ is maximized among $f : \{-1,1\}^n \to \{-1,1\}$ by $f(x) = x_1$? We do not resolve this problem. Instead, we resolve the analogous problem in the settings of Gaussian space and the sphere. Our proof uses rearrangement.',
    'paper_68' => 'We study maximum coloring of sparse random geometric graphs, in an arbitrary but constant dimension, with a constant number of colors. We show laws of large numbers as well as central limit theorem type results for the maximum number of vertices that can be properly colored. Since this object is neither scale-invariant nor smooth, we design tools that with the main method of sub-additivity allow us to show the weak and strong laws. Additionally, by proving the Lindeberg conditions, we show the normal limiting distribution.',
    'paper_69' => 'In this work, we make major progress towards solving an open problem from [Frieze and McDiarmid, 1997]. They ask whether there exists a fully polynomial time approximation scheme (fpras) for counting k-cliques and k-independent sets in a random graph. We present a fpras for counting cliques and independent sets in random graphs when k = (1+o(1))log n. We note that no efficient algorithm is known to even {\em detect} a clique or an independent set of larger size with non-vanishing probability. Furthermore, [Jerrum, 1992] presents some evidence that one cannot hope to easily improve our results. They show an exponential lower bound on mixing time of the Metropolis process that samples cliques of size larger than $(1+o(1))\log_2{n}$ with high probability. Additionally, we provide an fpras for counting k-clique covers when k is a constant. Using our techniques, we also obtain an alternate derivation of the closed form expression for the $k$-th moment of a binomial random variable using our techniques. The previous derivation [Knoblauch (2008)] was based on the moment generating function of a binomial random variable. ',
    'paper_70' => 'We analyze the component evolution in inhomogeneous random intersection graphs when the average degree is close to 1. As the average degree increases, the size of the largest component in the random intersection graph goes through a phase transition. Our results show a qualita- tive similarity to the phase transition in Erdős-Rényi random graphs; one notable difference is that the magnitude of the jump in the size of the largest component varies depending on the parameters of the random intersection graph. We give a lower bound for the order of magnitude of this largest component and show that it is unique.',
    'paper_71' => 'However, the counterexample provided by the RT-bound is an artificial distribution found in a non-constructive way. Thus, the RT-bound does not disprove the existence of a "nice" class of sources which can be used with particular extractors (for instance with widely used universal hash functions) to reduce the entropy loss. 

  In this paper, motivated in applications related to key derivation, we initiate studying the problem of finding \emph{necessary conditions} for extracting $m$ bits, which are $\epsilon$-close to uniform, from a weak source $X$. The goal is to identify natural properties of a source $X$ (e.g., being flat or efficiently samplable) together with an extractor such that by extracting from $X$ we can beat the $2\log(1/\epsilon)$ entropy loss. To avoid trivial examples (e.g., outputting the first $k$ bits of a source that is uniform on the first $k$ bits), we require that the extractor is at least pairwise independent. 

  As a negative result we show that the goal of designing "nice" sources cannot be achieved for $4$-wise independent hash functions. In this case we give a \emph{complete and tight characterization of all extractable sources}, by showing that any $X$ obeys the "generalized" RT bound with respect to \emph{smooth collision entropy}: the necessarily condition for extracting $m$ bits $\epsilon$-close to uniform is to be $\epsilon\'$-close to a distribution of collision entropy $m+2\log(1/\epsilon)-\mathcal{O}(1)$ where $\epsilon\' = \mathcal{O}(\epsilon)$. By the Leftover Hash Lemma, this condition is also sufficient (up to a constant factor in the statistical distance and an additive constant in the entropy amount). For flat sources we state this bound in terms of min-entropy: the necessary condition for \emph{any} flat $X$ to extract $m$ bits $\epsilon$-close to uniform by $4$-wise independent hashing is that $X$ has min-entropy at least $m+2\log(1/\epsilon)-6$, which shows that the classical RT-bound is tight for any flat distribution. 

  On the positive side we prove that for pairwise independent functions, somewhat surprisingly, one can significantly beat the RT-bound with even efficiently samplable distributions $X$. We construct a family of pairwise independent hash functions from $n$ to 1 bits and a very simple source X with min-entropy $\log(1/\epsilon)$, such that $H(X)$, where $H$ is randomly chosen from the hashing family, is $\epsilon$-close to uniform. 

  We note that our results, besides impossibilities in key derivation, give an elegant characterization of smooth Renyi entropy: a source $X$ is $\epsilon$-close to a distribution of $k$ bits of collision entropy if and only if by $4$-wise independent hashing applied to $X$ one can extract $m$ bits which are $\epsilon\'$-close to uniform with $\epsilon\' = \mathcal{O}\left( \sqrt{2^{m-k}}+\epsilon\right)$. Remarkably, this characterization is true only with $4$-wise, not for pairwise, independent hash functions. 

  Our technique is based on the reduction of studying the deviation of hashed sequences to problems concerning moments of 
  random walks. In particular, we use interpolation inequalities to compare moments of random walks with $p$-wise independent increments, in the same way like in the Khintchine inequalities for independent sums.',
    'paper_72' => 'We study the existence and complexity of pairs of distributions $\mu$ and $\nu$ on $n$ symbols all of whose $k$-symbol projections are identical but can be distinguished by a given boolean function $f$ on $n$ bits. Over the binary alphabet, we observe that this property of functions is closely related to their approximate degree. Using the body of work on the latter, we conclude that bounded indistinguishability behaves differently from bounded independence. We further present two kinds of applications in cryptography. 

  On the one hand, such pairs of distributions yield secret sharing schemes with reconstruction procedure $f$. We apply this connection to obtain new positive results on the complexity of secret sharing. In particular, we obtain the first "visual" secret sharing schemes that scale well with the secrecy threshold, as well as the first nontrivial constructions of secret sharing schemes in which the secret can be shared and reconstructed by $\mathrm{AC}^0$ functions. 

  On the other hand, if no such pair of distributions exists, then the transcripts of secure multiparty protocols that offer security against a bounded number of parties are automatically secure against leakage computed by $f$. We illustrate the usefulness of this connection by applying it to improve the efficiency of private circuits that resist several low-complexity leakage classes, either unconditionally or under natural conjectures. 

  Most of our results follow directly or easily from previous works. Our presentation highlights the role played by bounded indistinguishability in pseudorandomness, complexity of secret sharing, and leakage-resilient cryptography. ',
    'paper_73' => 'Rumor spreading is a basic model for information dissemination in a social network. 
  In this setting a central concern for an entity, say the service provider, is to find ways to speed up the dissemination process and to maximize the overall information spread. In the last decade there have been multiple approaches to deal with this loosely defined problem, including the well known influence maximization problem. A central issue absent in the first model is that of adaptivity. How can the service provider use information about the current state of the network to cost effectively speed up the process? 

  Motivated by the recent emergence of the so-called opportunistic communication networks, we take a novel approach by considering the issue of adaptivity in the most basic continuous time (asynchronous) rumor spreading process. 
  In our setting a rumor has to be spread to a population and the service provider can push it at any time to any node in the network and has unit cost for doing this. On the other hand, as usual in rumor spreading, upon meeting, nodes share the rumor and this imposes no cost on the service provider. 
  Rather than fixing a budget on the number of pushes, we consider the cost version of the problem with a fixed deadline and ask for a minimum cost strategy that spreads the rumor to every node. 
  A non-adaptive strategy can only intervene at the beginning and at the end, while an adaptive strategy has full knowledge and intervention capabilities. 
  Our main result is that in the homogeneous case (where every pair of nodes randomly meet at the same rate) the benefit of adaptivity is bounded by a constant. 
  This requires a subtle analysis of the underlying random process that is of interest in its own right.',
    'paper_74' => 'We study the problem of approximately counting the number of occurrences of small subgraphs of interest within large graphs.
  This problem has applications in many different fields, including the study of biological, internet and database systems.
  In this work, we focus on approximately counting the number of star subgraphs. 
  Inspired by the work of Gonen, Ron and Shavitt [SIAM J. Comput., 25 (2011), pp. 1365-1411], we aim to design sublinear-time algorithms,
  which compute such an approximation without needing to see the entire input.
  In their work, they assume the ability to sample vertices uniformly from the input graph.
  We show how to bypass lower bounds given in their work when one has the ability to sample edges.
  Our algorithm has query and time complexities $\O(m \log \log n\,/\,\epsilon^2 S_p^{1/p})$,
  where $S_p$ is the actual number of stars with $p+1$ vertices in the undirected input graph.
  We also provide lower bounds under our proposed model, which are tight (up to polylogarithmic factors) in almost all cases.

  In addition, we consider the problem of counting the number of directed paths of length two in the generalization of our model to directed graphs. We prove that the general version of this problem cannot be solved in sublinear time. However, when the ratio between the in-degree and the out-degree on every vertex is bounded, we give a sublinear time algorithm via a reduction to the undirected case.',
    'paper_75' => 'In the most popular distribution testing model, one can obtain information about an unknown distribution $\mathcal D$ via independent samples. We consider a model in which every sample comes with an estimate of its probability. In this setting, we give algorithms for testing if two distributions are (approximately) identical and estimating the total variation distance between distributions. The sample complexity of all of our algorithms is optimal up to a constant factor for sufficiently large support size. The running times of our algorithms are near-linear in the number of samples collected. Our algorithms are robust to small multiplicative errors in probability estimates.

  The complexity of our model lies strictly between the complexity of the model with only independent samples and the complexity of the model that allows also for arbitrary probability queries. For instance, we need $O(\max\{\frac{n^{1/2}}{ \eps}, \frac{1}{\eps^2}\})$ samples to estimate the distance between two unknown distributions on a domain of size $n$ up to an additive $\eps$. If only standard samples are available, the sample complexity of the task is known to be $\Omega(n/\log n)$. If also arbitrary probability queries are available, the complexity decreases to $O(1/\eps^2)$.

  Our model finds applications in situations where once a given element is sampled, it is easier to estimate its probability. We describe two scenarios in which all occurrences of each element are easy to discover once at least one copy of the element is detected.',
    'paper_76' => 'Let G=G(n,m) be a random graph whose average degree d=2m/n is below the k-colorability threshold. If we sample a k-coloring X of G uniformly at random, what can we say about the correlations between the colors assigned to vertices that are far apart? According to a prediction from statistical physics, for average degrees below the so-called "condensation threshold", denoted by dc, the colors assigned to far away vertices are asymptotically independent [Krzakala et al.: PNAS 2007]. We prove this conjecture for k exceeding a certain constant k_0. More generally, we determine the joint distribution of the k-colorings that X induces locally on the bounded-depth neighborhoods of a fixed number of vertices.',
    'paper_77' => 'AC^0(MOD_2) circuits are AC^0 circuits augmented with a layer of parity gates 
  just above the input layer. We study AC^0(MOD_2) circuit lower bounds for computing the Boolean Inner Product functions. Recent works by Servedio and Viola (ECCC TR12-144) and Akavia et al.~(ITCS 2014) have highlighted this problem as a frontier problem in circuit complexity that arose both as a first step towards solving natural special cases of the matrix rigidity problem and as a candidate for constructing pseudorandom generators of minimal complexity. We give the first superlinear lower bound for the Boolean Inner Product function against AC^0(MOD_2) of depth four or greater. Specifically, we prove a superlinear lower bound for circuits of arbitrary constant depth, and an $\tilde{\Omega}(n^2)$ lower bound for the special case of depth-4 AC^0(MOD_2). Our proof of the depth-4 lower bound employs a new "moment-matching" inequality for bounded, nonnegative integer-valued random variables that may be of independent interest: we prove an optimal bound on the maximum difference between two discrete distributions\' values at $0$, given that their first $d$ moments match.',
    'paper_78' => 'For Boolean functions computed by read-once, depth-$D$ circuits with unbounded fan-in over the de Morgan basis, we present an explicit pseudorandom generator with seed length $\tilde{O}(\log^{D+1} n)$. The previous best seed length known for this model was $\tilde{O}(\log^{D+4} n)$, obtained by Trevisan and Xue (CCC `13) for all of $\AC^0$ (not just read-once). Our work makes use of Fourier analytic techniques for pseudorandomness introduced by Reingold, Steinke, and Vadhan (RANDOM `13) to show that the generator of Gopalan et al. (FOCS `12) fools read-once $\AC^0$. To this end, we prove a new Fourier growth bound for read-once circuits, namely that for every $F: \{0,1\}^n\to\{0,1\}$ computed by a read-once, depth-$D$ circuit, \begin{equation*}\sum_{s\subseteq[n], |s|=k}|\hat{F}[s]|\le O(\log^{D-1}n)^k,\end{equation*} where $\hat{F}$ denotes the Fourier transform of $F$ over $\mathds{Z}^n_2$.',
    'paper_79' => 'A $k$-complex contagion starts from a set of initially infected seeds and any node with at least $k$ infected neighbors becomes infected. While simple contagions (i.e., $k=1$) can quickly spread to the entire network in small world graphs, fast spreading of complex contagions appears to be less likely and more delicate; the successful cases depend crucially on the network structure~\cite{G08,Ghasemiesfeh:2013:CCW,Ebrahimi:2015:CCK}. 

  We show that complex contagions can spread fast in a general family of time-evolving networks which includes the preferential attachment model. 
  We prove that if the initial seeds are chosen as the $k$ oldest nodes in a network of this family, a $k$-complex contagion covers the entire network of $n$ nodes in $O(\log n)$ steps. We also show that the choice of the initial seeds is crucial: in the preferential attachment model, even if a much larger number of initial seeds are uniformly randomly chosen (polynomially large as compared to the previous constant-size initial set), a $k$-complex contagion will stop prematurely. 
  Although the oldest nodes in a preferential attachment model are likely to have high degrees, it is actually the evolutionary graph structure of such models that facilitates fast spreading of complex contagions. The general family of evolving graphs with this property even contains networks without a power law degree distribution. 

  Using similar techniques, we also prove that complex contagions are fast in the copy model~\cite{KumarRaRa00}, a variant of the preferential attachment family, if the initial seeds are chosen as the oldest nodes. 

  Finally, we prove that when a $k$-complex contagion starts from an arbitrary set of initial seeds on a general graph, determining if the number of infected vertices is above a given threshold is $P$-complete. Thus, one cannot hope to categorize all the settings in which complex contagions percolate in a graph.',
    'paper_80' => 'In this paper, we show that Clarkson’s sampling algorithm can be applied to two separate problems in computational algebra: solving large-scale polynomial systems, for which we utilize a Helly-type result for algebraic varieties, and finding small generating sets of graded ideals. The cornerstone of our work is showing that the theory of violator spaces of G\"artner et al. applies to these polynomial ideal problems. The resulting algorithms have expected runtime linear in the number of input polynomials​.',
    'paper_81' => 'We initiate a systematic study of local testing for membership in lattices. Apart from a complexity theory interest, testing membership in lattices is of practical relevance with applications to integer programming and error detection of communication codes based on lattice constructions. In this work, we take the first steps towards understanding local testing of lattices, complementing and
  building upon the extensive body of work on locally testable codes. In particular, we formally define the notion of local tests for lattices and show the following.

  1. A generic construction of one-sided, non-adaptive, and linear testers based on any two-sided, adaptive, and possibly nonlinear tester, akin to and based on an analogous result for error correction codes by Ben-Sasson, Harsha and Raskhodnikova (SIAM J. Computing 35(1) pp. 1--21).

  2. We consider a widely used construction of lattices from error-correcting codes, known as code formula lattices (Forney, IEEE Transactions on Information Theory 34(5) pp. 1152--1187) that generalizes Barnes-Wall Lattices. We prove almost matching lower and upper bounds for testing lattices arising from this construction. We then instantiate the result to the specific towers based on Reed-Muller codes, which are widely used in practice, and derive nearly matching lower and upper bounds for local testing of this family of lattices.

  We believe that this work raises many open questions regarding local models for lattices that merit further study.',
    'paper_82' => 'Significant progress has been made recently in the understanding of random constraint satisfaction problems such as random $k$-SAT.
  Most progress, however, has been restricted to large values of $k$ and there is still considerable interest in the smallest values of $k$. To illustrate the power of the interpolation method from statistical physics we derive improved upper bounds for 3-SAT and 4-SAT with the aid of a computer assisted proof. This approach is amenable to a range of random constraint satisfaction problems.',
    'paper_83' => 'We introduce the notion of {\em one way communication schemes under partial noiseless feedback}. In this setting, Alice wishes to communicate a message to Bob by using a communication scheme that involves sending a sequence of bits over a channel while receiving feedback bits from Bob for $\delta$ fraction of the transmissions. An adversary is allowed to corrupt up to a constant fraction of Alice\'s transmissions, while the feedback is always uncorrupted. Motivated by questions relating to coding for interactive communication, we seek to determine the maximum error rate, as a function of $0\leq \delta\leq 1$, such that Alice can send a message to Bob via some protocol with $\delta$ fraction of noiseless feedback. The case $\delta = 1$ corresponds to {\em full feedback}, in which the result of [Berlekamp \'64] implies that the maximum tolerable error rate is $1/3$, while the case $\delta = 0$ corresponds to {\em no feedback}, in which the maximum tolerable error rate is $1/4$, achievable by use of a binary error-correcting code.

  In this work, we show that for any $0 < \delta \leq 1$, $0\leq\gamma < 1/3$, there exists a {\em randomized} encoding scheme that allows one-way communication with partial noiseless feedback such that the probability of miscommunication is low, as long as no more than an $\gamma$ fraction of the rounds are corrupted. Moreover, we show that for any $0 < \delta \leq 1$ and $\gamma < f(\delta)$, there is an explicit {\em deterministic} encoding scheme that solves the problem of one-way communication with partial noiseless feedback and tolerates an error fraction of up to $\gamma$, where $f$ is a monotonically increasing, piecewise linear, continuous function with $f(0) = 1/4$ and $f(1) = 1/3$. Also, the rate of communication in both instances is constant (dependent on $\delta$ and $\gamma$ but independent of the input length).',
    }

end
