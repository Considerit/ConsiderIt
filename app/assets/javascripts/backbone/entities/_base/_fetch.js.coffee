@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  App.commands.setHandler "when:fetched", (entities, callback) ->
    xhrs = _.chain([entities]).flatten().pluck("_fetch").value()
    App.execute "when:completed", xhrs, callback

  App.commands.setHandler "when:completed", (xhrs, callback) ->
    xhrs = _.flatten [xhrs]
    $.when(xhrs...).done ->
      callback()