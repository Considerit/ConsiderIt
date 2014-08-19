(function () {
    /*   To do:
          - Make fetch() work for root objects lacking cache key
     */

    // ****************
    // Public API
    var cache = {}
    function fetch(url, defaults) {
        record_dependence(url)

        // Return the cached version if it exists
        if (cache[url]) return cache[url]

        // Else, start a serverFetch in the background and return stub.
        if (url[0] === '/')
            serverFetch(url)

        return cache[url] = extend({key: url}, defaults)
    }

    /*
     *  Takes any number of object arguments.  For each:
     *  - Update cache
     *  - Saves to server
     *
     *  It supports multiple arguments to allow batching multiple
     *  serverSave() calls together in future optimizations.
     */
    function save() {
        for (var i=0; i < arguments.length; i++) {
            var object = arguments[i]
            updateCache(object)
            if (object.key && object.key[0] == '/')
                serverSave(object)
        }
    }

    // ================================
    // == Internal funcs

    var new_index = 0
    function updateCache(object) {
        var affected_keys = []
        function updateCacheInternal(object) {
            // Recurses through object and folds it into the cache.

            // If this object has a key, update the cache for it
            var key = object && object.key
            if (key) {
                // Change /new/thing to /new/thing/45
                if (key.match(new RegExp('^/new/'))     // Starts with /new/
                    && !key.match(new RegExp('/\\d+$'))) // Doesn't end in a /number
                    key = object.key = key + '/' + new_index++

                var cached = cache[key]
                if (!cached)
                    // This object is new.  Let's cache it.
                    cache[key] = object
                else if (object !== cached)
                    // Else, mutate cache to equal the object.
                    for (var k in object)          // Mutating in place preserves
                        cache[key][k] = object[k]  // pointers to this object

                // Remember this key for re-rendering
                affected_keys.push(key)
            }

            // Now recurse into this object.
            //  - Through each element in arrays
            //  - And each property on objects
            if (Array.isArray(object))
                for (var i=0; i < object.length; i++)
                    object[i] = updateCacheInternal(object[i])
            else if (typeof(object) === 'object' && object !== null)
                for (var k in object)
                    object[k] = updateCacheInternal(object[k])

            // Return the new cached representation of this object
            return cache[key] || object
        }

        updateCacheInternal(object)
        var re_render = (window.re_render || function () {
            console.log('You need to implement re_render()') })
        re_render(affected_keys)
    }

    var outstanding_requests = {}
    function serverFetch(key) {
        // Error check
        if (outstanding_requests[key]) throw Error('Duplicate request for '+key)

        // Build request
        var request = new XMLHttpRequest()
        request.onload = function () {
            delete outstanding_requests[key]
            if (request.status === 200) {
                console.log('Fetch returned for', key)
                var result = JSON.parse(request.responseText)
                // Warn if the server returns data for a different url than we asked it for
                console.assert(result.key && result.key === key,
                               'Server returned data with unexpected key', result, 'for key', key)
                updateCache(result)
            }
            else if (request.status === 500)
                window.ajax_error && window.ajax_error()

        }

        // Open request
        outstanding_requests[key] = request
        request.open('GET', key, true)
        request.setRequestHeader('Accept','application/json')
        request.send(null);
    }

    function serverSave(object) {
        var original_key = object.key
        
        // Special case for /new.  Grab the pieces of the URL.
        var pattern = new RegExp("/new/([^/]+)/(\\d+)")
        var match = original_key.match(pattern)
        var url = (match && '/' + match[1]) || original_key

        // Build request
        var request = new XMLHttpRequest()
        request.onload = function () {
            if (request.status === 200) {
                var result = JSON.parse(request.responseText)
                console.log('New save result', result)
                // Handle /new/stuff
                map_objects(result, function (obj) {
                    match = obj.key && obj.key.match(/(.*)\?original_id=(\d+)$/)
                    if (match && match[2]) {
                        // Let's map the old and new together
                        var new_key = match[1]                // It's got a fresh key
                        cache[new_key] = cache[original_key]  // Point them at the same thing
                        obj.key = new_key                     // And it's no longer new
                    }
                })
                updateCache(result)
            }
            else if (request.status === 500)
                window.ajax_error && window.ajax_error()
        }

        object = clone(object)
        object['authenticity_token'] = csrf()

        // Open request
        var POST_or_PUT = match ? 'POST' : 'PUT'
        request.open(POST_or_PUT, url, true)
        request.setRequestHeader('Accept','application/json')
        request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
        request.setRequestHeader('X-CSRF-Token', csrf())
        request.send(JSON.stringify(object));
    }

    var csrf_token = null
    function csrf(new_token) {
        if (new_token) csrf_token = new_token
        if (csrf_token) return csrf_token
        var metas = document.getElementsByTagName('meta'); 
        for (i=0; i<metas.length; i++) { 
            if (metas[i].getAttribute("name") == "csrf-token") { 
                return metas[i].getAttribute("content"); 
            } 
        } 
        return "";
    }

    loading_indicator = React.DOM.div({style: {height: '100%', width: '100%'},
                                       className: 'loading'}, 'Loading')
    function error_indicator(message) {
        return React.DOM.div(null, 'Error! ' + message)
    }

    // ****************
    // Utility for React Components
    function hashset() {
        var hash = this.hash = {}
        this.get = function (k) { return hash[k] || [] }
        this.add = function (k, v) {
            // if (k == 'component/946') {console.log('Adding component/946');console.trace()}
            if (hash[k] === undefined)
                hash[k] = []
            hash[k].push(v)
        }
        this.del = function (k, v) {
            var i = hash[k].indexOf(v)
            hash[k].splice(i, 1)
        }
        this.delAll = function (k) { hash[k] = [] }
    }


    // ****************
    // Wrapper for React Components
    var components = {}                  // Indexed by 'component/0', 'component/1', etc.
    var components_next_id = 0
    var keys_4_component = new hashset() // Maps component to its dependence keys
    var components_4_key = new hashset() // Maps key to its dependent components
    var dirty_components = {}
    function ReactiveComponent(obj) {
        obj.data = obj.get = function (key, defaults) {
            if (!this._lifeCycleState || this._lifeCycleState == 'UNMOUNTED')
                throw Error('Component ' + this.name + ' (' + this.local_key 
                            + ') is tryin to get data(' + key + ') after it died.')

            if (key === undefined)    key = this.mounted_key || this.name
            if (!key)                 return null
            // if (!key)    throw TypeError('Component mounted onto a null key. '
            //                              + this.name + ' ' + this.local_key)
            if (key.key) key = key.key   // If user passes key as object
            return fetch(key, defaults)  // Call into main activerest
        }
        obj.save = save                  // Call into main activerest
        
        // Render will need to clear the component's old dependencies
        // before rendering and finding new ones
        wrap(obj, 'render', function () {
            clearComponentDeps(this.local_key)
            delete dirty_components[this.local_key]
        })

        // We will register this component when creating it
        wrap(obj, 'componentWillMount',
             function () { 
                 this.local_key = 'component/' + components_next_id++
                 // console.log('mounting', this.props.key)

                 if (obj.displayName === undefined) throw 'Component has not defined a displayName'

                 this.name = obj.displayName.toLowerCase()
                 components[this.local_key] = this

                 if (this.props.key && this.props.key.key)
                     this.props.key = this.props.key.key

                 // XXX Putting this into WillMount probably won't let
                 // you use the mounted_key inside getInitialState!
                 this.mounted_key = this.props.key
                 window.tmp = this

                 // Create shortcuts e.g. `this.foo' for all parents
                 // up the tree, and this component's local key
                 Object.defineProperty(this, 'local', {
                     get: function () { return this.get(this.local_key) },
                     configurable: true })

                 var parents = this.props.parents.concat([this.local_key])
                 for (var i=0; i<parents.length; i++) {
                     var name = components[parents[i]].name.toLowerCase()
                     var key = components[parents[i]].props.key
                     if (!key && cache[name] !== undefined)
                         key = name
                     delete this[name]
                     Object.defineProperty(this,
                                           name,
                                           { get: function () { return this.get(key) },
                                             configurable: true })
                 }
             })
        wrap(obj, 'componentDidMount')
        wrap(obj, 'componentDidUpdate')
        wrap(obj, 'getDefaultProps')
        //wrap(obj, 'componentWillReceiveProps')
        wrap(obj, 'componentWillUnmount', function () {
            clearComponentDeps(this.local_key)
            delete cache[this.local_key]
            delete components[this.local_key]
            delete dirty_components[this.local_key]
            //sanity(this.local_key)
        })
        obj.shouldComponentUpdate = function (next_props, next_state) {
            // This component definitely needs to update if it is marked as dirty
            if (dirty_components[this.local_key] !== undefined) return true

            // Otherwise, we'll check to see if its state or props have changed. 
            // We can do so by simply serializing them and then comparing them. 
            // There is a catch however: If React's children property is set on the 
            // props, serialization will lead to an error because of a circular 
            // reference. So we'll remove the children property.
            next_props = clone(next_props); this_props = clone(this.props)
            delete next_props['children']; delete this_props['children']
            return JSON.stringify([next_state, next_props]) != JSON.stringify([this.state, this_props])
        }
        
        obj.is_waiting = function () {
            // Does this component depend on any keys that are being
            // requested?
            var dependent_keys = keys_4_component.get(this.local_key)
            for (var i=0; i<dependent_keys.length; i++)
                if (outstanding_requests[dependent_keys[i]])
                    return true
            return false
        }

        window.re_render = function (keys) {
            // console.log('Re-rendering keys', keys)
            setTimeout(function () {
                for (var i=0; i<keys.length; i++) {
                    affected_components = components_4_key.get(keys[i])
                    for (var j=0; j<affected_components.length; j++)
                        dirty_components[affected_components[j]] = true
                }

                for (var comp_key in dirty_components)
                    // Cause they will clear from underneath us
                    if (dirty_components[comp_key]) {
                        // console.log('force updating component', components[comp_key].name)
                        components[comp_key].forceUpdate()
                    }
            })
        }

        var react_class = React.createClass(obj)
        return function (props, children) {
            props = props || {}
            props.parents = execution_context.slice()
            // if (props.key === '/user/14733')
            //     console.log('Found /user/14733 at', props)
            return react_class(props, children)
        }
    }

    var execution_context = []
    function record_dependence(key) {
        if (execution_context.length > 0) {
            var component = execution_context[execution_context.length-1]
            keys_4_component.add(component, key)  // Track dependencies
            components_4_key.add(key, component)  // both ways
        }
    }

    function sanity(compkey) {
        for (var attr in components)
            if (components[attr]._lifeCycleState != 'MOUNTED')
                console.error('Component ' + attr + ' isn\'t mounted')

        for (var attr in components_4_key.hash) {
            var list = components_4_key.hash[attr]
            for (var i=0; i < list.length; i++) {
                if (list[i] === compkey
                    && (!components[compkey]
                        || components[compkey]._lifeCycleState != 'MOUNTED'))
                    console.error('Did not clean this well!', compkey, attr, list, i)
            }
        }
    }

    function clearComponentDeps (component) {
        // if (component === 'component/0')
        //     console.log('Clearing component/0')
        var depends_on_keys = keys_4_component.get(component)
        for (var i=0; i<depends_on_keys.length; i++)
            components_4_key.del(depends_on_keys[i], component)
        keys_4_component.delAll(component)
    }


    // ******************
    // Internal helpers/utility funcs
    function clone(obj) {
        if (obj == null) return obj
        var copy = obj.constructor()
        for (var attr in obj)
            if (obj.hasOwnProperty(attr)) copy[attr] = obj[attr]
        return copy
    }
    function extend(obj, with_obj) {
        if (with_obj === undefined) return obj
        for (var attr in with_obj)
            if (!obj.hasOwnProperty(attr)) obj[attr] = with_obj[attr]
        return obj
    }
    function wrap(obj, method, before, after) {
        var original_method = obj[method]
        if (!(original_method || before || after)) return
        obj[method] = function() {
            before && before.apply(this, arguments)
            if (this.local_key !== undefined)
                // We only want to set the execution context on
                // wrapped methods that are called on live instance.
                // getDefaultProps(), for instance, is called when
                // defining a component class, but not on actual
                // instances.  You can't render new components from
                // within there, so we don't need to track the
                // execution context.
                execution_context = this.props.parents.concat([this.local_key])

            try {
                var result = original_method && original_method.apply(this, arguments)
            } catch (e) {
                execution_context = []
                if (e instanceof TypeError) {
                    if (this.is_waiting()) return loading_indicator
                    else { console.error("In", this.name + ':', e.stack); return error_indicator(e.message) }
                } else { console.error('In', this.name + ':', e.stack); throw e }
            }
            execution_context = []
            after && after.apply(this, arguments)

            return result
        }
    }
    function map_objects(object, func) {
        if (Array.isArray(object))
            for (var i=0; i < object.length; i++)
                map_objects(object[i], func)
        else if (typeof(object) === 'object' && object !== null) {
            func(object)
            for (var k in object)
                map_objects(object[k], func)
        }
    }

    // Export the public API
    window.ReactiveComponent = ReactiveComponent
    window.fetch = fetch
    window.save = save

    // Make the private methods accessible under "window.arest"
    vars = 'cache fetch save serverFetch serverSave updateCache csrf keys_4_component components_4_key components execution_context hashset clone wrap sanity clearComponentDeps dirty_components'.split(' ')
    window.arest = {}
    for (var i=0; i<vars.length; i++)
        window.arest[vars[i]] = eval(vars[i])

})()
