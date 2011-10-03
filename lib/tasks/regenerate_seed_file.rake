require 'csv'
require 'pp'

namespace :admin do
  desc "Regenerates the LVG2 seed file"
  task :regen_seeds => :environment do

    domains = {}
    CSV.foreach("lib/tasks/measures.csv") do |row|
        if row[0] != 'Source'
            domain = row[11].strip
            if !domains.has_key?(domain)
                domains[domain] = {
                    :measures => [],
                    :zips => []
                }
            end

            domains[domain][:measures].push({
                :id => row[1],          #ID
                :short_name => row[2],  #name
                :domain => domain,      #jurisdiction
                :category => row[4],    #type
                :designator => row[5],  #number
                :name => row[6],        #title
                :description => row[7], #description
                :long_description => row[8], #explanatory statement
                :additional_details => row[9], #fiscal impact statement
                :url => row[10],         #URL
                :domain_lookup => row[11], #jurisdiction lookup
                :domain_short => row[3].strip
            })

        end
    end

    zip_to_jurisdiction_map = {}
    CSV.foreach("lib/tasks/zip-jurisdiction.csv") do |row|
        if row[0] != 'Zip'
            domains[row[1].strip][:zips].push(row[0].strip)
        end
    end

    seedf = File.new('db/seeds.lvg2.root.rb', "w")

    zips = {}
    CSV.foreach("lib/tasks/zips.csv") do |row|
        if row[0] != ''
            zips[row[0]] = 1
            seedf.puts "
z#{row[0]} = Domain.create!(
  :identifier => #{row[0]},
  :name => '#{row[2].capitalize}'
)".force_encoding('utf-8').encode

        end
    end

    cnt = 0
    zip_cnt = 0
    domains.each_pair do |k,v|
        v[:measures].each do |measure|
            seedf.puts "
o#{cnt} = Option.create!(
  :name => '#{measure[:name]}',
  :short_name => '#{measure[:short_name]}',
  :description => '#{measure[:description].sub("'", "\\\'")}',
  :domain => '#{measure[:domain]}',
  :domain_short => '#{measure[:domain_short]}',
  :url => '#{measure[:url]}',
  :category => '#{measure[:category]}',
  :designator => '#{measure[:designator]}',
  :long_description => '#{measure[:long_description]}',
  :additional_details => '#{measure[:additional_details]}'
)".force_encoding('utf-8').encode
            zips_added = {}
            v[:zips].each do |zip|
                if zips.has_key?(zip) && !zips_added.has_key?(zip)
                    seedf.puts "
    z#{zip_cnt} = DomainMap.create!(
      :domain => z#{zip},
      :option => o#{cnt}
    )".force_encoding('utf-8').encode
                    zip_cnt += 1
                    zips_added[zip] = 1
                end
            end
        cnt += 1
        end

    end


  end

end