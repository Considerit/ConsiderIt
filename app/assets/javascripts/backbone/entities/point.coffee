@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Point extends App.Entities.Model
    name: 'point'

    initialize : (options = {}) ->
      super options

      #@attributes.nutshell = htmlFormat(@attributes.nutshell)
      @attributes.text = htmlFormat(@attributes.text)

    url : () ->
      if @id
        Routes.proposal_point_path @get('long_id'), @id
      else
        Routes.proposal_points_path @get('long_id') 

    parse : (response) ->
      if 'comments' of response
        @parseAssociated response

      if 'point' of response then response.point else {}

    parseAssociated : (data) ->
      comments = (co.comment for co in data.comments)
      App.vent.trigger 'comments:fetched', comments

      tenant = App.request('tenant:get')

      if tenant.get('assessment_enabled') && data.assessment
        App.request 'assessments:add', [data.assessment]
        App.request 'claims:add', (c.claim for c in data.claims)

        current_user = App.request 'user:current'
        if data.already_requested_assessment
          App.request 'assessment:request:add', {assessment_id : data.assessment.id, user_id : current_user.id}

        # App.vent.trigger 'assessment:client:fetched', 
        #   assessment : data.assessment
        #   claims : (c.claim for c in data.claims)
        #   num_requests : data.num_assessment_requests
        #   already_requested_assessment : data.already_requested_assessment

        #TODO: the pointview should listen for assessment:client:fetched
        # and pick up on the "already_requested_assessment" field
        #@already_requested_assessment = data.already_requested_assessment

    getIncluders : ->
      $.parseJSON @get 'includers'

    isPro : ->
      @get 'is_pro'

    has_details : -> attributes.text? && attributes.text.length > 0

    adjusted_nutshell : -> 
      nutshell = @get('nutshell')
      if nutshell.length > 140
        nutshell[0..140]
      else if nutshell.length > 0
        nutshell
      else if @get('text').length > 137 
        @get('text')[0..137] 
      else
        @get('text')

    #relations
    getUser : ->
      if !@user
        @user = App.request 'user', @get 'user_id'
      @user

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id') 
      @proposal

    getComments : ->
      if !@comments
        @comments = App.request 'comments:get:point', @id
      @comments

    getAssessment : ->
      if !@assessment
        @assessment = App.request 'assessment:get:point', @id
      @assessment


  class Entities.Points extends App.Entities.Collection
    model : Entities.Point

    parse : (attrs) ->
      attrs

  class Entities.PaginatedPoints extends App.Entities.PaginatedCollection
    model : Entities.Point

    state:
      pageSize: 3
      currentPage: 1

    initialize : (options = {}) ->
      @setPageSize options.perPage if 'perPage' of options

  API = 
    all_points : new Entities.Points

    getPoint : (id, fetch = false, long_id = null) ->
      point = @all_points.get(id) || new Entities.Point({id : id, long_id : long_id})
      if fetch
        point.fetch()
      point

    createPoint : (attrs, options = {wait: true}) ->
      point = @all_points.create attrs, options
      point

    addPoints : (points) ->
      @all_points.add @all_points.parse(points), {merge: true}

    getPointsBy : (filters = {}) ->
      if _.keys(filters).length > 0
        new Entities.Points @all_points.where filters
      else
        @all_points

    getPointsByUser : (user_id) ->
      @getPointsBy {user_id : user_id}

    getPointsByProposal : (proposal_id) ->
      points = @getPointsBy {proposal_id : proposal_id}
      points

  App.reqres.setHandler 'point:get', (id, fetch = false, proposal_id = null) ->
    API.getPoint id, fetch, proposal_id

  App.reqres.setHandler 'point:create', (attrs, options = {wait: true}) ->
    API.createPoint attrs, options

  App.vent.on 'points:fetched', (points) ->
    API.addPoints points

  App.reqres.setHandler 'points:get:user', (model_id) ->
    API.getPointsByUser model_id

  App.reqres.setHandler 'points:get:proposal', (model_id) ->
    API.getPointsByProposal model_id

  App.reqres.setHandler 'points:get', (filter = {}) ->
    API.getPointsBy filter



