require Rails.root.join('@server', 'translations')



task :migrate_translations => :environment do 

  $to_delete = {}
  def delete_translation(id)
    $to_delete[id] = 1
  end 

  $to_rename = {}
  def rename_translation(source, dest)
    $to_rename[source] = dest
  end


  def sync_keys_with_english
    base_translations = get_translations '/translations'

    en_dict = get_translations "/translations/en"

    base_translations["available_languages"].each do |langcode, lang| 
      next if langcode == 'en'
      pp "",""
      pp "syncing #{lang} (#{langcode}) with english"
      pp ""

      lang_key = "/translations/#{langcode}"
      trans = get_translations lang_key

      deleted = false 
      trans.each do |key, ___|
        if !en_dict.has_key?(key)
          pp "#{lang} has #{key} that en doesn't"
          trans.delete(key)
          deleted = true 
        end
      end

      if deleted 
        update_translations lang_key, trans
      end

    end 

  end

  def execute_translation_migration
    base_translations = get_translations '/translations'
    base_translations["available_languages"].each do |langcode, lang| 
      pp "",""
      pp "Migrating #{lang} (#{langcode})"
      pp ""


      lang_key = "/translations/#{langcode}"
      trans = get_translations lang_key

      $to_rename.each do |source, dest|
        if trans.has_key?(source) && !trans.has_key?(dest)
          pp "  Rename #{source} to #{dest}", trans[source]
          trans[dest] = trans.delete source
          pp "renamed", trans[source], trans[dest]
        end 
      end 

      $to_delete.each do |id, __|
        if trans.has_key?(id)
          pp "  Deleting #{id}", trans[id]
          trans.delete(id)

          pp "  Deleted", trans[id]
        end
      end 

      update_translations lang_key, trans

    end

  end 


  delete_translation "engage.save_your_opinion.button"

  delete_translation "engage.header.Citizens' opinions"
  delete_translation "engage.header.Commitments"
  delete_translation "engage.header.PC's ratings"
  delete_translation "engage.header.Student responses"
  delete_translation "engage.header.Students' feedback"
  delete_translation "engage.header.Students' opinions"
  delete_translation "engage.header.Votes"
  rename_translation "engage.header.Opinions", "engage.list_opinions_title.Opinions"

  delete_translation "engage.header_your.Throw your --valences--"
  delete_translation "engage.header_top.Best --valences--"
  delete_translation "engage.header_other.Others' --valences--"
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

  sync_keys_with_english
  execute_translation_migration
end