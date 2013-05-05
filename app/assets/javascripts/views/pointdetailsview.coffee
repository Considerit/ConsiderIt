class ConsiderIt.PointDetailsView extends Backbone.View

  #@template : _.template $("#tpl_point_details").html()

  initialize : (options) -> 
    @proposal = options.proposal
    #@listenTo @proposal.view, 'point_details:staged', => @remove()
    @listenTo @model, 'point:included', => @close_details()

    @listenTo @model, 'point:removed', => @close_details()

  render : () ->    
    @transparent_els = @proposal.view.$el.find("[data-role='m-point']:not([data-id='#{@model.id}'])")
    @hidden_els = @proposal.view.$el.find(".m-newpoint, .m-position-heading, .m-pointlist-pagination, .m-stance, .l-message-speaker, .l-message-listener, .m-position-message-body > .t-bubble, .m-results-summary, .m-results-responders.summary")

    @$el.toggleClass 'm-point-expanded m-point-unexpanded'

    # @$el.hide()

    if ConsiderIt.current_tenant.get('assessment_enabled') && @proposal.model.get('active') 
      
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
    @$el.find('.m-point-wrap').append($comment_el)
    
    @commentsview = new ConsiderIt.CommentListView({
      collection: ConsiderIt.comments[@model.id]
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
      @$el.find('.m-point-nutshell ').editable {
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @proposal.model.attributes.long_id, @model.id
          type: 'textarea'
          name: 'nutshell'
        }
      @$el.find('.m-point-details-description ').editable {
          resource: 'point'
          pk: @model.id
          url: Routes.proposal_point_path @proposal.model.attributes.long_id, @model.id
          type: 'textarea'
          name: 'text'
        }


    $('body').stop(true, true)
    $('body').animate {scrollTop: @$el.offset().top - 50}, 1000, =>

      @assessmentview.render()

      @commentsview.renderAllItems()

      @transparent_els.animate { opacity: .1 } 
      @hidden_els.css {visibility: 'hidden'}

      # when clicking outside of point, close it
      $(document).on 'click.m-point-details', (ev)  => 
        if !$(ev.target).data('target')
          @close_details()
      @$el.on 'click.m-point-details', (ev) => 
        if !$(ev.target).data('target')
          ev.stopPropagation()
      $(document).on 'keyup.m-point-details', (ev) => @close_by_keyup(ev)

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

  close_details : ->
    @$el.find('.m-point-discussion').slideUp 100
    $('body').animate {scrollTop: @$el.offset().top - 50}, 400, =>

      @commentsview.clear()
      @commentsview.remove()
      @assessmentview.remove()
      @$el.find('.m-point-include-wrap').css 'display', 'none'

      $(document).off 'click.m-point-details' #, @close_details
      $(document).off 'keyup.m-point-details' #, @close_by_keyup
      @$el.off 'click.m-point-details'

      @$el.toggleClass('m-point-expanded m-point-unexpanded')
      @transparent_els.css('opacity', '')
      @hidden_els.css {visibility: ''}


      @proposal.view.trigger 'point_details:closed'

      @model.trigger 'change' #trigger a render event
      @undelegateEvents()
      delete this


