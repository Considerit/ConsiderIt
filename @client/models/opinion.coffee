@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Opinion extends App.Entities.Model
    name : 'opinion'
    defaults : 
      stance : 0
      user_id : -1

    urlRoot : ''
    written_points : []
    viewed_points : {}

    url : () ->
      if @attributes.proposal_id #avoid url if this is a new proposal

        if @id
          Routes.proposal_opinion_path @get('long_id'), @id
        else
          Routes.proposal_opinions_path @get('long_id')

    initialize : (options) ->
      super
      #TODO: create HTML version of explanation, instead of overwriting old
      @attributes.explanation = htmlFormat(@attributes.explanation) if @attributes.explanation
      
      # @proposal = ConsiderIt.all_proposals.get @attributes.proposal_id

    # SUBSUME: if a user published a previous opinion on this before,
    # but is submitting a new opinion (e.g. if they saved their
    # opinion, logged out, came back after a couple days, created a
    # new opinion, hit “save opinion”, then login), then merge the two
    # opinions.
    subsume : (other_pos) ->
      params = 
        stance : if other_pos.get('stance') != 0 then other_pos.get('stance') else @get('stance')
        stance_segment : if other_pos.get('stance') != 0 then other_pos.get('stance_segment') else @get('stance_segment')

      explanation = other_pos.get('explanation')
      params.explanation = explanation if explanation? and explanation.length > 0

      @set params

      @viewed_points = _.union @viewed_points, other_pos.viewed_points
      @written_points = _.union @written_points, other_pos.written_points
      @included_points = _.union @getIncludedPoints(), other_pos.getIncludedPoints()

    clear : ->
      super
      @written_points = []
      @viewed_points = {}


    getIncludedPoints : (filter_to_existing = false) ->
      if !@included_points
        @included_points = if @get('point_inclusions') then $.parseJSON(@get('point_inclusions')) else []

      if filter_to_existing
        @included_points = _.filter @included_points, (pnt) -> App.request('point:get', pnt, false, null, false)
      @included_points

    includePoint : (point) ->
      included_points = @getIncludedPoints()
      included_points.push point.id

    removePoint : (point) ->
      if !@included_points
        throw 'Removing point without having defined included points first!'
      @included_points = _.without(@included_points, point.id)

    addViewedPoint : (point_id) ->
      @viewed_points[point_id] = 1
      

    # relations

    getInclusions : ->
      new App.Entities.Points (App.request('point:get', p) for p in @getIncludedPoints())

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id')
      @proposal

    getUser : ->
      App.request 'user', @get('user_id')

    setUser : (user) ->
      @set 'user_id', user.id
      if @written_points
        _.each @written_points, (pnt) =>
          pnt.set 'user_id', user.id      

    stanceLabel : ->
      Entities.Opinion.stance_name_adverb @get('stance_segment')

    @stance_name_for_bar : (d) ->
      switch parseInt(d)
        when 0 then "fully oppose"
        when 1 then "strongly oppose"
        when 2 then "lean oppose"
        when 3 then "are neutral"
        when 4 then "lean support"
        when 5 then "strongly support"
        when 6 then "fully support"

    @stance_name_adverb : (d) ->
      switch parseInt(d)
        when 0 then "fully opposes"
        when 1 then "strongly opposes"
        when 2 then "leans oppose on"
        when 3 then "is neutral about"
        when 4 then "leans support on"
        when 5 then "strongly supports"
        when 6 then "fully supports"

    @stance_name : (d) ->
      switch parseInt(d)
        when 0 then "strong opposers"
        when 1 then "opposers"
        when 2 then "mild opposers"
        when 3 then "neutral parties"
        when 4 then "mild supporters"
        when 5 then "supporters"
        when 6 then "strong supporters"

  class Entities.Opinions extends App.Entities.Collection
    model : Entities.Opinion

    parse : (models) ->
      if models instanceof Entities.Opinion
        # happens when new proposal is created, called by backbone.set
        opinions = [models] 
      else if !(models instanceof Array)
        opinions = ((o.opinion for o in models.opinions))
      else
        opinions = ((o.opinion for o in models))

      opinions


  API = 
    all_opinions : new Entities.Opinions()


    getOpinion : (opinion_id) ->
      @all_opinions.get opinion_id

    createOpinion : (opinion_attrs = {}) ->
      opinion = new Entities.Opinion opinion_attrs
      @all_opinions.add opinion
      opinion

    syncOpinion : (opinion, params = {}) -> 
      params = _.extend params, 
        included_points : opinion.getIncludedPoints(true)
        viewed_points : _.keys(opinion.viewed_points)
        opinion : 
          opinion.attributes

      method = if opinion.id then 'update' else 'create'

      xhr = Backbone.sync method, opinion,
        data : JSON.stringify params
        contentType : 'application/json'

        success : (data) =>
          proposal = opinion.getProposal()
          opinion.set data.opinion.opinion

          App.vent.trigger 'points:fetched', (p.point for p in data.updated_points)
          proposal.set(data.proposal) if 'proposal' of data

          if 'subsumed_opinion' of data && data.subsumed_opinion && data.subsumed_opinion.id != opinion.id
            App.vent.trigger 'opinion:subsumed', data.subsumed_opinion.opinion

          proposal.newOpinionSaved opinion

          # Mark all the written points by this user as published...
          # this is important for proper behavior when logging out and in
          opinion.getInclusions().each (pnt) ->
            if !pnt.get 'published'
              pnt.set 'published', true
            if !pnt.get 'user_id'
              pnt.set 'user_id', App.request('user:current').id

          #TODO: make sure points getting updated properly in all containers

          #TODO: check to make sure this case of newfound activity is handled
          # if @$el.attr('activity') == 'proposal-no-activity' && @model.has_participants()
          #   @$el.attr('activity', 'proposal-has-activity')

          opinion.trigger 'opinion:synced'


        failure : (data) => @trigger 'opinion:sync:failed'

      App.execute 'show:loading',
        loading:
          entities : xhr
          xhr: true


    addOpinions : (opinions) -> 
      opinions = @all_opinions.parse(opinions)
      @all_opinions.add opinions,
        merge: true

    getOpinionForProposalForCurrentUser : (long_id, create_if_not_found = true) ->
      current_user = App.request 'user:current'

      opinion = @all_opinions.findWhere
        long_id: long_id
        user_id: current_user.id

      if !opinion && create_if_not_found
        opinion = new Entities.Opinion
          user_id : current_user.id #todo: make sure this doesn't get shown in results
          published : false
          long_id: long_id 
          proposal_id : App.request('proposal:get', long_id).get('id')

        @all_opinions.add opinion

      opinion


    getOpinionsByProposal : (long_id) ->
      new Entities.Opinions @all_opinions.where({long_id: long_id, published : true})

    getOpinionsByUser : (user_id, published = true) ->
      params = 
        user_id : user_id

      if published
        params.published = true

      new Entities.Opinions @all_opinions.where params

    getOpinions : ->
      @all_opinions

    opinionSubsumed : (opinion_data) ->
      opinion = @all_opinions.get opinion_data.id
      if opinion
        #@all_opinions.remove opinion        
        opinion.trigger 'destroy', opinion, opinion.collection


  # provides this API
  App.reqres.setHandler 'opinion:get', (opinion_id) ->
    API.getOpinion opinion_id

  App.reqres.setHandler 'opinion:get_by_current_user_and_proposal', (long_id, create_if_not_found = true) ->
    API.getOpinionForProposalForCurrentUser long_id, create_if_not_found

  App.reqres.setHandler 'opinion:create', (attrs = {}) ->
    API.createOpinion attrs

  App.reqres.setHandler 'opinion:sync', (opinion, params) ->
    API.syncOpinion opinion, params

  App.reqres.setHandler 'opinions:get', ->
    API.getOpinions()

  App.reqres.setHandler 'opinions:get_by_proposal', (long_id) ->
    API.getOpinionsByProposal long_id

  App.reqres.setHandler 'opinions:get_by_user', (model_id, published = true) ->
    API.getOpinionsByUser model_id, published


  # subscribes to these events
  App.vent.on 'opinion:subsumed', (opinion_data) ->
    API.opinionSubsumed opinion_data

  App.vent.on 'opinions:fetched', (opinions) -> #, opinion = null) ->
    API.addOpinions opinions #, opinion


  App.addInitializer ->

    if ConsiderIt.opinions && _.size(ConsiderIt.opinions) > 0
      App.vent.trigger 'opinions:fetched', ConsiderIt.opinions
      ConsiderIt.opinions = null


