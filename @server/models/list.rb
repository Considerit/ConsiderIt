

class List


  def self.list_lists(subdomain=nil)
    subdomain ||= current_subdomain

    all_lists = []

    if subdomain.customizations && subdomain.customizations.has_key?("homepage_tabs") && subdomain.customizations["homepage_tabs"].length > 0
      tabs = subdomain.customizations["homepage_tabs"]

      # Hack to fix a bug I haven't found where a tab can have a null name
      idx = tabs.length - 1
      while idx >= 0
        if tabs[idx]["name"].nil?
          tabs.delete_at(idx)
        end
        idx -= 1
      end

      tabs
    else
      tabs = nil
    end

    # Give primacy to specified order of lists in tab config or ordered_list customization

    if tabs
      tabs.each do |tab|
        all_lists.concat(tab["lists"].select { |l| l != '*' && l != '*-' })
      end
    elsif subdomain.customizations.has_key?('lists')
      all_lists = subdomain.customizations['lists'].select { |l| l != '*' && l != '*-' }
    end

    # Lists might also just be defined as a customization, without any proposals in them yet
    subdomain.customizations.each do |k, v|
      all_lists.push(k) if k.match(/list\//)
    end


    clusters = ActiveRecord::Base.connection.execute """\
      SELECT DISTINCT(cluster)
          FROM proposals 
          WHERE subdomain_id=#{subdomain.id};
      """

    clusters.each do |row|
      clust = row[0] || 'Proposals'
      all_lists.push "list/#{clust.strip}"
    end

    all_lists = all_lists.uniq



    # # Give primacy to specified order of lists in tab config or ordered_list customization
    # subdomain = fetch('/subdomain')
    # if get_tabs()
    #   for tab in get_tabs()
    #     all_lists = all_lists.concat (l for l in tab.lists when l != '*' && l != '*-')
    # else if customization 'lists'
    #   all_lists = (l for l in customization('lists') when l != '*' && l != '*-')

    # # lists might also just be defined as a customization, without any proposals in them yet
    # subdomain_name = subdomain.name?.toLowerCase()
    # config = customizations[subdomain_name]
    # for k,v of config 
    #   if k.match( /list\// )
    #     all_lists.push k

    # proposals = fetch '/proposals'
    # if proposals.proposals
    #   all_lists = all_lists.concat("list/#{(p.cluster or 'Proposals').trim()}" for p in proposals.proposals)

    # all_lists = _.uniq all_lists

    all_lists 

  end

  def self.all_data(key)
    proposals = Proposal.summaries[:proposals]
    cluster = key.split('/')[-1]

    resp = {
      key: key,
      proposals: proposals.select {|proposal| (proposal["cluster"] || 'Proposals') == cluster }
    }
    resp 
  end



end





