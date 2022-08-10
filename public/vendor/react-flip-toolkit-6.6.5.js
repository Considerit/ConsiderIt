(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('react'), require('prop-types')) :
    typeof define === 'function' && define.amd ? define(['exports', 'react', 'prop-types'], factory) :
    (global = global || self, factory(global.ReactFlipToolkit = {}, global.React, global.PropTypes));
}(this, function (exports, React, PropTypes) { 'use strict';

    var React__default = 'default' in React ? React['default'] : React;
    PropTypes = PropTypes && PropTypes.hasOwnProperty('default') ? PropTypes['default'] : PropTypes;

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation. All rights reserved.
    Licensed under the Apache License, Version 2.0 (the "License"); you may not use
    this file except in compliance with the License. You may obtain a copy of the
    License at http://www.apache.org/licenses/LICENSE-2.0

    THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
    WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
    MERCHANTABLITY OR NON-INFRINGEMENT.

    See the Apache Version 2.0 License for specific language governing permissions
    and limitations under the License.
    ***************************************************************************** */
    /* global Reflect, Promise */

    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    function __rest(s, e) {
        var t = {};
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
            t[p] = s[p];
        if (s != null && typeof Object.getOwnPropertySymbols === "function")
            for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) if (e.indexOf(p[i]) < 0)
                t[p[i]] = s[p[i]];
        return t;
    }

    var animateUnflippedElements = function (_a) {
        var unflippedIds = _a.unflippedIds, flipCallbacks = _a.flipCallbacks, getElement = _a.getElement, flippedElementPositionsBeforeUpdate = _a.flippedElementPositionsBeforeUpdate, flippedElementPositionsAfterUpdate = _a.flippedElementPositionsAfterUpdate, inProgressAnimations = _a.inProgressAnimations;
        var enteringElementIds = unflippedIds.filter(function (id) { return flippedElementPositionsAfterUpdate[id]; });
        var animatedEnteringElementIds = enteringElementIds.filter(function (id) { return flipCallbacks[id] && flipCallbacks[id].onAppear; });
        var animatedExitingElementIds = unflippedIds.filter(function (id) {
            return flippedElementPositionsBeforeUpdate[id] &&
                flipCallbacks[id] &&
                flipCallbacks[id].onExit;
        });
        // make sure appearing elements aren't taken into account by the filterFlipDescendants function
        enteringElementIds.forEach(function (id) {
            var element = getElement(id);
            if (element) {
                element.dataset.isAppearing = 'true';
            }
        });
        var hideEnteringElements = function () {
            animatedEnteringElementIds.forEach(function (id) {
                var element = getElement(id);
                if (element) {
                    element.style.opacity = '0';
                }
            });
        };
        var animateEnteringElements = function () {
            animatedEnteringElementIds.forEach(function (id, i) {
                var element = getElement(id);
                if (element) {
                    flipCallbacks[id].onAppear(element, i);
                }
            });
        };
        var closureResolve;
        var promiseToReturn = new Promise(function (resolve) {
            closureResolve = resolve;
        });
        var fragmentTuples = [];
        var exitingElementCount = 0;
        var onExitCallbacks = animatedExitingElementIds.map(function (id, i) {
            var _a = flippedElementPositionsBeforeUpdate[id].domDataForExitAnimations, element = _a.element, parent = _a.parent, _b = _a.childPosition, top = _b.top, left = _b.left, width = _b.width, height = _b.height;
            // insert back into dom
            if (getComputedStyle(parent).position === 'static') {
                parent.style.position = 'relative';
            }
            element.style.transform = 'matrix(1, 0, 0, 1, 0, 0)';
            element.style.position = 'absolute';
            element.style.top = top + 'px';
            element.style.left = left + 'px';
            // taken out of the dom flow, the element might have lost these dimensions
            element.style.height = height + 'px';
            element.style.width = width + 'px';
            var fragmentTuple = fragmentTuples.filter(function (t) { return t[0] === parent; })[0];
            if (!fragmentTuple) {
                fragmentTuple = [parent, document.createDocumentFragment()];
                fragmentTuples.push(fragmentTuple);
            }
            fragmentTuple[1].appendChild(element);
            exitingElementCount += 1;
            var stop = function () {
                try {
                    parent.removeChild(element);
                }
                catch (DOMException) {
                    // the element is already gone
                }
                finally {
                    exitingElementCount -= 1;
                    if (exitingElementCount === 0) {
                        closureResolve();
                    }
                }
            };
            inProgressAnimations[id] = { stop: stop };
            return function () { return flipCallbacks[id].onExit(element, i, stop); };
        });
        // now append all the fragments from the onExit callbacks
        // (we use fragments for performance)
        fragmentTuples.forEach(function (t) {
            t[0].appendChild(t[1]);
        });
        if (!onExitCallbacks.length) {
            closureResolve();
        }
        var animateExitingElements = function () {
            onExitCallbacks.forEach(function (c) { return c(); });
            return promiseToReturn;
        };
        return {
            hideEnteringElements: hideEnteringElements,
            animateEnteringElements: animateEnteringElements,
            animateExitingElements: animateExitingElements
        };
    };

    /*! @license Rematrix v0.2.2

      Copyright 2018 Fisssion LLC.

      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:

      The above copyright notice and this permission notice shall be included in
      all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
      THE SOFTWARE.
    */
    /**
     * @module Rematrix
     */

    /**
     * Transformation matrices in the browser come in two flavors:
     *
     *  - `matrix` using 6 values (short)
     *  - `matrix3d` using 16 values (long)
     *
     * This utility follows this [conversion guide](https://goo.gl/EJlUQ1)
     * to expand short form matrices to their equivalent long form.
     *
     * @param  {array} source - Accepts both short and long form matrices.
     * @return {array}
     */
    function format(source) {
      if (source.constructor !== Array) {
        throw new TypeError('Expected array.')
      }
      if (source.length === 16) {
        return source
      }
      if (source.length === 6) {
        var matrix = identity();
        matrix[0] = source[0];
        matrix[1] = source[1];
        matrix[4] = source[2];
        matrix[5] = source[3];
        matrix[12] = source[4];
        matrix[13] = source[5];
        return matrix
      }
      throw new RangeError('Expected array with either 6 or 16 values.')
    }

    /**
     * Returns a matrix representing no transformation. The product of any matrix
     * multiplied by the identity matrix will be the original matrix.
     *
     * > **Tip:** Similar to how `5 * 1 === 5`, where `1` is the identity.
     *
     * @return {array}
     */
    function identity() {
      var matrix = [];
      for (var i = 0; i < 16; i++) {
        i % 5 == 0 ? matrix.push(1) : matrix.push(0);
      }
      return matrix
    }

    /**
     * Returns a 4x4 matrix describing the combined transformations
     * of both arguments.
     *
     * > **Note:** Order is very important. For example, rotating 45°
     * along the Z-axis, followed by translating 500 pixels along the
     * Y-axis... is not the same as translating 500 pixels along the
     * Y-axis, followed by rotating 45° along on the Z-axis.
     *
     * @param  {array} m - Accepts both short and long form matrices.
     * @param  {array} x - Accepts both short and long form matrices.
     * @return {array}
     */
    function multiply(m, x) {
      var fm = format(m);
      var fx = format(x);
      var product = [];

      for (var i = 0; i < 4; i++) {
        var row = [fm[i], fm[i + 4], fm[i + 8], fm[i + 12]];
        for (var j = 0; j < 4; j++) {
          var k = j * 4;
          var col = [fx[k], fx[k + 1], fx[k + 2], fx[k + 3]];
          var result =
            row[0] * col[0] + row[1] * col[1] + row[2] * col[2] + row[3] * col[3];

          product[i + k] = result;
        }
      }

      return product
    }

    /**
     * Attempts to return a 4x4 matrix describing the CSS transform
     * matrix passed in, but will return the identity matrix as a
     * fallback.
     *
     * **Tip:** In virtually all cases, this method is used to convert
     * a CSS matrix (retrieved as a `string` from computed styles) to
     * its equivalent array format.
     *
     * @param  {string} source - String containing a valid CSS `matrix` or `matrix3d` property.
     * @return {array}
     */
    function parse(source) {
      if (typeof source === 'string') {
        var match = source.match(/matrix(3d)?\(([^)]+)\)/);
        if (match) {
          var raw = match[2].split(', ').map(parseFloat);
          return format(raw)
        }
      }
      return identity()
    }

    /**
     * Returns a 4x4 matrix describing X-axis scaling.
     *
     * @param  {number} scalar - Decimal multiplier.
     * @return {array}
     */
    function scaleX(scalar) {
      var matrix = identity();
      matrix[0] = scalar;
      return matrix
    }

    /**
     * Returns a 4x4 matrix describing Y-axis scaling.
     *
     * @param  {number} scalar - Decimal multiplier.
     * @return {array}
     */
    function scaleY(scalar) {
      var matrix = identity();
      matrix[5] = scalar;
      return matrix
    }

    /**
     * Returns a 4x4 matrix describing X-axis translation.
     *
     * @param  {number} distance - Measured in pixels.
     * @return {array}
     */
    function translateX(distance) {
      var matrix = identity();
      matrix[12] = distance;
      return matrix
    }

    /**
     * Returns a 4x4 matrix describing Y-axis translation.
     *
     * @param  {number} distance - Measured in pixels.
     * @return {array}
     */
    function translateY(distance) {
      var matrix = identity();
      matrix[13] = distance;
      return matrix
    }

    var isNumber = function (x) { return typeof x === 'number'; };
    var isFunction = function (x) { return typeof x === 'function'; };
    var isObject = function (x) {
        return Object.prototype.toString.call(x) === '[object Object]';
    };
    var toArray = function (arrayLike) {
        return Array.prototype.slice.apply(arrayLike);
    };
    var getDuplicateValsAsStrings = function (arr) {
        var baseObj = {};
        var obj = arr.reduce(function (acc, curr) {
            acc[curr] = (acc[curr] || 0) + 1;
            return acc;
        }, baseObj);
        return Object.keys(obj).filter(function (val) { return obj[val] > 1; });
    };
    // tslint only likes this with a regular function, not an arrow function
    function assign(target) {
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        args.forEach(function (arg) {
            if (!arg) {
                return;
            }
            // Skip over if undefined or null
            for (var nextKey in arg) {
                // Avoid bugs when hasOwnProperty is shadowed
                if (Object.prototype.hasOwnProperty.call(arg, nextKey)) {
                    target[nextKey] = arg[nextKey];
                }
            }
        });
        return target;
    }

    // adapted from
    // https://github.com/chenglou/react-motion/blob/master/src/presets.js
    var springPresets = {
        noWobble: { stiffness: 200, damping: 26 },
        gentle: { stiffness: 120, damping: 14 },
        veryGentle: { stiffness: 130, damping: 17 },
        wobbly: { stiffness: 180, damping: 12 },
        stiff: { stiffness: 260, damping: 26 }
    };
    function argIsSpringConfig(arg) {
        return isObject(arg);
    }
    var getSpringConfig = function (_a) {
        var _b = _a === void 0 ? {} : _a, flipperSpring = _b.flipperSpring, flippedSpring = _b.flippedSpring;
        var normalizeSpring = function (spring) {
            if (argIsSpringConfig(spring)) {
                return spring;
            }
            else if (Object.keys(springPresets).indexOf(spring) > -1) {
                return springPresets[spring];
            }
            else {
                return {};
            }
        };
        return assign({}, springPresets.noWobble, normalizeSpring(flipperSpring), normalizeSpring(flippedSpring));
    };

    var DATA_FLIP_ID = 'data-flip-id';
    var DATA_INVERSE_FLIP_ID = 'data-inverse-flip-id';
    var DATA_FLIP_CONFIG = 'data-flip-config';
    var DATA_PORTAL_KEY = 'data-portal-key';
    var DATA_EXIT_CONTAINER = 'data-exit-container';
    var DATA_IS_APPEARING = 'data-is-appearing';

    // scoped selector makes sure we're querying inside the right Flipper
    // container, either internally or with the right portal key
    var selectFlipChildIds = function (scopedSelector, selector, flippedIds) {
        var childIds = scopedSelector(selector).map(function (el) { return el.dataset.flipId; });
        // now return an array ordered by the original order in the DOM
        return flippedIds.filter(function (id) { return childIds.indexOf(id) > -1; });
    };
    var baseSelector = "[" + DATA_FLIP_ID + "]:not([" + DATA_IS_APPEARING + "])";
    var filterFlipDescendants = (function (_a) {
        var flipDataDict = _a.flipDataDict, flippedIds = _a.flippedIds, scopedSelector = _a.scopedSelector;
        var levelToChildren = {};
        var buildHierarchy = function (selector, level, oldResult) {
            var newSelector = selector + " " + baseSelector;
            // make sure this is scoped to the Flipper element in case there are
            // mulitiple Flipper elements on the page
            var newResult = selectFlipChildIds(scopedSelector, newSelector, flippedIds);
            var oldLevelChildren = oldResult.filter(function (id) { return newResult.indexOf(id) === -1; });
            levelToChildren[level] = oldLevelChildren;
            oldLevelChildren.forEach(function (childId) {
                if (flipDataDict[childId]) {
                    flipDataDict[childId].level = level;
                }
            });
            if (newResult.length !== 0) {
                buildHierarchy(newSelector, level + 1, newResult);
            }
        };
        // the top level selectChildFlipIds should use the scopedSelector
        buildHierarchy(baseSelector, 0, selectFlipChildIds(scopedSelector, baseSelector, flippedIds));
        // now make sure childIds in each flippedData contains only direct children
        // since to enable nested stagger we want each parent to be able to kick off
        // the animations only for its direct children
        Object.keys(flipDataDict).forEach(function (flipId) {
            var data = flipDataDict[flipId];
            // scope by parent element
            data.childIds = selectFlipChildIds(function (selector) { return toArray(data.element.querySelectorAll(selector)); }, baseSelector, flippedIds);
            data.childIds = data.childIds.filter(function (id) {
                return levelToChildren[data.level + 1] &&
                    levelToChildren[data.level + 1].indexOf(id) > -1;
            });
        });
        return levelToChildren['0'];
    });

    function _typeof(obj) {
      if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
        _typeof = function (obj) {
          return typeof obj;
        };
      } else {
        _typeof = function (obj) {
          return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
        };
      }

      return _typeof(obj);
    }

    function _classCallCheck(instance, Constructor) {
      if (!(instance instanceof Constructor)) {
        throw new TypeError("Cannot call a class as a function");
      }
    }

    function _defineProperties(target, props) {
      for (var i = 0; i < props.length; i++) {
        var descriptor = props[i];
        descriptor.enumerable = descriptor.enumerable || false;
        descriptor.configurable = true;
        if ("value" in descriptor) descriptor.writable = true;
        Object.defineProperty(target, descriptor.key, descriptor);
      }
    }

    function _createClass(Constructor, protoProps, staticProps) {
      if (protoProps) _defineProperties(Constructor.prototype, protoProps);
      if (staticProps) _defineProperties(Constructor, staticProps);
      return Constructor;
    }

    /**
     *  Copyright (c) 2013, Facebook, Inc.
     *  All rights reserved.
     *
     *  This source code is licensed under the BSD-style license found in the
     *  LICENSE file in the root directory of this source tree. An additional grant
     *  of patent rights can be found in the PATENTS file in the same directory.
     *
     *
     */
    var _onFrame;

    if (typeof window !== "undefined") {
      _onFrame = window.requestAnimationFrame;
    }

    _onFrame = _onFrame || function (callback) {
      window.setTimeout(callback, 1000 / 60);
    };

    var _onFrame$1 = _onFrame;

    function onFrame(func) {
      return _onFrame$1(func);
    }
    var start = Date.now();
    var performanceNow = (typeof performance === "undefined" ? "undefined" : _typeof(performance)) === "object" && typeof performance.now === "function" ? function () {
      return performance.now();
    } : function () {
      return Date.now() - start;
    }; // Lop off the first occurence of the reference in the Array.

    function removeFirst(array, item) {
      var idx = array.indexOf(item);
      idx !== -1 && array.splice(idx, 1);
    }

    /**
     * Plays each frame of the SpringSystem on animation
     * timing loop. This is the default type of looper for a new spring system
     * as it is the most common when developing UI.
     * @public
     */

    var AnimationLooper =
    /*#__PURE__*/
    function () {
      function AnimationLooper() {
        _classCallCheck(this, AnimationLooper);
      }

      _createClass(AnimationLooper, [{
        key: "run",
        value: function run() {
          var _this = this;

          onFrame(function () {
            _this.springSystem.loop(performanceNow());
          });
        }
      }]);

      return AnimationLooper;
    }();

    var PhysicsState = function PhysicsState() {
      _classCallCheck(this, PhysicsState);

      this.position = 0;
      this.velocity = 0;
    };
    /**
     * Provides a model of a classical spring acting to
     * resolve a body to equilibrium. Springs have configurable
     * tension which is a force multipler on the displacement of the
     * spring from its rest point or `endValue` as defined by [Hooke's
     * law](http://en.wikipedia.org/wiki/Hooke's_law). Springs also have
     * configurable friction, which ensures that they do not oscillate
     * infinitely. When a Spring is displaced by updating it's resting
     * or `currentValue`, the SpringSystems that contain that Spring
     * will automatically start looping to solve for equilibrium. As each
     * timestep passes, `SpringListener` objects attached to the Spring
     * will be notified of the updates providing a way to drive an
     * animation off of the spring's resolution curve.
     * @public
     */


    var Spring =
    /*#__PURE__*/
    function () {
      function Spring(springSystem) {
        _classCallCheck(this, Spring);

        this._id = "s" + Spring._ID++;
        this._springSystem = springSystem;
        this.listeners = [];
        this._startValue = 0;
        this._currentState = new PhysicsState();
        this._displacementFromRestThreshold = 0.001;
        this._endValue = 0;
        this._overshootClampingEnabled = false;
        this._previousState = new PhysicsState();
        this._restSpeedThreshold = 0.001;
        this._tempState = new PhysicsState();
        this._timeAccumulator = 0;
        this._wasAtRest = true;
      }

      _createClass(Spring, [{
        key: "getId",
        value: function getId() {
          return this._id;
        }
        /**
         * Remove a Spring from simulation and clear its listeners.
         * @public
         */

      }, {
        key: "destroy",
        value: function destroy() {
          this.listeners = [];

          this._springSystem.deregisterSpring(this);
        }
        /**
         * Set the configuration values for this Spring. A SpringConfig
         * contains the tension and friction values used to solve for the
         * equilibrium of the Spring in the physics loop.
         * @public
         */

      }, {
        key: "setSpringConfig",
        value: function setSpringConfig(springConfig) {
          this._springConfig = springConfig;
          return this;
        }
        /**
         * Retrieve the current value of the Spring.
         * @public
         */

      }, {
        key: "getCurrentValue",
        value: function getCurrentValue() {
          return this._currentState.position;
        }
        /**
         * Get the absolute distance of the Spring from a given state value
         */

      }, {
        key: "getDisplacementDistanceForState",
        value: function getDisplacementDistanceForState(state) {
          return Math.abs(this._endValue - state.position);
        }
        /**
         * Set the endValue or resting position of the spring. If this
         * value is different than the current value, the SpringSystem will
         * be notified and will begin running its solver loop to resolve
         * the Spring to equilibrium. Any listeners that are registered
         * for onSpringEndStateChange will also be notified of this update
         * immediately.
         * @public
         */

      }, {
        key: "setEndValue",
        value: function setEndValue(endValue) {
          if (this._endValue === endValue && this.isAtRest()) {
            return this;
          }

          this._startValue = this.getCurrentValue();
          this._endValue = endValue;

          this._springSystem.activateSpring(this.getId());

          for (var i = 0, len = this.listeners.length; i < len; i++) {
            var listener = this.listeners[i];
            var onChange = listener.onSpringEndStateChange;
            onChange && onChange(this);
          }

          return this;
        }
        /**
         * Set the current velocity of the Spring, in pixels per second. As
         * previously mentioned, this can be useful when you are performing
         * a direct manipulation gesture. When a UI element is released you
         * may call setVelocity on its animation Spring so that the Spring
         * continues with the same velocity as the gesture ended with. The
         * friction, tension, and displacement of the Spring will then
         * govern its motion to return to rest on a natural feeling curve.
         * @public
         */

      }, {
        key: "setVelocity",
        value: function setVelocity(velocity) {
          if (velocity === this._currentState.velocity) {
            return this;
          }

          this._currentState.velocity = velocity;

          this._springSystem.activateSpring(this.getId());

          return this;
        }
        /**
         * Enable overshoot clamping. This means that the Spring will stop
         * immediately when it reaches its resting position regardless of
         * any existing momentum it may have. This can be useful for certain
         * types of animations that should not oscillate such as a scale
         * down to 0 or alpha fade.
         * @public
         */

      }, {
        key: "setOvershootClampingEnabled",
        value: function setOvershootClampingEnabled(enabled) {
          this._overshootClampingEnabled = enabled;
          return this;
        }
        /**
         * Check if the Spring has gone past its end point by comparing
         * the direction it was moving in when it started to the current
         * position and end value.
         * @public
         */

      }, {
        key: "isOvershooting",
        value: function isOvershooting() {
          var start = this._startValue;
          var end = this._endValue;
          return this._springConfig.tension > 0 && (start < end && this.getCurrentValue() > end || start > end && this.getCurrentValue() < end);
        }
        /**
         * The main solver method for the Spring. It takes
         * the current time and delta since the last time step and performs
         * an RK4 integration to get the new position and velocity state
         * for the Spring based on the tension, friction, velocity, and
         * displacement of the Spring.
         * @public
         */

      }, {
        key: "advance",
        value: function advance(time, realDeltaTime) {
          var isAtRest = this.isAtRest();

          if (isAtRest && this._wasAtRest) {
            return;
          }

          var adjustedDeltaTime = realDeltaTime;

          if (realDeltaTime > Spring.MAX_DELTA_TIME_SEC) {
            adjustedDeltaTime = Spring.MAX_DELTA_TIME_SEC;
          }

          this._timeAccumulator += adjustedDeltaTime;
          var tension = this._springConfig.tension;
          var friction = this._springConfig.friction;
          var position = this._currentState.position;
          var velocity = this._currentState.velocity;
          var tempPosition = this._tempState.position;
          var tempVelocity = this._tempState.velocity;
          var aVelocity;
          var aAcceleration;
          var bVelocity;
          var bAcceleration;
          var cVelocity;
          var cAcceleration;
          var dVelocity;
          var dAcceleration;
          var dxdt;
          var dvdt;

          while (this._timeAccumulator >= Spring.SOLVER_TIMESTEP_SEC) {
            this._timeAccumulator -= Spring.SOLVER_TIMESTEP_SEC;

            if (this._timeAccumulator < Spring.SOLVER_TIMESTEP_SEC) {
              this._previousState.position = position;
              this._previousState.velocity = velocity;
            }

            aVelocity = velocity;
            aAcceleration = tension * (this._endValue - tempPosition) - friction * velocity;
            tempPosition = position + aVelocity * Spring.SOLVER_TIMESTEP_SEC * 0.5;
            tempVelocity = velocity + aAcceleration * Spring.SOLVER_TIMESTEP_SEC * 0.5;
            bVelocity = tempVelocity;
            bAcceleration = tension * (this._endValue - tempPosition) - friction * tempVelocity;
            tempPosition = position + bVelocity * Spring.SOLVER_TIMESTEP_SEC * 0.5;
            tempVelocity = velocity + bAcceleration * Spring.SOLVER_TIMESTEP_SEC * 0.5;
            cVelocity = tempVelocity;
            cAcceleration = tension * (this._endValue - tempPosition) - friction * tempVelocity;
            tempPosition = position + cVelocity * Spring.SOLVER_TIMESTEP_SEC;
            tempVelocity = velocity + cAcceleration * Spring.SOLVER_TIMESTEP_SEC;
            dVelocity = tempVelocity;
            dAcceleration = tension * (this._endValue - tempPosition) - friction * tempVelocity;
            dxdt = 1.0 / 6.0 * (aVelocity + 2.0 * (bVelocity + cVelocity) + dVelocity);
            dvdt = 1.0 / 6.0 * (aAcceleration + 2.0 * (bAcceleration + cAcceleration) + dAcceleration);
            position += dxdt * Spring.SOLVER_TIMESTEP_SEC;
            velocity += dvdt * Spring.SOLVER_TIMESTEP_SEC;
          }

          this._tempState.position = tempPosition;
          this._tempState.velocity = tempVelocity;
          this._currentState.position = position;
          this._currentState.velocity = velocity;

          if (this._timeAccumulator > 0) {
            this._interpolate(this._timeAccumulator / Spring.SOLVER_TIMESTEP_SEC);
          }

          if (this.isAtRest() || this._overshootClampingEnabled && this.isOvershooting()) {
            if (this._springConfig.tension > 0) {
              this._startValue = this._endValue;
              this._currentState.position = this._endValue;
            } else {
              this._endValue = this._currentState.position;
              this._startValue = this._endValue;
            }

            this.setVelocity(0);
            isAtRest = true;
          }

          var notifyActivate = false;

          if (this._wasAtRest) {
            this._wasAtRest = false;
            notifyActivate = true;
          }

          var notifyAtRest = false;

          if (isAtRest) {
            this._wasAtRest = true;
            notifyAtRest = true;
          }

          this.notifyPositionUpdated(notifyActivate, notifyAtRest);
        }
      }, {
        key: "notifyPositionUpdated",
        value: function notifyPositionUpdated(notifyActivate, notifyAtRest) {
          for (var i = 0, len = this.listeners.length; i < len; i++) {
            var listener = this.listeners[i];

            if (notifyActivate && listener.onSpringActivate) {
              listener.onSpringActivate(this);
            }

            if (listener.onSpringUpdate) {
              listener.onSpringUpdate(this);
            }

            if (notifyAtRest && listener.onSpringAtRest) {
              listener.onSpringAtRest(this);
            }
          }
        }
        /**
         * Check if the SpringSystem should advance. Springs are advanced
         * a final frame after they reach equilibrium to ensure that the
         * currentValue is exactly the requested endValue regardless of the
         * displacement threshold.
         * @public
         */

      }, {
        key: "systemShouldAdvance",
        value: function systemShouldAdvance() {
          return !this.isAtRest() || !this.wasAtRest();
        }
      }, {
        key: "wasAtRest",
        value: function wasAtRest() {
          return this._wasAtRest;
        }
        /**
         * Check if the Spring is atRest meaning that it's currentValue and
         * endValue are the same and that it has no velocity. The previously
         * described thresholds for speed and displacement define the bounds
         * of this equivalence check. If the Spring has 0 tension, then it will
         * be considered at rest whenever its absolute velocity drops below the
         * restSpeedThreshold.
         * @public
         */

      }, {
        key: "isAtRest",
        value: function isAtRest() {
          return Math.abs(this._currentState.velocity) < this._restSpeedThreshold && (this.getDisplacementDistanceForState(this._currentState) <= this._displacementFromRestThreshold || this._springConfig.tension === 0);
        }
      }, {
        key: "_interpolate",
        value: function _interpolate(alpha) {
          this._currentState.position = this._currentState.position * alpha + this._previousState.position * (1 - alpha);
          this._currentState.velocity = this._currentState.velocity * alpha + this._previousState.velocity * (1 - alpha);
        }
      }, {
        key: "addListener",
        value: function addListener(newListener) {
          this.listeners.push(newListener);
          return this;
        }
      }, {
        key: "removeListener",
        value: function removeListener(listenerToRemove) {
          removeFirst(this.listeners, listenerToRemove);
          return this;
        }
      }]);

      return Spring;
    }();

    Spring._ID = 0;
    Spring.MAX_DELTA_TIME_SEC = 0.064;
    Spring.SOLVER_TIMESTEP_SEC = 0.001;

    /**
     * A set of Springs that all run on the same physics
     * timing loop. To get started with a Rebound animation, first
     * create a new SpringSystem and then add springs to it.
     * @public
     */

    var SpringSystem =
    /*#__PURE__*/
    function () {
      function SpringSystem(looper) {
        _classCallCheck(this, SpringSystem);

        this.looper = looper || new AnimationLooper();
        this.looper.springSystem = this;
        this.listeners = [];
        this._activeSprings = [];
        this._idleSpringIndices = [];
        this._isIdle = true;
        this._lastTimeMillis = -1;
        this._springRegistry = {};
      }
      /**
       * Add a new spring to this SpringSystem. This Spring will now be solved for
       * during the physics iteration loop. By default the spring will use the
       * default Origami spring config with 40 tension and 7 friction, but you can
       * also provide your own values here.
       * @public
       */


      _createClass(SpringSystem, [{
        key: "createSpring",
        value: function createSpring(tension, friction) {
          return this.createSpringWithConfig({
            tension: tension,
            friction: friction
          });
        }
        /**
         * Add a spring with the provided SpringConfig.
         * @public
         */

      }, {
        key: "createSpringWithConfig",
        value: function createSpringWithConfig(springConfig) {
          var spring = new Spring(this);
          this.registerSpring(spring);
          spring.setSpringConfig(springConfig);
          return spring;
        }
        /**
         * Check if a SpringSystem is idle or active. If all of the Springs in the
         * SpringSystem are at rest, i.e. the physics forces have reached equilibrium,
         * then this method will return true.
         * @public
         */

      }, {
        key: "getIsIdle",
        value: function getIsIdle() {
          return this._isIdle;
        }
        /**
         * Manually add a spring to this system. This is called automatically
         * if a Spring is created with SpringSystem#createSpring.
         *
         * This method sets the spring up in the registry so that it can be solved
         * in the solver loop.
         * @public
         */

      }, {
        key: "registerSpring",
        value: function registerSpring(spring) {
          this._springRegistry[spring.getId()] = spring;
        }
        /**
         * Deregister a spring with this SpringSystem. The SpringSystem will
         * no longer consider this Spring during its integration loop once
         * this is called. This is normally done automatically for you when
         * you call Spring#destroy.
         * @public
         */

      }, {
        key: "deregisterSpring",
        value: function deregisterSpring(spring) {
          removeFirst(this._activeSprings, spring);
          delete this._springRegistry[spring.getId()];
        }
      }, {
        key: "advance",
        value: function advance(time, deltaTime) {
          var _this = this;

          while (this._idleSpringIndices.length > 0) {
            this._idleSpringIndices.pop();
          }

          this._activeSprings.filter(Boolean).forEach(function (spring) {
            if (spring.systemShouldAdvance()) {
              spring.advance(time / 1000.0, deltaTime / 1000.0);
            } else {
              _this._idleSpringIndices.push(_this._activeSprings.indexOf(spring));
            }
          });

          while (this._idleSpringIndices.length > 0) {
            var idx = this._idleSpringIndices.pop();

            idx >= 0 && this._activeSprings.splice(idx, 1);
          }
        }
        /**
         * This is the main solver loop called to move the simulation
         * forward through time. Before each pass in the solver loop
         * onBeforeIntegrate is called on an any listeners that have
         * registered themeselves with the SpringSystem. This gives you
         * an opportunity to apply any constraints or adjustments to
         * the springs that should be enforced before each iteration
         * loop. Next the advance method is called to move each Spring in
         * the systemShouldAdvance forward to the current time. After the
         * integration step runs in advance, onAfterIntegrate is called
         * on any listeners that have registered themselves with the
         * SpringSystem. This gives you an opportunity to run any post
         * integration constraints or adjustments on the Springs in the
         * SpringSystem.
         * @public
         */

      }, {
        key: "loop",
        value: function loop(currentTimeMillis) {
          var listener;

          if (this._lastTimeMillis === -1) {
            this._lastTimeMillis = currentTimeMillis - 1;
          }

          var ellapsedMillis = currentTimeMillis - this._lastTimeMillis;
          this._lastTimeMillis = currentTimeMillis;
          var i = 0;
          var len = this.listeners.length;

          for (i = 0; i < len; i++) {
            listener = this.listeners[i];
            listener.onBeforeIntegrate && listener.onBeforeIntegrate(this);
          }

          this.advance(currentTimeMillis, ellapsedMillis);

          if (this._activeSprings.length === 0) {
            this._isIdle = true;
            this._lastTimeMillis = -1;
          }

          for (i = 0; i < len; i++) {
            listener = this.listeners[i];
            listener.onAfterIntegrate && listener.onAfterIntegrate(this);
          }

          if (!this._isIdle) {
            this.looper.run();
          }
        }
        /**
         * Used to notify the SpringSystem that a Spring has become displaced.
         * The system responds by starting its solver loop up if it is currently idle.
         */

      }, {
        key: "activateSpring",
        value: function activateSpring(springId) {
          var spring = this._springRegistry[springId];

          if (this._activeSprings.indexOf(spring) === -1) {
            this._activeSprings.push(spring);
          }

          if (this.getIsIdle()) {
            this._isIdle = false;
            this.looper.run();
          }
        }
      }]);

      return SpringSystem;
    }();

    // this should get created only 1x
    var springSystem = new SpringSystem();
    var createSuspendedSpring = function (_a) {
        var _b = _a.springConfig, stiffness = _b.stiffness, damping = _b.damping, overshootClamping = _b.overshootClamping, noOp = _a.noOp, onSpringActivate = _a.onSpringActivate, getOnUpdateFunc = _a.getOnUpdateFunc, onAnimationEnd = _a.onAnimationEnd;
        if (noOp) {
            return null;
        }
        var spring = springSystem.createSpring(stiffness, damping);
        spring.setOvershootClampingEnabled(!!overshootClamping);
        spring.addListener({
            onSpringActivate: onSpringActivate,
            onSpringUpdate: getOnUpdateFunc(spring.destroy.bind(spring)),
            onSpringAtRest: function () {
                // prevent SpringSystem from caching unused springs
                spring.destroy();
                onAnimationEnd();
            }
        });
        return spring;
    };
    var createSpring = function (flipped) {
        var spring = createSuspendedSpring(flipped);
        if (spring) {
            spring.setEndValue(1);
        }
        else {
            // even if it was a noop,
            // we still need to call onSpringActivate in case it calls
            // cascading flip initiation functions
            flipped.onSpringActivate();
        }
    };
    var normalizeSpeed = function (speedConfig) {
        if (typeof speedConfig !== 'number')
            return 1.1;
        return 1 + Math.min(Math.max(speedConfig * 5, 0), 5);
    };
    var staggeredSprings = function (flippedArray, staggerConfig) {
        if (staggerConfig === void 0) { staggerConfig = {}; }
        if (!flippedArray || !flippedArray.length) {
            return;
        }
        if (staggerConfig.reverse) {
            flippedArray.reverse();
        }
        var normalizedSpeed = normalizeSpeed(staggerConfig.speed);
        var nextThreshold = 1 / Math.max(Math.min(flippedArray.length, 100), 10);
        var springFuncs = flippedArray
            .filter(function (flipped) { return !flipped.noOp; })
            .map(function (flipped, i) {
            var cachedGetOnUpdate = flipped.getOnUpdateFunc;
            // modify the update function to adjust
            // the end value of the trailing Flipped component
            flipped.getOnUpdateFunc = function (stop) {
                var onUpdate = cachedGetOnUpdate(stop);
                return function (spring) {
                    var currentValue = spring.getCurrentValue();
                    if (currentValue > nextThreshold) {
                        if (springFuncs[i + 1]) {
                            springFuncs[i + 1].setEndValue(Math.min(currentValue * normalizedSpeed, 1));
                        }
                    }
                    // now call the actual update function
                    onUpdate(spring);
                };
            };
            return flipped;
        })
            .map(function (flipped) { return createSuspendedSpring(flipped); });
        if (springFuncs[0]) {
            springFuncs[0].setEndValue(1);
        }
    };

    var initiateImmediateAnimations = function (immediate) {
        if (!immediate) {
            return;
        }
        immediate.forEach(function (flipped) {
            createSpring(flipped);
            initiateImmediateAnimations(flipped.immediateChildren);
        });
    };
    var createCallTree = function (_a) {
        var flipDataDict = _a.flipDataDict, topLevelChildren = _a.topLevelChildren, initiateStaggeredAnimations = _a.initiateStaggeredAnimations;
        // build a data struct to run the springs
        var tree = {
            root: {
                staggeredChildren: {},
                immediateChildren: []
            }
        };
        // helper function to build the nested structure
        var appendChild = function (parent, childId) {
            var flipData = flipDataDict[childId];
            // might have been filtered (e.g. because it was off screen)
            if (!flipData) {
                return;
            }
            if (flipData.stagger) {
                parent.staggeredChildren[flipData.stagger]
                    ? parent.staggeredChildren[flipData.stagger].push(flipData)
                    : (parent.staggeredChildren[flipData.stagger] = [flipData]);
            }
            else {
                parent.immediateChildren.push(flipData);
            }
            // only when the spring is first activated, activate the child animations as well
            // this enables nested stagger
            flipData.onSpringActivate = function () {
                initiateImmediateAnimations(flipData.immediateChildren);
                initiateStaggeredAnimations(flipData.staggeredChildren);
            };
            flipData.staggeredChildren = {};
            flipData.immediateChildren = [];
            flipData.childIds.forEach(function (childId) { return appendChild(flipData, childId); });
        };
        // create the nested structure
        topLevelChildren.forEach(function (c) {
            appendChild(tree.root, c);
        });
        return tree;
    };
    var initiateAnimations = (function (_a) {
        var staggerConfig = _a.staggerConfig, flipDataDict = _a.flipDataDict, topLevelChildren = _a.topLevelChildren;
        var initiateStaggeredAnimations = function (staggered) {
            if (!staggered || !Object.keys(staggered).length) {
                return;
            }
            Object.keys(staggered).forEach(function (staggerKey) {
                return staggeredSprings(staggered[staggerKey], staggerConfig[staggerKey]);
            });
        };
        var tree = createCallTree({
            flipDataDict: flipDataDict,
            topLevelChildren: topLevelChildren,
            initiateStaggeredAnimations: initiateStaggeredAnimations
        });
        initiateImmediateAnimations(tree.root.immediateChildren);
        initiateStaggeredAnimations(tree.root.staggeredChildren);
    });

    // 3d transforms were causing weird issues in chrome,
    // especially when opacity was also being tweened,
    // so convert to a 2d matrix
    var convertMatrix3dArrayTo2dArray = function (matrix) {
        return [0, 1, 4, 5, 12, 13].map(function (index) { return matrix[index]; });
    };
    var convertMatrix2dArrayToString = function (matrix) {
        return "matrix(" + matrix.join(', ') + ")";
    };
    var invertTransformsForChildren = function (_a) {
        var invertedChildren = _a.invertedChildren, matrix = _a.matrix, body = _a.body;
        invertedChildren.forEach(function (_a) {
            var child = _a[0], childFlipConfig = _a[1];
            if (!body.contains(child)) {
                return;
            }
            var scaleX = matrix[0];
            var scaleY = matrix[3];
            var translateX = matrix[4];
            var translateY = matrix[5];
            var inverseVals = { translateX: 0, translateY: 0, scaleX: 1, scaleY: 1 };
            var transformString = '';
            if (childFlipConfig.translate) {
                inverseVals.translateX = -translateX / scaleX;
                inverseVals.translateY = -translateY / scaleY;
                transformString += "translate(" + inverseVals.translateX + "px, " + inverseVals.translateY + "px)";
            }
            if (childFlipConfig.scale) {
                inverseVals.scaleX = 1 / scaleX;
                inverseVals.scaleY = 1 / scaleY;
                transformString += " scale(" + inverseVals.scaleX + ", " + inverseVals.scaleY + ")";
            }
            child.style.transform = transformString;
        });
    };
    var createApplyStylesFunc = function (_a) {
        var element = _a.element, invertedChildren = _a.invertedChildren, body = _a.body, retainTransform = _a.retainTransform;
        return function (_a) {
            var matrix = _a.matrix, opacity = _a.opacity, forceMinVals = _a.forceMinVals;
            if (isNumber(opacity)) {
                element.style.opacity = opacity + '';
            }
            if (forceMinVals) {
                element.style.minHeight = '1px';
                element.style.minWidth = '1px';
            }
            if (!matrix) {
                return;
            }
            var identityTransform = 'matrix(1, 0, 0, 1, 0, 0)';
            var transformWithInvisibleSkew = 'matrix(1, 0.00001, -0.00001, 1, 0, 0)';
            var stringTransform = convertMatrix2dArrayToString(matrix);
            if (retainTransform && stringTransform === identityTransform) {
                stringTransform = transformWithInvisibleSkew;
            }
            element.style.transform = stringTransform;
            if (invertedChildren) {
                invertTransformsForChildren({
                    invertedChildren: invertedChildren,
                    matrix: matrix,
                    body: body
                });
            }
        };
    };
    var rectInViewport = function (_a) {
        var top = _a.top, bottom = _a.bottom, left = _a.left, right = _a.right;
        return (top < window.innerHeight &&
            bottom > 0 &&
            left < window.innerWidth &&
            right > 0);
    };
    var getInvertedChildren = function (element, id) {
        return toArray(element.querySelectorAll("[" + DATA_INVERSE_FLIP_ID + "=\"" + id + "\"]"));
    };
    var tweenProp = function (start, end, position) {
        return start + (end - start) * position;
    };
    var animateFlippedElements = (function (_a) {
        var flippedIds = _a.flippedIds, flipCallbacks = _a.flipCallbacks, inProgressAnimations = _a.inProgressAnimations, flippedElementPositionsBeforeUpdate = _a.flippedElementPositionsBeforeUpdate, flippedElementPositionsAfterUpdate = _a.flippedElementPositionsAfterUpdate, applyTransformOrigin = _a.applyTransformOrigin, spring = _a.spring, getElement = _a.getElement, debug = _a.debug, staggerConfig = _a.staggerConfig, _b = _a.decisionData, decisionData = _b === void 0 ? {} : _b, scopedSelector = _a.scopedSelector, retainTransform = _a.retainTransform, onComplete = _a.onComplete;
        // the stuff below is used so we can return a promise that resolves when all FLIP animations have
        // completed
        var closureResolve;
        var flipCompletedPromise = new Promise(function (resolve) {
            closureResolve = resolve;
        });
        // hook for users of lib to attach logic when all flip animations have completed
        if (onComplete) {
            flipCompletedPromise.then(onComplete);
        }
        if (!flippedIds.length) {
            return function () {
                closureResolve([]);
                return flipCompletedPromise;
            };
        }
        var withInitFuncs;
        var completedAnimationIds = [];
        var firstElement = getElement(flippedIds[0]);
        // special handling for iframes
        var body = firstElement
            ? firstElement.ownerDocument.querySelector('body')
            : document.querySelector('body');
        if (debug) {
            // eslint-disable-next-line no-console
            console.error('[react-flip-toolkit]\nThe "debug" prop is set to true. All FLIP animations will return at the beginning of the transition.');
        }
        var duplicateFlipIds = getDuplicateValsAsStrings(flippedIds);
        if (duplicateFlipIds.length) {
            // eslint-disable-next-line no-console
            console.error("[react-flip-toolkit]\nThere are currently multiple elements with the same flipId on the page.\nThe animation will only work if each Flipped component has a unique flipId.\nDuplicate flipId" + (duplicateFlipIds.length > 1 ? 's' : '') + ": " + duplicateFlipIds.join('\n'));
        }
        var flipDataArray = flippedIds
            // take all the measurements we need
            // and return an object with animation functions + necessary data
            .map(function (id) {
            var prevRect = flippedElementPositionsBeforeUpdate[id].rect;
            var currentRect = flippedElementPositionsAfterUpdate[id].rect;
            var prevOpacity = flippedElementPositionsBeforeUpdate[id].opacity;
            var currentOpacity = flippedElementPositionsAfterUpdate[id].opacity;
            var needsForcedMinVals = currentRect.width < 1 || currentRect.height < 1;
            // don't animate elements outside of the user's viewport
            if (!rectInViewport(prevRect) && !rectInViewport(currentRect)) {
                return false;
            }
            // it's never going to be visible, so dont animate it
            if ((prevRect.width === 0 && currentRect.width === 0) ||
                (prevRect.height === 0 && currentRect.height === 0)) {
                return false;
            }
            var element = getElement(id);
            // this might happen if we are rapidly adding & removing elements(?)
            if (!element) {
                return false;
            }
            var flipConfig = JSON.parse(element.dataset.flipConfig);
            var springConfig = getSpringConfig({
                flipperSpring: spring,
                flippedSpring: flipConfig.spring
            });
            var stagger = flipConfig.stagger === true ? 'default' : flipConfig.stagger;
            var toReturn = {
                element: element,
                id: id,
                stagger: stagger,
                springConfig: springConfig,
                noOp: true
            };
            if (flipCallbacks[id] && flipCallbacks[id].shouldFlip) {
                var elementShouldFlip = flipCallbacks[id].shouldFlip(decisionData.prev, decisionData.current);
                // this element wont be animated, but its children might be
                if (!elementShouldFlip) {
                    return toReturn;
                }
            }
            // don't animate elements that didn't visbly change
            // but possibly animate their children
            var transformDifference = Math.abs(prevRect.left - currentRect.left) +
                Math.abs(prevRect.top - currentRect.top);
            var sizeDifference = Math.abs(prevRect.width - currentRect.width) +
                Math.abs(prevRect.height - currentRect.height);
            var opacityDifference = Math.abs(currentOpacity - prevOpacity);
            if (transformDifference < 0.5 &&
                sizeDifference < 0.5 &&
                opacityDifference < 0.01) {
                // this element wont be animated, but its children might be
                return toReturn;
            }
            toReturn.noOp = false;
            var currentTransform = parse(flippedElementPositionsAfterUpdate[id].transform);
            var toVals = { matrix: currentTransform };
            var fromVals = { matrix: [] };
            var transformsArray = [currentTransform];
            // we're only going to animate the values that the child wants animated
            if (flipConfig.translate) {
                transformsArray.push(translateX(prevRect.left - currentRect.left));
                transformsArray.push(translateY(prevRect.top - currentRect.top));
            }
            // going any smaller than 1px breaks transitions in Chrome
            if (flipConfig.scale) {
                transformsArray.push(scaleX(Math.max(prevRect.width, 1) / Math.max(currentRect.width, 1)));
                transformsArray.push(scaleY(Math.max(prevRect.height, 1) / Math.max(currentRect.height, 1)));
            }
            if (flipConfig.opacity) {
                fromVals.opacity = prevOpacity;
                toVals.opacity = currentOpacity;
            }
            var invertedChildren = [];
            if (!flipCallbacks[id] ||
                !flipCallbacks[id].shouldInvert ||
                flipCallbacks[id].shouldInvert(decisionData.prev, decisionData.current)) {
                var invertedChildElements = getInvertedChildren(element, id);
                invertedChildren = invertedChildElements.map(function (c) { return [
                    c,
                    JSON.parse(c.dataset.flipConfig)
                ]; });
            }
            fromVals.matrix = convertMatrix3dArrayTo2dArray(transformsArray.reduce(multiply));
            toVals.matrix = convertMatrix3dArrayTo2dArray(toVals.matrix);
            var applyStyles = createApplyStylesFunc({
                element: element,
                invertedChildren: invertedChildren,
                body: body,
                retainTransform: retainTransform
            });
            var onComplete;
            if (flipCallbacks[id] && flipCallbacks[id].onComplete) {
                // must cache or else this could cause an error
                var cachedOnComplete_1 = flipCallbacks[id].onComplete;
                onComplete = function () {
                    return cachedOnComplete_1(element, decisionData.prev, decisionData.current);
                };
            }
            // this should be called when animation ends naturally
            // but also when it is interrupted
            // when it is called, the animation has already been cancelled
            var onAnimationEnd = function () {
                delete inProgressAnimations[id];
                if (isFunction(onComplete)) {
                    onComplete();
                }
                // remove identity transform -- this should have no effect on layout
                element.style.transform = '';
                if (needsForcedMinVals && element) {
                    element.style.minHeight = '';
                    element.style.minWidth = '';
                }
                completedAnimationIds.push(id);
                if (completedAnimationIds.length >= withInitFuncs.length) {
                    // we can theoretically call multiple times since a promise only resolves 1x
                    // but that shouldnt happen
                    closureResolve(completedAnimationIds);
                }
            };
            var animateOpacity = isNumber(fromVals.opacity) &&
                isNumber(toVals.opacity) &&
                fromVals.opacity !== toVals.opacity;
            var onStartCalled = false;
            var getOnUpdateFunc = function (stop) {
                inProgressAnimations[id] = {
                    stop: stop,
                    onComplete: onComplete
                };
                var onUpdate = function (spring) {
                    if (flipCallbacks[id] && flipCallbacks[id].onSpringUpdate) {
                        flipCallbacks[id].onSpringUpdate(spring.getCurrentValue());
                    }
                    // trigger the user provided onStart function
                    if (!onStartCalled) {
                        onStartCalled = true;
                        if (flipCallbacks[id] && flipCallbacks[id].onStart) {
                            flipCallbacks[id].onStart(element, decisionData.prev, decisionData.current);
                        }
                    }
                    var currentValue = spring.getCurrentValue();
                    if (!body.contains(element)) {
                        stop();
                        return;
                    }
                    var vals = { matrix: [] };
                    vals.matrix = fromVals.matrix.map(function (fromVal, index) {
                        return tweenProp(fromVal, toVals.matrix[index], currentValue);
                    });
                    if (animateOpacity) {
                        vals.opacity = tweenProp(fromVals.opacity, toVals.opacity, currentValue);
                    }
                    applyStyles(vals);
                };
                return onUpdate;
            };
            var initializeFlip = function () {
                // before animating, immediately apply FLIP styles to prevent flicker
                applyStyles({
                    matrix: fromVals.matrix,
                    opacity: animateOpacity ? fromVals.opacity : undefined,
                    forceMinVals: needsForcedMinVals
                });
                if (flipCallbacks[id] && flipCallbacks[id].onStartImmediate) {
                    flipCallbacks[id].onStartImmediate(element, decisionData.prev, decisionData.current);
                }
                // and batch any other style updates if necessary
                if (flipConfig.transformOrigin) {
                    element.style.transformOrigin = flipConfig.transformOrigin;
                }
                else if (applyTransformOrigin) {
                    element.style.transformOrigin = '0 0';
                }
                invertedChildren.forEach(function (_a) {
                    var child = _a[0], childFlipConfig = _a[1];
                    if (childFlipConfig.transformOrigin) {
                        child.style.transformOrigin = childFlipConfig.transformOrigin;
                    }
                    else if (applyTransformOrigin) {
                        child.style.transformOrigin = '0 0';
                    }
                });
            };
            return assign({}, toReturn, {
                stagger: stagger,
                springConfig: springConfig,
                getOnUpdateFunc: getOnUpdateFunc,
                initializeFlip: initializeFlip,
                onAnimationEnd: onAnimationEnd
            });
        })
            // filter out data for all non-animated elements first
            .filter(function (x) { return x; });
        // we use this array to compare with completed animations
        // to decide when all animations are completed
        withInitFuncs = flipDataArray.filter(function (_a) {
            var initializeFlip = _a.initializeFlip;
            return Boolean(initializeFlip);
        });
        //  put items back in place
        withInitFuncs.forEach(function (_a) {
            var initializeFlip = _a.initializeFlip;
            return initializeFlip();
        });
        if (debug) {
            return function () { };
        }
        var flipDataDict = flipDataArray.reduce(function (acc, curr) {
            acc[curr.id] = curr;
            return acc;
        }, {});
        // this function modifies flipDataDict in-place
        // by removing references to non-direct children
        // to enable recursive stagger
        var topLevelChildren = filterFlipDescendants({
            flipDataDict: flipDataDict,
            flippedIds: flippedIds,
            scopedSelector: scopedSelector
        });
        return function () {
            // there are no active FLIP animations, so immediately resolve the
            // returned promise
            if (!withInitFuncs.length) {
                closureResolve([]);
            }
            initiateAnimations({ topLevelChildren: topLevelChildren, flipDataDict: flipDataDict, staggerConfig: staggerConfig });
            return flipCompletedPromise;
        };
    });

    var addTupleToObject = function (acc, curr) {
        var _a;
        return assign(acc, (_a = {}, _a[curr[0]] = curr[1], _a));
    };
    var getAllElements = function (element, portalKey) {
        if (portalKey) {
            return toArray(document.querySelectorAll("[" + DATA_PORTAL_KEY + "=\"" + portalKey + "\"]"));
        }
        else {
            return toArray(element.querySelectorAll("[" + DATA_FLIP_ID + "]"));
        }
    };

    var getFlippedElementPositionsAfterUpdate = function (_a) {
        var element = _a.element, portalKey = _a.portalKey;
        return (getAllElements(element, portalKey)
            .map(function (child) {
            var computedStyle = window.getComputedStyle(child);
            var rect = child.getBoundingClientRect();
            return [
                child.dataset.flipId,
                {
                    rect: rect,
                    opacity: parseFloat(computedStyle.opacity),
                    transform: computedStyle.transform
                }
            ];
        })
            // @ts-ignore
            .reduce(addTupleToObject, {}));
    };

    var createPortalScopedSelector = function (portalKey) { return function (selector) {
        return toArray(document.querySelectorAll("[" + DATA_PORTAL_KEY + "=\"" + portalKey + "\"]" + selector));
    }; };
    var createFlipperScopedSelector = function (containerEl) {
        var tempFlipperId = Math.random().toFixed(5);
        containerEl.dataset.flipperId = tempFlipperId;
        return function (selector) {
            return toArray(containerEl.querySelectorAll("[data-flipper-id=\"" + tempFlipperId + "\"] " + selector));
        };
    };
    var createScopedSelector = function (_a) {
        var containerEl = _a.containerEl, portalKey = _a.portalKey;
        if (portalKey) {
            return createPortalScopedSelector(portalKey);
        }
        else if (containerEl) {
            return createFlipperScopedSelector(containerEl);
        }
        else {
            return function () { return []; };
        }
    };
    var createGetElementFunc = function (scopedSelector) {
        return function (id) {
            return scopedSelector("[" + DATA_FLIP_ID + "=\"" + id + "\"]")[0];
        };
    };
    var onFlipKeyUpdate = function (_a) {
        var _b = _a.cachedOrderedFlipIds, cachedOrderedFlipIds = _b === void 0 ? [] : _b, _c = _a.inProgressAnimations, inProgressAnimations = _c === void 0 ? {} : _c, _d = _a.flippedElementPositionsBeforeUpdate, flippedElementPositionsBeforeUpdate = _d === void 0 ? {} : _d, _e = _a.flipCallbacks, flipCallbacks = _e === void 0 ? {} : _e, containerEl = _a.containerEl, applyTransformOrigin = _a.applyTransformOrigin, spring = _a.spring, debug = _a.debug, portalKey = _a.portalKey, _f = _a.staggerConfig, staggerConfig = _f === void 0 ? {} : _f, _g = _a.decisionData, decisionData = _g === void 0 ? {} : _g, handleEnterUpdateDelete = _a.handleEnterUpdateDelete, retainTransform = _a.retainTransform, onComplete = _a.onComplete;
        var flippedElementPositionsAfterUpdate = getFlippedElementPositionsAfterUpdate({
            element: containerEl,
            portalKey: portalKey
        });
        var scopedSelector = createScopedSelector({
            containerEl: containerEl,
            portalKey: portalKey
        });
        var getElement = createGetElementFunc(scopedSelector);
        var isFlipped = function (id) {
            return flippedElementPositionsBeforeUpdate[id] &&
                flippedElementPositionsAfterUpdate[id];
        };
        var unflippedIds = Object.keys(flippedElementPositionsBeforeUpdate)
            .concat(Object.keys(flippedElementPositionsAfterUpdate))
            .filter(function (id) { return !isFlipped(id); });
        var baseArgs = {
            flipCallbacks: flipCallbacks,
            getElement: getElement,
            flippedElementPositionsBeforeUpdate: flippedElementPositionsBeforeUpdate,
            flippedElementPositionsAfterUpdate: flippedElementPositionsAfterUpdate,
            inProgressAnimations: inProgressAnimations
        };
        var animateUnFlippedElementsArgs = assign({}, baseArgs, {
            unflippedIds: unflippedIds
        });
        var _h = animateUnflippedElements(animateUnFlippedElementsArgs), hideEnteringElements = _h.hideEnteringElements, animateEnteringElements = _h.animateEnteringElements, animateExitingElements = _h.animateExitingElements;
        var flippedIds = cachedOrderedFlipIds.filter(isFlipped);
        // @ts-ignore
        var animateFlippedElementsArgs = assign({}, baseArgs, {
            flippedIds: flippedIds,
            applyTransformOrigin: applyTransformOrigin,
            spring: spring,
            debug: debug,
            staggerConfig: staggerConfig,
            decisionData: decisionData,
            scopedSelector: scopedSelector,
            retainTransform: retainTransform,
            onComplete: onComplete
        });
        // the function handles putting flipped elements back in their original positions
        // and returns another function to actually call the flip animation
        var flip = animateFlippedElements(animateFlippedElementsArgs);
        // clear temp markup that was added to facilitate FLIP
        // namely, in the filterFlipDescendants function
        var cleanupTempDataAttributes = function () {
            unflippedIds
                .filter(function (id) { return flippedElementPositionsAfterUpdate[id]; })
                .forEach(function (id) {
                var element = getElement(id);
                if (element) {
                    element.removeAttribute(DATA_IS_APPEARING);
                }
            });
        };
        cleanupTempDataAttributes();
        if (handleEnterUpdateDelete) {
            handleEnterUpdateDelete({
                hideEnteringElements: hideEnteringElements,
                animateEnteringElements: animateEnteringElements,
                animateExitingElements: animateExitingElements,
                animateFlippedElements: flip
            });
        }
        else {
            hideEnteringElements();
            animateExitingElements().then(animateEnteringElements);
            flip();
        }
    };

    var cancelInProgressAnimations = function (inProgressAnimations) {
        Object.keys(inProgressAnimations).forEach(function (id) {
            if (inProgressAnimations[id].stop) {
                inProgressAnimations[id].stop();
            }
            delete inProgressAnimations[id];
        });
    };
    var getFlippedElementPositionsBeforeUpdate = function (_a) {
        var element = _a.element, _b = _a.flipCallbacks, flipCallbacks = _b === void 0 ? {} : _b, _c = _a.inProgressAnimations, inProgressAnimations = _c === void 0 ? {} : _c, portalKey = _a.portalKey;
        var flippedElements = getAllElements(element, portalKey);
        var inverseFlippedElements = toArray(element.querySelectorAll("[" + DATA_INVERSE_FLIP_ID + "]"));
        var childIdsToParentBCRs = {};
        var parentBCRs = [];
        var childIdsToParents = {};
        // this is for exit animations so we can re-insert exiting elements in the
        // DOM later
        flippedElements
            .filter(function (el) {
            return flipCallbacks &&
                flipCallbacks[el.dataset.flipId] &&
                flipCallbacks[el.dataset.flipId].onExit;
        })
            .forEach(function (el) {
            var parent = el.parentNode;
            // this won't work for IE11
            if (el.closest) {
                var exitContainer = el.closest("[" + DATA_EXIT_CONTAINER + "]");
                if (exitContainer) {
                    parent = exitContainer;
                }
            }
            var bcrIndex = parentBCRs.findIndex(function (n) { return n[0] === parent; });
            if (bcrIndex === -1) {
                parentBCRs.push([parent, parent.getBoundingClientRect()]);
                bcrIndex = parentBCRs.length - 1;
            }
            childIdsToParentBCRs[el.dataset.flipId] = parentBCRs[bcrIndex][1];
            childIdsToParents[el.dataset.flipId] = parent;
        });
        var flippedElementPositions = flippedElements
            .map(function (child) {
            var domDataForExitAnimations = {};
            var childBCR = child.getBoundingClientRect();
            // only cache extra data for exit animations
            // if the element has an onExit listener
            if (flipCallbacks &&
                flipCallbacks[child.dataset.flipId] &&
                flipCallbacks[child.dataset.flipId].onExit) {
                var parentBCR = childIdsToParentBCRs[child.dataset.flipId];
                assign(domDataForExitAnimations, {
                    element: child,
                    parent: childIdsToParents[child.dataset.flipId],
                    childPosition: {
                        top: childBCR.top - parentBCR.top,
                        left: childBCR.left - parentBCR.left,
                        width: childBCR.width,
                        height: childBCR.height
                    }
                });
            }
            return [
                child.dataset.flipId,
                {
                    rect: childBCR,
                    opacity: parseFloat(window.getComputedStyle(child).opacity || '1'),
                    domDataForExitAnimations: domDataForExitAnimations
                }
            ];
        })
            // @ts-ignore
            .reduce(addTupleToObject, {});
        // do this at the very end since we want to cache positions of elements
        // while they are mid-transition
        cancelInProgressAnimations(inProgressAnimations);
        flippedElements.concat(inverseFlippedElements).forEach(function (el) {
            el.style.transform = '';
            el.style.opacity = '';
        });
        return {
            flippedElementPositions: flippedElementPositions,
            cachedOrderedFlipIds: flippedElements.map(function (el) { return el.dataset.flipId; })
        };
    };

    var FlipContext = React.createContext({});
    var PortalContext = React.createContext('portal');
    var Flipper = /** @class */ (function (_super) {
        __extends(Flipper, _super);
        function Flipper() {
            var _this = _super !== null && _super.apply(this, arguments) || this;
            _this.inProgressAnimations = {};
            _this.flipCallbacks = {};
            _this.el = undefined;
            return _this;
        }
        Flipper.prototype.getSnapshotBeforeUpdate = function (prevProps) {
            if (prevProps.flipKey !== this.props.flipKey && this.el) {
                return getFlippedElementPositionsBeforeUpdate({
                    element: this.el,
                    // if onExit callbacks exist here, we'll cache the DOM node
                    flipCallbacks: this.flipCallbacks,
                    inProgressAnimations: this.inProgressAnimations,
                    portalKey: this.props.portalKey
                });
            }
            return null;
        };
        Flipper.prototype.componentDidUpdate = function (prevProps, _prevState, cachedData) {
            if (this.props.flipKey !== prevProps.flipKey && this.el) {
                onFlipKeyUpdate({
                    flippedElementPositionsBeforeUpdate: cachedData.flippedElementPositions,
                    cachedOrderedFlipIds: cachedData.cachedOrderedFlipIds,
                    containerEl: this.el,
                    inProgressAnimations: this.inProgressAnimations,
                    flipCallbacks: this.flipCallbacks,
                    applyTransformOrigin: this.props.applyTransformOrigin,
                    spring: this.props.spring,
                    debug: this.props.debug,
                    portalKey: this.props.portalKey,
                    staggerConfig: this.props.staggerConfig,
                    handleEnterUpdateDelete: this.props.handleEnterUpdateDelete,
                    // typescript doesn't recognize defaultProps (?)
                    retainTransform: this.props.retainTransform,
                    decisionData: {
                        prev: prevProps.decisionData,
                        current: this.props.decisionData
                    },
                    onComplete: this.props.onComplete
                });
            }
        };
        Flipper.prototype.render = function () {
            var _this = this;
            var _a = this.props, element = _a.element, className = _a.className, portalKey = _a.portalKey;
            var Element = element;
            var FlipperBase = (React__default.createElement(FlipContext.Provider, { value: this.flipCallbacks },
                React__default.createElement(Element, { className: className, ref: function (el) { return (_this.el = el); } }, this.props.children)));
            if (portalKey) {
                return (React__default.createElement(PortalContext.Provider, { value: portalKey }, FlipperBase));
            }
            else {
                return FlipperBase;
            }
        };
        Flipper.defaultProps = {
            applyTransformOrigin: true,
            element: 'div',
            retainTransform: false
        };
        return Flipper;
    }(React.Component));

    var propTypes = {
        children: PropTypes.oneOfType([PropTypes.node, PropTypes.func]).isRequired,
        inverseFlipId: PropTypes.string,
        flipId: PropTypes.string,
        opacity: PropTypes.bool,
        translate: PropTypes.bool,
        scale: PropTypes.bool,
        transformOrigin: PropTypes.string,
        spring: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
        onStart: PropTypes.func,
        onComplete: PropTypes.func,
        onAppear: PropTypes.func,
        onSpringUpdate: PropTypes.func,
        shouldFlip: PropTypes.func,
        shouldInvert: PropTypes.func,
        onExit: PropTypes.func,
        portalKey: PropTypes.string,
        stagger: PropTypes.oneOfType([PropTypes.string, PropTypes.bool])
    };
    function isFunction$1(child) {
        return typeof child === 'function';
    }
    // This wrapper creates child components for the main Flipper component
    var Flipped = function (_a) {
        var _b;
        var children = _a.children, flipId = _a.flipId, inverseFlipId = _a.inverseFlipId, portalKey = _a.portalKey, rest = __rest(_a, ["children", "flipId", "inverseFlipId", "portalKey"]);
        var child = children;
        var isFunctionAsChildren = isFunction$1(child);
        if (!isFunctionAsChildren) {
            try {
                child = React.Children.only(children);
            }
            catch (e) {
                throw new Error('Each Flipped component must wrap a single child');
            }
        }
        // if nothing is being animated, assume everything is being animated
        if (!rest.scale && !rest.translate && !rest.opacity) {
            assign(rest, {
                translate: true,
                scale: true,
                opacity: true
            });
        }
        var dataAttributes = (_b = {},
            // these are both used as selectors so they have to be separate
            _b[DATA_FLIP_ID] = flipId,
            _b[DATA_INVERSE_FLIP_ID] = inverseFlipId,
            _b[DATA_FLIP_CONFIG] = JSON.stringify(rest),
            _b);
        if (portalKey) {
            dataAttributes[DATA_PORTAL_KEY] = portalKey;
        }
        if (isFunctionAsChildren) {
            return child(dataAttributes);
        }
        return React.cloneElement(child, dataAttributes);
    };
    // @ts-ignore
    var FlippedWithContext = function (_a) {
        var children = _a.children, flipId = _a.flipId, shouldFlip = _a.shouldFlip, shouldInvert = _a.shouldInvert, onAppear = _a.onAppear, onStart = _a.onStart, onStartImmediate = _a.onStartImmediate, onComplete = _a.onComplete, onExit = _a.onExit, onSpringUpdate = _a.onSpringUpdate, rest = __rest(_a, ["children", "flipId", "shouldFlip", "shouldInvert", "onAppear", "onStart", "onStartImmediate", "onComplete", "onExit", "onSpringUpdate"]);
        if (!children) {
            return null;
        }
        if (rest.inverseFlipId) {
            return React__default.createElement(Flipped, __assign({}, rest), children);
        }
        return (React__default.createElement(PortalContext.Consumer, null, function (portalKey) { return (React__default.createElement(FlipContext.Consumer, null, function (data) {
            // if there is no surrounding Flipper component,
            // we don't want to throw an error, so check
            // that data exists and is not the default string
            if (isObject(data)) {
                // @ts-ignore
                data[flipId] = {
                    shouldFlip: shouldFlip,
                    shouldInvert: shouldInvert,
                    onAppear: onAppear,
                    onStart: onStart,
                    onStartImmediate: onStartImmediate,
                    onComplete: onComplete,
                    onExit: onExit,
                    onSpringUpdate: onSpringUpdate
                };
            }
            return (React__default.createElement(Flipped, __assign({ flipId: flipId }, rest, { portalKey: portalKey }), children));
        })); }));
    };

    var ExitContainer = function (_a) {
        var _b;
        var children = _a.children;
        return React.cloneElement(children, (_b = {},
            _b[DATA_EXIT_CONTAINER] = true,
            _b));
    };

    // for umd build
    var index = {
        Flipper: Flipper,
        Flipped: FlippedWithContext,
        ExitContainer: ExitContainer
    };

    exports.ExitContainer = ExitContainer;
    exports.Flipped = FlippedWithContext;
    exports.Flipper = Flipper;
    exports.default = index;

    Object.defineProperty(exports, '__esModule', { value: true });

}));
//# sourceMappingURL=react-flip-toolkit.js.map