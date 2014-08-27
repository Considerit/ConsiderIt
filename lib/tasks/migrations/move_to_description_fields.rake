require 'json'

task :move_to_description_fields => :environment do 
  def convertProposalDescription(account, fields, urls = nil)

    account.proposals.each do |proposal|
      description_fields = []

      for fld in fields
        if proposal[fld[0]] && proposal[fld[0]].length > 0
          description_fields.append({
                    :label => fld[1],
                    :html => proposal[fld[0]]
                  })
        end
      end

      if urls
        html = "<ul>"
        for url in urls
          pp url[0], proposal[url[0]]
          if proposal[url[0]] && proposal[url[0]].length > 0
            pp 'GOT URL!!'
            html += "<li><a href='#{proposal[url[0]]}' target='_blank'>#{url[1]}</a></li>"
          end
        end
        html += "</ul>"

        if html != "<ul></ul>"
          pp html
          description_fields.append( {
                    :label => "Links",
                    :html => html
                  })
        end
      end
      # pp description_fields
      # pp description_fields.to_json
      proposal.description_fields = description_fields.to_json
      proposal.save
    end
  end

  def copyProposalDescription(account)
    account.proposals.each do |proposal|
      proposal.description_fields = proposal.additional_description1
      proposal.save
    end
  end

  convertProposalDescription Account.find_by_identifier('livingvotersguide'), [
    [:additional_description1, 'Long Description'],
    [:additional_description2, 'Fiscal Impact Statement'],
    [:additional_description3, 'Resources curated by Seattle Public Library']], 
    [ [:url1, 'Full text'], [:url2, 'Responsible Choices Analysis'], [:url3, 'Funding Sources']]

  begin
    convertProposalDescription Account.find_by_identifier('tigard'), [
      [:additional_description1, 'More information']
    ]
  rescue
    pp "Couldn't convert tigard proposals"
  end

  begin
    copyProposalDescription Account.find_by_identifier('cityoftigard')
  rescue
    pp "couldn't convert city of tigard proposals"
  end

end
