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
        Routes.point_path @id
      else
        Routes.points_path()

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
 
      tenant = App.request 'tenant'

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
      console.log @attributes
      App.request 'user', @get('user').substring(6, @get('user').length)

    getProposal : ->
      if !@proposal
        proposal_id = @get('proposal').substring(10, @get('proposal').length)
        @proposal = App.request 'proposal:get_by_id', parseInt(proposal_id)
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

    getPoint : (id, fetch = false, long_id = null, create_if_doesnt_exist = true) ->
      point = @all_points.get(id) || if create_if_doesnt_exist then new Entities.Point({id : id, long_id : long_id}) else null
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

    getPointsByUser : (user_id, published = true) ->
      params = 
        user_id : user_id
      if published
        params.published = true
      @getPointsBy params

    getPointsByProposal : (long_id) ->
      points = @getPointsBy {long_id : long_id}
      points

    getTopPointsByProposal : (long_id) ->
      proposal = App.request 'proposal:get', long_id
      # top_pro = if proposal.get('top_pro') then @getPoint proposal.get('top_pro'), false, long_id else null
      # top_con = if proposal.get('top_con') then @getPoint proposal.get('top_con'), false, long_id else null

      new Entities.Points _.compact([top_pro, top_con])

  # provides this API
  App.reqres.setHandler 'point:bootstrap', (data) ->
    API.bootstrapPoint data

  App.reqres.setHandler 'point:get', (id, fetch = false, proposal_id = null, create_if_doesnt_exist = true) ->
    API.getPoint id, fetch, proposal_id, create_if_doesnt_exist

  App.reqres.setHandler 'point:create', (attrs, options) ->
    _.defaults options, 
      wait : true
    API.createPoint attrs, options

  App.reqres.setHandler 'points:get', (filter = {}) ->
    API.getPointsBy filter

  App.reqres.setHandler 'points:get_by_user', (model_id, published = true) ->
    API.getPointsByUser model_id, published

  App.reqres.setHandler 'points:get_by_proposal', (long_id) ->
    API.getPointsByProposal long_id

  App.reqres.setHandler 'points:get_top_points_for_proposal', (long_id) ->
    API.getTopPointsByProposal long_id

  # subscribes to these events
  App.vent.on 'points:fetched', (points) ->
    API.addPoints points


  App.addInitializer ->
    if ConsiderIt.current_point
      App.request 'point:bootstrap', ConsiderIt.current_point
      ConsiderIt.current_point = null
