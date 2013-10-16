@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  App.commands.setHandler "when:fetched", (entities, callback, loading = true) ->
    already_fetched = true

    entities = _.flatten [entities]
    _.each entities, (e) ->
      console.log entities
      already_fetched &&= e.fetched

    if already_fetched
      callback()
      return

    xhrs = _.chain(entities).pluck("_fetch").value()
    App.execute "when:completed", xhrs, callback, loading

  App.commands.setHandler "when:completed", (xhrs, callback, loading = true) ->
    xhrs = _.flatten [xhrs]
    $.when(xhrs...).done ->
      callback()

    if loading
      App.execute 'show:loading',
        loading:
          entities : xhrs
          xhr: true
