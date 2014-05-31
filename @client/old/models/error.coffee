@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Error extends App.Entities.Model
    name: 'error'

    url : () ->
      Routes.report_client_error_path( )

    parse : (attrs) ->
      if 'client_error' of attrs
        attrs.client_error
      else
        attrs

  class Entities.Errors extends App.Entities.Collection
    model: Entities.Error

    parse : (attrs) ->
      errors = (attr.client_error for attr in attrs)
      errors

  API = 
    all_errors : new Entities.Errors()

    createError : (type, trace, msg, url, line, options = {wait : true}) ->
      attrs = 
        error_type : type
        trace : trace
        line : line
        location : url #window.location.href
        message : msg

      @all_errors.create attrs, options

    addErrors : (errors) -> 
      @all_errors.add @all_errors.parse(errors), {merge: true}

    getErrors : -> @all_errors

  App.vent.on 'javascript:error', (type, trace, msg, url, line) ->
    API.createError type, trace, msg, url, line

  App.reqres.setHandler 'javascript:errors:get', ->
    API.getErrors()

  App.vent.on 'javascript:errors:fetched', (errors) ->
    API.addErrors errors