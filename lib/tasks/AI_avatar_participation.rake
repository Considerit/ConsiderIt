
require 'ruby_llm'


require 'logger'

LOG_PATH = Rails.root.join("log", "ruby_llm.log")
LLMLogger = Logger.new(LOG_PATH, 'monthly')
LLMLogger.level = Logger::DEBUG

# Monkey-patch to write to stdout tood
LLMLogger.define_singleton_method(:add) do |severity, message = nil, progname = nil, &block|
  STDOUT.puts(message || block&.call || progname)
  super(severity, message, progname, &block)
end




# Note: RubyLLM chat objects have persistant chat state. So for avatars,
#       we might experiment with maintaining a chat object per LLM for
#       memory persistence and personality / background animation. 


# open-ai compatible endpoint. 
# Locally I'm using LM Studio / Qwen3 14b
use_GWDG = false

if use_GWDG
  llm_api_key = APP_CONFIG[:GWDG][:access]
  llm_endpoint = "https://llm.hrz.uni-giessen.de/api/"
  $llm_model = "deepseek-r1-distill-llama-70b"
  $json_extraction_model = 'qwq-32b' 
  $llm_provider = :openai
  RubyLLM.configure do |config|
    config.openai_api_key = llm_api_key
    config.openai_api_base = llm_endpoint
    config.request_timeout = 560  

    config.logger = LLMLogger
  end

else
  llm_endpoint = "http://localhost:1234/v1"
  llm_api_key = "local-not-used" #ENV.fetch('OPENAI_API_KEY', nil)

  $llm_model = "qwen:qwen3-14b"
  $json_extraction_model = "qwen:qwen3-14b" # 'deepseek:deepseek-r1-0528-qwen3-8b' # 
  $llm_provider = :ollama # :open("path/or/url/or/pipe", "w") { |io|  }nai

  RubyLLM.configure do |config|
    # config.openai_api_key = llm_api_key
    # config.openai_api_base = llm_endpoint
    config.ollama_api_base = llm_endpoint
    config.request_timeout = 560  
    config.logger = LLMLogger

  end

end



task :animate_avatars => :environment do

  create_test_avatar_forum()

  ai_runner_success_file = Rails.root.join('tmp', 'ai_participation_runner_success')

  success_times = if File.exist?(ai_runner_success_file)
                    JSON.parse(File.read(ai_runner_success_file))
                  else
                    {}
                  end


  Subdomain.all.each do |forum|
    next if !forum.customizations
    next if forum.name != 'united-states2'

    customizations = forum.customizations
    avatar_conf = customizations["ai_participation"]

    next if !avatar_conf

    begin 
      last_success_time = if success_times.has_key?(forum.name)
                            Time.parse(success_times[forum.name])
                          else
                            1.week.ago
                          end

      facilitate_dialogue(forum, last_successful_run=last_success_time)

      success_times[forum.name] = Time.now.utc.iso8601
      File.write(ai_runner_success_file, JSON.pretty_generate(success_times))
    rescue => err
      LLMLogger.error "**** Error occurred running facilator for #{forum.name}: #{err.message}"
      LLMLogger.debug err.backtrace.join("\n")
    end
  end
end


