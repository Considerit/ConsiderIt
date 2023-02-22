task :supported_languages_to_active_record => :environment do 
  langs = ActiveRecord::Base.connection.execute("SELECT v FROM datastore where k='/translations'")
  langs.each do |r|
    supported = JSON.load(r[0])
    supported["available_languages"].each do |lang_code,name|
      if !Translations::SupportedLanguage.find_by_name(name)
        attrs = {
                  "name": name, 
                  "lang_code": lang_code
                }
        Translations::SupportedLanguage.create!(attrs)
        pp "Added language #{lang_code}"
      end
    end
  end
end

task :translations_to_active_record => :environment do
  subdomains = {}
  Subdomain.all.each do |s|
    subdomains[s.name] = 1
  end

  supported_languages = {}
  Translations::SupportedLanguage.all.each do |sl|
    supported_languages[sl.lang_code] = sl.name
  end

  def load_translations(lang_code, trans, subdomain_name=nil)
    pp "Loading #{trans.values.length} Translations for #{lang_code} #{subdomain_name}"

    if subdomain_name
      subdomain = Subdomain.find_by_name(subdomain_name)
    end

    trans.each do |string_id, vals|
      next if string_id == 'key'
      u = vals["u"]
      txt = vals["txt"]

      attrs = {
        "string_id": string_id,
        "translation": txt,
        "lang_code": lang_code,
        "accepted": true,
        "accepted_at": DateTime.now(),
        "origin_server": "US"
      }

      if u 
        attrs["user_id"] = u.split('/')[2]
      end

      if subdomain_name
        attrs["subdomain_id"] = subdomain.id
      end

      if Translations::Translation.where(:string_id => string_id, :user_id => attrs["user_id"], :lang_code => lang_code).count == 0
        Translations::Translation.create! attrs
      end

      proposals = vals["proposals"]

      if proposals && proposals.length > 0
        proposals.each do |proposal|
          txt = proposal["txt"]
          u = proposal["u"]
          if u 
            attrs["user_id"] = u.split('/')[2]
          end

          attrs["accepted"] = false
          attrs["accepted_at"] = nil
          attrs["user_id"] = u.split('/')[2]
          attrs["translation"] = txt

          if Translations::Translation.where(:string_id => string_id, :user_id => attrs["user_id"], :lang_code => lang_code).count == 0
            Translations::Translation.create! attrs
          end
        end
      end

    end
  
  end

  trans = ActiveRecord::Base.connection.execute("SELECT k,v FROM datastore")
  trans.each do |t|
    k = t[0]
    v = Oj.load t[1]

    parts = k.split('/')
    if parts.length >= 3
      if supported_languages.has_key?(parts[2]) && parts.length == 3
        load_translations(parts[2], v)
      elsif parts[2] == 'pseudo-en' || parts[3] == 'pseudo-en'
        # we'll automatically fill in pseudo-en elsewhere
      elsif subdomains.has_key?(parts[2])
        if parts.length != 4
          # junk
        else 
          load_translations(parts[3], v, parts[2])
        end
      else 
        # subdomain not found or junk
      end
    else
      # junk
    end
  end

end


