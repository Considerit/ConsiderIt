# Admin components, like moderation and factchecking backend


# Checks if current user has proper credentials to view this component. 
# If not, shows Auth. 


AccessControlled = ReactiveComponent
  displayName: 'AccessControlled'

  render : -> 
    current_user = fetch '/current_user'

    is_permitted = false
    for role in @props.permitted
      if current_user["is_#{role}"]
        is_permitted = true
        break

    if is_permitted
      @props.children
    else
      @root.auth_mode = 'login'
      save @root
      SPAN null

FactcheckDash = ReactiveComponent
  displayName: 'FactcheckDash'

  render : ->
    assessments = @data().assessments.sort (a,b) -> new Date(b.created_at) - new Date(a.created_at)

    # Separate assessments by status
    completed = (a for a in assessments when a.complete)
    reviewable = (a for a in assessments when !a.complete && a.reviewable)
    todo = (a for a in assessments when !a.complete && !a.reviewable)

    if !@local.selected_factcheck && @data().assessments.length > 0
      @local.selected_factcheck = if reviewable.length > 0 then reviewable[0].key else if todo.length > 0 then todo[0].key else completed[0].key
      save @local


    DIV style: {width: CONTENT_WIDTH, margin: 'auto'}, 
      STYLE null, '.factcheck_tab:hover{background-color: #f1f1f1 }'
      H1 style: {fontSize: 28, marginTop: 20}, 'Fact Checking Interface'

      DIV style: {}, 
        for assessments in [['Pending review', reviewable], ['Incomplete', todo], ['Complete', completed]]
          if assessments[1].length > 0
            DIV style: {marginTop: 20}, key: assessments[0],
              H1 style: {fontSize: 22}, assessments[0]
              UL style: {},
                for assessment in assessments[1]
                  point = @data(assessment.point)
                  proposal = @data(point.proposal)
                  background_color = if assessment.key == @local.selected_factcheck then '#F4F0E9' else ''
                  LI 
                    key: assessment.key
                    className: 'factcheck_tab'
                    style: {zIndex: 1, position: 'relative', width: CONTENT_WIDTH / 4, cursor: 'pointer', padding: '10px', margin: '5px 0', listStyle: 'none', borderRadius: '8px 0 0 8px', backgroundColor: background_color}
                    onClick: do (assessment) => => 
                      @local.selected_factcheck = assessment.key
                      save @local

                    DIV style: {fontSize: 14, fontWeight: 600}, "Fact check point #{point.id}"
                    DIV style: {fontSize: 12}, "Requested on #{new Date(assessment.requests[0].created_at).toDateString()}"
                    DIV style: {fontSize: 12}, "Issue: #{proposal.name}"

                    if @local.selected_factcheck == assessment.key
                      FactcheckPoint key: assessment.key


