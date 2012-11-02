alter table accounts change identifier identifier VARCHAR(255) character set latin1;
alter table accounts change identifier identifier VARBINARY(255);
alter table accounts change identifier identifier VARCHAR(255) character set utf8;

alter table accounts change theme theme VARCHAR(255) character set latin1;
alter table accounts change theme theme VARBINARY(255);
alter table accounts change theme theme VARCHAR(255) character set utf8;

alter table accounts change app_title app_title VARCHAR(255) character set latin1;
alter table accounts change app_title app_title VARBINARY(255);
alter table accounts change app_title app_title VARCHAR(255) character set utf8;

alter table accounts change contact_email contact_email VARCHAR(255) character set latin1;
alter table accounts change contact_email contact_email VARBINARY(255);
alter table accounts change contact_email contact_email VARCHAR(255) character set utf8;

alter table accounts change socmedia_facebook_page socmedia_facebook_page VARCHAR(255) character set latin1;
alter table accounts change socmedia_facebook_page socmedia_facebook_page VARBINARY(255);
alter table accounts change socmedia_facebook_page socmedia_facebook_page VARCHAR(255) character set utf8;

alter table accounts change socmedia_twitter_account socmedia_twitter_account VARCHAR(255) character set latin1;
alter table accounts change socmedia_twitter_account socmedia_twitter_account VARBINARY(255);
alter table accounts change socmedia_twitter_account socmedia_twitter_account VARCHAR(255) character set utf8;

alter table accounts change analytics_google analytics_google VARCHAR(255) character set latin1;
alter table accounts change analytics_google analytics_google VARBINARY(255);
alter table accounts change analytics_google analytics_google VARCHAR(255) character set utf8;

alter table accounts change socmedia_facebook_client socmedia_facebook_client VARCHAR(255) character set latin1;
alter table accounts change socmedia_facebook_client socmedia_facebook_client VARBINARY(255);
alter table accounts change socmedia_facebook_client socmedia_facebook_client VARCHAR(255) character set utf8;

alter table accounts change socmedia_facebook_secret socmedia_facebook_secret VARCHAR(255) character set latin1;
alter table accounts change socmedia_facebook_secret socmedia_facebook_secret VARBINARY(255);
alter table accounts change socmedia_facebook_secret socmedia_facebook_secret VARCHAR(255) character set utf8;

alter table accounts change socmedia_twitter_consumer_key socmedia_twitter_consumer_key VARCHAR(255) character set latin1;
alter table accounts change socmedia_twitter_consumer_key socmedia_twitter_consumer_key VARBINARY(255);
alter table accounts change socmedia_twitter_consumer_key socmedia_twitter_consumer_key VARCHAR(255) character set utf8;

alter table accounts change socmedia_twitter_consumer_secret socmedia_twitter_consumer_secret VARCHAR(255) character set latin1;
alter table accounts change socmedia_twitter_consumer_secret socmedia_twitter_consumer_secret VARBINARY(255);
alter table accounts change socmedia_twitter_consumer_secret socmedia_twitter_consumer_secret VARCHAR(255) character set utf8;

alter table accounts change socmedia_twitter_oauth_token_secret socmedia_twitter_oauth_token_secret VARCHAR(255) character set latin1;
alter table accounts change socmedia_twitter_oauth_token_secret socmedia_twitter_oauth_token_secret VARBINARY(255);
alter table accounts change socmedia_twitter_oauth_token_secret socmedia_twitter_oauth_token_secret VARCHAR(255) character set utf8;

alter table accounts change socmedia_twitter_oauth_token socmedia_twitter_oauth_token VARCHAR(255) character set latin1;
alter table accounts change socmedia_twitter_oauth_token socmedia_twitter_oauth_token VARBINARY(255);
alter table accounts change socmedia_twitter_oauth_token socmedia_twitter_oauth_token VARCHAR(255) character set utf8;

alter table accounts change default_hashtags default_hashtags VARCHAR(255) character set latin1;
alter table accounts change default_hashtags default_hashtags VARBINARY(255);
alter table accounts change default_hashtags default_hashtags VARCHAR(255) character set utf8;

