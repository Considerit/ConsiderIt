# encoding: UTF-8

require 'pp'

namespace :encodings do
  desc ""  
  task :hawaii => :environment do  
    Subdomain.where(:name => 'oha').each do |a|
      a.pro_label = "Kakoʻo"
      a.con_label = "Kūʻē"
      a.slider_prompt = "He aha kao mana‘o?"
      a.statement_prompt = "Any final mana‘o?"
      a.slider_left = "Kako‘o"
      a.slider_right = "Kū‘ē"
      a.save
    end
  end
end

