SitemapGenerator::Sitemap.sitemaps_host = "http:consider.it"

Account.find_each do |accnt|

  indexability = APP_CONFIG[:indexability]
  indexed = indexability.has_key?(accnt.identifier.intern) ? indexability[accnt.identifier.intern] : indexability[:default]  
  next if !indexed

  subdomain = accnt.identifier  
  # Set the host name for URL creation
  SitemapGenerator::Sitemap.default_host = "https://#{accnt.host}"

  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{subdomain}"

  SitemapGenerator::Sitemap.create do
    # Put links creation logic here.
    #
    # The root path '/' and sitemap index file are added automatically for you.
    # Links are added to the Sitemap in the order they are specified.
    #
    # Usage: add(path, options={})
    #        (default options are used if you don't specify)
    #
    # Defaults: :priority => 0.5, :changefreq => 'weekly',
    #           :lastmod => Time.now, :host => default_host
    #
    accnt.proposals.active.open_to_public.each do |prop|
      begin
        add proposal_path(prop.long_id), {:priority => 1.0, :changefreq => 'daily'}
      rescue
        pp "#{prop.long_id} failed"
      end
    end

    accnt.proposals.inactive.open_to_public.each do |prop|
      begin
        add proposal_path(prop.long_id), {:priority => 0.2, :changefreq => 'monthly'}
        #add proposal_path(prop.long_id), {:priority => 0.7, :changefreq => 'weekly'}
      rescue
        pp "#{prop.long_id} failed"
      end
    end

  end
  #SitemapGenerator::Sitemap.ping_search_engines

end