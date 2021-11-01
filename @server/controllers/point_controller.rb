class PointController < ApplicationController

  def show
    begin
      point = Point.find params[:id]
    rescue 
      render :json => []
      return
    end 
    authorize! 'read point', point
    dirty_key "/point/#{params[:id]}"

    render :json => []
  end

  def index
    dirty_key '/points'
    render :json => []
  end


  def validate_input(attrs, proposal, point)
    errors = []
    if !attrs['nutshell'] || attrs['nutshell'].length == 0
      errors.append translator('errors.summary_required', 'A summary is required')
    end

    if (!point || (point && point.nutshell != attrs['nutshell'])) && proposal.points.find_by_nutshell(attrs['nutshell'])
      errors.append translator('errors.duplicate_point', 'Someone has already made that point')
    end

    return errors
  end


  def create
    # Validate by filtering out unwanted fields
    # todo: validate data types too
    fields = ['nutshell', 'text', 'is_pro', 'hide_name', 'proposal']
    point = params.select{|k,v| fields.include? k}.to_h

    # Set private values
    point['proposal'] = proposal = Proposal.find(key_id(point['proposal']))
    point['comment_count'] = 0
    point['published'] = true
    point['user_id'] = current_user && current_user.id || nil

    authorize! 'create point', proposal


    errors = validate_input point, proposal, nil

    if errors.length == 0

      point = Point.new point


      if !proposal
        raise "Error! No proposal matching '#{point['proposal']}'"
      end

      point.save
      point.publish

      po_params = {
        subdomain_id: point.subdomain_id,
        statement_id: point.id,
        statement_type: 'Point',
        stance: 0.5,
        user_id: point.user_id,
        published: true
      }

      # The author of the point gets a default stance on the point
      po = Opinion.new po_params

      po.save 


      original_id = key_id(params[:key])
      result = point.as_json
      result['key'] = "/point/#{point.id}?original_id=#{original_id}"

      dirty_key "/page/#{proposal.slug}"
      dirty_key "/proposal/#{proposal.id}"
      write_to_log({
        :what => 'wrote new point',
        :where => request.fullpath,
        :details => {:point => "/point/#{point.id}"}
      })

    else 
      result = {
        :key => params[:key],
        :errors => errors
      }
    end

    render :json => [result]
  end

  def update
    point = Point.find params[:id]

    errors = []

    if permit('update point', point) > 0

      fields = ["nutshell", "text", "hide_name"]
      updates = params.select{|k,v| fields.include? k}.to_h

      fields.each do |f|
        if !updates.has_key?(f)
          updates[f] = point[f]
        end
      end

      errors = validate_input updates, point.proposal, point

      if errors.length == 0

        point.update_attributes! updates

        if point.published
          write_to_log({
            :what => 'edited a point',
            :where => request.fullpath,
            :details => {:point => "/point/#{point.id}"}
          })

          point.redo_moderation
        end
      end
    end

    response = point.as_json
    if errors.length > 0
      response[:errors] = errors
    end

    render :json => [response]
  end

  def destroy
    point = Point.find params[:id]
    proposal = point.proposal
    
    authorize! 'delete point', point

    point.destroy

    dirty_key("/page/#{proposal.slug}") #because /points is changed...
    dirty_key("/proposal/#{proposal.id}")
    render :json => []
  end
 
end
