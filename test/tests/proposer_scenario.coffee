require('../library/casper')
require('../library/asserts')
actions = require('../library/actions')
_ = require('underscore')

###
Tests creating a new proposal.

Not tested:
   - deleting a proposal from the homepage
   - after deleting a proposal, make sure it has been deleted from the homepage, when it would have shown up in the first set of results
   - for private proposal, receiving an invite email, following the link and logging in / creating an account

###

# BASIC
# login as admin
# create a new conversation
# are we navigated to the proposal page?
# refresh page, is new conversation still there, and is it visible? Is it still unpublished?
# delete conversation, is it gone?
# refresh page, is conversation still gone?
casper.test.begin 'Basic proposal pre-publishing and deletion tests', 12, (test) ->

  casper.start "http://localhost:8787/"

  casper.waitUntilVisible '[action="login"]', ->    
    actions.loginAsAdmin()

  casper.waitUntilVisible '.user-options-display', -> #wait until logged in...
    casper.HTMLCapture 'body', 
      caption : "After logging in as an admin"

    test.assertVisible '[action="create-new-proposal"]', 'Ability to create a new proposal'

    @click '[action="create-new-proposal"]'


  casper.waitUntilStateTransitioned 'crafting', ->
    @HTMLCapture 'body', 
      caption : "Now at the new proposal page"

    test.assertNotEquals "http://localhost:8787/", @getCurrentUrl(), 'We have navigated to the new proposal page'
    test.assertVisible "[activity='proposal-no-activity'][status='proposal-active'][visibility='unpublished']", 'Proposal has correct state settings'
    test.assertVisible "[action='delete-proposal']", 'Ability to delete proposal'
    test.assertVisible "[action='publish-proposal']", 'Ability to publish proposal'

    proposal_id = @getCurrentUrl().substring(@getCurrentUrl().lastIndexOf('/') + 1, @getCurrentUrl().length)

    @reload()

    @waitUntilVisible '[action="publish-proposal"]', ->
      test.assertVisible "[activity='proposal-no-activity'][status='proposal-active'][visibility='unpublished']", 'Proposal has correct state settings, after refreshing'
      test.assertVisible "[action='delete-proposal']", 'Ability to delete proposal after refreshing'
      test.assertVisible "[action='publish-proposal']", 'Ability to publish proposal after refreshing'

      @removeAllFilters 'page.confirm'
      @setFilter 'page.confirm', (message) ->
        return true

      @thenClick "[action='delete-proposal']"      
      @waitForUrl "http://localhost:8787/", ->
        test.pass 'After delete, navigate to homepage'

      @waitUntilVisible '#active_proposals_region [action="load-proposals"]', ->
        @click '#active_proposals_region [action="load-proposals"]'
        @waitUntilVisible '[data-type="sort"][action="created_at"]', ->
          @thenClick '[data-type="sort"][action="created_at"]', ->
            @wait 200, ->
              test.assertNotVisible "[data-id='#{proposal_id}']", 'Deleted proposal is not on homepage'

      @reload()

      @waitUntilVisible '#active_proposals_region', ->
        @click '#active_proposals_region [action="load-proposals"]'
        @waitUntilVisible '[data-type="sort"][action="created_at"]', ->
          @click '[data-type="sort"][action="created_at"]'
          @wait 200, ->
            test.assertNotVisible "[data-id='#{proposal_id}']", 'Deleted proposal is not on homepage after refresh'


    @thenOpen "http://localhost:8787/#{proposal_id}", ->
      @echo "loaded http://localhost:8787/#{proposal_id}"
      @wait 500, ->
        test.assertNotVisible '[role="proposal"]', "Can't load proposal that has been deleted"

  casper.then ->
    actions.logout()

  casper.run ->
    test.done()


# PUBLIC CONVERSATION
# login as admin
# create a new conversation
# update description, details
# hit publish
# does crafting view show up?
# go to homepage, is it there?
# navigate to it, can we see it?
# refresh page, is it still there?
# go to homepage, can we find it there?

# casper.test.begin 'Creating and accessing a public proposal tests', 9, (test) ->
#   casper.start "http://localhost:8787/"

#   casper.waitUntilVisible '[action="login"]', ->    
#     actions.loginAsAdmin()


#   casper.then ->
#     actions.logout()

#   casper.run ->
#     test.done() 

# # LINK ONLY CONVERSATION
# # login as admin
# # create a new conversation
# # update description
# # change to link only
# # publish
# # go to homepage, is it visible?
# # refresh page, is it still visible?
# # log out, is it not there?
# # open link, is it there? 
# # can a position be submitted?

# casper.test.begin 'Creating and accessing a link-only proposal tests', 9, (test) ->
#   casper.start "http://localhost:8787/"

#   casper.waitUntilVisible '[action="login"]', ->    
#     actions.loginAsAdmin()


#   casper.then ->
#     actions.logout()

#   casper.run ->
#     test.done() 

# # PRIVATE CONVERSATION
# # login as admin
# # create a new conversation
# # update description
# # change to private
# # add someone else as invited
# # publish
# # go to homepage, is it visible?
# # refresh page, is it still visible?
# # log out, is it not there?
# # login as invited user
# # is it on homepage?
# # can i access it directly?
# # can a position be submitted?
# casper.test.begin 'Creating and accessing a private proposal tests', 9, (test) ->

#   casper.start "http://localhost:8787/"

#   casper.waitUntilVisible '[action="login"]', ->    
#     actions.loginAsAdmin()

#   casper.then ->
#     actions.logout()

#   casper.run ->
#     test.done() 