alter table accounts change host host VARCHAR(255) character set latin1;
alter table accounts change host host VARBINARY(255);
alter table accounts change host host VARCHAR(255) character set utf8;

alter table accounts change host_with_port host_with_port VARCHAR(255) character set latin1;
alter table accounts change host_with_port host_with_port VARBINARY(255);
alter table accounts change host_with_port host_with_port VARCHAR(255) character set utf8;

alter table accounts change inherited_themes inherited_themes VARCHAR(255) character set latin1;
alter table accounts change inherited_themes inherited_themes VARBINARY(255);
alter table accounts change inherited_themes inherited_themes VARCHAR(255) character set utf8;

alter table accounts change pro_label pro_label VARCHAR(255) character set latin1;
alter table accounts change pro_label pro_label VARBINARY(255);
alter table accounts change pro_label pro_label VARCHAR(255) character set utf8;

alter table accounts change con_label con_label VARCHAR(255) character set latin1;
alter table accounts change con_label con_label VARBINARY(255);
alter table accounts change con_label con_label VARCHAR(255) character set utf8;

alter table accounts change slider_right slider_right VARCHAR(255) character set latin1;
alter table accounts change slider_right slider_right VARBINARY(255);
alter table accounts change slider_right slider_right VARCHAR(255) character set utf8;

alter table accounts change slider_left slider_left VARCHAR(255) character set latin1;
alter table accounts change slider_left slider_left VARBINARY(255);
alter table accounts change slider_left slider_left VARCHAR(255) character set utf8;

alter table accounts change slider_prompt slider_prompt VARCHAR(255) character set latin1;
alter table accounts change slider_prompt slider_prompt VARBINARY(255);
alter table accounts change slider_prompt slider_prompt VARCHAR(255) character set utf8;

alter table accounts change considerations_prompt considerations_prompt VARCHAR(255) character set latin1;
alter table accounts change considerations_prompt considerations_prompt VARBINARY(255);
alter table accounts change considerations_prompt considerations_prompt VARCHAR(255) character set utf8;

alter table accounts change statement_prompt statement_prompt VARCHAR(255) character set latin1;
alter table accounts change statement_prompt statement_prompt VARBINARY(255);
alter table accounts change statement_prompt statement_prompt VARCHAR(255) character set utf8;

alter table accounts change entity entity VARCHAR(255) character set latin1;
alter table accounts change entity entity VARBINARY(255);
alter table accounts change entity entity VARCHAR(255) character set utf8;





alter table proposals change designator designator VARCHAR(255) character set latin1;
alter table proposals change designator designator VARBINARY(255);
alter table proposals change designator designator VARCHAR(255) character set utf8;

alter table proposals change category category VARCHAR(255) character set latin1;
alter table proposals change category category VARBINARY(255);
alter table proposals change category category VARCHAR(255) character set utf8;

alter table proposals change name name VARCHAR(255) character set latin1;
alter table proposals change name name VARBINARY(255);
alter table proposals change name name VARCHAR(255) character set utf8;

alter table proposals change short_name short_name VARCHAR(255) character set latin1;
alter table proposals change short_name short_name VARBINARY(255);
alter table proposals change short_name short_name VARCHAR(255) character set utf8;

alter table proposals change description description TEXT character set latin1;
alter table proposals change description description BLOB;
alter table proposals change description description TEXT character set utf8;

alter table proposals change long_description long_description TEXT character set latin1;
alter table proposals change long_description long_description BLOB;
alter table proposals change long_description long_description TEXT character set utf8;

alter table proposals change additional_details additional_details TEXT character set latin1;
alter table proposals change additional_details additional_details BLOB;
alter table proposals change additional_details additional_details TEXT character set utf8;


alter table proposals change slider_right slider_right VARCHAR(255) character set latin1;
alter table proposals change slider_right slider_right VARBINARY(255);
alter table proposals change slider_right slider_right VARCHAR(255) character set utf8;

