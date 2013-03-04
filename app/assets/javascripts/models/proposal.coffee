class ConsiderIt.Proposal extends Backbone.Model
  defaults: { }
  name: 'proposal'

  initialize : ->
    super
    @attributes.description = htmlFormat(@attributes.description)

  url : () ->
    Routes.proposal_path( @attributes.long_id )

  title : (max_len = 140) ->
    if @get('name') && @get('name').length > 0
      my_title = @get('name')
    else if @get('description')
      my_title = @get('description')
    else
      throw 'Name and description nil'
    

    if my_title.length > max_len
      "#{my_title[0..max_len]}..."
    else
      my_title

  description_detail_fields : ->
    [ ['Long Description', $.trim(htmlFormat(@attributes.long_description))], 
      ['Fiscal Impact Statement', $.trim(htmlFormat(@attributes.additional_details))] ]