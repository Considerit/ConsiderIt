@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Error extends App.Entities.Model
    name: 'error'

    url : () ->
      Routes.report_client_error_path( )

  class Entities.Errors extends App.Entities.Collection
    model: Entities.Error

  API = 
    all_errors : new Entities.Errors()

    createError : (type, trace, msg, url, line, options = {wait : true}) ->
      attrs = 
        type : type
        trace : trace
        line : line
        location : url #window.location.href
        message : msg

      
      @all_errors.create attrs, options


  App.vent.on 'javascript:error', (type, trace, msg, url, line) ->
    API.createError trace, msg, url, line