alter table proposals change slider_left slider_left VARCHAR(255) character set latin1;
alter table proposals change slider_left slider_left VARBINARY(255);
alter table proposals change slider_left slider_left VARCHAR(255) character set utf8;

alter table proposals change slider_prompt slider_prompt VARCHAR(255) character set latin1;
alter table proposals change slider_prompt slider_prompt VARBINARY(255);
alter table proposals change slider_prompt slider_prompt VARCHAR(255) character set utf8;

alter table proposals change considerations_prompt considerations_prompt VARCHAR(255) character set latin1;
alter table proposals change considerations_prompt considerations_prompt VARBINARY(255);
alter table proposals change considerations_prompt considerations_prompt VARCHAR(255) character set utf8;

alter table proposals change statement_prompt statement_prompt VARCHAR(255) character set latin1;
alter table proposals change statement_prompt statement_prompt VARBINARY(255);
alter table proposals change statement_prompt statement_prompt VARCHAR(255) character set utf8;

alter table proposals change entity entity VARCHAR(255) character set latin1;
alter table proposals change entity entity VARBINARY(255);
alter table proposals change entity entity VARCHAR(255) character set utf8;





alter table activities change action_type action_type VARCHAR(255) character set latin1;
alter table activities change action_type action_type VARBINARY(255);
alter table activities change action_type action_type VARCHAR(255) character set utf8;

alter table assessments change assessable_type assessable_type VARCHAR(255) character set latin1;
alter table assessments change assessable_type assessable_type VARBINARY(255);
alter table assessments change assessable_type assessable_type VARCHAR(255) character set utf8;

alter table assessments change qualifies_reason qualifies_reason VARCHAR(255) character set latin1;
alter table assessments change qualifies_reason qualifies_reason VARBINARY(255);
alter table assessments change qualifies_reason qualifies_reason VARCHAR(255) character set utf8;

alter table claims change result result TEXT character set latin1;
alter table claims change result result BLOB;
alter table claims change result result TEXT character set utf8;

alter table claims change claim claim TEXT character set latin1;
alter table claims change claim claim BLOB;
alter table claims change claim claim TEXT character set utf8;

alter table claims change notes notes TEXT character set latin1;
alter table claims change notes notes BLOB;
alter table claims change notes notes TEXT character set utf8;

alter table comments change commentable_type commentable_type VARCHAR(255) character set latin1;
alter table comments change commentable_type commentable_type VARBINARY(255);
alter table comments change commentable_type commentable_type VARCHAR(255) character set utf8;

alter table comments change title title VARCHAR(255) character set latin1;
alter table comments change title title VARBINARY(255);
alter table comments change title title VARCHAR(255) character set utf8;

alter table comments change subject subject VARCHAR(255) character set latin1;
alter table comments change subject subject VARBINARY(255);
alter table comments change subject subject VARCHAR(255) character set utf8;

alter table comments change body body TEXT character set latin1;
alter table comments change body body BLOB;
alter table comments change body body TEXT character set utf8;


alter table delayed_jobs change queue queue VARCHAR(255) character set latin1;
alter table delayed_jobs change queue queue VARBINARY(255);
alter table delayed_jobs change queue queue VARCHAR(255) character set utf8;

alter table delayed_jobs change locked_by locked_by VARCHAR(255) character set latin1;
alter table delayed_jobs change locked_by locked_by VARBINARY(255);
alter table delayed_jobs change locked_by locked_by VARCHAR(255) character set utf8;

alter table delayed_jobs change handler handler TEXT character set latin1;
alter table delayed_jobs change handler handler BLOB;
alter table delayed_jobs change handler handler TEXT character set utf8;

alter table delayed_jobs change last_error last_error TEXT character set latin1;
alter table delayed_jobs change last_error last_error BLOB;
alter table delayed_jobs change last_error last_error TEXT character set utf8;



alter table emails change from_address from_address VARCHAR(255) character set latin1;
alter table emails change from_address from_address VARBINARY(255);
alter table emails change from_address from_address VARCHAR(255) character set utf8;

alter table emails change reply_to_address reply_to_address VARCHAR(255) character set latin1;
alter table emails change reply_to_address reply_to_address VARBINARY(255);
alter table emails change reply_to_address reply_to_address VARCHAR(255) character set utf8;

