class ConsiderIt.PointDetailsView extends Backbone.View

  @template : _.template $("#tpl_point_details").html()

  initialize : (options) -> 
    @proposal = options.proposal
    @listenTo @proposal.view, 'point_details:staged', => @remove()

  render : () -> 
    @$el.hide()

    # existing_follows = followable.follows.where(:user_id => current_user.id).first
    # already_follows = !existing_follows.nil? && existing_follows.follow    
    @$el.html ConsiderIt.PointDetailsView.template($.extend({}, @model.attributes, {
        adjusted_nutshell : @model.adjusted_nutshell()
        user : ConsiderIt.users[this.model.get('user_id')]
        proposal : @proposal.model.attributes,
        already_follows : ConsiderIt.current_user.is_following('Point', @model.id)
      }))
    
    @commentsview = new ConsiderIt.CommentListView({
      collection: ConsiderIt.comments[@model.id], 
      el: @$el.find('.m-point-discussion')
      commentable_id: @model.id,
      commentable_type: 'Point'})
    @commentsview.renderAllItems()

    if ConsiderIt.current_tenant.get('assessment_enabled') && @proposal.model.get('active') 
      @assessmentview = new ConsiderIt.AssessmentView({
        model : @model
        el: @$el.find('.m-point-assessment-wrap'), 
        proposal : @proposal
      })
      @assessmentview.render()

    # when clicking outside of point, close it
    $(document).click => @close_details()
    @$el.click (e) => 
      if !$(e.target).data('target')
        e.stopPropagation()
    $(document).keyup (ev) => @close_by_keyup(ev)

    #TODO: if user logs in as admin, need to do this
    if ConsiderIt.current_user.id == @model.get('user_id') || ConsiderIt.roles.is_admin
      @$el.find('.m-point-details-nutshell ').editable {
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

    $('body').prepend('<div id="lightbox">')
    @$el.show()

    $unexpanded_point = $("[data-id='#{@model.cid}']")
    
    if false && $unexpanded_point.length > 0
      @$el.css {left: $unexpanded_point.offset().left - @proposal.view.$el.offset().left - (if @model.get('is_pro') == true then 0 else @$el.width()), top: $unexpanded_point.offset().top - @proposal.view.$el.offset().top }
    else
      @center_overlay()

    $('html, body').stop(true, true)
    #@center_overlay()
    $('html, body').animate {scrollTop: @$el.offset().top - 50}, 1000

    this

  close_by_keyup : (ev) ->
    if ev.keyCode == 27 && $('#registration_overlay').length == 0
      @close_details()    

  center_overlay : () ->
    $overlay = $('#point_details_overlay')
    @$el.offset 
      #top: $('body').scrollTop() + window.innerHeight / 2 - @$el.outerHeight() / 2  
      top: $('body').scrollTop() + 50 #window.innerHeight / 2 - @$el.outerHeight() / 2     
      left: window.innerWidth / 2 - @$el.outerWidth() / 2

  events : 
    'click .m-point-details-close' : 'close_details'
    'ajax:success .follow form' : 'toggle_follow'
    'ajax:success .unfollow form' : 'toggle_follow'

  toggle_follow : (ev, data) -> 
    console.log $(ev.currentTarget)
    $(ev.currentTarget).parent().addClass('hide').siblings('.follow, .unfollow').removeClass('hide')
    ConsiderIt.current_user.set_following(data.follow.follow)

  close_details : (ev) ->
    $('#lightbox').remove()
    @commentsview.clear()
    @commentsview.remove()
    if @assessmentview
      @assessmentview.remove()

    @$el.html ''
    @remove()
    $(document)
      .unbind 'click', @close_details
    $(document)
      .unbind 'keyup', @close_by_keyup

    @proposal.view.trigger 'point_details:closed'


