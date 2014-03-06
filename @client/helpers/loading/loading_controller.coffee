# from http://www.backbonerails.com/screencasts/loading-views

@ConsiderIt.module "Helpers.Loading", (Loading, App, Backbone, Marionette, $, _) ->
  
  class Loading.LoadingController extends App.Controllers.Base
    
    initialize: (options) ->
      { view, config } = options
      
      config = if _.isBoolean(config) then {} else config
      
      _.defaults config,
        loadingType: "spinner"
        entities: @getEntities(view)
        debug: false
      
      switch config.loadingType
        when "opacity"
          @region.currentView.$el.css "opacity", 0.5
        when "spinner"      
          loadingView = @getLoadingView()
          @show loadingView
        else 
          throw new Error("Invalid loadingType")
      
      @showRealView view, loadingView, config
      
    showRealView: (realView, loadingView, config) ->
      method = if config.xhr then 'when:completed' else 'when:fetched'
      App.execute method, config.entities, =>
        ## ...after the entities are fetched, execute this callback
        ## ================================================================ ##
        ## If the region we are trying to insert is not the loadingView then
        ## we know the user has navigated to a different page while the loading 
        ## view was still open. In that case, we know to manually close the original 
        ## view so its controller is also closed.  We also prevent showing the real 
        ## view (which would snap the user back to the old view unexpectedly)
        ## ================================================================ ##
        switch config.loadingType
          when "opacity"
            @region.currentView.$el.removeAttr "style"
          when "spinner"
            return realView.close() if @region.currentView isnt loadingView
        
        ## show the real view unless we've set debug in the loading options
        if realView instanceof Loading.LoadingView
          loadingView.close()
        else if !config.debug
          @show realView 

        @close()
      , false # by default, when:fetched will invoke a loading screen, so skip that here

    getEntities: (view) ->
      ## return the entities manually set during configuration, or just pull 
      ## off the model and collection from the view (if they exist)
      _.chain(view).pick("model", "collection").toArray().compact().value()
    
    getLoadingView: ->
      new Loading.LoadingView
  
  App.commands.setHandler "show:loading", (options) ->
    new Loading.LoadingController
      view: options.view || new Loading.LoadingView
      region: options.region || new Backbone.Marionette.Region { el: $('#l-loading-indicator') }
      config: options.loading

