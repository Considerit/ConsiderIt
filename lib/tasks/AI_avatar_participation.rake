
require 'ruby_llm'




# open-ai compatible endpoint. 
# Locally I'm using LM Studio / Qwen3 14b
llm_endpoint = "http://localhost:1234/v1"
llm_api_key = "local" #ENV.fetch('OPENAI_API_KEY', nil)
llm_model = "qwen:qwen3-14b"


RubyLLM.configure do |config|
  config.openai_api_key = llm_api_key
  config.openai_api_base = llm_endpoint
end



# Note: RubyLLM chat object has persistant chat state. So for avatars,
#       we might experiment with maintaining a chat object per LLM for
#       memory persistence and personality / background animation. 
chat = RubyLLM.chat(
  model: llm_model, 
  provider: :openai, 
  assume_model_exists: true
)

response = chat.ask "You are an avatar representing Consider.it, a deliberation platform. Answer all questions from that perspective."
pp response.content
pp ""

response = chat.ask "Who do you serve? What is your purpose?"
pp response.content
pp ""

response = chat.ask "How can the humans who design and program you help you fill your purpose better?"
pp response.content
pp ""


create_test_avatar_forum("united-states")




task :animate_avatars => :environment do

  Subdomain.all.each do |subdomain|
    next if !subdomain.customizations

    customizations = subdomain.customizations
    avatar_conf = customizations["ai_participation"]

    next if !avatar_conf

  end

end






def create_test_avatar_forum(forum_name, force=false)

  user = User.where(:super_admin=>1).first

  subdomain = Subdomain.find_by_name(forum_name)
  if !subdomain
    new_subdomain = Subdomain.new name: forum_name
    roles = new_subdomain.user_roles
    roles['admin'].push "/user/#{user.id}"
    roles['visitor'].push "*"
    new_subdomain.roles = roles
    new_subdomain.created_by = user.id
    subdomain = new_subdomain
  end 


  if !subdomain.customizations || !customizations['ai_participation'] || force
    # initial customizations
    customizations = {
      "ai_participation": {
        "forum_prompt": "In this forum, avatars personifying important United States historical figures and texts deliberate about contemporary issues facing the United States.",
        "ai_facilitation": {
          "seed_initial_focus": true,
          "deliberation_phases": [
            {
              "name": "Novel Ideation",
              "generate_proposals": true,
              "generate_opinions": false,
              "proposal_prompt": "Generate proposals that are novel and conceptually distinct from existing ones. Avoid repetition or consensus-building in this phase.",
              "transition_criteria": {
                "max_duration_minutes": 30
              }
            },
            {
              "name": "Consensus Seeking",
              "generate_proposals": true,
              "generate_opinions": true,
              "proposal_prompt": "Synthesize earlier ideas and propose refinements likely to attract wider support. Consider tradeoffs identified in previous opinions.",
              "transition_criteria": {
                "max_duration_minutes": 30
              }
            }
          ] 
        }
      }
    }
    subdomain.customizations ||= {}
    subdomain.customizations.update customizations
    subdomain.save
  end

  if !subdomain.customizations["ai_participation"]["avatars"] && false
    subdomain.customizations["ai_participation"]["avatars"] = generate_avatars()
    subdomain.save
  end

end



def generate_avatars

  return nil

end