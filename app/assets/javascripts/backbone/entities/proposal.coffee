@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Proposal extends App.Entities.Model
    name: 'proposal'
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


    description_detail_fields : ->
      [ ['additional_description1', 'Long Description', $.trim(htmlFormat(@attributes.additional_description1))], 
        ['additional_description2', 'Fiscal Impact Statement', $.trim(htmlFormat(@attributes.additional_description2))] ]

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
      if !@participant_list?
        @participant_list = $.parseJSON(@attributes.participants) || []
      @participant_list

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
      if !@positions
        @positions = App.request 'positions:get:proposal', @id
      @positions

    getPoints : ->
      if !@points
        @points = App.request 'points:get:proposal', @id
      @points

    updatePosition : (attrs) ->
      @getUserPosition().set attrs
      @getUserPosition

    setUserPosition : (position_id) ->
      @position = App.request 'position:get', position_id

    # TODO: refactor this method out...handles what happens when 
    # current user saves a new position
    newPositionSaved : (position) ->
      user_id = @position.get('user_id')
      if position.get('published') && !@user_participated(user_id)
        @positions = null
        @participant_list.push user_id 

    isActive : ->
      @get('active')


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
      pageSize: 5
      currentPage: 1

  API =
    all_proposals : new Entities.Proposals()
    proposals_fetched : false
    proposals_created : false
    total_active : 0
    total_inactive : 0


    bootstrapProposal : (proposal_attrs) ->
      proposal = @all_proposals.findWhere {long_id : proposal_attrs.proposal.long_id}
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
      else if fetch
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
      ['additional_description1', 'additional_description2']     

    areProposalsFetched : () ->
      @proposals_fetched
    
    addProposals : (proposals) ->
      @all_proposals.add @all_proposals.parse(proposals), {merge: true}

    bootstrapProposals : (proposals_attrs) ->      
      @all_proposals.set @all_proposals.parse proposals_attrs

    getProposals: (fetch = false) ->
      if fetch && !@proposals_fetched
        @all_proposals.fetch
          reset: true
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