###########
# Main facilitation event loop for AI participation
def facilitate_dialogue(forum, last_successful_run)

  ai_config = forum.customizations['ai_participation']


  chat = RubyLLM.chat(
    model: $llm_model, 
    provider:  $llm_provider,
    assume_model_exists: true
  )

  # chat.with_instructions(
  #   "You are helping to facilitate a Consider.it deliberative forum. #{ai_config["forum_prompt"]}"
  # )

  prompts = get_all_considerit_prompts(forum, include_archived=false)
  pp prompts
  if prompts.length == 0
    # create a meta-prompt by the facilitating avatar (TODO)
    user = User.where(:super_admin=>1).first
    to_import = []

    if get_all_considerit_prompts(forum, include_archived=true).length > 0
      to_import.push "[What should we focus on next?]{\"list_description\": \"Each answer should be an open-ended question that we could pose to the rest of the group for ideation.\", \"list_item_name\": \"Focus\", \"slider_pole_labels\": {\"oppose\": \"lower priority\", \"support\": \"higher priority\"}}"
    else # first prompt
      first_prompt = ai_config.fetch("ai_facilitation", {}).fetch("seed_initial_focus", "What open-ended question should we focus on first?")
      to_import.push "[#{first_prompt}]{\"list_description\": \"\", \"list_item_name\": \"Focus\", \"slider_pole_labels\": {\"oppose\": \"lower priority\", \"support\": \"higher priority\"}}"
    end 


    forum.import_from_argdown to_import, user
    prompts = get_all_considerit_prompts(forum, include_archived=false)

  end 

  current_prompt = prompts[-1]
  current_prompt_id = current_prompt[:key].split('/')[-1]


  ai_config["avatars"].each do |k,v|
    pp v["name"]
    user = get_and_create_avatar_user(forum, v, generate_avatar_pic=true)
  end

  while forum.proposals.where(cluster: current_prompt_id).length < 12
    # nominate new proposer
    avatar = ai_config["avatars"].values.sample
    begin
      propose(forum, current_prompt, avatar)
    rescue
      pp "failed to create proposal"
    end
  end 

  while rand >= 0.25 # TODO: stopping condition

    proposal = forum.proposals.where(cluster: current_prompt_id).sample

    avatar_count = ai_config["avatars"].values.length

    while proposal.opinions.published.count < avatar_count / 8

      avatar = ai_config["avatars"].values.sample

      if !avatar["user_id"] || proposal.opinions.published.where(:user_id => avatar["user_id"]).count == 0
        begin 
          opine(forum, current_prompt[:data], proposal, avatar)
        rescue
          pp "failed to create opinion"
        end 
      end
    end
  end


  proposal_count = forum.proposals.where(cluster: current_prompt_id).count
  ai_config["avatars"].each do |avatar| #while rand >= 0.05 # TODO: stopping condition   

    opinions = 0
    forum.proposals.where(cluster: current_prompt_id).each do |p|

      if p.opinions.where(:user_id=>avatar["user_id"]).count > 0
        opinions += 1
      end
    end

    if opinions < proposal_count
      prioritize_proposals(forum, current_prompt, avatar)
    end
  end


end



###########################
# Deliberation capabilities


def propose(forum, considerit_prompt, avatar)

  ai_config = forum.customizations['ai_participation']

  chat = RubyLLM.chat(
    model: $llm_model, 
    provider:  $llm_provider,
    assume_model_exists: true
  )

  # chat.with_instructions(get_embodiment_instructions(forum, avatar))

  prompt_id = considerit_prompt[:key].split('/')[-1]

  existing = []
  existing_proposals = Proposal.where(cluster: prompt_id).each do |p|
    existing.push(p.name)
  end


  propose_json_schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "Proposal",
    "type": "object",
    "properties": {
      "name": {
        "type": "string",
        "description": "The succinct title of this proposal"
      },
      "description": {
        "type": "string",
        "description": "A more extended description of this proposal"
      }
    },
    "required": ["name", "description"],
    "additionalProperties": false
  }

  propose_prompt = "Please give one answer to this prompt: \"#{considerit_prompt[:data]["list_title"]}  #{considerit_prompt[:data].fetch("list_description", "")}\"   Your answer should give a name and a description. Strive for a novel proposal that has not already been contributed. The name should be direct and simple;  Don't make the name clever, academic, or sweeping (e.g. do not use colonic titles!)."
  pp propose_prompt

  response = chat.ask(get_embodiment_instructions(forum, avatar) + " " + propose_prompt + " Proposals that have already been added are: #{JSON.dump(existing)}")

  proposal = extract_structure_from_response($json_extraction_model, $llm_provider, propose_prompt, response, propose_json_schema)

  pp "***** GOT PROPOSAL", proposal

  user = get_and_create_avatar_user(forum, avatar, generate_avatar_pic=true)

  params = {
      'subdomain_id': forum.id,
      'user_id': user.id,
      'name': proposal["name"].split(": ")[-1],
      'description': proposal["description"],
      'cluster': prompt_id,
      'published': true
    }
  proposal = Proposal.create!(params)

  # proposer should add first opinion
  opine(forum, considerit_prompt, proposal, avatar)

  Proposal.clear_cache(forum)



  return proposal

