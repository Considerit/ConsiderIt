module ApplicationHelper
  
  def get_initiatives
    return Option.all(:order => "id")
  end

  def has_stance(user, initiative)
    return false
    
    if user.nil? || initiative.nil?
      return 'unfinished'
    end
    
    stance = Stance.last( :conditions => { :user_id => user.id, :initiative_id => initiative.id, :active => 1})
    if stance.nil?
      return 'unfinished'
    end
    
    if stance.bucket == 3
      return 'finished neutral'
    elsif stance.bucket < 3
      return 'finished con'
    else
      return 'finished pro'
    end
    
  end


  ## modified from: https://github.com/ryanb/complex-form-examples/blob/master/app/helpers/application_helper.rb
  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
  
  def link_to_add_fields(name, f, association, partial, mclass)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :f => builder)
    end
    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => mclass)
  end

end
