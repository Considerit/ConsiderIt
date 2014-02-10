@ConsiderIt.module "Franklin.Proposal", (Proposal, App, Backbone, Marionette, $, _) ->
  
  class Proposal.ProposalDescriptionView extends App.Views.StatefulLayout
    template : '#tpl_proposal_description'
    className : 'proposal-description-wrap'

    show_details : true

    regions : 
      adminRegion : '.proposal-admin-region'
      socialMediaRegion : '.proposal-socialmedia-region'
      

    ui : 
      details : '.proposal-details'

    editable : =>
      @state != Proposal.State.Summary && App.request 'auth:can_edit_proposal', @model    

    serializeData : ->
      user_opinion = @model.getUserOpinion()

      user = @model.getUser()
      params = _.extend {}, @model.attributes,
        proposal : @model
        avatar : App.request('user:avatar', user, 'large' )
        description_detail_fields : @model.description_detail_fields()
        show_details : @state != Proposal.State.Summary 

      params

    initialize : (options = {}) ->
      super options

      if @editable()
        if !Proposal.ProposalDescriptionView.editable_fields
          fields = [
            ['.proposal-description-title', 'name', 'textarea'], 
            ['.proposal-description-body', 'description', 'textarea'] ]

          editable_fields = _.union fields,
            ([".proposal-description-detail-field-#{f}", f, 'textarea'] for f in App.request('proposal:description_fields'))          

          Proposal.ProposalDescriptionView.editable_fields = editable_fields

        @editable_fields = Proposal.ProposalDescriptionView.editable_fields

    onRender : ->
      super

      @bindUIElements()      
      @stickit()
      _.each @editable_fields, (field) =>
        [selector, name, type] = field 
        $editable = @$el.find(selector)

        $editable.editable
          resource: 'proposal'
          pk: @long_id
          disabled: @state == Proposal.State.Summary && @model.get('published')
          url: Routes.proposal_path @model.id
          type: type
          name: name
          success : (response, new_value) => @model.set(name, new_value)

        # $editable.addClass 'icon-pencil icon-large'
        $editable.prepend '<i class="editable-pencil icon-pencil icon-large">'

    onShow : ->

    bindings : 
      '.proposal-description-title' : 
        observe : ['name', 'description']
        onGet : (values) -> @model.title(280)
      '.proposal-description-body' : 
        observe : 'description'
        updateMethod: 'html'
        onGet : (value) => htmlFormat(value)

    events : 
      'click .hidden' : 'showDetails'
      'click .showing' : 'hideDetails'      
      'click .proposal-description' : 'toggleDescription'

    showDetails : (ev) ->
      $block = $(ev.currentTarget).closest('.proposal-description-detail-field')

      $toggle = $block.find('.hidden:first')
      
      @desc = $toggle.data('label', $toggle.text()) if !$toggle.data('label')

      $block.find('.proposal-description-detail-field-full').slideDown();
      $toggle
        .text('hide')
        .toggleClass('hidden showing');

      ev.stopPropagation()

    hideDetails : (ev) ->

      $block = $(ev.currentTarget).closest('.proposal-description-detail-field')

      if $(document).scrollTop() > $block.offset().top
        $('body').animate {scrollTop: $block.offset().top}, 1000

      $toggle = $block.find('.showing:first')

      $block.find('.proposal-description-detail-field-full').slideUp(1000);
      $toggle
        .text($toggle.data('label'))
        .toggleClass('hidden showing');

      ev.stopPropagation()

    toggleDescription : (ev) ->
      @trigger 'proposal:clicked'
      

  class Proposal.SocialMediaView extends App.Views.ItemView
    template : '#tpl_proposal_social_media'
    className : 'proposal-socialmedia'