end


# def opine(forum, considerit_prompt, proposal, avatar)

#   ai_config = forum.customizations['ai_participation']

#   chat = RubyLLM.chat(
#     model: $llm_model, 
#     provider:  $llm_provider,
#     assume_model_exists: true
#   )

#   # chat.with_instructions(get_embodiment_instructions(forum, avatar))


#   existing = []
#   existing_pros_and_cons = proposal.points.published.each do |p|
#     existing.push({
#       id: p.id, 
#       type: p.is_pro ? "Pro" : "Con",
#       point: p.nutshell
#     })
#   end

#   embodiment_instructions = get_embodiment_instructions(forum, avatar)
#   proposal_desc = "You are evaluating the following proposal: <proposal>#{proposal.name}: #{proposal.description}</proposal>. This proposal was made in response to the following prompt: <prompt>\"#{considerit_prompt["list_title"]}  #{considerit_prompt.fetch("list_description", "")}\"</prompt>"

#   interests = "First, formulate your specific interests with respect to this proposal. "
#   pros_and_cons = "Then assess the pros and cons of this proposal. The pros and cons that other participants have already identified are listed below (if any). You are to identify up to four pros and/or cons representing the most important factors for you as you consider this proposal. Each pro or con point can be either (1) a new pro or con point that you author yourself or (2) a pro or con point that some other participant already added (listed below). Don't author a pro or con point if someone else has already contributed a very similar point; instead, mark down the pro or con point with its ID. But also, don't be afraid to add a new one if there's something important to your interests about this proposal that has not yet been addressed! You do not need to balance out your pros and cons."
#   spectrum = "Finally, you will rate the proposal on a continuous spectrum of support ([-1,1]), with the -1 pole labeled #{} and the +1 pole labeled #{}. The center of the spectrum around 0 signals either (1) apathy about the proposal or (2) there are strong tradeoffs that roughly balance out. "
#   wrap_up = "Please make sure to output a spectrum and the pro/con tradeoffs that are most salient to you as you make a decision. "

#   prompt = "#{embodiment_instructions} #{proposal_desc} #{interests} #{pros_and_cons} #{spectrum} #{wrap_up}"

#   pp prompt
#   response = chat.ask(prompt + " Existing pros and cons: #{JSON.dump(existing)}")
#   pp response.content


#   opinion_schema = {
#     "$schema": "https://json-schema.org/draft/2020-12/schema",
#     "title": "EvaluationResult",
#     "type": "object",
#     "properties": {
#       "score": {
#         "type": "number",
#         "minimum": -1.0,
#         "maximum": 1.0,
#         "description": "A continuous value in the range [-1, 1]"
#       },
#       "new_pro_con_points": {
#         "type": "array",
#         "items": {
#           "type": "object",
#           "properties": {
#             "type": {
#               "type": "string",
#               "description": "Either 'pro' or 'con'"
#             },
#             "point": {
#               "type": "string",
#               "description": "A summary of the pro or con"
#             },
#             "description": {
#               "type": "string",
#               "description": "Additional description (optional)"
#             }
#           },
#           "required": ["type", "point"],
#           "additionalProperties": false
#         }
#       },
#       "included_pro_con_points": {
#         "type": "array",
#         "items": {
#           "type": "object",
#           "properties": {
#             "id": {
#               "type": "integer",
#               "description": "The ID of the included pro/con point"
#             }
#           },
#           "required": ["id"],
#           "additionalProperties": false
#         }
#       },
#       "interests": {
#         "type": "string",
#         "description": "The identified interests"
#       }
#     },
#     "required": ["score"],
#     "additionalProperties": false
#   }


#   extractor = ResponseExtractor.new($json_extraction_model, $llm_provider)  
#   opinion = extractor.extract_structure_from_response(prompt, response, opinion_schema)
#   pp opinion

#   user = get_and_create_avatar_user(forum, avatar, generate_avatar_pic=true)

#   o = Opinion.get_or_make(proposal, user)
#   o.stance = opinion["score"].to_f
#   o.explanation = opinion.fetch("interests")
#   pp "  ** Took stance #{o.stance}"

