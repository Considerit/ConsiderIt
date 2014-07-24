@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Thank extends App.Entities.Model
    name: 'thank'

    url : ->
      if @id
        Routes.thankable_path @id
      else
        Routes.thankable_index_path()

    parse : (attrs) ->
      attrs.thank

  class Entities.Thanks extends App.Entities.Collection
    model : Entities.Thank

    existsForUser : (thankable_type, thankable_id, user_id) ->
      thank = @findWhere 
        thankable_type : thankable_type
        thankable_id : thankable_id
        user_id : user_id

      return !!thank


  API = 
    all_thanks : new Entities.Thanks()

    addThanks : (thanks) ->
      @all_thanks.set thanks

    getThanks : (thankable_type, thankable_id) ->
      new Entities.Thanks @all_thanks.where {thankable_type: thankable_type, thankable_id : thankable_id}

    getThanksForUser : (thankable_type, thankable_id, user_id) ->
      @all_thanks.findWhere {thankable_type: thankable_type, thankable_id : thankable_id, user_id : user_id}

    hasThanks : (thankable_type, thankable_id, user_id) ->
      @all_thanks.existsForUser thankable_type, thankable_id, user_id

    createThanks : (attrs) ->
      @all_thanks.create attrs, {wait: true}

  App.vent.on 'comments:thanks:fetched', (thanks) ->
    API.addThanks thanks

  App.reqres.setHandler 'thanks', (thankable_type, thankable_id) ->
    API.getThanks thankable_type, thankable_id

  App.reqres.setHandler 'thanks:exists_for_user', (thankable_type, thankable_id, user_id) ->
    API.hasThanks thankable_type, thankable_id, user_id

  App.reqres.setHandler 'thanks:create', (attrs) ->
    API.createThanks attrs

  App.reqres.setHandler 'thanks:get:user', (thankable_type, thankable_id, user_id) ->
    API.getThanksForUser thankable_type, thankable_id, user_id

