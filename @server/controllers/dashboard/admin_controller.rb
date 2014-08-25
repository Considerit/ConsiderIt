require 'date'

class Dashboard::AdminController < Dashboard::DashboardController
  #respond_to :json
  
  def admin_template
    render :json => { 
      :admin_template => self.process_admin_template() }
  end

  def proposals
    # if !(current_user.is_admin? || current_user.has_role?(:manager))
    #   redirect_to root_path, :notice => "You need to be an admin to do that."
    #   return
    # end
  end

  def roles

    if current_user.nil? || !(current_user.is_admin? || current_user.has_role?(:manager))
      result = {
        :result => 'failed',
        :reason => current_user.nil? ? 'not logged in' : 'not authorized'
      }
    else
      result = { 
        :admin_template => params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil}
    end

    if request.xhr?
      render :json => result 
    else
      render "layouts/dash", :layout => false 
    end
  end

  def update_role

    if current_user.nil? || !(current_user.is_admin? || current_user.has_role?(:manager))
      result = {
        :result => 'failed',
        :reason => current_user.nil? ? 'not logged in' : 'not authorized'
      }
    else

      user = User.find(params[:user_id])

      if params[:user][:role] == 'admin'
        user.roles = :admin
      elsif params[:user][:role] == 'user'
        user.roles = nil
      else
        [:moderator, :evaluator, :manager, :analyst].each do |role|
          user.roles.delete(role)
          if params[:user][role] == '1'
            user.roles << role
          end
        end
      end

      user.save
      result = { :roles_mask => user.roles_mask, :role_list => user.role_list } 
    end

    render :json => result
  end

  def analytics

    if current_user.nil? || !(current_user.is_admin? || current_user.has_role?(:analyst))
      result = {
        :result => 'failed',
        :reason => current_user.nil? ? 'not logged in' : 'not authorized'
      }
    else

      time_series = _get_timeseries
      visitation_data = _get_visitation

      result = { 
        :time_series_data => time_series,
        :visitation_data => visitation_data,
        :admin_template => params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil}
    end


    render :json => result

  end

  def import_data
    if current_user.nil? || !(current_user.is_admin? || current_user.has_role?(:analyst))
      result = {
        :result => 'failed',
        :reason => current_user.nil? ? 'not logged in' : 'not authorized'
      }
    else
      result = { 
        :admin_template => params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil}
    end

    if request.xhr?
      render :json => result 
    else
      render "layouts/dash", :layout => false 
    end    

  end

  def import_data_create
    result = Proposal.import_from_spreadsheet params[:account][:csv], {
      :published => params[:account]["published"],
      :user_id => params[:account]["user_id"],
    }

    if current_tenant.theme == 'lvg' && params[:account].has_key?(:csv_local) && params[:account][:csv_local]
      result.update Proposal.import_jurisdictions params[:account][:csv], params[:account][:csv_local]
    end

    render :json => result

  end

  protected

  def _get_timeseries
    series = []

    classes = [User, Opinion, Inclusion, Point, Comment]

    classes.each_with_index do |data, idx|
      dates = {}
      name = data.name.split('::').last

      if [Opinion, Point].include?(data)
        qry = data.published
      else
        qry = data
      end

      if [Inclusion].include? data
        qry = qry
                .joins(:opinion)
                .where('opinions.published = 1')
                .where('inclusions.created_at is not null')
                .select('count(*) as cnt, inclusions.created_at')
                .group('YEAR(inclusions.created_at), MONTH(inclusions.created_at), DAY(inclusions.created_at)')
      else
        qry = qry.select('count(*) as cnt, created_at')
                .group('YEAR(created_at), MONTH(created_at), DAY(created_at)')
                .where('created_at is not null')
      end

      qry = qry.order('created_at')

      time = []
      qry.each do |obj|
         time.push([obj.created_at.to_date.strftime('%s').to_i * 1000, obj.cnt ])
      end

      cumulative = []
      prev = 0
      time.each_with_index do |row, idx|
        cumulative.push([row[0], row[1] + prev])
        prev += row[1]
      end

      series.push( {
        :title => name,
        :main => { :title => name, :data => time}, 
        :cumulative => { :title => 'Cumulative ' + name, :data => cumulative}
      })
    end
    series
  end

  def _get_visitation

    visitation = {}

    visits = current_tenant.page_views

    sessions_for_user = Hash.new {|h,k| h[k] = Set.new }
    sessions_for_ip = Hash.new {|h,k| h[k] = Set.new }
    views_for_sessions = Hash.new {|h,k| h[k] = [] }

    bots_regex = Regexp.new(/\(.*https?:\/\/.*\)/)

    bots = Hash.new {|h,k| h[k] = 0 }
    not_bots = Hash.new {|h,k| h[k] = 0 }

    visits.each do |pv|
      next if bots_regex.match pv.user_agent # pass on bots

      views_for_sessions[pv.session] << pv
      
      sessions_for_user[pv.user_id] << pv.session if pv.user_id
      sessions_for_ip[pv.ip_address] << pv.session

    end

    # collapse users with multiple sessions
    sessions_for_user.each do |user_id,sessions|
      sessions = sessions.to_a
      next if sessions.length < 2
      canonical_session = sessions[0]
      sessions[1..sessions.length].each do |session|
        views_for_sessions[canonical_session].concat views_for_sessions.delete(session) if views_for_sessions.has_key?(session)
      end
      views_for_sessions[canonical_session].each do |pv|
        pv.user_id = user_id
      end
    end

    #collapse ips with multiple sessions
    sessions_for_ip.each do |ip,sessions|
      sessions = sessions.to_a
      sessions = sessions.select {|s| views_for_sessions.has_key?(s) && views_for_sessions[s].length > 0 && views_for_sessions[s].collect{|c| c.user_id ? 1 : 0}.reduce(:+) == 0}
      next if sessions.length < 2

      canonical_session = sessions[0]
      sessions[1..sessions.length].each do |session|
        views_for_sessions[canonical_session].concat views_for_sessions.delete(session) if views_for_sessions.has_key?(session)
      end
      views_for_sessions[canonical_session].each do |pv|
        pv.ip_address = ip
      end
    end

    unique_visitors = []
    views_for_sessions.each do |session, views|
      views.sort! { |x,y| x.created_at <=> y.created_at }

      referer = views[0].referer
      begin
        referer_domain = referer ? URI.parse( referer ).host.gsub('www.', '') : '(not set)'
      rescue
        referer_domain = 'unknown'
      end

      visitor = {
        :referer => referer,
        :referer_domain => referer_domain,
        :user => views[0].user_id,
        :visits => views.count
      }
      unique_visitors.push visitor

    end

    #TODO: for users that created an account, measure things
    unique_visitors
  end

end