#   o.save


#   begin 
#     new_points = opinion.fetch("new_pro_con_points", [])
#     new_points.each do |new_pt|
#       point = proposal.points.where(:nutshell => new_pt["point"]).first
#       if !point
#         point = Point.create!({
#           subdomain_id: forum.id,
#           nutshell: new_pt["point"],
#           text: new_pt.fetch("description", nil),
#           is_pro: new_pt["type"] == 'pro',
#           proposal_id: proposal.id,
#           user_id: user.id,
#           comment_count: 0,
#           published: true
#         })
#         point.publish
#         pp "  ** Creating point #{point.nutshell}"
#       end
#       o.include(point, forum)    
#     end
#   rescue => err
#     pp "Failed to create new points", err
#   end

#   begin
#     included_points = opinion.fetch("included_pro_con_points", [])
#     included_points.each do |pt|
#       pp pt
#       point = proposal.points.where(:id => pt['id']).first
#       if point
#         pp "  ** Including point #{point.id}"
#         o.include(point, forum)    
#       end
#     end
#   rescue => err
#     pp "Failed to include points", err

#   end




# end



def opine(forum, considerit_prompt, proposal, avatar)

  ai_config = forum.customizations['ai_participation']

  chat = RubyLLM.chat(
    model: $llm_model, 
    provider:  $llm_provider,
    assume_model_exists: true
  )

  # chat.with_instructions(get_embodiment_instructions(forum, avatar))


  existing = []
  existing_pros_and_cons = proposal.points.published.each do |p|
    existing.push({
      id: p.id, 
      type: p.is_pro ? "Pro" : "Con",
      point: p.nutshell
    })
  end

  poles = get_slider_poles(forum, considerit_prompt)

  embodiment_instructions = get_embodiment_instructions(forum, avatar)
  proposal_desc = "You are evaluating the following proposal: <proposal>#{proposal.name}: #{proposal.description}</proposal>. This proposal was made in response to the following prompt: <prompt>\"#{considerit_prompt["list_title"]}  #{considerit_prompt.fetch("list_description", "")}\"</prompt>"

  interests = "First, formulate your specific interests with respect to this proposal. "
  pros_and_cons = "Then assess the pros and cons of this proposal. You are to identify up to four pros and/or cons representing the most important factors for you as you consider this proposal. You do not need to balance your pros and cons: you can have 4 pros if you want, for example. Or just one con and no pros."
  wrap_up = "Please make sure to output up to four pro/con tradeoffs that are most salient to you as you make a decision. "

  prompt = "#{embodiment_instructions} #{proposal_desc} #{interests} #{pros_and_cons} #{wrap_up}"

  response = chat.ask(prompt)
  intermediate = response.content.sub(/<think>.*?<\/think>/m, '').strip


  embodiment_instructions = get_embodiment_instructions(forum, avatar)
  proposal_desc = "You are evaluating the following proposal: <proposal>#{proposal.name}: #{proposal.description}</proposal>. This proposal was made in response to the following prompt: <prompt>\"#{considerit_prompt["list_title"]}  #{considerit_prompt.fetch("list_description", "")}\"</prompt>"

  existing_deliberation = "You have already articulated your interests and authored some pro and con statements: <interests and authored pros+cons>#{intermediate}</interests and authored pros+cons>. First, restate your interests. "

  pros_and_cons = "Next, I'm going to show you the pros and/or cons that *other participants* have already contributed. We do not want duplicate pros and cons. So I want you to (1) compare each of the pros and/or cons you authored already and restate only the ones that do not significantly overlap with a pro or con point that someone else contributed; (2) identify up to four pro and/or con points other people have contributed that best represent to your interests (for each of these, note the point's ID)."

  # interests = "First, formulate your specific interests with respect to this proposal. "
  # pros_and_cons = "Then assess the pros and cons of this proposal. The pros and cons that other participants have already identified are listed below (if any). You are to identify up to four pros and/or cons representing the most important factors for you as you consider this proposal. Each pro or con point can be either (1) a new pro or con point that you author yourself or (2) a pro or con point that some other participant already added (listed below). Don't author a pro or con point if someone else has already contributed a very similar point; instead, mark down the pro or con point with its ID. But also, don't be afraid to add a new one if there's something important to your interests about this proposal that has not yet been addressed! You do not need to balance out your pros and cons."
  spectrum = "Finally, you will rate the proposal on a continuous spectrum of support ([-1,1]), with the -1 pole labeled #{poles['oppose']} and the +1 pole labeled #{poles['support']}. The center of the spectrum around 0 signals either (1) apathy about the proposal or (2) there are strong tradeoffs that roughly balance out. "
  wrap_up = "To summarize, please make sure to output an evaluation of this proposal that includes your interests, a score on the spectrum of support, your original pro and/or con points (if any), and the pro and/or con points that others have contributed that speak for you. "

  prompt = "#{embodiment_instructions} #{proposal_desc} #{existing_deliberation} #{pros_and_cons} #{spectrum} #{wrap_up}"

  response = chat.ask(prompt + " Existing pros and cons: <points contributed by others>#{JSON.dump(existing)}</points contributed by others>")


  opinion_schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "EvaluationResult",
    "type": "object",
    "properties": {
      "score": {
        "type": "number",
        "minimum": -1.0,
        "maximum": 1.0,
        "description": "A continuous value in the range [-1, 1]"
      },
      "new_pro_con_points": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": {
              "type": "string",
              "description": "Either 'pro' or 'con'"
            },
            "point": {
              "type": "string",
              "description": "A summary of the pro or con"
            },
            "description": {
              "type": "string",
              "description": "Additional description (optional)"
            }
          },
          "required": ["type", "point"],
          "additionalProperties": false
        }
      },
      "included_pro_con_points": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": {
              "type": "integer",
              "description": "The ID of the included pro/con point"
            }
          },
          "required": ["id"],
          "additionalProperties": false
        }
      },
      "interests": {
        "type": "string",
        "description": "The identified interests"
      }
    },
    "required": ["score"],
    "additionalProperties": false
  }


  opinion = extract_structure_from_response($json_extraction_model, $llm_provider, prompt, response, opinion_schema)
  pp opinion

  user = get_and_create_avatar_user(forum, avatar, generate_avatar_pic=true)

  o = Opinion.get_or_make(proposal, user)
  o.stance = opinion["score"].to_f
  o.explanation = opinion.fetch("interests")
  pp "  ** Took stance #{o.stance}"

  o.save


  begin 
    new_points = opinion.fetch("new_pro_con_points", [])
    new_points.each do |new_pt|
      point = proposal.points.where(:nutshell => new_pt["point"]).first
      if !point
        point = Point.create!({
          subdomain_id: forum.id,
          nutshell: new_pt["point"],
          text: new_pt.fetch("description", nil),
          is_pro: new_pt["type"] == 'pro',
          proposal_id: proposal.id,
          user_id: user.id,
          comment_count: 0,
          published: true
        })
        point.publish
        pp "  ** Creating point #{point.nutshell}"
      end
      o.include(point, forum)    
    end
  rescue => err
    pp "Failed to create new points", err
  end

  begin
    included_points = opinion.fetch("included_pro_con_points", [])
    included_points.each do |pt|
      pp pt
      point = proposal.points.where(:id => pt['id']).first
      if point
        pp "  ** Including point #{point.id}"
        o.include(point, forum)    
      end
    end
  rescue => err
    pp "Failed to include points", err

  end




