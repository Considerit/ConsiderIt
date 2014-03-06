@ConsiderIt.module "Franklin.UserOpinion", (UserOpinion, App, Backbone, Marionette, $, _) ->
  class UserOpinion.UserOpinionView extends App.Views.ItemView
    template : '#tpl_user_opinion'
    dialog : ->
      title : "#{@model.getUser().get('name')} #{@model.stanceLabel()} this proposal"

    serializeData : ->
      included_points = @model.getInclusions()
      support_is_pros = @model.get('stance_segment') >= 3

      _.extend {}, @model.attributes, 
        supporting_points : included_points.where {is_pro : support_is_pros}
        opposing_points : included_points.where {is_pro : !support_is_pros}
        user : @model.getUser().attributes
        stance_label : @model.stanceLabel()