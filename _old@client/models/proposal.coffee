@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Proposal extends App.Entities.Model
    name: 'proposal'
    fetched: false
    idAttribute : 'long_id'
    defaults : 
      participants : '[]'
      active : true
      published : false

    initialize : (options = {}) ->
      super options
      #@long_id = @get 'long_id'
      #@on 'change:long_id', (model, value) -> model.long_id = value   

      if !@attributes.participants || @attributes.participants == ""
        @participant_list = []
      else            
        @participant_list = $.parseJSON(@attributes.participants)

    urlRoot : ''

    url : () ->
      if @id
        Routes.proposal_path @id
      else
        # for create
        Routes.proposals_path()

    parse : (response) ->
      if 'opinions' of response
        @parseAssociated response
        proposal_attrs = response.proposal
      else if 'proposal' of response
        proposal_attrs = response.proposal
      else
        proposal_attrs = response

      if 'access_list' of response
        proposal_attrs.access_list = response.access_list

      proposal_attrs

    parseAssociated : (params) ->
      @fetched = true

      App.vent.trigger 'points:fetched',
        (p.point for p in params.points)

      App.vent.trigger 'opinions:fetched', 
        (p for p in params.opinions) #, params.opinion.opinion

      #@setUserOpinion params.opinion.opinion.id

      # For users whose opinion is not yet in the database, and users whose opinion has
      # not been fully saved, we need to use other data besides that which is stored 
      # in the opinion to bring the opinion fully up to date. Only do this if
      # the proposal has already been created
      if !@isNew()
        opinion = @getUserOpinion()
        for p in params.included_points
          opinion.includePoint App.request('point:get', p.point.id)

      current_tenant = App.request 'tenant'
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
        my_title = "Unnamed or private"
      
      if my_title.length > max_len
        "#{my_title[0..max_len]}..."
      else
        my_title

    user_participated : (user_id) -> 
      user_id in @participants()

    participants : -> @participant_list

    has_participants : -> 
      return @participants().length > 0   

    num_participants : ->
      return @participants().length

    getParticipants : ->
      @all_participants = (App.request('user', u) for u in @participants())
      @all_participants

    # Relations
    getUser : ->
      user = App.request 'user', @get('user_id')
      user

    getUserOpinion : ->
      App.request 'opinion:get_by_current_user_and_proposal', @id

    getOpinions : ->
      App.request 'opinions:get_by_proposal', @id

    getPoints : ->
      App.request 'points:get_by_proposal', @id
      
    # updateOpinion : (attrs) ->
    #   @getUserOpinion().set attrs
    #   @getUserOpinion

    # setUserOpinion : (opinion_id) ->
    #   @opinion = App.request 'opinion:get', opinion_id

    # TODO: refactor this method out...handles what happens when 
    # current user saves a new opinion
    newOpinionSaved : (opinion) ->
      user_id = opinion.get('user_id')
      if opinion.get('published') 
        if !@user_participated(user_id)
          @participant_list.push user_id 

        if !@get('top_pro')
          _.each opinion.written_points, (pnt) =>
            @set('top_pro', pnt.id) if pnt.isPro()

        if !@get('top_con')
          _.each opinion.written_points, (pnt) =>
            @set('top_con', pnt.id) if !pnt.isPro()

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
      defaults = 
        title : "#{@get('category')||''} #{@get('designator')||''} #{@get('name')}"
        description : @get('name')
        keywords : "#{@get('category')||''} #{@get('designator')||''}"

      meta = 
        title : if @get('seo_title') then @get('seo_title') else defaults.title
        description : if @get('seo_description') then @get('seo_title') else defaults.description
        keywords : if @get('seo_keywords') then @get('seo_keywords') else defaults.keywords

      meta

  class Entities.Proposals extends App.Entities.Collection

    model : Entities.Proposal

    initialize : (options = {}) ->
      super options
      @listenTo App.vent, 'user:signout', => 
        @purge_inaccessible()

    url : ->
      Routes.proposals_path( )

    parse : (response) ->
      if response instanceof Entities.Proposal
        # happens when new proposal is created, called by backbone.set
        proposals = [response] 
      else if !(response instanceof Array)
        if 'points' of response
          App.vent.trigger 'points:fetched', response.points
        proposals = response.proposals
      else
        proposals = response

      proposals

    purge_inaccessible : -> 
      to_remove = @filter (p) -> 
        p.get('publicity') < 2 || !p.get('published')

      @remove to_remove


  class Entities.PaginatedProposals extends window.mixOf Entities.Proposals, App.Entities.PaginatedCollection 
    state:
      currentPage: 1

    initialize : (options = {}) ->
      @listenTo App.vent, 'user:signout', => 
        @purge_inaccessible()


  API =
    all_proposals : new Entities.Proposals()
    proposals_fetched : false
    proposals_created : false
    total_active : 0
    total_inactive : 0


    bootstrapProposal : (proposal_attrs) ->
      proposal = @all_proposals.get proposal_attrs.proposal.proposal.long_id
      if proposal        
        proposal.set proposal_attrs.proposal
      else
        proposal = API.newProposal proposal_attrs.proposal

      #TODO: DRY this out because it is repeated in parse()
      if 'access_list' of proposal_attrs
        proposal.set 'access_list', proposal_attrs.access_list


      proposal.parseAssociated proposal_attrs
      proposal
    
    getProposal: (long_id, fetch = false) ->
      proposal = @all_proposals.get long_id

      if !proposal
        proposal = API.newProposal {long_id : long_id}
        proposal.fetch()
      else if fetch && !proposal.fetched #don't double fetch, else end up with multiple user opinions
        proposal.fetch()
      proposal

    getProposalById: (id, fetch = false) ->
      throw 'Cannot get proposal without id' if !id
      proposal = @all_proposals.findWhere {id : id}
      if !proposal
        proposal = API.newProposal {id : id}
        proposal.fetch()
      else if fetch
        proposal.fetch()
      proposal

    newProposal: (attrs = {} ) ->
      proposal = new Entities.Proposal attrs
      @all_proposals.add proposal
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
          merge: true
          success : =>
            @proposals_fetched = true
            App.vent.trigger 'proposals:just_fetched_from_server'


      @all_proposals

    getProposalsByUser : (user_id) ->
      new Entities.Proposals @all_proposals.where({user_id : user_id})

    initializeTotalCounts : (total_active, total_inactive) ->
      @total_inactive = total_inactive
      @total_active = total_active

    getTotalCounts : ->
      [@total_active, @total_inactive]

    tenantUpdated : ->
      tenant = App.request 'tenant'
      if tenant.get('enable_hibernation')
        _.each @all_proposals.where({active : true}), (proposal) ->
          proposal.set 'active', false


  # provides this API
  App.reqres.setHandler "proposal:get", (long_id, fetch = false) ->
    API.getProposal long_id, fetch

  App.reqres.setHandler "proposal:bootstrap", (proposal_attrs) ->
    API.bootstrapProposal proposal_attrs

  App.reqres.setHandler "proposal:new", (attrs = {})->
    API.newProposal attrs

  App.reqres.setHandler "proposal:create", (attrs, options) ->
    API.createProposal(attrs, options)
  
  App.reqres.setHandler "proposal:get_description_fields", ->
    API.proposalDescriptionFields()

  App.reqres.setHandler "proposals:bootstrap", (proposals_attrs) ->
    API.bootstrapProposals proposals_attrs

  App.reqres.setHandler "proposals:get", (fetch = false) ->
    API.getProposals fetch

  App.reqres.setHandler "proposals:get_by_user", (model_id) ->
    API.getProposalsByUser model_id
    
  App.reqres.setHandler "proposals:fetched_from_server?", ->
    API.areProposalsFetched()

  App.reqres.setHandler 'proposals:totals', ->
    API.getTotalCounts()


  # subscribes to these events
  App.vent.on 'proposal:deleted', (model) ->
    API.removeProposal model

  App.vent.on "proposals:fetched", (proposals) ->
    API.addProposals proposals

  App.vent.on "tenant:updated", ->
    API.tenantUpdated()


  App.addInitializer ->

    if ConsiderIt.proposals
      App.request 'proposals:bootstrap', ConsiderIt.proposals
      API.initializeTotalCounts ConsiderIt.proposals.proposals_active_count, ConsiderIt.proposals.proposals_inactive_count

    if ConsiderIt.current_proposal
      App.request 'proposal:bootstrap', ConsiderIt.current_proposal