end








def get_slider_poles(forum, considerit_prompt)

  return considerit_prompt.fetch("slider_pole_labels", forum.customizations.fetch("slider_pole_labels", {"oppose": "strongly disagree", "support": "strongly agree"}))
  
end


def prioritize_proposals(forum, considerit_prompt, avatar)

  ai_config = forum.customizations['ai_participation']

  prompt_id = considerit_prompt[:key].split('/')[-1]

  proposals = forum.proposals.where(cluster: prompt_id)
  
  poles = get_slider_poles(forum, considerit_prompt)

  chat = RubyLLM.chat(
    model: $llm_model, 
    provider:  $llm_provider,
    assume_model_exists: true
  )

  # chat.with_instructions(get_embodiment_instructions(forum, avatar))


  existing = []
  proposals.each do |p|
    existing.push({
      id: p.id, 
      title: p.name,
      description: p.description
    })
  end


  embodiment_instructions = get_embodiment_instructions(forum, avatar)
  proposal_desc = "The forum host has asked the group to propose answers to the following prompt: <prompt>\"#{considerit_prompt["list_title"]}  #{considerit_prompt.fetch("list_description", "")}\"</prompt>. Your task is to evaluate all of the proposals that have responded to this prompt thus far. The proposals will be listed below."

  interests = "Your process is the following: First, formulate your specific interests in the context of the prompt and the set of proposals."
  spectrum = "Second, you will prioritize each proposal on a continuous spectrum of support ([-1,1]), with the -1 pole labeled #{poles['oppose']} and the +1 pole labeled #{poles['support']}. The center of the spectrum around 0 signals either (1) apathy about the proposal or (2) there are strong tradeoffs that roughly balance out. Please make sure that your rating is paired with identifying information about the proposal (in particular its ID). You do not need to explain your reasoning."

  prompt = "#{embodiment_instructions} #{proposal_desc} #{interests} #{spectrum}"

  pp prompt
  response = chat.ask(prompt + " The proposals to evaluate: #{JSON.dump(existing)}")
  pp response.content


  opinions_schema = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "ProposalScores",
    "type": "object",
    "properties": {
      "scores": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": {
              "type": "integer",
              "description": "The ID of the proposal"
            },
            "score": {
              "type": "number",
              "minimum": -1.0,
              "maximum": 1.0,
              "description": "A continuous value between -1 and 1"
            }
          },
          "required": ["id", "score"],
          "additionalProperties": false
        }
      },
      "interests": {
        "type": "string",
        "description": "The identified interests"
      }
    },
    "required": ["scores", "interests"],
    "additionalProperties": false
  }


  opinions = extract_structure_from_response($json_extraction_model, $llm_provider, prompt, response, opinions_schema)

  pp opinions

  user = get_and_create_avatar_user(forum, avatar, generate_avatar_pic=true)


  opinions["scores"].each do |opinion|
    proposal = forum.proposals.find(opinion["id"])
    o = Opinion.get_or_make(proposal, user)
    o.stance = opinion["score"].to_f
    o.explanation = opinions.fetch("interests")
    pp "  ** Took stance #{o.stance} on #{proposal.name}"
    o.save
  end


  Proposal.clear_cache(forum)

