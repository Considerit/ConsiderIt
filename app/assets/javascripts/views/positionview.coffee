#############
## Responsible for managing inclusions between peer points and 
## the individual's personal points.
#############

class ConsiderIt.PositionView extends Backbone.View
  initialize : (options) -> 
    @proposal = options.proposal
    @state = 0

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
    crafting_el = $('<div class="m-proposal-message m-position">')
    @crafting_view = new ConsiderIt.CraftingView
      el : crafting_el
      proposal : @proposal
      model : @model

    @crafting_view.render()
    @your_action_view.crafting_state()
    @state = 1

    crafting_el

  close_crafting : ->
    if @state == 1
      @crafting_view.$el.slideUp =>
        @crafting_view.remove()
        @your_action_view.close_crafting()
        @state = 0

  events :
    'click .submit' : 'handle_submit_position'

  submit_position : () ->
    _.extend(@proposal.position.attributes, @crafting_view.position_attributes())
    Backbone.sync 'update', @proposal.position,
      success : (data) =>
        #TODO: any reason to wait for the server to respond before navigating to the results?
        ConsiderIt.router.navigate(Routes.proposal_path( @proposal.model.get('long_id') ), {trigger: true})

      failure : (data) =>
        console.log('Something went wrong syncing position')

  handle_submit_position : (ev) ->
    if ConsiderIt.current_user.isNew()
      regview = ConsiderIt.app.usermanagerview.handle_user_registration(ev)
      # if user cancels login, then we could later submit this position unexpectedly when signing in to submit a different position!
      @listenTo @proposal.view, 'proposal:handled_signin', () => 
        @stopListening @proposal.view, 'proposal:handled_signin'
        @submit_position()
    else
      @submit_position()


class ConsiderIt.YourActionView extends Backbone.View
  @craft_template : _.template( $("#tpl_your_action_craft").html() )
  @save_template : _.template( $("#tpl_your_action_save").html() )

  initialize : (options) -> 
    @proposal = options.proposal

  render : () -> 
    @close_crafting()

  crafting_state : ->
    @$el.html ConsiderIt.YourActionView.save_template 
      call : if true then 'Save your position' else 'Update your position'

  close_crafting : ->
    @$el.html ConsiderIt.YourActionView.craft_template
      call : if true then 'Join the conversation' else 'Revisit the conversation'
      long_id : @proposal.model.get('long_id')


