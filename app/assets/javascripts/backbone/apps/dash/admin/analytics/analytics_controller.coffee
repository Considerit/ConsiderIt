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
      new Analytics.Visitation
        data : @visitation_data

    getTimeSeries : ->
      new Analytics.TimeSeries
        data : @time_series_data