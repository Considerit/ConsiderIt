task :compute_metrics => :environment do 
  begin
    Point.update_scores()
    Rails.logger.info "Updated point scores"
  rescue
    Rails.logger.info "Could not update point scores"
  end 
end

# For a weird bug we can't figure out that leaves an 
# inclusion without an associated point. 
# Remove this after we have a decent caching method for inclusions
task :clear_null_inclusions => :environment do
  Inclusion.where(:point_id => nil).destroy_all
end

task :dao_org => :environment do 

  subdomain = Subdomain.find_by_name 'dao'

  category_map = {
    'Incomplete' => 'Proposals',
    'Needs more description' => 'Proposals',
    'Incubator' => 'Proposals',
    'investment' => 'Proposals',
    'Mature' => 'Developmental',
    'Under review' => 'Under development',

  }

  category_map.each do |k,v|
    subdomain.proposals.where(:cluster => k).update_all(:cluster => v)
    puts "Mapped #{k} to #{v}"
  end


  slugs = {
    'Meta' => ['extending-proposal-vote-deadlines', 'expansion-upon-daoconsiderit-to-where-suggestionsideasproposals-graduate-to-higher-levels-process-of-collective-consideration'],
    'Proposals' => ['adding-a-decentralized-cloud-brother-of-ethereum-blockchain-to-make-it-the-futur-1st-world-web-hosting-cie', 'found-or-buy-law-firms-in-major-economic-countries', 'invest-in-real-estate', 'by_klm', 'daollery-we-are-open-an-art-gallery-and-collectively-choose-pieces-of-artwork-to-display-for-each-show'],
    'Needs more description' => ['smart-contracts-for-world-trade-per-incoterms'],
    'DAO 2.0 Wishlist' => ['create-an-upgrade-protocol-for-thedao-code-and-funds-into-thedao-v20-and-beyond-in-order-to-adapt-to-urgent-attacks-known-weaknesses-or-new-features']
  }

  slugs.each do |category, proposals|
    puts "Mapping to #{category}:"
    proposals.each do |slug|
      prop = subdomain.proposals.find_by_slug slug 
      prop.cluster = category 
      prop.save

      puts "\t#{slug}"
      
    end
  end 

end