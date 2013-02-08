#############
## Responsible for managing inclusions between peer points and 
## the individual's personal points.
#############

class ConsiderIt.PositionView extends Backbone.View

  #el: '.user_opinion'
  @template : _.template( $("#tpl_position").html() )
  @newpoint_template : _.template( $("#tpl_newpoint").html() )
  slider_template : () -> $('<div class="slider noUiSlider">').appendTo(@$el.find('.slider_container'))
  
  initialize : (options) -> 
    @proposal = options.proposal
    @parent = options.parent

  render : () -> 
    this.$el.html ConsiderIt.PositionView.template($.extend({}, this.model.attributes, {proposal : @proposal.model.attributes}))

    @slider = 
      max_effect : 65 
      value : @model.get('stance') * 100
      $right : @$el.find( '.slider_table .right')
      $left : @$el.find( '.slider_table .left')
      params :       
        handles: 1
        connect: "lower"
        scale: [100, -100]
        change: () => @slider_change(@slider.$el.noUiSlider('value')[1])

    @pointlists = 
      mypros : @proposal.points.included_pros
      peerpros : @proposal.points.peer_pros
      mycons : @proposal.points.included_cons
      peercons : @proposal.points.peer_cons
    
    @views = 
      mypros : new ConsiderIt.PointListView({collection : @pointlists.mypros, el : @$el.find('#propoints'), location: 'self', proposal : @proposal})
      peerpros : new ConsiderIt.PaginatedPointListView({collection : @pointlists.peerpros, el : @$el.find('#peer_pros'), location: 'margin', proposal : @proposal})
      mycons : new ConsiderIt.PointListView({collection : @pointlists.mycons, el : @$el.find('#conpoints'), location: 'self', proposal : @proposal})
      peercons : new ConsiderIt.PaginatedPointListView({collection : @pointlists.peercons, el : @$el.find('#peer_cons'), location: 'margin', proposal : @proposal})

    @listenTo @pointlists.peerpros, 'reset', @peer_point_list_reset
    @listenTo @pointlists.peercons, 'reset', @peer_point_list_reset

    @views.mypros.renderAllItems()
    @views.mycons.renderAllItems()

    $('#points_on_board_pro .inner_wrapper', @$el).append(ConsiderIt.PositionView.newpoint_template({is_pro : true}))
    $('#points_on_board_con .inner_wrapper', @$el).append(ConsiderIt.PositionView.newpoint_template({is_pro : false}))

    @create_slider()
    @stickit()

    @listenTo @model, 'change:stance', => 
      @slider.$el.noUiSlider('destroy')
      @create_slider()

    @show()

    this

  bindings : 
    'textarea[name="explanation"]' : 'explanation'

  create_slider : () ->
    @slider.$el = @slider_template()
    @slider.params.start = @model.get('stance') * 100      
    @slider.$el.noUiSlider('init', @slider.params)

  show : () ->
    @pointlists.peerpros.goTo(1)
    @pointlists.peercons.goTo(1)
    @$el.show()

  hide : () ->
    @$el.hide()  

  #handlers
  events :
    'click .include' : 'include_point'
    'click .remove' : 'remove_point'
    'click a.write_new' : 'new_point'
    'click a.new_point_cancel' : 'cancel_new_point'
    'click .point-submit input' : 'create_new_point'
    'click .submit' : 'handle_submit_position'

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

  point_attributes : ($form) ->       
    {
      nutshell : $form.find('.point-title').val()
      text : $form.find('.point-description').val()
      is_pro : $form.hasClass('pro')
      hide_name : $form.find('.hide_name input').is(':checked')
      comment_count : 0
      proposal_id : @proposal.model.id
    }

  new_point : (ev) ->
    $(ev.currentTarget).fadeOut 100, () ->
      $(this).siblings('.pointform').fadeIn 'fast', () ->
        $(this).find('iframe').focus().contents().trigger('keyup').find('#page')            
        $(this).find('input,textarea').trigger('keyup')
        $(this).find('.point-title').focus()

  cancel_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.pointform')
    $form
      .fadeOut () -> 
        $form.siblings('.write_new').fadeIn() 
        $form.find('textarea').val('').trigger('keydown')
        $form.find('label.inline').addClass('empty')
        $('.newpoint').fadeIn()

  create_new_point : (ev) ->
    $form = $(ev.currentTarget).closest('.pointform')
    attrs = @point_attributes($form)

    pointlist = if attrs.is_pro then @pointlists.mypros else @pointlists.mycons
    @cancel_new_point({currentTarget: $form.find('.new_point_cancel')})

    new_point = pointlist.create attrs, {wait: true}
      success : (data) ->
    @proposal.points.written_points.push new_point

  slider_change : (new_value) -> 

    @slider.value = new_value

    @model.set('stance', @slider.value / 100, {silent : true})

    size = @slider.max_effect / 100 * @slider.value
    @slider.$right.css('font-size', 100 - size + '%')
    @slider.$left.css('font-size', 100 + size + '%')

    #ConsiderIt.update_unobtrusive_edit_heights($(".slider_label .unobtrusive_edit textarea"));

  position_attributes : () -> {
      stance : @model.get('stance')
      explanation : @$el.find('.position_statement textarea').val()
      included_points : ( pnt.id for pnt in @pointlists.mypros.models ).concat ( pnt.id for pnt in @pointlists.mycons.models )
      viewed_points : _.values(@proposal.points.viewed_points)
    }

  submit_position : () ->
    _.extend(@proposal.position.attributes, @position_attributes())
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
      @listenTo @parent, 'proposal:handled_signin', () => 
        @stopListening @parent, 'proposal:handled_signin'
        @submit_position()
    else
      @submit_position()

  peer_point_list_reset : (list) ->
    for pnt in list.models
      @proposal.points.viewed_points[pnt.id] = pnt.id

  _$item : (child) ->
    $(child).closest(".#{ConsiderIt.PointListView.childClass}")


