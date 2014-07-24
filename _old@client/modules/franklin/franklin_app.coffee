@ConsiderIt.module "Franklin", (Franklin, App, Backbone, Marionette, $, _) ->

  class Franklin.Router extends Marionette.AppRouter
    appRoutes : 
      "(/)" : "Root"      
      ":proposal(/)": "CraftOpinion"
      ":proposal/results(/)": "Results"
      ":proposal/points/:point(/)" : "OpenPoint"
      ":proposal/opinions/:user_id(/)" : "UserOpinion"


  API =
    Root: -> 

      region = App.request "default:region"
      return if region.controlled_by instanceof Franklin.Homepage.HomepageController

      history = [ ['homepage', '/'] ]

      App.request "sticky_footer:close"

      # if we're coming from a proposal page, note the proposal so that we can seek to it on the homepage      
      last_proposal_id = if region.controlled_by instanceof Franklin.Proposal.ProposalController then region.controlled_by.model.id else null
      
      if region.controlled_by
        region.controlled_by.close() 

      root_controller = new Franklin.Homepage.HomepageController
        region : region
        last_proposal_id : last_proposal_id

      region.controlled_by = root_controller

      App.vent.trigger 'route:completed', history
      App.request 'meta:change:default'


    CraftOpinion: (long_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      
      proposal = App.request 'proposal:get', long_id, true
      history = [ 
        ['homepage', '/'], 
        ["#{proposal.title(40)}", Routes.new_opinion_proposal_path(proposal.id)]
      ]

      @_transitionProposal proposal, history, 
        new_state : Franklin.Proposal.State.Crafting
        callback : =>
          App.request 'meta:set', proposal.getMeta() 


    Results: (long_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      
      proposal = App.request 'proposal:get', long_id, true
      history = [ 
        ['homepage', '/'], 
        ["#{proposal.title(40)}", Routes.new_opinion_proposal_path(proposal.id)] 
        ["results", Routes.proposal_path(proposal.id)]
      ]

      @_transitionProposal proposal, history, 
        new_state : Franklin.Proposal.State.Results
        callback : =>
          App.request 'meta:set', proposal.getMeta() 


    OpenPoint: (long_id, point_id) -> 
      return if ConsiderIt.inaccessible_proposal != null      
      proposal = App.request 'proposal:get', long_id, true
      point = App.request 'point:get', parseInt(point_id), true, long_id

      region = App.request 'default:region'
      proposal_controller = region.controlled_by

      is_in_crafting = region.controlled_by instanceof Franklin.Proposal.ProposalController && region.controlled_by.state == Franklin.Proposal.State.Crafting
      history = [ 
        ['homepage', '/'], 
        if is_in_crafting then ["#{proposal.id}", Routes.new_opinion_proposal_path(long_id)] else ["results", Routes.proposal_path(long_id)],      
        ["#{ if point.isPro() then 'Pro' else 'Con'} point", Routes.proposal_point_path(long_id, point_id)] ]


      @_transitionProposal proposal, history, 
        point : point
        callback : =>
          region.controlled_by.trigger 'point:open', point
          App.request 'meta:change:default'


    _transitionProposal: (proposal, history, options) -> 
      _.defaults options, 
        new_state :  null, 
        point : null
        callback : null

      region = App.request 'default:region'

      proposal_controller = if !proposal.get('published') then null else 
        try
          App.request "proposal_controller:#{proposal.id}"
        catch
          null

      # preserve the existing proposal controller if it exists and we're transitioning 
      animate_proposal_expansion_from_homepage = region.controlled_by instanceof Franklin.Homepage.HomepageController && proposal_controller && proposal_controller.region && proposal.get('published') 

      if animate_proposal_expansion_from_homepage
        #remove surrounding elements, while suspending proposal el and moving it gracefully to top
        #TODO: move to root controller? 
        $description_animation_time = if Modernizr.csstransitions then 500 else 0
        root_controller = region.controlled_by
        $pel = $(proposal_controller.region.el)
        $pel_offset = $pel.position()
        $pel.css
          top : $pel_offset.top - $(document).scrollTop()
          minHeight : 2000

        root_controller.region.hideAllExcept $pel
        $pel.addClass('transitioning')

        if $description_animation_time > 0
          $pel.animate
            top : 0
          , $description_animation_time, =>
            _.delay ->
              $pel.attr 'style', ''
            , 2500


        start = new Date().getTime()

        proposal_controller.showDescription options.new_state

      to_fetch = _.compact [proposal, options.point]
      App.execute 'when:fetched', to_fetch, =>

        remaining_time = if !animate_proposal_expansion_from_homepage then 0 else $description_animation_time - (new Date().getTime() - start)
        _.delayIfWait remaining_time, =>
          if region.controlled_by && region.controlled_by != proposal_controller
            if animate_proposal_expansion_from_homepage
              proposal_controller.upRoot() #preserve proposal's dom

            region.controlled_by.close()
            region.$el.find('.homepage_layout').remove()

            if animate_proposal_expansion_from_homepage
              proposal_controller.plant region #re-place proposal's dom

          # if we're already showing this proposal or we're transitioning from root with a proposal that is already instantiated
          if region.controlled_by && region.controlled_by == proposal_controller || animate_proposal_expansion_from_homepage
            # only change state if requested
            proposal_controller.changeState(options.new_state) if options.new_state
          else
            proposal_controller = new Franklin.Proposal.ProposalController
              region : region
              model : proposal
              proposal_state : options.new_state || Franklin.Proposal.State.Results

          region.controlled_by = proposal_controller  

          $pel.removeClass('transitioning') if $pel

          App.vent.trigger 'route:completed', history
          
          App.vent.trigger 'points:unexpand'
          if options.callback
            options.callback()

    UserOpinion: (long_id, user_id) ->
      return if ConsiderIt.inaccessible_proposal != null      

      proposal = App.request 'proposal:get', long_id, true
      App.execute 'when:fetched', proposal, => 
        region = App.request "default:region"        

        from_root = region.controlled_by instanceof Franklin.Homepage.HomepageController
        if !region.controlled_by #!(region.controlled_by instanceof Franklin.Proposal.ProposalController && region.controlled_by.model.id == proposal.id) && !from_root
          #region.controlled_by.close() if region.controlled_by
          proposal_controller = new Franklin.Proposal.ProposalController
            region : region
            model : proposal
            proposal_state : Franklin.Proposal.State.Results                        
          region.controlled_by = proposal_controller

        user = App.request 'user', parseInt(user_id)
        opinion = App.request('opinions:get').findWhere {long_id : long_id, user_id : user.id }
        new Franklin.UserOpinion.UserOpinionController
          model : opinion
          region: new Backbone.Marionette.Region
            el: $("body")

        if from_root
          history = [ 
            ['homepage', '/'], 
            ["#{user.get('name')}", Routes.proposal_opinion_path(long_id, opinion.id)] ]
        else
          history = [ 
            ['homepage', '/'], 
            if region.controlled_by.state == Franklin.Proposal.State.Crafting then ["#{proposal.id}", Routes.new_opinion_proposal_path(long_id)] else ["results", Routes.proposal_path(long_id)],
            ["#{user.get('name')}", Routes.proposal_opinion_path(long_id, opinion.id)] ]


        App.vent.trigger 'route:completed', history
        App.request 'meta:change:default'



  Franklin.on "start", ->

  App.addInitializer ->
    new Franklin.Router
      controller: API
