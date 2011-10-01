module ApplicationHelper
  
  def get_initiatives
    return Option.all(:order => "id")
  end

  def has_stance(option)
    return current_user && current_user.positions.where(:option_id => option.id).count > 0
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
