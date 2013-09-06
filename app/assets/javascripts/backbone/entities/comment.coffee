@ConsiderIt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Comment extends App.Entities.Model
    name: 'comment'

    defaults: 
      moderation_status : 1

    initialize : (options = {}) ->
      super options
      #TODO: revisit htmlformat
      @attributes.body = htmlFormat(@attributes.body)

    url : () ->
      if @id
        Routes.show_comment_path(@id)
      else
        Routes.comments_path( )

    # relations
    getRoot : ->
      if !@root 
        @root = App.request "#{@get('commentable_type').toLowerCase()}:get", @get('commentable_id')
      @root
      
    getUser : ->
      if !@user 
        @user = App.request 'user', @get('user_id')
      @user

  class Entities.Comments extends App.Entities.Collection
    model: Entities.Comment

  API = 
    all_comments : new Entities.Comments()

    getComment : (id) ->
      @all_comments.get id

    addComments : (comments) ->
      @all_comments.set comments

    createComment : (attrs, options = {wait : true}) ->
      @all_comments.create attrs, options

    getCommentsByUser : (user_id) ->
      new Entities.Comments @all_comments.where({user_id : user_id})

    getCommentsByPoint : (point_id) ->
      new Entities.Comments @all_comments.where({commentable_type : 'Point', commentable_id : point_id})

  App.reqres.setHandler 'comment:get', (id) ->
    API.getComment id

  App.reqres.setHandler 'comment:create', (attrs, options = {wait : true}) ->
    API.createComment attrs, options

  App.vent.on 'comments:fetched', (comments) ->
    API.addComments comments

  App.reqres.setHandler 'comments:get:user', (model_id) ->
    API.getCommentsByUser model_id

  App.reqres.setHandler 'comments:get:point', (model_id) ->
    API.getCommentsByPoint model_id