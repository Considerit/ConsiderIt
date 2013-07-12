class ConsiderIt.Assessable.AssessmentsView extends Backbone.View

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