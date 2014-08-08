_ = require('../../node_modules/underscore')

_.extend casper.test, 
  assertLoggedIn : ->
    @assertExists '[data-action="logout"]', 'User is logged in'

  assertLoggedOut : ->
    @assertExists '[action="login"]', 'User has successfully logged out'

  assertOnHomepage : ->
    @assertExists '[data-role="proposal"][data-state="summary"]', "there is at least one proposal, and it is collapsed"
    @assertElementCount '#active_proposals_region [data-role="proposal"]', 5, "there are 5 active proposals"
    @assertElementCount '#past_proposals_region [data-role="proposal"]', 0, "there are no inactive proposals"
    @assertExists '#active_proposals_region [action="load-proposals"]', 'ability to load more active proposals'
    @assertExists '#past_proposals_region [action="load-proposals"]', 'ability to load more inactive proposals'

  assertInResultsState : ->
    @assertExists '[data-role="proposal"][data-state="results"]', 'Proposal is in results state'
    @assertElementCount '[data-role="proposal"]', 1, "there is only one proposal on the page"
    @assertVisible '.proposal_details', 'Proposal details are visible'
    @assertElementCount '.histogram_bar', 7, 'There are seven histogram bars visible'
    @assertExists '.points_by_community[data-state="results"]', 'Pros and cons in together state'
    @assertSelectorHasText '.points_heading_label', 'Pros', 'Pros present in pros header'
    @assertSelectorDoesntHaveText '.points_heading_label', 'upport', 'Supporter is not present in pros header'

  assertInCraftingState : (state_suffix = '') ->
    @assertExists '[data-role="proposal"][data-state="crafting"]', 'Proposal is in crafting state' + state_suffix
    @assertElementCount '[data-role="proposal"]', 1, "there is only one proposal on the page" + state_suffix
    @assertVisible '.proposal_details', 'Proposal details are visible' + state_suffix
    @assertExists '.decision_board_layout[data-state="crafting"]', 'Decision slate is visible' + state_suffix
    @assertExists '.points_by_community[data-state="crafting"]', 'Pros and cons on margins' + state_suffix
    @assertExists '.slider_container', 'Slider present' + state_suffix
    @assertElementCount '.add_point_drop_target', 2, 'Drop targets present' + state_suffix
    @assertElementCount '[action="write-point"]', 2, 'Add points present' + state_suffix
    @assertExists '[action="view-results"]', 'Opportunity to navigate to results page' + state_suffix

  assertInUserProfile : ->
    @assertElementCount '.dashboard-profile-activity-summary', 4, "there are four activity blocks"
    #@assertExists '.dashboard-profile-influence-summary', 'There is an influence tracker'

  assertPointIsOpen : ->
    @assertVisible '.point_description', 'Point details are visible'
    @assertVisible '.point_discussion_region', 'Discussion section exists'

  assertCommentIsVisible : (comment_id) ->
    @assertPointIsOpen()
    @assertVisible "#comment_#{comment_id}", 'Comment is visible'

  assertUserOpinionVisible : ->
    @assertVisible '.user_opinion-reasons', 'Viewing other user opinion works'
