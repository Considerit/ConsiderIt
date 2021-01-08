class PointController < ApplicationController

  def show
    point = Point.find params[:id]
    authorize! 'read point', point

    dirty_key "/point/#{params[:id]}"
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
    point['published'] = false
    point['user_id'] = current_user && current_user.id || nil

    authorize! 'create point', proposal


    errors = validate_input point, proposal, nil

    if errors.length == 0

      point = Point.new point

      opinion = Opinion.get_or_make(proposal)

      if !proposal
        raise "Error! No proposal matching '#{point['proposal']}'"
      end
      if !opinion
        raise "Error! No opinion for user #{current_user.id} and proposal #{proposal.id}"
      end

      if opinion.published
        point.publish
      else
        point.save
      end

      # Include into the user's opinion
      opinion.include(point)

      original_id = key_id(params[:key])
      result = point.as_json
      result['key'] = "/point/#{point.id}?original_id=#{original_id}"

      dirty_key "/page/#{proposal.slug}"

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
    proposal.opinions.where("point_inclusions like '%#{params[:id]}%'").map do |o|
      o.recache
      dirty_key "/opinion/#{o.id}"
    end

    dirty_key("/page/#{proposal.slug}") #because /points is changed...

    render :json => []
  end
 
end
