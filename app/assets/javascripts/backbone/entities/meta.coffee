@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  # not persisted
  class Entities.MetaData extends App.Entities.Model
    name: 'meta'

  API = 
    active_meta : new App.Entities.MetaData
    default_meta : new App.Entities.MetaData

    setMeta : (args, default_meta) ->
      if default_meta
        @default_meta.set args
        @active_meta.set @default_meta.attributes
      else
        if 'title' of args
          args['title'] = "#{args['title']}"
        if 'description' of args
          args['description'] = "#{args['description']}"
        if 'keywords' of args
          args['keywords'] = "#{args['keywords']}"

        @active_meta.set _.defaults(args, @default_meta.attributes)
      @active_meta

    getMeta : ->
      @active_meta

    changeToDefault : ->
      @setMeta {}, true

  App.reqres.setHandler 'meta:get', ->
    API.getMeta()

  App.reqres.setHandler 'meta:change:default', ->
    API.changeToDefault()

  App.reqres.setHandler 'meta:set', (args, default_meta = false) ->
    API.setMeta args, default_meta

  API.active_meta.on 'change', ->
    meta = API.getMeta()
    document.title = meta.get('title')
    $('head meta[name="description"]').attr('content', meta.get('description')) 
    $('head meta[name="keywords"]').attr('content', meta.get('keywords')) 

    # console.log 'updated meta', meta

  App.addInitializer ->
    
    args = 
      title : document.title
      description : $('head meta[name="description"]').attr('content')
      keywords : $('head meta[name="keywords"]').attr('content')

    App.request 'meta:set', args, true
