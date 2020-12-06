require 'csv'
require 'json'

require Rails.root.join("lib/services/google_sheet")


namespace :customizations do 
  task :generate_lists, [:fpath] => :environment do |t, args|

    # edit this before running if necessary: 

    list_defaults = {
      # list_permit_new_items: true,
      # hide_category_for_new: true,
      # list_is_archived: false,
      # list_opinions_title: 'Opinions',
      # slider_pole_labels: slider_labels.important_unimportant,
      # list_title_style: {}, 
      # list_items_title: '',
      # list_no_filters: false,
      # list_uncollapseable,
    }

    file_path = args[:fpath] || 'lib/tasks/client_data/lists.csv'


    if file_path.index('google.com')
      sheet_id = /\/d\/(.+?)\//.match(file_path)[1]
      sheet = Services::GoogleSheet.new
      sheets = sheet.getSheets(sheet_id)

      structure_sheet = sheets[1]
      sheets.each do |sh|
        if sh.index('structure')
          structure_sheet = sh
        end
      end

      data = []
      headers = nil      
      sheet.getData(sheet_id, structure_sheet).values.each_with_index do |row, idx|
        if idx == 0 
          headers = row
        else
          vals = {}
          row.each_with_index do |cell, col|
            if cell && cell.length > 0 
              vals[headers[col]] = cell
            end
          end
          data.push vals
        end 

      end 
    else 
      data = CSV.parse(File.read(file_path), headers: true)
    end

    sections = {}

    lists = []

    config = {}


    out = File.open('lib/tasks/client_data/customizations.txt', 'w')

    data.each do |row|
      name = row['name']
      desc = row['description']
      header = row['title'] || row['header']
      if desc && !header 
        header = name
      end

      show_new = row['community can add to list']
      starts_closed = row['starts closed']

      slider = row['slider']

      list = {}
      list_defaults.each do |k,v|
        list[k] = v
      end

      list[:key] = "list/#{name}"

      if header 
        list[:list_title] = header
      else 
        list[:list_category] = name
      end

      if desc 
        list[:list_description] = desc 
      end

      if show_new
        if show_new.downcase == 'no' || show_new.downcase == 'false'
          list[:list_permit_new_items] = false 
        else 
          list[:list_permit_new_items] = true 
        end 
      end 

      if starts_closed && !(starts_closed.downcase == 'no' || starts_closed.downcase == 'false')
        list[:list_is_archived] = true 
      end

      if slider
        sldr =  case slider 
        when 'concern'
          {
            support: 'Most Concerning',
            oppose: 'Least Concerning'
          }
        when 'importance'
          {
            support: 'Most Important',
            oppose: 'Least Important'
          }

        when 'effectiveness'
          {
            support: 'Most Effective',
            oppose: 'Least Effective'
          }
        when 'priority'
          {
            support: 'High Priority',
            oppose: 'Low Priority'
          }

        else 
          nil 
        end 
        if sldr 
          list[:slider_pole_labels] = sldr 
        end




      end 


      out.puts "  \"list/#{name}\": {\n"
      list.each do |k,v|
        # if false && v.is_a? String
        #   out.puts "    #{k}: \"#{JSON.dump(v)}\"\n"
        # else 
        out.puts "    #{JSON.dump(k)}: #{JSON.dump(v)},\n"
        # end
      end

      # out.puts "  }\n"

      config["list/#{name}"] = list 

      section = row['section']
      if section 
        if !sections.has_key? section 
          sections[section] = []
        end
        sections[section].push "list/#{name}"
      end 
    end

    config["homepage_tabs"] = {}

    # out.puts "  \"homepage_tabs\": { \n"
    sections.each do |name, section|
      config["homepage_tabs"][name] = section
    end 

    # out.puts "  }"

    out.puts JSON.pretty_generate(config)
    out.close

    puts JSON.pretty_generate(config)

  end
end