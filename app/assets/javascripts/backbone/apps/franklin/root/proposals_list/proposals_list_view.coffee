@ConsiderIt.module "Franklin.Root.ProposalsList", (ProposalsList, App, Backbone, Marionette, $, _) ->

  class ProposalsList.ProposalsRegionLayout extends App.Views.Layout
    template: '#tpl_proposals_region_layout'

    regions: 
      activeRegion : '#m-proposals-container'
      pastRegion : '#m-proposals-container-completed'

  class ProposalsList.ProposalsListLayout extends App.Views.Layout
    template: '#tpl_proposals_list_layout'
    
    regions: 
      createRegion : '.m-proposals-create'
      proposalsRegion : '.m-proposal-list-region'
      filtersRegion : '.m-proposals-filters'
      paginationRegion : '.m-proposals-list-pagination'

  class ProposalsList.CreateProposalView extends App.Views.ItemView
    template: '#tpl_proposals_list_create'

    events :
      'click .m-new-proposal-submit' : 'createNewProposal'

    createNewProposal : (ev) ->
      @trigger 'proposal:new:requested'


  class ProposalsList.FilterView extends App.Views.ItemView
    template: '#tpl_proposals_list_filters'
    sort_by : 'activity'

    initialize : (options = {}) ->
      super options
      @listenTo @collection, 'reset', =>
        @updateSelectedFilter()

    serializeData : ->
      sortable_fields : [ 
        {name: 'Most active', target: 'activity'}, 
        {name: 'Newness', target: 'created_at'} ]

    updateSelectedFilter : ->
      @$el.find(".m-proposallist-sort.selected").removeClass 'selected'      
      @$el.find("[data-target='#{@sort_by}']").addClass 'selected'

    onShow : ->
      @updateSelectedFilter()      

    events :
      'click .m-proposallist-sort' : 'sortProposalsTo'

    sortProposalsTo : (ev) ->  
      sort_by = $(ev.target).data('target')
      @trigger 'sort:requested', sort_by
      @sort_by = sort_by
      #window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))


  class ProposalsList.PaginationView extends App.Views.ItemView
    template: '#tpl_proposal_list_pagination'

    initialize : (options = {} ) ->
      super options
      @listenTo @collection, 'reset add remove', =>
        @render()

    serializeData : ->
      _.extend {}, @collection.state,
        page_set : (page for page in [@collection.state.firstPage..@collection.state.lastPage])
        data_loaded : App.request "proposals:are_fetched"
        prompt: if @options.is_active then "Show more ongoing conversations" else "Show past conversations"

    events : 
      'click .m-pointlist-pagination-showmore' : 'showMoreRequested'
      'click [data-target="proposallist:first"]' : 'gotoFirst'
      'click [data-target="proposallist:prev"]' : 'gotoPrev'
      'click [data-target="proposallist:next"]' : 'gotoNext'
      'click [data-target="proposallist:last"]' : 'gotoLast'
      'click [data-target="proposallist:page"]' : 'gotoPage'

    showMoreRequested : (ev) ->
      @trigger 'pagination:show_more'

    gotoFirst : (ev) ->
      ev.preventDefault()
      @collection.getFirstPage()
      # window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))

    gotoPrev : (ev) ->
      ev.preventDefault()
      @collection.getPreviousPage()
      # window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))

    gotoNext : (ev) ->
      ev.preventDefault()
      @collection.getNextPage()
      # window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))

    gotoLast : (ev) ->
      ev.preventDefault()
      @collection.getLastPage()
      # window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))

    gotoPage : (ev) ->
      ev.preventDefault()
      page = $(ev.target).data('page')

      @collection.getPage(page)
      # window.ensure_el_in_view(@$el.find('.m-proposals-list-pagination'))


  class ProposalsList.ProposalStatusDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_active'

    dialog:
      title : 'Set the status of this proposal.'

    serializeData : ->
      _.extend {}, @model.attributes

    events : 
      'ajax:complete .m-proposal-admin_operations-settings-form' : 'changeSettings'

    changeSettings : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'proposal:updated', data

  class ProposalsList.ProposalPublicityDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_publicity'

    dialog:
      title : 'Who can view and participate?'

    serializeData : ->
      _.extend {}, @model.attributes

    changeSettings : (ev, response ,options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:updated', data


  class ProposalsList.ProposalSummaryView extends App.Views.ItemView
    template : '#tpl_proposal_summary'
    tagName: 'li'
    className : 'm-proposal'

    serializeData : ->
      user = App.request 'user', @model.get('user_id')
      
      params = _.extend {}, @model.attributes, 
        description_detail_fields : @model.description_detail_fields()
        avatar : App.request('user:avatar', user, 'large' )
        tile_size : Math.min 50, ConsiderIt.utils.get_tile_size(110, 55, @model.participants().length)
        participants : _.sortBy(@model.participants(), (user) -> !App.request('user', user).get('avatar_file_name')?  )

      params

    onRender : ->
      @stickit()

    onShow : ->

    bindings : 
      '.m-proposal-description-title' : 
        observe : ['name', 'description']
        onGet : (values) -> @model.title()
      '.m-proposal-description-body' : 
        observe : 'description'
        updateMethod: 'html'
        onGet : (value) => htmlFormat(value)

    transitionCreated : ->
      @$el.find('.m-proposal-description').trigger('click')
      @$el.attr('data-visibility', 'unpublished')

  class ProposalsList.ModifiableProposalSummaryView extends ProposalsList.ProposalSummaryView
    admin_template : '#tpl_proposal_admin_strip'

    initialize : (options = {} ) ->
      super options

      if !ProposalsList.ModifiableProposalSummaryView.editable_fields
        fields = [
          ['.m-proposal-description-title', 'name', 'textarea'], 
          ['.m-proposal-description-body', 'description', 'textarea'] ]

        editable_fields = _.union fields,
          ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in App.request('proposal:description_fields'))          

        ProposalsList.ModifiableProposalSummaryView.editable_fields = editable_fields

      @editable_fields = ProposalsList.ModifiableProposalSummaryView.editable_fields


    onShow : (options = {}) ->
      super options
      if !ModifiableProposalSummaryView.compiled_admin_template?
        ModifiableProposalSummaryView.compiled_admin_template = _.template($(@admin_template).html())

      params = _.extend {}, @model.attributes
      @$admin_el = ModifiableProposalSummaryView.compiled_admin_template params
      @$el.append @$admin_el

      _.each @editable_fields, (field) =>
        [selector, name, type] = field 

        @$el.find(selector).editable
          resource: 'proposal'
          pk: @long_id
          disabled: @state == 0 && @model.get('published')
          url: Routes.proposal_path @model.long_id
          type: type
          name: name
          success : (response, new_value) => @model.set(name, new_value)

      #TODO: can this just be removed???          
      # else if @has_been_admin_in_past
      #   for field in ConsiderIt.ProposalView.editable_fields
      #     [selector, name, type] = field 
      #     @$el.find(selector).editable('disable')



    events : 
      'ajax:complete .m-delete_proposal' : 'deleteProposal'
      'click .m-proposal-admin_operations-status' : 'showStatus'
      'click .m-proposal-admin_operations-publicity' : 'showPublicity'
      'ajax:complete .m-proposal-publish-form' : 'publishProposal'

    showStatus : (ev) ->
      @trigger 'status_dialog'

    showPublicity : (ev) ->
      @trigger 'publicity_dialog'

    deleteProposal : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      if data.success
        @trigger 'proposal:deleted', @model
        toastr.success 'Successfully deleted'
      else
        toastr.error 'Failed to delete'

    publishProposal : (ev, response, options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:published', data.proposal.proposal, data.position


  class ProposalsList.ProposalsListView extends App.Views.CompositeView
    template: '#tpl_proposals_list'
    itemViewContainer : 'ul.m-proposal-list' 

    initialize : (options = {}) ->
      super options

    serializeData : ->
      is_active : @is_active

    buildItemView : (proposal) ->
      if App.request "auth:can_edit_proposal", proposal
        view_cls = ProposalsList.ModifiableProposalSummaryView
      else
        view_cls = ProposalsList.ProposalSummaryView

      model = new view_cls
        model: proposal
        class : 'm-proposal'
        attributes : 
          'data-id': "#{proposal.id}"
          'data-role': 'm-proposal'
          'data-activity': if proposal.has_participants() then 'proposal-has-activity' else 'proposal-no-activity'
          'data-status': if proposal.get('active') then 'proposal-active' else 'proposal-inactive'
          'data-visibility': if proposal.get('published') then 'published' else 'unpublished'

      model

  class ProposalsList.ActiveProposalsList extends ProposalsList.ProposalsListView
    is_active : true

    prepareNewProposal : (proposal) ->
      childview = @children.findByModel proposal
      childview.transitionCreated()


  class ProposalsList.PastProposalsList extends ProposalsList.ProposalsListView
    is_active : false




