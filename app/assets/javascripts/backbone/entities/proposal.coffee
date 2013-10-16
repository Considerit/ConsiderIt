@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Proposal extends App.Entities.Model
    name: 'proposal'
    fetched: false
    defaults : 
      participants : '[]'
      active : true
      published : false

    initialize : (options = {}) ->
      super options
      @long_id = @get 'long_id'
      @on 'change:long_id', (model, value) -> model.long_id = value      

    urlRoot : ''

    url : () ->
      if @long_id
        Routes.proposal_path( @attributes.long_id ) 
      else
        # for create
        Routes.proposals_path()

    parse : (response) ->
      if 'positions' of response
        @parseAssociated response
        proposal_attrs = response.proposal.proposal
      else
        proposal_attrs = response.proposal

      proposal_attrs

    parseAssociated : (params) ->
      @fetched = true

      App.vent.trigger 'points:fetched',
        (p.point for p in params.points)

      App.vent.trigger 'positions:fetched', 
        (p.position for p in params.positions), params.position.position

      @setUserPosition params.position.position.id

      position = @getUserPosition()
      position.setIncludedPoints (p.point.id for p in params.included_points)

      current_tenant = App.request 'tenant:get'
      if current_tenant.get 'assessment_enabled'
        App.request 'assessments:add', (a.assessment for a in params.assessments)
        App.request 'claims:add', (c.claim for c in params.claims)
        App.request 'verdicts:add', (v.verdict for v in params.verdicts)



    #TODO: make this general beyond LVG
    description_detail_fields : ->
      [ ['additional_description1', 'Long Description', $.trim(htmlFormat(@attributes.additional_description1))], 
        ['additional_description2', 'Fiscal Impact Statement', $.trim(htmlFormat(@attributes.additional_description2))],
        ['additional_description3', 'Resources curated by Seattle Public Library', $.trim(htmlFormat(@attributes.additional_description3))] ]

    title : (max_len = 140) ->
      if @get('name') && @get('name').length > 0
        my_title = @get 'name'
      else if @get 'description'
        my_title = @get 'description'
      else
        throw 'Name and description nil'
      
      if my_title.length > max_len
        "#{my_title[0..max_len]}..."
      else
        my_title

    user_participated : (user_id) -> 
      user_id in @participants()

    participants : ->
      if !@attributes.participants || @attributes.participants == ""
        @participant_list = []
      else 
        @participant_list = $.parseJSON(@attributes.participants)


    has_participants : -> 
      return @participants().length > 0   

    getParticipants : ->
      if !@all_participants
        @all_participants = (App.request('user', u) for u in @participants())

      @all_participants


    # Relations
    getUser : ->
      user = App.request 'user', @get('user_id')
      user

    getUserPosition : ->
      if !@position
        null
      else
        @position

    getPositions : ->
      App.request 'positions:get:proposal', @id

    getPoints : ->
      App.request 'points:get:proposal', @id
      
    # updatePosition : (attrs) ->
    #   @getUserPosition().set attrs
    #   @getUserPosition

    setUserPosition : (position_id) ->
      @position = App.request 'position:get', position_id

    # TODO: refactor this method out...handles what happens when 
    # current user saves a new position
    newPositionSaved : (position) ->
      user_id = @position.get('user_id')
      if position.get('published') 

        if !@user_participated(user_id)
          @positions = null
          @participant_list.push user_id 

        if !@get('top_pro')
          _.each position.written_points, (pnt) =>
            if pnt.isPro()
              @set('top_pro', pnt.id)
        if !@get('top_con')
          _.each position.written_points, (pnt) =>
            if !pnt.isPro()
              @set('top_con', pnt.id)

    isActive : ->
      @get('active')

    #TODO: refactor this out into "tagged" model
    getTags : ->
      if tags = @get('tags')
        _.compact tags.split(';')
      else
        []

    getTagsByType : (type) ->
      tags = @getTags()
      tags = (t.split(':')[1] for t in tags when t.split(':')[0] == type)
      tags ||= []      
      tags = tags[0] if tags.length == 1
      tags

    openToPublic : ->
      @get('publicity') > 0 && @get('published')

    getMeta : ->
      meta = 
        title : if @get('seo_title') then @get('seo_title') else "Discuss #{@get('category')} #{@get('designator')} #{@get('name')}: #{@get('name')}"
        description : if @get('seo_description') then @get('seo_title') else "Think through and discuss #{@get('category')} #{@get('designator')} - #{@get('name')}."
        keywords : if @get('seo_keywords') then @get('seo_keywords') else "#{@get('category')} #{@get('designator')}"

      meta

  class Entities.Proposals extends App.Entities.Collection

    model : Entities.Proposal

    initialize : (options = {}) ->
      super options
      @listenTo ConsiderIt.vent, 'user:signout', => 
        @purge_inaccessible()      

    url : ->
      Routes.proposals_path( )

    parse : (response) ->
      if !(response instanceof Array)
        if 'top_points' of response
          App.vent.trigger 'points:fetched', (p.point for p in response.top_points)
        proposals = response.proposals
      else
        proposals = response

      proposals

    purge_inaccessible : -> 
      @remove @filter (p) -> 
        p.get('publicity') < 2 || !p.get('published')


  class Entities.PaginatedProposals extends window.mixOf Entities.Proposals, App.Entities.PaginatedCollection 
    state:
      currentPage: 1

    initialize : ->
      @state.pageSize = App.request('tenant:get').get('num_proposals_per_page')

  API =
    all_proposals : new Entities.Proposals()
    proposals_fetched : false
    proposals_created : false
    total_active : 0
    total_inactive : 0


    bootstrapProposal : (proposal_attrs) ->
      proposal = @all_proposals.findWhere {long_id : proposal_attrs.proposal.proposal.long_id}
      if proposal
        proposal.set proposal_attrs.proposal
      else
        proposal = API.newProposal proposal_attrs.proposal
      proposal.parseAssociated proposal_attrs
      proposal
    
    getProposal: (long_id, fetch = false) ->
      proposal = @all_proposals.findWhere {long_id : long_id}

      if !proposal
        proposal = API.newProposal {long_id : long_id}
        proposal.fetch()
      else if fetch && !proposal.fetched #don't double fetch, else end up with multiple user positions
        proposal.fetch()
      proposal

    getProposalById: (id, fetch = false) ->
      proposal = @all_proposals.get id
      if !proposal
        proposal = API.newProposal {long_id : long_id}
        proposal.fetch()
      else if fetch
        proposal.fetch()
      proposal

    newProposal: (attrs = {}, add_to_all = true ) ->
      proposal = new Entities.Proposal attrs
      @all_proposals.add proposal if add_to_all
      proposal

    createProposal: (attrs, options) ->
      proposal = @all_proposals.create attrs, options
      proposal

    removeProposal: (model) ->
      @all_proposals.remove model
  
    proposalDescriptionFields : ->
      ['additional_description1', 'additional_description2', 'additional_description3']     

    areProposalsFetched : () ->
      @proposals_fetched
    
    addProposals : (proposals) ->
      @all_proposals.add @all_proposals.parse(proposals), {merge: true}
      App.vent.trigger 'proposals:added'

    bootstrapProposals : (proposals_attrs) ->  
      @all_proposals.set @all_proposals.parse proposals_attrs

    getProposals: (fetch = false) ->
      if fetch && !@proposals_fetched
        @all_proposals.fetch
          remove: false

        @proposals_fetched = true

        App.execute "when:fetched", @all_proposals, ->
          App.vent.trigger 'proposals:fetched:done'

      @all_proposals

    getProposalsByUser : (user_id) ->
      new Entities.Proposals @all_proposals.where({user_id : user_id})

    initializeTotalCounts : (total_active, total_inactive) ->
      @total_inactive = total_inactive
      @total_active = total_active

    getTotalCounts : ->
      [@total_active, @total_inactive]


  App.reqres.setHandler "proposal:bootstrap", (proposal_attrs) ->
    API.bootstrapProposal proposal_attrs

  App.reqres.setHandler "proposal:get", (long_id, fetch = false) ->
    API.getProposal long_id, fetch

  App.reqres.setHandler "proposal:get:id", (id, fetch = false) ->
    API.getProposalById id, fetch

  App.reqres.setHandler "proposal:new", (attrs = {}, add_to_all = true)->
    API.newProposal attrs, add_to_all

  App.reqres.setHandler "proposal:create", (attrs, options) ->
    API.createProposal(attrs, options)
  
  App.reqres.setHandler "proposal:description_fields", ->
    API.proposalDescriptionFields()

  App.vent.on 'proposal:deleted', (model) ->
    API.removeProposal model

  App.vent.on "proposals:fetched", (proposals) ->
    API.addProposals proposals

  App.reqres.setHandler "proposals:bootstrap", (proposals_attrs) ->
    API.bootstrapProposals proposals_attrs

  App.reqres.setHandler "proposals:get", (fetch = false) ->
    API.getProposals fetch

  App.reqres.setHandler "proposals:get:user", (model_id) ->
    API.getProposalsByUser model_id
    
  App.reqres.setHandler "proposals:are_fetched", ->
    API.areProposalsFetched()

  App.reqres.setHandler 'proposals:totals', ->
    API.getTotalCounts()


  App.addInitializer ->

    if ConsiderIt.proposals
      App.request 'proposals:bootstrap', ConsiderIt.proposals
      API.initializeTotalCounts ConsiderIt.proposals.proposals_active_count, ConsiderIt.proposals.proposals_inactive_count

    if ConsiderIt.current_proposal
      App.request 'proposal:bootstrap', ConsiderIt.current_proposal




