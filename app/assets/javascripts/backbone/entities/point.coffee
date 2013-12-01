@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Point extends App.Entities.Model
    name: 'point'
    fetched: false

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
      @fetched = true
      comments = (co.comment for co in data.comments)
      thanks = (t.thank for t in data.thanks)
      App.vent.trigger 'comments:fetched', comments
      App.vent.trigger 'comments:thanks:fetched', thanks
 
      tenant = App.request 'tenant:get'

      if tenant.get 'assessment_enabled'
        current_user = App.request 'user:current'

        if data.assessment
          App.request 'assessments:add', [data.assessment]
          App.request 'verdicts:add', (v.verdict for v in data.verdicts)
          App.request 'claims:add', (c.claim for c in data.claims)


        if data.already_requested_assessment
          params = 
            assessable_id : @id
            assessable_type : 'Point'
            user_id : current_user.id
          if data.assessment
            _.extend params, 
              assessment_id : data.assessment.id

          App.request 'assessment:request:add', params

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
      App.request 'user', @get 'user_id'

    getProposal : ->
      if !@proposal
        @proposal = App.request 'proposal:get', @get('long_id') 
      @proposal

    getComments : ->
      App.request 'comments:get:point', @id

    getAssessment : ->
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

    bootstrapPoint : (data) ->
      point = new Entities.Point data.point.point
      point.parse data.associated
      @all_points.add point

    getPoint : (id, fetch = false, long_id = null) ->
      point = @all_points.get(id) || new Entities.Point({id : id, long_id : long_id})
      if fetch && !point.fetched
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

    getPointsByProposal : (long_id) ->
      points = @getPointsBy {long_id : long_id}
      points

    getTopPointsByProposal : (long_id) ->
      proposal = App.request 'proposal:get', long_id
      top_pro = if proposal.get('top_pro') then @getPoint proposal.get('top_pro'), false, long_id else null
      top_con = if proposal.get('top_con') then @getPoint proposal.get('top_con'), false, long_id else null

      new Entities.Points _.compact([top_pro, top_con])

  App.reqres.setHandler 'point:bootstrap', (data) ->
    API.bootstrapPoint data

  App.reqres.setHandler 'point:get', (id, fetch = false, proposal_id = null) ->
    API.getPoint id, fetch, proposal_id

  App.reqres.setHandler 'point:create', (attrs, options = {wait: true}) ->
    API.createPoint attrs, options

  App.vent.on 'points:fetched', (points) ->
    API.addPoints points

  App.reqres.setHandler 'points:get:user', (model_id) ->
    API.getPointsByUser model_id

  App.reqres.setHandler 'points:get:proposal', (long_id) ->
    API.getPointsByProposal long_id

  App.reqres.setHandler 'points:get:proposal:top', (long_id) ->
    API.getTopPointsByProposal long_id

  App.reqres.setHandler 'points:get', (filter = {}) ->
    API.getPointsBy filter


  App.addInitializer ->
    if ConsiderIt.current_point
      App.request 'point:bootstrap', ConsiderIt.current_point
      ConsiderIt.current_point = null
