class PageController < ApplicationController
  respond_to :json
  def show

    case params[:id]

    when 'homepage'
      result = {
        # proposals: Proposal.summaries(), 
        users: get_all_user_data(),
        contributors: recent_contributors()
      } 
      result['your_opinions'] = current_user.opinions.map {|o| o.as_json}

    when 'about'
      result = {} # don't need anything special, just the customer object with the about page url

    else # if proposal

      proposal = Proposal.find_by_long_id(params[:id])
      if !proposal 
        render :status => :not_found, :json => {:result => 'Not found'}
        return
      elsif cannot?(:read, proposal)
        render :status => :forbidden, :json => {:result => 'Permission denied'}
        return
      end

      result = proposal.full_data(can?(:manage, proposal))
      result['users'] = get_all_user_data()
      result['your_opinions'] = current_user.opinions.map {|o| o.as_json}

    end


    result['customer'] = current_tenant
    result['key'] = "/page/#{params[:id]}"
    render :json => result
  end

  private

  def get_all_user_data
    users = ActiveRecord::Base.connection.select( "SELECT id,name,avatar_file_name FROM users WHERE account_id=#{current_tenant.id} AND (registration_complete=true OR id=#{current_user.id})")
    users = users.as_json
    jsonify_objects(users, 'user')
  end

  def recent_contributors
    users = ActiveRecord::Base.connection.select( "SELECT u.id FROM users as u, opinions WHERE u.account_id=#{current_tenant.id} AND u.registration_complete=true AND opinions.user_id = u.id AND opinions.created_at > '#{9.months.ago.to_date}'")
    return users.map {|u| "/user/#{u['id']}"}
  end

end
