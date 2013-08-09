@ConsiderIt.module "Dash.Admin", (Admin, App, Backbone, Marionette, $, _) ->

  class Admin.AppSettingsView extends App.Dash.View
    dash_name : 'app_settings'
    checkboxes : [
      ['account', 'assessment_enabled', 'account_assessment_enabled'],
      ['account', 'enable_moderation', 'account_enable_moderation'],
      ['account', 'enable_position_statement', 'account_enable_position_statement'],
      ['account', 'enable_user_conversations', 'account_enable_user_conversations']]

    radioboxes : [
      ['account', 'moderate_points_mode', 'account_moderate_points_mode'],
      ['account', 'moderate_comments_mode', 'account_moderate_comments_mode'],
      ['account', 'moderate_proposals_mode', 'account_moderate_proposals_mode'],      
    ]

    serializeData : ->
      @model.attributes

    onShow : ->
      super
      @$el.find('#account_header_text').autosize()
      @$el.find('#account_header_details_text').autosize()
      @toggleModeration()

    events : 
      'ajax:complete .m-dashboard-edit-account' : 'accountUpdated'
      'click #account_enable_moderation' : 'toggleModeration'

    accountUpdated : (ev, response, options) ->
      data = $.parseJSON(response.responseText)

      @$el.find('.save_block').append('<div class="flash_notice">Account updated</div>').delay(1500).fadeOut 'fast', =>
        @trigger 'account:updated', data.account


    toggleModeration : ->
      if @$el.find('#account_enable_moderation').is(':checked')
        @$el.find('.m-moderation-settings').slideDown()
      else
        @$el.find('.m-moderation-settings').slideUp()


  # class Admin.ManageProposalsView extends App.Dash.View
  #   dash_name : 'manage_proposals'

  #   serializeData : ->
  #     active_proposals : @options.active_proposals
  #     inactive_proposals : @options.inactive_proposals


  class Admin.UserRolesView extends App.Dash.View
    dash_name : 'user_roles'
    templates : {}

    serializeData : ->
      users_by_roles_mask: @collection

    onShow : ->
      super
      @$el.find('#account_header_text').autosize()
      @$el.find('#account_header_details_text').autosize()

    events : 
      'click .m-user_roles-invoke_role_change' : 'editRole'

    editRole : (ev) ->

      @trigger 'role:edit:requested', $(ev.currentTarget).data('id')


  class Admin.EditUserRoleView extends App.Dash.View
    dash_name : 'user_roles_edit'

    dialog: =>
      name = if @model.get('name') && @model.get('name').length > 0 then @model.get('name') else @model.get('email')

      return {
        title : "Authorized roles for #{ name }"
      }

    onShow : ->
      super
      @checkBox @model, null, 'user_role_admin', @model.has_role('admin') || @model.has_role('superadmin')
      @checkBox @model, null, 'user_role_specific', !@model.has_role('admin') && @model.roles_mask > 0
      @checkBox @model, null, 'user_manager', @model.has_role('manager')
      @checkBox @model, null, 'user_moderator', @model.has_role('moderator')
      @checkBox @model, null, 'user_evaluator', @model.has_role('evaluator')    
      @checkBox @model, null, 'user_analyst', @model.has_role('analyst')
      @checkBox @model, null, 'user_role_user', @model.roles_mask == 0

    events : 
      'click .m-user_roles-edit_form input[type="checkbox"]' : 'roleEdited'
      'ajax:complete .m-user_roles-edit_form' : 'roleChanged'


    roleEdited : (ev) ->
      $(ev.currentTarget).closest('.m-user_roles-edit_form').find('.option.specific input[type="radio"]').trigger('click')

    roleChanged : (data, response, xhr) ->
      result = $.parseJSON(response.responseText)
      @trigger 'role:changed', result


  class Admin.DatabaseView extends App.Dash.View
    dash_name : 'database'

  class Admin.AnalyticsView extends App.Dash.View
    dash_name : 'analyze'
  
    initialize : (options) -> 
      @analytics_data = options.analytics_data
      @analytics_plots = {}

      @analytics_options = {
        main : {
          xaxis: { mode: "time", tickLength: 5 },
          selection: { mode: "x" },
          series: { bars: { show: true } } 
        },
        cumulative : {
          xaxis: { mode: "time", tickLength: 5 },
          selection: { mode: "x" },
        }
      }

      super

    serializeData : ->
      analytics_data: @analytics_data

    onShow : () -> 
      super

      SIZE = 
        graph: { width: '300px', height: '150px' }
        overview: { width: '288px', height: '50px' }

      for s in @analytics_data
        @analytics_plots[s.title] = {}
        for style in ['main', 'cumulative']
          d = s[style]['data']

          graph = $("#placeholder-#{s.title} .#{style} .graph")
          graph.css SIZE.graph

          plot = $.plot(graph, [d], @analytics_options[style])

          graph = $("#placeholder-#{s.title} .#{style} .overview")
          graph.css SIZE.overview

          overview = $.plot(graph, [d], {
              series: {
                  lines: { show: true, lineWidth: 1 },
                  shadowSize: 0
              },
              xaxis: { ticks: [], mode: "time" },
              yaxis: { ticks: [], min: 0, autoscaleMargin: 0.1 },
              selection: { mode: "x" }
          })
          @analytics_plots["#{s.title}"]["#{style}"] = [plot,overview]

      this

    events : 
      'plotselected .graph' : 'graphSelection'
      'plotselected .overview' : 'overviewSelection'

    graphSelection : (event, ranges) ->
      # do the zooming
      new_options_main = $.extend(true, {}, @analytics_options['main'], {
                      xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }})

      new_options_cumulative = $.extend(true, {}, @analytics_options['cumulative'], {
                      xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }})

      for s in @analytics_data
        $.plot($("#placeholder-" + s.title + " .main .graph"), [s.main.data], new_options_main)
        $.plot($("#placeholder-" + s.title + " .cumulative .graph"), [s.cumulative.data], new_options_cumulative)

        # don't fire event on the overview to prevent eternal loop
        @analytics_plots[s.title]['main'][1].setSelection(ranges, true)
        @analytics_plots[s.title]['cumulative'][1].setSelection(ranges, true)

    overviewSelection : (event, ranges) ->
      for s in @analytics_data
        @analytics_plots[s.title]['main'][0].setSelection(ranges)
        @analytics_plots[s.title]['cumulative'][0].setSelection(ranges)

