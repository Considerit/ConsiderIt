@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  # polymorphic collection for comments 
  class Entities.DiscussionCollection extends App.Entities.Collection
    model : (attrs, options) -> 
      if 'commentable_id' of attrs
        new Entities.Comment attrs, options
      else if 'assessment_id' of attrs
        new Entities.Claim attrs, options

    comparator : (el) ->
      if el instanceof Entities.Claim
        dt = el.getAssessment().get 'published_at'
      else if el instanceof Entities.Comment
        dt = el.get 'created_at'

      dt = new Date(dt).getTime()
      dt