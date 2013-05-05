
#######
# state
# -1 = unexpanded
#  0 = expanded
#  1 = position
#  2 = results

class ConsiderIt.ProposalView extends Backbone.View
  @expanded_template : _.template( $("#tpl_expanded_proposal").html() )
  @unexpanded_template: _.template( $("#tpl_unexpanded_proposal").html() )

  tagName : 'li'

  @editable_fields : _.union([ ['.m-proposal-heading', 'name', 'text'], ['.m-proposal-description-body', 'description', 'textarea'] ], ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in ConsiderIt.Proposal.description_detail_fields() ))

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
      }))

    @$el.removeClass('expanded')
    @$el.addClass('unexpanded')

    @set_unexpanded()

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
    # if @state == -1
    #   console.log 'load data toggle'
    #   @toggle()

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
    @close()


  take_position : (me) ->
    me.proposal.views.results.show_summary()

    el = me.proposal.views.take_position.show_crafting()
    el.insertAfter(me.$el.find('[data-role="results-section"]'))
    
    $('html, body').stop(true, false);
    $('body').animate {scrollTop: el.offset().top - 100 }, 500

    me.state = 1

  show_results : (me) ->

    me.proposal.views.take_position.close_crafting()
    me.proposal.views.results.show_explorer()

    $('html, body').stop(true, false);
    $('body').animate {scrollTop: me.proposal.views.results.$el.offset().top - 100 }, 500

    me.state = 2

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

  close : () ->
    #_.each @proposal.views, (vw) -> 
    #  delete vw.remove()
    #@proposal.views = {}
    @proposal.views.take_position.close_crafting()
    @proposal.views.results.show_summary()
    if @pointdetailsview
      @pointdetailsview.remove()


  # Point details are being handled here (messily) for the case when a user directly visits the point details page without
  # (e.g. if they followed a link to it). In that case, we need to create some context around it first.
  prepare_for_point_details : (me, params) ->

    me.show_results(me)
    results_explorer = me.proposal.views.results.view

    for pnt in me.proposal.points.pros.concat me.proposal.points.cons
      if pnt.id == parseInt(params.point_id)
        point = pnt
        break

    pointlistview = if pnt.get('is_pro') then results_explorer.views.pros else results_explorer.views.pros
    pointview = pointlistview.getViewByModel(point) || pointlistview.addModelView(pnt) # this happens if the point is being directly visited, but is not on the front page of results

    pointview.show_point_details_handler() if pointview?


  show_point_details_handler : (point_id) ->

    if !@data_loaded
      @load_data(@prepare_for_point_details, {point_id : point_id})
    # if data is already loaded, then the PointListView is already properly handling this

  set_unexpanded : =>
    if @state > -1
      @$hidden_els.css 'display', ''

      console.log @scroll_position
      $('body').scrollTop @scroll_position

    @state = -1

  set_expanded : =>
    @state = 0
    @$hidden_els = $("[data-role='m-proposal']:not([data-id='#{@model.id}']), .m-proposals-heading, .t-intro-wrap")
    @$hidden_els.css 'display', 'none'
    $('body').scrollTop 0 #@$el.offset().top

  events : 
    'click .hidden' : 'show_details'
    'click .showing' : 'hide_details'
    # 'click .m-proposal-heading-wrap' : 'toggle'
    'click ' : 'toggle_if_not_expanded'
    'click .m-proposal-toggle' : 'toggle'
    'click .m-proposal-follow_conversation' : 'toggle_follow_proposal'

    'click .m-proposal-admin_operations-status' : 'show_status'
    'click .m-proposal-admin_operations-publicity' : 'show_publicity'
    'ajax:complete .m-proposal-admin_operations-settings-form' : 'change_settings'
    'click .l-dialog-detachable a.cancel' : 'cancel_dialog'
    'ajax:complete .m-delete_proposal' : 'delete_proposal'

    'ajax:complete .m-proposal-publish-form' : 'publish_proposal'

  toggle_if_not_expanded : (ev) ->
    if @$el.is('.unexpanded')
      @toggle(ev)

  toggle : (ev) ->
    if ev
      ev.stopPropagation()

    if @state == -1
      @scroll_position = @$el.offset().top - $('.t-intro-wrap').offset().top - parseInt(@$el.css('marginTop'))

      @$main_content_el.hide()

      @$main_content_el.append ConsiderIt.ProposalView.expanded_template($.extend({}, @model.attributes, {
          title : @model.title()
          description_detail_fields : @model.description_detail_fields(),
          avatar : window.PaperClip.get_avatar_url(ConsiderIt.users[@model.get('user_id')], 'original')
        }))


      if @model.get('published')
        results_el = $('<div class="m-proposal-message">')
        @proposal.views.results = new ConsiderIt.ResultsView
          el : results_el
          proposal : @proposal
          model : @model

        @proposal.views.results.render()


        @proposal.views.take_position = new ConsiderIt.PositionView
          proposal : @proposal
          model : @proposal.position
          el : @$el

        position_el = @proposal.views.take_position.render()
        
        results_el.insertAfter(@$el.find('.m-proposal-introduction'))
        position_el.insertAfter(results_el)



      @$el.addClass('expanded')
      @$el.removeClass('unexpanded')

      @$main_content_el.slideDown 500, =>

        $('body').animate {scrollTop: @scroll_position }, 500, =>


          @set_expanded()

          #TODO: if user logs in as admin, need to do this
          if ConsiderIt.roles.is_admin || ConsiderIt.roles.is_manager

            @render_admin_strip()
            for field in ConsiderIt.ProposalView.editable_fields
              [selector, name, type] = field 
              @$el.find(selector).editable {
                resource: 'proposal'
                pk: @long_id
                url: Routes.proposal_path @long_id
                type: type
                name: name
              }

      this
    else
      $('body').animate {scrollTop: @scroll_position}, =>
        @$main_content_el.slideUp => 
          @render()
          @set_unexpanded()
          ConsiderIt.router.navigate(Routes.root_path(), {trigger: false})

        #@$el.addClass('unexpanded')


  render_admin_strip : ->
    @$el.find('.m-proposal-admin_strip').remove()
    admin_strip_el = $('<div class="m-proposal-admin_strip m-proposal-strip">')
    template = _.template($('#tpl_proposal_admin_strip').html())
    admin_strip_el.html( template(@model.attributes))
    admin_strip_el.insertBefore(@$el.find('.m-proposal_strip_toggle'))

  show_details : (ev) -> 
    $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

    $block.find('.m-proposal-description-detail-field-full').slideDown();
    $block.find('.hidden')
      .text('hide')
      .toggleClass('hidden showing');

  hide_details : (ev) -> 
    $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

    $block.find('.m-proposal-description-detail-field-full').slideUp(1000);
    $block.find('.showing')
      .text('show')
      .toggleClass('hidden showing');      

  toggle_follow_proposal : (ev) -> 
    $follow_button = $(ev.currentTarget)
    follows = ConsiderIt.current_user.is_following('Proposal', @model.id)
    url = if !follows then Routes.follow_path() else Routes.unfollow_path()

    $.post url, {follows: {user_id: ConsiderIt.current_user.id, followable_type: 'Proposal', followable_id: @model.id, follow: !follows} }, (data, status, xhr) => 
      if follows
        $follow_button.removeClass('selected')
      else 
        $follow_button.addClass('selected')

      ConsiderIt.current_user.set_following {followable_type: 'Proposal', followable_id: @model.id, follow: !follows, explicit: true}

  # ADMIN methods
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
