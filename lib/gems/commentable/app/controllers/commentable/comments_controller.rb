#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************


class Commentable::CommentsController < ApplicationController
  protect_from_forgery

  respond_to :json

  def create
    authorize! :create, Commentable::Comment
    @proposal = Proposal.find(params[:comment][:proposal_id])
    @user_who_commented = current_user
    commentable_type = params[:comment][:commentable_type]

    existing = Commentable::Comment.find_by_body(params[:comment][:body])
    commentable = commentable_type.constantize.find(params[:comment][:commentable_id])

    if existing.nil?
      @comment = Commentable::Comment.build_from(commentable, @user_who_commented.id, params[:comment][:body] )
    else
      @comment = existing
    end

    if !existing.nil? || @comment.save

      if existing.nil?

        ActiveSupport::Notifications.instrument("new_comment_on_#{commentable_type}", 
          :commentable => commentable,
          :comment => @comment, 
          :current_tenant => current_tenant,
          :mail_options => mail_options
        )

        #@comment.notify_parties(current_tenant, mail_options)
        @comment.track!
        @comment.follow!(current_user, :follow => true, :explicit => false)
        if commentable.respond_to? :follow!
          commentable.follow!(current_user, :follow => true, :explicit => false)
        end
      end

      follows = commentable.follows.where(:user_id => current_user.id).first

      new_comment = render_to_string :partial => "commentable/comment", :locals => { :comment => @comment } 
      response = { :new_point => new_comment, :comment_id => @comment.id, :is_following => follows && follows.follow }

      #if existing.nil? && grounded_in_point
      #  response[:rerendered_ranked_point] = render_to_string :partial => "points/ranked_list", :locals => { :point => point }
      #end
      render :json => response.to_json     
    end

  end

end