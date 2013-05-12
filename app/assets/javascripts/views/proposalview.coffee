
#######
# state
#  0 = unexpanded
#  1 = position
#  2 = results

class ConsiderIt.ProposalView extends Backbone.View
  @unexpanded_template: _.template( $("#tpl_unexpanded_proposal").html() )
  @proposal_strip_template: _.template( $("#tpl_proposal_strip").html() )

  tagName : 'li'

  @editable_fields : _.union([ ['.m-proposal-description-title', 'name', 'text'], ['.m-proposal-description-body', 'description', 'textarea'] ], ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in ConsiderIt.Proposal.description_detail_fields() ))

  initialize : (options) -> 
    #@state = 0
    @long_id = @model.get('long_id')
    @proposal = ConsiderIt.proposals[@long_id]
    @data_loaded = false

    @on 'point_details:closed', ->
      if @state == 2
        ConsiderIt.router.navigate(Routes.proposal_path( @proposal.model.get('long_id') ), {trigger: false})
      else if @state == 1
        ConsiderIt.router.navigate(Routes.new_position_proposal_path( @proposal.model.get('long_id') ), {trigger: false})
      else if @state == 0
        ConsiderIt.router.navigate(Routes.proposal_path( @proposal.model.get('long_id') ), {trigger: false})

  
  render : -> 

    @$el.html ConsiderIt.ProposalView.unexpanded_template($.extend({}, @model.attributes, {
        title : this.model.title()
        description_detail_fields : this.model.description_detail_fields()
        avatar : window.PaperClip.get_avatar_url(ConsiderIt.users[@model.get('user_id')], 'original')
        tile_size : Math.min 50, ConsiderIt.utils.get_tile_size(110, 55, ($.parseJSON(@model.get('participants'))||[]).length)
        participants : _.sortBy($.parseJSON(@model.get('participants')), (user) -> !ConsiderIt.users[user].get('avatar_file_name')?  )

      }))

    results_el = $('<div class="m-proposal-message">')
    @proposal.views.results = new ConsiderIt.ResultsView
      el : results_el
      proposal : @proposal
      model : @model

    @proposal.views.results.render()
    results_el.insertAfter(@$el.find('.m-proposal-introduction'))

    if @model.get('published')
      @proposal.views.take_position = new ConsiderIt.PositionView
        proposal : @proposal
        model : @proposal.position
        el : @$el

      position_el = @proposal.views.take_position.render()              
      position_el.insertAfter(results_el)

    @transition_unexpanded()

    @$main_content_el = @$el.find('.m-proposal-body_wrap')

    this

  set_data : (data) =>
    _.extend(@proposal, {
      points : {
        pros : _.map(data.points.pros, (pnt) -> new ConsiderIt.Point(pnt.point))
        cons : _.map(data.points.cons, (pnt) -> new ConsiderIt.Point(pnt.point))
        included_pros : new ConsiderIt.PointList()
        included_cons : new ConsiderIt.PointList()
        peer_pros : new ConsiderIt.PaginatedPointList()
        peer_cons : new ConsiderIt.PaginatedPointList()
        viewed_points : {}    
        written_points : []
      }
      positions : _.object(_.map(data.positions, (pos) -> [pos.position.user_id, new ConsiderIt.Position(pos.position)]))
      position : new ConsiderIt.Position(data.position.position)
    })
    
    @proposal.positions[@proposal.position.user_id] = @proposal.position
    @proposal.views.take_position.set_model @proposal.position

    # separating points out into peers and included
    for [source_points, source_included, dest_included, dest_peer] in [[@proposal.points.pros, data.points.included_pros, @proposal.points.included_pros, @proposal.points.peer_pros], [@proposal.points.cons, data.points.included_cons, @proposal.points.included_cons, @proposal.points.peer_cons]]
      indexed_inclusions = _.object( ([pnt.point.id, true] for pnt in source_included)  )
      peers = []
      included = []
      for pnt in source_points
        if pnt.id of indexed_inclusions
          included.push(pnt)
        else
          peers.push(pnt)

      dest_peer.reset(peers)
      dest_included.reset(included)

    @data_loaded = true
    @listenTo ConsiderIt.app, 'user:signin', @post_signin
    @listenTo ConsiderIt.app, 'user:signout', @post_signout
    @trigger 'proposal:data_loaded'


  load_data : (callback, callback_params) ->
    @once 'proposal:data_loaded', => callback(this, callback_params)
    if ConsiderIt.current_proposal && ConsiderIt.current_proposal.long_id == @long_id
      @set_data(ConsiderIt.current_proposal.data)
    else
      $.get Routes.proposal_path(@long_id), @set_data


  merge_existing_position_into_current : (existing_position) ->
    existing_position.subsume(@proposal.position)
    @proposal.position.set(existing_position.attributes)
    @proposal.positions[ConsiderIt.current_user.id] = @proposal.position
    delete @proposal.positions[-1]

    # transfer already included points from existing_position into the included lists
    for pnt_id in $.parseJSON(existing_position.get('point_inclusions'))
      if (model = @proposal.points.peer_pros.remove_from_all(pnt_id))?
        @proposal.points.included_pros.add model
      else if (model = @proposal.points.peer_cons.remove_from_all(pnt_id))?
        @proposal.points.included_cons.add model

  post_signin : () ->
    point.set('user_id', ConsiderIt.current_user.id) for point in @proposal.points.written_points
    existing_position = @proposal.positions[ConsiderIt.current_user.id]
    if existing_position?
      @merge_existing_position_into_current(existing_position)
    @trigger 'proposal:handled_signin'


  post_signout : () -> 
    for pnt in @proposal.points.written_points
      if pnt.get('is_pro') @proposal.points.included_pros.remove(pnt) else @proposal.points.included_cons.remove(pnt)

    @proposal.position.clear()
    @proposal.points.written_points = {}
    @proposal.points.viewed_points = {}
    @data_loaded = false
    @transition_unexpanded()


  take_position : (me) ->
    me.transition_expanded(1)

  show_results : (me) ->
    me.transition_expanded(2)


  take_position_handler : () ->
    if @state == -1
      @toggle()

    if @data_loaded
      @take_position(this)
    else
      @load_data(@take_position)


  show_results_handler : () ->
    if @state == -1
      @toggle()

    if @data_loaded
      @show_results(this)
    else
      @load_data(@show_results)


  # TODO: This should be triggered on results opened & position opened
  transition_expanded : (new_state) =>

    callback = (new_state) =>
      if new_state == 1
        el = @proposal.views.take_position.show_crafting()
        el.insertAfter(@proposal.views.results.$el)
        el.fadeIn 500, =>
          $my_position = el.find('.m-position-message-body')
          $my_header = $my_position.find('.m-position-heading')
          flash_color = '#be5237'
          $my_position.queue( (next) => 
            $my_position.css({borderColor: flash_color})
            $my_header.css({color: flash_color})
            next()
          ).delay(800).queue( (next) => 
            $my_position.css({borderColor: ''})
            $my_header.css({color: ''})            
            next()
          )

        @set_state(1)
      else if new_state == 2
        @proposal.views.results.show_explorer()
        @set_state(2)

      strip = ConsiderIt.ProposalView.proposal_strip_template( @model.attributes )
      @$el.prepend(strip)
      $('.l-navigate-home').fadeIn() #TODO: handle this in userdashboard via proposal opened event


    if @state > 0
      if new_state == 1
        @proposal.views.results.show_summary()
      else if new_state == 2
        @proposal.views.take_position.close_crafting()

      callback(new_state)

    else
      @scroll_position = @$el.offset().top - $('.t-intro-wrap').offset().top - parseInt(@$el.css('marginTop'))

      @$hidden_els = $("[data-role='m-proposal']:not([data-id='#{@model.id}']), .m-proposals-list-header, .t-intro-wrap")
      @$hidden_els.css 'display', 'none'
      $('body').scrollTop 0 #@$el.offset().top

      $('body').animate {scrollTop: @scroll_position }, 300, =>

        #if @$el.find('.m-proposal-description-body').is(':hidden')
        @$el.find('.m-proposal-description-body').slideDown()

        @$el.find('.m-proposal-description-details').slideDown =>

          #TODO: if user logs in as admin, need to do this
          @render_admin_strip() if ConsiderIt.roles.is_admin || ConsiderIt.roles.is_manager
          callback(new_state)
        

  transition_unexpanded : =>
    $('body').animate {scrollTop: @scroll_position}, =>
      # TODO: remove strip at top
      ConsiderIt.router.navigate(Routes.root_path(), {trigger: false}) if Backbone.history.fragment != ''

      if @state > 0

        #@$hidden_els.css 'display', ''
        @$hidden_els.css {opacity: 0, display: ''}
        @$hidden_els.animate {opacity: 1}, 350
        $('body').scrollTop @scroll_position

        @proposal.views.take_position.close_crafting()
        @proposal.views.results.show_summary()

        @$el.find('.m-proposal-strip').remove()
        $('.l-navigate-home').hide() 

        if @pointdetailsview
          @pointdetailsview.remove()

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
    @$el.find('.m-proposal-description-body, .m-proposal-description-details').slideToggle()

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
  prepare_for_point_details : (me, params) ->

    me.once 'ResultsExplorer:rendered', => 
      results_explorer = me.proposal.views.results.view

      for pnt in me.proposal.points.pros.concat me.proposal.points.cons
        if pnt.id == parseInt(params.point_id)
          point = pnt
          break

      pointlistview = if point.get('is_pro') then results_explorer.views.pros else results_explorer.views.cons
      pointview = pointlistview.getViewByModel(point) || pointlistview.addModelView(point) # this happens if the point is being directly visited, but is not on the front page of results

      pointview.show_point_details_handler() if pointview?
      $('body').animate {scrollTop: pointview.$el.offset().top - 50}, 200

    me.show_results(me)



  show_point_details_handler : (point_id) ->

    console.log 'SHOWP'
    if !@data_loaded
      @load_data(@prepare_for_point_details, {point_id : point_id})
    # if data is already loaded, then the PointListView is already properly handling this




  # TODO: move to its own view
  # ADMIN methods

  render_admin_strip : ->
    @$el.find('.m-proposal-admin_strip').remove()
    admin_strip_el = $('<div class="m-proposal-admin_strip m-proposal-strip">')
    template = _.template($('#tpl_proposal_admin_strip').html())
    admin_strip_el.html( template(@model.attributes))
    admin_strip_el.insertBefore(@$el.find('.m-proposal_strip_toggle'))
    for field in ConsiderIt.ProposalView.editable_fields
      [selector, name, type] = field 
      @$el.find(selector).editable {
        resource: 'proposal'
        pk: @long_id
        url: Routes.proposal_path @long_id
        type: type
        name: name
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
      ConsiderIt.app.trigger('proposal:deleted', @proposal.model )

  publish_proposal : (ev, response, options) ->
    data = $.parseJSON(response.responseText)
    @model.set(data.proposal.proposal)
    @render()
    @toggle()
