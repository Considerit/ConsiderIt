do (Backbone) ->
  for override in [Backbone] #, Backbone.Paginator.clientPager.prototype]

    _sync = override.sync

    override.sync = (method, entity, options = {}) ->
      _.defaults options,
        beforeSend: _.bind(methods.beforeSend,   entity)
        complete:    _.bind(methods.complete,    entity)
            
      if override == Backbone
        sync = _sync method, entity, options
      else
        sync = _sync.apply entity, [method, entity, options]

      if !entity._fetch and method in ["read", "create", "update"]
        entity._fetch = sync

      sync

    methods =
      beforeSend: ->
        @trigger "sync:start", @
      
      complete: ->
        @trigger "sync:stop", @


