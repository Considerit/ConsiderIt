Fart = (function () {
    /*   To do:
          - Make fetch() work for root objects lacking cache key
     */

    // ****************
    // Public API
    var cache = {}
    function fetch(url) {
        // Return the cached version if it exists
        var cache_key = url.split('?')[0]
        var result = cache[cache_key]
        if (result)
            return result

        // Else, start a serverFetch in the background and return stub.
        if (url[0] === '/')
            serverFetch(url, updateCache)

        // This stub is not in the cache, but if you save() it, it
        // will end up there.
        return {key: url}
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
                serverSave(object, updateCache)
        }
    }

    // ================================
    // == Internal funcs

    function updateCache(object) {
        var affected_keys = []
        function updateCacheInternal(object) {
            // Recurses through object and folds it into the cache.

            // If this object has a key, update the cache for it
            var key = object && object.key && object.key.split('?')[0]
            if (key) {
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
        for (var i=0; i<affected_keys.length; i++)
            re_render(affected_keys[i])
    }

    function serverFetch(key, callback) {
        var request = new XMLHttpRequest()
        request.onload = function () {
            if (request.status === 200) {
                var result = JSON.parse(request.responseText)
                // Warn if the server returns data for a different url than we asked it for
                console.assert(result.key && result.key === key,
                               'Server returned data with unexpected key', result, 'for key', key)
                //console.log(result)
                callback && callback(result)
            }
        }

        request.open('GET', key, true)
        request.setRequestHeader('Accept','application/json')
        request.send(null);
    }

    function serverSave(object, callback) {
        var request = new XMLHttpRequest()
        request.onload = function () {
            if (request.status === 200) {
                var result = JSON.parse(request.responseText)
                //console.log(result)
                callback && callback(result)
            }
        }

        object = clone(object)
        object['authenticity_token'] = csrf()

        request.open('PUT', object.key, true)
        request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
        request.setRequestHeader('X-CSRF-Token', csrf())
        request.send(JSON.stringify(object));
    }

    function csrf() {
        var metas = document.getElementsByTagName('meta'); 
        for (i=0; i<metas.length; i++) { 
            if (metas[i].getAttribute("name") == "csrf-token") { 
                return metas[i].getAttribute("content"); 
            } 
        } 
        return "";
    }
    function serverNew(object, callback) {
        object = clone(object)
        object.csrf = csrf()
        var request = new XMLHttpRequest()
        request.onload = function () {
            if (request.status === 200) {
                var result = JSON.parse(request.responseText)

                // TODO: We still need to update the old /new/data url.
                //console.log(result)
                callback && callback(result)
            }
        }

        request.open('POST', object.key, true)
        request.send(JSON.stringify(object));
    }


    // ****************
    // Utility for React Components
    function hashset() {
        var hash = this.hash = {}
        this.get = function (k) { return hash[k] || [] }
        this.add = function (k, v) {
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
    var keys_4_component = new hashset() // Maps component to its dependence keys
    var components_4_key = new hashset() // Maps key to its depndent components
    function ReactiveComponent(obj) {
        var mounted_key = null;          // You can pass a key: '/thing' into component

        obj.get = function (key) {
            if (!key)    key = mounted_key
            if (key.key) key = key.key   // You user passes key as object
            keys_4_component.add(this.local_key, key)   // Track dependencies
            components_4_key.add(key, this.local_key)  // both ways

            return fetch(key)            // Call into main activerest
        }
        obj.save = save                  // Call into main activerest
        
        // Render will need to clear the component's old dependencies
        // before rendering and finding new ones
        wrap(obj, 'render',
             function () {
                 // Clear this component's dependencies
                 var component = this.local_key
                 var depends_on_keys = keys_4_component.get(component)
                 for (var i=0; i<depends_on_keys.length; i++)
                     components_4_key.del(depends_on_keys[i], component)
                 keys_4_component.delAll(component)
             })

        // We will register this component when creating it
        wrap(obj, 'componentWillMount',
             function () { 
                 this.local_key = 'component/' + Object.keys(components).length
                 components[this.local_key] = this

                 // XXX Putting this into WillMount probably won't let
                 // you use the mounted_key inside getInitialState!
                 mounted_key = this.props.key
             })
        
        window.re_render = function (key) {
            var comps = components_4_key.get(key)
            for (var i=0; i<comps.length; i++)
                components[comps[i]].forceUpdate()
        }

        return React.createClass(obj)
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

    function wrap(obj, method, before, after) {
        var original_method = obj[method]
        obj[method] = function() {
            before && before.apply(this, arguments)
            var result = original_method && original_method.apply(this, arguments)
            after && after.apply(this, arguments)
            return result
        }
    }

    // Export the public API
    window.fetch = fetch
    window.save = save
    window.serverFetch = serverFetch
    window.serverNew = serverNew
    window.serverSave = serverSave
    window.cache = cache
    window.csrf = csrf
    window.NonReactiveComponent = ReactiveComponent
    window.keys_4_component = keys_4_component
    window.components_4_key = components_4_key
    window.components = components
})()
