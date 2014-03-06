@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.DescriptionController extends App.Controllers.StatefulController


    initialize : (options = {}) ->
      super options

      @model = options.model
      @layout = @getLayout()

      @setupLayout @layout

      # important for showing or removing the proposal settings given auth change
      @listenTo App.vent, 'user:signout user:signin', => 
        if @region #this controller might have been closed by parent, e.g. if this is a private proposal and user just signed out         
          @region.show @layout

      @region.open = (view) => @stateIsChanging @region, view # this will set how this region handles the transitions between views
      @region.show @layout

    stateWasChanged : ->
      if @prior_state != @state
        @layout = @resetLayout @layout

      if @state == Proposal.State.Results
        @createSharing @layout
      else
        @removeSharing @layout


    stateIsChanging : (region, view) ->

      already_showing_details = region.$el.find('.proposal_details').length > 0

      if @state != Proposal.State.Summary && @prior_state == Proposal.State.Summary && !already_showing_details
        
        view.ui.details.hide()
        region.$el.empty().append view.el
        view.ui.details.slideDown 500
        #view.ui.details.show()
      else# if @state == Proposal.State.Summary || @prior_state == null
        region.$el.empty().append view.el

    removeSharing : (layout) ->
      if @model.openToPublic() && App.request('tenant').get('enable_sharing')
        layout.socialMediaRegion.reset()

    createSharing : (layout) ->
      if @model.openToPublic() && App.request('tenant').get('enable_sharing')
        social_view = @getSocialMediaView()
        layout.socialMediaRegion.show social_view

    setupLayout : (layout) ->

      @listenTo layout, 'show', ->
        @listenTo layout, 'proposal:clicked', =>
          App.navigate Routes.new_opinion_proposal_path( @model.id ), {trigger: true}

        if App.request "auth:can_edit_proposal", @model
          @admin_controller = @getAdminController layout.adminRegion
          @setupAdminController @admin_controller

        if @state == Proposal.State.Results
          @createSharing layout


    setupAdminController : (controller) ->
      @listenTo controller, 'proposal:published', =>
        @trigger 'proposal:published'
        @region.show @layout

      @listenTo controller, 'proposal:setting_changed', =>
        @trigger 'proposal:setting_changed'

    getAdminController : (region) ->
      new Proposal.ProposalSettingsController
        model : @model
        region : region
        parent_state : @state
        parent_controller : @

    getLayout : ->
      new Proposal.ProposalDescriptionView
        model : @model
        state : @state

    getSocialMediaView : ->
      new Proposal.SocialMediaView
        model : @model

