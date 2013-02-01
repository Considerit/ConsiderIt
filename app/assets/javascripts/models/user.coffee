class ConsiderIt.User extends Backbone.Model
  defaults: { }
  name: 'user'

  initialize : () ->
    
  url : () ->
    Routes.user_path( @attributes.id )