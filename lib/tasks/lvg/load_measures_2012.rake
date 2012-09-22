#!/bin/env ruby
# encoding: utf-8

require 'csv'
require 'pp'
require 'iconv'

namespace :admin do
  task :create_sensible_seo_long_ids => :environment do
    #they need to be 10 chars ...
    # CALI: "cal_prop_30"
    Proposal.all.each do |prop|
        if prop.account_id == 1
            des = prop.designator.gsub(' ', '_')

            case prop.designator.length

                when 1
                    prop.long_id = "advisory_#{des}"
                when 2
                    prop.long_id = "measure_#{des}"
                when 3
                    prop.long_id = "measure#{des}"
                when 4
                    prop.long_id = "wash__#{des}"
                when 5
                    prop.long_id = "wash_#{des}"
                when 6
                    prop.long_id = "wash#{des}"
                when 7
                    prop.long_id = "wa_#{des}"
            end
            i = 0
            while Proposal.where("id!=#{prop.id} AND long_id='#{prop.long_id}'").count > 0 && i < 10
                case prop.designator.length
                    when 5
                        case i
                        when 0
                            prop.long_id = "prop_#{des}"
                        when 1
                            prop.long_id = "init_#{des}"
                        end
                end
                i += 1
            end
            
        else
            prop.long_id = "ca_prop_#{prop.designator}"
        end
        prop.save
        pp prop
    end

  end
  task :tag_and_deactivate_old_measures => :environment do
    Proposal.all.each do |prop|
        if prop.id > 323
            prop.tag_list = '2012'
        else
            prop.active = false
            prop.tag_list = prop.id > 125 ? '2010' : '2011'
        end
        prop.save
        pp prop
    end
  end

  desc "Loads LVG data for 2012"
  task :load_measures => :environment do
    contents = File.read("lib/tasks/lvg/measures2012_state.csv")
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    valid_contents = ic.iconv(contents)
    measures = []
    CSV.parse(valid_contents) do |row|
      if row[0] != 'account_id'
        #TODO: once we also have local measures, we'll need to add jurisdiction to this key lookup
        proposal = Proposal.where(:account_id => row[0], :designator => row[2]).first
        attrs = {
            :category => row[3],
            :short_name => row[4],
            :name => row[5],
            :description => row[6],
            :long_description => row[7],
            :additional_details => row[8],
            :url => row[9]
          }

        if proposal.nil?
          pp "Creating #{row[3]} #{row[2]}"
          attrs.merge!({
            :account_id => row[0],
            :designator => row[2],
            :user_id => 1,
            :active => 1,
            :tag_list => '2012'
          })
          proposal = Proposal.create(attrs)
          proposal.save

        else
          pp "Updating #{row[3]} #{row[2]}"
          proposal.update_attributes!(attrs)
        end
      end
    end
  end

  task :sanitize_measure_html do 
      measure = 1185
      f = File.new("lib/tasks/lvg/measures/#{measure}.html")

      html = f.read

      html = html.gsub('&nbsp;', '')

      to_replace = { "\u00B7" => '&#8226;', "\u201c" => '&ldquo;', "\u201d" => '&rdquo;', "\u2013" => '&ndash;', "\u2014" => '&mdash;', "\u2018" => '&lsquo;', "\u2019" => '&rsquo;', '<span><span>&#8226;<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </span></span></span><span>' => '&nbsp;&#8226;&nbsp;'}

      to_remove = [ '<span><o:p>&nbsp;</o:p></span>', '<o:p></o:p>', "\u00E2", '<?xml:namespace prefix = o ns = "urn:schemas-microsoft-com:office:office" />','<p> </p>', '<p></p>', '\n']

      to_replace.each do |k,v|
        pp html.index(k)
        html = html.gsub(k,v)
        pp html.index(k)
      end
      to_remove.each do |r|
        pp html.index(r)
        html = html.gsub(r,'')
        pp html.index(r)
      end
      doc = Hpricot(html)

      searches_to_remove = ['font', 'img', 'script', '#StatementForAgainst']
      searches_to_remove.each do |s|
        doc.search(s).remove
      end


      attrs = ['class', 'id', 'onclick', 'style', 'face', 'href', 'src']
      attrs.each do |att|
        doc.search("[@#{att}]").each do |e|
          e.remove_attribute(att)
        end
      end



      html = doc.to_html

      #html = Sanitize.clean(html, Sanitize::Config::RELAXED)

      File.open("lib/tasks/lvg/measures/#{measure}.clean.html", 'w+') {|f| f.write(html)}
  end

end