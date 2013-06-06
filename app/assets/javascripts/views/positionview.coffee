#############
## Responsible for managing inclusions between peer points and
## the individual's personal points.
#############

class ConsiderIt.PositionView extends Backbone.View

  initialize : (options) ->
    @proposal = options.proposal
    @state = 0

    @listenToOnce @proposal, 'proposal:data_loaded', => 
      @model = @proposal.position
      if @your_action_view
        @your_action_view.model = @proposal.position
      if @crafting_view
        @crafting_view.model = @proposal.position

      @listenTo ConsiderIt.app, 'user:signin', @post_signin
      @listenTo ConsiderIt.app, 'user:signout', @post_signout  

  post_signin : () ->
    return if !@model.positions

    point.set('user_id', ConsiderIt.current_user.id) for point in @model.written_points
    existing_position = @model.positions[ConsiderIt.current_user.id]

    # need to merge old position into new
    existing_position.subsume @model
    @model.set existing_position.attributes
    @proposal.positions[ConsiderIt.current_user.id] = @model
    delete @proposal.positions[-1]

    # transfer already included points from existing_position into the included lists
    for pnt_id in $.parseJSON(existing_position.get('point_inclusions'))
      if (model = @proposal.peer_pros.remove_from_all(pnt_id))?
        @proposal.included_pros.add model
      else if (model = @proposal.peer_cons.remove_from_all(pnt_id))?
        @proposal.included_cons.add model

    @trigger 'position:signin_handled'


  post_signout : () ->
    for pnt in @model.written_points
      if pnt.get('is_pro') then @proposal.included_pros.remove(pnt) else @proposal.included_cons.remove(pnt)

    @model.clear()

  render : ->
    your_action_el = $('<div class="m-proposal-message m-position-your_action">')

    @your_action_view = new ConsiderIt.YourActionView 
      el : your_action_el
      proposal : @proposal
      model : @model

    @your_action_view.render() 

    your_action_el

  set_model : (model) ->
    @model = model
    @your_action_view.model = model if @your_action_view
    @your_action_view.render()
    @crafting_view.model = model if @state == 1

  show_crafting : ->
    if @state != 1
      crafting_el = $('<div class="m-proposal-message m-position">')
      @crafting_view = new ConsiderIt.CraftingView
        el : crafting_el
        proposal : @proposal
        model : @model

      @crafting_view.render()
      @your_action_view.crafting_state()
      @state = 1

      @trigger 'PositionCrafting:rendered'

      crafting_el
    else
      @crafting_view.$el

  close_crafting : ->
    if @state == 1
      @crafting_view.$el.slideUp =>
        @crafting_view.remove()
        @your_action_view.close_crafting()
        @state = 0

  events :
    'click .submit' : 'handle_submit_position'
    'click .m-position-cancel' : 'position_canceled'

  position_canceled : ->
    # TODO: discard changes
    @trigger 'position:canceled'

  handle_submit_position : (ev) ->
    if ConsiderIt.current_user.isNew()
      regview = ConsiderIt.app.usermanagerview.handle_user_registration(ev)
      # if user cancels login, then we could later submit this position unexpectedly when signing in to submit a different position!      
      @on 'position:signin_handled', => @submit_position()
    else
      @submit_position()

  submit_position : () ->
    _.extend(@model.attributes, @crafting_view.position_attributes())
    Backbone.sync 'update', @model,
      success : (data) =>
        @model.set( data.position )
        @proposal.updated_position @model
        ConsiderIt.router.navigate(Routes.proposal_path( @model.proposal.long_id ), {trigger: true})

      failure : (data) =>
        console.log('Something went wrong syncing position')

class ConsiderIt.YourActionView extends Backbone.View
  @craft_template : _.template( $("#tpl_your_action_craft").html() )
  @save_template : _.template( $("#tpl_your_action_save").html() )

  initialize : (options) -> 
    @proposal = options.proposal

  render : () -> 
    @close_crafting()

  crafting_state : ->
    @$el.html ConsiderIt.YourActionView.save_template
      updating : false
      follows : ConsiderIt.current_user.is_following('Proposal', @model.id)

  close_crafting : ->
    @$el.html ConsiderIt.YourActionView.craft_template
      call : if true then 'What do you think?' else 'Revisit the conversation'
      long_id : @proposal.long_id


