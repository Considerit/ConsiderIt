@ConsiderIt.module "Franklin.Homepage", (Homepage, App, Backbone, Marionette, $, _) ->

  class Homepage.HomepageLayout extends App.Views.Layout
    template: "#tpl_homepage_layout"
    className : 'homepage_layout'
    regions :
      headerRegion : '#homepage_header_region'
      proposalsRegion : '#homepage_proposals_region'


  class Homepage.HomepageHeadingView extends App.Views.ItemView
    template: '#tpl_homepage_heading'
    className: 'homepage_heading_view'

    serializeData : ->
      is_manager : App.request('user:current').isManager()
      tenant : App.request('tenant')

    bindings : 
      '.homepage_account_image .hide' : 
        observe : 'homepage_pic_file_name'
        onGet : (values) ->
          return if !values? || $.trim(values)==''
          @$el.find('.homepage_account_image img.customfile-preview').attr('src', App.request("tenant").getHomepagePic('original', values))

    events : 
      'change input[type="file"]' : 'fileChanged'
      'ajax:complete form' : 'fileUpdated'

    fileChanged : (ev) ->
      if @submit
        $save_button = @$el.find(".homepage_account_image_form button")
        $save_button.text 'Save image'
        $save_button.show() if @submit

    fileUpdated : (ev) ->
      $save_button = @$el.find(".homepage_account_image_form button")
      $save_button.hide()

    onShow : ->
      if App.request('user:current').isManager()
        @submit = false
        @$el.find('input[type="file"]').customFileInput()
        @stickit()
        @$el.find('.customfile-preview').attr('src', @model.homepage_pic_remote_url)
        @submit = true



    