(function (factory) {
    typeof define === 'function' && define.amd ? define(factory) :
    factory();
}((function () { 'use strict';

    function invariant(condition, message, Err) {
        if (Err === void 0) { Err = Error; }
        if (!condition) {
            throw new Err(message);
        }
    }

    /**
     * https://tc39.es/ecma262/#sec-toobject
     * @param arg
     */
    function toObject(arg) {
        if (arg == null) {
            throw new TypeError('undefined/null cannot be converted to object');
        }
        return Object(arg);
    }
    /**
     * https://tc39.es/ecma402/#sec-getoption
     * @param opts
     * @param prop
     * @param type
     * @param values
     * @param fallback
     */
    function getOption(opts, prop, type, values, fallback) {
        // const descriptor = Object.getOwnPropertyDescriptor(opts, prop);
        var value = opts[prop];
        if (value !== undefined) {
            if (type !== 'boolean' && type !== 'string') {
                throw new TypeError('invalid type');
            }
            if (type === 'boolean') {
                value = Boolean(value);
            }
            if (type === 'string') {
                value = String(value);
            }
            if (values !== undefined && !values.filter(function (val) { return val == value; }).length) {
                throw new RangeError(value + " in not within " + values);
            }
            return value;
        }
        return fallback;
    }
    function setInternalSlot(map, pl, field, value) {
        if (!map.get(pl)) {
            map.set(pl, Object.create(null));
        }
        var slots = map.get(pl);
        slots[field] = value;
    }
    function getInternalSlot(map, pl, field) {
        var slots = map.get(pl);
        if (!slots) {
            throw new TypeError(pl + " InternalSlot has not been initialized");
        }
        return slots[field];
    }

    /**
     * IE11-safe version of getCanonicalLocales since it's ES2016
     * @param locales locales
     */
    function getCanonicalLocales(locales) {
        // IE11
        var getCanonicalLocales = Intl.getCanonicalLocales;
        if (typeof getCanonicalLocales === 'function') {
            return getCanonicalLocales(locales);
        }
        return Intl.NumberFormat.supportedLocalesOf(locales || '');
    }

    var __extends = (undefined && undefined.__extends) || (function () {
        var extendStatics = function (d, b) {
            extendStatics = Object.setPrototypeOf ||
                ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
                function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
            return extendStatics(d, b);
        };
        return function (d, b) {
            extendStatics(d, b);
            function __() { this.constructor = d; }
            d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
        };
    })();
    var __assign = (undefined && undefined.__assign) || function () {
        __assign = Object.assign || function(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                    t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };
    function createResolveLocale(getDefaultLocale) {
        var lookupMatcher = createLookupMatcher(getDefaultLocale);
        var bestFitMatcher = createBestFitMatcher(getDefaultLocale);
        /**
         * https://tc39.es/ecma402/#sec-resolvelocale
         */
        return function resolveLocale(availableLocales, requestedLocales, options, relevantExtensionKeys, localeData) {
            var matcher = options.localeMatcher;
            var r;
            if (matcher === 'lookup') {
                r = lookupMatcher(availableLocales, requestedLocales);
            }
            else {
                r = bestFitMatcher(availableLocales, requestedLocales);
            }
            var foundLocale = r.locale;
            var result = { locale: '', dataLocale: foundLocale };
            var supportedExtension = '-u';
            for (var _i = 0, relevantExtensionKeys_1 = relevantExtensionKeys; _i < relevantExtensionKeys_1.length; _i++) {
                var key = relevantExtensionKeys_1[_i];
                var foundLocaleData = localeData[foundLocale];
                invariant(typeof foundLocaleData === 'object' && foundLocaleData !== null, "locale data " + key + " must be an object");
                var keyLocaleData = foundLocaleData[key];
                invariant(Array.isArray(keyLocaleData), 'keyLocaleData must be an array');
                var value = keyLocaleData[0];
                invariant(typeof value === 'string' || value === null, 'value must be string or null');
                var supportedExtensionAddition = '';
                if (r.extension) {
                    var requestedValue = unicodeExtensionValue(r.extension, key);
                    if (requestedValue !== undefined) {
                        if (requestedValue !== '') {
                            if (~keyLocaleData.indexOf(requestedValue)) {
                                value = requestedValue;
                                supportedExtensionAddition = "-" + key + "-" + value;
                            }
                        }
                        else if (~requestedValue.indexOf('true')) {
                            value = 'true';
                            supportedExtensionAddition = "-" + key;
                        }
                    }
                }
                if (key in options) {
                    var optionsValue = options[key];
                    invariant(typeof optionsValue === 'string' ||
                        typeof optionsValue === 'undefined' ||
                        optionsValue === null, 'optionsValue must be String, Undefined or Null');
                    if (~keyLocaleData.indexOf(optionsValue)) {
                        if (optionsValue !== value) {
                            value = optionsValue;
                            supportedExtensionAddition = '';
                        }
                    }
                }
                result[key] = value;
                supportedExtension += supportedExtensionAddition;
            }
            if (supportedExtension.length > 2) {
                var privateIndex = foundLocale.indexOf('-x-');
                if (privateIndex === -1) {
                    foundLocale = foundLocale + supportedExtension;
                }
                else {
                    var preExtension = foundLocale.slice(0, privateIndex);
                    var postExtension = foundLocale.slice(privateIndex, foundLocale.length);
                    foundLocale = preExtension + supportedExtension + postExtension;
                }
                foundLocale = getCanonicalLocales(foundLocale)[0];
            }
            result.locale = foundLocale;
            return result;
        };
    }
    /**
     * https://tc39.es/ecma402/#sec-unicodeextensionvalue
     * @param extension
     * @param key
     */
    function unicodeExtensionValue(extension, key) {
        invariant(key.length === 2, 'key must have 2 elements');
        var size = extension.length;
        var searchValue = "-" + key + "-";
        var pos = extension.indexOf(searchValue);
        if (pos !== -1) {
            var start = pos + 4;
            var end = start;
            var k = start;
            var done = false;
            while (!done) {
                var e = extension.indexOf('-', k);
                var len = void 0;
                if (e === -1) {
                    len = size - k;
                }
                else {
                    len = e - k;
                }
                if (len === 2) {
                    done = true;
                }
                else if (e === -1) {
                    end = size;
                    done = true;
                }
                else {
                    end = e;
                    k = e + 1;
                }
            }
            return extension.slice(start, end);
        }
        searchValue = "-" + key;
        pos = extension.indexOf(searchValue);
        if (pos !== -1 && pos + 3 === size) {
            return '';
        }
        return undefined;
    }
    var UNICODE_EXTENSION_SEQUENCE_REGEX = /-u(?:-[0-9a-z]{2,8})+/gi;
    /**
     * https://tc39.es/ecma402/#sec-bestavailablelocale
     * @param availableLocales
     * @param locale
     */
    function bestAvailableLocale(availableLocales, locale) {
        var candidate = locale;
        while (true) {
            if (~availableLocales.indexOf(candidate)) {
                return candidate;
            }
            var pos = candidate.lastIndexOf('-');
            if (!~pos) {
                return undefined;
            }
            if (pos >= 2 && candidate[pos - 2] === '-') {
                pos -= 2;
            }
            candidate = candidate.slice(0, pos);
        }
    }
    function createLookupMatcher(getDefaultLocale) {
        /**
         * https://tc39.es/ecma402/#sec-lookupmatcher
         */
        return function lookupMatcher(availableLocales, requestedLocales) {
            var result = { locale: '' };
            for (var _i = 0, requestedLocales_1 = requestedLocales; _i < requestedLocales_1.length; _i++) {
                var locale = requestedLocales_1[_i];
                var noExtensionLocale = locale.replace(UNICODE_EXTENSION_SEQUENCE_REGEX, '');
                var availableLocale = bestAvailableLocale(availableLocales, noExtensionLocale);
                if (availableLocale) {
                    result.locale = availableLocale;
                    if (locale !== noExtensionLocale) {
                        result.extension = locale.slice(noExtensionLocale.length + 1, locale.length);
                    }
                    return result;
                }
            }
            result.locale = getDefaultLocale();
            return result;
        };
    }
    function createBestFitMatcher(getDefaultLocale) {
        return function bestFitMatcher(availableLocales, requestedLocales) {
            var result = { locale: '' };
            for (var _i = 0, requestedLocales_2 = requestedLocales; _i < requestedLocales_2.length; _i++) {
                var locale = requestedLocales_2[_i];
                var noExtensionLocale = locale.replace(UNICODE_EXTENSION_SEQUENCE_REGEX, '');
                var availableLocale = bestAvailableLocale(availableLocales, noExtensionLocale);
                if (availableLocale) {
                    result.locale = availableLocale;
                    if (locale !== noExtensionLocale) {
                        result.extension = locale.slice(noExtensionLocale.length + 1, locale.length);
                    }
                    return result;
                }
            }
            result.locale = getDefaultLocale();
            return result;
        };
    }
    function getLocaleHierarchy(locale, aliases, parentLocales) {
        var results = [locale];
        if (aliases[locale]) {
            locale = aliases[locale];
            results.push(locale);
        }
        var parentLocale = parentLocales[locale];
        if (parentLocale) {
            results.push(parentLocale);
        }
        var localeParts = locale.split('-');
        for (var i = localeParts.length; i > 1; i--) {
            results.push(localeParts.slice(0, i - 1).join('-'));
        }
        return results;
    }
    function lookupSupportedLocales(availableLocales, requestedLocales) {
        var subset = [];
        for (var _i = 0, requestedLocales_3 = requestedLocales; _i < requestedLocales_3.length; _i++) {
            var locale = requestedLocales_3[_i];
            var noExtensionLocale = locale.replace(UNICODE_EXTENSION_SEQUENCE_REGEX, '');
            var availableLocale = bestAvailableLocale(availableLocales, noExtensionLocale);
            if (availableLocale) {
                subset.push(availableLocale);
            }
        }
        return subset;
    }
    function supportedLocales(availableLocales, requestedLocales, options) {
        var matcher = 'best fit';
        if (options !== undefined) {
            options = toObject(options);
            matcher = getOption(options, 'localeMatcher', 'string', ['lookup', 'best fit'], 'best fit');
        }
        if (matcher === 'best fit') {
            return lookupSupportedLocales(availableLocales, requestedLocales);
        }
        return lookupSupportedLocales(availableLocales, requestedLocales);
    }
    var MissingLocaleDataError = /** @class */ (function (_super) {
        __extends(MissingLocaleDataError, _super);
        function MissingLocaleDataError() {
            var _this = _super !== null && _super.apply(this, arguments) || this;
            _this.type = 'MISSING_LOCALE_DATA';
            return _this;
        }
        return MissingLocaleDataError;
    }(Error));
    function isMissingLocaleDataError(e) {
        return e.type === 'MISSING_LOCALE_DATA';
    }
    function unpackData(locale, localeData, 
    /** By default shallow merge the dictionaries. */
    reducer) {
        if (reducer === void 0) { reducer = function (all, d) { return (__assign(__assign({}, all), d)); }; }
        var localeHierarchy = getLocaleHierarchy(locale, localeData.aliases, localeData.parentLocales);
        var dataToMerge = localeHierarchy
            .map(function (l) { return localeData.data[l]; })
            .filter(Boolean);
        if (!dataToMerge.length) {
            throw new MissingLocaleDataError("Missing locale data for \"" + locale + "\", lookup hierarchy: " + localeHierarchy.join(', '));
        }
        dataToMerge.reverse();
        return dataToMerge.reduce(reducer, {});
    }

    function validateInstance(instance, method) {
        if (!(instance instanceof PluralRules)) {
            throw new TypeError(`Method Intl.PluralRules.prototype.${method} called on incompatible receiver ${String(instance)}`);
        }
    }
    /**
     * https://tc39.es/ecma402/#sec-defaultnumberoption
     * @param val
     * @param min
     * @param max
     * @param fallback
     */
    function defaultNumberOption(val, min, max, fallback) {
        if (val !== undefined) {
            val = Number(val);
            if (isNaN(val) || val < min || val > max) {
                throw new RangeError(`${val} is outside of range [${min}, ${max}]`);
            }
            return Math.floor(val);
        }
        return fallback;
    }
    /**
     * https://tc39.es/ecma402/#sec-getnumberoption
     * @param options
     * @param property
     * @param min
     * @param max
     * @param fallback
     */
    function getNumberOption(options, property, min, max, fallback) {
        const val = options[property];
        return defaultNumberOption(val, min, max, fallback);
    }
    /**
     * https://tc39.es/ecma402/#sec-setnfdigitoptions
     * https://tc39.es/proposal-unified-intl-numberformat/section11/numberformat_diff_out.html#sec-setnfdigitoptions
     * @param pl
     * @param opts
     * @param mnfdDefault
     * @param mxfdDefault
     */
    function setNumberFormatDigitOptions(internalSlotMap, pl, opts, mnfdDefault, mxfdDefault) {
        const mnid = getNumberOption(opts, 'minimumIntegerDigits', 1, 21, 1);
        let mnfd = opts.minimumFractionDigits;
        let mxfd = opts.maximumFractionDigits;
        let mnsd = opts.minimumSignificantDigits;
        let mxsd = opts.maximumSignificantDigits;
        setInternalSlot(internalSlotMap, pl, 'minimumIntegerDigits', mnid);
        setInternalSlot(internalSlotMap, pl, 'minimumFractionDigits', mnfd);
        setInternalSlot(internalSlotMap, pl, 'maximumFractionDigits', mxfd);
        if (mnsd !== undefined || mxsd !== undefined) {
            setInternalSlot(internalSlotMap, pl, 'roundingType', 'significantDigits');
            mnsd = defaultNumberOption(mnsd, 1, 21, 1);
            mxsd = defaultNumberOption(mxsd, mnsd, 21, 21);
            setInternalSlot(internalSlotMap, pl, 'minimumSignificantDigits', mnsd);
            setInternalSlot(internalSlotMap, pl, 'maximumSignificantDigits', mxsd);
        }
        else if (mnfd !== undefined || mxfd !== undefined) {
            setInternalSlot(internalSlotMap, pl, 'roundingType', 'fractionDigits');
            mnfd = defaultNumberOption(mnfd, 0, 20, mnfdDefault);
            const mxfdActualDefault = Math.max(mnfd, mxfdDefault);
            mxfd = defaultNumberOption(mxfd, mnfd, 20, mxfdActualDefault);
            setInternalSlot(internalSlotMap, pl, 'minimumFractionDigits', mnfd);
            setInternalSlot(internalSlotMap, pl, 'maximumFractionDigits', mxfd);
        }
        else if (getInternalSlot(internalSlotMap, pl, 'notation') === 'compact') {
            setInternalSlot(internalSlotMap, pl, 'roundingType', 'compactRounding');
        }
        else {
            setInternalSlot(internalSlotMap, pl, 'roundingType', 'fractionDigits');
            setInternalSlot(internalSlotMap, pl, 'minimumFractionDigits', mnfdDefault);
            setInternalSlot(internalSlotMap, pl, 'maximumFractionDigits', mxfdDefault);
        }
    }
    /**
     * https://tc39.es/ecma402/#sec-torawprecision
     * @param x
     * @param minPrecision
     * @param maxPrecision
     */
    function toRawPrecision(x, minPrecision, maxPrecision) {
        let m = x.toPrecision(maxPrecision);
        if (~m.indexOf('.') && maxPrecision > minPrecision) {
            let cut = maxPrecision - minPrecision;
            while (cut > 0 && m[m.length - 1] === '0') {
                m = m.slice(0, m.length - 1);
                cut--;
            }
            if (m[m.length - 1] === '.') {
                return m.slice(0, m.length - 1);
            }
        }
        return m;
    }
    /**
     * https://tc39.es/ecma402/#sec-torawfixed
     * @param x
     * @param minInteger
     * @param minFraction
     * @param maxFraction
     */
    function toRawFixed(x, minInteger, minFraction, maxFraction) {
        let cut = maxFraction - minFraction;
        let m = x.toFixed(maxFraction);
        while (cut > 0 && m[m.length - 1] === '0') {
            m = m.slice(0, m.length - 1);
            cut--;
        }
        if (m[m.length - 1] === '.') {
            m = m.slice(0, m.length - 1);
        }
        const int = m.split('.')[0].length;
        if (int < minInteger) {
            let z = '';
            for (; z.length < minInteger - int; z += '0')
                ;
            m = z + m;
        }
        return m;
    }
    function formatNumericToString(internalSlotMap, pl, x) {
        const minimumSignificantDigits = getInternalSlot(internalSlotMap, pl, 'minimumSignificantDigits');
        const maximumSignificantDigits = getInternalSlot(internalSlotMap, pl, 'maximumSignificantDigits');
        if (minimumSignificantDigits !== undefined &&
            maximumSignificantDigits !== undefined) {
            return toRawPrecision(x, minimumSignificantDigits, maximumSignificantDigits);
        }
        return toRawFixed(x, getInternalSlot(internalSlotMap, pl, 'minimumIntegerDigits'), getInternalSlot(internalSlotMap, pl, 'minimumFractionDigits'), getInternalSlot(internalSlotMap, pl, 'maximumFractionDigits'));
    }
    class PluralRules {
        constructor(locales, options) {
            // test262/test/intl402/RelativeTimeFormat/constructor/constructor/newtarget-undefined.js
            // Cannot use `new.target` bc of IE11 & TS transpiles it to something else
            const newTarget = this && this instanceof PluralRules ? this.constructor : void 0;
            if (!newTarget) {
                throw new TypeError("Intl.PluralRules must be called with 'new'");
            }
            const requestedLocales = getCanonicalLocales(locales);
            const opt = Object.create(null);
            const opts = options === undefined ? Object.create(null) : toObject(options);
            setInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'initializedPluralRules', true);
            const matcher = getOption(opts, 'localeMatcher', 'string', ['best fit', 'lookup'], 'best fit');
            opt.localeMatcher = matcher;
            // test262/test/intl402/PluralRules/prototype/select/tainting.js
            // TODO: This is kinda cheating, but unless we rely on WeakMap to
            // hide the internal slots it's hard to be completely safe from tainting
            setInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'type', getOption(opts, 'type', 'string', ['cardinal', 'ordinal'], 'cardinal'));
            setNumberFormatDigitOptions(PluralRules.__INTERNAL_SLOT_MAP__, this, opts, 0, 3);
            const r = createResolveLocale(PluralRules.getDefaultLocale)(PluralRules.availableLocales, requestedLocales, opt, PluralRules.relevantExtensionKeys, PluralRules.localeData);
            setInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'locale', r.locale);
        }
        resolvedOptions() {
            validateInstance(this, 'resolvedOptions');
            const opts = Object.create(Object.prototype);
            opts.locale = getInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'locale');
            opts.type = getInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'type');
            [
                'minimumIntegerDigits',
                'minimumFractionDigits',
                'maximumFractionDigits',
                'minimumSignificantDigits',
                'maximumSignificantDigits',
            ].forEach(field => {
                const val = getInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, field);
                if (val !== undefined) {
                    opts[field] = val;
                }
            });
            opts.pluralCategories = [
                ...PluralRules.localeData[opts.locale].categories[opts.type],
            ];
            return opts;
        }
        select(val) {
            validateInstance(this, 'select');
            const locale = getInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'locale');
            const type = getInternalSlot(PluralRules.__INTERNAL_SLOT_MAP__, this, 'type');
            return PluralRules.localeData[locale].fn(formatNumericToString(PluralRules.__INTERNAL_SLOT_MAP__, this, Math.abs(Number(val))), type == 'ordinal');
        }
        toString() {
            return '[object Intl.PluralRules]';
        }
        static supportedLocalesOf(locales, options) {
            return supportedLocales(PluralRules.availableLocales, getCanonicalLocales(locales), options);
        }
        static __addLocaleData(...data) {
            for (const datum of data) {
                const availableLocales = Object.keys([
                    ...datum.availableLocales,
                    ...Object.keys(datum.aliases),
                    ...Object.keys(datum.parentLocales),
                ].reduce((all, k) => {
                    all[k] = true;
                    return all;
                }, {}));
                availableLocales.forEach(locale => {
                    try {
                        PluralRules.localeData[locale] = unpackData(locale, datum);
                    }
                    catch (e) {
                        if (isMissingLocaleDataError(e)) {
                            // If we just don't have data for certain locale, that's ok
                            return;
                        }
                        throw e;
                    }
                });
            }
            PluralRules.availableLocales = Object.keys(PluralRules.localeData);
            if (!PluralRules.__defaultLocale) {
                PluralRules.__defaultLocale = PluralRules.availableLocales[0];
            }
        }
        static getDefaultLocale() {
            return PluralRules.__defaultLocale;
        }
    }
    PluralRules.localeData = {};
    PluralRules.availableLocales = [];
    PluralRules.__defaultLocale = 'en';
    PluralRules.relevantExtensionKeys = [];
    PluralRules.polyfilled = true;
    PluralRules.__INTERNAL_SLOT_MAP__ = new WeakMap();
    try {
        // https://github.com/tc39/test262/blob/master/test/intl402/PluralRules/length.js
        Object.defineProperty(PluralRules, 'length', {
            value: 0,
            writable: false,
            enumerable: false,
            configurable: true,
        });
        // https://github.com/tc39/test262/blob/master/test/intl402/RelativeTimeFormat/constructor/length.js
        Object.defineProperty(PluralRules.prototype.constructor, 'length', {
            value: 0,
            writable: false,
            enumerable: false,
            configurable: true,
        });
        // https://github.com/tc39/test262/blob/master/test/intl402/RelativeTimeFormat/constructor/supportedLocalesOf/length.js
        Object.defineProperty(PluralRules.supportedLocalesOf, 'length', {
            value: 1,
            writable: false,
            enumerable: false,
            configurable: true,
        });
    }
    catch (ex) {
        // Meta fixes for test262
    }

    if (typeof Intl.PluralRules === 'undefined') {
        Object.defineProperty(Intl, 'PluralRules', {
            value: PluralRules,
            writable: true,
            enumerable: false,
            configurable: true,
        });
    }

    if (Intl.PluralRules && typeof Intl.PluralRules.__addLocaleData === 'function') {
      Intl.PluralRules.__addLocaleData(
    {"data":{"af":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["af"]},
    {"data":{"ak":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return ((n == 0
              || n == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ak"]},
    {"data":{"am":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["am"]},
    {"data":{"ar":{"categories":{"cardinal":["zero","one","two","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n100 = t0 && s[0].slice(-2);
      if (ord) return 'other';
      return (n == 0) ? 'zero'
          : (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : ((n100 >= 3 && n100 <= 10)) ? 'few'
          : ((n100 >= 11 && n100 <= 99)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ar"]},
    {"data":{"as":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","many","other"]},"fn":function(n, ord) {
      if (ord) return ((n == 1 || n == 5 || n == 7 || n == 8 || n == 9
              || n == 10)) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["as"]},
    {"data":{"asa":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["asa"]},
    {"data":{"ast":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ast"]},
    {"data":{"az":{"categories":{"cardinal":["one","other"],"ordinal":["one","few","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], i10 = i.slice(-1),
          i100 = i.slice(-2), i1000 = i.slice(-3);
      if (ord) return ((i10 == 1 || i10 == 2 || i10 == 5 || i10 == 7 || i10 == 8)
              || (i100 == 20 || i100 == 50 || i100 == 70
              || i100 == 80)) ? 'one'
          : ((i10 == 3 || i10 == 4) || (i1000 == 100 || i1000 == 200
              || i1000 == 300 || i1000 == 400 || i1000 == 500 || i1000 == 600 || i1000 == 700
              || i1000 == 800
              || i1000 == 900)) ? 'few'
          : (i == 0 || i10 == 6 || (i100 == 40 || i100 == 60
              || i100 == 90)) ? 'many'
          : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"az-AZ":"az-Latn-AZ"},"parentLocales":{},"availableLocales":["az"]},
    {"data":{"be":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2);
      if (ord) return ((n10 == 2
              || n10 == 3) && n100 != 12 && n100 != 13) ? 'few' : 'other';
      return (n10 == 1 && n100 != 11) ? 'one'
          : ((n10 >= 2 && n10 <= 4) && (n100 < 12
              || n100 > 14)) ? 'few'
          : (t0 && n10 == 0 || (n10 >= 5 && n10 <= 9)
              || (n100 >= 11 && n100 <= 14)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["be"]},
    {"data":{"bem":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bem"]},
    {"data":{"bez":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bez"]},
    {"data":{"bg":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bg"]},
    {"data":{"bm":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bm"]},
    {"data":{"bn":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","many","other"]},"fn":function(n, ord) {
      if (ord) return ((n == 1 || n == 5 || n == 7 || n == 8 || n == 9
              || n == 10)) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bn"]},
    {"data":{"bo":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["bo"]},
    {"data":{"br":{"categories":{"cardinal":["one","two","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2),
          n1000000 = t0 && s[0].slice(-6);
      if (ord) return 'other';
      return (n10 == 1 && n100 != 11 && n100 != 71 && n100 != 91) ? 'one'
          : (n10 == 2 && n100 != 12 && n100 != 72 && n100 != 92) ? 'two'
          : (((n10 == 3 || n10 == 4) || n10 == 9) && (n100 < 10
              || n100 > 19) && (n100 < 70 || n100 > 79) && (n100 < 90
              || n100 > 99)) ? 'few'
          : (n != 0 && t0 && n1000000 == 0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["br"]},
    {"data":{"brx":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["brx"]},
    {"data":{"bs":{"categories":{"cardinal":["one","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), i100 = i.slice(-2), f10 = f.slice(-1), f100 = f.slice(-2);
      if (ord) return 'other';
      return (v0 && i10 == 1 && i100 != 11
              || f10 == 1 && f100 != 11) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12 || i100 > 14)
              || (f10 >= 2 && f10 <= 4) && (f100 < 12
              || f100 > 14)) ? 'few'
          : 'other';
    }}},"aliases":{"bs-BA":"bs-Latn-BA"},"parentLocales":{},"availableLocales":["bs"]},
    {"data":{"ca":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return ((n == 1
              || n == 3)) ? 'one'
          : (n == 2) ? 'two'
          : (n == 4) ? 'few'
          : 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ca"]},
    {"data":{"ce":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ce"]},
    {"data":{"ceb":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), f10 = f.slice(-1);
      if (ord) return 'other';
      return (v0 && (i == 1 || i == 2 || i == 3)
              || v0 && i10 != 4 && i10 != 6 && i10 != 9
              || !v0 && f10 != 4 && f10 != 6 && f10 != 9) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ceb"]},
    {"data":{"cgg":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["cgg"]},
    {"data":{"chr":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["chr"]},
    {"data":{"ckb":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ckb"]},
    {"data":{"cs":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one'
          : ((i >= 2 && i <= 4) && v0) ? 'few'
          : (!v0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["cs"]},
    {"data":{"cy":{"categories":{"cardinal":["zero","one","two","few","many","other"],"ordinal":["zero","one","two","few","many","other"]},"fn":function(n, ord) {
      if (ord) return ((n == 0 || n == 7 || n == 8
              || n == 9)) ? 'zero'
          : (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : ((n == 3
              || n == 4)) ? 'few'
          : ((n == 5
              || n == 6)) ? 'many'
          : 'other';
      return (n == 0) ? 'zero'
          : (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : (n == 3) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["cy"]},
    {"data":{"da":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], t0 = Number(s[0]) == n;
      if (ord) return 'other';
      return (n == 1 || !t0 && (i == 0
              || i == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["da"]},
    {"data":{"de":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["de"]},
    {"data":{"dsb":{"categories":{"cardinal":["one","two","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i100 = i.slice(-2), f100 = f.slice(-2);
      if (ord) return 'other';
      return (v0 && i100 == 1
              || f100 == 1) ? 'one'
          : (v0 && i100 == 2
              || f100 == 2) ? 'two'
          : (v0 && (i100 == 3 || i100 == 4) || (f100 == 3
              || f100 == 4)) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["dsb"]},
    {"data":{"dz":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["dz"]},
    {"data":{"ee":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ee"]},
    {"data":{"el":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["el"]},
    {"data":{"en":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1], t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2);
      if (ord) return (n10 == 1 && n100 != 11) ? 'one'
          : (n10 == 2 && n100 != 12) ? 'two'
          : (n10 == 3 && n100 != 13) ? 'few'
          : 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{"en-150":"en-001","en-AG":"en-001","en-AI":"en-001","en-AU":"en-001","en-BB":"en-001","en-BM":"en-001","en-BS":"en-001","en-BW":"en-001","en-BZ":"en-001","en-CA":"en-001","en-CC":"en-001","en-CK":"en-001","en-CM":"en-001","en-CX":"en-001","en-CY":"en-001","en-DG":"en-001","en-DM":"en-001","en-ER":"en-001","en-FJ":"en-001","en-FK":"en-001","en-FM":"en-001","en-GB":"en-001","en-GD":"en-001","en-GG":"en-001","en-GH":"en-001","en-GI":"en-001","en-GM":"en-001","en-GY":"en-001","en-HK":"en-001","en-IE":"en-001","en-IL":"en-001","en-IM":"en-001","en-IN":"en-001","en-IO":"en-001","en-JE":"en-001","en-JM":"en-001","en-KE":"en-001","en-KI":"en-001","en-KN":"en-001","en-KY":"en-001","en-LC":"en-001","en-LR":"en-001","en-LS":"en-001","en-MG":"en-001","en-MO":"en-001","en-MS":"en-001","en-MT":"en-001","en-MU":"en-001","en-MW":"en-001","en-MY":"en-001","en-NA":"en-001","en-NF":"en-001","en-NG":"en-001","en-NR":"en-001","en-NU":"en-001","en-NZ":"en-001","en-PG":"en-001","en-PH":"en-001","en-PK":"en-001","en-PN":"en-001","en-PW":"en-001","en-RW":"en-001","en-SB":"en-001","en-SC":"en-001","en-SD":"en-001","en-SG":"en-001","en-SH":"en-001","en-SL":"en-001","en-SS":"en-001","en-SX":"en-001","en-SZ":"en-001","en-TC":"en-001","en-TK":"en-001","en-TO":"en-001","en-TT":"en-001","en-TV":"en-001","en-TZ":"en-001","en-UG":"en-001","en-VC":"en-001","en-VG":"en-001","en-VU":"en-001","en-WS":"en-001","en-ZA":"en-001","en-ZM":"en-001","en-ZW":"en-001","en-AT":"en-150","en-BE":"en-150","en-CH":"en-150","en-DE":"en-150","en-DK":"en-150","en-FI":"en-150","en-NL":"en-150","en-SE":"en-150","en-SI":"en-150"},"availableLocales":["en"]},
    {"data":{"eo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["eo"]},
    {"data":{"es":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{"es-AR":"es-419","es-BO":"es-419","es-BR":"es-419","es-BZ":"es-419","es-CL":"es-419","es-CO":"es-419","es-CR":"es-419","es-CU":"es-419","es-DO":"es-419","es-EC":"es-419","es-GT":"es-419","es-HN":"es-419","es-MX":"es-419","es-NI":"es-419","es-PA":"es-419","es-PE":"es-419","es-PR":"es-419","es-PY":"es-419","es-SV":"es-419","es-US":"es-419","es-UY":"es-419","es-VE":"es-419"},"availableLocales":["es"]},
    {"data":{"et":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["et"]},
    {"data":{"eu":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["eu"]},
    {"data":{"fa":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fa"]},
    {"data":{"ff":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n < 2) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ff"]},
    {"data":{"fi":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fi"]},
    {"data":{"fil":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), f10 = f.slice(-1);
      if (ord) return (n == 1) ? 'one' : 'other';
      return (v0 && (i == 1 || i == 2 || i == 3)
              || v0 && i10 != 4 && i10 != 6 && i10 != 9
              || !v0 && f10 != 4 && f10 != 6 && f10 != 9) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fil"]},
    {"data":{"fo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fo"]},
    {"data":{"fr":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one' : 'other';
      return (n >= 0 && n < 2) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fr"]},
    {"data":{"fur":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fur"]},
    {"data":{"fy":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["fy"]},
    {"data":{"ga":{"categories":{"cardinal":["one","two","few","many","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return (n == 1) ? 'one' : 'other';
      return (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : ((t0 && n >= 3 && n <= 6)) ? 'few'
          : ((t0 && n >= 7 && n <= 10)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ga"]},
    {"data":{"gd":{"categories":{"cardinal":["one","two","few","other"],"ordinal":["one","two","few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return ((n == 1
              || n == 11)) ? 'one'
          : ((n == 2
              || n == 12)) ? 'two'
          : ((n == 3
              || n == 13)) ? 'few'
          : 'other';
      return ((n == 1
              || n == 11)) ? 'one'
          : ((n == 2
              || n == 12)) ? 'two'
          : (((t0 && n >= 3 && n <= 10)
              || (t0 && n >= 13 && n <= 19))) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["gd"]},
    {"data":{"gl":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["gl"]},
    {"data":{"gsw":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["gsw"]},
    {"data":{"gu":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","many","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["gu"]},
    {"data":{"gv":{"categories":{"cardinal":["one","two","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], i10 = i.slice(-1),
          i100 = i.slice(-2);
      if (ord) return 'other';
      return (v0 && i10 == 1) ? 'one'
          : (v0 && i10 == 2) ? 'two'
          : (v0 && (i100 == 0 || i100 == 20 || i100 == 40 || i100 == 60
              || i100 == 80)) ? 'few'
          : (!v0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["gv"]},
    {"data":{"ha":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"ha-Latn-GH":"ha-GH","ha-Latn-NE":"ha-NE","ha-Latn-NG":"ha-NG"},"parentLocales":{},"availableLocales":["ha"]},
    {"data":{"haw":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["haw"]},
    {"data":{"he":{"categories":{"cardinal":["one","two","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1);
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one'
          : (i == 2 && v0) ? 'two'
          : (v0 && (n < 0
              || n > 10) && t0 && n10 == 0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["he"]},
    {"data":{"hi":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","many","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["hi"]},
    {"data":{"hr":{"categories":{"cardinal":["one","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), i100 = i.slice(-2), f10 = f.slice(-1), f100 = f.slice(-2);
      if (ord) return 'other';
      return (v0 && i10 == 1 && i100 != 11
              || f10 == 1 && f100 != 11) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12 || i100 > 14)
              || (f10 >= 2 && f10 <= 4) && (f100 < 12
              || f100 > 14)) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["hr"]},
    {"data":{"hsb":{"categories":{"cardinal":["one","two","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i100 = i.slice(-2), f100 = f.slice(-2);
      if (ord) return 'other';
      return (v0 && i100 == 1
              || f100 == 1) ? 'one'
          : (v0 && i100 == 2
              || f100 == 2) ? 'two'
          : (v0 && (i100 == 3 || i100 == 4) || (f100 == 3
              || f100 == 4)) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["hsb"]},
    {"data":{"hu":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return ((n == 1
              || n == 5)) ? 'one' : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["hu"]},
    {"data":{"hy":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one' : 'other';
      return (n >= 0 && n < 2) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["hy"]},
    {"data":{"ia":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ia"]},
    {"data":{"id":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["id"]},
    {"data":{"ig":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ig"]},
    {"data":{"ii":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ii"]},
    {"data":{"is":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], t0 = Number(s[0]) == n,
          i10 = i.slice(-1), i100 = i.slice(-2);
      if (ord) return 'other';
      return (t0 && i10 == 1 && i100 != 11
              || !t0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["is"]},
    {"data":{"it":{"categories":{"cardinal":["one","other"],"ordinal":["many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return ((n == 11 || n == 8 || n == 80
              || n == 800)) ? 'many' : 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["it"]},
    {"data":{"ja":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ja"]},
    {"data":{"jgo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["jgo"]},
    {"data":{"jmc":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["jmc"]},
    {"data":{"jv":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["jv"]},
    {"data":{"ka":{"categories":{"cardinal":["one","other"],"ordinal":["one","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], i100 = i.slice(-2);
      if (ord) return (i == 1) ? 'one'
          : (i == 0 || ((i100 >= 2 && i100 <= 20) || i100 == 40 || i100 == 60
              || i100 == 80)) ? 'many'
          : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ka"]},
    {"data":{"kab":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n < 2) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kab"]},
    {"data":{"kde":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kde"]},
    {"data":{"kea":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kea"]},
    {"data":{"kk":{"categories":{"cardinal":["one","other"],"ordinal":["many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1);
      if (ord) return (n10 == 6 || n10 == 9
              || t0 && n10 == 0 && n != 0) ? 'many' : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"kk-Cyrl-KZ":"kk-KZ"},"parentLocales":{},"availableLocales":["kk"]},
    {"data":{"kkj":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kkj"]},
    {"data":{"kl":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kl"]},
    {"data":{"km":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["km"]},
    {"data":{"kn":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kn"]},
    {"data":{"ko":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ko"]},
    {"data":{"ks":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"ks-Arab-IN":"ks-IN"},"parentLocales":{},"availableLocales":["ks"]},
    {"data":{"ksb":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ksb"]},
    {"data":{"ksh":{"categories":{"cardinal":["zero","one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 0) ? 'zero'
          : (n == 1) ? 'one'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ksh"]},
    {"data":{"ku":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ku"]},
    {"data":{"kw":{"categories":{"cardinal":["zero","one","two","few","many","other"],"ordinal":["one","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n100 = t0 && s[0].slice(-2), n1000 = t0 && s[0].slice(-3),
          n100000 = t0 && s[0].slice(-5), n1000000 = t0 && s[0].slice(-6);
      if (ord) return ((t0 && n >= 1 && n <= 4) || ((n100 >= 1 && n100 <= 4)
              || (n100 >= 21 && n100 <= 24) || (n100 >= 41 && n100 <= 44)
              || (n100 >= 61 && n100 <= 64)
              || (n100 >= 81 && n100 <= 84))) ? 'one'
          : (n == 5
              || n100 == 5) ? 'many'
          : 'other';
      return (n == 0) ? 'zero'
          : (n == 1) ? 'one'
          : ((n100 == 2 || n100 == 22 || n100 == 42 || n100 == 62 || n100 == 82)
              || t0 && n1000 == 0 && ((n100000 >= 1000 && n100000 <= 20000) || n100000 == 40000
              || n100000 == 60000 || n100000 == 80000)
              || n != 0 && n1000000 == 100000) ? 'two'
          : ((n100 == 3 || n100 == 23 || n100 == 43 || n100 == 63
              || n100 == 83)) ? 'few'
          : (n != 1 && (n100 == 1 || n100 == 21 || n100 == 41 || n100 == 61
              || n100 == 81)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["kw"]},
    {"data":{"ky":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"ky-Cyrl-KG":"ky-KG"},"parentLocales":{},"availableLocales":["ky"]},
    {"data":{"lag":{"categories":{"cardinal":["zero","one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0];
      if (ord) return 'other';
      return (n == 0) ? 'zero'
          : ((i == 0
              || i == 1) && n != 0) ? 'one'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lag"]},
    {"data":{"lb":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lb"]},
    {"data":{"lg":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lg"]},
    {"data":{"lkt":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lkt"]},
    {"data":{"ln":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return ((n == 0
              || n == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ln"]},
    {"data":{"lo":{"categories":{"cardinal":["other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one' : 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lo"]},
    {"data":{"lt":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), f = s[1] || '', t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2);
      if (ord) return 'other';
      return (n10 == 1 && (n100 < 11
              || n100 > 19)) ? 'one'
          : ((n10 >= 2 && n10 <= 9) && (n100 < 11
              || n100 > 19)) ? 'few'
          : (f != 0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lt"]},
    {"data":{"lv":{"categories":{"cardinal":["zero","one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), f = s[1] || '', v = f.length,
          t0 = Number(s[0]) == n, n10 = t0 && s[0].slice(-1),
          n100 = t0 && s[0].slice(-2), f100 = f.slice(-2), f10 = f.slice(-1);
      if (ord) return 'other';
      return (t0 && n10 == 0 || (n100 >= 11 && n100 <= 19)
              || v == 2 && (f100 >= 11 && f100 <= 19)) ? 'zero'
          : (n10 == 1 && n100 != 11 || v == 2 && f10 == 1 && f100 != 11
              || v != 2 && f10 == 1) ? 'one'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["lv"]},
    {"data":{"mas":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mas"]},
    {"data":{"mg":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return ((n == 0
              || n == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mg"]},
    {"data":{"mgo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mgo"]},
    {"data":{"mk":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), i100 = i.slice(-2), f10 = f.slice(-1), f100 = f.slice(-2);
      if (ord) return (i10 == 1 && i100 != 11) ? 'one'
          : (i10 == 2 && i100 != 12) ? 'two'
          : ((i10 == 7
              || i10 == 8) && i100 != 17 && i100 != 18) ? 'many'
          : 'other';
      return (v0 && i10 == 1 && i100 != 11
              || f10 == 1 && f100 != 11) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mk"]},
    {"data":{"ml":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ml"]},
    {"data":{"mn":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"mn-Cyrl-MN":"mn-MN"},"parentLocales":{},"availableLocales":["mn"]},
    {"data":{"mr":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mr"]},
    {"data":{"ms":{"categories":{"cardinal":["other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one' : 'other';
      return 'other';
    }}},"aliases":{"ms-Latn-BN":"ms-BN","ms-Latn-MY":"ms-MY","ms-Latn-SG":"ms-SG"},"parentLocales":{},"availableLocales":["ms"]},
    {"data":{"mt":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n100 = t0 && s[0].slice(-2);
      if (ord) return 'other';
      return (n == 1) ? 'one'
          : (n == 0
              || (n100 >= 2 && n100 <= 10)) ? 'few'
          : ((n100 >= 11 && n100 <= 19)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["mt"]},
    {"data":{"my":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["my"]},
    {"data":{"naq":{"categories":{"cardinal":["one","two","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["naq"]},
    {"data":{"nb":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nb"]},
    {"data":{"nd":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nd"]},
    {"data":{"ne":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return ((t0 && n >= 1 && n <= 4)) ? 'one' : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ne"]},
    {"data":{"nl":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nl"]},
    {"data":{"nn":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nn"]},
    {"data":{"nnh":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nnh"]},
    {"data":{"nyn":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["nyn"]},
    {"data":{"om":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["om"]},
    {"data":{"or":{"categories":{"cardinal":["one","other"],"ordinal":["one","two","few","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return ((n == 1 || n == 5
              || (t0 && n >= 7 && n <= 9))) ? 'one'
          : ((n == 2
              || n == 3)) ? 'two'
          : (n == 4) ? 'few'
          : (n == 6) ? 'many'
          : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["or"]},
    {"data":{"os":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["os"]},
    {"data":{"pa":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return ((n == 0
              || n == 1)) ? 'one' : 'other';
    }}},"aliases":{"pa-IN":"pa-Guru-IN","pa-PK":"pa-Arab-PK"},"parentLocales":{},"availableLocales":["pa"]},
    {"data":{"pl":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], i10 = i.slice(-1),
          i100 = i.slice(-2);
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12
              || i100 > 14)) ? 'few'
          : (v0 && i != 1 && (i10 == 0 || i10 == 1)
              || v0 && (i10 >= 5 && i10 <= 9)
              || v0 && (i100 >= 12 && i100 <= 14)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["pl"]},
    {"data":{"prg":{"categories":{"cardinal":["zero","one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), f = s[1] || '', v = f.length,
          t0 = Number(s[0]) == n, n10 = t0 && s[0].slice(-1),
          n100 = t0 && s[0].slice(-2), f100 = f.slice(-2), f10 = f.slice(-1);
      if (ord) return 'other';
      return (t0 && n10 == 0 || (n100 >= 11 && n100 <= 19)
              || v == 2 && (f100 >= 11 && f100 <= 19)) ? 'zero'
          : (n10 == 1 && n100 != 11 || v == 2 && f10 == 1 && f100 != 11
              || v != 2 && f10 == 1) ? 'one'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["prg"]},
    {"data":{"ps":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ps"]},
    {"data":{"pt":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0];
      if (ord) return 'other';
      return ((i == 0
              || i == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{"pt-AO":"pt-PT","pt-CH":"pt-PT","pt-CV":"pt-PT","pt-FR":"pt-PT","pt-GQ":"pt-PT","pt-GW":"pt-PT","pt-LU":"pt-PT","pt-MO":"pt-PT","pt-MZ":"pt-PT","pt-ST":"pt-PT","pt-TL":"pt-PT"},"availableLocales":["pt"]},
    {"data":{"rm":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["rm"]},
    {"data":{"ro":{"categories":{"cardinal":["one","few","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1], t0 = Number(s[0]) == n,
          n100 = t0 && s[0].slice(-2);
      if (ord) return (n == 1) ? 'one' : 'other';
      return (n == 1 && v0) ? 'one'
          : (!v0 || n == 0
              || (n100 >= 2 && n100 <= 19)) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ro"]},
    {"data":{"rof":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["rof"]},
    {"data":{"root":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["root"]},
    {"data":{"ru":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], i10 = i.slice(-1),
          i100 = i.slice(-2);
      if (ord) return 'other';
      return (v0 && i10 == 1 && i100 != 11) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12
              || i100 > 14)) ? 'few'
          : (v0 && i10 == 0 || v0 && (i10 >= 5 && i10 <= 9)
              || v0 && (i100 >= 11 && i100 <= 14)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ru"]},
    {"data":{"rwk":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["rwk"]},
    {"data":{"sah":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sah"]},
    {"data":{"saq":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["saq"]},
    {"data":{"sd":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sd"]},
    {"data":{"se":{"categories":{"cardinal":["one","two","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["se"]},
    {"data":{"seh":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["seh"]},
    {"data":{"ses":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ses"]},
    {"data":{"sg":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sg"]},
    {"data":{"shi":{"categories":{"cardinal":["one","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return 'other';
      return (n >= 0 && n <= 1) ? 'one'
          : ((t0 && n >= 2 && n <= 10)) ? 'few'
          : 'other';
    }}},"aliases":{"shi-MA":"shi-Tfng-MA"},"parentLocales":{},"availableLocales":["shi"]},
    {"data":{"si":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '';
      if (ord) return 'other';
      return ((n == 0 || n == 1)
              || i == 0 && f == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["si"]},
    {"data":{"sk":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one'
          : ((i >= 2 && i <= 4) && v0) ? 'few'
          : (!v0) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sk"]},
    {"data":{"sl":{"categories":{"cardinal":["one","two","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], i100 = i.slice(-2);
      if (ord) return 'other';
      return (v0 && i100 == 1) ? 'one'
          : (v0 && i100 == 2) ? 'two'
          : (v0 && (i100 == 3 || i100 == 4)
              || !v0) ? 'few'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sl"]},
    {"data":{"smn":{"categories":{"cardinal":["one","two","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one'
          : (n == 2) ? 'two'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["smn"]},
    {"data":{"sn":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sn"]},
    {"data":{"so":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["so"]},
    {"data":{"sq":{"categories":{"cardinal":["one","other"],"ordinal":["one","many","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2);
      if (ord) return (n == 1) ? 'one'
          : (n10 == 4 && n100 != 14) ? 'many'
          : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sq"]},
    {"data":{"sr":{"categories":{"cardinal":["one","few","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], f = s[1] || '', v0 = !s[1],
          i10 = i.slice(-1), i100 = i.slice(-2), f10 = f.slice(-1), f100 = f.slice(-2);
      if (ord) return 'other';
      return (v0 && i10 == 1 && i100 != 11
              || f10 == 1 && f100 != 11) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12 || i100 > 14)
              || (f10 >= 2 && f10 <= 4) && (f100 < 12
              || f100 > 14)) ? 'few'
          : 'other';
    }}},"aliases":{"sr-BA":"sr-Cyrl-BA","sr-ME":"sr-Latn-ME","sr-RS":"sr-Cyrl-RS","sr-XK":"sr-Cyrl-XK"},"parentLocales":{},"availableLocales":["sr"]},
    {"data":{"sv":{"categories":{"cardinal":["one","other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1], t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2);
      if (ord) return ((n10 == 1
              || n10 == 2) && n100 != 11 && n100 != 12) ? 'one' : 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sv"]},
    {"data":{"sw":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["sw"]},
    {"data":{"ta":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ta"]},
    {"data":{"te":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["te"]},
    {"data":{"teo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["teo"]},
    {"data":{"th":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["th"]},
    {"data":{"ti":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return ((n == 0
              || n == 1)) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ti"]},
    {"data":{"tk":{"categories":{"cardinal":["one","other"],"ordinal":["few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1);
      if (ord) return ((n10 == 6 || n10 == 9)
              || n == 10) ? 'few' : 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["tk"]},
    {"data":{"to":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["to"]},
    {"data":{"tr":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["tr"]},
    {"data":{"tzm":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), t0 = Number(s[0]) == n;
      if (ord) return 'other';
      return ((n == 0 || n == 1)
              || (t0 && n >= 11 && n <= 99)) ? 'one' : 'other';
    }}},"aliases":{"tzm-Latn-MA":"tzm-MA"},"parentLocales":{},"availableLocales":["tzm"]},
    {"data":{"ug":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"ug-Arab-CN":"ug-CN"},"parentLocales":{},"availableLocales":["ug"]},
    {"data":{"uk":{"categories":{"cardinal":["one","few","many","other"],"ordinal":["few","other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), i = s[0], v0 = !s[1], t0 = Number(s[0]) == n,
          n10 = t0 && s[0].slice(-1), n100 = t0 && s[0].slice(-2), i10 = i.slice(-1),
          i100 = i.slice(-2);
      if (ord) return (n10 == 3 && n100 != 13) ? 'few' : 'other';
      return (v0 && i10 == 1 && i100 != 11) ? 'one'
          : (v0 && (i10 >= 2 && i10 <= 4) && (i100 < 12
              || i100 > 14)) ? 'few'
          : (v0 && i10 == 0 || v0 && (i10 >= 5 && i10 <= 9)
              || v0 && (i100 >= 11 && i100 <= 14)) ? 'many'
          : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["uk"]},
    {"data":{"ur":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["ur"]},
    {"data":{"uz":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{"uz-AF":"uz-Arab-AF","uz-UZ":"uz-Latn-UZ"},"parentLocales":{},"availableLocales":["uz"]},
    {"data":{"vi":{"categories":{"cardinal":["other"],"ordinal":["one","other"]},"fn":function(n, ord) {
      if (ord) return (n == 1) ? 'one' : 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["vi"]},
    {"data":{"vo":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["vo"]},
    {"data":{"vun":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["vun"]},
    {"data":{"wae":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["wae"]},
    {"data":{"wo":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["wo"]},
    {"data":{"xh":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["xh"]},
    {"data":{"xog":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n == 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["xog"]},
    {"data":{"yi":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      var s = String(n).split('.'), v0 = !s[1];
      if (ord) return 'other';
      return (n == 1 && v0) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["yi"]},
    {"data":{"yo":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["yo"]},
    {"data":{"yue":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{"yue-CN":"yue-Hans-CN","yue-HK":"yue-Hant-HK"},"parentLocales":{},"availableLocales":["yue"]},
    {"data":{"zh":{"categories":{"cardinal":["other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return 'other';
    }}},"aliases":{"zh-CN":"zh-Hans-CN","zh-guoyu":"zh","zh-hakka":"hak","zh-HK":"zh-Hant-HK","zh-min-nan":"nan","zh-MO":"zh-Hant-MO","zh-SG":"zh-Hans-SG","zh-TW":"zh-Hant-TW","zh-xiang":"hsn","zh-min":"nan-x-zh-min"},"parentLocales":{"zh-Hant-MO":"zh-Hant-HK"},"availableLocales":["zh"]},
    {"data":{"zu":{"categories":{"cardinal":["one","other"],"ordinal":["other"]},"fn":function(n, ord) {
      if (ord) return 'other';
      return (n >= 0 && n <= 1) ? 'one' : 'other';
    }}},"aliases":{},"parentLocales":{},"availableLocales":["zu"]}
      );
    }

})));