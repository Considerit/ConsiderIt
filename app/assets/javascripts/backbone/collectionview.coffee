# Backbone.CollectionView
# https://github.com/anthonyshort/backbone.collectionview
#
# General class for rendering Collections. Extend this class and
# specify an itemView.
#
# Heavily inspired by the CollectionView from ChaplinJS. Thanks dudes.
#
# Copyright (c) 2012 Anthony Short
# Licensed under the MIT license.

class Backbone.CollectionView extends Backbone.View

  # Borrow the extend method
  @extend: Backbone.Model.extend

  # The constructor function used to create a view
  # for each of the list items
  itemView: null

  # Class that is added to the element when there are no
  # items to show in the list
  emptyClass: 'is-empty'

  # Class that is added to the element when the collection is loading
  loadingClass: 'is-loading'

  # Selector which identifies child elements belonging to collection
  # All children are seen as belonging to collection if not present
  itemSelector: null

  # The list element the item views are actually appended to.
  # If empty, $el is used.
  # Set the selector property in the derived class to use a specific element.
  listSelector: null

  # The actual element reference which is filled using listSelector
  list: null

  # Hash which saves all item views by CID
  viewsByCid: null

  constructor: (options = {}) ->
    super

    unless options.collection
      throw "Backbone.CollectionView requires a collection"

    # Default options
    # These are not in the options property on so derived classes
    # may override them when calling super
    _(options).defaults
      render: false      # Render the view immediately per default
      renderItems: false # Render all items immediately per default

    # Initialize lists for views and visible items
    @viewsByCid = {}

    # Start observing the model
    @collectionEvents or= {}
    @addCollectionListeners(options.collection)

    # Observe events on each view
    @viewEvents or= {}

    # Allow setting of the itemView in the options
    @itemView = options.itemView or @itemView

    # Render template once
    @render() if options.render

    # Render all items initially
    @renderAllItems() if options.renderItems

  # Binding of collection listeners
  addCollectionListeners: (collection)->
    collection.on 'add', @onAdd, @
    collection.on 'remove', @onRemove, @
    collection.on 'reset', @onReset, @
    collection.on 'loading', @onLoad, @
    collection.on 'ready', @onReady, @

    for name,handler of @collectionEvents
      collection.on name, @[handler], @

    collection

  # Automatically add listeners for item views
  # This allows you to specify events to listen for on item views
  # and respond to them all from with the CollectionView definition
  addViewListeners: (view)->
    for name,handler of @viewEvents
      view.on name, @[handler], @
    view

  # When the collection fires a 'loading' event we add a loading
  # class to the collection list
  onLoad: =>
    @$el.addClass(@loadingClass)

  # Inversely, when it is finished loading and a 'ready' event is fired
  # we remove the loading class and check to see if we should show the
  # fallback content
  onReady: =>
    @$el.removeClass(@loadingClass)
    @initFallback()

  # When a model is added to the collection we add an item views to the list
  # in the correct position
  onAdd: (model) =>
    @addModelView(model)

  # When a model is removed from the collection, remove the view from the list
  onRemove: (model) =>
    @removeModelView(model)

  # When the collection is reset we will re-render all of the items in the list
  onReset: =>
    @renderAllItems()

  # Allows you to add a model to the collection easily which will add a view
  # to the list of items. Returns the newly created view which has the model
  # attached to it
  add: (data = {}, options = {}) ->
    model = new @collection.model(data)
    @collection.add(model,options)
    @getViewByModel(model)

  # Render the list. This doesn't render the items in the list. Shows the
  # fallback content if necessary
  render: ->
    super
    @list = if @listSelector then @$(@listSelector) else @$el
    @initFallback()

  # Determine if we should add the empty class to the element
  initFallback: ->
    if @collection.length is 0
      @$el.addClass(@emptyClass)
    else
      @$el.removeClass(@emptyClass)

  # Render all items from the collection into the list. We remove
  # all the views in the list and then rebuild them. A more efficient
  # way would be to only remove the items that aren't in the collection
  renderAllItems: ->
    @render()
    @clear()
    @collection.each (model) => @addModelView(model)

  # Reset the view. Empty the list and remove all the views
  clear: ->
    @list.empty()
    for own cid, view of @viewsByCid
      model = @collection.get(cid)
      @removeModelView(model) if model

  # Returns an instance of the view class
  # This method has to be overridden by a derived class.
  # This is not simply a property with a constructor so that
  # several item view constructors are possible depending
  # on the item model type.
  getItemView: (model)->
    unless @itemView
      throw 'Backbone.CollectionView needs an itemView property set. Alternatively override the getItemView method'
    new @itemView
      model: model
      collection: @collection

  # Add a model view to the list. Create the view for the model
  # and add it to the list
  addModelView: (model)->
    view = @getItemView(model)
    @addViewListeners(view)
    view.render()
    @viewsByCid[model.cid] = view
    @initFallback()
    @renderItem(view,model)
    view

  # Get the view for a model in the collection
  getViewByModel: (model) ->
    @viewsByCid[model.cid]

  # Remove a model's view from the list
  removeModelView: (model) ->
    view = @viewsByCid[model.cid]
    return unless view
    view.remove()
    delete @viewsByCid[model.cid]
    @initFallback()

  # Add the view to the list. This method can be overwritten if
  # you need to do something unique while adding it to the list
  renderItem: (view, model) ->
    children = @list.children(@itemSelector)
    position = @collection.indexOf(model)
    if position is 0
      @list.prepend(view.$el)
    else if position < children.length
      children.eq(position).before(view.$el)
    else
      @list.append(view.$el)
    @afterRenderItem(view,model)

  # Item post-render hook
  afterRenderItem: (view, model) ->

  # Remove the view and clean up any loose ends so that
  # no trace of the object is left in memory
  dispose: ->
    super
    delete @[prop] for prop in ['list','viewsByCid','collection']

module?.exports = Backbone.CollectionView