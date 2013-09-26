@ConsiderIt.module "Franklin.Comments", (Comments, App, Backbone, Marionette, $, _) ->
  class Comments.DiscussionEntry extends App.Views.ItemView
    events : 
      'click .thank' : 'giveThanks'
      'click .unthank' : 'revokeThanks'

    giveThanks : (ev) ->
      @trigger 'give_thanks'

    revokeThanks : (ev) ->
      @trigger 'revoke_thanks'

  class Comments.CommentView extends Comments.DiscussionEntry
    template : '#tpl_comment_view'
    className : 'm-comment'

    serializeData : ->
      current_user = App.request 'user:current'

      _.extend {}, @model.attributes,
        user : @model.getUser().attributes
        thanks : @model.getThanks()
        user_thanked : App.request 'thanks:exists_for_user', 'Comment', @model.id, current_user.id
        can_thank : current_user.isLoggedIn()

    onShow : ->
      current_user = App.request 'user:current'
      if current_user.id == @model.get('user_id') #|| ConsiderIt.request('user:current').isAdmin()
        @$el.find('.m-comment-body').editable 
          resource: 'comment'
          pk: @model.id
          url: Routes.comment_path @model.id
          type: 'textarea'
          name: 'body'
          success : (response, new_value) => @model.set('body', new_value)
    


  class Comments.ClaimView extends Comments.DiscussionEntry
    template : '#tpl_claim_comment_view' 
    className : 'm-claim-comment m-comment'


    serializeData : ->
      current_user = App.request 'user:current'
      
      params = 
        claim : @model
        assessment : @model.getAssessment()
        verdict : @model.getVerdict()
        thanks : @model.getThanks()
        user_thanked : App.request 'thanks:exists_for_user', 'Claim', @model.id, current_user.id
        can_thank : current_user.isLoggedIn()

      params