alter table emails change subject subject VARCHAR(255) character set latin1;
alter table emails change subject subject VARBINARY(255);
alter table emails change subject subject VARCHAR(255) character set utf8;

alter table emails change to_address to_address TEXT character set latin1;
alter table emails change to_address to_address BLOB;
alter table emails change to_address to_address TEXT character set utf8;

alter table emails change cc_address cc_address TEXT character set latin1;
alter table emails change cc_address cc_address BLOB;
alter table emails change cc_address cc_address TEXT character set utf8;

alter table emails change bcc_address bcc_address TEXT character set latin1;
alter table emails change bcc_address bcc_address BLOB;
alter table emails change bcc_address bcc_address TEXT character set utf8;

alter table emails change content content TEXT character set latin1;
alter table emails change content content BLOB;
alter table emails change content content TEXT character set utf8;

alter table follows change followable_type followable_type VARCHAR(255) character set latin1;
alter table follows change followable_type followable_type VARBINARY(255);
alter table follows change followable_type followable_type VARCHAR(255) character set utf8;

alter table moderations change moderatable_type moderatable_type VARCHAR(255) character set latin1;
alter table moderations change moderatable_type moderatable_type VARBINARY(255);
alter table moderations change moderatable_type moderatable_type VARCHAR(255) character set utf8;

alter table points change nutshell nutshell TEXT character set latin1;
alter table points change nutshell nutshell BLOB;
alter table points change nutshell nutshell TEXT character set utf8;

alter table points change text text TEXT character set latin1;
alter table points change text text BLOB;
alter table points change text text TEXT character set utf8;

alter table points change includers includers TEXT character set latin1;
alter table points change includers includers BLOB;
alter table points change includers includers TEXT character set utf8;

alter table positions change explanation explanation TEXT character set latin1;
alter table positions change explanation explanation BLOB;
alter table positions change explanation explanation TEXT character set utf8;

alter table reflect_response_revisions change text text TEXT character set latin1;
alter table reflect_response_revisions change text text BLOB;
alter table reflect_response_revisions change text text TEXT character set utf8;

alter table reflect_bullet_revisions change text text TEXT character set latin1;
alter table reflect_bullet_revisions change text text BLOB;
alter table reflect_bullet_revisions change text text TEXT character set utf8;

alter table reflect_bullet_revisions change comment_type comment_type TEXT character set latin1;
alter table reflect_bullet_revisions change comment_type comment_type BLOB;
alter table reflect_bullet_revisions change comment_type comment_type TEXT character set utf8;

alter table requests change suggestion suggestion TEXT character set latin1;
alter table requests change suggestion suggestion BLOB;
alter table requests change suggestion suggestion TEXT character set utf8;

alter table taggings change taggable_type taggable_type VARCHAR(255) character set latin1;
alter table taggings change taggable_type taggable_type VARBINARY(255);
alter table taggings change taggable_type taggable_type VARCHAR(255) character set utf8;

alter table taggings change tagger_type tagger_type VARCHAR(255) character set latin1;
alter table taggings change tagger_type tagger_type VARBINARY(255);
alter table taggings change tagger_type tagger_type VARCHAR(255) character set utf8;

alter table taggings change context context VARCHAR(255) character set latin1;
alter table taggings change context context VARBINARY(255);
alter table taggings change context context VARCHAR(255) character set utf8;

alter table tags change name name VARCHAR(255) character set latin1;
alter table tags change name name VARBINARY(255);
alter table tags change name name VARCHAR(255) character set utf8;


alter table users change email email VARCHAR(255) character set latin1;
alter table users change email email VARBINARY(255);
alter table users change email email VARCHAR(255) character set utf8;

alter table users change name name VARCHAR(255) character set latin1;
alter table users change name name VARBINARY(255);
alter table users change name name VARCHAR(255) character set utf8;

alter table users change bio bio TEXT character set latin1;
alter table users change bio bio BLOB;
alter table users change bio bio TEXT character set utf8;
