class ConsiderIt.Moderatable.ModerationView extends Backbone.View
  @template : _.template( $("#tpl_dashboard_moderate").html() )

  initialize : (options) -> 
    @data = options.data
    super

  render : () -> 

    @$el.html(
      ConsiderIt.Moderatable.ModerationView.template( @data )
    )

    #@$el.find('.table').fixedHeaderTable({ footer: false, cloneHeadToFoot: false, fixedColumn: false, height: 700 })
    @$el.find('#tabs a:first').trigger('click')
    if @$el.find('#hide_moderated').is(':checked')
      @$el.find('#hide_moderated').trigger('click')

    this

  events : 
    'click #tabs a.inactive' : 'change_model'
    'click #hide_moderated' : 'toggle_moderated'
    'click .m-moderate-row button' : 'moderation'

  change_model : (ev) ->
    $target = $(ev.currentTarget)
    cls = $target.attr('class_name')
    $target.siblings('.active').toggleClass('active inactive')
    $target.toggleClass('active inactive')

    @$el.find('.m-moderate-content').hide()
    @$el.find('.m-moderate-content[class_name="' + cls + '"]').show()

  toggle_moderated : ->
    @$el.find('.m-moderate-content').toggleClass('hide_moderated')

  moderation : (ev) ->
    $target = $(ev.currentTarget)
    $target.addClass('selected')
    $target.siblings('button').removeClass('selected')
    $target.parents('.m-moderate-row').removeClass('passed failed').addClass($target.hasClass('pass') ? 'passed' : 'failed')
    $target.parents('form:first, .m-moderate-row').removeClass('not_moderated').addClass('moderated')
    $target.parents('form:first').find('#moderate_status').val($target.hasClass('pass') ? 1 : 0)
    $target.parents('form:first').find('input[type="submit"]').trigger('click')
