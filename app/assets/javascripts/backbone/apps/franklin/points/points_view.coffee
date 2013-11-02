@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  
  class Points.PointList extends App.Views.CompositeView
    template: '#tpl_points'
    itemViewContainer : 'ul.m-point-list' 
    sort : null
    itemView : App.Franklin.Point.PointView

    initialize : (options = {}) ->
      @state = options.state
      super options
      @sort = options.sort || @sort

    onRender : ->
      @setDataState @state

    setDataState : (state) ->
      @$el.attr 'data-state', state
      @$el.data 'state', state
      @state = state 

    onShow : ->
      if @sort
        @requestSort @sort

      @listenTo @collection, 'reset', =>
        @render()

      # @listenTo @collection, 'add', =>
      #   @requestSort @sort

    serializeData : ->
      header : @getHeaderText()

    getHeaderText : ->
      valence = if @options.valence == 'pro' then 'Pros' else 'Cons'
      valence


    buildItemView : (point, itemview, options) ->
      if itemview == Points.PeerEmptyView

        new itemview()
      else
        valence = if point.attributes.is_pro then 'pro' else 'con'
        view = new @itemView
          model : point
          attributes : 
            'data-id': "#{point.id}"
            'data-role': 'm-point'
            includers : "#{point.get('includers')}"
            class : "m-point m-point-unexpanded m-point-#{@location} #{valence}"

        view

    requestSort : (sort_by) ->
      @sort = sort_by

      @trigger 'sort', sort_by

    events : {}

  class Points.ExpandablePointList extends Points.PointList
    template: '#tpl_points_expandable'

    ui : 
      browse_header : '.m-pointlist-browse-header'
      browse_footer : '.m-pointlist-browse'

    initialize : (options = {}) ->
      super options
      @browsing = false

    serializeData : ->
      data = super
      tenant = App.request 'tenant:get'
      params = _.extend data,
        pros : @options.valence == 'pro'
        cnt : _.size @collection.fullCollection
        sort_by : @sort
        browsing_all : @browsing
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true, plural:true}) else tenant.getConLabel({capitalize:false, plural:true})        
        has_points : @collection.length > 0
        sorts : [ 
          { name: 'Persuasiveness', title: 'Considerations that are proportionately better at convincing other people to add them to their pro/con list are rated higher. Newer considerations that have been seen by fewer people may be ranked higher than the most popular considerations.', target: 'persuasiveness'}, 
          { name: 'Popularity', title: 'Considerations that have been added to the most pro/con lists are ranked higher.', target: 'score'}, 
          { name: "Newest", title: 'The newest considerations are shown first.', target: 'created_at' } ]
          # { name: 'Common Ground', title: 'Considerations that tend to be added by both supporters and opposers are ranked higher. Low ranked considerations are more divisive.', target: '-divisiveness'}]
      params

    onRender : ->
      super
      @bindUIElements()      
      @selectSort()
      @ui.browse_header.css('display', if @browsing then 'block' else 'none') 

    getHeaderText : ->
      valence = if @options.valence == 'pro' then 'Pros' else 'Cons'
      modifier = switch @sort
        when 'score'
          'Top'
        when 'persuasiveness'
          'Persuasive'
        when 'created_at'
          'New'
        else
          '' 

      tail = if modifier == '' then "for #{App.Entities.Position.stance_name(@segment)}" else ''


      $.trim "#{modifier} #{valence} #{tail}"


    selectSort : ->
      @$el.find("[data-target]").removeClass 'selected'
      @$el.find("[data-target='#{@sort}']").addClass 'selected'

    toggleBrowse : (browse) ->
      @browsing = browse

      if browse
        @toggleBrowseOn()
      else
        @toggleBrowseOff()


    toggleBrowseOn : ->

      @ui.browse_footer.find('.m-pointlist-browse-toggle').text "Stop browsing"
      @ui.browse_header.slideDown()

      # when clicking outside of pointlist, close browsing
      $(document).on 'click.m-pointlist-browsing', (ev)  => 
        if $(ev.target).closest('.m-pointlist-sort-option').length == 0 && $(ev.target).closest('.m-pointlist-browsing')[0] != @$el[0] && $('.m-point-expanded, #l-dialog-detachable').length == 0
          @toggleBrowse false
          ev.stopPropagation()

      $(document).on 'keyup.m-pointlist-browsing', (ev) => 
        if ev.keyCode == 27 && $('.m-point-expanded, #l-dialog-detachable').length == 0
          @toggle_browse false 
      @trigger 'points:browsing'


    toggleBrowseOff : ->
      tenant = App.request 'tenant:get'
      cnt = _.size @collection.fullCollection
      label = if @options.valence == 'pro' then tenant.getProLabel({capitalize:true, plural:true}) else tenant.getConLabel({capitalize:false, plural:true})        

      @ui.browse_footer.find('.m-pointlist-browse-toggle').text "View all #{cnt} #{label}"      
      @ui.browse_header.slideUp()

      $(document).off '.m-pointlist-browsing'
      @$el.off '.m-pointlist-browsing'
      @$el.find('.m-pointlist-header').ensureInView {fill_threshold: .5}

      @trigger 'points:browsing:off'

    events : _.extend {}, Points.PointList.prototype.events,
      'click .m-pointlist-sort-option a' : 'sortList'
      'click [data-target="browse-toggle"]' : 'handleToggleBrowse'

    sortList : (ev) ->
      sort_by = $(ev.target).data('target')
      @requestSort sort_by
      @selectSort()
      ev.stopPropagation()

    handleToggleBrowse : (ev) ->
      if @state != Points.States.collapsed
        @toggleBrowse !@browsing
        ev.stopPropagation()


  class Points.PeerEmptyView extends App.Views.ItemView
    template : '#tpl_points_peer_empty'
    className : 'points_peer_empty'

  class Points.PeerPointList extends Points.ExpandablePointList
    sort : 'score'    
    location : 'peer'
    className : => "m-peer-reasons m-reasons-peer-#{@options.valence}s"
    itemView : App.Franklin.Point.PeerPointView
    emptyView : Points.PeerEmptyView

    events : _.extend {}, Points.ExpandablePointList.prototype.events
    
    initialize : (options = {}) ->
      super options


  class Points.UserReasonsList extends Points.PointList
    template: '#tpl_points_user_reasons'
    location : 'position'
    className : => "m-position-points m-position-#{@options.valence}points"
    itemView : App.Franklin.Point.PositionPointView

    serializeData : ->
      data = super

      tenant = App.request 'tenant:get'
      _.extend data, 
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true}) else tenant.getConLabel({capitalize:true})
        hide_label : "hide_name-#{@options.valence}"
        is_pro : @options.valence == 'pro'

    getHeaderText : ->
      valence = if @options.valence == 'pro' then 'Pros' else 'Cons'

      "Your #{valence}"

    onShow : ->  
      super   
      @$el.find('.m-newpoint-nutshell').autosize()
      @$el.find('.m-newpoint-description').autosize()
      @$el.find('.m-position-statement').autosize()

      for el in @$el.find('.m-newpoint-form .is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()       


    events : _.extend Points.PointList.prototype.events,
      'click .m-newpoint-new' : 'newPoint'
      'click .m-newpoint-cancel' : 'cancelPoint'
      'click .m-newpoint-create' : 'createPoint'

    newPoint : (ev) ->
      $(ev.currentTarget).hide()
      $form = $(ev.currentTarget).siblings('.m-newpoint-form')

      $form.find('.m-newpoint-nutshell, .m-newpoint-description').trigger('keyup')
      $form.show()

      if !Modernizr.input.placeholder
        $form.find('[placeholder]').simplePlaceholder() 
      else
        $form.find('.m-newpoint-nutshell').focus()
    
    cancelPoint : (ev) ->
      $form = $(ev.currentTarget).closest('.m-newpoint-form')
      $form.hide()
      $form.siblings('.m-newpoint-new').show()
      $form.find('textarea').val('').trigger('keydown')
      $form.find('label.inline').addClass('empty')

    createPoint : (ev) ->
      $form = $(ev.currentTarget).closest('.m-newpoint-form')

      point_attributes =
        nutshell : $form.find('.m-newpoint-nutshell').val()
        text : $form.find('.m-newpoint-description').val()
        is_pro : $form.find('.m-newpoint-is_pro').val() == 'true'
        hide_name : $form.find('.m-newpoint-anonymous').is(':checked')
        comment_count : 0

      if point_attributes.nutshell.length < 4
        toastr.error 'Sorry, the summary of your point must be longer'
      else if point_attributes.nutshell.length > 140
        toastr.error 'Sorry, the summary of your point must be less than 140 characters.'
      else
        @trigger 'point:create:requested', point_attributes
        @cancelPoint {currentTarget: $form.find('.m-newpoint-cancel')}