@ConsiderIt.module "Dash.Admin.Moderation", (Moderation, App, Backbone, Marionette, $, _) ->
  class Moderation.ModerationController extends App.Dash.Admin.AdminController
    initialize : (options = {} ) ->
      super options
      @classes_to_moderate = ConsiderIt.current_tenant.classesToModerate()

    data_uri : ->
      Routes.dashboard_moderate_path()

    process_data_from_server : (data) ->
      moderations = {}
      _.each @classes_to_moderate, (cls) =>
        [key, cls] = cls
        if cls == 'Point'
          text_fields = ['nutshell', 'text']
        else if cls == 'Comment'
          text_fields = ['body']
        else if cls == 'Proposal'
          text_fields = ['short_name', 'description', 'long_description']

        else
          throw "#{cls} is not a valid moderatable class"

        moderations[key] = new Backbone.Collection data.existing_moderations[cls],
          model : App.Entities.Moderation

        _.each data.objs_to_moderate[cls], (moderated_obj) ->

          prior = moderations[key].findWhere( {moderatable_id : moderated_obj.id} ) 
          if !prior
            prior = new App.Entities.Moderation
              moderatable_id : moderated_obj.id
              moderatable_type : cls
              status : null
            moderations[key].add prior

          field_vals = (moderated_obj[fld] for fld in text_fields)
          prior.setModeratedFields field_vals
          prior.setModeratedObject new App.Entities[cls] moderated_obj

      @moderations = moderations
      data

    setupLayout : ->
      @classes_to_moderate = ConsiderIt.current_tenant.classesToModerate()

      layout = @getLayout()
      @listenTo layout, 'show', ->
        tabs = new Moderation.ModerationTabView
          classes_to_moderate : (c[0] for c in @classes_to_moderate)
          moderations : @moderations

        @listenTo tabs, 'tab:changed', (cls) ->

          initial_collection = new Backbone.Collection @moderations[cls].filter((mod) -> !mod.isCompleted()),
            model : App.Entities.Moderation

          moderations = new Moderation.ModerationListView
            collection : initial_collection


          @listenTo moderations, 'childview:moderation:updated', (view, data) ->
            view.model.set data

          @listenTo moderations, 'filter:changed', (filter) ->
            if filter == 'all'
              filtered_collection = @moderations[cls].filter (mod) -> true
            else if filter == 'quarantine'
              filtered_collection = @moderations[cls].filter (mod) -> mod.quarantined()
            else if filter == 'pass'
              filtered_collection = @moderations[cls].filter (mod) -> mod.passed()
            else if filter == 'fail'
              filtered_collection = @moderations[cls].filter (mod) -> mod.failed()
            else if filter == 'incomplete'
              filtered_collection = @moderations[cls].filter (mod) -> !mod.isCompleted()

            moderations.collection.reset filtered_collection

          @listenTo moderations, 'childview:mod:emailRequest', (view) -> 
            email_controller = @getEmailDialog view.model

          layout.moderationsRegion.show moderations
          moderations.setFilter 'incomplete'

        layout.tabsRegion.show tabs


      layout


    getLayout : ->
      new Moderation.ModerationLayout()

    getEmailDialog : (moderation) ->
      new Moderation.EmailDialogController
        model : moderation.moderated_object

  class Moderation.EmailDialogController extends App.Dash.EmailDialogController

    initialize : (options = {}) -> 
      super options

    email : -> 
      recipient : @options.model.get 'user_id'
      body : "(write your message)\n\n--\n\nPlease edit your #{@options.model.name} at #{window.location.origin}#{@options.model.url()}" 
      subject : "Concerning your #{@options.model.name}" 
      sender : 'moderator@{{domain}}'

    dialog : 
      title : 'Email the content author'

    getEmailView : ->
      new Moderation.EmailDialogView
        model : @getMessage()
