class ConsiderIt.PointDetailsView extends Backbone.View

  #@template : _.template $("#tpl_point_details").html()

  initialize : (options) -> 
    @proposal = options.proposal
    @listenTo @model, 'point:included', => @close_details()
    @listenTo @model, 'point:removed', => @close_details()

  render : () ->    

    # @$el.hide()

    if ConsiderIt.current_tenant.get('assessment_enabled') && @proposal.get('active') 
      
      if @model.assessment
        $assessment_el = $('<div class="m-point-assessment-wrap">')
        @$el.find('.m-point-wrap').append($assessment_el)
      else
        $assessment_el = @$el.find('.m-point-assess')


      @assessmentview = new ConsiderIt.AssessmentView({
        model : @model
        el: $assessment_el
        proposal : @proposal
      })


    $comment_el = $('<div class="m-point-discussion">')
    
    @commentsview = new ConsiderIt.CommentListView({
      collection: @model.comments
      el: $comment_el
      commentable_id: @model.id
      commentable_type: 'Point'})


    if ConsiderIt.current_user.is_logged_in()
      if !ConsiderIt.PointDetailsView.follow_tpl
        ConsiderIt.PointDetailsView.follow_tpl = _.template( $('#tpl_point_follows').html() )
      @$el.find('.m-point-follow').append( ConsiderIt.PointDetailsView.follow_tpl( _.extend( {}, @model.attributes,
        already_follows : ConsiderIt.current_user.is_following('Point', @model.id)
      )))

    #TODO: if user logs in as admin, need to do this
    if ConsiderIt.current_user.id == @model.get('user_id') || ConsiderIt.roles.is_admin
      @$el.find('.m-point-nutshell ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @proposal.long_id, @model.id
          type: 'textarea'
          name: 'nutshell'
          success : (response, new_value) => @model.set('nutshell', new_value)


      @$el.find('.m-point-details-description ').editable
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @proposal.long_id, @model.id
          type: 'textarea'
          name: 'text'
          success : (response, new_value) => @model.set('text', new_value)



    @$el.find('.m-point-wrap').append($comment_el)
    @$el.find('.m-point-wrap > *').css 'visibility', 'hidden'

    @$el.toggleClass( 'm-point-expanded m-point-unexpanded').delay(1).queue (next) =>

      @assessmentview.render()
      @commentsview.renderAllItems()
  
      @$el.find('.m-point-wrap > *').css 'visibility', ''

      # when clicking outside of point, close it
      $(document).on 'click.m-point-details', (ev)  => @close_details( !$(ev.target).data('target') )

      @$el.on 'click.m-point-details', (ev) => ev.stopPropagation() if !$(ev.target).data('target')
          
      $(document).on 'keyup.m-point-details', (ev) => @close_by_keyup(ev)

      next()

    this

  close_by_keyup : (ev) ->
    if ev.keyCode == 27 && $('#registration_overlay').length == 0
      @close_details()    

  events : 
    #'click .m-point-details-close' : 'close_details'
    'ajax:success .follow form' : 'toggle_follow'
    'ajax:success .unfollow form' : 'toggle_follow'

  toggle_follow : (ev, data) -> 
    $(ev.currentTarget).parent().addClass('hide').siblings('.follow, .unfollow').removeClass('hide')
    ConsiderIt.current_user.set_following(data.follow.follow)

  close_details : (trigger) ->
    trigger ?= true
    @$el.find('.m-point-wrap > *').css 'visibility', 'hidden'

    @commentsview.clear()
    @commentsview.remove()
    @assessmentview.remove()

    $(document).off '.m-point-details' #, @close_by_keyup
    @$el.off '.m-point-details'

    @$el.removeClass('m-point-expanded')
    @$el.addClass('m-point-unexpanded')

    @undelegateEvents()
    @stopListening()
    delete this

    @model.trigger 'change' #trigger a render event
    $('.l-navigate-back').trigger 'click'
    #next()

