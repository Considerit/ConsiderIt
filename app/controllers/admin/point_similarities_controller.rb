class Admin::PointSimilaritiesController < ApplicationController
  
  def new
    redirect_to root_path unless current_user.admin?

    @option = Option.find(params[:option_id])
    @user = current_user

    @total_compared = current_user.point_similarities.count
    @num_points = @option.points.count
    if current_user.point_similarities.count >= num_points * (num_points+1)/2 - num_points
      first = current_user.point_similarities.where(:option_id => @option.id).first
      redirect_to edit_option_point_similarity_path(@option, first)
    end

    pairs = {}
    pp current_user.point_similarities
    
    current_user.point_similarities.each do |ps|

      if pairs.has_key?(ps.p1_id)
        pairs[ps.p1_id][ps.p2_id] = 1
      else
        pairs[ps.p1_id] = {ps.p2_id => 1}
      end

      if pairs.has_key?(ps.p2_id)
        pairs[ps.p2_id][ps.p1_id] = 1
      else
        pairs[ps.p2_id] = {ps.p1.id => 1}
      end

    end

    @comparison = @option.point_similarities.build

    @p1 = @p2 = nil
    while ( !@p1 || !@p2) || (pairs.has_key?(@p1.id) && pairs[@p1.id].has_key?(@p2.id))
      (@p1, @p2) = @option.points.sample(2)
    end
    
  end
  
  def edit    
    redirect_to root_path unless current_user.admin?
    
    @option = Option.find(params[:option_id])
    @user = current_user
    @total_compared = current_user.point_similarities.count
    @num_points = @option.points.count
    @comparison = PointSimilarity.find(params[:id])
    @p1 = @comparison.p1
    @p2 = @comparison.p2
  end
  
  def create
    @option = Option.find(params[:option_id])
    @user = current_user
    
    params[:point_similarity].update({
      :user_id => current_user.id,
      :option_id => @option.id,
    })
    
    last = current_user.point_similarities.where(:option_id => @option.id).last
    @comparison = PointSimilarity.create!(params[:point_similarity])

    if params[:commit] == 'Next >>'
      pp 'new!!!'
      redirect_to new_option_point_similarity_path(@option)
    else
      pp 'old!!!'
      redirect_to edit_option_point_similarity_path(@option, last)
    end
  end

  def update
    @option = Option.find(params[:option_id])
    @user = current_user
    @comparison = PointSimilarity.find(params[:id])
    
    @comparison.value = params[:point_similarity][:value]
    @comparison.save

    last = current_user.point_similarities.where(:option_id => @option.id).last

    if params[:commit] == 'Next >>'
      if last.id > @comparison.id
        comp_next = current_user.point_similarities
          .where(:option_id => @option.id)
          .where('id > ?', @comparison.id)
          .order('id')
          .first
        redirect_to edit_option_point_similarity_path(@option, comp_next)
      else
        redirect_to new_option_point_similarity_path(@option)        
      end
    else
      comp_prev = current_user.point_similarities
        .where(:option_id => @option.id)
        .where('id < ?', @comparison.id)
        .order('id DESC')
        .first        
      redirect_to edit_option_point_similarity_path(@option, comp_prev)
    end
  end
  
end
