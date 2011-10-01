# create_table "options", :force => true do |t|
#   t.string   "designator"
#   t.string   "category"
#   t.string   "name"
#   t.string   "short_name"
#   t.text     "description"
#   t.string   "image"
#   t.string   "url"
#   t.datetime "created_at"
#   t.datetime "updated_at"
#   t.string   "domain"
#   t.string   "domain_short"
# end


require 'csv'
require 'pp'

namespace :admin do
  desc "Regenerates the LVG2 seed file"
  task :regen_seeds => :environment do

    domains = {}
    CSV.foreach("lib/tasks/measures.csv") do |row|
        if row[0] != 'Source'
            domain = row[3].strip
            if !domains.has_key?(domain)
                domains[domain] = {
                    :measures => [],
                    :zips => []
                }
            end

            if domain.downcase.include? 'county'
                domain_short = 'county'
            elsif domain.downcase.include? 'city'
                domain_short = 'city'
            elsif domain.downcase.include? 'state'
                domain_short = 'state'
            elsif domain.downcase.include? 'town'
                domain_short = 'town'
            elsif domain.downcase.include? 'port'
                domain_short = 'port'
            elsif domain.downcase.include? 'district'
                domain_short = 'district'
            end                

            domains[domain][:measures].push({
                :id => row[1],          #ID
                :short_name => row[2],  #name
                :domain => domain,      #jurisdiction
                :category => row[4],    #type
                :designator => row[5],  #number
                :name => row[6],        #title
                :description => row[7], #description
                :url => row[8],         #URL
                :domain_short => domain_short
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
    cnt = 0
    zip_cnt = 0
    domains.each_pair do |k,v|
        pp k
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
  :designator => '#{measure[:designator]}'
)".force_encoding('utf-8').encode
            v[:zips].each do |zip|
                seedf.puts "
z#{zip_cnt} = DomainMap.create!(
  :identifier => #{zip},
  :option => o#{cnt}
)".force_encoding('utf-8').encode
                zip_cnt += 1
            end
        cnt += 1
        end

    end


  end

end