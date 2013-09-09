@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  
  class Entities.Collection extends Backbone.Collection

  class Entities.PaginatedCollection extends Backbone.PageableCollection

    mode: "client"
    state:
      firstPage: 1
      currentPage: 1
      pageSize: 5


    initialize : (options = {}) ->
      super options

    pageOf : (model) ->
      idx = _.indexOf @fullCollection.models, model
      if idx > -1
        Math.floor(idx / @state.pageSize + 1)
      else
        null