end







def get_embodiment_instructions(forum, avatar)
  ai_config = forum.customizations["ai_participation"]

  prompt = "You are participating in a deliberative forum. #{ai_config["forum_prompt"]}. You are speaking as \"#{avatar["name"]}\", in first person voice. #{avatar["embodiment_prompt"]}. Speak in the first person. You've been included in this forum because: #{avatar["nomination"]}"
  return prompt
end




#######################################
# Populating a forum with Avatars

def generate_avatars(forum, ai_config)

  avatar_nominations_json = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "AvatarList",
    "type": "object",
    "properties": {
      "avatars": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "The name of the avatar"
            },  
            "embodiment_prompt": {
              "type": "string",
              "description": "A prompt that can be used to instruct an LLM to personify this avatar"
            },
            "nomination_reason": {
              "type": "string",
              "description": "The reason why this avatar has been nominated"
            }
          },
          "required": ["name", "description", "nomination_reason"],
          "additionalProperties": false
        }
      }
    },
    "required": ["avatars"],
    "additionalProperties": false
  } 

  chat = RubyLLM.chat(
    model: $llm_model, 
    provider:  $llm_provider,
    assume_model_exists: true
  )

  avatars_gen = "We're creating a Consider.it deliberative forum that involves some AI participants. #{ai_config["forum_prompt"]}. #{ai_config["avatars_prompt"]}. Do not repeat any avatar. After thinking about it, please give each unique proposed avatar (1) a name, (2) a reason why it has been nominated, and (3) a prompt that can be used to instruct an LLM to personify this avatar (include the name, some background, an orientation to the topic, and suggestions for tone and attitude)."
  response = chat.ask(avatars_gen)

  nominated_avatars = extract_structure_from_response($json_extraction_model, $llm_provider, avatars_gen, response, avatar_nominations_json)

  pp nominated_avatars

  avatars_config = {}
  nominated_avatars["avatars"].each do |candidate|
    avatars_config[candidate["name"]] = {
      "name": candidate["name"],
      "embodiment_prompt": candidate["embodiment_prompt"],
      "nomination": candidate["nomination_reason"]
    }
  end

  return avatars_config

