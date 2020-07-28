require 'csv'


namespace :customizations do 
  task :generate_lists, [:fpath] => :environment do |t, args|

    # edit this before running if necessary: 

    list_defaults = {
      # list_show_new_button: true,
      # hide_category_for_new: true,
      # list_is_archived: false,
      # list_opinions_title: 'Opinions',
      # slider_pole_labels: slider_labels.important_unimportant,
      # list_label_style: {}, 
      # list_items_title: '',
      # list_no_filters: false,
      # list_uncollapseable,
      # list_label_style
    }

    file_path = args[:fpath] || 'lib/tasks/client_data/lists.csv'

    data = CSV.parse(File.read(file_path), headers: true)

    sections = {}

    lists = []




    out = File.open('lib/tasks/client_data/customizations.txt', 'w')

    data.each do |row|
      name = row['name']
      header = row['header'] || name
      desc = row['description']

      show_new = row['community can add to list']
      starts_closed = row['starts closed']

      list = {}
      list_defaults.each do |k,v|
        list[k] = v
      end

      list[:list_label] = header

      if desc 
        list[:list_description] = desc 
      end

      if show_new
        if show_new.downcase == 'no' || show_new.downcase == 'false'
          list[:list_show_new_button] = false 
        else 
          list[:list_show_new_button] = true 
        end 
      end 

      if starts_closed
        list[:list_is_archived] = true 
      end


      out.puts "  \"list/#{name}\":\n"
      list.each do |k,v|
        # if false && v.is_a? String
        #   out.puts "    #{k}: \"#{JSON.dump(v)}\"\n"
        # else 
        out.puts "    #{JSON.dump(k)}: #{JSON.dump(v)}\n"
        # end
      end

      out.puts "\n"


      section = row['section']
      if section 
        if !sections.has_key? section 
          sections[section] = []
        end
        sections[section].push name 
      end 
    end


    out.puts "  \"homepage_tabs\": \n"
    sections.each do |name, section|
      out.puts "    #{JSON.dump(name)}: #{JSON.dump(section)}\n"
    end 

    out.close

  end
end