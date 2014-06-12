require('../library/casper')
require('../library/asserts')
actions = require('../library/actions')
_ = require('../../node_modules/underscore')

###
Tests creating a new proposal.

Not tested:
   - deleting a proposal from the homepage
   - after deleting a proposal, make sure it has been deleted from the homepage, when it would have shown up in the first set of results
   - for private proposal, receiving an invite email, following the link and logging in / creating an account
   - making a proposal inactive
   - changing publicity settings after publishing
###

# BASIC
# login as admin
# create a new conversation
# are we navigated to the proposal page?
# refresh page, is new conversation still there, and is it visible? Is it still unpublished?
# delete conversation, is it gone?
# refresh page, is conversation still gone?
casper.test.begin 'Basic proposal pre-publishing and deletion tests', 11, (test) ->

  casper.start "http://localhost:8787/"

  casper.waitUntilVisible '[action="login"]', ->    
    actions.loginAsAdmin()


  casper.then ->
    casper.HTMLCapture 'body', 
      caption : "After logging in as an admin"

    test.assertVisible '[action="create-new-proposal"]', 'Ability to create a new proposal'

    @click '[action="create-new-proposal"]'


  casper.waitUntilStateTransitioned 'crafting', ->
    @HTMLCapture 'body', 
      caption : "Now at the new proposal page"

    test.assertNotEquals "http://localhost:8787/", @getCurrentUrl(), 'We have navigated to the new proposal page'
    test.assertVisible "[data-activity='proposal-no-activity'][data-status='proposal-active'][data-visibility='unpublished']", 'Proposal has correct state settings'
    test.assertVisible "[action='delete-proposal']", 'Ability to delete proposal'
    test.assertVisible "[action='publish-proposal']", 'Ability to publish proposal'

    proposal_id = @getCurrentUrl().substring(@getCurrentUrl().lastIndexOf('/') + 1, @getCurrentUrl().length)

    @reload()

    @waitUntilVisible '[action="publish-proposal"]', ->
      test.assertVisible "[data-activity='proposal-no-activity'][data-status='proposal-active'][data-visibility='unpublished']", 'Proposal has correct state settings, after refreshing'
      test.assertVisible "[action='delete-proposal']", 'Ability to delete proposal after refreshing'
      test.assertVisible "[action='publish-proposal']", 'Ability to publish proposal after refreshing'

      @removeAllFilters 'page.confirm'
      @setFilter 'page.confirm', (message) ->
        return true

      @thenClick "[action='delete-proposal']"      
      @waitForUrl "http://localhost:8787/"

      @waitUntilVisible '#active_proposals_region [action="load-proposals"]'
      @thenClick '#active_proposals_region [action="load-proposals"]'
      @waitUntilVisible '[data-type="sort"][action="created_at"]'
      @thenClick '[data-type="sort"][action="created_at"]'
      @wait 200, ->
        test.assertNotVisible "[data-id='#{proposal_id}']", 'Deleted proposal is not on homepage'

      @reload()

      @waitUntilVisible '#active_proposals_region'
      @thenClick '#active_proposals_region [action="load-proposals"]'
      @waitUntilVisible '[data-type="sort"][action="created_at"]'
      @thenClick '[data-type="sort"][action="created_at"]'
      @wait 200, ->
        test.assertNotVisible "[data-id='#{proposal_id}']", 'Deleted proposal is not on homepage after refresh'


    @thenOpen "http://localhost:8787/#{proposal_id}"
    @wait 500, ->
      test.assertNotVisible '[data-role="proposal"]', "Can't load proposal that has been deleted"

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
# can a position be submitted?

# LINK ONLY CONVERSATION
# login as admin
# create a new conversation
# update description
# change to link only
# publish
# go to homepage, is it visible?
# refresh page, is it still visible?
# log out, is it not there?
# open link, is it there? 
# can a position be submitted?

# PRIVATE CONVERSATION
# login as admin
# create a new conversation
# update description
# change to private
# add someone else as invited
# publish
# go to homepage, is it visible?
# refresh page, is it still visible?
# log out, is it not there?
# login as invited user
# is it on homepage?
# can i access it directly?
# can a position be submitted?

