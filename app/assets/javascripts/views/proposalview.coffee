
#######
# state
#  0 = unexpanded
#  1 = position
#  2 = results

class ConsiderIt.ProposalView extends Backbone.View
  @unexpanded_template: _.template( $("#tpl_unexpanded_proposal").html() )
  #@proposal_strip_template: _.template( $("#tpl_proposal_strip").html() )

  tagName : 'li'

  @editable_fields : _.union([ ['.m-proposal-description-title', 'name', 'text'], ['.m-proposal-description-body', 'description', 'textarea'] ], ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in ConsiderIt.Proposal.description_detail_fields ))

  initialize : (options) -> 
    #@state = 0
    super
    @long_id = @model.long_id
    @data_loaded = false

    ConsiderIt.router.on 'route:Root', => @transition_unexpanded() if @state > 0

    # @on 'point_details:closed', ->
    #   if @state == 2 || @state == 4
    #     ConsiderIt.router.navigate(Routes.proposal_path( @model.long_id ), {trigger: false})
    #   else if @state == 1
    #     ConsiderIt.router.navigate(Routes.new_position_proposal_path( @model.long_id ), {trigger: false})
    #   else if @state == 0
    #     ConsiderIt.router.navigate(Routes.proposal_path( @model.long_id ), {trigger: false})

  render : -> 
    @$el.html ConsiderIt.ProposalView.unexpanded_template($.extend({}, @model.attributes, {
        title : this.model.title()
        description_detail_fields : this.model.description_detail_fields()
        avatar : window.PaperClip.get_avatar_url(ConsiderIt.users[@model.get('user_id')], 'large')
        tile_size : Math.min 50, ConsiderIt.utils.get_tile_size(110, 55, @model.participants().length)
        participants : _.sortBy(@model.participants(), (user) -> !ConsiderIt.users[user].get('avatar_file_name')?  )

      }))

    results_el = $('<div class="m-proposal-message">')
    @results_view = new ConsiderIt.ResultsView
      el : results_el
      model : @model

    @results_view.render()
    results_el.insertAfter(@$el.find('.m-proposal-introduction'))
    @listenTo @results_view, 'results:implode_participants', => @set_state(2)
    @listenTo @results_view, 'results:explode_participants', => @set_state(4)


    if @model.get('published') #|| @can_edit()
      @position_view = new ConsiderIt.PositionView
        proposal : @model
        model : @model.position
        el : @$el

      position_el = @position_view.render()              
      position_el.insertAfter(results_el)

      #@listenTo @position_view, 'position:canceled', @show_results_handler
      @listenTo @position_view, 'positionview:submitted_position', @position_submitted
    else
      @$el.find('.m-proposal-description-body, .m-proposal-description-details').slideToggle()

    #TODO: if user logs in as admin, need to do this
    @render_admin_strip() if @can_edit()

    @transition_unexpanded()

    @$main_content_el = @$el.find('.m-proposal-body_wrap')

    this



  can_edit : ->
    ConsiderIt.current_user.id == @model.get('user_id') || ConsiderIt.roles.is_admin || ConsiderIt.roles.is_manager


  post_signout : () -> 
    @data_loaded = false
    @transition_unexpanded()


  take_position : () ->
    @transition_expanded(1)

  show_results : () ->
    @transition_expanded(2)

  show_results_handler : () -> 
    if @state == 4 #skip the transition if we're already on the results page
      @$hidden_els.css('display', 'none')
    else 
      @show_results()


  # TODO: This should be triggered on results opened & position opened
  transition_expanded : (new_state) =>
    @$el.css('display', '') if !@$el.is(':visible')
    if new_state == @state #can happen, e.g. when transitioning out of point details view
      @$hidden_els.css('display', 'none')
      return 

    callback = (new_state) =>
      if new_state == 1
        @results_view.hide()

        if @model.get('published')
          el = @position_view.show_crafting()
          el.insertAfter(@results_view.$el)
          el.fadeIn 500, =>
        @set_state(1)
      else if new_state == 2
        @results_view.show_explorer()
        @set_state(2)

    if @state > 0
      if new_state == 1
        #@results_view.show_summary()
      else if new_state == 2
        @position_view.close_crafting() if @model.get('published')

    else
      @scroll_position = @$el.offset().top - $('.t-intro-wrap').offset().top - parseInt(@$el.css('marginTop'))

      @$hidden_els = $("[data-role='m-proposal']:not([data-id='#{@model.id}']), [data-domain='homepage']")
      @$hidden_els.css('display', 'none')
      @$el.find('.m-proposal-description-body').slideDown()

      @$el.find('.m-proposal-description-details').slideDown()

    callback(new_state)
        

  transition_unexpanded : =>
    #$('body').animate {scrollTop: @scroll_position}, =>
      # TODO: remove strip at top
    ConsiderIt.router.navigate(Routes.root_path(), {trigger: false}) if Backbone.history.fragment != ''

    if @state > 0

      @$hidden_els.css 'display', ''
      $('body').scrollTop @scroll_position

      @position_view.close_crafting()
      @results_view.show_summary()

      #@$el.find('.m-proposal-connect').remove()

      if @pointdetailsview
        @pointdetailsview.remove()

      @$el.find('.m-proposal-description-body, .m-proposal-description-details').slideUp()

    $('body').animate {scrollTop: @scroll_position}
    @set_state(0)


  set_state : (new_state) ->
    @state = new_state
    @$el.attr('data-state', new_state)

  events : 
    'click .m-proposal-description' : 'toggle_description'
    'click .hidden' : 'show_details'
    'click .showing' : 'hide_details'

    #'click .m-proposal-follow_conversation' : 'toggle_follow_proposal'

    'click .m-proposal-admin_operations-status' : 'show_status'
    'click .m-proposal-admin_operations-publicity' : 'show_publicity'
    'ajax:complete .m-proposal-admin_operations-settings-form' : 'change_settings'
    'click .l-dialog-detachable a.cancel' : 'cancel_dialog'
    'ajax:complete .m-delete_proposal' : 'delete_proposal'

    'ajax:complete .m-proposal-publish-form' : 'publish_proposal'



  toggle_description : (ev) ->
    return if !@model.get('published') || (@state > 0 && ( $(ev.target).is('.editable') || $(ev.target).closest('.editable-container').length > 0))
    if @$el.is('[data-state="0"]')
      ConsiderIt.router.navigate(Routes.new_position_proposal_path( @model.long_id ), {trigger: true})
    else
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: true})

    # return if @can_edit() && $(ev.target).closest('.editable-click, .editable-inline').length > 0

    # @$el.find('.m-proposal-description-body, .m-proposal-description-details').slideToggle()

  show_details : (ev) -> 
    $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

    $block.find('.m-proposal-description-detail-field-full').slideDown();
    $block.find('.hidden')
      .text('hide')
      .toggleClass('hidden showing');

    ev.stopPropagation()

  hide_details : (ev) -> 
    $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

    $block.find('.m-proposal-description-detail-field-full').slideUp(1000);
    $block.find('.showing')
      .text('show')
      .toggleClass('hidden showing');      
    ev.stopPropagation()


  # Point details are being handled here (messily) for the case when a user directly visits the point details page without
  # (e.g. if they followed a link to it). In that case, we need to create some context around it first.
  prepare_for_point_details : (params) ->
    @listenToOnce @results_view, 'ResultsExplorer:rendered', => 
      pnt = parseInt(params.point_id)
      point = @model.pros.get(pnt)
      if !point
        point = @model.cons.get(pnt)

      results_explorer = @results_view.view
      pointlistview = if point.get('is_pro') then results_explorer.views.pros else results_explorer.views.cons
      pointview = pointlistview.getViewByModel(point) || pointlistview.addModelView(point) # this happens if the point is being directly visited, but is not on the front page of results

      pointview.show_point_details_handler() if pointview?
      $('body').animate {scrollTop: pointview.$el.offset().top - 50}, 200

    @show_results()

  prepare_for_static_position : (params) ->
    callback = (user_id) =>
      #me.static_position.close() if me.static_position
      @static_position = new ConsiderIt.StaticPositionView
        proposal : @model
        user_id : user_id
        el : @$el
      @static_position.render()

    if @state == 0
      @listenToOnce @position_view, 'PositionCrafting:rendered', => 
        callback(params.user_id)
      @take_position()    
    else
      callback(params.user_id)

  show_point_details_handler : (params) ->
    # only do this if user has navigated directly to the point
    @prepare_for_point_details(params) if params.data_just_loaded

  position_submitted : ->
    if @$el.data('activity') == 'proposal-no-activity' && @model.has_participants()
      @$el.attr('data-activity', 'proposal-has-activity')

  # TODO: move to its own view
  # ADMIN methods
  render_admin_strip : ->
    @$el.find('.m-proposal-admin_strip').remove()
    admin_strip_el = $('<div class="m-proposal-admin_strip m-proposal-strip">')
    template = _.template($('#tpl_proposal_admin_strip').html())
    admin_strip_el.html( template(@model.attributes))
    @$el.find('.m-proposal-body_wrap').append admin_strip_el 

    for field in ConsiderIt.ProposalView.editable_fields
      [selector, name, type] = field 
      @$el.find(selector).editable {
        resource: 'proposal'
        pk: @long_id
        url: Routes.proposal_path @model.long_id
        type: type
        name: name
        success : (response, new_value) => @model.set(name, new_value)
      }

  show_status : (ev) ->
    tpl = _.template( $('#tpl_proposal_admin_strip_edit_active').html() )
    @$el.find('.m-proposal-admin-status').append tpl(@model.attributes)

  show_publicity : (ev) ->
    tpl = _.template( $('#tpl_proposal_admin_strip_edit_publicity').html() )
    @$el.find('.m-proposal-admin-publicity').append tpl(@model.attributes)

  change_settings : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    @model.set({access_list: data.access_list, active: data.active, publicity: data.publicity})
    @render_admin_strip()

  cancel_dialog : (ev) ->
    $(ev.currentTarget).closest('.l-dialog-detachable').remove()

  delete_proposal : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    if data.success
      ConsiderIt.app.trigger('proposal:deleted', @model )

  publish_proposal : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    @model.set(data.proposal.proposal)
    @model.set_data
      position: data.position
      points: {}
    @model.long_id = @model.get('long_id')
    @data_loaded = true
    #@$el.attr('data-visibility', '')

    @render()
    ConsiderIt.router.navigate(Routes.new_position_proposal_path( @model.long_id ), {trigger: true} )
