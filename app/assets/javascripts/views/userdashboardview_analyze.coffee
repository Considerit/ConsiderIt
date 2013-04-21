#TODO: this shouldn't be loaded with all the other classes, most won't use it
class ConsiderIt.UserDashboardViewAnalyze extends Backbone.View
  #template : _.template( $("#tpl_dashboard_analyze").html() )
  
  initialize : (options) -> 
    @template = _.template( $("#tpl_dashboard_analyze").html() )
    @analytics_data = options.data.analytics_data
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

  render : () -> 

    @$el.html(
      @template( {
        analytics_data: @analytics_data
      } )
    )

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
    'plotselected .graph' : 'graph_selection'
    'plotselected .overview' : 'overview_selection'

  graph_selection : (event, ranges) ->
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

  overview_selection : (event, ranges) ->
    for s in @analytics_data
      @analytics_plots[s.title]['main'][0].setSelection(ranges)
      @analytics_plots[s.title]['cumulative'][0].setSelection(ranges)
