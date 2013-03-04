class ConsiderIt.PointDetailsView extends Backbone.View

  @template : _.template $("#tpl_point_details").html()

  initialize : (options) -> 
    @proposal = options.proposal
    @listenTo @proposal.view, 'point_details:staged', -> @remove()

  render : () -> 
    @$el.html ConsiderIt.PointDetailsView.template($.extend({}, @model.attributes, {
        adjusted_nutshell : this.model.adjusted_nutshell(),
        user : ConsiderIt.users[this.model.get('user_id')],
        proposal : @proposal.model.attributes
      }))
    
    @commentsview = new ConsiderIt.CommentListView({
      collection: ConsiderIt.comments[@model.id], 
      el: @$el.find('.m-point-discussion')
      commentable_id: @model.id,
      commentable_type: 'Point'})
    @commentsview.renderAllItems()
    
    $('html, body').stop(true, true);
    @center_overlay()
    $('html, body').animate {scrollTop: @$el.offset().top - 50}, 1000

    # when clicking outside of point, close it
    $(document).click => @close_details()
    @$el.click (e) => e.stopPropagation()
    $(document).keyup (ev) => @close_by_keyup(ev)

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

  close_details : (ev) ->
    @commentsview.clear()
    @commentsview.remove()
    @$el.html ''
    @remove()
    $(document)
      .unbind 'click', @close_details
    $(document)
      .unbind 'keyup', @close_by_keyup

    @proposal.view.trigger 'point_details:closed'



