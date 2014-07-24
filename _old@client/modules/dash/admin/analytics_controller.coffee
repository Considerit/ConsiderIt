@ConsiderIt.module "Dash.Admin.Analytics", (Analytics, App, Backbone, Marionette, $, _) ->


  class Analytics.AnalyticsController extends App.Dash.Admin.AdminController
    auth : 'is_analyst'

    data_uri : ->
      Routes.analytics_path()

    process_data_from_server : (data) ->
      @time_series_data = data.time_series_data
      @visitation_data = data.visitation_data
      data

    setupLayout : ->
      layout = @getLayout()
      @listenTo layout, 'show', =>
        @listenTo layout, 'switch_view', (target) =>
          view = switch target
            when 'visitation'
              @getVisitation()
            when 'timeseries'
              @getTimeSeries()

          layout.analyticsRegion.show view

      layout

    getLayout : ->
      new Analytics.AnalyticsLayout

    getVisitation : ->
      by_domain = {}
      for visitor in @visitation_data
        if !(visitor.referer_domain of by_domain)
          by_domain[visitor.referer_domain] = {
            domain: visitor.referer_domain,
            total: 0,
            registered: 0,
            visitors: []
          }
        by_domain[visitor.referer_domain].total += 1
        by_domain[visitor.referer_domain].registered += 1 if visitor.user
        by_domain[visitor.referer_domain].visitors.push visitor

      total_registered = (d.registered for d in _.values(by_domain) )
      # this will sum array
      total_registered = _.reduce total_registered, (before, el) -> 
        before + el
      , 0

      new Analytics.Visitation
        all_data : 
          total : @visitation_data.length
          registered : total_registered 
          visitors : @visitation_data
        by_domain : _.values by_domain

    getTimeSeries : ->
      new Analytics.TimeSeries
        data : @time_series_data