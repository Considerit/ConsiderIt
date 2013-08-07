@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Assessment extends App.Entities.Model
    name: 'assessment'

  class Entities.Claim extends App.Entities.Model
    name: 'claim'

    format_verdict : ->

      switch @get('verdict')
        when 2 then 'Accurate'
        when 1 then 'Unverifiable'
        when 0 then 'Questionable'
        when -1 then 'No checkable claims'
        else '-'

  class Entities.Request extends App.Entities.Model
    name: 'request'