class ConsiderIt.CraftingView extends Backbone.View
  @template : _.template( $("#tpl_position").html() )
  @newpoint_template : _.template( $("#tpl_newpoint").html() )
  
  initialize : (options) -> 
    @proposal = options.proposal

  render : () -> 

    @$el.hide()
    @$el.html ConsiderIt.CraftingView.template($.extend({}, @model.attributes, {proposal : @model.proposal.attributes}))

    @slider = 
      max_effect : 65 
      value : @model.get('stance') * 100
      $oppose_label : @$el.find( '.m-stance-label-oppose')
      $support_label : @$el.find( '.m-stance-label-support')
      $neutral_label : @$el.find( '.m-stance-label-neutral')
      is_neutral : Math.abs(@model.get('stance') * 100) < 5
      params :       
        handles: 1
        connect: "lower"
        scale: [100, -100]
        width: 300
        change: () => @slider_change(@slider.$el.noUiSlider('value')[1])

    @pointlists = 
      mypros : @proposal.included_pros
      peerpros : @proposal.peer_pros
      mycons : @proposal.included_cons
      peercons : @proposal.peer_cons

    @views = 
      mypros : new ConsiderIt.PointListView({collection : @pointlists.mypros, el : @$el.find('.m-pro-con-list-propoints'), location: 'position', proposal : @proposal})
      peerpros : new ConsiderIt.BrowsablePointListView({collection : @pointlists.peerpros, el : @$el.find('.m-reasons-peer-pros'), location: 'peer', proposal : @proposal})
      mycons : new ConsiderIt.PointListView({collection : @pointlists.mycons, el : @$el.find('.m-pro-con-list-conpoints'), location: 'position', proposal : @proposal})
      peercons : new ConsiderIt.BrowsablePointListView({collection : @pointlists.peercons, el : @$el.find('.m-reasons-peer-cons'), location: 'peer', proposal : @proposal})

    #@listenTo @pointlists.peerpros, 'reset', @peer_point_list_reset
    #@listenTo @pointlists.peercons, 'reset', @peer_point_list_reset

    @views.mypros.renderAllItems()
    @views.mycons.renderAllItems()

    $('.m-pro-con-list-propoints', @$el).append(ConsiderIt.CraftingView.newpoint_template({is_pro : true}))
    $('.m-pro-con-list-conpoints', @$el).append(ConsiderIt.CraftingView.newpoint_template({is_pro : false}))

    @$el.find('.m-newpoint-nutshell').autoResize {extraSpace: 10, minHeight: 50}
    @$el.find('.m-newpoint-description').autoResize {extraSpace: 10, minHeight: 100 }

    @$el.find('.m-position-statement').autoResize {extraSpace: 5}
    @$el.find('[placeholder]').simplePlaceholder()

    for el in @$el.find('.m-newpoint-form .is_counted')
      $(el).NobleCount $(el).siblings('.count'), {
        block_negative: true,
        max_chars : parseInt($(el).siblings('.count').text()) }        

    @stickit()

    @create_slider()
    
    @listenTo @model, 'change:stance', => 
      @slider.$el.noUiSlider('destroy')
      @create_slider()

    @pointlists.peerpros.goTo(1)
    @pointlists.peercons.goTo(1)

    this

  bindings : 
    'textarea[name="explanation"]' : 'explanation'

  create_slider : () ->    
    @slider.$el = $('<div class="noUiSlider">').appendTo(@$el.find('.m-stance-slider-container'))
    @slider.params.start = @model.get('stance') * 100  
    @slider.$el.noUiSlider('init', @slider.params)
    if !@slider.is_neutral
      @slider.$neutral_label.css('opacity', 0)
  

  hide : () ->
    @$el.slideUp()  

  #handlers
  events :
    'click [data-target="point-include"]' : 'include_point'
    'click [data-target="point-remove"]' : 'remove_point'
    'click .m-newpoint-new' : 'new_point'
    'click .m-newpoint-cancel' : 'cancel_new_point'
    'click .m-newpoint-create' : 'create_new_point'
    'click .m-point-wrap' : 'navigate_point_details'
    'mouseenter .m-point-peer' : 'log_point_view'

  include_point : (ev) ->
    $item = @_$item(ev.currentTarget)
    id = $item.data('id')

    [peers, mine] = if $item.hasClass('pro') then [@pointlists.peerpros, @pointlists.mypros] else [@pointlists.peercons, @pointlists.mycons]

    model = peers.get(id)
    included_point_model = mine.add(model).get(model)

    model.trigger('point:included') 

    if $item.is('.m-point-unexpanded')
      $included_point = @$el.find(".m-point-position[data-id='#{included_point_model.id}']")
      $included_point.css 'visibility', 'hidden'

      item_offset = $item.offset()
      ip_offset = $included_point.offset()
      [offsetX, offsetY] = [ip_offset.left - item_offset.left, ip_offset.top - item_offset.top]

      styles = $included_point.getStyles()

      target_props = {
        color: styles['color'],
        #fontSize: styles['fontSize']
        width: styles['width']
        paddingRight: styles['paddingRight']
        paddingLeft: styles['paddingLeft']
        paddingTop: styles['paddingTop']
        paddingBottom: styles['paddingBottom']
        background: 'none'
        border: 'none'
      }
      delete target_props['visibility']

      _.extend target_props, {top: offsetY, left: offsetX, position: 'absolute'}

      $placeholder = $('<li class="m-point-peer">')
      $placeholder.css {height: $item.outerHeight(), visibility: 'hidden'}

      $item.find('.m-point-author-avatar, .m-point-include-wrap, .m-point-operations').fadeOut(50)

      $wrap = $item.find('.m-point-wrap')
      $wrap.css {position: 'absolute', width: $wrap.outerWidth()}

      $placeholder.insertAfter($item)

      $wrap.css(target_props).delay(500).queue (next) =>
        $item.fadeOut -> 
          peers.remove(model)
          $placeholder.remove()
          $included_point.css 'visibility', ''
        next()
    else
      peers.remove(model)


    ev.stopPropagation()

    # persist the inclusion ... (in future, don't have to do this until posting...)
    params = {  }
    csrfName = $("meta[name='csrf-param']").attr('content')
    csrfValue = $("meta[name='csrf-token']").attr('content')
    params[csrfName] = csrfValue

    $.post Routes.proposal_point_inclusions_path( @model.proposal.long_id, model.attributes.id ), 
      params, 
      (data) ->


  remove_point : (ev) ->
    $item = @_$item(ev.currentTarget)
    id = $item.data('id')

    [peers, mine] = if $item.hasClass('pro') then [@pointlists.peerpros, @pointlists.mypros] else [@pointlists.peercons, @pointlists.mycons]

    model = mine.get(id)

    model.trigger('point:removed') 

    mine.remove(model)
    peers.add(model)

    params = { }
    ConsiderIt.utils.add_CSRF(params)

    ev.stopPropagation()

    $.post Routes.proposal_point_inclusions_path( @model.proposal.long_id, model.attributes.id, {delete : true} ), 
      params, 
      (data) ->

  point_attributes : ($form) ->  {

    nutshell : $form.find('.m-newpoint-nutshell').val()
    text : $form.find('.m-newpoint-description').val()
    is_pro : $form.find('.m-newpoint-is_pro').val() == 'true'
    hide_name : $form.find('.m-newpoint-anonymous').is(':checked')
    comment_count : 0
    proposal_id : @model.proposal.id
  }

  new_point : (ev) ->
    #$(ev.currentTarget).fadeOut 100, () ->
    $(ev.currentTarget).hide()
    $form = $(ev.currentTarget).siblings('.m-newpoint-form')

    $form.find('.m-newpoint-nutshell, .m-newpoint-description').trigger('keyup')
    $form.show() # 'fast', () ->
      #$(this).find('iframe').focus().contents().trigger('keyup').find('#page')            
    $form.find('.m-newpoint-nutshell').focus()
  
  cancel_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.m-newpoint-form')
    $form.hide()
    $form.siblings('.m-newpoint-new').show()
    $form.find('textarea').val('').trigger('keydown')
    $form.find('label.inline').addClass('empty')
      #$('.newpoint').fadeIn()

  create_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.m-newpoint-form')

    attrs = @point_attributes($form)


    pointlist = if attrs.is_pro then @pointlists.mypros else @pointlists.mycons
    @cancel_new_point({currentTarget: $form.find('.m-newpoint-cancel')})

    new_point = pointlist.create attrs, {wait: true}
    @model.written_points.push new_point

  slider_change : (new_value) -> 
    return unless isFinite(new_value)

    if Math.abs(new_value) < 5
      @slider.$neutral_label.css('opacity', 1)
      @slider.is_neutral = true
    else if @slider.is_neutral
      @slider.$neutral_label.css('opacity', 0)
      @slider.is_neutral = false

    @slider.value = new_value

    @model.set('stance', @slider.value / 100, {silent : true})

    size = @slider.max_effect / 100 * @slider.value
    @slider.$oppose_label.css('font-size', 100 - size + '%')
    @slider.$support_label.css('font-size', 100 + size + '%')

    #ConsiderIt.update_unobtrusive_edit_heights($(".slider_label .unobtrusive_edit textarea"));

  position_attributes : () -> {
    stance : @model.get('stance')
    explanation : @$el.find('.position_statement textarea').val()
    included_points : ( pnt.id for pnt in @pointlists.mypros.models ).concat ( pnt.id for pnt in @pointlists.mycons.models )
    viewed_points : _.values(@model.viewed_points)
    follow_proposal : @$el.find('#follow_proposal').is(':checked')
  }

  log_point_view : (ev) ->
    pnt = $(ev.currentTarget).data('id')
    @model.viewed_points[pnt] = pnt

  # peer_point_list_reset : (list) ->
  #   for pnt in list.models
  #     @model.viewed_points[pnt.id] = pnt.id

  _$item : (child) ->
    $(child).closest("[data-role=\"#{ConsiderIt.PointListView.childClass}\"]")

  navigate_point_details : (ev) ->
    point_id = $(ev.currentTarget).closest('.pro, .con').data('id')
    ConsiderIt.router.navigate(Routes.proposal_point_path(@model.proposal.long_id, point_id), {trigger: true})


