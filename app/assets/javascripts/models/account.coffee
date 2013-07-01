class ConsiderIt.Account extends Backbone.Model
  name: 'account'
  
  initialize : (attrs) ->
    attrs['slider_right'] = 'oppose' if !(attrs['slider_right']?)
    attrs['slider_left'] = 'support' if !(attrs['slider_left']?)
    attrs['considerations_prompt'] = 'What are the most important pros and cons to you?' if !(attrs['considerations_prompt']?)
    attrs['slider_prompt'] = 'What is your overall opinion given these Pros and Cons?' if !(attrs['slider_prompt']?)
    attrs['statement_prompt'] = 'support' if !(attrs['statement_prompt']?)
    attrs['pro_label'] = 'pro' if !(attrs['pro_label']?)
    attrs['con_label'] = 'con' if !(attrs['con_label']?)

    super attrs

  url : () ->
    Routes.account_path()