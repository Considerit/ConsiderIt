@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  
  class Points.PointListLayout extends App.Views.StatefulLayout
    template: '#tpl_points'

    regions : 
      headerRegion : '.m-pointlist-header-region'
      listRegion : '.m-pointlist-list-region'
      footerRegion : '.m-pointlist-footer-region'

    initialize : (options={}) ->
      super options

  class Points.ExpandablePointList extends Points.PointListLayout
    template: '#tpl_points_expandable'

  class Points.PeerPointList extends Points.ExpandablePointList
    className : => 
      "m-peer-reasons m-reasons-peer-#{@options.valence}s"

  class Points.UserReasonsList extends Points.PointListLayout
    className : => 
      "m-position-points m-position-#{@options.valence}points"

    onRender : ->
      super

  class Points.PointList extends App.Views.CollectionView
    tagName : 'ul'
    className : 'm-point-list'

    initialize : (options = {}) ->
      @itemView = options.itemView
      @emptyView = options.emptyView
      @location = options.location
      super options

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

  class Points.PointListHeader extends App.Views.ItemView
    template : '#tpl_points_header'
    sort : null

    initialize : (options = {}) ->
      super options
      @sort = options.sort || @sort

    serializeData : ->
      header : @getHeaderText()

    getHeaderText : ->
      valence = if @options.valence == 'pro' then 'Pros' else 'Cons'
      valence

    requestSort : (sort_by) ->
      @sort = sort_by

      @trigger 'sort', sort_by

    onShow : ->      
      @requestSort(@sort) if @sort
      @listenTo @collection, 'reset', =>  
        @render()

  class Points.UserReasonsPointListHeader extends Points.PointListHeader
    getHeaderText : ->
      valence = if @options.valence == 'pro' then 'Pros' else 'Cons'

      "Your #{valence}"


  class Points.ExpandablePointListHeader extends Points.PointListHeader
    template : '#tpl_points_expandable_header'
    browsing : false
    sort : 'score'    
    
    initialize : (options = {}) ->
      super options
      @collection = options.collection
      @browsing = @setBrowsing(options.browsing) if options.browsing
      @segment = options.segment

    setBrowsing : (browsing) ->
      @browsing = browsing
      @render()

      if @browsing
        # when clicking outside of pointlist, close browsing
        $(document).on 'click.m-pointlist-browsing', (ev)  => 
          if $(ev.target).closest('.m-pointlist-sort-option').length == 0 && $(ev.target).closest('.m-pointlist-browsing')[0] != @$el[0] && $('.m-point-expanded, #l-dialog-detachable').length == 0
            @trigger 'points:browsing:toggle', true
            ev.stopPropagation()

        $(document).on 'keyup.m-pointlist-browsing', (ev) => 
          if ev.keyCode == 27 && $('.m-point-expanded, #l-dialog-detachable').length == 0
            @trigger 'points:browsing:toggle', true
            ev.stopPropagation()
      else
        $(document).off '.m-pointlist-browsing'
        # @$el.off '.m-pointlist-browsing'
        @$el.ensureInView {fill_threshold: .5}

    serializeData : ->
      data = super
      tenant = App.request 'tenant:get'
      params = _.extend data,
        pros : @options.valence == 'pro'
        sort_by : @sort
        browsing_all : @browsing
        sorts : [ 
          { name: 'Persuasiveness', title: 'Considerations that are proportionately better at convincing other people to add them to their pro/con list are rated higher. Newer considerations that have been seen by fewer people may be ranked higher than the most popular considerations.', target: 'persuasiveness'}, 
          { name: 'Popularity', title: 'Considerations that have been added to the most pro/con lists are ranked higher.', target: 'score'}, 
          { name: "Newest", title: 'The newest considerations are shown first.', target: 'created_at' } ]
          # { name: 'Common Ground', title: 'Considerations that tend to be added by both supporters and opposers are ranked higher. Low ranked considerations are more divisive.', target: '-divisiveness'}]
      params

    onRender : ->
      @selectSort()

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

    events : _.extend {}, Points.PointList.prototype.events,
      'click .m-pointlist-sort-option a' : 'sortList'
      'click [data-target="browse-toggle"]' : 'handleToggleBrowse'

    sortList : (ev) ->
      sort_by = $(ev.target).data('target')
      @requestSort sort_by
      @selectSort()
      ev.stopPropagation()

    handleToggleBrowse : (ev) ->
      @trigger 'points:browsing:toggle', @browsing
      ev.stopPropagation()
      # if @state != Points.States.collapsed
      #   @toggleBrowse !@browsing
      #   ev.stopPropagation()

  class Points.ExpandablePointListFooter extends App.Views.ItemView
    template : '#tpl_points_expandable_footer'
    browsing : false

    initialize : (options = {}) ->
      @collection = options.collection

    setBrowsing : (browsing) ->
      @browsing = browsing
      @render()

    onShow : ->
      @listenTo @collection, 'reset', =>  
        @render()

    serializeData : ->
      data = super
      tenant = App.request 'tenant:get'
      params = _.extend data,
        cnt : _.size @collection.fullCollection
        has_more_points : @collection.state.totalPages > 1
        browsing_all : @browsing
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true, plural:true}) else tenant.getConLabel({capitalize:false, plural:true})        

      params

    events : 
      'click [data-target="browse-toggle"]' : 'handleToggleBrowse'

    handleToggleBrowse : (ev) ->
      @trigger 'points:browsing:toggle', @browsing
      ev.stopPropagation()

  class Points.UserReasonsPointListFooter extends App.Views.ItemView
    template : '#tpl_points_user_reasons_footer'

    serializeData : ->
      tenant = App.request 'tenant:get'
      params =  
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true}) else tenant.getConLabel({capitalize:true})
        hide_label : "hide_name-#{@options.valence}"
        is_pro : @options.valence == 'pro'
        direction : if @options.valence == 'pro' then 'left' else 'right'
      params

    onShow : ->  
      @$el.find('.m-newpoint-nutshell').autosize()
      @$el.find('.m-newpoint-description').autosize()
      @$el.find('.m-position-statement').autosize()

      for el in @$el.find('.m-newpoint-form .is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()       


    events : 
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

      @$el.find('.m-newpoint').addClass 'm-newpoint-adding'
    
    cancelPoint : (ev) ->
      $form = $(ev.currentTarget).closest('.m-newpoint-form')
      $form.hide()
      $form.siblings('.m-newpoint-new').show()
      $form.find('textarea').val('').trigger('keydown')
      $form.find('label.inline').addClass('empty')

      @$el.find('.m-newpoint').removeClass 'm-newpoint-adding'

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


  class Points.PeerEmptyView extends App.Views.ItemView
    template : '#tpl_points_peer_empty'
    className : 'points_peer_empty'