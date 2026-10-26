Consider.it Data Exports
========================

Hosts of Premium Consider.it forums can export forum data via the "Data Import & Export" dashboard. There, you are able to download a zip file containing five CSV files (users, opinions, proposals, points, and inclusions). CSVs can be opened in Excel or Google Sheets etc. 


Before Diving into the Data
---------------------------

You may first wish to do some exploratory data analysis using the Consider.it interface itself. Beyond the basic Consider.it interface showing pros and cons, here are some features to explore:

#### Proposal Sorting
You can sort the proposals by various metrics to see what rises to the surface. Some favorites are *total score* and *most polarizing first*. 

#### Data Analytics Dashboard

Consider.it Premium Forums have a [data analytics dashboard](/dashboard/analytics). This dashboard plots basic visitation, participant, opinion, and comment data on timelines, and allows you to slice and dice the data by sign-in questions. It also just gives some useful raw data counts. 



<video preload="true" loop autoplay controls title="Consider.it data analytics dashboard" style="position: relative; width: 100%; aspect-ratio: 1920 / 1080; box-shadow: rgba(0, 0, 0, 0.25) 0px 1px 4px; transition: box-shadow 500ms ease 0s; display: block;" data-initialized playsinline data-controls><source src="//f.consider.it/participation_dashboard.mp4
" type="video/mp4">Consider.it data analytics dashboard.</video>



#### Opinion Analytics


If you've asked sign-in questions, you may wish to use the [opinion analytics](https://traviskriplean.com/exploratory-data-analysis-in-c-1cm7y6) functionality for slicing, dicing, and comparing opinions of subgroups.

Furthermore, opinion analytics weights can help you identify influential participants in the dialogue (those who wrote pros and cons and/or proposals that other people found important). 

<video loading="lazy" preload="true" loop="true" autoplay="true" controls="" title="In Consider.it, you can examine similarities and differences of opinions between subgroups." style="position: relative; width: 100%; aspect-ratio: 1920 / 1080; box-shadow: rgba(0, 0, 0, 0.25) 0px 1px 4px; transition: box-shadow 500ms ease 0s; display: block;" data-initialized="" playsinline="" class="" data-controls=""><source src="//d2rtgkroh5y135.cloudfront.net/images/product_page/screencasts/trimmed-opinion_analytics-small-x264.mp4" type="video/mp4">In Consider.it, you can examine similarities and differences of opinions between subgroups.</video>


The Data Export
---------------

As mentioned earlier, the forum data export contains five CSV files (users, opinions, proposals, points, and inclusions). 

Each of these files contains unique keys that can be used to link data together via a pivot table to answer most questions you might have, using the analysis software of your choice (e.g. Excel, Google Sheets, Tableau).

Specifically, the keys are:
 * The Users file contains an "email" column representing a participants' unique email address. The proposal, opinion, and points files also contains an "email" column representing the corresponding user that carried out that action.
 * The Proposals file contains a "proposal_slug" column identifying the proposal. The opinion, points, and inclusions files also have a proposal_slug column representing the proposal associated with the opinion or point.


Below is specific documentation for each file in the export.  


Users
-----

Users are all the people who signed up to participate in the forum.

The identification columns are: 
 * *email*: The participant's email address. Serves as the unique identifier for this participant.
 * *username*: The user name of the participant.

The basic columns are:
 * *date joined*: The date this user registered to participate.

If you added sign-up questions, there will be a column for each of those as well. Multi-select checkbox sign-up questions can have hard to interpret values if someone selects multiple values. There will be a delimiter like ';;;' separating each selection. 

#### For anonymized forums
Email and username will be anonymized if you permanently anonymized your forum. The email field will contain a unique identifier. 

If you asked sign-in questions in an anonymized forum, and didn't get them whitelisted for safety, please [Contact Us](mailto:help@consider.it).



Proposals
---------

Proposals are all of the statements in the forum that can be evaluated on spectrum with pro/con dialogue. 

The identification columns are: 
 * *proposal_slug*: The unique identifier for this proposal.
 * *url*: A link to this proposal in the forum. 

The author columns are:
 * *email*: The unique identifier for the author of this proposal.
 * *username*: The user name of the author of this proposal.

The basic columns are:
 * *created*: The date this proposal was first created.
 * *name*: The short headline of this proposal.
 * *category*: The prompt to which this proposal responds (like an open-ended question or a list header). 
 * *description*: The extended proposal description, if any was given.

