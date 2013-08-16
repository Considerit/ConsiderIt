@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Proposal extends App.Entities.Model
    name: 'proposal'
    defaults : 
      participants : '[]'

    initialize : (options = {}) ->
      super options
      @long_id = @attributes.long_id
      [@top_pro, @top_con] = App.request 'proposal:top_points', [@get('top_pro'), @get('top_con')]

    urlRoot : ''

    url : () ->
      if @id
        Routes.proposal_path( @attributes.long_id ) 
      else
        # for create
        Routes.proposals_path()

    parse : (response) ->
      if 'positions' of response
        @parseAssociated response
      return response.proposal

    parseAssociated : (params) ->
      @points = params.points

      App.vent.trigger 'positions:fetched', 
        (p.position for p in params.positions), params.position.position

      @setUserPosition params.position.position.id

    user_participated : (user_id) -> user_id in @participants()

    participants : ->
      if !@participant_list?
        @participant_list = $.parseJSON(@attributes.participants) || []
      @participant_list

    has_participants : -> 
      return @participants().length > 0   

    description_detail_fields : ->
      [ ['long_description', 'Long Description', $.trim(htmlFormat(@attributes.long_description))], 
        ['additional_details', 'Fiscal Impact Statement', $.trim(htmlFormat(@attributes.additional_details))] ]

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

    # Relations
    getUser : ->
      App.request 'user', @get('user_id')

    getUserPosition : ->
      @position

    getPositions : ->
      if !@positions
        @positions = App.request 'positions:get:proposal', @id
      @positions

    setUserPosition : (position_id) ->
      @position = App.request 'position:get', position_id


  class Entities.Proposals extends App.Entities.Collection

    model : Entities.Proposal

    initialize : (options = {}) ->
      super options
      @listenTo ConsiderIt.vent, 'user:signout', => 
        @purge_inaccessible()      

    url : ->
      Routes.proposals_path( )

    parse : (response) ->
      @top_points = response.top_points
      proposals = response.proposals
      proposals

    topPoints : (points) ->
      (if pnt of @top_points then @top_points[pnt].point else null for pnt in points)

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


    bootstrapProposal : (proposal_attrs) ->
      proposal = @all_proposals.findWhere {long_id : long_id}
      if proposal
        proposal.set proposal_attrs.proposal
      else
        API.newProposal proposal_attrs.proposal
      proposal.parseAssociated proposal_attrs
    
    getProposal: (long_id) ->
      proposal = @all_proposals.findWhere {long_id : long_id}
      if !proposal
        proposal = API.newProposal {long_id : long_id}
        proposal.fetch()
  
      proposal
    
    newProposal: (attrs = {}, add_to_all = true ) ->
      proposal = new Entities.Proposal attrs
      @all_proposals.add proposal if add_to_all

    createProposal: (attrs, options) ->
      proposal = @all_proposals.create attrs, options
      proposal

    removeProposal: (model) ->
      @all_proposals.remove model
  
    topPoints : (points) ->
      @all_proposals.topPoints points

    proposalDescriptionFields : ->
      ['long_description', 'additional_details']     

    areProposalsFetched : () ->
      @proposals_fetched
    

    #TODO: harmonize addProposals and bootstrapProposals
    addProposals : (proposals) ->
      @all_proposals.set proposals

    bootstrapProposals : (proposals_attrs) ->
      @all_proposals.top_points = proposals_attrs.top_points if 'top_points' of proposals_attrs
      @all_proposals.set (prop.proposal for prop in proposals_attrs.proposals) 

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


  App.reqres.setHandler "proposal:bootstrap", (proposal_attrs) ->
    API.bootstrapProposal proposal_attrs

  App.reqres.setHandler "proposal:get", (long_id) ->
    API.getProposal long_id
  
  App.reqres.setHandler "proposal:new", (attrs = {}, add_to_all = true)->
    API.newProposal attrs, add_to_all

  App.reqres.setHandler "proposal:create", (attrs, options) ->
    API.createProposal(attrs, options)

  App.reqres.setHandler "proposal:top_points", (points) ->
    API.topPoints points
  
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


  App.addInitializer ->
    if ConsiderIt.proposals
      API.bootstrapProposals ConsiderIt.proposals

    if ConsiderIt.current_proposal
      API.bootstrapProposal ConsiderIt.current_proposal




