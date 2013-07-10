class ConsiderIt.StaticPositionView extends Backbone.View
  template : _.template( $('#tpl_static_position').html())

  initialize : (options) ->
    super
    @proposal = options.proposal
    @user = ConsiderIt.users[options.user_id]
    @data_loaded = false

  render : ->
    callback = =>
      if @stance < 3
        supporting_points = @included_cons
        opposing_points = @included_pros
      else if @stance >= 3
        supporting_points = @included_pros
        opposing_points = @included_cons

      overlay = @template
        supporting_points : supporting_points
        opposing_points : opposing_points
        stance : @stance 
        stance_label : ConsiderIt.Position.stance_name_adverb(@stance)
        user : @user

      @$el.find('[data-role="results-section"]').before(overlay) 

      @$dialog = @$el.find('.m-static-position')

      # when clicking outside of point, close it
      $(document).on 'click.m-static-position', (ev) => @close()
      
      @$dialog.on 'click.m-static-position', (ev) => 
        ev.stopPropagation() if !$(ev.target).data('target')
      $(document).on 'keyup.m-static-position', (ev) => @close_by_keyup(ev)


    if @data_loaded
      callback()
    else
      @once 'StaticPosition:DataLoaded', => callback()
      @load_data()

  close_by_keyup : (ev) -> @close() if ev.keyCode == 27 && $('#registration_overlay').length == 0

  set_data : (data) ->
    @included_pros = (@proposal.pros.get(p) for p in data.included_pros)
    @included_cons = (@proposal.cons.get(p) for p in data.included_cons)
    @stance = data.stance

    @data_loaded = true
    @trigger 'StaticPosition:DataLoaded'

  load_data : ->
    $.get Routes.user_position_proposal_path(@proposal.long_id, @user.id), (data) => @set_data(data)

  events : 
    'click [data-target="static-position-close"]' : 'close'

  close : ->
    $(document).off 'click.m-static-position' 
    $(document).off 'keyup.m-static-position'
    @$dialog.off 'click.m-static-position'

    ConsiderIt.app.go_back_crumb()
    @stopListening()
    @undelegateEvents()
    @$dialog.remove()
