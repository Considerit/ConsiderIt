class Subdomain < ApplicationRecord
  belongs_to :user, :foreign_key => 'created_by', :class_name => 'User'
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :moderations, :dependent => :destroy

  has_many :visits, class_name: 'Ahoy::Visit', :dependent => :destroy  
  has_many :events, class_name: 'Ahoy::Event', :dependent => :destroy  

  has_many :logs

  has_attached_file :logo, :processors => [:thumbnail]
  has_attached_file :masthead, :processors => [:thumbnail]

  validates_attachment_content_type :masthead, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"
  validates_attachment_content_type :logo, :content_type => ["image/jpg", "image/jpeg", "image/pjpeg", "image/png","image/x-png", "image/gif", "image/webp"], message: "Only jpeg, png, gif, and webp images types are allowed"

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :lang, :name, :created_at, :about_page_url, :external_project_url, :moderation_policy, :plan, :SSO_domain, :custom_url]

  scope :public_fields, -> { select(self.my_public_fields) }

  def users(registered=true)
    qry = User
    if registered
      qry = qry.where(registered: true)
    end

    qry.where("active_in like '%\"#{self.id}\"%'")
  end

  def as_json(options={})
    options[:only] ||= Subdomain.my_public_fields
    json = super(options)
    json['key'] = !options[:include_id] ? '/subdomain' : "/subdomain/#{self.id}"
    if current_user.is_admin?
      json['roles'] = self.user_roles
      json['invitations'] = nil

      # for anonymous forums, we go back to just email addresses 
      # for access control, lest we leak information about who 
      # is actually participating, vs just invited to. 
      if self.customizations['anonymize_everything']
        json['roles'].each do |role, users|

          json['roles'][role] = json['roles'][role].map{|email_or_key|
            begin
              email_or_key.match("/user/") ? User.find(key_id(email_or_key)).email : email_or_key
            rescue
              email_or_key
            end
          }
        end
      end

    else
      json['roles'] = self.user_roles(filter = true)

    end


    if current_user.super_admin
      shared = File.read("@client/customizations_helpers.coffee")
      json['shared_code'] = shared
    end

    json['host'] = considerit_host
    json['customizations'] = self.customization_json
    json
  end

  def url
    self.custom_url || considerit_host
  end

  def considerit_host
    if APP_CONFIG[:product_page] == self.name
      "#{APP_CONFIG[:domain]}"
    else 
      "#{self.name}.#{APP_CONFIG[:domain]}"
    end
  end


  def import_configuration(copy_from_subdomain)
    customizations = copy_from_subdomain.customizations.clone
    if customizations.has_key?('user_tags')
      if self.plan == 0 || self.plan == nil
        customizations.delete 'user_tags'
        if customizations.has_key?('host_questions_framing')
          customizations.delete('host_questions_framing')
        end
      else 
        # don't reuse tags between forums because it can create incoherent data
        # when one forum changes the options and/or labels
        customizations['user_tags'] = customizations['user_tags'].clone
        customizations['user_tags'].each do |tag|
          if tag['key'].start_with?("#{copy_from_subdomain.name}-")
            tag['key'] = tag['key'].sub "#{copy_from_subdomain.name}-", "#{self.name}-"
          end
        end
      end
    end

    self.customizations = customizations
    self.roles = copy_from_subdomain.roles
    self.masthead = copy_from_subdomain.masthead
    self.logo = copy_from_subdomain.logo
    self.lang = copy_from_subdomain.lang
    self.SSO_domain = copy_from_subdomain.SSO_domain
    self.moderation_policy = copy_from_subdomain.moderation_policy
    self.save
  end

  def rename(new_name)
    existing = Subdomain.where(:name => new_name).first
    if existing
      raise "Sorry, #{new_name}.#{APP_CONFIG[:domain]} is already taken"
    end

    self.name = new_name
    self.save
  end

  def customization_json
    begin
      config = self.customizations || {}
    rescue => e
      config = {}
      ExceptionNotifier.notify_exception e
    end 

    config['banner'] ||= {}
    config['banner']['logo'] ||= {}

    if self.logo_file_name
      config['banner']['logo']['url'] = self.logo.url
    elsif config['banner']['logo'].has_key?('url')
      config['banner']['logo']['url'] = nil
    end 

    if self.masthead_file_name
      config['banner']['background_image_url'] = self.masthead.url
    elsif config['banner'].has_key?('background_image_url')
      config['banner'].delete('background_image_url')
    end 

    config

  end


  # Returns a hash of all the roles. Each role is expressed
  # as a list of (1) user keys, (2) email addresses (for users w/o an account)
  # and (3) email wildcards ('*', '*@consider.it'). 
  # 
  # Setting filter to try returns a roles hash that strips out 
  # all specific email addresses / user keys that are not the
  # current user. 
  #
  # TODO: consolidate with proposal.user_roles
  def user_roles(filter = false)
    rolez = roles ? roles.deep_dup : {}
    ['admin', 'proposer', 'visitor', 'participant'].each do |role|

      # default roles if they haven't been set
      default_role = ['visitor', 'proposer', 'participant'].include?(role) ? ['*'] : []
      rolez[role] = default_role if !rolez.has_key?(role) || !rolez[role]

      # Filter role if the client isn't supposed to see it
      if filter
        # Remove all specific email address for privacy. Leave wildcards.
        # Is used by client permissions system to determining whether 
        # to show action buttons for unauthenticated users. 
        rolez[role] = rolez[role].map{|email_or_key|
          email_or_key.index('*') || email_or_key.match("/user/") ? email_or_key : '-'
        }.uniq
      end
    end

    rolez
  end

  def title 
    self.name
  end

  def classes_to_moderate
    if moderation_policy > 0
      [Proposal, Point, Comment]
    else
      []
    end

  end

  def nuke 
    self.proposals.destroy_all
    self.opinions.destroy_all
    self.points.destroy_all
    self.comments.destroy_all
    Proposal.clear_cache(self)
  end

  def import_from_argdown(argdown, active_user)
    errors = []
    modified = {
      "lists" => [],
      "proposals" => [],
      "points" => [],
      "comments" => []
    }

    def parse_parts(line)
      line = line.strip
      line.force_encoding("utf-8")

      title_start = line.index('[')
      title_end = line.index(']')

      if title_start == nil
        title_start = 0
        title_end = -1
        desc_start = desc_end = -1
      else 
        title_start += 1
        desc_start = title_end + 1
        if line[title_end + 1] == ':'
          desc_start += 1
        end
        desc_end = -1
        title_end -= 1
      end

      meta_starts = -1
      if line[-1] == '}'
        meta_starts = line.index('{')
        desc_end = meta_starts - 1
        if meta_starts < title_end || title_end == -1
          title_end = meta_starts - 1
        end
      end 

      {
        title: line[title_start..title_end].strip,
        desc: desc_start > -1 ? line[desc_start..desc_end].strip: nil,
        meta: meta_starts > -1 ? JSON.parse(line[meta_starts..-1].strip) : {}
      }
    end


    subdomain = self
    self.customizations ||= {}
    customization = subdomain.customizations

    current_page = current_list = current_proposal = current_point = page_info = nil
    argdown.each do |line|
      next if line.strip.length == 0

      if line.strip[0] == '{' && line.strip[-1] == '}'
        # parsing an instruction block
        instructions = JSON.parse line.strip
        if instructions['active_user']
          active_user = User.find(instructions['active_user'].to_i)
        end

      elsif line.start_with?('### ')
        # parsing a page (currently used for tabs)
        current_page = line[4..-5].strip
        page_info = current_page.split(': ')
        current_page = page_info[0]
        current_list = current_proposal = current_point = nil

      elsif line[0] == '['
        # parsing a list

        current_proposal = current_point = nil
        list_config = parse_parts(line)

        if list_config[:meta].has_key?("list_key")
          current_list = list_config[:meta]["list_key"]
        else 
          current_list = "list/#{slugify(list_config[:title])}"
        end

        params = {
            "list_title" => list_config[:title],
            "list_description" => list_config[:desc],
            "created_by" => "/user/#{active_user.id}"
          }

        if !subdomain.customizations.has_key?(current_list)
          subdomain.customizations[current_list] = params
          modified['lists'].push "Created list #{subdomain.customizations[current_list]["list_title"]}"
        else 
          subdomain.customizations[current_list].merge!(params)
          modified['lists'].push "Modified list #{subdomain.customizations[current_list]["list_title"]}"
        end

        if list_config[:meta]
          subdomain.customizations[current_list].merge!(list_config[:meta])
        end

        if current_page
          subdomain.customizations["homepage_tabs"] ||= []

          tab_config = subdomain.customizations["homepage_tabs"]
          if !tab_config 
            subdomain
          end

          page_config = nil 
          found = false 

          tab_config.each do |page|
            if page["name"] == current_page
              found = true
              page["lists"] ||= []
              if !page["lists"].index(current_list)
                page["lists"].push(current_list)
                modified['lists'].push "Added list #{subdomain.customizations[current_list][:list_title]} to #{current_page}"
              end
            end
          end

          if !found 
            page = {"name": current_page, "lists": [current_list]}
            if page_info.length > 1
              page["page_preamble"] = page_info[1]
            end 

            tab_config.push(page)
            modified['lists'].push "Created page #{current_page}"
            modified['lists'].push "Added list #{subdomain.customizations[current_list][:list_title]} to #{current_page}"
          end
        end 

        subdomain.save

      elsif line.start_with?('* ') && current_list
        # parsing a proposal
        current_point = nil

        title = line[line.index('[')..line.index(']') - 1]
        desc = line[line.index(']') + 1..-1]
        proposal_config = parse_parts(line)

        if proposal_config[:meta].has_key?("slug")
          current_proposal = Proposal.find_by_slug proposal_config[:meta]["slug"]
        elsif proposal_config[:meta].has_key?("id") && Proposal.find_by_id(proposal_config[:meta]["id"])
          current_proposal = Proposal.find proposal_config[:meta]["id"]
        else 
          current_proposal = subdomain.proposals.find_by_name proposal_config[:title]
        end

        if proposal_config[:meta].has_key?("user")
          user = User.find proposal_config[:meta]["user"][6..-1]
        else
          user = active_user
        end

        params = {
            'subdomain_id': subdomain.id,
            'user_id': user.id,
            'name': proposal_config[:title],
            'description': proposal_config[:desc],
            'cluster': current_list[5..-1],
            'published': true
          }
        if !current_proposal
          current_proposal = Proposal.new(params)
          modified['proposals'].push "Created Proposal #{current_proposal.name}"

        else
          current_proposal.update params
          modified['proposals'].push "Modified Proposal #{current_proposal.name}"
        end
        current_proposal.save

        if proposal_config[:meta]
          vals = proposal_config[:meta]
          if vals.has_key?("author_opinion")
            val = vals["author_opinion"].to_f
            opinion = Opinion.get_or_make(current_proposal, user)
            opinion.stance = val
            opinion.published = true
            opinion.save
          end
        end

      elsif current_proposal && (line.start_with?('  +') || line.start_with?('  -'))
        # parsing a pro or con
        is_pro = line[2] == '+'

        point_config = parse_parts(line[3..-1])

        if point_config[:meta].has_key?("id") && Point.find_by_id(point_config[:meta]["id"])
          current_point = Point.find point_config[:meta]["id"]
        else 
          current_point = Point.find_by_nutshell point_config[:title]
        end

        if point_config[:meta].has_key?("user")
          user = User.find point_config[:meta]["user"][6..-1]
        else
          user = active_user
        end
        

        opinion = Opinion.get_or_make(current_proposal, user)

        attrs = {
            'subdomain_id': subdomain.id,
            'proposal_id': current_proposal.id,
            'user_id': user.id,
            'nutshell': point_config[:title],
            'text': point_config[:desc],
            'is_pro': is_pro,
            'published': true
          }
        if !current_point
          current_point = Point.new(attrs)
          modified['points'].push "Created point #{current_point.nutshell}"
        else 
          current_point.update attrs
          modified['points'].push "Modified point #{current_point.nutshell}"
        end
        current_point.save

        opinion.include current_point

      elsif current_point && line.start_with?('    *')
        # parsing a comment
        comment_config = parse_parts(line[5..-1])

        if comment_config[:meta].has_key?("id") && current_point.comments.find_by_id(comment_config[:meta]["id"])
          comment = current_point.comments.find comment_config[:meta]["id"]
        else 
          comment = current_point.comments.find_by_body comment_config[:title]
        end

        if comment_config[:meta].has_key?("user")
          user = User.find comment_config[:meta]["user"][6..-1]
        else
          user = active_user
        end

        params = {
            'subdomain_id': subdomain.id,
            'user_id': user.id,
            'body': comment_config[:title],
            'point_id': current_point.id,
            'commentable_type': 'Point',
            'commentable_id': current_point.id
          }

        if !comment
          comment = Comment.new(params)
          modified['comments'].push "Created comment #{comment.body}"
        else 
          comment.update params 
        end
        comment.save

        current_point.set_comment_count
        current_point.save


      elsif line.strip.start_with?('//') # skip comment
        pp "comment: ", line.strip
      else 
        errors.push "Could not read line '#{line}'"
      end



    end


    {errors: errors, modified: modified}


  end



end