proposal_summary = "Should creating a proposal be rigorously tested?"
proposal_details = "We could test all day all night all day all night."


test_proposal_publicity = (test, publicity) ->
  casper.start "http://localhost:8787/"

  casper.waitUntilVisible '[action="login"]', ->    
    actions.loginAsAdmin()

  casper.waitUntilVisible '.user-options-display', -> #wait until logged in...
    @click '[action="create-new-proposal"]'

  casper.waitUntilStateTransitioned 'crafting', ->
    test.assertExists '.description_region_summary.editable', 'Proposal summary is editable'
    test.assertExists '.proposal_details.editable', 'Proposal details is editable'

    proposal_id = @getCurrentUrl().substring(@getCurrentUrl().lastIndexOf('/') + 1, @getCurrentUrl().length)

    @thenClick '.description_region_summary.editable'

    @waitUntilVisible '.editable-input textarea', ->
      @sendKeys ".editable-input textarea", proposal_summary
      @click '.editable-buttons button[type="submit"]'
      @wait 200, ->
        test.assertSelectorHasText '.description_region_summary.editable', proposal_summary, 'proposal summary can be modified'

    @thenClick '.proposal_details.editable'

    @waitUntilVisible '.editable-input textarea', ->
      @sendKeys ".editable-input textarea", proposal_details

      @HTMLCapture 'body', 
        caption : "Editing a proposal"

      @click '.editable-buttons button[type="submit"]'
      @wait 200, ->
        test.assertSelectorHasText '.proposal_details.editable', proposal_details, 'proposal details can be modified'

    if publicity == 'private' || publicity == 'link-only'
      @then ->
        test.assertVisible '.proposal_admin_publicity', 'Ability to change proposal publicity'
        @thenClick '.proposal_admin_publicity a'
        @waitUntilVisible '.l-dialog-detachable.proposal_admin_publicity', ->
          if publicity == 'link-only'
            test.assertVisible '#proposal_publicity_1', 'Ability to select link-only publicity'
            @thenClick '#proposal_publicity_1'
          else if publicity == 'private'
            test.assertVisible '#proposal_publicity_0', 'Ability to select private publicity'
            @thenClick '#proposal_publicity_0'
            test.assertVisible '#proposal_access_list', 'ability to specify access list'
            @sendKeys '#proposal_access_list', 'testy_mctesttest@local.dev,testy_mctesttest_private@local.dev'

            @HTMLCapture '.l-dialog-detachable', 
              caption : "Specifying private proposal"

          @thenClick '.l-dialog-detachable input[type="submit"]'
        , -> test.fail 'Publicity dialog never appears'

        @waitWhileVisible '.l-dialog-detachable.proposal_admin_publicity'


    @thenClick "[action='publish-proposal']"

    @waitUntilVisible '[data-visibility="published"]', ->
      test.pass 'Proposal is published'
      test.assertVisible '[action="submit-opinion"]', 'Crafting view is now visible'
    , ->
      test.fail 'Proposal cannot be published'

    @thenClick '[action="go-home"]'
    @waitUntilVisible '#active_proposals_region [action="load-proposals"]', ->
      @click '#active_proposals_region [action="load-proposals"]'
      @waitUntilVisible '[data-type="sort"][action="created_at"]', ->
        @thenClick '[data-type="sort"][action="created_at"]', ->
          @wait 200, ->
            test.assertVisible "[data-id='#{proposal_id}']", 'New published proposal is on homepage for creator, before refreshing'
    , -> test.fail 'Homepage never loaded'

    @reload()

    @waitUntilVisible '#active_proposals_region [action="load-proposals"]' 
    @thenClick '#active_proposals_region [action="load-proposals"]'
    @waitUntilVisible '[data-type="sort"][action="created_at"]'
    @thenClick '[data-type="sort"][action="created_at"]'
    @wait 200, ->
      test.assertVisible "[data-id='#{proposal_id}']", 'New published proposal is on homepage for creator, after refreshing'


    @thenOpen "http://localhost:8787/#{proposal_id}"
    @waitUntilStateTransitioned 'crafting', ->
      test.pass 'New proposal can be directly accessed by creator'

    actions.logout()

    @thenOpen "http://localhost:8787/#{proposal_id}", ->
      if publicity == 'public' || publicity == 'link-only'
        @waitUntilStateTransitioned 'crafting', ->
          test.pass "New #{publicity} proposal can be directly accessed by anon"
        , -> test.fail "New #{publicity} proposal can be directly accessed by anon"

        actions.createAccount "testy_mctesttest_#{publicity}@local.dev"

        @waitUntilVisible '[action="submit-opinion"]', ->
          @thenClick '[action="submit-opinion"]'
        , -> test.fail "New user can't submit opinion"

        @waitUntilStateTransitioned 'results', ->
          test.pass "New user can submit an opinion for a #{publicity} proposal"
        , -> test.fail "New user can submit an opinion for a #{publicity} proposal"

        actions.logout()

      else if publicity == 'private'
        @waitUntilStateTransitioned 'summary', ->
          test.pass 'Anon accessing a private proposal is redirected to homepage'

          @HTMLCapture 'body', 
            caption : "After anon tries to access a private proposal"


    @thenOpen "http://localhost:8787/"

    @waitUntilVisible '#active_proposals_region [action="load-proposals"]' 
    @thenClick '#active_proposals_region [action="load-proposals"]'
    @waitUntilVisible '[data-type="sort"][action="created_at"]'
    @thenClick '[data-type="sort"][action="created_at"]', ->
      @wait 200, ->
        if publicity == 'public'
          test.assertVisible "[data-id='#{proposal_id}']", 'New published proposal is on homepage for anon'
        else 
          test.assertDoesntExist "[data-id='#{proposal_id}']", "New published #{publicity} proposal is NOT on homepage for anon"

    @then ->
      if publicity == 'private'
        actions.createAccount "testy_mctesttest_#{publicity}@local.dev"
        @wait 3000 # WAIT FOR AJAX TO RETURN; would be nice to have better condition
        @waitUntilVisible '[data-type="sort"][action="created_at"]'
        @thenClick '[data-type="sort"][action="created_at"]', ->
          @wait 200, ->
            test.assertVisible "[data-id='#{proposal_id}']", 'New published proposal is on homepage for user with access'

        @thenOpen "http://localhost:8787/#{proposal_id}"
        @waitUntilStateTransitioned 'crafting', null, -> 
          test.fail 'Could not craft position when logged in as user with access to a private proposal'

        @waitUntilVisible '[action="submit-opinion"]', ->
          @thenClick '[action="submit-opinion"]'
        , -> test.fail "User with access can't submit opinion"

        @waitUntilStateTransitioned 'results', ->
          test.pass "User with access can submit an opinion for a private proposal"
        , -> test.fail "User with access can submit an opinion for a private proposal"

        @thenOpen "http://localhost:8787/"
        @waitUntilVisible '#active_proposals_region [action="load-proposals"]' 
        @thenClick '#active_proposals_region [action="load-proposals"]'

    actions.loginAsAdmin()

    @thenClick '[data-type="sort"][action="created_at"]'
    @wait 200, ->
      test.assertVisible "[data-id='#{proposal_id}']", "Published #{publicity} proposal is accessible after logging out and back in"
      test.assertVisible "[data-id='#{proposal_id}'] .proposal_admin_strip i", 'Ability to access proposal settings for published proposal'
      @mouse.move "[data-id='#{proposal_id}'] .proposal_admin_strip i"
      test.assertVisible "[data-id='#{proposal_id}'] [action='delete-proposal']", 'Ability to delete proposal from settings menu'

    @thenClick "[data-id='#{proposal_id}'] [action='delete-proposal']"

    @waitWhileSelector "[data-id='#{proposal_id}']", ->
      test.pass 'Published proposal can be deleted'
    , -> test.fail 'Published proposal was not deleted'

    actions.logout()



casper.test.begin "Creating and accessing a public proposal tests", 16, (test) ->
  test_proposal_publicity test, 'public'

  casper.run ->
    test.done() 

casper.test.begin "Creating and accessing a link-only proposal tests", 18, (test) ->
  test_proposal_publicity test, 'link-only'

  casper.run ->
    test.done() 

casper.test.begin "Creating and accessing a private proposal tests", 20, (test) ->
  test_proposal_publicity test, 'private'

  casper.run ->
    test.done() 