FactcheckPoint = ReactiveComponent
  displayName: 'FactcheckPoint'

  render : ->
    assessment = @data()
    point = @data(assessment.point)
    proposal = @data(point.proposal)
    current_user = @data('/current_user')

    all_claims_answered = assessment.claims.length > 0
    all_claims_approved = assessment.claims.length > 0
    for claim in assessment.claims
      if !claim.verdict || !claim.result
        all_claims_answered = all_claims_approved = false 
      if !claim.approver
        all_claims_approved = false

    header_style = {fontSize: 24, fontWeight: 400, margin: '10px 0'}
    section_style = {margin: '10px 0px 20px 0px', position: 'relative'}

    DIV style: {cursor: 'auto', width: 3 * CONTENT_WIDTH / 4, backgroundColor: '#F4F0E9', position: 'absolute', left: CONTENT_WIDTH/4, top: -35, borderRadius: 8},
      
      # status area
      DIV style: {padding: '4px 30px', fontSize: 24, borderRadius: '8px 8px 0 0', height: 35, backgroundColor: 'rgba(0,0,55,.1)'},
        if assessment.complete
          SPAN style: {}, "Published #{new Date(assessment.published_at).toDateString()}"
        else if assessment.reviewable
          SPAN style: {}, "Awaiting approval"
        else
          SPAN style: {}, "Fact check this point"

        SPAN style: {float: 'right', fontSize: 18, verticalAlign: 'bottom'},
          if assessment.user 
            ["Responsible: #{@data(assessment.user).name}"
            if assessment.user == current_user.user && !assessment.reviewable && !assessment.complete
              BUTTON style: {marginLeft: 8, fontSize: 14}, onClick: @toggleResponsibility, "I won't do it"]
          else 
            ['Responsible: '
            BUTTON style: {backgroundColor: considerit_blue, color: 'white', fontSize: 14, border: 'none', borderRadius: 8, fontWeight: 600 }, onClick: @toggleResponsibility, "I'll do it"]

      DIV style: {padding: '10px 30px'},
        # point area
        DIV style: section_style, 
          UL style: {marginLeft: 73}, 
            DIV style:{fontSize: 12, marginLeft: 0},
              fetch(point.user).name

            Point key: point, rendered_as: 'under_review'
            # TODO: email author
            # TODO: read point in context

        # requests area
        DIV style: section_style, 
          H1 style: header_style, 'Fact check requests'
          DIV style: {}, 
            for request in assessment.requests
              DIV className: 'comment_entry',

                DIV style:{fontSize: 12, marginLeft: 73},
                  fetch(request.user).name

                Avatar
                  className: 'comment_entry_avatar'
                  tag: DIV
                  key: request.user
                  hide_name: true

                DIV style: {marginLeft: 73},
                  splitParagraphs(request.suggestion)

              # TODO: email requester

        # claims area
        DIV style: section_style, 
          H1 style: header_style, 'Claims under review'


          DIV style: {}, 
            for claim in assessment.claims
              claim = @data(claim)
              if @local.editing == claim.key
                EditClaim fresh: false, key: claim.key, parent: @local, assessment: @data()
              else 

                verdict = @data(claim.verdict)
                DIV style: {marginLeft: 73, marginBottom: 18, position: 'relative'}, 
                  IMG style: {position: 'absolute', width: 50, left: -73}, src: verdict.icon

                  DIV style: {fontSize: 18}, claim.claim_restatement
                  DIV style: {fontSize: 12}, verdict.name
                  
                  DIV 
                    style: {marginTop: 10, fontSize: 14}
                    dangerouslySetInnerHTML: {__html: claim.result }
                  
                  DIV style: {marginTop: 10, position: 'relative'},

                    DIV style: {fontSize: 12, marginTop: 10}, 
                      DIV null, "Created by #{@data(claim.creator).name}"
                      if claim.approver
                        DIV null, "Approved by #{@data(claim.approver).name}"

                    DIV style: {fontSize: 14},
                      if claim.result && claim.verdict && !claim.approver #&& current_user.id != claim.creator
                        BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Approve'
                      else if claim.approver
                        BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @toggleClaimApproval(claim)), 'Unapprove'

                      BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @local.editing = claim.key; save(@local)), 'Edit'
                      BUTTON style: {marginRight: 5}, onClick: (do (claim) => => @deleteClaim(claim)), 'Delete'

            if @local.editing == 'new'
              EditClaim fresh: true, key: '/new/claim', parent: @local, assessment: @data()
            else if !@local.editing
              Button {style: {marginLeft: 73, marginTop: 15}}, '+ Add new claim', => @local.editing = 'new'; save(@local)

        DIV style: section_style,
          H1 style: header_style, 'Private notes'
          AutoGrowTextArea
            className: 'assessment_notes'
            placeholder: 'Private notes about this fact check'
            defaultValue: assessment.notes
            min_height: 60
            style: 
              width: 550
              fontSize: 14
              display: 'block'

          BUTTON style: {fontSize: 14}, onClick: @saveNotes, 'Save notes'

          DIV style: header_style,
            if assessment.complete
              'Congrats, this one is finished.'
            else if all_claims_answered && !assessment.reviewable
              Button({}, 'Request approval', @requestApproval)
            else if assessment.reviewable
              if all_claims_approved && current_user.user != assessment.user
                Button({}, 'Publish fact check', @publish)
              else if all_claims_answered
                'This fact-check is awaiting publication'

  deleteClaim : (claim) -> destroy claim.key

  toggleClaimApproval : (claim) -> 
    if claim.approver
      claim.approver = null
    else
      claim.approver = @data('/current_user').user
    save(claim)

  saveNotes: -> 
    assessment = @data()
    assessment.notes = $('.assessment_notes').val()
    save(assessment)

  publish : -> 
    assessment = @data()
    assessment.complete = true
    save(assessment)

  requestApproval : -> 
    assessment = @data()
    assessment.reviewable = true
    if !assessment.user
      assessment.user = @data("/current_user").user
    save(assessment)

  toggleResponsibility : ->
    assessment = @data()
    current_user = @data('/current_user')

    if assessment.user == current_user.user
      assessment.user = null
    else if !assessment.user
      assessment.user = current_user.user

    save assessment

EditClaim = ReactiveComponent
  displayName: 'EditClaim'

  render : -> 
    text_style = 
      width: 550
      fontSize: 14
      display: 'block'

    DIV style: {padding: '8px 12px', backgroundColor: "rgba(0,0,0,.1)", marginLeft: 73, marginBottom: 18 },
      DIV style: {marginBottom: 8},
        LABEL null, 'Restate the claim'
        AutoGrowTextArea
          className: 'claim_restatement'
          placeholder: 'The claim'
          defaultValue: if @props.fresh then null else @data().claim_restatement
          min_height: 30
          style: text_style

      DIV style: {marginBottom: 8},
        LABEL style: {marginRight: 8}, 'Evaluate the claim'
        SELECT
          defaultValue: if @props.fresh then null else @data().verdict
          className: 'claim_verdict'
          for verdict in @data('/dashboard/assessment').verdicts
            OPTION key: verdict.key, value: verdict.key, verdict.name


      DIV style: {marginBottom: 8},
        LABEL null, 'Review the claim'
        AutoGrowTextArea
          className: 'claim_result'
          placeholder: 'Prose review of this claim'
          defaultValue: if @props.fresh then null else @data().result
          min_height: 80
          style: text_style

      Button {}, 'Save claim', @saveClaim
      A style: {marginLeft: 12}, onClick: (=> @props.parent.editing = null; save(@props.parent)), 'cancel'



  saveClaim : -> 
    $el = $(@getDOMNode())

    claim = if @props.fresh then {key: '/new/claim'} else @data()

    claim.claim_restatement = $el.find('.claim_restatement').val()
    claim.result = $el.find('.claim_result').val()
    claim.assessment = @props.assessment.key
    claim.verdict = $el.find('.claim_verdict').val()

    save(claim)

    # This is ugly, what is activeRESTy way of doing this? 
    @props.parent.editing = null
    save @props.parent


## Export...
window.FactcheckDash = FactcheckDash
window.AccessControlled = AccessControlled