end


###################################
# A test forum for development

def create_test_avatar_forum(force=false)
  forum_name = "united-states2"
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


  if !subdomain.customizations || !subdomain.customizations['ai_participation'] || force
    # initial customizations
    customizations = {
      "ai_participation": {
        "forum_prompt": "In this forum, avatars personifying important figures and texts from the history of the United States deliberate about contemporary issues facing the United States.",
        "avatars_prompt": "Generate approximately 50 representative avatars for this forum. About 40 of these should be historical figures that span the political and cultural gamut, and about 10 of them should be important texts or key American concepts.",
        "ai_facilitation": {
          "seed_initial_focus": "What are the biggest problems facing the United States today? A good proposed problem describes a specific, actionable problem. It does not have to propose mechanisms to solve the problem. At a later point, we will ideate about how to address some of the more salient problems.",
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

  if !subdomain.customizations["ai_participation"]["avatars"] 
    subdomain.customizations["ai_participation"]["avatars"] = generate_avatars(subdomain, subdomain.customizations["ai_participation"])
    subdomain.save
  end

  if subdomain.customizations["ai_participation"]["avatars"] 
    subdomain.customizations["ai_participation"]["avatars"].each do |k, avatar|
      if !avatar["user_id"]
        get_and_create_avatar_user(subdomain, avatar, generate_avatar_pic=true)
      end
    end
  end

end




############################
# Constraining LLMs to produce structured output can reduce their quality. Instead, we generate natural language
# responses, and then use another LLM call that takes a natural language response and structures it into JSON. 
# 
# ResponseExtractor facilitates the extraction of JSON from natural language responses to a prompt. 
#
require 'json-schema'



def extract_structure_from_response(model, provider, original_prompt, response, schema)
  max_retries = 3

  nl = preprocess_natural_language_response(response)

  instructions = "You extract data given in natural language (and sometimes structured data) and formulate it according to a JSON schema the prompter gives to you, maintaining as much of the original phrasing as possible."

  parse_proposals_query = <<~PROMPT
    Here is a response to the prompt <prompt>#{original_prompt}<end prompt>: <begin response>#{nl}<end response> While maintaining as much of the original response text as possible, I would like you to extract data from this response into JSON that follows this JSON schema: #{JSON.dump(schema)}. Your response should only include the JSON. Don't include any markup (like astericks). Note that the provided JSON is a schema that *describes* the desired JSON output, but is not the output format itself.   
  PROMPT

  attempt = 0
  begin 
    json_parser = RubyLLM.chat(
      model: model,
      provider: provider,
      assume_model_exists: true
    )

    llm_response = json_parser.ask(instructions + " " + parse_proposals_query)
    parsed = try_parse_json(llm_response.content)

    if parsed && valid_against_schema?(parsed, schema)
      return parsed
    end

  rescue => err
    pp "**** FAILED #{attempt}"
    pp "Failed to extract structure", err.message

    attempt += 1
    if attempt <= max_retries
      retry
    end
  end

  raise "Failed to extract valid structured data from response after #{max_retries + 1} attempts"
end

private

def preprocess_natural_language_response(response)
  remove_reasoning_block(response.content)
end

def try_parse_json(text)
  JSON.load(remove_reasoning_block(text))
rescue JSON::ParserError
  nil
end

def valid_against_schema?(data, schema)
  pp JSON::Validator.validate(schema, data)
  return true
rescue => err 
  pp err.message
  false
end



#######################
# Bridges to Considerit
def get_all_considerit_prompts(forum, include_archived=false)

  prompts = []
  forum.customizations.each do |k, v|
    if k.match(/list\//) && !v["list_is_archived"]
      prompts << { key: k, data: v }
    end
  end

  sorted_prompts = prompts.sort_by do |entry|
    created_at = entry[:data]["created_at"]
    created_at.nil? ? -1 : created_at
  end

  return sorted_prompts

end

# not fully implemented
def generate_image(forum, avatar, result = 0)
  # ai_config = forum.customizations["ai_participation"]
  # prompt = "You're generating an avatar image to be used in forum software. The image is for an AI-backed participant named \"#{avatar["name"]}\" in a deliberative forum where the AI is role-playing the following perspective: #{avatar['embodiment_prompt']} #{avatar['nomination']}."
  # client = get_client()
  # begin 
  #   response = client.images.generate(parameters: { prompt: prompt, size: "256x256" })
  # rescue
  #   return generate_image(prompt)
  # end
  # img_url = response.dig("data", 0, "url")

  attempts = 0
  begin
    img_url = first_squareish_avatar(avatar["name"], idx=result)
    pp img_url
  rescue
    attempts += 1
    if attempts < 5
      retry
    end
  end


  return img_url
end

require 'faraday'

def first_squareish_avatar(query, idx:0, tolerance: 0.2, min_size: 500)
  # Step 1: Get vqd token from DuckDuckGo homepage

  headers = { "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }

  home_resp = Faraday.get("https://duckduckgo.com/", { q: query }) do |req|
    req.headers.update(headers)
  end

  vqd = home_resp.body.match(/vqd=['"]?([\d-]+)['"]?/) { |m| m[1] }

  raise "Failed to extract vqd token on #{query}" unless vqd

  # Step 2: Fetch image search results
  image_resp = Faraday.get("https://duckduckgo.com/i.js", { q: query, vqd: vqd, o: "json" }) do |req|
    req.headers.update(headers)
  end


  raise "Image search failed: #{image_resp.status}" unless image_resp.status == 200

  images = JSON.parse(image_resp.body)["results"]

  # Step 3: Filter for square-ish images
  found = -1
  images.find do |img|
    width  = img["width"].to_f
    height = img["height"].to_f
    next false if width < min_size || height < min_size || found += 1 > idx

    aspect_ratio = width / height
    (1 - tolerance..1 + tolerance).include?(aspect_ratio)
  end&.dig("image") # return just the image URL
end



def get_and_create_avatar_user(forum, avatar, generate_avatar_pic=true)
  # returns the user associated with this avatar. If it doesn't yet exist, create it
  ai_config = forum.customizations["ai_participation"]

  if avatar["user_id"]
    user = User.find(avatar["user_id"])

  else
    attempts = 0
    begin
      attrs = {
        name: avatar["name"],
        email: "#{forum.name}-#{User.all.count}@generated_avatar.ai",
        password: SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20],
        registered: true,
        verified: true
      }
      if generate_avatar_pic
        attrs[:avatar_url] = generate_image(forum, avatar, result = attempts)
      end 
      
      user = User.create! attrs
      user.add_to_active_in(forum)

      ai_config["avatars"][avatar["name"]]["user_id"] = user.id
      forum.save
    rescue => err
      attempts += 1
      if attempts < 4
        retry
      end
      raise err
    end
  end

  return user
end




#### 
# Utility function for removing the <think> blocks that some LLMs produce. And other
# artifacts
def remove_reasoning_block(input)
  # Remove <think>...</think> section if present (including multiline content)
  cleaned = input.sub(/<think>.*?<\/think>/m, '').strip

  # Extract substring from first { to last }, inclusive
  if cleaned =~ /{.*}/m
    cleaned = cleaned[/\{.*\}/m]
  end

  cleaned
end



# proposal_list_json = {
#   "$schema": "https://json-schema.org/draft/2020-12/schema",
#   "title": "ProposalList",
#   "type": "object",
#   "properties": {
#     "proposals": {
#       "type": "array",
#       "items": {
#         "type": "object",
#         "properties": {
#           "name": {
#             "type": "string",
#             "description": "A succinct summary of the proposal"
#           },
#           "description": {
#             "type": "string",
#             "description": "A fuller description of the proposal"
#           }
#         },
#         "required": ["name", "description"],
#         "additionalProperties": false
#       }
#     }
#   },
#   "required": ["proposals"],
#   "additionalProperties": false
# }



