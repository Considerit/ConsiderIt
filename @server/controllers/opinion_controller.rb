class OpinionController < ApplicationController

  def show
    opinion = Opinion.find(params[:id])
    authorize! 'read opinion', opinion
    dirty_key opinion.key
    render :json => []
  end

  def create
    matches = /\/([a-zA-Z]+)\/(\d+)/.match(params['statement'])
    params['statement_type'] = matches[1].capitalize
    params['statement_id'] = matches[2]

    statement = params['statement_type'].constantize.find params['statement_id']
    authorize! 'publish opinion', statement

    fields = ['statement_id', 'statement_type', 'stance', 'point_inclusions']
    updates = params.select{|k,v| fields.include? k}.to_h

    # Convert point_inclusions to ids
    incs = updates['point_inclusions']
    incs = [] if incs.nil? # Damn rails http://guides.rubyonrails.org/security.html#unsafe-query-generation

    incs = incs.map! {|p| key_id(p)}
    updates['point_inclusions'] = incs

    updates['user_id'] = current_user.id 
    
    opinion = Opinion.new updates 
    opinion.update_inclusions incs

    opinion.save 
    opinion.publish()
    write_to_log({
      :what => 'published opinion',
      :where => statement.slug || statement.key
    })

    original_id = key_id(params[:key])
    result = opinion.as_json
    result['key'] = "#{opinion.key}?original_id=#{original_id}"
    
    dirty_key statement.key
    render :json => [result]

  end
  
  def update
    opinion = Opinion.find key_id(params)
    authorize! 'update opinion', opinion

    fields = ['stance', 'point_inclusions', 'explanation']
    updates = params.select{|k,v| fields.include? k}.to_h

    # Convert point_inclusions to ids
    incs = updates['point_inclusions']
    incs = [] if incs.nil? # Damn rails http://guides.rubyonrails.org/security.html#unsafe-query-generation

    incs = incs.map! {|p| key_id(p)}
    opinion.update_inclusions incs
    updates['point_inclusions'] = incs
    
    # Update the normal fields
    opinion.update_attributes updates
    opinion.save

    statement = opinion.statement

    # Update published
    if params['published'] && !opinion.published

      authorize! 'publish opinion', statement

      opinion.publish()  # This will also publish all the newly-written points

      write_to_log({
        :what => 'published opinion',
        :where => statement.slug || statement.key
      })
    elsif params.has_key?('published') && !params['published'] && opinion.published
      opinion.unpublish()
      write_to_log({
        :what => 'unpublished opinion',
        :where => statement.slug || statement.key
      })

    end

    dirty_key statement.key
    
    dirty_key opinion.key

    render :json => []

  end

end
