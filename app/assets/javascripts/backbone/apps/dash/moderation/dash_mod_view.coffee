@ConsiderIt.module "Dash", (Dash, App, Backbone, Marionette, $, _) ->

  class Dash.ModerationView extends Dash.View
    dash_name : 'moderate'

    serializeData : ->
      objs_to_moderate : @options.objs_to_moderate
      existing_moderations : @options.existing_moderations
      classes_to_moderate : @options.classes_to_moderate      

    onShow : ->
      super

      @$el.find('#tabs a:first').trigger('click')
      if @$el.find('#hide_moderated').is(':checked')
        @$el.find('#hide_moderated').trigger('click')

    events : 
      'click #tabs a.inactive' : 'changeModel'
      'click #hide_moderated' : 'toggleModerated'
      'click .m-moderate-row button' : 'moderation'

    changeModel : (ev) ->
      $target = $(ev.currentTarget)
      cls = $target.attr('class_name')
      $target.siblings('.active').toggleClass('active inactive')
      $target.toggleClass('active inactive')

      @$el.find('.m-moderate-content').hide()
      @$el.find('.m-moderate-content[class_name="' + cls + '"]').show()

    toggleModerated : ->
      @$el.find('.m-moderate-content').toggleClass('hide_moderated')

    moderation : (ev) ->
      $target = $(ev.currentTarget)
      $target.addClass('selected')
      $target.siblings('button').removeClass('selected')
      $target.parents('.m-moderate-row').removeClass('passed failed').addClass($target.hasClass('pass') ? 'passed' : 'failed')
      $target.parents('form:first, .m-moderate-row').removeClass('not_moderated').addClass('moderated')
      $target.parents('form:first').find('#moderate_status').val($target.hasClass('pass') ? 1 : 0)
      $target.parents('form:first').find('input[type="submit"]').trigger('click')
