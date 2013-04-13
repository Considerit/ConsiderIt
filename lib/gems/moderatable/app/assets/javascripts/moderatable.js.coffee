

$(document).ready () ->

  $('#moderate .table').fixedHeaderTable({ footer: false, cloneHeadToFoot: false, fixedColumn: false, height: 700 })

  $(document).on 'click', '#moderate #tabs a.inactive', () ->
    cls = $(this).attr('class_name')
    $(this).siblings('.active').toggleClass('active inactive')
    $(this).toggleClass('active inactive')
    $('#moderate .moderation_block').hide()
    $('#moderate .moderation_block[class_name="' + cls + '"]').show()

  $('#moderate #tabs a:first').trigger('click')

  $('#moderate #heading #hide_moderated').click () ->
    $('#moderate .moderation_block').toggleClass('hide_moderated')

  if $('#moderate #heading #hide_moderated:checked').length > 0
    $('#moderate .moderation_block').toggleClass('hide_moderated')
  
  $(document).on 'click', '#moderate .moderation_row button', () ->
    $(this).addClass('selected')
    $(this).siblings('button').removeClass('selected')
    $(this).parents('.moderation_row').removeClass('passed failed').addClass($(this).hasClass('pass') ? 'passed' : 'failed')
    $(this).parents('form:first, .moderation_row').removeClass('not_moderated').addClass('moderated')
    $(this).parents('form:first').find('#moderate_status').val($(this).hasClass('pass') ? 1 : 0)
    $(this).parents('form:first').find('input[type="submit"]').trigger('click')
