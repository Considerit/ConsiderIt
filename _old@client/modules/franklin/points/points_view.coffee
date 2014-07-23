@ConsiderIt.module "Franklin.Points", (Points, App, Backbone, Marionette, $, _) ->
  
  # Defines the high-level point list layout
  class Points.PointsLayout extends App.Views.StatefulLayout
    template: '#tpl_points_layout'

    regions : 
      headerRegion : '.points_heading_region'
      listRegion : '.points_list_region'
      footerRegion : '.points_footer_region'

    initialize : (options={}) ->
      super options

  class Points.CommunityPointsColumn extends Points.PointsLayout
    template: '#tpl_community_points'
    className : => "points_by_community #{@options.valence}s_by_community points_layout"


  class Points.DecisionBoardColumn extends Points.PointsLayout
    className : => "points_on_decision_board #{@options.valence}s_on_decision_board points_layout"

  #############


  # Manages the actual list of points
  class Points.PointsList extends App.Views.CollectionView
    tagName : 'ul'
    className : 'point_list_collectionview'

    initialize : (options = {}) ->
      @itemView = options.itemView
      @emptyView = options.emptyView
      @location = options.location
      super options

    buildItemView : (point, itemview, options) ->
      if itemview == Points.NoCommunityPointsView
        new itemview()
      else
        valence = if point.attributes.is_pro then 'pro' else 'con'
        view = new @itemView
          model : point
          attributes : 
            'data-id': "#{point.id}"
            'role': 'point'
            includers : "#{point.get('includers')}"
            class : "point closed_point #{@location}_point #{valence}"

        view


  # PointsHeading and its two subclasses handles the content displayed
  # at the top of the point list 
  class Points.PointsHeading extends App.Views.ItemView
    template : '#tpl_points_heading'
    className: 'points_heading_view'
    sort : null

    initialize : (options = {}) ->
      super options
      @sort = options.sort || @sort

    serializeData : ->
      header : @getHeaderText()

    processValenceForHeader : ->
      tenant = App.request 'tenant'
      valence = if @options.valence == 'pro' then tenant.getProLabel({capitalize:true,plural:true}) else tenant.getConLabel({capitalize:true,plural:true})
      valence

    getHeaderText : -> @processValenceForHeader()

    requestSort : (sort_by) ->
      @sort = sort_by

      @trigger 'sort', sort_by

    onShow : ->      
      @requestSort(@sort) if @sort
      @listenTo @collection, 'reset', =>  
        @render()

  class Points.DecisionBoardColumnHeader extends Points.PointsHeading
    getHeaderText : ->
      valence = @processValenceForHeader()
      "List Your #{valence}"

  class Points.CommunityPointsHeader extends Points.PointsHeading
    template : '#tpl_community_points_heading'
    is_expanded : false
    sort : 'score'    
    
    initialize : (options = {}) ->
      super options
      @collection = options.collection
      @is_expanded = @setExpandPoints(options.expanded) if options.expanded
      @segment = options.segment

    setExpandPoints : (expand) ->
      @is_expanded = expand
      @render()

      if @is_expanded
        # unexpand when clicking outside of points
        $(document).on 'click.unexpand_points', (ev)  => 
          if $(ev.target).closest('.sort_points_menu_option').length == 0 && $(ev.target).closest('.unexpand_points')[0] != @$el[0] && $('.open_point, .l-dialog-detachable').length == 0
            @trigger 'points:toggle_expanded', true
            ev.stopPropagation()

        $(document).on 'keyup.unexpand_points', (ev) => 
          if ev.keyCode == 27 && $('.open_point, .l-dialog-detachable').length == 0
            @trigger 'points:toggle_expanded', true
            ev.stopPropagation()
      else
        $(document).off '.unexpand_points'
        # @$el.off '.unexpand_points'
        @$el.ensureInView {fill_threshold: .5}

    serializeData : ->
      data = super
      tenant = App.request 'tenant'
      params = _.extend data,
        pros : @options.valence == 'pro'
        sort_by : @sort
        is_expanded : @is_expanded
        sorts : [ 
          { name: 'Persuasiveness', title: 'Considerations that are proportionately better at convincing other people to add them to their pro/con list are rated higher. Newer considerations that have been seen by fewer people may be ranked higher than the most popular considerations.', target: 'persuasiveness'}, 
          { name: 'Popularity', title: 'Considerations that have been added to the most pro/con lists are ranked higher.', target: 'score'}, 
          { name: "Newest", title: 'The newest considerations are shown first.', target: 'created_at' } ]
          # { name: 'Common Ground', title: 'Considerations that tend to be added by both supporters and opposers are ranked higher. Low ranked considerations are more divisive.', target: '-divisiveness'}]
      params

    onRender : ->
      @selectSort()

    getHeaderText : ->
      valence = @processValenceForHeader()
      modifier = switch @sort
        when 'score'
          'Top'
        when 'persuasiveness'
          'Persuasive'
        when 'created_at'
          'New'
        else
          '' 

      tail = if modifier == '' then "for #{App.Entities.Opinion.stance_name(@segment)}" else ''


      $.trim "#{modifier} #{valence} #{tail}"

    selectSort : ->
      @$el.find("[action]").removeClass 'selected'
      @$el.find("[action='#{@sort}']").addClass 'selected'

    events : _.extend {}, Points.PointsList.prototype.events,
      'click .sort_points_menu_option a' : 'sortList'
      'click [action="expand-toggle"]' : 'handleExpandToggle'

    sortList : (ev) ->
      sort_by = $(ev.target).attr('action')
      @requestSort sort_by
      @selectSort()
      ev.stopPropagation()

    handleExpandToggle : (ev) ->
      @trigger 'points:toggle_expanded', @is_expanded
      ev.stopPropagation()

  ######


  # The footer of Community point list just allows for the points to be un/expanded
  class Points.CommunityPointsFooter extends App.Views.ItemView
    template : '#tpl_community_points_footer'
    is_expanded : false
    className : 'community_points_footer_view'

    initialize : (options = {}) ->
      @collection = options.collection

    setExpandPoints : (expanded) ->
      @is_expanded = expanded
      @render()

    onShow : ->
      @listenTo @collection, 'reset', =>  
        @render()

    serializeData : ->
      data = super
      tenant = App.request 'tenant'
      params = _.extend data,
        cnt : _.size @collection.fullCollection
        has_more_points : @collection.state.totalPages > 1
        is_expanded : @is_expanded
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true, plural:true}) else tenant.getConLabel({capitalize:false, plural:true})        

      params

    events : 
      'click [action="expand-toggle"]' : 'handleExpandToggle'

    handleExpandToggle : (ev) ->
      @trigger 'points:toggle_expanded', @is_expanded
      ev.stopPropagation()


  # The footer of Decision Board point list manages adding a new point, both authoring and including
  class Points.DecisionBoardColumnFooter extends App.Views.ItemView
    template : '#tpl_decision_board_points_footer'
    className : 'decision_board_points_footer_view'

    serializeData : ->
      tenant = App.request 'tenant'
      params =  
        label : if @options.valence == 'pro' then tenant.getProLabel({capitalize:true}) else tenant.getConLabel({capitalize:true})
        hide_label : "hide_name-#{@options.valence}"
        is_pro : @options.valence == 'pro'
        direction : if @options.valence == 'pro' then 'left' else 'right'
      params

    onShow : ->  
      @$el.find('.newpoint_nutshell').autosize()
      @$el.find('.newpoint_description').autosize()
      # @$el.find('.position-statement').autosize()

      for el in @$el.find('.newpoint_form .is_counted')
        $(el).NobleCount $(el).siblings('.count'), 
          block_negative: true,
          max_chars : parseInt $(el).siblings('.count').text()       


    events : 
      'click [action="write-point"]' : 'newPoint'
      'click .newpoint-cancel' : 'cancelPoint'
      'click [action="submit-point"]' : 'createPoint'
      # 'blur .newpoint_nutshell' : 'checkIfShouldClose'
      'focusout .newpoint_form' : 'checkIfShouldClose'

    checkIfShouldClose : (ev) ->
      $form = $(ev.currentTarget).closest('.newpoint_form')

      $nutshell = $form.find('.newpoint_nutshell')
      $description = $form.find('.newpoint_description')

      if $nutshell.val().length + $description.val().length == 0
        click_inside = false
        $form.one 'focusin.checkshouldclose', => 
          click_inside = true

        _.delay =>
          $form.off '.checkshouldclose'
          @cancelPoint(ev) if !click_inside
        , 10

    newPoint : (ev) ->
      $(ev.currentTarget).hide()
      $form = $(ev.currentTarget).siblings('.newpoint_form')

      $form.find('.newpoint_nutshell, .newpoint_description').trigger('keyup')
      $form.show()

      if !Modernizr.input.placeholder && @$el.find('label[for="nutshell"]').length == 0
        #$form.find('[placeholder]').simplePlaceholder() 
        #IE hack
        @$el.find('#nutshell').before('<label for="nutshell">Summarize your point (required)</label>')
        @$el.find('#text').before('<label for="text">Additional details (optional)</label>')

      $form.find('.newpoint_nutshell').focus()

 


      @$el.find('.newpoint').addClass 'is_adding_newpoint'
    
    cancelPoint : (ev) ->
      $form = $(ev.currentTarget).closest('.newpoint_form')
      $form.hide()
      $form.siblings('.newpoint_prompt').show()
      $form.find('textarea').val('').trigger('keydown')
      $form.find('label.inline').addClass('empty')

      @$el.find('.newpoint').removeClass 'is_adding_newpoint'

    createPoint : (ev) ->
      $form = $(ev.currentTarget).closest('.newpoint_form')

      point_attributes =
        nutshell : $form.find('.newpoint_nutshell').val()
        text : $form.find('.newpoint_description').val()
        is_pro : $form.find('#is_pro').val() == 'true'
        hide_name : $form.find('.newpoint-anonymous').is(':checked')
        comment_count : 0

      if point_attributes.nutshell.length < 4
        toastr.error 'Sorry, the summary of your point must be longer'
      else if point_attributes.nutshell.length > 140
        toastr.error 'Sorry, the summary of your point must be less than 140 characters.'
      else
        @trigger 'point:please_create_point', point_attributes
        @cancelPoint {currentTarget: $form.find('.newpoint-cancel')}


  # Displayed if there are no Community points in this list
  class Points.NoCommunityPointsView extends App.Views.ItemView
    template : '#tpl_no_community_points'
    className : 'no_community_points_view'