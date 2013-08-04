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

    @listenTo @commentsview, 'CommentListView:new_comment_added', => @model.set('comment_count', @model.comments.length )


    if ConsiderIt.request('user:current').is_logged_in()
      if !ConsiderIt.PointDetailsView.follow_tpl
        ConsiderIt.PointDetailsView.follow_tpl = _.template( $('#tpl_point_follows').html() )
      @$el.find('.m-point-follow').append( ConsiderIt.PointDetailsView.follow_tpl( _.extend( {}, @model.attributes,
        already_follows : ConsiderIt.request('user:current').is_following('Point', @model.id)
      )))

    #TODO: if user logs in as admin, need to do this
    if ConsiderIt.request('user:current').id == @model.get('user_id') #|| ConsiderIt.request('user:current').is_admin()
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

      window.ensure_el_in_view(@$el, .5, 100)

      @assessmentview.render() if @assessmentview?
      @commentsview.renderAllItems()
  
      @$el.find('.m-point-wrap > *').css 'visibility', ''

      # when clicking outside of point, close it
      $(document).on 'click.m-point-details', (ev)  => 
        if ($(ev.target).closest('.m-point-expanded').length == 0 || $(ev.target).closest('.m-point-expanded').data('id') != @model.id) && $(ev.target).closest('.editable-buttons').length == 0
          @close_details( $(ev.target).closest('[data-role="m-point"]').length == 0 && $(ev.target).closest('.l-navigate-wrap').length == 0 ) 

      $(document).on 'keyup.m-point-details', (ev) => @close_details() if ev.keyCode == 27 && $('#l-dialog-detachable').length == 0

      next()

    this
    

  events : 
    #'click .m-point-details-close' : 'close_details'
    'ajax:success .follow form' : 'toggle_follow'
    'ajax:success .unfollow form' : 'toggle_follow'

  toggle_follow : (ev, data) -> 
    $(ev.currentTarget).parent().addClass('hide').siblings('.follow, .unfollow').removeClass('hide')
    ConsiderIt.request('user:current').set_following(data.follow.follow)

  close_details : (go_back) ->
    go_back ?= true
    @$el.find('.m-point-wrap > *').css 'visibility', 'hidden'

    @commentsview.clear()
    @commentsview.remove()
    @assessmentview.remove() if @assessmentview?

    $(document).off '.m-point-details' #, @close_by_keyup
    @$el.off '.m-point-details'

    @$el.removeClass('m-point-expanded')
    @$el.addClass('m-point-unexpanded')

    @undelegateEvents()
    @stopListening()
    
    @model.trigger 'change' #trigger a render event
    ConsiderIt.app.go_back_crumb() if go_back
    #next()

