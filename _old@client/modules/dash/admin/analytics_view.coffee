@ConsiderIt.module "Dash.Admin.Analytics", (Analytics, App, Backbone, Marionette, $, _) ->

  class Analytics.AnalyticsLayout extends App.Dash.View
    dash_name : 'analyze'

    regions: 
      analyticsRegion : '.analytics-region'

    events : 
      'click .analytics-view:not(.active)' : 'changeView'

    changeView : (ev) ->
      $target = $(ev.currentTarget)
      @trigger 'switch_view', $target.attr('action')
      @$el.find('.analytics-view').removeClass('active')
      $target.addClass('active')

  class Analytics.AnalyticsView extends App.Views.ItemView

  class Analytics.Visitation extends Analytics.AnalyticsView
    template : '#tpl_dashboard_analytics_visitation'

    initialize : (options) ->

    serializeData : ->
      params = 
        all_data : @options.all_data
        by_domain : @options.by_domain

      params

  class Analytics.TimeSeries extends Analytics.AnalyticsView
    template : '#tpl_dashboard_analytics_timeseries'

    initialize : (options) -> 
      @time_series_data = options.data
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
      time_series_data: @time_series_data

    onShow : () -> 

      SIZE = 
        graph: { width: '300px', height: '150px' }
        overview: { width: '288px', height: '50px' }

      for s in @time_series_data
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

    events : #_.extend @events,
      'plotselected .graph' : 'graphSelection'
      'plotselected .overview' : 'overviewSelection'

    graphSelection : (event, ranges) ->
      # do the zooming
      new_options_main = $.extend(true, {}, @analytics_options['main'], {
                      xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }})

      new_options_cumulative = $.extend(true, {}, @analytics_options['cumulative'], {
                      xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }})

      for s in @time_series_data
        $.plot($("#placeholder-" + s.title + " .main .graph"), [s.main.data], new_options_main)
        $.plot($("#placeholder-" + s.title + " .cumulative .graph"), [s.cumulative.data], new_options_cumulative)

        # don't fire event on the overview to prevent eternal loop
        @analytics_plots[s.title]['main'][1].setSelection(ranges, true)
        @analytics_plots[s.title]['cumulative'][1].setSelection(ranges, true)

    overviewSelection : (event, ranges) ->
      for s in @time_series_data
        @analytics_plots[s.title]['main'][0].setSelection(ranges)
        @analytics_plots[s.title]['cumulative'][0].setSelection(ranges)
