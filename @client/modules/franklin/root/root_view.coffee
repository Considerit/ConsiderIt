@ConsiderIt.module "Franklin.Root", (Root, App, Backbone, Marionette, $, _) ->

  class Root.Layout extends App.Views.Layout
    template: "#tpl_homepage_layout"
    className : 'homepage-region'
    regions :
      headerRegion : '#homepage-header'
      proposalsRegion : '#homepage-proposals'


  class Root.HeaderView extends App.Views.ItemView
    template: '#tpl_homepage_heading'

    serializeData : ->
      is_manager : App.request('user:current').isManager()
      tenant : App.request('tenant:get')

    bindings : 
      '.l-homepage-pic .hide' : 
        observe : 'homepage_pic_file_name'
        onGet : (values) ->
          return if !values? || $.trim(values)==''
          @$el.find('.l-homepage-pic img.customfile-preview').attr('src', App.request("tenant:get").getHomepagePic('original', values))

    events : 
      'change input[type="file"]' : 'fileChanged'
      'ajax:complete form' : 'fileUpdated'

    fileChanged : (ev) ->
      if @submit
        $save_button = @$el.find(".l-homepage-pic-form button")
        $save_button.text 'Save image'
        $save_button.show() if @submit

    fileUpdated : (ev) ->
      $save_button = @$el.find(".l-homepage-pic-form button")
      $save_button.hide()

    onShow : ->
      if App.request('user:current').isManager()
        @submit = false
        @$el.find('input[type="file"]').customFileInput()
        @stickit()
        @$el.find('.customfile-preview').attr('src', @model.homepage_pic_remote_url)
        @submit = true



    