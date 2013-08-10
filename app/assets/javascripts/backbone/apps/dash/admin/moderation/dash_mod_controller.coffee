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

          moderations = new Moderation.ModerationListView
            collection : @moderations[cls]

          layout.moderationsRegion.show moderations

        layout.tabsRegion.show tabs


      layout

    getLayout : ->
      new Moderation.ModerationLayout()
