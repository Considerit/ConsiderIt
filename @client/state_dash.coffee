for el of React.DOM
  this[el.toUpperCase()] = React.DOM[el]

window.parse_key = (key) ->
  word = "([^/]+)"
  # Matching things like: "/new/name/number"
  # or:                   "/name/number"
  # or:                   "/name"
  # or:                   "name/number"
  # or:                   "name"
  # ... and you can optionally include a final slash.
  regexp = new RegExp("(/)?(new/)?#{word}(/#{word})?(/)?")
  m = key.match(regexp)
  if not m
    return null

  [has_match, server_owned, is_new, name, tmp1, number, tmp2] = m
  owner = if server_owned then 'server' else 'client'
  return has_match and {owner, 'new': is_new, name, number}

window.StateDash = ReactiveComponent
  displayName: 'State Dash'
  render: ->
    dash = @fetch('state_dash')
    
    if not dash.on
      return DIV null, ''

    url_tree = () ->
      # The key tree looks like:
      #
      # {server: {thing: [obj1, obj2], shing: [obj1, obj2], ...}
      #  client: {dong: [obj1, ...]}}
      #
      # And objects without a number, like '/shong' will go on:
      #  key_tree.server.shong[null]
      tree = {server: {}, client: {}}
      
      incorporate_key = (key) ->
        p = parse_key(key)
        if not p
          console.log('The state dash can\'t deal with key', key); return null

        tree[p.owner][p.name] ||= []
        tree[p.owner][p.name][p.number or null] = arest.cache[key]

      for key of arest.cache
        incorporate_key(key)
      return tree

    tree = url_tree()

    DIV className: 'state_dash',
      STYLE null,
        """
        .state_dash {
          position: absolute;
          margin: 20px;
          z-index: 10000;
          max-width: 100%;
        }
        .state_dash .left, .state_dash .right, .state_dash .top {
          background-color: #eee;
          overflow-wrap: break-word;
          padding: 10px;
          vertical-align: top;
        }
        .state_dash .left  { min-width:   40px; display: inline-block; }
        .state_dash .right { margin-left: 30px; display: inline-block; max-width: 70%; }
        .state_dash .top   { max-width:   100%; margin: 20px 0; }
        """

      # Render the top (name) menu
      DIV className: 'top',
        for owner in ['server', 'client']
          SPAN {style: {'margin': '10px 0'}, key: owner},
            B(style: {'font-weight': '600'}, owner.toUpperCase() + ':'),
            for name of tree[owner]
              do (owner, name) ->
                f = -> dash.selected={owner, name, number:null}; save(dash)
                style = (name == dash.selected.name) and {'background-color':'#aaf'} or {}
                SPAN({onMouseEnter: f, key: name, style},
                  ' ', name, ' ')

      # Render the side (number) menu
      if dash.selected.name
        DIV className: 'left',
          for number of tree[dash.selected.owner][dash.selected.name]
            if number == 'null'
              continue
            do (number) ->
              f = -> dash.selected.number = number; save(dash)
              style = number == dash.selected.number and {'background-color':'#aaf'} or {}

              DIV {onMouseEnter: f, style}, number
        
      # Render the object
      if dash.selected.number or (dash.selected.name and tree[dash.selected.owner][dash.selected.name][null])
        DIV className: 'right',
          JSON.stringify(tree[dash.selected.owner][dash.selected.name][dash.selected.number])


fetch 'state_dash',
  on: false
  selected: {owner: null, name: null, number: null}

document.onkeypress = (e) ->
  key = (e and e.keyCode) or event.keyCode
  console.log(key)
  if key==4
    dash = fetch('state_dash')
    if dash.on
      dash.on = false
    else
      dash.on = true
    save(dash)

