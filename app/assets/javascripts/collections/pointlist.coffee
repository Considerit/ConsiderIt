class ConsiderIt.PointList extends Backbone.Collection
  model: ConsiderIt.Point


class ConsiderIt.PaginatedPointList extends Backbone.Paginator.clientPager
  model: ConsiderIt.Point

  paginator_ui: 
    firstPage: 1
    currentPage: 1
    perPage: 3

  initialize: (options) -> 
    _.extend @paginator_ui, options || {}
    super