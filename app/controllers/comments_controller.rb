class CommentsController < ApplicationController
  protect_from_forgery

  respond_to :json

  def index
    @option = Option.find(params[:option_id])
    
    render :partial => "comments/discussion", :locals => { :comments => @option.root_comments, :new_thread => true, :parent_id => nil }

  end

  def create
    @option = Option.find(params[:comment][:option_id])
    @user_who_commented = current_user
    
    existing = Comment.find_by_body(params[:comment][:body])
    
    if existing.nil?
      @comment = Comment.build_from(@option, @user_who_commented.id, params[:comment][:body] )
      grounded_in_point = params[:comment].key?(:point_id)
      @comment.parent_id = params[:comment][:parent_id]
  
      if grounded_in_point
        point = Point.find(params[:comment][:point_id])
        #@comment.subject = "#{{1 => "Pro", 0 => "Con"}[point.position]} :: #{point.nutshell}"
        @comment.point_id = params[:comment][:point_id].to_i
      else
        @comment.subject = params[:comment][:subject]
      end
    else
      @comment = existing
    end

    if !grounded_in_point
      point = nil
    end


    if !existing.nil? || @comment.save

      if existing.nil?
        @comment.notify_parties
      end

      new_point = render_to_string :partial => "comments/comment", :locals => { :comment => @comment } 
      response = { :new_point => new_point, :comment_id => @comment.id }

      #if existing.nil? && grounded_in_point
      #  response[:rerendered_ranked_point] = render_to_string :partial => "points/ranked_list", :locals => { :point => point }
      #end
      render :json => response.to_json     
    end

  end

end





