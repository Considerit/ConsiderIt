module Invitations
end

class SubdomainController < ApplicationController
  respond_to :json
  skip_before_action :verify_authenticity_token, :only => :update_images_hack
  include Invitations

  def index 
    ActsAsTenant.without_tenant do 
      subdomains = Subdomain.where('name != "homepage"').map {|s| {:id => s.id, :name => s.name, :customizations => s.customizations, :activity => s.proposals.count > 1 || s.opinions.published.count > 1 || s.points.published.count > 0}}
      render :json => [{
        key: '/subdomains',
        subs: subdomains
      }]
    end
  end


  def create
    authorize! 'create subdomain'

    errors = []

    # TODO: sanitize / make sure has url-able characters
    subdomain = params[:subdomain]

    existing = Subdomain.find_by_name(subdomain)
    if existing
      errors.push "That site already exists. Please choose a different name."
      render :json => [{errors: errors}]
    else
      new_subdomain = Subdomain.new name: subdomain, app_title: params[:app_title]
      roles = new_subdomain.user_roles
      roles['admin'].push "/user/#{current_user.id}"
      roles['visitor'].push "*"
      new_subdomain.roles = JSON.dump roles
      new_subdomain.host = "#{new_subdomain.name}.#{request.host}"
      new_subdomain.host_with_port = "#{new_subdomain.name}.#{request.host_with_port}"
      new_subdomain.save


      set_current_tenant(new_subdomain)


      # Seed a new proposal
      proposal = Proposal.new({
        subdomain_id: new_subdomain.id, 
        slug: 'considerit_can_help', 
               # if you change the slug, be sure to update the 
               # welcome_new_customer email template
        name: 'Consider.it can help me',
        description: '',
        user: current_user,
        cluster: 'Test question',
        active: true,
        published: true, 
        moderation_status: 1,
        roles: "{\"editor\":[\"/user/#{current_user.id}\"],\"writer\":[\"*\"],\"commenter\":[\"*\"],\"opiner\":[\"*\"],\"observer\":[\"*\",\"*\"]}"
      })
      proposal.save

      opinion = Opinion.create!({
        published: true,         
        user: current_user,
        subdomain_id: new_subdomain.id, 
        proposal: proposal,
        stance: 0.0
      })
      current_user.add_to_active_in(new_subdomain)

      set_current_tenant(Subdomain.find_by_name('homepage'))


      # Send welcome email to subdomain creator
      UserMailer.welcome_new_customer(current_user, new_subdomain, params[:plan]).deliver_later

      render :json => [{key: 'new_subdomain', name: new_subdomain.name, t: ApplicationController.MD5_hexdigest("#{current_user.email}#{current_user.unique_token}#{new_subdomain.name}")}]

    end

  end

  def show
    if params[:id]
      dirty_key "/subdomain/#{params[:id] or current_subdomain.id}"
    else 
      dirty_key '/subdomain'
    end
    render :json => []
  end

  def update
    errors = []

    subdomain = Subdomain.find(params[:id])
    authorize! 'update subdomain', subdomain

    if subdomain.id != current_subdomain.id #&& !current_user.super_admin
      # for now, don't allow modifying non-current subdomain
      raise PermissionDenied.new Permission::DISABLED
    end

    fields = ['lang', 'moderate_points_mode', 'moderate_comments_mode', 'moderate_proposals_mode', 'about_page_url', 'notifications_sender_email', 'app_title', 'external_project_url', 'google_analytics_code']
    attrs = params.select{|k,v| fields.include? k}

    update_roles

    serialized_fields = ['roles', 'branding']
    for field in serialized_fields
      if params.has_key? field
        attrs[field] = JSON.dump params[field]
      end
    end

    if current_user.super_admin && params.has_key?('plan')
      attrs['plan'] = params['plan'].to_i
    end 

    if current_user.super_admin && params.has_key?('customizations')
      attrs['customizations'] = params['customizations']
    end 


    current_user.add_to_active_in
    current_subdomain.update_attributes! attrs

    response = current_subdomain.as_json
    if errors.length > 0
      response[:errors] = errors
    end
    render :json => [response]

  end

  def update_roles
    if params.has_key?('roles')
      if params.has_key?(:invitations) && params[:invitations]
        params['roles'] = process_and_send_invitations(params['roles'], params[:invitations], current_subdomain)
      end
      # rails replaces [] with nil in params for some reason...
      params['roles'].each do |k,v|
        params['roles'][k] = [] if !v
      end
    end
  end

  def update_images_hack
    attrs = {}
    if params['masthead']
      attrs['masthead'] = params['masthead']
    end
    if params['logo']
      attrs['logo'] = params['logo']
    end

    current_tenant.update_attributes attrs
    dirty_key '/subdomain'
    render :json => []
  end

  # errr, I'm just sticking this in here, shame on me...
  def metrics
    contribs = {}
    subs = {}
    total = {}

    fake_users = {}

    now = DateTime.now
    earliest = nil


    # TODO: put this in database
    demo_subs = ["galacticfederation", "MSNBC","washingtonpost","MsTimberlake","design","Relief-Demo","sosh","GS-Demo","impacthub-demo","librofm","bitcoin-demo","amberoon","SocialSecurityWorks","Airbdsm","event","lyftoff","Schools","ANUP2015","CARCD-demo","news","Committee-Meeting","Cattaca","AMA-RFS","economist","ITFeedback","kevin","program-committee-demo","ECAST-Demo"]
    skip_subs = {}
    demo_subs.each {|s| skip_subs[s] = 1}
    bad_subs = {}

    ActsAsTenant.without_tenant do 
      fake_users = {}
      fake = User.where("name like 'Fake User%' OR (active_in like '%2034%' AND (name like 'Public %' OR name like 'Community Member %' OR name like 'Stakeholder Working Group %' or name like 'Technical Advisory Committee Member %'))")
      fake.each do |u|
        fake_users[u.id] = 1
      end

      contribution_tables = [Proposal, Comment, Point, Opinion]
      contribution_tables.each do |table|
        qry = table.select(:created_at, :user_id, :subdomain_id)
        if [Point,Opinion,Proposal].include? table 
          qry = qry.where(:published => true)
        end 

        qry.each do |item|
          next if fake_users.has_key?(item.user_id) || !item.subdomain || skip_subs.has_key?(item.subdomain.name)

          days_since = (now - item.created_at.to_datetime).to_i


          # # for figuring out which subs have a lot of autogenerated participation
          # if !bad_subs.has_key?(item.subdomain.name)
          #   bad_subs[item.subdomain.name] = {
          #     :days => [],
          #     :users => []
          #   }
          # end

          # bad_subs[item.subdomain.name][:users].append item.user_id
          # bad_subs[item.subdomain.name][:days].append days_since



          if !contribs.has_key?(days_since)
            contribs[days_since] = {}
          end 
          if !subs.has_key?(days_since)
            subs[days_since] = {}
          end 
          if !total.has_key?(item.subdomain_id)
            total[item.subdomain_id] = {}
          end 
          if !total[item.subdomain_id].has_key?(days_since)
            total[item.subdomain_id][days_since] = {}
          end

          contribs[days_since][item.user_id] = 1 
          subs[days_since][item.subdomain_id] = 1
          
          total[item.subdomain_id][days_since][item.user_id] = 1

          if !earliest || earliest < days_since
            earliest = days_since
          end
        end
      end
    end

    # bad_subs.each do |k,v|
    #   m = {
    #     :sub => k,
    #     :users => v[:users].uniq.length,
    #     :days => v[:days].uniq.length,
    #     :d => v[:days][0]
    #   }
    #   puts "#{m[:sub]}\t#{m[:users]}\t#{m[:days]}\t#{m[:d]}"
    # end 

    active_contributors = []
    active_subs = []

    for i in (0..earliest)
      day = (now - i).strftime('%d-%b-%y')

      if contribs.has_key?(i)
        active_contributors.append [i, day, contribs[i].keys().length]
        active_subs.append [i, day, subs[i].keys().length]
      else 
        active_contributors.append [i, day, 0]
        active_subs.append [i, day, 0]            
      end 
    end

    contributors_per_subdomain = {}
    total.each do |subdomain, contributors_per_day| 
      c = {
        :active => 0,
        :lifetime => 0,
        :year => 0,
        :month => 0,
        :week => 0,
        :day => 0
      }
      contributors_per_day.each do |day, contributors|
        c[:active] += 1
        c[:lifetime] += contributors.keys().length
        c[:year] += contributors.keys().length if day <= 365
        c[:month] += contributors.keys().length if day <= 30
        c[:week] += contributors.keys().length if day <= 7                
        c[:day] += contributors.keys().length if day < 1
      end 
      contributors_per_subdomain[subdomain] = c
    end 

    metrics = {
      :key => '/metrics',
      :daily_active_contributors => active_contributors.reverse(),
      :daily_active_subdomains => active_subs.reverse(),
      :contributors_per_subdomain => contributors_per_subdomain
    }


    render :json => [metrics]
  end



end

module Invitations
  def process_and_send_invitations(roles, invitations, target)

    invitations.each do |invite|
      message = invite['message'] && invite['message'].length > 0 ? invite['message'] : nil
      users_with_role = roles[invite['role']]

      invites = invite['keys_or_emails']
      if !invites
        invites = []
      end

      invites.each do |user_or_email|
        next if user_or_email.index('*') # wildcards; no invitations!!
          
        if user_or_email[0] == '/'
          invitee = User.find(key_id(user_or_email))

        else 
          # check to make sure this user doesn't already have an account... 
          invitee = User.find_by_email(user_or_email)
          if !invitee
            # every invited & fully specified email address who doesn't yet have an account will have one created for them
            invitee = User.create!({
              :name => user_or_email.split('@')[0],
              :email => user_or_email,
              :registered => true,
              :complete_profile => true,
              :password => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] #temp password
            })
            invitee.add_to_active_in

            # replace email address with the user's key in the roles object
            users_with_role[users_with_role.index(user_or_email)] = "/user/#{invitee.id}"

          end
        end
        UserMailer.invitation(current_user, invitee, target, invite['role'], current_subdomain, message).deliver_later

      end
    end

    roles
  end
end
