@ConsiderIt.module "Dash.Admin.Assessment", (Assessment, App, Backbone, Marionette, $, _) ->
  class Assessment.AssessmentEditController extends App.Dash.Admin.AdminController
    auth : 'is_evaluator'

    data_uri : ->
      Routes.edit_assessment_path @options.model_id

    process_data_from_server : (data) ->
      App.request 'verdicts:add', (v.verdict for v in data.verdicts)      
      App.request 'assessments:add', [data.assessment]
      App.vent.trigger 'points:fetched', [data.assessable_obj.point]
      App.vent.trigger 'proposals:fetched', [data.root_object.proposal]
      App.request 'claims:add', (c.claim for c in data.claims)
      App.request 'claims:add', (c.claim for c in data.all_claims), data.root_object.proposal.long_id
      App.request 'assessment:requests:add', (r.request for r in data.requests)

    setupLayout : ->
      assessment = App.request 'assessment:get', @options.model_id

      layout = @getLayout assessment

      @listenTo layout, 'show', ->
        context = new Assessment.ContextView
          model : assessment
          root_object : assessment.getRoot()
          assessable : assessment.getAssessable()

        @listenTo context, 'show', =>
          @listenTo context, 'email:author', (view) -> 
            new Assessment.EmailDialogController
              model : assessment.getAssessable()
              title : 'Clarification regarding your point'
              parent_controller : @


        layout.contextRegion.show context

        requests = new Assessment.RequestsView
          collection : assessment.getRequests()

        @listenTo requests, 'show', =>
          @listenTo requests, 'childview:email:requester', (view) -> 
            new Assessment.EmailDialogController
              model : view.model
              title : 'Question regarding your fact check request'
              parent_controller : @
              link : assessment.getAssessable().url()

        layout.requestsRegion.show requests

        claims_collection = assessment.getClaims()
        claims = new Assessment.ClaimsView
          collection: claims_collection
          assessment : assessment

        @listenTo claims, 'show', =>
          @listenTo claims, 'claim:new', => 
            @setupNewClaimView assessment, claims_collection

          @listenTo claims, 'childview:claim:delete', (view) -> 
            view.model.destroy()

          @listenTo claims, 'childview:claim:approved', (view) ->
            claim = view.model
            claim.save {approver : App.request('user:current').id}
            App.execute 'when:fetched', claim, =>
              App.execute 'notify:success', 'Claim approved'
              App.vent.trigger 'claim:approved'

          @listenTo assessment, 'change', ->
            claims.render()

          @listenTo claims, 'childview:claim:edit', (view) => @setupEditClaimView view.model

        layout.claimsRegion.show claims

        forms = new Assessment.EditFormsView
          model : assessment

        @listenTo forms, "show", =>
          @listenTo forms, 'publish', =>
            assessment.save {complete : true}, 
              success : ->
                App.execute 'notify:success', 'Assessment published.'
                forms.render()

          @listenTo forms, 'request_approval', =>
            assessment.save {reviewable : true}, 
              success : ->
                App.execute 'notify:success', 'Submitted for approval'
                forms.render()

          @listenTo forms, 'save_notes', (notes) =>
            assessment.save {notes: notes}, 
              success : ->
                App.execute 'notify:success', 'Notes saved'
                forms.render()

          @listenTo assessment, 'change', ->
            forms.render()


          @listenTo App.vent, 'claim:approved claim:created claim:updated', ->
            forms.render()

          rerender_forms_on_claim_change =  (claim) =>
            @listenTo claim, 'sync:stop', ->
              forms.render()

          claims_collection.each (claim) =>
            rerender_forms_on_claim_change claim

          @listenTo claims_collection, 'add', (claim) ->
            rerender_forms_on_claim_change claim

          @listenTo claims_collection, 'remove', ->
            forms.render()


        layout.footerRegion.show forms

      layout

    setupNewClaimView : (assessment, claims_collection) ->
      new_claim_view = @getNewClaimView assessment

      @listenTo new_claim_view, 'show', =>
        @listenTo new_claim_view, 'claim:create', (attrs) =>
          attrs.assessment_id = assessment.id
          claim = App.request 'claim:create', attrs
          App.execute 'when:fetched', claim, =>
            claims_collection.add claim
            App.execute 'notify:success', 'Claim added'            
            new_claim_view.close()
            App.vent.trigger 'claim:created'


      overlay = App.request 'dialog:new', new_claim_view, 
        class: 'overlay_claim_view'

    setupEditClaimView : (claim) ->
      edit_claim_view = @getEditClaimView claim

      @listenTo edit_claim_view, 'show', =>
        @listenTo edit_claim_view, 'claim:updated', (attrs) =>
          claim.save attrs
          App.execute 'when:fetched', claim, =>
            App.execute 'notify:success', 'Claim updated'
            edit_claim_view.close()         
            App.vent.trigger 'claim:updated'

      overlay = App.request 'dialog:new', edit_claim_view,
        class: 'overlay_claim_view'


    getNewClaimView : (assessment) ->
      new Assessment.ClaimForm
        assessment: assessment
        all_claims: App.request 'claims:get:proposal', assessment.getRoot().id

    getEditClaimView : (model) ->
      new Assessment.EditClaimForm
        model : model

    getLayout : (model) ->
      new Assessment.EditLayout
        model : model

  class Assessment.EmailDialogController extends App.Dash.EmailDialogController

    initialize : (options = {}) -> 
      options.link ?= options.model.url()
      super options

    email : -> 
      sender = "#{App.request("tenant").get('identifier')}-factcheckers@{{domain}}"
      
      # IE fix
      if !window.location.origin
        window.location.origin = "#{window.location.protocol}//#{window.location.hostname}#{if window.location.port then ':' + window.location.port else ''}"

      return {
        recipient : @options.model.get 'user_id'
        body : "(write your message)\n\n--\n\nThe point referred to can be found at #{window.location.origin}#{@options.link}" 
        subject : @options.title
        sender :  sender
      }
      
    getEmailView : ->
      new Assessment.EmailDialogView
        model : @getMessage()
