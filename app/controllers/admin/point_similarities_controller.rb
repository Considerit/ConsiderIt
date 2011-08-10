class Admin::PointSimilaritiesController < ApplicationController
  
  def index
    @user = current_user
    @option = Option.find(params[:option_id])

    pairs = {};
    @option.point_similarities.each do |ps|
      pp pairs
      if pairs.has_key?(ps.p1)
        if pairs[ps.p1].has_key?(ps.p2)
          pairs[ps.p1][ps.p2].push(ps)
        else
          pairs[ps.p1][ps.p2] = [ps]
        end
      else
        pairs[ps.p1] = {ps.p2 => [ps]}
      end

      if pairs.has_key?(ps.p2)
        if pairs[ps.p2].has_key?(ps.p1)
          pairs[ps.p2][ps.p1].push(ps)
        else
          pairs[ps.p2][ps.p1] = [ps]
        end


      else
        pairs[ps.p2] = {ps.p1 => [ps]}
      end

    end

    @graph_def = []

    pairs.each do |pnt, compared_points|

      my_def = {
        "data" => {  
          "$color" => pnt.is_pro ? "#988"  : "#899",   
          "$type" => pnt.is_pro ? "circle"  : "triangle"  
        },   
        "id" => "point-#{pnt.id}",   
        "name" => "point-#{pnt.id}",
        "adjacencies"  => [] 
      }
      compared_points.each do |pnt2, comparisons|
        weight = comparisons.inject(0){ |sum, el| sum + el.value }.to_f / comparisons.size
        if weight < 4
          next
        end        
        my_def["adjacencies"].push({
         "nodeTo" =>  "point-#{pnt2.id}",
         "nodeFrom" => "point-#{pnt.id}",
         "data" => { "weight" => weight }
        })
      end
      @graph_def.push(my_def)
    end
    @graph_def = @graph_def.to_json

  end

  def new
    redirect_to root_path unless current_user.admin?

    @option = Option.find(params[:option_id])
    @user = current_user

    @total_compared = current_user.point_similarities.where(:option_id=>@option.id).count
    @num_points = @option.points.count
    @total_possible_comparisons = (@num_points * (@num_points-1))/2
    @current = @total_compared + 1

    if @total_compared >= @total_possible_comparisons
      first = current_user.point_similarities.where(:option_id => @option.id).first
      redirect_to edit_option_point_similarity_path(@option, first)
    end

    pairs = {}

    current_user.point_similarities.where(:option_id=>@option.id).each do |ps|

      if pairs.has_key?(ps.p1_id)
        pairs[ps.p1_id][ps.p2_id] = 1
      else
        pairs[ps.p1_id] = {ps.p2_id => 1}
      end

      if pairs.has_key?(ps.p2_id)
        pairs[ps.p2_id][ps.p1_id] = 1
      else
        pairs[ps.p2_id] = {ps.p1_id => 1}
      end

    end

    @comparison = @option.point_similarities.build
    @init_val = 3

    last_comparison = current_user.point_similarities.where(:option_id=>@option.id).last
    if ( last_comparison && pairs[last_comparison.p1_id].length < @num_points - 1 && @total_compared % 10 != 9 )
      @p1 = last_comparison.p1
      while ( !@p2) || @p2.id == @p1.id || (pairs.has_key?(@p1.id) && pairs[@p1.id].has_key?(@p2.id))
        @p2 = @option.points.sample()
      end
    else(!last_comparison || @total_compared % 10 == 9) 
      @p1 = @p2 = nil
      while ( !@p1 || !@p2) || @p2.id == @p1.id || (pairs.has_key?(@p1.id) && pairs[@p1.id].has_key?(@p2.id))
        (@p1, @p2) = @option.points.sample(2)
      end
    end
    
  end
  
  def edit    
    redirect_to root_path unless current_user.admin?
    
    @option = Option.find(params[:option_id])
    @user = current_user
    @total_compared = current_user.point_similarities.where(:option_id=>@option.id).count
    @num_points = @option.points.count
    @comparison = PointSimilarity.find(params[:id])
    @init_val = @comparison.value
    @total_possible_comparisons = (@num_points * (@num_points-1))/2
    @current = current_user.point_similarities.where(:option_id=>@option.id).where('id <' + params[:id]).count + 1

    @p1 = @comparison.p1
    @p2 = @comparison.p2
  end
  
  def create
    redirect_to root_path unless current_user.admin?
    @option = Option.find(params[:option_id])
    @user = current_user
    
    params[:point_similarity].update({
      :user_id => current_user.id,
      :option_id => @option.id,
    })
    
    last = current_user.point_similarities.where(:option_id => @option.id).last
    @comparison = PointSimilarity.create!(params[:point_similarity])

    if params[:commit] == 'Next >>'
      redirect_to new_option_point_similarity_path(@option)
    else
      redirect_to edit_option_point_similarity_path(@option, last)
    end
  end

  def update
    redirect_to root_path unless current_user.admin?
    
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
