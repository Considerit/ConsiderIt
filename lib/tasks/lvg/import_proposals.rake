require 'csv'
require 'pp'

namespace :lvg do

  task :add_zips_for_proposals => :environment do 

    jurisdiction_to_proposals = {}

    CSV.foreach("lib/tasks/lvg/measures.csv", :headers => true) do |row|
      proposal = Proposal.find_by_long_id(row['long_id'])
      if !proposal
        throw 'Could not find proposal'
      end
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if jurisdiction == 'Statewide'
        proposal.add_tag 'type:statewide'
        proposal.add_tag "jurisdiction:State of Washington"
        proposal.save
        next
      end

      if !(jurisdiction_to_proposals.has_key?(jurisdiction))
        jurisdiction_to_proposals[jurisdiction] = []
      end

      jurisdiction_to_proposals[jurisdiction].push proposal
    end

    jurisdiction_to_zips = {}
    CSV.foreach("lib/tasks/lvg/jurisdictions.csv", :headers => true) do |row|
      jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        jurisdiction_to_zips[jurisdiction] = []
      end
      jurisdiction_to_zips[jurisdiction].push row['zip']
    end

    jurisdiction_to_proposals.each do |jurisdiction, proposals|
      jurisdiction = jurisdiction.split.map(&:capitalize).join(' ')
      zips = jurisdiction_to_zips[jurisdiction]
      if !jurisdiction_to_zips.has_key?(jurisdiction)
        pp "ERROR: jurisdiction #{jurisdiction} not found!...skipping"
        next
      end
      pp "For #{jurisdiction}, adding #{zips.length} zips to #{proposals.length} measures"

      # tags = zips.map{|z|"zip:#{z}"}.join(';')

      proposals.each do |p|
        p.add_tag "type:local"
        p.add_tag "jurisdiction:#{jurisdiction}"

        zips.each do |zip|
          p.targettable = true
          p.add_tag "zip:#{zip}"
          p.save
        end
      end

    end



  end

  task :import_proposals => :environment do
    domains = {}
    measures = []

    CSV.foreach("lib/tasks/lvg/measures.csv", :headers => true) do |row|

      measure = {
        :account_id => 1, #TODO: remove, when moved into admin panel
        :user_id => 1, #TODO: make configurable
        :long_id => row['long_id'],
        :name => row['name'],
        :category => row['category'],
        :designator => row['designator'],
        :description => row['description'].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''),
        :published => true, #TODO: make configurable

        :additional_description1 => row.fetch('additional_description1', nil),
        :additional_description2 => row.fetch('additional_description2', nil),
        :additional_description3 => row.fetch('additional_description3', nil),
        :url1 => row.fetch('url1', nil),
        :url2 => row.fetch('url2', nil),
        :url3 => row.fetch('url3', nil),
        :url4 => row.fetch('url4', nil)
      }

      proposal = Proposal.find_by_long_id measure[:long_id]
      if !proposal
        proposal = Proposal.new measure
        proposal.save
        pp "Added #{row['name']}"
      else
        measure.delete :account_id
        proposal.update_attributes measure
        pp "Updated #{row['name']}"        
      end

    end


  end
end

