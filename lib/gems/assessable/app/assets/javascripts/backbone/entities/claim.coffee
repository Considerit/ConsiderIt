class ConsiderIt.Assessable.Claim extends Backbone.Model
  name: 'claim'

  format_verdict : ->

    switch @get('verdict')
      when 2 then 'Accurate'
      when 1 then 'Unverifiable'
      when 0 then 'Questionable'
      when -1 then 'No checkable claims'
      else '-'