class ConsiderIt.CraftingView extends Backbone.View
  @template : _.template( $("#tpl_position").html() )
  @newpoint_template : _.template( $("#tpl_newpoint").html() )
  
  initialize : (options) -> 
    @proposal = options.proposal

  render : () -> 
    @$el.html ConsiderIt.CraftingView.template($.extend({}, @model.attributes, {proposal : @proposal.model.attributes}))

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
      mypros : @proposal.points.included_pros
      peerpros : @proposal.points.peer_pros
      mycons : @proposal.points.included_cons
      peercons : @proposal.points.peer_cons
    
    @views = 
      mypros : new ConsiderIt.PointListView({collection : @pointlists.mypros, el : @$el.find('.m-pro-con-list-propoints'), location: 'position', proposal : @proposal})
      peerpros : new ConsiderIt.PaginatedPointListView({collection : @pointlists.peerpros, el : @$el.find('.m-reasons-peer-pros'), location: 'peer', proposal : @proposal})
      mycons : new ConsiderIt.PointListView({collection : @pointlists.mycons, el : @$el.find('.m-pro-con-list-conpoints'), location: 'position', proposal : @proposal})
      peercons : new ConsiderIt.PaginatedPointListView({collection : @pointlists.peercons, el : @$el.find('.m-reasons-peer-cons'), location: 'peer', proposal : @proposal})

    @listenTo @pointlists.peerpros, 'reset', @peer_point_list_reset
    @listenTo @pointlists.peercons, 'reset', @peer_point_list_reset

    @views.mypros.renderAllItems()
    @views.mycons.renderAllItems()

    $('.m-pro-con-list-propoints', @$el).append(ConsiderIt.CraftingView.newpoint_template({is_pro : true}))
    $('.m-pro-con-list-conpoints', @$el).append(ConsiderIt.CraftingView.newpoint_template({is_pro : false}))

    @$el.find('.m-newpoint-nutshell').autoResize {extraSpace: 10, minHeight: 50}
    @$el.find('.m-newpoint-description').autoResize {extraSpace: 10, minHeight: 100 }

    @$el.find('.m-position-statement').autoResize {extraSpace: 5}
    @$el.find('[placeholder]').simplePlaceholder()

    @$el.find('.m-newpoint-form .is_counted').each ->
      $(this).NobleCount $(this).siblings('.count'), {
        block_negative: true,
        max_chars : parseInt($(this).siblings('.count').text()) }        

    @stickit()

    @create_slider()
    
    @listenTo @model, 'change:stance', => 
      @slider.$el.noUiSlider('destroy')
      @create_slider()

    @show()

    this

  bindings : 
    'textarea[name="explanation"]' : 'explanation'

  create_slider : () ->

    @slider.$el = $('<div class="noUiSlider">').appendTo(@$el.find('.m-stance-slider-container'))
    @slider.params.start = @model.get('stance') * 100  
    @slider.$el.noUiSlider('init', @slider.params)
    if !@slider.is_neutral
      @slider.$neutral_label.hide()
    

  show : () ->
    @pointlists.peerpros.goTo(1)
    @pointlists.peercons.goTo(1)
    @$el.show()

  hide : () ->
    @$el.hide()  

  #handlers
  events :
    'click .m-point-include' : 'include_point'
    'click .m-point-remove' : 'remove_point'
    'click .m-newpoint-new' : 'new_point'
    'click .m-newpoint-cancel' : 'cancel_new_point'
    'click .m-newpoint-create' : 'create_new_point'
    'click .m-point-peer' : 'navigate_point_details'

  include_point : (ev) ->
    $item = @_$item(ev.currentTarget)
    id = $item.data('id')

    [peers, mine] = if $item.hasClass('pro') then [@pointlists.peerpros, @pointlists.mypros] else [@pointlists.peercons, @pointlists.mycons]

    model = peers.get(id)

    peers.remove(model)
    mine.add(model)

    # persist the inclusion ... (in future, don't have to do this until posting...)
    params = {  }
    csrfName = $("meta[name='csrf-param']").attr('content')
    csrfValue = $("meta[name='csrf-token']").attr('content')
    params[csrfName] = csrfValue

    $.post Routes.proposal_point_inclusions_path( @proposal.model.get('long_id'), model.attributes.id ), 
      params, 
      (data) ->

    ev.stopPropagation()

  remove_point : (ev) ->
    $item = @_$item(ev.currentTarget)
    id = $item.data('id')

    [peers, mine] = if $item.hasClass('pro') then [@pointlists.peerpros, @pointlists.mypros] else [@pointlists.peercons, @pointlists.mycons]

    model = mine.get(id)

    mine.remove(model)
    peers.add(model)

    params = { }
    ConsiderIt.utils.add_CSRF(params)

    $.post Routes.proposal_point_inclusions_path( @proposal.model.get('long_id'), model.attributes.id, {delete : true} ), 
      params, 
      (data) ->

  point_attributes : ($form) ->  {
    nutshell : $form.find('.m-newpoint-nutshell').val()
    text : $form.find('.m-newpoint-description').val()
    is_pro : $form.hasClass('pro')
    hide_name : $form.find('.m-newpoint-anonymous').is(':checked')
    comment_count : 0
    proposal_id : @proposal.model.id
  }

  new_point : (ev) ->
    $(ev.currentTarget).fadeOut 100, () ->
      $(this).siblings('.m-newpoint-form').find('.m-newpoint-nutshell, .m-newpoint-description').trigger('keyup')
      $(this).siblings('.m-newpoint-form').fadeIn 'fast', () ->
        #$(this).find('iframe').focus().contents().trigger('keyup').find('#page')            
        $(this).find('.m-newpoint-nutshell').focus()
  
  cancel_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.m-newpoint-form')
    $form
      .fadeOut () -> 
        $form.siblings('.m-newpoint-new').fadeIn() 
        $form.find('textarea').val('').trigger('keydown')
        $form.find('label.inline').addClass('empty')
        #$('.newpoint').fadeIn()

  create_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.m-newpoint-form')
    attrs = @point_attributes($form)

    pointlist = if attrs.is_pro then @pointlists.mypros else @pointlists.mycons
    @cancel_new_point({currentTarget: $form.find('.new_point_cancel')})

    new_point = pointlist.create attrs, {wait: true}
      success : (data) ->
    @proposal.points.written_points.push new_point

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
      viewed_points : _.values(@proposal.points.viewed_points)
    }


  peer_point_list_reset : (list) ->
    for pnt in list.models
      @proposal.points.viewed_points[pnt.id] = pnt.id

  _$item : (child) ->
    $(child).closest("[data-role=\"#{ConsiderIt.PointListView.childClass}\"]")

  navigate_point_details : (ev) ->
    ConsiderIt.router.navigate(Routes.proposal_point_path(@proposal.model.get('long_id'), $(ev.currentTarget).data('id')), {trigger: true})