task :migrate_translations => :environment do 

  def delete_translation(id)
    to_delete = Translations::Translation.where(:string_id => id)
    pp "  Deleting #{id} (#{to_delete.count})"
    to_delete.destroy_all
  end 

  def rename_translation(source, dest)
    to_rename = Translations::Translation.where(:string_id => source)
    pp "renamed #{source} to  #{dest} (#{to_rename.count})"
    to_rename.update_all(:string_id => dest)
  end

  delete_translation "engage.save_your_opinion.button"

  delete_translation "engage.header.Citizens' opinions"
  delete_translation "engage.header.Commitments"
  delete_translation "engage.header.PC's ratings"
  delete_translation "engage.header.Student responses"
  delete_translation "engage.header.Students' feedback"
  delete_translation "engage.header.Students' opinions"
  delete_translation "engage.header.Votes"
  delete_translation "engage.list_opinions_title.Citizens' opinions"
  delete_translation "engage.list_opinions_title.Commitments"
  delete_translation "engage.list_opinions_title.PC's ratings"
  delete_translation "engage.list_opinions_title.Student responses"
  delete_translation "engage.list_opinions_title.Students' feedback"
  delete_translation "engage.list_opinions_title.Students' opinions"
  delete_translation "engage.list_opinions_title.Votes"

  delete_translation "point_labels.Shade"
  delete_translation "point_labels.Love"

  rename_translation "engage.header.Opinions", "engage.list_opinions_title.Opinions"

  delete_translation "engage.header_your.Throw your --valences--"
  delete_translation "engage.header_top.Best --valences--"
  delete_translation "engage.header_other.Others' --valences--"
  delete_translation "engage.header_other.Others' {arguments}"

  delete_translation "point_labels.header_other.Others' --valences--"
  rename_translation "engage.header_your.Give your {arguments}", "point_labels.header_your.Give your {arguments}"
  rename_translation "engage.header_top.Top {arguments}", "point_labels.header_top.Top {arguments}"
  rename_translation "engage.header_your.{arguments}", "point_labels.header_your.{arguments}"
  rename_translation "engage.header_other.{arguments} observed", "point_labels.header_other.{arguments} observed"

  rename_translation "engage.slider_label.Agree", "sliders.pole.Agree"
  rename_translation "engage.slider_label.Disagree", "sliders.pole.Disagree"
  rename_translation "engage.slider_label.Important", "sliders.pole.Important"
  rename_translation "engage.slider_label.Unimportant", "sliders.pole.Unimportant"
  rename_translation "engage.slider_label.High Priority", "sliders.pole.High Priority"
  rename_translation "engage.slider_label.Low Priority", "sliders.pole.Low Priority"
  rename_translation "engage.slider_label.Support", "sliders.pole.Support"
  rename_translation "engage.slider_label.Oppose", "sliders.pole.Oppose"
  delete_translation "engage.slider_label.Absolutely"
  delete_translation "engage.slider_label.Accept"
  delete_translation "engage.slider_label.Advance"
  delete_translation "engage.slider_label.Big impact!"
  delete_translation "engage.slider_label.Commitment"
  delete_translation "engage.slider_label.Committed"
  delete_translation "engage.slider_label.Concern"
  delete_translation "engage.slider_label.Confused"
  delete_translation "engage.slider_label.Definitely no"
  delete_translation "engage.slider_label.Definitely yes"
  delete_translation "engage.slider_label.Effective"
  delete_translation "engage.slider_label.Hellz No!"
  delete_translation "engage.slider_label.In Bush"
  delete_translation "engage.slider_label.In Hand"
  delete_translation "engage.slider_label.Ineffective"
  delete_translation "engage.slider_label.Interested"
  delete_translation "engage.slider_label.Less Important"
  delete_translation "engage.slider_label.Moldy"
  delete_translation "engage.slider_label.More Important"
  delete_translation "engage.slider_label.No"
  delete_translation "engage.slider_label.No Way"
  delete_translation "engage.slider_label.No impact on me"
  delete_translation "engage.slider_label.Not at all"
  delete_translation "engage.slider_label.Not ready"
  delete_translation "engage.slider_label.Objection"
  delete_translation "engage.slider_label.Ready"
  delete_translation "engage.slider_label.Reject"
  delete_translation "engage.slider_label.Ripe"
  delete_translation "engage.slider_label.Strong"
  delete_translation "engage.slider_label.Uncommitted"
  delete_translation "engage.slider_label.Understand"
  delete_translation "engage.slider_label.Unimportant"
  delete_translation "engage.slider_label.Uninterested"
  delete_translation "engage.slider_label.Weak"
  delete_translation "engage.slider_label.YAAAAAAS"
  delete_translation "engage.slider_label.Yes"
  delete_translation "engage.slider_label.Yes indeed!"

  delete_translation "engage.proposal_cluster_placeholder"

  rename_translation "engage.slider_feedback.agree_disagree.Firmly-oppose", "sliders.feedback.Firmly"
  rename_translation "engage.slider_feedback.agree_disagree.Fully-oppose", "sliders.feedback.Fully"
  rename_translation "engage.slider_feedback.agree_disagree.Slightly-oppose", "sliders.feedback.Slightly"

  delete_translation "engage.slider_feedback.agree_disagree.Firmly-support"
  delete_translation "engage.slider_feedback.agree_disagree.Fully-support"
  delete_translation "engage.slider_feedback.agree_disagree.Slightly-support"

  delete_translation "engage.slider_feedback.support_oppose.Firmly-oppose"
  delete_translation "engage.slider_feedback.support_oppose.Fully-oppose"
  delete_translation "engage.slider_feedback.support_oppose.Slightly-oppose"

  delete_translation "engage.slider_feedback.support_oppose.Firmly-support"
  delete_translation "engage.slider_feedback.support_oppose.Fully-support"
  delete_translation "engage.slider_feedback.support_oppose.Slightly-support"


  rename_translation "engage.slider_feedback.default.neutral", "sliders.feedback.neutral"
  delete_translation "engage.slider_feedback.agree_disagree.neutral"
  delete_translation "engage.slider_feedback.support_oppose.neutral"

  rename_translation "engage.slider_feedback.neutral", "sliders.feedback-short.neutral"

  rename_translation "engage.opinion_slider.directions", "sliders.instructions-with-proposal"
  rename_translation "engage.slider.instructions", "sliders.instructions"

  rename_translation "engage.slide_prompt", "sliders.slide_prompt"
  rename_translation "engage.slide_feedback_short", "sliders.slide_feedback_short"

  delete_translation "engage.slider_label."


  delete_translation "auth.reset_password.new_pass.placeholder"
  delete_translation "auth.login.password.placeholder"
  delete_translation "auth.create.full_name.placeholder"
  delete_translation "auth.code_entry.placeholder"
  delete_translation "auth.update_profile.heading"
  delete_translation "engage.permissions.verify_account_to_comment"
  delete_translation "engage.permissions.login_to_comment"
  delete_translation "email_notifications.digests_purpose"

  for event in ['new_comment:point_authored', 'new_comment:point_engaged', 'new_comment', 'new_opinion', 'new_point', 'new_point:proposal_authored']
    delete_translation "email_notifications.event.#{event}"
  end

  rename_translation "banner.save_changes_button", "shared.save_changes_button"
  rename_translation "engage.cancel_button", "shared.cancel_button"
  rename_translation "auth.sign_up", "shared.auth.sign_up"
  rename_translation "auth.log_in", "shared.auth.log_in"


  delete_translation "engage.opinion_filter.label"
  delete_translation "engage.proposal_score_summary.explanation"
  delete_translation "engage.proposal_score_summary.explanation"
  delete_translation "engage.re-sort_list"

  delete_translation "engage.save_opinion_button"
  delete_translation "engage.proposal_meta_data"

  delete_translation "footer.back_to_top_button"
  delete_translation "banner.background_css_is_light.label"
  delete_translation "banner.change_background_label"

  delete_translation "engage.point_authoring.tip_review"

  # delete_translation "engage.navigation_helper_current_location"

  delete_translation "engage.add_your_own"

  delete_translation "translation"

  delete_translation "\"proposal_list. \""

  to_delete = Translations::Translation.where("string_id like 'engage.add_new_%' AND string_id != 'engage.add_new_proposal_to_list' AND subdomain_id is null")
  pp "  Deleting bad response labels (#{to_delete.count})"
  to_delete.destroy_all

  to_delete = Translations::Translation.where("string_id like 'engage.opinion_header_results_%' AND subdomain_id is null")
  pp "  Deleting bad opinion headers (#{to_delete.count})"
  to_delete.destroy_all

  to_delete = Translations::Translation.where("string_id like 'homepage_tab.%' AND string_id != 'homepage_tab.Show all' AND string_id != 'homepage_tab.add_more' AND string_id != 'homepage_tab.enable' AND string_id != 'homepage_tab.disable_confirmation' AND string_id != 'homepage_tab.confirm-tab-deletion' AND subdomain_id is null")
  pp "  Deleting bad tabs (#{to_delete.count})"
  to_delete.destroy_all

  to_delete = Translations::Translation.where("string_id like 'opinion_filter.name.%' AND subdomain_id is null")
  pp "  Deleting bad opinion filter names (#{to_delete.count})"
  to_delete.destroy_all

  to_delete = Translations::Translation.where("string_id like 'point_labels.header_%' AND subdomain_id is null")
  pp "  Deleting bad point_labels (#{to_delete.count})"
  to_delete.destroy_all

  to_delete = Translations::Translation.where("string_id like 'proposal_list.%' AND subdomain_id is null")
  pp "  Deleting bad proposal_list (#{to_delete.count})"
  to_delete.destroy_all

  ActiveRecord::Base.connection.execute("update language_translations set translation=REPLACE(translation,'[object Object]', '\"{question}\"') where string_id='auth.validation.invalid_answer' AND translation like '%[object Object]%'")

  rename_translation "homepage_tab.Show all", "homepage_tab.name.Show all"


end