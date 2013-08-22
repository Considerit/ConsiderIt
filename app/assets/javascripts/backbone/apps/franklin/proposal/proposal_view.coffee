@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.ProposalDescriptionView extends App.Views.ItemView
    template : '#tpl_proposal_description'
    className : 'm-proposal-description-wrap'

    show_details : true

    editable : =>
      App.request 'auth:can_edit_proposal', @model    

    serializeData : ->
      user = @model.getUser()
      _.extend {}, @model.attributes,
        avatar : App.request('user:avatar', user, 'large' )
        description_detail_fields : @model.description_detail_fields()
        show_details : @show_details

    initialize : ->
      if @editable()
        if !Proposal.ProposalDescriptionView.editable_fields
          fields = [
            ['.m-proposal-description-title', 'name', 'textarea'], 
            ['.m-proposal-description-body', 'description', 'textarea'] ]

          editable_fields = _.union fields,
            ([".m-proposal-description-detail-field-#{f}", f, 'textarea'] for f in App.request('proposal:description_fields'))          

          Proposal.ProposalDescriptionView.editable_fields = editable_fields

        @editable_fields = Proposal.ProposalDescriptionView.editable_fields

    onRender : ->
      @stickit()
      _.each @editable_fields, (field) =>
        [selector, name, type] = field 

        @$el.find(selector).editable
          resource: 'proposal'
          pk: @long_id
          disabled: @state == 0 && @model.get('published')
          url: Routes.proposal_path @model.long_id
          type: type
          name: name
          success : (response, new_value) => @model.set(name, new_value)

    onShow : ->


    bindings : 
      '.m-proposal-description-title' : 
        observe : ['name', 'description']
        onGet : (values) -> @model.title()
      '.m-proposal-description-body' : 
        observe : 'description'
        updateMethod: 'html'
        onGet : (value) => htmlFormat(value)

    events : 
      'click .hidden' : 'showDetails'
      'click .showing' : 'hideDetails'      

    showDetails : (ev) ->
      $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

      $block.find('.m-proposal-description-detail-field-full').slideDown();
      $block.find('.hidden')
        .text('hide')
        .toggleClass('hidden showing');

      ev.stopPropagation()

    hideDetails : (ev) ->
      $block = $(ev.currentTarget).closest('.m-proposal-description-detail-field')

      if $(document).scrollTop() > $block.offset().top
        $('body').animate {scrollTop: $block.offset().top}, 1000

      $block.find('.m-proposal-description-detail-field-full').slideUp(1000);
      $block.find('.showing')
        .text('show')
        .toggleClass('hidden showing');

      ev.stopPropagation()



  ##############################################
  #### PositionView
  ##############################################
  class Proposal.PositionLayout extends App.Views.Layout
    template : '#tpl_position_layout'
    className : 'm-proposal'

    regions : 
      proposalRegion : '.m-proposal-description-region'
      positionRegion : '.m-position-crafting-region'
      footerRegion : '.m-position-footer-region'

  class Proposal.PositionProposalDescription extends Proposal.ProposalDescriptionView

  class Proposal.PositionCraftingLayout extends App.Views.Layout
    template : '#tpl_position_crafting'
    className : 'm-position-crafting'

    regions : 
      reasonsRegion : '.m-position-reasons-region'
      stanceRegion : '.m-position-stance-region'
      explanationRegion : '.m-position-explanation-region'

    serializeData : ->
      tenant = App.request 'tenant:get'
      _.extend {}, tenant.attributes

    # Hacky to put this here...need to log point views for peer points
    events : 
      'mouseenter .m-point-peer' : 'log_point_view'

    logPointView : (ev) ->
      pnt = $(ev.currentTarget).data('id')
      @trigger 'point:viewed', pnt

  class Proposal.PositionFooterView extends App.Views.ItemView
    template : '#tpl_position_footer'
    className : 'm-position-footer l-message m-position-your_action'

    serializeData : ->
      _.extend {},
        active : @model.getProposal().get 'active'
        updating : @model && @model.get 'published'
        follows : @model.getUser().isFollowing('Proposal', @model.id)

    events : 
      'click .submit' : 'handleSubmitPosition'
      'click .m-position-cancel' : 'handleCanceled'

    handleSubmitPosition : (ev) ->
      @trigger 'position:submit-requested'

    handleCanceled : (ev) ->
      @trigger 'position:canceled'

  class Proposal.PositionReasonsLayout extends App.Views.Layout
    template : '#tpl_position_reasons'
    className : 'm-reasons'

    regions : 
      'peerProsRegion' : '.m-reasons-peer-points-pros'
      'peerConsRegion' : '.m-reasons-peer-points-cons'
      'positionProsRegion' : '.m-pro-con-list-propoints-region'
      'positionConsRegion' : '.m-pro-con-list-conpoints-region'

  class Proposal.PositionStance extends App.Views.ItemView
    template : '#tpl_position_stance'
    className : 'm-stance'

    serializeData : ->
      tenant = App.request 'tenant:get'
      _.extend {}, tenant.attributes

    slider : 
      max_effect : 65 
    
    slider_ui_init : 
      handles: 1
      connect: "lower"
      scale: [100, -100]
      width: 300

    ui : 
      slider : '.noUiSlider'
      neutral_label : '.m-stance-label-neutral'
      support_label : '.m-stance-label-support'
      oppose_label : '.m-stance-label-oppose'

    onShow : ->
      @bindUIElements()
      @listenTo @model, 'change:stance', => 
        @ui.slider.noUiSlider('destroy')
        @createSlider()

      @createSlider()

    createSlider : ->
      @value = @model.get('stance') * 100

      @ui.slider.noUiSlider 'init',
        _.extend {}, @slider_ui_init, 
          start : @model.get('stance') * 100  
          change : =>
            @sliderChange(@ui.slider.noUiSlider('value')[1])

      is_neutral = Math.abs(@model.get('stance') * 100) < 5
      if !is_neutral
        @ui.neutral_label.css('opacity', 0)

    sliderChange : (new_value) -> 
      return unless isFinite(new_value)

      if Math.abs(new_value) < 5
        @ui.neutral_label.css('opacity', 1)
        @is_neutral = true
      else if @is_neutral
        @ui.neutral_label.css('opacity', 0)
        @is_neutral = false

      @value = new_value

      @model.set('stance', @value / 100, {silent : true})

      size = @slider.max_effect / 100 * @value
      @ui.oppose_label.css('font-size', 100 - size + '%')
      @ui.support_label.css('font-size', 100 + size + '%')



  class Proposal.PositionExplanation extends App.Views.ItemView
    template : '#tpl_position_explanation'
    className : 'position_statement'

    onRender : ->
      @stickit()

    bindings : 
      'textarea[name="explanation"]' : 'explanation'



  ##############################################
  #### ProposalAggregateView
  ##############################################
  class Proposal.AggregateLayout extends App.Views.Layout
    template : '#tpl_aggregate_layout'
    className : 'm-proposal'
    regions : 
      proposalRegion : '.m-proposal-description-region'
      histogramRegion : '.m-histogram-region'
      reasonsRegion : '.m-reasons-region'

    serializeData : ->
      participants = @model.getParticipants()
      user_position = @model.getUserPosition()
      _.extend {}, @model.attributes,
        tile_size : @getTileSize()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )
        call : if user_position && user_position.get('published') then 'Update your position' else 'What do you think?'


    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 110

      Math.min 50, 
        ConsiderIt.utils.get_tile_size(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.getParticipants().length)

    onRender : ->
      @$el.attr('data-state', 4)


    implodeParticipants : ->
      @trigger 'results:implode_participants'
      $participants = @$el.find('.l-message-speaker .l-group-container')
      $participants.find('.avatar').css {position: '', zIndex: '', '-ms-transform': "", '-moz-transform': "", '-webkit-transform': "", transform: ""}

      @$el.find('.m-bar-percentage').fadeOut()
      @$el.find('.m-histogram').fadeOut =>
        @$el.find('.m-histogram').css('opacity', '')
        $participants.fadeIn()

    explodeParticipants : (transition = true) ->
      @trigger 'results:explode_participants'

      modern = Modernizr.csstransforms && Modernizr.csstransitions

      $participants = @$el.find('.l-message-speaker .l-group-container')

      $histogram = @$el.find('.m-histogram')

      if !modern || !transition
        @$el.find('.m-histogram').css 'opacity', 1
        $participants.fadeOut()
      else
        speed = 750
        from_tile_size = $participants.find('.avatar:first').width()
        to_tile_size = $histogram.find(".avatar:first").width()
        ratio = to_tile_size / from_tile_size

        # compute all offsets first, before applying changes, for perf reasons
        positions = {}
        $user_els = $participants.find('.avatar')
        for participant in $user_els
          $from = $(participant)
          id = $from.data('id')
          $to = $histogram.find("#avatar-#{id}")

          to_offset = $to.offset()
          from_offset = $from.offset()

          offsetX = to_offset.left - from_offset.left
          offsetY = to_offset.top - from_offset.top

          offsetX -= (from_tile_size - to_tile_size)/2
          offsetY -= (from_tile_size - to_tile_size)/2

          positions[id] = [offsetX, offsetY]

        for participant in $user_els
          $from = $(participant)
          id = $from.data('id')
          [offsetX, offsetY] = positions[id]
          
          $from.css 
            #'-o-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-ms-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-moz-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            '-webkit-transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)",
            'transform': "scale(#{ratio},#{ratio}) translate(#{ 1/ratio * offsetX}px,#{ 1/ratio * offsetY}px)"

        _.delay => 
          $histogram.css { opacity: 1, display: '' }
          #window.delay 25, -> 
          $participants.fadeOut()
          #@$el.find('.m-bar-percentage').fadeIn()
        , speed + 150




  class Proposal.AggregateProposalDescription extends Proposal.ProposalDescriptionView


  class Proposal.AggregateHistogram extends App.Views.ItemView
    template : '#tpl_aggregate_histogram'
    className : 'm-histogram'

    serializeData : ->
      _.extend {}, @model.attributes,
        histogram : @options.histogram

    events : 
      'mouseenter .m-histogram-bar:not(.m-bar-is-selected)' : 'selectBar'
      'click .m-histogram-bar:not(.m-bar-is-hard-selected)' : 'selectBar'
      'click .m-bar-is-hard-selected' : 'deselectBar'
      'mouseleave .m-histogram-bar' : 'deselectBar'
      'keypress' : 'deselectBar'
      'mouseenter .m-histogram-bar:not(.m-bar-is-hard-selected) [data-target="user_profile_page"]' : 'preventProfile'

    preventProfile : (ev) ->
      ev.stopPropagation()
      $(ev.currentTarget).parent().trigger('mouseenter')

    highlightUsers : (users, highlight = true) ->

      selector = ("#avatar-#{uid}" for uid in users).join(',')

      @$el.css 'visibility', 'hidden'
      if highlight
        @$el.addClass 'm-histogram-segment-selected'
        @$el.find('.avatar').hide()        
        @$el.find(selector).css {'display': '', 'opacity': 1}
      else
        @$el.removeClass 'm-histogram-segment-selected'
        @$el.find('.avatar').css {'display': '', 'opacity': ''} 
      @$el.css 'visibility', ''



    selectBar : (ev) ->
      return if $('.m-point-expanded').length > 0
      $target = $(ev.currentTarget)
      hard_select = ev.type == 'click'

      if ( hard_select || @$el.find('.m-bar-is-hard-selected').length == 0 )
        @$el.addClass 'm-histogram-segment-selected'
        #@$el.find('.m-bar-percentage').hide()


        $bar = $target.closest('.m-histogram-bar')
        # bubble_offset = $bar.offset().top - @$el.closest('.l-message-body').offset().top + 20

        @$el.hide()

        bucket = 6 - $bar.attr('bucket')
        $('.m-bar-is-selected', @$el).removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')
        $bar.addClass("m-bar-is-selected #{if hard_select then 'm-bar-is-hard-selected' else 'm-bar-is-soft-selected'}")


        fld = "score_stance_group_#{bucket}"

        @trigger 'histogram:segment_results', bucket


        @$el.find('.l-message-speaker').css('z-index': 999)

        #######
        # when clicking outside of bar, close it
        if hard_select
          $(document).on 'click.histogram', (ev) => @closeBarClick(ev)
          $(document).on 'keyup.histogram', (ev) => @closeBarKey(ev)
          ev.stopPropagation()
        #######

        @$el.show()

    closeBarClick : (ev) -> @deselectBar() if $(ev.target).closest('.m-results-responders').length == 0

    closeBarKey : (ev) -> @deselectBar() if ev.keyCode == 27 && $('#l-dialog-detachable').children().length == 0 && $('.m-point-expanded').length == 0
    
    deselectBar : (ev) ->

      $selected_bar = @$el.find('.m-bar-is-selected')
      return if $selected_bar.length == 0 || (ev && ev.type == 'mouseleave' && $selected_bar.is('.m-bar-is-hard-selected')) || $('.m-point-expanded').length > 0

      @$el.removeClass 'm-histogram-segment-selected'
      #@$el.find('.m-bar-percentage').show()

      hiding = @$el.find('.m-point-list, .m-results-pro-con-list-who')
      hiding.css 'visibility', 'hidden'

      @trigger 'histogram:segment_results', 'all'

      @$el.find('.l-message-speaker').css('z-index': '')

      hiding.css 'visibility', ''

      $selected_bar.removeClass('m-bar-is-selected m-bar-is-hard-selected m-bar-is-soft-selected')

      $(document).off 'click.histogram'
      $(document).off 'keyup.histogram'



  class Proposal.AggregateReasons extends App.Views.Layout
    template : '#tpl_aggregate_reasons'
    className : 'm-aggregate-reasons'
    regions : 
      prosRegion : '.m-aggregated-propoints-region'
      consRegion : '.m-aggregated-conpoints-region'

    events : 
      'click .point_filter:not(.selected)' : 'sortAll'

    updateHeader : (segment) ->
      if segment == 'all'
        aggregate_heading = @$el.find '.m-results-pro-con-list-who-all'
        aggregate_heading.siblings('.m-results-pro-con-list-who-others').hide()
        aggregate_heading.show()
      else 
        others = @$el.find '.m-results-pro-con-list-who-others'
        others.siblings('.m-results-pro-con-list-who-all').hide()
        group_name = App.Entities.Position.stance_name segment
        others
          .html("The most compelling considerations for us <span class='group_name'>#{group_name}</span>")
          .show()


  ##############################################
  #### ProposalSummaryView
  ##############################################

  class Proposal.ProposalSummaryView extends App.Views.Layout
    template : '#tpl_proposal_summary'
    tagName: 'li'
    className : 'm-proposal'

    regions : 
      summaryRegion : '.m-results-summary-region'
      proposalRegion : '.m-proposal-description-region'

    initialize : (options = {}) ->


    serializeData : ->
      user_position = @model.getUserPosition()

      params = _.extend {}, @model.attributes, 
        call : if user_position && user_position.get('published') then 'Update your position' else 'What do you think?'
      params

    onRender : ->
      @$el.attr('data-state', 0)
      @$el.attr('data-visibility', 'unpublished') if !@model.get 'published'


  class Proposal.SummaryProposalDescription extends Proposal.ProposalDescriptionView
    show_details : false
  
    editable : => false

    initialize : (options = {}) ->
      super options
      _.extend @events, 
        'click .m-proposal-description' : 'toggleDescription'

    toggleDescription : (ev) ->
      @trigger 'proposal:clicked'

  class Proposal.UnpublishedProposalDescription extends Proposal.ProposalDescriptionView


  class Proposal.SummaryResultsView extends App.Views.ItemView

    template : '#tpl_proposal_summary_results'

    serializeData : ->
      top_pro = App.request 'point:get', @model.get('top_pro')
      top_con = App.request 'point:get', @model.get('top_con')
      tenant = App.request 'tenant:get'
      participants = @model.getParticipants()
      
      params = _.extend {}, @model.attributes, 
        top_pro : if top_pro then top_pro.attributes else null
        top_con : if top_con then top_con.attributes else null
        top_pro_user : if top_pro then top_pro.getUser().attributes else null
        top_con_user : if top_con then top_con.getUser().attributes else null
        pro_label : tenant.getProLabel()
        con_label : tenant.getConLabel()
        participants : _.sortBy(participants, (user) -> !user.get('avatar_file_name')?  )
        tile_size : @getTileSize()

      params

    getTileSize : ->
      PARTICIPANT_WIDTH = 150
      PARTICIPANT_HEIGHT = 110

      Math.min 50, 
        ConsiderIt.utils.get_tile_size(PARTICIPANT_WIDTH, PARTICIPANT_HEIGHT, @model.getParticipants().length)

    onShow : ->


  class Proposal.ModifiableProposalSummaryView extends Proposal.ProposalSummaryView
    admin_template : '#tpl_proposal_admin_strip'

    initialize : (options = {} ) ->
      super options

    onShow : (options = {}) ->
      #super options
      if !Proposal.ModifiableProposalSummaryView.compiled_admin_template?
        Proposal.ModifiableProposalSummaryView.compiled_admin_template = _.template($(@admin_template).html())

      params = _.extend {}, @model.attributes
      @$admin_el = Proposal.ModifiableProposalSummaryView.compiled_admin_template params
      @$el.append @$admin_el


    events : 
      'ajax:complete .m-delete_proposal' : 'deleteProposal'
      'click .m-proposal-admin_operations-status' : 'showStatus'
      'click .m-proposal-admin_operations-publicity' : 'showPublicity'
      'ajax:complete .m-proposal-publish-form' : 'publishProposal'

    showStatus : (ev) ->
      @trigger 'status_dialog'

    showPublicity : (ev) ->
      @trigger 'publicity_dialog'

    deleteProposal : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      if data.success
        @trigger 'proposal:deleted', @model
        toastr.success 'Successfully deleted'
      else
        toastr.error 'Failed to delete'

    publishProposal : (ev, response, options) ->
      data = $.parseJSON response.responseText
      if data.success
        toastr.success 'Published!'
      else
        toastr.error 'Failed to publish'

      @trigger 'proposal:published', data.proposal.proposal, data.position.position

  class Proposal.ProposalStatusDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_active'

    dialog:
      title : 'Set the status of this proposal.'

    serializeData : ->
      _.extend {}, @model.attributes

    events : 
      'ajax:complete .m-proposal-admin_operations-settings-form' : 'changeSettings'

    changeSettings : (ev, response, options) ->
      data = $.parseJSON(response.responseText)
      @trigger 'proposal:updated', data

  class Proposal.ProposalPublicityDialogView extends App.Views.ItemView
    template : '#tpl_proposal_admin_strip_edit_publicity'

    dialog:
      title : 'Who can view and participate?'

    serializeData : ->
      _.extend {}, @model.attributes

    changeSettings : (ev, response ,options) ->
      data = $.parseJSON response.responseText
      @trigger 'proposal:updated', data

  ##############################################
