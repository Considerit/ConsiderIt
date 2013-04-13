class ConsiderIt.Account extends Backbone.Model
  name: 'account'
  
  url : () ->
    Routes.account_path()