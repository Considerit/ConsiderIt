@ConsiderIt = do (Backbone, Marionette) ->
  
  App = new Marionette.Application

  App.on "initialize:before", (options) ->
    App.environment = options.environment
  
  App.addRegions
    headerRegion: "#l-header"
    mainRegion:    "#l-content-main-wrap"
    footerRegion: "#l-footer"
  
  App.rootRoute = Routes.root_path()
  
  App.addInitializer ->
    headerApp = App.module("HeaderApp")

    @listenTo headerApp, 'start', => 
      App.module("Auth").start()

    headerApp.start()
    App.module("FooterApp").start()

  App.reqres.setHandler "default:region", ->
    App.mainRegion
  
  App.commands.setHandler "register:instance", (instance, id) ->
    App.register instance, id if App.environment is "development"
  
  App.commands.setHandler "unregister:instance", (instance, id) ->
    App.unregister instance, id if App.environment is "development"
  
  App.on "initialize:after", ->
    
    #TODO: don't remove this until everything loaded
    $('#l-preloader').hide()

    # REFACTOR
    # ConsiderIt.router = new ConsiderIt.Router();

    #appview = new ConsiderIt.AppView()
    #@mainRegion.show appview

    #@dashboardview = new ConsiderIt.UserDashView({ model : ConsiderIt.request('user:current'), el : '#l-wrap'})

    #appview.render()

    #####
    
    # ConsiderIt.all_proposals = new ConsiderIt.ProposalList()
    # ConsiderIt.all_proposals.add_proposals ConsiderIt.proposals
    # if ConsiderIt.current_proposal
    #   ConsiderIt.all_proposals.add_proposal(ConsiderIt.current_proposal.data) 
    #   ConsiderIt.current_proposal = null


    @startHistory()
    @navigate(@rootRoute, trigger: true) unless @getCurrentRoute()


  App