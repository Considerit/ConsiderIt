# TODO: make this into its own submodule....
@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.AssessmentListView extends App.Views.CompositeView
    template : '#tpl_dashboard_assess'

    serializeData : ->
      account : ConsiderIt.current_tenant.attributes


  class Dash.AssessmentsView extends App.Views.ItemView

    initialize : (options) -> 
      @template = _.template( $("#tpl_dashboard_assess").html() )

      @claims = new Backbone.Collection(options.data.claims, {model : ConsiderIt.Assessable.Claim})
      @requests = new Backbone.Collection([], {model : ConsiderIt.Assessable.Request})
      @requests.comparator = (rq) =>
        return rq.get("created_at")

      @requests.set options.data.requests

      @assessments = new Backbone.Collection(options.data.assessments, {model : ConsiderIt.Assessable.Assessment})

      @assessable_objects = {}
      for obj in options.data.assessable_objects
        @assessable_objects[obj.point.id] = obj.point

      super

    render : () -> 
      @$el.html( @template( {
        assessments: @assessments,
        claims : @claims,
        requests : @requests,
        assessable_objects : @assessable_objects
      } ) )

      @$el.find('.table').fixedHeaderTable({ footer: false, cloneHeadToFoot: false, fixedColumn: false, height: 700 })
      
      hm = @$el.find('#hide_completed')
      if hm.is(':checked')
        hm.trigger('click')

      this

    events : 
      'click #hide_completed' : 'toggle_completed'
      'click .m-assessment-edit' : 'edit_assessment'

    toggle_completed : (ev) ->
      @$el.find('.assessment_block').toggleClass('hide_completed')

    edit_assessment : (ev) ->
      # Routes.edit_assessment_path(obj.id)
      assessment = @assessments.get($(ev.currentTarget).data('id'))
      assessable = @assessable_objects[assessment.get('assessable_id')]
      proposal = ConsiderIt.all_proposals.get(assessable.proposal_id)

      all_claims = @claims.filter((clm) => clm.get('assessment_id') != assessment.id && proposal.id == @assessable_objects[@assessments.get(clm.get('assessment_id')).get('assessable_id')].proposal_id)

      @edit_assessment_view = new ConsiderIt.Assessable.AssessmentEditView({
        el : @$el,
        parent : this,
        model : assessment,
        all_claims : all_claims,
        claims : @claims.where({assessment_id: assessment.id})
        requests : @requests.where({assessment_id: assessment.id}),
        assessable : assessable,
        proposal : proposal
        })

      @edit_assessment_view.render()





  # context link; destroy claim, update claim, assessment_update, create claim

  class Dash.AssessmentEditView extends App.Views.ItemView

    initialize : (options) -> 
      @template = _.template( $("#tpl_dashboard_assess_edit").html() )

      @all_claims = options.all_claims

      @claims = new Backbone.Collection( options.claims, {model : ConsiderIt.Assessable.Claim})

      @proposal = options.proposal

      @parent = options.parent
      @requests = options.requests
      @assessable = options.assessable

      super

    render : () -> 
      @$el.html( @template( {
        assessment: @model.attributes,
        claims : @claims,
        all_claims : @all_claims,
        requests : @requests,
        assessable : @assessable,
        proposal: @proposal.attributes
      } ) )

      @claimsview = new ConsiderIt.Assessable.ClaimsListView({el: @$el, collection: @claims, assessment: @model})
      @claimsview.renderAllItems()

      @$el.find('.autosize').autosize()

      num_claims = @claims.length
      num_answered_claims = @claims.filter((clm) -> clm.get('verdict')? ).length

      if num_claims > 0 && num_answered_claims != num_claims
        @$el.find('#evaluate .complete, #evaluate .review').hide()

      this

    events :
      'click .actions .answer' : 'toggle_edit'
      'click .open .cancel' : 'toggle_edit'
      'click #evaluate .add_claim' : 'toggle_claim_form'
      'click #evaluate .add_claim_form .cancel' : 'toggle_claim_form'
      'click .m-assessment-back' : 'back_to_index'

      'ajax:complete .m-assessment-update' : 'assessment_updated'

    back_to_index : (ev) ->
      @undelegateEvents()
      @parent.render()

    toggle_edit : (ev) ->
      $claim = $(ev.currentTarget).parents('.claim')
      $claim.find('.open, .closed, .head .answer').toggleClass('hide')
      $claim.find('.autosize').trigger('keyup')

    toggle_claim_form : (ev) ->
      $(ev.currentTarget).parents('#evaluate').find('.add_claim, .add_claim_form form, .add_claim_form #other_claims').toggleClass('hide')
      @$el.find('.add_claim_form').find('.autosize').trigger('keyup')

    assessment_updated : (ev, response, options) ->
      params = $.parseJSON(response.responseText).assessment
      @model.set(params)
      @render()


  class Dash.ClaimsListView extends App.Views.CollectionView

    @itemView : App.Entities.Claim
    @childClass : 'claim'
    listSelector : '#claims'

    initialize : (options) ->
      super
      @assessment = options.assessment

    render : () ->
      super

    # Returns an instance of the view class
    getItemView : (claim)->
      new ConsiderIt.Assessable.ClaimsView
        model: claim
        collection: @collection
        assessment : @assessment
        attributes : 
          'data-id': "#{claim.id}"
          'class': 'claim'

    events : 
      'ajax:complete .m-assessment-claim-delete' : 'claim_deleted'
      'ajax:complete .m-assessment-create_claim' : 'create_claim'

    claim_deleted : (ev, response, options) ->
      claim_id = $.parseJSON(response.responseText).id
      @collection.remove @collection.get(claim_id)

    create_claim : (ev, response, options) ->
      claim = $.parseJSON(response.responseText).claim
      @collection.add(claim)
      #do we need to re-render the collection now? or does Backbone.CollectionView take care of it?

  class Dash.ClaimsView extends App.Views.ItemView
    tagName : 'li'

    initialize : (options) -> 
      @template = _.template( $("#tpl_dashboard_assess_claim").html() )

      @assessment = options.assessment
      super

    render : () -> 

      @$el.html( @template( {
        assessment: @assessment.attributes,
        claim : @model.attributes,
        formatted_verdict: @model.format_verdict()
      }))
      
      @_check_box @model, null, 'claim_verdict_accurate', @model.get('verdict') == 2
      @_check_box @model, null, 'claim_verdict_unverifiable', @model.get('verdict') == 1
      @_check_box @model, null, 'claim_verdict_questionable', @model.get('verdict') == 0

      this

    _check_box : (model, attribute, selector, condition) ->
      if condition || (!condition? && model.get(attribute))
        input = @$el.find('#' + selector).attr('checked', 'checked')

    events : 
      'ajax:complete .m-assessment-claim-update' : 'claim_updated'

    claim_updated : (ev, response, options) ->
      params = $.parseJSON(response.responseText).claim
      @model.set(params)
      #need this, or does collection automatically do it?
      #@render()
