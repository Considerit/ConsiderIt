(function () {

    // ****************
    // Public API
    var cache = {}
    function fetch(url, defaults) {
        //if (window.watch && watch(url)) console.trace()

        if (!url) return null
        if (url.key) url = url.key   // If user passes key as object

        window.record_dependence && record_dependence(url)

        // Return the cached version if it exists
        if (cache[url]) return cache[url]

        // Else, start a serverFetch in the background and return stub.
        if (url[0] === '/')
            server_fetch(url)

        update_cache(extend({key: url}, defaults), true)
        return cache[url]
    }

    /*  Updates cache and saves to server.
     *  You can pass a callback that will run when the saves have finished.
     */
    function save(object, continuation) {
        update_cache(object)

        // Save all the objects
        if (object.key && object.key[0] == '/')
            server_save(object, continuation)
        else
            if (continuation) continuation()
    }

    /*  Deletes from server (if it's there) and removes from cache
     *  You can pass a callback that will run when the delete has finished.
     */
    function destroy(key, continuation) {
        if (!key) return

        // Save all the objects
        if (key[0] == '/')
            server_destroy(key, continuation)
        else {
            // Just remove the key from the cache if this state is
            // owned by the client.  Note that this won't clean up
            // references to this object in e.g. any lists. The Client
            // is responsible for updating all the relevant
            // references.
            delete cache[key]
            if (continuation) continuation()
        }
    }


    // ================================
    // == Internal funcs

    var new_index = 0
    var affected_keys = new Set()
    var re_render_timer = null
    function update_cache(object, from_fetch) {
        function recurse(object) {
            // Recurses into object and folds it into the cache.

            // If this object has a key, update the cache for it
            var key = object && object.key
            if (key) {
                // if (!key || !key.match) {
                //     console.trace()
                //     console.log(key)
                // }

                // Change /new/thing to /new/thing/45
                if (key.match(new RegExp('^/new/'))     // Starts with /new/
                    && !key.match(new RegExp('/\\d+$'))) // Doesn't end in a /number
                    key = object.key = key + '/' + new_index++

                var cached = cache[key]
                if (!cached)
                    // This object is new.  Let's cache it.
                    cache[key] = object
                else if (object !== cached)
                    // Else, mutate cache to match the object.
                    for (var k in object)          // Mutating in place preserves
                        cache[key][k] = object[k]  // pointers to this object

                // Remember this key for re-rendering
                if (!from_fetch) {
                    affected_keys.add(key)
                }
            }

            // Now recurse into this object.
            //  - Through each element in arrays
            //  - And each property on objects
            if (Array.isArray(object))
                for (var i=0; i < object.length; i++)
                    object[i] = recurse(object[i])
            else if (typeof(object) === 'object' && object !== null)
                for (var k in object)
                    object[k] = recurse(object[k])

            // Return the new cached representation of this object
            return cache[key] || object
        }

        recurse(object)

        // Now initiate the re-rendering, if there isn't a timer already going
        if (!re_render_timer){
            re_render_timer = requestAnimationFrame(function () {
                re_render_timer = null
                var keys = affected_keys.all()
                affected_keys.clear()
                if (keys.length > 0) {
                    var re_render = (window.re_render || function () {
                        console.log('You need to implement re_render()') })
                    re_render(keys)
                }
            })
        }
    }

    var outstanding_fetches = {}
    function server_fetch(key) {
        // Error check
        if (outstanding_fetches[key]) {
            console.error('Duplicate request for '+key)
            return
        }

        // Build request
        var request = new XMLHttpRequest()
        request.onload = function () {
            delete outstanding_fetches[key]
            if (request.status === 200) {
                var result = JSON.parse(request.responseText)
                if (window.arest.trans_in)
                    result = arest.trans_in(result)
                update_cache(result)
            }
            else if (request.status === 500)
                if (window.on_ajax_error) window.on_ajax_error()

        }

        // Open request
        outstanding_fetches[key] = request
        request.open('GET', key, true)
        request.setRequestHeader('Accept','application/json')
        request.setRequestHeader('X-Requested-With','XMLHttpRequest')

        request.send(null)
    }

    var pending_saves = {} // Stores xmlhttprequest of any key being saved
                           // (Note: This shim will fail in many situations...)
    function server_save(object, continuation) {
        if (pending_saves[object.key]) {
            console.log('Yo foo, aborting', object.key)
            pending_saves[object.key].abort()
            delete pending_saves[object.key]
        }

        var original_key = object.key
        
        // Special case for /new.  Grab the pieces of the URL.
        var pattern = new RegExp("/new/([^/]+)/(\\d+)")
        var match = original_key.match(pattern)
        var url = (match && '/' + match[1]) || original_key

        // Build request
        var request = new XMLHttpRequest()
        request.onload = function () {
            // No longer pending
            delete pending_saves[original_key]

            if (request.status === 200) {
                var result = JSON.parse(request.responseText)
                // console.log('New save result', result)
                // Handle /new/stuff
                deep_map(function (obj) {
                    match = obj.key && obj.key.match(/(.*)\?original_id=(\d+)$/)
                    if (match && match[2]) {
                        // Let's map the old and new together
                        var new_key = match[1]                // It's got a fresh key
                        cache[new_key] = cache[original_key]  // Point them at the same thing
                        obj.key = new_key                     // And it's no longer "/new/*"
                    }
                },
                        result)
                update_cache(result)
                if (continuation) continuation()
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
        request.setRequestHeader('X-Requested-With','XMLHttpRequest')
        request.send(JSON.stringify(object))

        // Remember it
        pending_saves[original_key] = request
    }

    function server_destroy(key, continuation) {
        // Build request
        var request = new XMLHttpRequest()
        request.onload = function () {
            if (request.status === 200) {
                console.log('Destroy returned for', key)
                var result = JSON.parse(request.responseText)
                delete cache[key]
                update_cache(result)
                if (continuation) continuation()
            }
            else if (request.status === 500)
                if (window.on_ajax_error) window.on_ajax_error()
            else {
                // TODO: give user feedback that DELETE failed
                console.log('DELETE of', key, 'failed!')
            }

        }

        payload = {'authenticity_token': csrf()}

        // Open request
        request.open('DELETE', key, true)
        request.setRequestHeader('Accept','application/json')
        request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
        request.setRequestHeader('X-CSRF-Token', csrf())
        request.setRequestHeader('X-Requested-With','XMLHttpRequest')
        request.send(JSON.stringify(payload))
    }

    // This is used in a specific hack.  I need to work on it.
    function clear_matching_objects (match_key_func) {
        // Clears all keys where match_key_func(key) returns true
        for (key in cache)
            if (match_key_func(key))
                delete cache[key]
    }


    var csrf_token = null
    function csrf(new_token) {
        if (new_token) csrf_token = new_token
        if (csrf_token) return csrf_token
        var metas = document.getElementsByTagName('meta')
        for (i=0; i<metas.length; i++) { 
            if (metas[i].getAttribute("name") == "csrf-token") { 
                return metas[i].getAttribute("content");
            } 
        } 
        return ""
    }

    window.loading_indicator = React.createFactory(ReactDOMFactories.div)({style: {height: '100%', width: '100%'},
                                       className: 'loading'}, 'Loading')

    function error_indicator(message) {
        return ReactDOMFactories.div(null, 'Error! ' + message)
    }


    // ****************
    // Wrapper for React Components
    var components = {}                  // Indexed by 'component/0', 'component/1', etc.
    var components_count = 0
    var dirty_components = {}
    var execution_context = []  // The stack of components that are being rendered

    function ReactiveComponent(component) {

        // STEP 1: Define get() and save()
        component.fetch = component.data = component.get = function (key, defaults) {
            if (!this.isMounted)
                throw Error('Component ' + this.name + ' (' + this.local_key
                            + ') is tryin to get data(' + key + ') after it died.')

            if (key === undefined)    key = this.mounted_key || this.name
            if (!key)                 return null
            // if (!key)    throw TypeError('Component mounted onto a null key. '
            //                              + this.name + ' ' + this.local_key)
            if (key.key) key = key.key   // If user passes key as object
            return fetch(key, defaults)  // Call into main activerest
        }
        component.save = save                  // Call into main activerest
        

        // STEP 2: Wrap all the component's methods
        function wrap(obj, method, before, after) {
            var original_method = obj[method]
            if (!(original_method || before || after)) return
            obj[method] = function() {
                before && before.apply(this, arguments)
                if (this.local_key !== undefined)
                    // We only want to set the execution context on wrapped methods
                    // that are called on live instance.  getDefaultProps(), for
                    // instance, is called when defining a component class, but not
                    // on actual instances.  You can't render new components from
                    // within there, so we don't need to track the execution context.
                    execution_context = this.props.parents.concat([this.local_key])

                try {
                    var result = original_method && original_method.apply(this, arguments)
                } catch (e) {
                    execution_context = []
                    if (this.is_waiting()){
                        // console.log('waiting for', this.name, 'missing', this.is_waiting())
                        return loading_indicator
                    }
                    else {
                        // Then let's re-cause the error, but without catching it
                        original_method.apply(this, arguments)
                        console.assert(false) // this cannot happen unless method has side effects
                    }
                }

                execution_context = []
                after && after.apply(this, arguments)

                return result
            }
        }

        // We register the component when mounting it into the DOM
        wrap(component, 'UNSAFE_componentWillMount',
            function () { 

                 // STEP 1. Register the component's basic info
                 if (component.displayName === undefined)
                     throw 'Component needs a displayName'
                 this.name = component.displayName.toLowerCase().replace(' ', '_')
                 this.local_key = 'component/' + components_count++
                 components[this.local_key] = this


                 // This is broken now that React doesn't allow props to be modified
                 // // You can pass an object in as a key if you want:
                 // var my_props = get_current_props_for_component_instance(this)
                 // if (my_props.key && my_props.key.key)
                 //     my_props.key = my_props.key.key


                 // XXX Putting this into WillMount probably won't let you use the
                 // mounted_key inside getInitialState!  But you should be using
                 // activerest state anyway, right?
                 this.mounted_key = this._reactInternals.key

                 // STEP 2: Create shortcuts e.g. `this.foo' for all parents up the
                 // tree, and this component's local key
                 
                 function add_shortcut (obj, shortcut_name, to_key) {
                     //console.log('Giving '+obj.name+' shorcut @'+shortcut_name+'='+to_key)
                     // console.log('shortcut', obj, shortcut_name, to_key)
                     delete obj[name]
                     Object.defineProperty(obj, shortcut_name, {
                         get: function () {
                            if (!obj.shortcuts)
                                obj.shortcuts = Object.create(null)
                            if (!obj.shortcuts[to_key])
                              obj.shortcuts[to_key] = obj.get(to_key)
                            return obj.shortcuts[to_key]
                         },
                         configurable: true })
                 }

                 // ...first for @local
                 add_shortcut(this, 'local', this.local_key)
                 
                 // ...and now for all parents
                 // (I don't use parent shortcuts anymore, and consider them an anti-pattern)
                 // var parents = this.props.parents.concat([this.local_key])
                 // for (var i=0; i<parents.length; i++) {
                 //     var name = components[parents[i]].name
                 //     var key = components[parents[i]].mounted_key //props.key
                 //     if (!key && cache[name] !== undefined)
                 //         key = name
                 //     add_shortcut(this, name, key)
                 // }
            })

        wrap(component, 'render', function () {
            // Render will need to clear the component's old
            // dependencies before rendering and finding new ones
            clear_component_dependencies(this.local_key)
            delete dirty_components[this.local_key]
            if (this.shortcuts) {
                keys = Object.keys(this.shortcuts)
                for (var i=0; i < keys.length; i++){
                    key = keys[i]
                    keys_4_component.add(this.local_key, key)  // Track dependencies
                    components_4_key.add(key, this.local_key)  // both ways
                }
            }
        })

        wrap(component, 'componentDidMount', function () {
            ReactDOM.findDOMNode(this).setAttribute('data-widget', component.displayName)
            if (this.mounted_key)
                ReactDOM.findDOMNode(this).setAttribute('data-key', this.mounted_key)              
        })
        wrap(component, 'componentDidUpdate', function () {
            ReactDOM.findDOMNode(this).setAttribute('data-widget', component.displayName)
            if (this.mounted_key)
                ReactDOM.findDOMNode(this).setAttribute('data-key', this.mounted_key)              
        })
        // wrap(component, 'getDefaultProps')
        //wrap(component, 'componentWillReceiveProps')
        wrap(component, 'componentWillUnmount', function () {
            // Clean up
            clear_component_dependencies(this.local_key)
            delete cache[this.local_key]
            delete components[this.local_key]
            delete dirty_components[this.local_key]
        })
        component.shouldComponentUpdate = function (next_props, next_state) {
            // This component definitely needs to update if it is marked as dirty
            if (dirty_components[this.local_key] !== undefined) return true

            // Otherwise, we'll check to see if its state or props
            // have changed.  We can do so by simply serializing them
            // and then comparing them.  But ignore React's 'children'
            // prop, because it often has a circular reference.
            next_props = clone(next_props); this_props = clone(this.props)
            delete next_props['children']; delete this_props['children']

            // console.assert(!_.isEqual([next_state, next_props], [this.state, this_props]) == JSON.stringify([next_state, next_props]) != JSON.stringify([this.state, this_props]), {next_state: next_state, next_props: next_props})
            if (_)
                return !_.isEqual([next_state, next_props], [this.state, this_props])
            else 
                return JSON.stringify([next_state, next_props]) != JSON.stringify([this.state, this_props])
        }
        
        component.is_waiting = function () {
            // Does this component depend on any keys that are being
            // requested?
            var dependent_keys = keys_4_component.get(this.local_key)
            for (var i=0; i<dependent_keys.length; i++)
                if (outstanding_fetches[dependent_keys[i]])
                    return dependent_keys[i]
            return false
        }

        window.waiting_for = function(obj_or_key) {
            return !!outstanding_fetches[obj_or_key.key || obj_or_key]
        }

        // STEP 3: Configure the global function hooks for React
        window.re_render = react_rerender
        window.record_dependence = record_component_dependence

        // Now create the actual React class with this definition, and
        // return it.
        var react_class = React.createFactory(createReactClass(component))
        var result = function (props, children) {
            props = props || {}
            props.parents = execution_context.slice()
            return react_class(props, children)
        }
        // Give it the same prototype as the original class so that it
        // passes React.isValidClass() inspection
        result.prototype = react_class.prototype
        return result
    }


    // *****************
    // Dependency-tracking for React components
    var keys_4_component = new One_To_Many() // Maps component to its dependence keys
    var components_4_key = new One_To_Many() // Maps key to its dependent components
    function react_rerender (keys) {
        // Re-renders only the components that depend on `keys'
        // console.log('RENDERING BASED ON:', keys)
        // First we determine the components that will need to be updated
        for (var i = 0; i < keys.length; i++) {
            affected_components = components_4_key.get(keys[i])
            for (var j = 0; j < affected_components.length; j++)
                dirty_components[affected_components[j]] = true
        }

        // Then we sweep through and update them
        for (var comp_key in dirty_components){
            // console.log("\tREDO", comp_key, arest.components[comp_key])
            // the check on both dirty_components and components is a PATCH
            // for a possible inconsistency between dirty_components and components
            // that occurs if a component has a componentWillUnmount method.
            if (dirty_components[comp_key] && components[comp_key]){ // Since one component might update another
                components[comp_key].forceUpdate()
            }
        }
    }
    function record_component_dependence(key) {
        // Looks up current component from the execution context
        if (execution_context.length > 0) {
            var component = execution_context[execution_context.length-1]
            keys_4_component.add(component, key)  // Track dependencies
            components_4_key.add(key, component)  // both ways
        }
    }
    function clear_component_dependencies(component) {
        var depends_on_keys = keys_4_component.get(component)
        for (var i=0; i<depends_on_keys.length; i++)
            components_4_key.del(depends_on_keys[i], component)
        keys_4_component.delAll(component)
    }


    // ****************
    // Utility for React Components
    window.add_cnt = {}
    window.print_add_cnt = function(){
        var my_keys = Object.keys(add_cnt);
        var values = Object.values(add_cnt)
        values = values.sort(function(a,b){return (b - a)})
        sorted_keys = my_keys.sort(function(a,b){return parseInt(add_cnt[b]) - parseInt(add_cnt[a])})
        var idx=0
        for(var i=0; i < sorted_keys.length; i++){
            key = sorted_keys[i]
            console.log(key, add_cnt[key])
            idx = idx + 1
            if (idx > 100)
                break
        }
    }
    function One_To_Many() {
        var hash = this.hash = Object.create(null)
        this.get = function (k) { return Object.keys(hash[k] || {}) }
        this.add = function (k, v) {
            if (hash[k] === undefined)
                hash[k] = Object.create(null)

            // if (window.add_cnt[k + v] == undefined)
            //     window.add_cnt[k+v] = 0 
            // if (k == 'component/64' && v == '/subdomain')
            //     console.trace()
            // window.add_cnt[k+v] += 1
            hash[k][v] = true
        }
        this.del = function (k, v) {
            delete hash[k][v]
        }
        this.delAll = function (k) { hash[k] = Object.create(null) }
    }
    function Set() {
        var hash = {}
        this.add = function (a) { if (!hash[a]) hash[a] = true }
        this.all = function () { return Object.keys(hash) }
        this.clear = function () { hash = {} }
    }


    // ******************
    // General utility funcs
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
    function deep_map(func, object) {
        // This function isn't actually a full "deep map" yet.
        // Limitations: It only applies func to OBJECTS (not arrays or
        // atoms), and doesn't return anything.
        if (Array.isArray(object))
            for (var i=0; i < object.length; i++)
                deep_map(func, object[i])
        else if (typeof(object) === 'object' && object !== null) {
            func(object)
            for (var k in object)
                deep_map(func, object[k])
        }
    }
    function error(e, name) {
        console.error('In', name + ':', e.stack)
        if (window.on_client_error)
            window.on_client_error(e)
    }

    function key_id(string) {
        return string.match(/\/[^\/]+\/(\d+)/)[1]
    }

    // Camelcased API options
    var updateCache=update_cache, serverFetch=server_fetch,
        serverSave=server_save, serverDestroy=server_destroy

    // Export the public API
    window.ReactiveComponent = ReactiveComponent
    window.fetch = fetch
    window.save = save
    window.destroy = destroy

    // Make the private methods accessible under "window.arest"
    vars = [['cache', cache], ['fetch',fetch], ['save',save], ['server_fetch', server_fetch], ['serverFetch', serverFetch], ['server_save', server_save], ['serverSave',serverSave], ['update_cache',update_cache], ['updateCache',updateCache], ['csrf',csrf], ['keys_4_component',keys_4_component], ['components_4_key', components_4_key], ['components',components], ['execution_context',execution_context], ['One_To_Many',One_To_Many], ['clone',clone], ['dirty_components', dirty_components], ['affected_keys',affected_keys], ['clear_matching_objects',clear_matching_objects], ['deep_map', deep_map], ['key_id', key_id], ['pending_saves', pending_saves]]
    window.arest = {}
    for (var i=0; i<vars.length; i++)
        window.arest[vars[i][0]] = vars[i][1]

})()
