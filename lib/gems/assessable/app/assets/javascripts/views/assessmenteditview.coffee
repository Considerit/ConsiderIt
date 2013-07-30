# context link; destroy claim, update claim, assessment_update, create claim

class ConsiderIt.Assessable.AssessmentEditView extends Backbone.View

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
