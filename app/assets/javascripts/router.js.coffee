class ConsiderIt.Router extends Backbone.Router
  routes : 
    ":proposal": "Consider"
    ":proposal/results": "Aggregate"
    ":proposal/points/:point" : "PointDetails"


