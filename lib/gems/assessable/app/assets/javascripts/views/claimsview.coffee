class ConsiderIt.Assessable.ClaimsListView extends Backbone.CollectionView

  @itemView : ConsiderIt.Assessable.Claim
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

class ConsiderIt.Assessable.ClaimsView extends Backbone.View
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