class CommentsController < ApplicationController
  protect_from_forgery

  respond_to :json

  def index
    
  end

  def create
    @proposal = Proposal.find(params[:comment][:proposal_id])
    @user_who_commented = current_user
    
    existing = Comment.find_by_body(params[:comment][:body])

    if existing.nil?
  
      if params[:comment].key?(:point_id)
        point = Point.find(params[:comment][:point_id])
        @comment = Comment.build_from(point, @user_who_commented.id, params[:comment][:body] )

        #@comment.point_id = params[:comment][:point_id].to_i
      elsif params[:comment].key?(:position_id)
        position = Position.published.find(params[:comment][:position_id])
        @comment = Comment.build_from(position, @user_who_commented.id, params[:comment][:body] )
      end

    else
      @comment = existing
    end


    if !existing.nil? || @comment.save

      if existing.nil?
        @comment.notify_parties(current_tenant, default_url_options)
        @comment.track!
      end

      new_comment = render_to_string :partial => "comments/comment", :locals => { :comment => @comment } 
      response = { :new_point => new_comment, :comment_id => @comment.id }

      #if existing.nil? && grounded_in_point
      #  response[:rerendered_ranked_point] = render_to_string :partial => "points/ranked_list", :locals => { :point => point }
      #end
      render :json => response.to_json     
    end

  end

end