The statistical columns are:
 * *#points*: The number of pro and con points participants articulated about this proposal.
 * *#opinions*: The number of opinions participants articulated about this proposal. Note that participants can express an opinion on the slider without substantiating their opinion with pro and con reasons. 
 * *total score*. As described in the Opinions section below, each opinion is a continuous value from -1.0 to 1.0, where -1.0 is full disagree, 0 is neutral, and 1.0 is full agreement. The total score of a proposal is the sum of the opinions given on this proposal, with negative opinions subtracting from the score, and positive values adding. Negative total scores are possible. 
 * *avg score*. Distinct from the total score is the average score. The average score is the average opinion score, on a scale from -1 to 1. Negative average scores are possible.
 * *std deviation*. Standard deviation of the opinion scores. This is useful as a metric of the polarization of the responses. You'll see a higher standard deviation for proposals with the widest variation in participants' opinions, and lower standard deviation for proposals where people vary less in their opinion (for example, many people giving negative opinions, or many people giving positive opinions). 

#### Total score vs Average score

Pretend that we have two proposals X and Y. X has 100 opinions with an average score of .5. Pretty good. Y on the other hand only has 10 opinions, each of them expressing maximal support with opinion scores of 1. Y will have the higher average score (1 vs .5), while X will have the higher total score (50 for X and 10 for Y). Proposals with a good total score tend to have both decent overall support and have been evaluated by quite a few people. There isn't a rule though about how to interpret proposals with a high average score and low total score (relative to other proposals). In some cases, this can happen if a proposal is added later on and few people saw it (but those that did really liked it). Or perhaps there were lots of proposals on the forum and people didn't get around to evaluating that proposal. Or many participants were indifferent to the proposal and didn't bother evaluating it, except for a few advocates. 


Opinions
--------


An opinion is the evaluation of a proposal by a participant, given by dragging the slider. 

The proposal columns are:
 * *proposal_slug*: The unique identifier for the proposal being evaluated.
 * *proposal_name*: The headline text of the proposal being evaluated.

The participant columns are:
 * *email*: The unique identifier of the user giving this opinion.
 * *username*: The user name of the user giving this opinion.

The basic columns are:
 * *created_at*: The date this opinion was first created.
 * *opinion*: The opinion score the participant gave the proposal. The score is a continuous value from -1.0 to 1.0, where -1.0 is fully negative, 0 is neutral, and 1.0 is fully positive.
 
The statistical columns are:
 * *#points*: The number of pro and con points this participant recognized as important (by authoring pro or con points and/or including the pros and cons of others). 


Points
------

The points file is a little strange. It contains both Pro and Con points, as well as any comments that other participants added in response to any of the pros or cons. The rows are structured such that if a pro or con point received any comments, the comments are shown immediately below the pro or con point. 


The proposal columns are:
 * *proposal_slug*: The unique identifier for the proposal being evaluated.
 * *proposal_name*: The headline text of the proposal being evaluated.

The participant columns are:
 * *email*: The unique identifier of the author.
 * *username*: The user name of the author.

The basic columns are:
 * *created*: The date the statement was added.
 * *type*: Whether this row represents a Pro/Con ("POINT") or a comment on a pro/con ("COMMENT").
 * *summary*: The main text.
 * *author_opinion*: The opinion score the author gave the proposal. Can be blank for comments, as commenters do not need to provide an opinion on the proposal. 

Columns for Pros and Cons (blank for comments):
 * *valence*: Whether it is a Pro or Con. 
 * *details*: Any additional description the author may have provided about their point.
 * *#inclusions*: The number of times people included this point into their pro/con list. You can think of an inclusion like a vote for its importance. 
 * *#comments*: The number of comments a pro or con point received.


Inclusions
----------

An inclusion happens when a user incorporates a pro or a con point into their opinion about a proposal. This can happen either by the user authoring a new pro or con point, or by dragging a pro or con point someone else wrote into their pro/con list. 

The proposal columns are:
 * *proposal_slug*: The unique identifier for the proposal being evaluated.
 * *proposal_name*: The headline text of the proposal being evaluated.

The participant columns are:
 * *email*: The unique identifier of the user giving this opinion.
 * *username*: The user name of the user giving this opinion.

The opinion columns are:
 * *created_at*: The date the opinion was first created.
 * *opinion_on_proposal*: The opinion score the participant gave the proposal. The score is a continuous value from -1.0 to 1.0, where -1.0 is fully negative, 0 is neutral, and 1.0 is fully positive.
 
The inclusion columns are:
 * *valence*: Whether the included point is a Pro or Con. 
 * *point*: The summary text of the pro or con point.
 * *is_author*: Whether this user wrote the point themselves (will be false if they dragged the point into their list)

