var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);

// node_modules/@hotwired/stimulus/dist/stimulus.js
function extendEvent(event) {
  if ("immediatePropagationStopped" in event) {
    return event;
  } else {
    const { stopImmediatePropagation } = event;
    return Object.assign(event, {
      immediatePropagationStopped: false,
      stopImmediatePropagation() {
        this.immediatePropagationStopped = true;
        stopImmediatePropagation.call(this);
      }
    });
  }
}
function parseActionDescriptorString(descriptorString) {
  const source = descriptorString.trim();
  const matches = source.match(descriptorPattern) || [];
  let eventName = matches[2];
  let keyFilter = matches[3];
  if (keyFilter && !["keydown", "keyup", "keypress"].includes(eventName)) {
    eventName += `.${keyFilter}`;
    keyFilter = "";
  }
  return {
    eventTarget: parseEventTarget(matches[4]),
    eventName,
    eventOptions: matches[7] ? parseEventOptions(matches[7]) : {},
    identifier: matches[5],
    methodName: matches[6],
    keyFilter: matches[1] || keyFilter
  };
}
function parseEventTarget(eventTargetName) {
  if (eventTargetName == "window") {
    return window;
  } else if (eventTargetName == "document") {
    return document;
  }
}
function parseEventOptions(eventOptions) {
  return eventOptions.split(":").reduce((options, token) => Object.assign(options, { [token.replace(/^!/, "")]: !/^!/.test(token) }), {});
}
function stringifyEventTarget(eventTarget) {
  if (eventTarget == window) {
    return "window";
  } else if (eventTarget == document) {
    return "document";
  }
}
function camelize(value) {
  return value.replace(/(?:[_-])([a-z0-9])/g, (_, char) => char.toUpperCase());
}
function namespaceCamelize(value) {
  return camelize(value.replace(/--/g, "-").replace(/__/g, "_"));
}
function capitalize(value) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}
function dasherize(value) {
  return value.replace(/([A-Z])/g, (_, char) => `-${char.toLowerCase()}`);
}
function tokenize(value) {
  return value.match(/[^\s]+/g) || [];
}
function isSomething(object) {
  return object !== null && object !== void 0;
}
function hasProperty(object, property) {
  return Object.prototype.hasOwnProperty.call(object, property);
}
function getDefaultEventNameForElement(element) {
  const tagName = element.tagName.toLowerCase();
  if (tagName in defaultEventNames) {
    return defaultEventNames[tagName](element);
  }
}
function error(message) {
  throw new Error(message);
}
function typecast(value) {
  try {
    return JSON.parse(value);
  } catch (o_O) {
    return value;
  }
}
function add(map, key, value) {
  fetch2(map, key).add(value);
}
function del(map, key, value) {
  fetch2(map, key).delete(value);
  prune(map, key);
}
function fetch2(map, key) {
  let values = map.get(key);
  if (!values) {
    values = /* @__PURE__ */ new Set();
    map.set(key, values);
  }
  return values;
}
function prune(map, key) {
  const values = map.get(key);
  if (values != null && values.size == 0) {
    map.delete(key);
  }
}
function parseTokenString(tokenString, element, attributeName) {
  return tokenString.trim().split(/\s+/).filter((content) => content.length).map((content, index) => ({ element, attributeName, content, index }));
}
function zip(left, right) {
  const length = Math.max(left.length, right.length);
  return Array.from({ length }, (_, index) => [left[index], right[index]]);
}
function tokensAreEqual(left, right) {
  return left && right && left.index == right.index && left.content == right.content;
}
function readInheritableStaticArrayValues(constructor, propertyName) {
  const ancestors = getAncestorsForConstructor(constructor);
  return Array.from(ancestors.reduce((values, constructor2) => {
    getOwnStaticArrayValues(constructor2, propertyName).forEach((name) => values.add(name));
    return values;
  }, /* @__PURE__ */ new Set()));
}
function readInheritableStaticObjectPairs(constructor, propertyName) {
  const ancestors = getAncestorsForConstructor(constructor);
  return ancestors.reduce((pairs, constructor2) => {
    pairs.push(...getOwnStaticObjectPairs(constructor2, propertyName));
    return pairs;
  }, []);
}
function getAncestorsForConstructor(constructor) {
  const ancestors = [];
  while (constructor) {
    ancestors.push(constructor);
    constructor = Object.getPrototypeOf(constructor);
  }
  return ancestors.reverse();
}
function getOwnStaticArrayValues(constructor, propertyName) {
  const definition = constructor[propertyName];
  return Array.isArray(definition) ? definition : [];
}
function getOwnStaticObjectPairs(constructor, propertyName) {
  const definition = constructor[propertyName];
  return definition ? Object.keys(definition).map((key) => [key, definition[key]]) : [];
}
function bless(constructor) {
  return shadow(constructor, getBlessedProperties(constructor));
}
function shadow(constructor, properties) {
  const shadowConstructor = extend(constructor);
  const shadowProperties = getShadowProperties(constructor.prototype, properties);
  Object.defineProperties(shadowConstructor.prototype, shadowProperties);
  return shadowConstructor;
}
function getBlessedProperties(constructor) {
  const blessings = readInheritableStaticArrayValues(constructor, "blessings");
  return blessings.reduce((blessedProperties, blessing) => {
    const properties = blessing(constructor);
    for (const key in properties) {
      const descriptor = blessedProperties[key] || {};
      blessedProperties[key] = Object.assign(descriptor, properties[key]);
    }
    return blessedProperties;
  }, {});
}
function getShadowProperties(prototype, properties) {
  return getOwnKeys(properties).reduce((shadowProperties, key) => {
    const descriptor = getShadowedDescriptor(prototype, properties, key);
    if (descriptor) {
      Object.assign(shadowProperties, { [key]: descriptor });
    }
    return shadowProperties;
  }, {});
}
function getShadowedDescriptor(prototype, properties, key) {
  const shadowingDescriptor = Object.getOwnPropertyDescriptor(prototype, key);
  const shadowedByValue = shadowingDescriptor && "value" in shadowingDescriptor;
  if (!shadowedByValue) {
    const descriptor = Object.getOwnPropertyDescriptor(properties, key).value;
    if (shadowingDescriptor) {
      descriptor.get = shadowingDescriptor.get || descriptor.get;
      descriptor.set = shadowingDescriptor.set || descriptor.set;
    }
    return descriptor;
  }
}
function blessDefinition(definition) {
  return {
    identifier: definition.identifier,
    controllerConstructor: bless(definition.controllerConstructor)
  };
}
function attributeValueContainsToken(attributeName, token) {
  return `[${attributeName}~="${token}"]`;
}
function objectFromEntries(array) {
  return array.reduce((memo, [k, v]) => Object.assign(Object.assign({}, memo), { [k]: v }), {});
}
function domReady() {
  return new Promise((resolve) => {
    if (document.readyState == "loading") {
      document.addEventListener("DOMContentLoaded", () => resolve());
    } else {
      resolve();
    }
  });
}
function ClassPropertiesBlessing(constructor) {
  const classes = readInheritableStaticArrayValues(constructor, "classes");
  return classes.reduce((properties, classDefinition) => {
    return Object.assign(properties, propertiesForClassDefinition(classDefinition));
  }, {});
}
function propertiesForClassDefinition(key) {
  return {
    [`${key}Class`]: {
      get() {
        const { classes } = this;
        if (classes.has(key)) {
          return classes.get(key);
        } else {
          const attribute = classes.getAttributeName(key);
          throw new Error(`Missing attribute "${attribute}"`);
        }
      }
    },
    [`${key}Classes`]: {
      get() {
        return this.classes.getAll(key);
      }
    },
    [`has${capitalize(key)}Class`]: {
      get() {
        return this.classes.has(key);
      }
    }
  };
}
function OutletPropertiesBlessing(constructor) {
  const outlets = readInheritableStaticArrayValues(constructor, "outlets");
  return outlets.reduce((properties, outletDefinition) => {
    return Object.assign(properties, propertiesForOutletDefinition(outletDefinition));
  }, {});
}
function getOutletController(controller, element, identifier) {
  return controller.application.getControllerForElementAndIdentifier(element, identifier);
}
function getControllerAndEnsureConnectedScope(controller, element, outletName) {
  let outletController = getOutletController(controller, element, outletName);
  if (outletController)
    return outletController;
  controller.application.router.proposeToConnectScopeForElementAndIdentifier(element, outletName);
  outletController = getOutletController(controller, element, outletName);
  if (outletController)
    return outletController;
}
function propertiesForOutletDefinition(name) {
  const camelizedName = namespaceCamelize(name);
  return {
    [`${camelizedName}Outlet`]: {
      get() {
        const outletElement = this.outlets.find(name);
        const selector = this.outlets.getSelectorForOutletName(name);
        if (outletElement) {
          const outletController = getControllerAndEnsureConnectedScope(this, outletElement, name);
          if (outletController)
            return outletController;
          throw new Error(`The provided outlet element is missing an outlet controller "${name}" instance for host controller "${this.identifier}"`);
        }
        throw new Error(`Missing outlet element "${name}" for host controller "${this.identifier}". Stimulus couldn't find a matching outlet element using selector "${selector}".`);
      }
    },
    [`${camelizedName}Outlets`]: {
      get() {
        const outlets = this.outlets.findAll(name);
        if (outlets.length > 0) {
          return outlets.map((outletElement) => {
            const outletController = getControllerAndEnsureConnectedScope(this, outletElement, name);
            if (outletController)
              return outletController;
            console.warn(`The provided outlet element is missing an outlet controller "${name}" instance for host controller "${this.identifier}"`, outletElement);
          }).filter((controller) => controller);
        }
        return [];
      }
    },
    [`${camelizedName}OutletElement`]: {
      get() {
        const outletElement = this.outlets.find(name);
        const selector = this.outlets.getSelectorForOutletName(name);
        if (outletElement) {
          return outletElement;
        } else {
          throw new Error(`Missing outlet element "${name}" for host controller "${this.identifier}". Stimulus couldn't find a matching outlet element using selector "${selector}".`);
        }
      }
    },
    [`${camelizedName}OutletElements`]: {
      get() {
        return this.outlets.findAll(name);
      }
    },
    [`has${capitalize(camelizedName)}Outlet`]: {
      get() {
        return this.outlets.has(name);
      }
    }
  };
}
function TargetPropertiesBlessing(constructor) {
  const targets = readInheritableStaticArrayValues(constructor, "targets");
  return targets.reduce((properties, targetDefinition) => {
    return Object.assign(properties, propertiesForTargetDefinition(targetDefinition));
  }, {});
}
function propertiesForTargetDefinition(name) {
  return {
    [`${name}Target`]: {
      get() {
        const target = this.targets.find(name);
        if (target) {
          return target;
        } else {
          throw new Error(`Missing target element "${name}" for "${this.identifier}" controller`);
        }
      }
    },
    [`${name}Targets`]: {
      get() {
        return this.targets.findAll(name);
      }
    },
    [`has${capitalize(name)}Target`]: {
      get() {
        return this.targets.has(name);
      }
    }
  };
}
function ValuePropertiesBlessing(constructor) {
  const valueDefinitionPairs = readInheritableStaticObjectPairs(constructor, "values");
  const propertyDescriptorMap = {
    valueDescriptorMap: {
      get() {
        return valueDefinitionPairs.reduce((result, valueDefinitionPair) => {
          const valueDescriptor = parseValueDefinitionPair(valueDefinitionPair, this.identifier);
          const attributeName = this.data.getAttributeNameForKey(valueDescriptor.key);
          return Object.assign(result, { [attributeName]: valueDescriptor });
        }, {});
      }
    }
  };
  return valueDefinitionPairs.reduce((properties, valueDefinitionPair) => {
    return Object.assign(properties, propertiesForValueDefinitionPair(valueDefinitionPair));
  }, propertyDescriptorMap);
}
function propertiesForValueDefinitionPair(valueDefinitionPair, controller) {
  const definition = parseValueDefinitionPair(valueDefinitionPair, controller);
  const { key, name, reader: read, writer: write } = definition;
  return {
    [name]: {
      get() {
        const value = this.data.get(key);
        if (value !== null) {
          return read(value);
        } else {
          return definition.defaultValue;
        }
      },
      set(value) {
        if (value === void 0) {
          this.data.delete(key);
        } else {
          this.data.set(key, write(value));
        }
      }
    },
    [`has${capitalize(name)}`]: {
      get() {
        return this.data.has(key) || definition.hasCustomDefaultValue;
      }
    }
  };
}
function parseValueDefinitionPair([token, typeDefinition], controller) {
  return valueDescriptorForTokenAndTypeDefinition({
    controller,
    token,
    typeDefinition
  });
}
function parseValueTypeConstant(constant) {
  switch (constant) {
    case Array:
      return "array";
    case Boolean:
      return "boolean";
    case Number:
      return "number";
    case Object:
      return "object";
    case String:
      return "string";
  }
}
function parseValueTypeDefault(defaultValue) {
  switch (typeof defaultValue) {
    case "boolean":
      return "boolean";
    case "number":
      return "number";
    case "string":
      return "string";
  }
  if (Array.isArray(defaultValue))
    return "array";
  if (Object.prototype.toString.call(defaultValue) === "[object Object]")
    return "object";
}
function parseValueTypeObject(payload) {
  const { controller, token, typeObject } = payload;
  const hasType = isSomething(typeObject.type);
  const hasDefault = isSomething(typeObject.default);
  const fullObject = hasType && hasDefault;
  const onlyType = hasType && !hasDefault;
  const onlyDefault = !hasType && hasDefault;
  const typeFromObject = parseValueTypeConstant(typeObject.type);
  const typeFromDefaultValue = parseValueTypeDefault(payload.typeObject.default);
  if (onlyType)
    return typeFromObject;
  if (onlyDefault)
    return typeFromDefaultValue;
  if (typeFromObject !== typeFromDefaultValue) {
    const propertyPath = controller ? `${controller}.${token}` : token;
    throw new Error(`The specified default value for the Stimulus Value "${propertyPath}" must match the defined type "${typeFromObject}". The provided default value of "${typeObject.default}" is of type "${typeFromDefaultValue}".`);
  }
  if (fullObject)
    return typeFromObject;
}
function parseValueTypeDefinition(payload) {
  const { controller, token, typeDefinition } = payload;
  const typeObject = { controller, token, typeObject: typeDefinition };
  const typeFromObject = parseValueTypeObject(typeObject);
  const typeFromDefaultValue = parseValueTypeDefault(typeDefinition);
  const typeFromConstant = parseValueTypeConstant(typeDefinition);
  const type = typeFromObject || typeFromDefaultValue || typeFromConstant;
  if (type)
    return type;
  const propertyPath = controller ? `${controller}.${typeDefinition}` : token;
  throw new Error(`Unknown value type "${propertyPath}" for "${token}" value`);
}
function defaultValueForDefinition(typeDefinition) {
  const constant = parseValueTypeConstant(typeDefinition);
  if (constant)
    return defaultValuesByType[constant];
  const hasDefault = hasProperty(typeDefinition, "default");
  const hasType = hasProperty(typeDefinition, "type");
  const typeObject = typeDefinition;
  if (hasDefault)
    return typeObject.default;
  if (hasType) {
    const { type } = typeObject;
    const constantFromType = parseValueTypeConstant(type);
    if (constantFromType)
      return defaultValuesByType[constantFromType];
  }
  return typeDefinition;
}
function valueDescriptorForTokenAndTypeDefinition(payload) {
  const { token, typeDefinition } = payload;
  const key = `${dasherize(token)}-value`;
  const type = parseValueTypeDefinition(payload);
  return {
    type,
    key,
    name: camelize(key),
    get defaultValue() {
      return defaultValueForDefinition(typeDefinition);
    },
    get hasCustomDefaultValue() {
      return parseValueTypeDefault(typeDefinition) !== void 0;
    },
    reader: readers[type],
    writer: writers[type] || writers.default
  };
}
function writeJSON(value) {
  return JSON.stringify(value);
}
function writeString(value) {
  return `${value}`;
}
var EventListener, Dispatcher, defaultActionDescriptorFilters, descriptorPattern, allModifiers, Action, defaultEventNames, Binding, ElementObserver, AttributeObserver, Multimap, SelectorObserver, StringMapObserver, TokenListObserver, ValueListObserver, BindingObserver, ValueObserver, TargetObserver, OutletObserver, Context, getOwnKeys, extend, Module, ClassMap, DataMap, Guide, TargetSet, OutletSet, Scope, ScopeObserver, Router, defaultSchema, Application, defaultValuesByType, readers, writers, Controller;
var init_stimulus = __esm({
  "node_modules/@hotwired/stimulus/dist/stimulus.js"() {
    EventListener = class {
      constructor(eventTarget, eventName, eventOptions) {
        this.eventTarget = eventTarget;
        this.eventName = eventName;
        this.eventOptions = eventOptions;
        this.unorderedBindings = /* @__PURE__ */ new Set();
      }
      connect() {
        this.eventTarget.addEventListener(this.eventName, this, this.eventOptions);
      }
      disconnect() {
        this.eventTarget.removeEventListener(this.eventName, this, this.eventOptions);
      }
      bindingConnected(binding) {
        this.unorderedBindings.add(binding);
      }
      bindingDisconnected(binding) {
        this.unorderedBindings.delete(binding);
      }
      handleEvent(event) {
        const extendedEvent = extendEvent(event);
        for (const binding of this.bindings) {
          if (extendedEvent.immediatePropagationStopped) {
            break;
          } else {
            binding.handleEvent(extendedEvent);
          }
        }
      }
      hasBindings() {
        return this.unorderedBindings.size > 0;
      }
      get bindings() {
        return Array.from(this.unorderedBindings).sort((left, right) => {
          const leftIndex = left.index, rightIndex = right.index;
          return leftIndex < rightIndex ? -1 : leftIndex > rightIndex ? 1 : 0;
        });
      }
    };
    Dispatcher = class {
      constructor(application) {
        this.application = application;
        this.eventListenerMaps = /* @__PURE__ */ new Map();
        this.started = false;
      }
      start() {
        if (!this.started) {
          this.started = true;
          this.eventListeners.forEach((eventListener) => eventListener.connect());
        }
      }
      stop() {
        if (this.started) {
          this.started = false;
          this.eventListeners.forEach((eventListener) => eventListener.disconnect());
        }
      }
      get eventListeners() {
        return Array.from(this.eventListenerMaps.values()).reduce((listeners, map) => listeners.concat(Array.from(map.values())), []);
      }
      bindingConnected(binding) {
        this.fetchEventListenerForBinding(binding).bindingConnected(binding);
      }
      bindingDisconnected(binding, clearEventListeners = false) {
        this.fetchEventListenerForBinding(binding).bindingDisconnected(binding);
        if (clearEventListeners)
          this.clearEventListenersForBinding(binding);
      }
      handleError(error2, message, detail = {}) {
        this.application.handleError(error2, `Error ${message}`, detail);
      }
      clearEventListenersForBinding(binding) {
        const eventListener = this.fetchEventListenerForBinding(binding);
        if (!eventListener.hasBindings()) {
          eventListener.disconnect();
          this.removeMappedEventListenerFor(binding);
        }
      }
      removeMappedEventListenerFor(binding) {
        const { eventTarget, eventName, eventOptions } = binding;
        const eventListenerMap = this.fetchEventListenerMapForEventTarget(eventTarget);
        const cacheKey = this.cacheKey(eventName, eventOptions);
        eventListenerMap.delete(cacheKey);
        if (eventListenerMap.size == 0)
          this.eventListenerMaps.delete(eventTarget);
      }
      fetchEventListenerForBinding(binding) {
        const { eventTarget, eventName, eventOptions } = binding;
        return this.fetchEventListener(eventTarget, eventName, eventOptions);
      }
      fetchEventListener(eventTarget, eventName, eventOptions) {
        const eventListenerMap = this.fetchEventListenerMapForEventTarget(eventTarget);
        const cacheKey = this.cacheKey(eventName, eventOptions);
        let eventListener = eventListenerMap.get(cacheKey);
        if (!eventListener) {
          eventListener = this.createEventListener(eventTarget, eventName, eventOptions);
          eventListenerMap.set(cacheKey, eventListener);
        }
        return eventListener;
      }
      createEventListener(eventTarget, eventName, eventOptions) {
        const eventListener = new EventListener(eventTarget, eventName, eventOptions);
        if (this.started) {
          eventListener.connect();
        }
        return eventListener;
      }
      fetchEventListenerMapForEventTarget(eventTarget) {
        let eventListenerMap = this.eventListenerMaps.get(eventTarget);
        if (!eventListenerMap) {
          eventListenerMap = /* @__PURE__ */ new Map();
          this.eventListenerMaps.set(eventTarget, eventListenerMap);
        }
        return eventListenerMap;
      }
      cacheKey(eventName, eventOptions) {
        const parts = [eventName];
        Object.keys(eventOptions).sort().forEach((key) => {
          parts.push(`${eventOptions[key] ? "" : "!"}${key}`);
        });
        return parts.join(":");
      }
    };
    defaultActionDescriptorFilters = {
      stop({ event, value }) {
        if (value)
          event.stopPropagation();
        return true;
      },
      prevent({ event, value }) {
        if (value)
          event.preventDefault();
        return true;
      },
      self({ event, value, element }) {
        if (value) {
          return element === event.target;
        } else {
          return true;
        }
      }
    };
    descriptorPattern = /^(?:(?:([^.]+?)\+)?(.+?)(?:\.(.+?))?(?:@(window|document))?->)?(.+?)(?:#([^:]+?))(?::(.+))?$/;
    allModifiers = ["meta", "ctrl", "alt", "shift"];
    Action = class {
      constructor(element, index, descriptor, schema) {
        this.element = element;
        this.index = index;
        this.eventTarget = descriptor.eventTarget || element;
        this.eventName = descriptor.eventName || getDefaultEventNameForElement(element) || error("missing event name");
        this.eventOptions = descriptor.eventOptions || {};
        this.identifier = descriptor.identifier || error("missing identifier");
        this.methodName = descriptor.methodName || error("missing method name");
        this.keyFilter = descriptor.keyFilter || "";
        this.schema = schema;
      }
      static forToken(token, schema) {
        return new this(token.element, token.index, parseActionDescriptorString(token.content), schema);
      }
      toString() {
        const eventFilter = this.keyFilter ? `.${this.keyFilter}` : "";
        const eventTarget = this.eventTargetName ? `@${this.eventTargetName}` : "";
        return `${this.eventName}${eventFilter}${eventTarget}->${this.identifier}#${this.methodName}`;
      }
      shouldIgnoreKeyboardEvent(event) {
        if (!this.keyFilter) {
          return false;
        }
        const filters = this.keyFilter.split("+");
        if (this.keyFilterDissatisfied(event, filters)) {
          return true;
        }
        const standardFilter = filters.filter((key) => !allModifiers.includes(key))[0];
        if (!standardFilter) {
          return false;
        }
        if (!hasProperty(this.keyMappings, standardFilter)) {
          error(`contains unknown key filter: ${this.keyFilter}`);
        }
        return this.keyMappings[standardFilter].toLowerCase() !== event.key.toLowerCase();
      }
      shouldIgnoreMouseEvent(event) {
        if (!this.keyFilter) {
          return false;
        }
        const filters = [this.keyFilter];
        if (this.keyFilterDissatisfied(event, filters)) {
          return true;
        }
        return false;
      }
      get params() {
        const params = {};
        const pattern = new RegExp(`^data-${this.identifier}-(.+)-param$`, "i");
        for (const { name, value } of Array.from(this.element.attributes)) {
          const match = name.match(pattern);
          const key = match && match[1];
          if (key) {
            params[camelize(key)] = typecast(value);
          }
        }
        return params;
      }
      get eventTargetName() {
        return stringifyEventTarget(this.eventTarget);
      }
      get keyMappings() {
        return this.schema.keyMappings;
      }
      keyFilterDissatisfied(event, filters) {
        const [meta, ctrl, alt, shift] = allModifiers.map((modifier) => filters.includes(modifier));
        return event.metaKey !== meta || event.ctrlKey !== ctrl || event.altKey !== alt || event.shiftKey !== shift;
      }
    };
    defaultEventNames = {
      a: () => "click",
      button: () => "click",
      form: () => "submit",
      details: () => "toggle",
      input: (e) => e.getAttribute("type") == "submit" ? "click" : "input",
      select: () => "change",
      textarea: () => "input"
    };
    Binding = class {
      constructor(context, action) {
        this.context = context;
        this.action = action;
      }
      get index() {
        return this.action.index;
      }
      get eventTarget() {
        return this.action.eventTarget;
      }
      get eventOptions() {
        return this.action.eventOptions;
      }
      get identifier() {
        return this.context.identifier;
      }
      handleEvent(event) {
        const actionEvent = this.prepareActionEvent(event);
        if (this.willBeInvokedByEvent(event) && this.applyEventModifiers(actionEvent)) {
          this.invokeWithEvent(actionEvent);
        }
      }
      get eventName() {
        return this.action.eventName;
      }
      get method() {
        const method = this.controller[this.methodName];
        if (typeof method == "function") {
          return method;
        }
        throw new Error(`Action "${this.action}" references undefined method "${this.methodName}"`);
      }
      applyEventModifiers(event) {
        const { element } = this.action;
        const { actionDescriptorFilters } = this.context.application;
        const { controller } = this.context;
        let passes = true;
        for (const [name, value] of Object.entries(this.eventOptions)) {
          if (name in actionDescriptorFilters) {
            const filter = actionDescriptorFilters[name];
            passes = passes && filter({ name, value, event, element, controller });
          } else {
            continue;
          }
        }
        return passes;
      }
      prepareActionEvent(event) {
        return Object.assign(event, { params: this.action.params });
      }
      invokeWithEvent(event) {
        const { target, currentTarget } = event;
        try {
          this.method.call(this.controller, event);
          this.context.logDebugActivity(this.methodName, { event, target, currentTarget, action: this.methodName });
        } catch (error2) {
          const { identifier, controller, element, index } = this;
          const detail = { identifier, controller, element, index, event };
          this.context.handleError(error2, `invoking action "${this.action}"`, detail);
        }
      }
      willBeInvokedByEvent(event) {
        const eventTarget = event.target;
        if (event instanceof KeyboardEvent && this.action.shouldIgnoreKeyboardEvent(event)) {
          return false;
        }
        if (event instanceof MouseEvent && this.action.shouldIgnoreMouseEvent(event)) {
          return false;
        }
        if (this.element === eventTarget) {
          return true;
        } else if (eventTarget instanceof Element && this.element.contains(eventTarget)) {
          return this.scope.containsElement(eventTarget);
        } else {
          return this.scope.containsElement(this.action.element);
        }
      }
      get controller() {
        return this.context.controller;
      }
      get methodName() {
        return this.action.methodName;
      }
      get element() {
        return this.scope.element;
      }
      get scope() {
        return this.context.scope;
      }
    };
    ElementObserver = class {
      constructor(element, delegate) {
        this.mutationObserverInit = { attributes: true, childList: true, subtree: true };
        this.element = element;
        this.started = false;
        this.delegate = delegate;
        this.elements = /* @__PURE__ */ new Set();
        this.mutationObserver = new MutationObserver((mutations) => this.processMutations(mutations));
      }
      start() {
        if (!this.started) {
          this.started = true;
          this.mutationObserver.observe(this.element, this.mutationObserverInit);
          this.refresh();
        }
      }
      pause(callback) {
        if (this.started) {
          this.mutationObserver.disconnect();
          this.started = false;
        }
        callback();
        if (!this.started) {
          this.mutationObserver.observe(this.element, this.mutationObserverInit);
          this.started = true;
        }
      }
      stop() {
        if (this.started) {
          this.mutationObserver.takeRecords();
          this.mutationObserver.disconnect();
          this.started = false;
        }
      }
      refresh() {
        if (this.started) {
          const matches = new Set(this.matchElementsInTree());
          for (const element of Array.from(this.elements)) {
            if (!matches.has(element)) {
              this.removeElement(element);
            }
          }
          for (const element of Array.from(matches)) {
            this.addElement(element);
          }
        }
      }
      processMutations(mutations) {
        if (this.started) {
          for (const mutation of mutations) {
            this.processMutation(mutation);
          }
        }
      }
      processMutation(mutation) {
        if (mutation.type == "attributes") {
          this.processAttributeChange(mutation.target, mutation.attributeName);
        } else if (mutation.type == "childList") {
          this.processRemovedNodes(mutation.removedNodes);
          this.processAddedNodes(mutation.addedNodes);
        }
      }
      processAttributeChange(element, attributeName) {
        if (this.elements.has(element)) {
          if (this.delegate.elementAttributeChanged && this.matchElement(element)) {
            this.delegate.elementAttributeChanged(element, attributeName);
          } else {
            this.removeElement(element);
          }
        } else if (this.matchElement(element)) {
          this.addElement(element);
        }
      }
      processRemovedNodes(nodes) {
        for (const node of Array.from(nodes)) {
          const element = this.elementFromNode(node);
          if (element) {
            this.processTree(element, this.removeElement);
          }
        }
      }
      processAddedNodes(nodes) {
        for (const node of Array.from(nodes)) {
          const element = this.elementFromNode(node);
          if (element && this.elementIsActive(element)) {
            this.processTree(element, this.addElement);
          }
        }
      }
      matchElement(element) {
        return this.delegate.matchElement(element);
      }
      matchElementsInTree(tree = this.element) {
        return this.delegate.matchElementsInTree(tree);
      }
      processTree(tree, processor) {
        for (const element of this.matchElementsInTree(tree)) {
          processor.call(this, element);
        }
      }
      elementFromNode(node) {
        if (node.nodeType == Node.ELEMENT_NODE) {
          return node;
        }
      }
      elementIsActive(element) {
        if (element.isConnected != this.element.isConnected) {
          return false;
        } else {
          return this.element.contains(element);
        }
      }
      addElement(element) {
        if (!this.elements.has(element)) {
          if (this.elementIsActive(element)) {
            this.elements.add(element);
            if (this.delegate.elementMatched) {
              this.delegate.elementMatched(element);
            }
          }
        }
      }
      removeElement(element) {
        if (this.elements.has(element)) {
          this.elements.delete(element);
          if (this.delegate.elementUnmatched) {
            this.delegate.elementUnmatched(element);
          }
        }
      }
    };
    AttributeObserver = class {
      constructor(element, attributeName, delegate) {
        this.attributeName = attributeName;
        this.delegate = delegate;
        this.elementObserver = new ElementObserver(element, this);
      }
      get element() {
        return this.elementObserver.element;
      }
      get selector() {
        return `[${this.attributeName}]`;
      }
      start() {
        this.elementObserver.start();
      }
      pause(callback) {
        this.elementObserver.pause(callback);
      }
      stop() {
        this.elementObserver.stop();
      }
      refresh() {
        this.elementObserver.refresh();
      }
      get started() {
        return this.elementObserver.started;
      }
      matchElement(element) {
        return element.hasAttribute(this.attributeName);
      }
      matchElementsInTree(tree) {
        const match = this.matchElement(tree) ? [tree] : [];
        const matches = Array.from(tree.querySelectorAll(this.selector));
        return match.concat(matches);
      }
      elementMatched(element) {
        if (this.delegate.elementMatchedAttribute) {
          this.delegate.elementMatchedAttribute(element, this.attributeName);
        }
      }
      elementUnmatched(element) {
        if (this.delegate.elementUnmatchedAttribute) {
          this.delegate.elementUnmatchedAttribute(element, this.attributeName);
        }
      }
      elementAttributeChanged(element, attributeName) {
        if (this.delegate.elementAttributeValueChanged && this.attributeName == attributeName) {
          this.delegate.elementAttributeValueChanged(element, attributeName);
        }
      }
    };
    Multimap = class {
      constructor() {
        this.valuesByKey = /* @__PURE__ */ new Map();
      }
      get keys() {
        return Array.from(this.valuesByKey.keys());
      }
      get values() {
        const sets = Array.from(this.valuesByKey.values());
        return sets.reduce((values, set) => values.concat(Array.from(set)), []);
      }
      get size() {
        const sets = Array.from(this.valuesByKey.values());
        return sets.reduce((size, set) => size + set.size, 0);
      }
      add(key, value) {
        add(this.valuesByKey, key, value);
      }
      delete(key, value) {
        del(this.valuesByKey, key, value);
      }
      has(key, value) {
        const values = this.valuesByKey.get(key);
        return values != null && values.has(value);
      }
      hasKey(key) {
        return this.valuesByKey.has(key);
      }
      hasValue(value) {
        const sets = Array.from(this.valuesByKey.values());
        return sets.some((set) => set.has(value));
      }
      getValuesForKey(key) {
        const values = this.valuesByKey.get(key);
        return values ? Array.from(values) : [];
      }
      getKeysForValue(value) {
        return Array.from(this.valuesByKey).filter(([_key, values]) => values.has(value)).map(([key, _values]) => key);
      }
    };
    SelectorObserver = class {
      constructor(element, selector, delegate, details) {
        this._selector = selector;
        this.details = details;
        this.elementObserver = new ElementObserver(element, this);
        this.delegate = delegate;
        this.matchesByElement = new Multimap();
      }
      get started() {
        return this.elementObserver.started;
      }
      get selector() {
        return this._selector;
      }
      set selector(selector) {
        this._selector = selector;
        this.refresh();
      }
      start() {
        this.elementObserver.start();
      }
      pause(callback) {
        this.elementObserver.pause(callback);
      }
      stop() {
        this.elementObserver.stop();
      }
      refresh() {
        this.elementObserver.refresh();
      }
      get element() {
        return this.elementObserver.element;
      }
      matchElement(element) {
        const { selector } = this;
        if (selector) {
          const matches = element.matches(selector);
          if (this.delegate.selectorMatchElement) {
            return matches && this.delegate.selectorMatchElement(element, this.details);
          }
          return matches;
        } else {
          return false;
        }
      }
      matchElementsInTree(tree) {
        const { selector } = this;
        if (selector) {
          const match = this.matchElement(tree) ? [tree] : [];
          const matches = Array.from(tree.querySelectorAll(selector)).filter((match2) => this.matchElement(match2));
          return match.concat(matches);
        } else {
          return [];
        }
      }
      elementMatched(element) {
        const { selector } = this;
        if (selector) {
          this.selectorMatched(element, selector);
        }
      }
      elementUnmatched(element) {
        const selectors = this.matchesByElement.getKeysForValue(element);
        for (const selector of selectors) {
          this.selectorUnmatched(element, selector);
        }
      }
      elementAttributeChanged(element, _attributeName) {
        const { selector } = this;
        if (selector) {
          const matches = this.matchElement(element);
          const matchedBefore = this.matchesByElement.has(selector, element);
          if (matches && !matchedBefore) {
            this.selectorMatched(element, selector);
          } else if (!matches && matchedBefore) {
            this.selectorUnmatched(element, selector);
          }
        }
      }
      selectorMatched(element, selector) {
        this.delegate.selectorMatched(element, selector, this.details);
        this.matchesByElement.add(selector, element);
      }
      selectorUnmatched(element, selector) {
        this.delegate.selectorUnmatched(element, selector, this.details);
        this.matchesByElement.delete(selector, element);
      }
    };
    StringMapObserver = class {
      constructor(element, delegate) {
        this.element = element;
        this.delegate = delegate;
        this.started = false;
        this.stringMap = /* @__PURE__ */ new Map();
        this.mutationObserver = new MutationObserver((mutations) => this.processMutations(mutations));
      }
      start() {
        if (!this.started) {
          this.started = true;
          this.mutationObserver.observe(this.element, { attributes: true, attributeOldValue: true });
          this.refresh();
        }
      }
      stop() {
        if (this.started) {
          this.mutationObserver.takeRecords();
          this.mutationObserver.disconnect();
          this.started = false;
        }
      }
      refresh() {
        if (this.started) {
          for (const attributeName of this.knownAttributeNames) {
            this.refreshAttribute(attributeName, null);
          }
        }
      }
      processMutations(mutations) {
        if (this.started) {
          for (const mutation of mutations) {
            this.processMutation(mutation);
          }
        }
      }
      processMutation(mutation) {
        const attributeName = mutation.attributeName;
        if (attributeName) {
          this.refreshAttribute(attributeName, mutation.oldValue);
        }
      }
      refreshAttribute(attributeName, oldValue) {
        const key = this.delegate.getStringMapKeyForAttribute(attributeName);
        if (key != null) {
          if (!this.stringMap.has(attributeName)) {
            this.stringMapKeyAdded(key, attributeName);
          }
          const value = this.element.getAttribute(attributeName);
          if (this.stringMap.get(attributeName) != value) {
            this.stringMapValueChanged(value, key, oldValue);
          }
          if (value == null) {
            const oldValue2 = this.stringMap.get(attributeName);
            this.stringMap.delete(attributeName);
            if (oldValue2)
              this.stringMapKeyRemoved(key, attributeName, oldValue2);
          } else {
            this.stringMap.set(attributeName, value);
          }
        }
      }
      stringMapKeyAdded(key, attributeName) {
        if (this.delegate.stringMapKeyAdded) {
          this.delegate.stringMapKeyAdded(key, attributeName);
        }
      }
      stringMapValueChanged(value, key, oldValue) {
        if (this.delegate.stringMapValueChanged) {
          this.delegate.stringMapValueChanged(value, key, oldValue);
        }
      }
      stringMapKeyRemoved(key, attributeName, oldValue) {
        if (this.delegate.stringMapKeyRemoved) {
          this.delegate.stringMapKeyRemoved(key, attributeName, oldValue);
        }
      }
      get knownAttributeNames() {
        return Array.from(new Set(this.currentAttributeNames.concat(this.recordedAttributeNames)));
      }
      get currentAttributeNames() {
        return Array.from(this.element.attributes).map((attribute) => attribute.name);
      }
      get recordedAttributeNames() {
        return Array.from(this.stringMap.keys());
      }
    };
    TokenListObserver = class {
      constructor(element, attributeName, delegate) {
        this.attributeObserver = new AttributeObserver(element, attributeName, this);
        this.delegate = delegate;
        this.tokensByElement = new Multimap();
      }
      get started() {
        return this.attributeObserver.started;
      }
      start() {
        this.attributeObserver.start();
      }
      pause(callback) {
        this.attributeObserver.pause(callback);
      }
      stop() {
        this.attributeObserver.stop();
      }
      refresh() {
        this.attributeObserver.refresh();
      }
      get element() {
        return this.attributeObserver.element;
      }
      get attributeName() {
        return this.attributeObserver.attributeName;
      }
      elementMatchedAttribute(element) {
        this.tokensMatched(this.readTokensForElement(element));
      }
      elementAttributeValueChanged(element) {
        const [unmatchedTokens, matchedTokens] = this.refreshTokensForElement(element);
        this.tokensUnmatched(unmatchedTokens);
        this.tokensMatched(matchedTokens);
      }
      elementUnmatchedAttribute(element) {
        this.tokensUnmatched(this.tokensByElement.getValuesForKey(element));
      }
      tokensMatched(tokens) {
        tokens.forEach((token) => this.tokenMatched(token));
      }
      tokensUnmatched(tokens) {
        tokens.forEach((token) => this.tokenUnmatched(token));
      }
      tokenMatched(token) {
        this.delegate.tokenMatched(token);
        this.tokensByElement.add(token.element, token);
      }
      tokenUnmatched(token) {
        this.delegate.tokenUnmatched(token);
        this.tokensByElement.delete(token.element, token);
      }
      refreshTokensForElement(element) {
        const previousTokens = this.tokensByElement.getValuesForKey(element);
        const currentTokens = this.readTokensForElement(element);
        const firstDifferingIndex = zip(previousTokens, currentTokens).findIndex(([previousToken, currentToken]) => !tokensAreEqual(previousToken, currentToken));
        if (firstDifferingIndex == -1) {
          return [[], []];
        } else {
          return [previousTokens.slice(firstDifferingIndex), currentTokens.slice(firstDifferingIndex)];
        }
      }
      readTokensForElement(element) {
        const attributeName = this.attributeName;
        const tokenString = element.getAttribute(attributeName) || "";
        return parseTokenString(tokenString, element, attributeName);
      }
    };
    ValueListObserver = class {
      constructor(element, attributeName, delegate) {
        this.tokenListObserver = new TokenListObserver(element, attributeName, this);
        this.delegate = delegate;
        this.parseResultsByToken = /* @__PURE__ */ new WeakMap();
        this.valuesByTokenByElement = /* @__PURE__ */ new WeakMap();
      }
      get started() {
        return this.tokenListObserver.started;
      }
      start() {
        this.tokenListObserver.start();
      }
      stop() {
        this.tokenListObserver.stop();
      }
      refresh() {
        this.tokenListObserver.refresh();
      }
      get element() {
        return this.tokenListObserver.element;
      }
      get attributeName() {
        return this.tokenListObserver.attributeName;
      }
      tokenMatched(token) {
        const { element } = token;
        const { value } = this.fetchParseResultForToken(token);
        if (value) {
          this.fetchValuesByTokenForElement(element).set(token, value);
          this.delegate.elementMatchedValue(element, value);
        }
      }
      tokenUnmatched(token) {
        const { element } = token;
        const { value } = this.fetchParseResultForToken(token);
        if (value) {
          this.fetchValuesByTokenForElement(element).delete(token);
          this.delegate.elementUnmatchedValue(element, value);
        }
      }
      fetchParseResultForToken(token) {
        let parseResult = this.parseResultsByToken.get(token);
        if (!parseResult) {
          parseResult = this.parseToken(token);
          this.parseResultsByToken.set(token, parseResult);
        }
        return parseResult;
      }
      fetchValuesByTokenForElement(element) {
        let valuesByToken = this.valuesByTokenByElement.get(element);
        if (!valuesByToken) {
          valuesByToken = /* @__PURE__ */ new Map();
          this.valuesByTokenByElement.set(element, valuesByToken);
        }
        return valuesByToken;
      }
      parseToken(token) {
        try {
          const value = this.delegate.parseValueForToken(token);
          return { value };
        } catch (error2) {
          return { error: error2 };
        }
      }
    };
    BindingObserver = class {
      constructor(context, delegate) {
        this.context = context;
        this.delegate = delegate;
        this.bindingsByAction = /* @__PURE__ */ new Map();
      }
      start() {
        if (!this.valueListObserver) {
          this.valueListObserver = new ValueListObserver(this.element, this.actionAttribute, this);
          this.valueListObserver.start();
        }
      }
      stop() {
        if (this.valueListObserver) {
          this.valueListObserver.stop();
          delete this.valueListObserver;
          this.disconnectAllActions();
        }
      }
      get element() {
        return this.context.element;
      }
      get identifier() {
        return this.context.identifier;
      }
      get actionAttribute() {
        return this.schema.actionAttribute;
      }
      get schema() {
        return this.context.schema;
      }
      get bindings() {
        return Array.from(this.bindingsByAction.values());
      }
      connectAction(action) {
        const binding = new Binding(this.context, action);
        this.bindingsByAction.set(action, binding);
        this.delegate.bindingConnected(binding);
      }
      disconnectAction(action) {
        const binding = this.bindingsByAction.get(action);
        if (binding) {
          this.bindingsByAction.delete(action);
          this.delegate.bindingDisconnected(binding);
        }
      }
      disconnectAllActions() {
        this.bindings.forEach((binding) => this.delegate.bindingDisconnected(binding, true));
        this.bindingsByAction.clear();
      }
      parseValueForToken(token) {
        const action = Action.forToken(token, this.schema);
        if (action.identifier == this.identifier) {
          return action;
        }
      }
      elementMatchedValue(element, action) {
        this.connectAction(action);
      }
      elementUnmatchedValue(element, action) {
        this.disconnectAction(action);
      }
    };
    ValueObserver = class {
      constructor(context, receiver) {
        this.context = context;
        this.receiver = receiver;
        this.stringMapObserver = new StringMapObserver(this.element, this);
        this.valueDescriptorMap = this.controller.valueDescriptorMap;
      }
      start() {
        this.stringMapObserver.start();
        this.invokeChangedCallbacksForDefaultValues();
      }
      stop() {
        this.stringMapObserver.stop();
      }
      get element() {
        return this.context.element;
      }
      get controller() {
        return this.context.controller;
      }
      getStringMapKeyForAttribute(attributeName) {
        if (attributeName in this.valueDescriptorMap) {
          return this.valueDescriptorMap[attributeName].name;
        }
      }
      stringMapKeyAdded(key, attributeName) {
        const descriptor = this.valueDescriptorMap[attributeName];
        if (!this.hasValue(key)) {
          this.invokeChangedCallback(key, descriptor.writer(this.receiver[key]), descriptor.writer(descriptor.defaultValue));
        }
      }
      stringMapValueChanged(value, name, oldValue) {
        const descriptor = this.valueDescriptorNameMap[name];
        if (value === null)
          return;
        if (oldValue === null) {
          oldValue = descriptor.writer(descriptor.defaultValue);
        }
        this.invokeChangedCallback(name, value, oldValue);
      }
      stringMapKeyRemoved(key, attributeName, oldValue) {
        const descriptor = this.valueDescriptorNameMap[key];
        if (this.hasValue(key)) {
          this.invokeChangedCallback(key, descriptor.writer(this.receiver[key]), oldValue);
        } else {
          this.invokeChangedCallback(key, descriptor.writer(descriptor.defaultValue), oldValue);
        }
      }
      invokeChangedCallbacksForDefaultValues() {
        for (const { key, name, defaultValue, writer } of this.valueDescriptors) {
          if (defaultValue != void 0 && !this.controller.data.has(key)) {
            this.invokeChangedCallback(name, writer(defaultValue), void 0);
          }
        }
      }
      invokeChangedCallback(name, rawValue, rawOldValue) {
        const changedMethodName = `${name}Changed`;
        const changedMethod = this.receiver[changedMethodName];
        if (typeof changedMethod == "function") {
          const descriptor = this.valueDescriptorNameMap[name];
          try {
            const value = descriptor.reader(rawValue);
            let oldValue = rawOldValue;
            if (rawOldValue) {
              oldValue = descriptor.reader(rawOldValue);
            }
            changedMethod.call(this.receiver, value, oldValue);
          } catch (error2) {
            if (error2 instanceof TypeError) {
              error2.message = `Stimulus Value "${this.context.identifier}.${descriptor.name}" - ${error2.message}`;
            }
            throw error2;
          }
        }
      }
      get valueDescriptors() {
        const { valueDescriptorMap } = this;
        return Object.keys(valueDescriptorMap).map((key) => valueDescriptorMap[key]);
      }
      get valueDescriptorNameMap() {
        const descriptors = {};
        Object.keys(this.valueDescriptorMap).forEach((key) => {
          const descriptor = this.valueDescriptorMap[key];
          descriptors[descriptor.name] = descriptor;
        });
        return descriptors;
      }
      hasValue(attributeName) {
        const descriptor = this.valueDescriptorNameMap[attributeName];
        const hasMethodName = `has${capitalize(descriptor.name)}`;
        return this.receiver[hasMethodName];
      }
    };
    TargetObserver = class {
      constructor(context, delegate) {
        this.context = context;
        this.delegate = delegate;
        this.targetsByName = new Multimap();
      }
      start() {
        if (!this.tokenListObserver) {
          this.tokenListObserver = new TokenListObserver(this.element, this.attributeName, this);
          this.tokenListObserver.start();
        }
      }
      stop() {
        if (this.tokenListObserver) {
          this.disconnectAllTargets();
          this.tokenListObserver.stop();
          delete this.tokenListObserver;
        }
      }
      tokenMatched({ element, content: name }) {
        if (this.scope.containsElement(element)) {
          this.connectTarget(element, name);
        }
      }
      tokenUnmatched({ element, content: name }) {
        this.disconnectTarget(element, name);
      }
      connectTarget(element, name) {
        var _a;
        if (!this.targetsByName.has(name, element)) {
          this.targetsByName.add(name, element);
          (_a = this.tokenListObserver) === null || _a === void 0 ? void 0 : _a.pause(() => this.delegate.targetConnected(element, name));
        }
      }
      disconnectTarget(element, name) {
        var _a;
        if (this.targetsByName.has(name, element)) {
          this.targetsByName.delete(name, element);
          (_a = this.tokenListObserver) === null || _a === void 0 ? void 0 : _a.pause(() => this.delegate.targetDisconnected(element, name));
        }
      }
      disconnectAllTargets() {
        for (const name of this.targetsByName.keys) {
          for (const element of this.targetsByName.getValuesForKey(name)) {
            this.disconnectTarget(element, name);
          }
        }
      }
      get attributeName() {
        return `data-${this.context.identifier}-target`;
      }
      get element() {
        return this.context.element;
      }
      get scope() {
        return this.context.scope;
      }
    };
    OutletObserver = class {
      constructor(context, delegate) {
        this.started = false;
        this.context = context;
        this.delegate = delegate;
        this.outletsByName = new Multimap();
        this.outletElementsByName = new Multimap();
        this.selectorObserverMap = /* @__PURE__ */ new Map();
        this.attributeObserverMap = /* @__PURE__ */ new Map();
      }
      start() {
        if (!this.started) {
          this.outletDefinitions.forEach((outletName) => {
            this.setupSelectorObserverForOutlet(outletName);
            this.setupAttributeObserverForOutlet(outletName);
          });
          this.started = true;
          this.dependentContexts.forEach((context) => context.refresh());
        }
      }
      refresh() {
        this.selectorObserverMap.forEach((observer) => observer.refresh());
        this.attributeObserverMap.forEach((observer) => observer.refresh());
      }
      stop() {
        if (this.started) {
          this.started = false;
          this.disconnectAllOutlets();
          this.stopSelectorObservers();
          this.stopAttributeObservers();
        }
      }
      stopSelectorObservers() {
        if (this.selectorObserverMap.size > 0) {
          this.selectorObserverMap.forEach((observer) => observer.stop());
          this.selectorObserverMap.clear();
        }
      }
      stopAttributeObservers() {
        if (this.attributeObserverMap.size > 0) {
          this.attributeObserverMap.forEach((observer) => observer.stop());
          this.attributeObserverMap.clear();
        }
      }
      selectorMatched(element, _selector, { outletName }) {
        const outlet = this.getOutlet(element, outletName);
        if (outlet) {
          this.connectOutlet(outlet, element, outletName);
        }
      }
      selectorUnmatched(element, _selector, { outletName }) {
        const outlet = this.getOutletFromMap(element, outletName);
        if (outlet) {
          this.disconnectOutlet(outlet, element, outletName);
        }
      }
      selectorMatchElement(element, { outletName }) {
        const selector = this.selector(outletName);
        const hasOutlet = this.hasOutlet(element, outletName);
        const hasOutletController = element.matches(`[${this.schema.controllerAttribute}~=${outletName}]`);
        if (selector) {
          return hasOutlet && hasOutletController && element.matches(selector);
        } else {
          return false;
        }
      }
      elementMatchedAttribute(_element, attributeName) {
        const outletName = this.getOutletNameFromOutletAttributeName(attributeName);
        if (outletName) {
          this.updateSelectorObserverForOutlet(outletName);
        }
      }
      elementAttributeValueChanged(_element, attributeName) {
        const outletName = this.getOutletNameFromOutletAttributeName(attributeName);
        if (outletName) {
          this.updateSelectorObserverForOutlet(outletName);
        }
      }
      elementUnmatchedAttribute(_element, attributeName) {
        const outletName = this.getOutletNameFromOutletAttributeName(attributeName);
        if (outletName) {
          this.updateSelectorObserverForOutlet(outletName);
        }
      }
      connectOutlet(outlet, element, outletName) {
        var _a;
        if (!this.outletElementsByName.has(outletName, element)) {
          this.outletsByName.add(outletName, outlet);
          this.outletElementsByName.add(outletName, element);
          (_a = this.selectorObserverMap.get(outletName)) === null || _a === void 0 ? void 0 : _a.pause(() => this.delegate.outletConnected(outlet, element, outletName));
        }
      }
      disconnectOutlet(outlet, element, outletName) {
        var _a;
        if (this.outletElementsByName.has(outletName, element)) {
          this.outletsByName.delete(outletName, outlet);
          this.outletElementsByName.delete(outletName, element);
          (_a = this.selectorObserverMap.get(outletName)) === null || _a === void 0 ? void 0 : _a.pause(() => this.delegate.outletDisconnected(outlet, element, outletName));
        }
      }
      disconnectAllOutlets() {
        for (const outletName of this.outletElementsByName.keys) {
          for (const element of this.outletElementsByName.getValuesForKey(outletName)) {
            for (const outlet of this.outletsByName.getValuesForKey(outletName)) {
              this.disconnectOutlet(outlet, element, outletName);
            }
          }
        }
      }
      updateSelectorObserverForOutlet(outletName) {
        const observer = this.selectorObserverMap.get(outletName);
        if (observer) {
          observer.selector = this.selector(outletName);
        }
      }
      setupSelectorObserverForOutlet(outletName) {
        const selector = this.selector(outletName);
        const selectorObserver = new SelectorObserver(document.body, selector, this, { outletName });
        this.selectorObserverMap.set(outletName, selectorObserver);
        selectorObserver.start();
      }
      setupAttributeObserverForOutlet(outletName) {
        const attributeName = this.attributeNameForOutletName(outletName);
        const attributeObserver = new AttributeObserver(this.scope.element, attributeName, this);
        this.attributeObserverMap.set(outletName, attributeObserver);
        attributeObserver.start();
      }
      selector(outletName) {
        return this.scope.outlets.getSelectorForOutletName(outletName);
      }
      attributeNameForOutletName(outletName) {
        return this.scope.schema.outletAttributeForScope(this.identifier, outletName);
      }
      getOutletNameFromOutletAttributeName(attributeName) {
        return this.outletDefinitions.find((outletName) => this.attributeNameForOutletName(outletName) === attributeName);
      }
      get outletDependencies() {
        const dependencies = new Multimap();
        this.router.modules.forEach((module) => {
          const constructor = module.definition.controllerConstructor;
          const outlets = readInheritableStaticArrayValues(constructor, "outlets");
          outlets.forEach((outlet) => dependencies.add(outlet, module.identifier));
        });
        return dependencies;
      }
      get outletDefinitions() {
        return this.outletDependencies.getKeysForValue(this.identifier);
      }
      get dependentControllerIdentifiers() {
        return this.outletDependencies.getValuesForKey(this.identifier);
      }
      get dependentContexts() {
        const identifiers = this.dependentControllerIdentifiers;
        return this.router.contexts.filter((context) => identifiers.includes(context.identifier));
      }
      hasOutlet(element, outletName) {
        return !!this.getOutlet(element, outletName) || !!this.getOutletFromMap(element, outletName);
      }
      getOutlet(element, outletName) {
        return this.application.getControllerForElementAndIdentifier(element, outletName);
      }
      getOutletFromMap(element, outletName) {
        return this.outletsByName.getValuesForKey(outletName).find((outlet) => outlet.element === element);
      }
      get scope() {
        return this.context.scope;
      }
      get schema() {
        return this.context.schema;
      }
      get identifier() {
        return this.context.identifier;
      }
      get application() {
        return this.context.application;
      }
      get router() {
        return this.application.router;
      }
    };
    Context = class {
      constructor(module, scope) {
        this.logDebugActivity = (functionName, detail = {}) => {
          const { identifier, controller, element } = this;
          detail = Object.assign({ identifier, controller, element }, detail);
          this.application.logDebugActivity(this.identifier, functionName, detail);
        };
        this.module = module;
        this.scope = scope;
        this.controller = new module.controllerConstructor(this);
        this.bindingObserver = new BindingObserver(this, this.dispatcher);
        this.valueObserver = new ValueObserver(this, this.controller);
        this.targetObserver = new TargetObserver(this, this);
        this.outletObserver = new OutletObserver(this, this);
        try {
          this.controller.initialize();
          this.logDebugActivity("initialize");
        } catch (error2) {
          this.handleError(error2, "initializing controller");
        }
      }
      connect() {
        this.bindingObserver.start();
        this.valueObserver.start();
        this.targetObserver.start();
        this.outletObserver.start();
        try {
          this.controller.connect();
          this.logDebugActivity("connect");
        } catch (error2) {
          this.handleError(error2, "connecting controller");
        }
      }
      refresh() {
        this.outletObserver.refresh();
      }
      disconnect() {
        try {
          this.controller.disconnect();
          this.logDebugActivity("disconnect");
        } catch (error2) {
          this.handleError(error2, "disconnecting controller");
        }
        this.outletObserver.stop();
        this.targetObserver.stop();
        this.valueObserver.stop();
        this.bindingObserver.stop();
      }
      get application() {
        return this.module.application;
      }
      get identifier() {
        return this.module.identifier;
      }
      get schema() {
        return this.application.schema;
      }
      get dispatcher() {
        return this.application.dispatcher;
      }
      get element() {
        return this.scope.element;
      }
      get parentElement() {
        return this.element.parentElement;
      }
      handleError(error2, message, detail = {}) {
        const { identifier, controller, element } = this;
        detail = Object.assign({ identifier, controller, element }, detail);
        this.application.handleError(error2, `Error ${message}`, detail);
      }
      targetConnected(element, name) {
        this.invokeControllerMethod(`${name}TargetConnected`, element);
      }
      targetDisconnected(element, name) {
        this.invokeControllerMethod(`${name}TargetDisconnected`, element);
      }
      outletConnected(outlet, element, name) {
        this.invokeControllerMethod(`${namespaceCamelize(name)}OutletConnected`, outlet, element);
      }
      outletDisconnected(outlet, element, name) {
        this.invokeControllerMethod(`${namespaceCamelize(name)}OutletDisconnected`, outlet, element);
      }
      invokeControllerMethod(methodName, ...args) {
        const controller = this.controller;
        if (typeof controller[methodName] == "function") {
          controller[methodName](...args);
        }
      }
    };
    getOwnKeys = (() => {
      if (typeof Object.getOwnPropertySymbols == "function") {
        return (object) => [...Object.getOwnPropertyNames(object), ...Object.getOwnPropertySymbols(object)];
      } else {
        return Object.getOwnPropertyNames;
      }
    })();
    extend = (() => {
      function extendWithReflect(constructor) {
        function extended() {
          return Reflect.construct(constructor, arguments, new.target);
        }
        extended.prototype = Object.create(constructor.prototype, {
          constructor: { value: extended }
        });
        Reflect.setPrototypeOf(extended, constructor);
        return extended;
      }
      function testReflectExtension() {
        const a = function() {
          this.a.call(this);
        };
        const b = extendWithReflect(a);
        b.prototype.a = function() {
        };
        return new b();
      }
      try {
        testReflectExtension();
        return extendWithReflect;
      } catch (error2) {
        return (constructor) => class extended extends constructor {
        };
      }
    })();
    Module = class {
      constructor(application, definition) {
        this.application = application;
        this.definition = blessDefinition(definition);
        this.contextsByScope = /* @__PURE__ */ new WeakMap();
        this.connectedContexts = /* @__PURE__ */ new Set();
      }
      get identifier() {
        return this.definition.identifier;
      }
      get controllerConstructor() {
        return this.definition.controllerConstructor;
      }
      get contexts() {
        return Array.from(this.connectedContexts);
      }
      connectContextForScope(scope) {
        const context = this.fetchContextForScope(scope);
        this.connectedContexts.add(context);
        context.connect();
      }
      disconnectContextForScope(scope) {
        const context = this.contextsByScope.get(scope);
        if (context) {
          this.connectedContexts.delete(context);
          context.disconnect();
        }
      }
      fetchContextForScope(scope) {
        let context = this.contextsByScope.get(scope);
        if (!context) {
          context = new Context(this, scope);
          this.contextsByScope.set(scope, context);
        }
        return context;
      }
    };
    ClassMap = class {
      constructor(scope) {
        this.scope = scope;
      }
      has(name) {
        return this.data.has(this.getDataKey(name));
      }
      get(name) {
        return this.getAll(name)[0];
      }
      getAll(name) {
        const tokenString = this.data.get(this.getDataKey(name)) || "";
        return tokenize(tokenString);
      }
      getAttributeName(name) {
        return this.data.getAttributeNameForKey(this.getDataKey(name));
      }
      getDataKey(name) {
        return `${name}-class`;
      }
      get data() {
        return this.scope.data;
      }
    };
    DataMap = class {
      constructor(scope) {
        this.scope = scope;
      }
      get element() {
        return this.scope.element;
      }
      get identifier() {
        return this.scope.identifier;
      }
      get(key) {
        const name = this.getAttributeNameForKey(key);
        return this.element.getAttribute(name);
      }
      set(key, value) {
        const name = this.getAttributeNameForKey(key);
        this.element.setAttribute(name, value);
        return this.get(key);
      }
      has(key) {
        const name = this.getAttributeNameForKey(key);
        return this.element.hasAttribute(name);
      }
      delete(key) {
        if (this.has(key)) {
          const name = this.getAttributeNameForKey(key);
          this.element.removeAttribute(name);
          return true;
        } else {
          return false;
        }
      }
      getAttributeNameForKey(key) {
        return `data-${this.identifier}-${dasherize(key)}`;
      }
    };
    Guide = class {
      constructor(logger) {
        this.warnedKeysByObject = /* @__PURE__ */ new WeakMap();
        this.logger = logger;
      }
      warn(object, key, message) {
        let warnedKeys = this.warnedKeysByObject.get(object);
        if (!warnedKeys) {
          warnedKeys = /* @__PURE__ */ new Set();
          this.warnedKeysByObject.set(object, warnedKeys);
        }
        if (!warnedKeys.has(key)) {
          warnedKeys.add(key);
          this.logger.warn(message, object);
        }
      }
    };
    TargetSet = class {
      constructor(scope) {
        this.scope = scope;
      }
      get element() {
        return this.scope.element;
      }
      get identifier() {
        return this.scope.identifier;
      }
      get schema() {
        return this.scope.schema;
      }
      has(targetName) {
        return this.find(targetName) != null;
      }
      find(...targetNames) {
        return targetNames.reduce((target, targetName) => target || this.findTarget(targetName) || this.findLegacyTarget(targetName), void 0);
      }
      findAll(...targetNames) {
        return targetNames.reduce((targets, targetName) => [
          ...targets,
          ...this.findAllTargets(targetName),
          ...this.findAllLegacyTargets(targetName)
        ], []);
      }
      findTarget(targetName) {
        const selector = this.getSelectorForTargetName(targetName);
        return this.scope.findElement(selector);
      }
      findAllTargets(targetName) {
        const selector = this.getSelectorForTargetName(targetName);
        return this.scope.findAllElements(selector);
      }
      getSelectorForTargetName(targetName) {
        const attributeName = this.schema.targetAttributeForScope(this.identifier);
        return attributeValueContainsToken(attributeName, targetName);
      }
      findLegacyTarget(targetName) {
        const selector = this.getLegacySelectorForTargetName(targetName);
        return this.deprecate(this.scope.findElement(selector), targetName);
      }
      findAllLegacyTargets(targetName) {
        const selector = this.getLegacySelectorForTargetName(targetName);
        return this.scope.findAllElements(selector).map((element) => this.deprecate(element, targetName));
      }
      getLegacySelectorForTargetName(targetName) {
        const targetDescriptor = `${this.identifier}.${targetName}`;
        return attributeValueContainsToken(this.schema.targetAttribute, targetDescriptor);
      }
      deprecate(element, targetName) {
        if (element) {
          const { identifier } = this;
          const attributeName = this.schema.targetAttribute;
          const revisedAttributeName = this.schema.targetAttributeForScope(identifier);
          this.guide.warn(element, `target:${targetName}`, `Please replace ${attributeName}="${identifier}.${targetName}" with ${revisedAttributeName}="${targetName}". The ${attributeName} attribute is deprecated and will be removed in a future version of Stimulus.`);
        }
        return element;
      }
      get guide() {
        return this.scope.guide;
      }
    };
    OutletSet = class {
      constructor(scope, controllerElement) {
        this.scope = scope;
        this.controllerElement = controllerElement;
      }
      get element() {
        return this.scope.element;
      }
      get identifier() {
        return this.scope.identifier;
      }
      get schema() {
        return this.scope.schema;
      }
      has(outletName) {
        return this.find(outletName) != null;
      }
      find(...outletNames) {
        return outletNames.reduce((outlet, outletName) => outlet || this.findOutlet(outletName), void 0);
      }
      findAll(...outletNames) {
        return outletNames.reduce((outlets, outletName) => [...outlets, ...this.findAllOutlets(outletName)], []);
      }
      getSelectorForOutletName(outletName) {
        const attributeName = this.schema.outletAttributeForScope(this.identifier, outletName);
        return this.controllerElement.getAttribute(attributeName);
      }
      findOutlet(outletName) {
        const selector = this.getSelectorForOutletName(outletName);
        if (selector)
          return this.findElement(selector, outletName);
      }
      findAllOutlets(outletName) {
        const selector = this.getSelectorForOutletName(outletName);
        return selector ? this.findAllElements(selector, outletName) : [];
      }
      findElement(selector, outletName) {
        const elements = this.scope.queryElements(selector);
        return elements.filter((element) => this.matchesElement(element, selector, outletName))[0];
      }
      findAllElements(selector, outletName) {
        const elements = this.scope.queryElements(selector);
        return elements.filter((element) => this.matchesElement(element, selector, outletName));
      }
      matchesElement(element, selector, outletName) {
        const controllerAttribute = element.getAttribute(this.scope.schema.controllerAttribute) || "";
        return element.matches(selector) && controllerAttribute.split(" ").includes(outletName);
      }
    };
    Scope = class _Scope {
      constructor(schema, element, identifier, logger) {
        this.targets = new TargetSet(this);
        this.classes = new ClassMap(this);
        this.data = new DataMap(this);
        this.containsElement = (element2) => {
          return element2.closest(this.controllerSelector) === this.element;
        };
        this.schema = schema;
        this.element = element;
        this.identifier = identifier;
        this.guide = new Guide(logger);
        this.outlets = new OutletSet(this.documentScope, element);
      }
      findElement(selector) {
        return this.element.matches(selector) ? this.element : this.queryElements(selector).find(this.containsElement);
      }
      findAllElements(selector) {
        return [
          ...this.element.matches(selector) ? [this.element] : [],
          ...this.queryElements(selector).filter(this.containsElement)
        ];
      }
      queryElements(selector) {
        return Array.from(this.element.querySelectorAll(selector));
      }
      get controllerSelector() {
        return attributeValueContainsToken(this.schema.controllerAttribute, this.identifier);
      }
      get isDocumentScope() {
        return this.element === document.documentElement;
      }
      get documentScope() {
        return this.isDocumentScope ? this : new _Scope(this.schema, document.documentElement, this.identifier, this.guide.logger);
      }
    };
    ScopeObserver = class {
      constructor(element, schema, delegate) {
        this.element = element;
        this.schema = schema;
        this.delegate = delegate;
        this.valueListObserver = new ValueListObserver(this.element, this.controllerAttribute, this);
        this.scopesByIdentifierByElement = /* @__PURE__ */ new WeakMap();
        this.scopeReferenceCounts = /* @__PURE__ */ new WeakMap();
      }
      start() {
        this.valueListObserver.start();
      }
      stop() {
        this.valueListObserver.stop();
      }
      get controllerAttribute() {
        return this.schema.controllerAttribute;
      }
      parseValueForToken(token) {
        const { element, content: identifier } = token;
        return this.parseValueForElementAndIdentifier(element, identifier);
      }
      parseValueForElementAndIdentifier(element, identifier) {
        const scopesByIdentifier = this.fetchScopesByIdentifierForElement(element);
        let scope = scopesByIdentifier.get(identifier);
        if (!scope) {
          scope = this.delegate.createScopeForElementAndIdentifier(element, identifier);
          scopesByIdentifier.set(identifier, scope);
        }
        return scope;
      }
      elementMatchedValue(element, value) {
        const referenceCount = (this.scopeReferenceCounts.get(value) || 0) + 1;
        this.scopeReferenceCounts.set(value, referenceCount);
        if (referenceCount == 1) {
          this.delegate.scopeConnected(value);
        }
      }
      elementUnmatchedValue(element, value) {
        const referenceCount = this.scopeReferenceCounts.get(value);
        if (referenceCount) {
          this.scopeReferenceCounts.set(value, referenceCount - 1);
          if (referenceCount == 1) {
            this.delegate.scopeDisconnected(value);
          }
        }
      }
      fetchScopesByIdentifierForElement(element) {
        let scopesByIdentifier = this.scopesByIdentifierByElement.get(element);
        if (!scopesByIdentifier) {
          scopesByIdentifier = /* @__PURE__ */ new Map();
          this.scopesByIdentifierByElement.set(element, scopesByIdentifier);
        }
        return scopesByIdentifier;
      }
    };
    Router = class {
      constructor(application) {
        this.application = application;
        this.scopeObserver = new ScopeObserver(this.element, this.schema, this);
        this.scopesByIdentifier = new Multimap();
        this.modulesByIdentifier = /* @__PURE__ */ new Map();
      }
      get element() {
        return this.application.element;
      }
      get schema() {
        return this.application.schema;
      }
      get logger() {
        return this.application.logger;
      }
      get controllerAttribute() {
        return this.schema.controllerAttribute;
      }
      get modules() {
        return Array.from(this.modulesByIdentifier.values());
      }
      get contexts() {
        return this.modules.reduce((contexts, module) => contexts.concat(module.contexts), []);
      }
      start() {
        this.scopeObserver.start();
      }
      stop() {
        this.scopeObserver.stop();
      }
      loadDefinition(definition) {
        this.unloadIdentifier(definition.identifier);
        const module = new Module(this.application, definition);
        this.connectModule(module);
        const afterLoad = definition.controllerConstructor.afterLoad;
        if (afterLoad) {
          afterLoad.call(definition.controllerConstructor, definition.identifier, this.application);
        }
      }
      unloadIdentifier(identifier) {
        const module = this.modulesByIdentifier.get(identifier);
        if (module) {
          this.disconnectModule(module);
        }
      }
      getContextForElementAndIdentifier(element, identifier) {
        const module = this.modulesByIdentifier.get(identifier);
        if (module) {
          return module.contexts.find((context) => context.element == element);
        }
      }
      proposeToConnectScopeForElementAndIdentifier(element, identifier) {
        const scope = this.scopeObserver.parseValueForElementAndIdentifier(element, identifier);
        if (scope) {
          this.scopeObserver.elementMatchedValue(scope.element, scope);
        } else {
          console.error(`Couldn't find or create scope for identifier: "${identifier}" and element:`, element);
        }
      }
      handleError(error2, message, detail) {
        this.application.handleError(error2, message, detail);
      }
      createScopeForElementAndIdentifier(element, identifier) {
        return new Scope(this.schema, element, identifier, this.logger);
      }
      scopeConnected(scope) {
        this.scopesByIdentifier.add(scope.identifier, scope);
        const module = this.modulesByIdentifier.get(scope.identifier);
        if (module) {
          module.connectContextForScope(scope);
        }
      }
      scopeDisconnected(scope) {
        this.scopesByIdentifier.delete(scope.identifier, scope);
        const module = this.modulesByIdentifier.get(scope.identifier);
        if (module) {
          module.disconnectContextForScope(scope);
        }
      }
      connectModule(module) {
        this.modulesByIdentifier.set(module.identifier, module);
        const scopes = this.scopesByIdentifier.getValuesForKey(module.identifier);
        scopes.forEach((scope) => module.connectContextForScope(scope));
      }
      disconnectModule(module) {
        this.modulesByIdentifier.delete(module.identifier);
        const scopes = this.scopesByIdentifier.getValuesForKey(module.identifier);
        scopes.forEach((scope) => module.disconnectContextForScope(scope));
      }
    };
    defaultSchema = {
      controllerAttribute: "data-controller",
      actionAttribute: "data-action",
      targetAttribute: "data-target",
      targetAttributeForScope: (identifier) => `data-${identifier}-target`,
      outletAttributeForScope: (identifier, outlet) => `data-${identifier}-${outlet}-outlet`,
      keyMappings: Object.assign(Object.assign({ enter: "Enter", tab: "Tab", esc: "Escape", space: " ", up: "ArrowUp", down: "ArrowDown", left: "ArrowLeft", right: "ArrowRight", home: "Home", end: "End", page_up: "PageUp", page_down: "PageDown" }, objectFromEntries("abcdefghijklmnopqrstuvwxyz".split("").map((c) => [c, c]))), objectFromEntries("0123456789".split("").map((n) => [n, n])))
    };
    Application = class {
      constructor(element = document.documentElement, schema = defaultSchema) {
        this.logger = console;
        this.debug = false;
        this.logDebugActivity = (identifier, functionName, detail = {}) => {
          if (this.debug) {
            this.logFormattedMessage(identifier, functionName, detail);
          }
        };
        this.element = element;
        this.schema = schema;
        this.dispatcher = new Dispatcher(this);
        this.router = new Router(this);
        this.actionDescriptorFilters = Object.assign({}, defaultActionDescriptorFilters);
      }
      static start(element, schema) {
        const application = new this(element, schema);
        application.start();
        return application;
      }
      async start() {
        await domReady();
        this.logDebugActivity("application", "starting");
        this.dispatcher.start();
        this.router.start();
        this.logDebugActivity("application", "start");
      }
      stop() {
        this.logDebugActivity("application", "stopping");
        this.dispatcher.stop();
        this.router.stop();
        this.logDebugActivity("application", "stop");
      }
      register(identifier, controllerConstructor) {
        this.load({ identifier, controllerConstructor });
      }
      registerActionOption(name, filter) {
        this.actionDescriptorFilters[name] = filter;
      }
      load(head, ...rest) {
        const definitions = Array.isArray(head) ? head : [head, ...rest];
        definitions.forEach((definition) => {
          if (definition.controllerConstructor.shouldLoad) {
            this.router.loadDefinition(definition);
          }
        });
      }
      unload(head, ...rest) {
        const identifiers = Array.isArray(head) ? head : [head, ...rest];
        identifiers.forEach((identifier) => this.router.unloadIdentifier(identifier));
      }
      get controllers() {
        return this.router.contexts.map((context) => context.controller);
      }
      getControllerForElementAndIdentifier(element, identifier) {
        const context = this.router.getContextForElementAndIdentifier(element, identifier);
        return context ? context.controller : null;
      }
      handleError(error2, message, detail) {
        var _a;
        this.logger.error(`%s

%o

%o`, message, error2, detail);
        (_a = window.onerror) === null || _a === void 0 ? void 0 : _a.call(window, message, "", 0, 0, error2);
      }
      logFormattedMessage(identifier, functionName, detail = {}) {
        detail = Object.assign({ application: this }, detail);
        this.logger.groupCollapsed(`${identifier} #${functionName}`);
        this.logger.log("details:", Object.assign({}, detail));
        this.logger.groupEnd();
      }
    };
    defaultValuesByType = {
      get array() {
        return [];
      },
      boolean: false,
      number: 0,
      get object() {
        return {};
      },
      string: ""
    };
    readers = {
      array(value) {
        const array = JSON.parse(value);
        if (!Array.isArray(array)) {
          throw new TypeError(`expected value of type "array" but instead got value "${value}" of type "${parseValueTypeDefault(array)}"`);
        }
        return array;
      },
      boolean(value) {
        return !(value == "0" || String(value).toLowerCase() == "false");
      },
      number(value) {
        return Number(value.replace(/_/g, ""));
      },
      object(value) {
        const object = JSON.parse(value);
        if (object === null || typeof object != "object" || Array.isArray(object)) {
          throw new TypeError(`expected value of type "object" but instead got value "${value}" of type "${parseValueTypeDefault(object)}"`);
        }
        return object;
      },
      string(value) {
        return value;
      }
    };
    writers = {
      default: writeString,
      array: writeJSON,
      object: writeJSON
    };
    Controller = class {
      constructor(context) {
        this.context = context;
      }
      static get shouldLoad() {
        return true;
      }
      static afterLoad(_identifier, _application) {
        return;
      }
      get application() {
        return this.context.application;
      }
      get scope() {
        return this.context.scope;
      }
      get element() {
        return this.scope.element;
      }
      get identifier() {
        return this.scope.identifier;
      }
      get targets() {
        return this.scope.targets;
      }
      get outlets() {
        return this.scope.outlets;
      }
      get classes() {
        return this.scope.classes;
      }
      get data() {
        return this.scope.data;
      }
      initialize() {
      }
      connect() {
      }
      disconnect() {
      }
      dispatch(eventName, { target = this.element, detail = {}, prefix = this.identifier, bubbles = true, cancelable = true } = {}) {
        const type = prefix ? `${prefix}:${eventName}` : eventName;
        const event = new CustomEvent(type, { detail, bubbles, cancelable });
        target.dispatchEvent(event);
        return event;
      }
    };
    Controller.blessings = [
      ClassPropertiesBlessing,
      TargetPropertiesBlessing,
      ValuePropertiesBlessing,
      OutletPropertiesBlessing
    ];
    Controller.targets = [];
    Controller.outlets = [];
    Controller.values = {};
  }
});

// app/javascript/lib/encrypt.js
async function encryptMessage(message, ttl, views, password = "", burnAfterReading = false) {
  try {
    const key = await generateEncryptionKey(password);
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const encrypted = await encryptData(message, key.key, iv);
    const payload = {
      ciphertext: Base64.encode(encrypted),
      nonce: Base64.encode(iv),
      ttl,
      views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading
    };
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }
    const response = await CSRFHelper.fetchWithCSRF("/encrypt", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message: ${response.status} ${response.statusText}`);
    }
    const data = await response.json();
    let link = window.location.origin + "/" + data.id;
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey("raw", key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += "#" + keyBase64;
    }
    return link;
  } catch (error2) {
    console.error("Encryption error:", error2);
    throw error2;
  }
}
async function encryptFiles(files, message, ttl, views, password = "", burnAfterReading = false, progressCallback = null, cancelToken = null) {
  try {
    const totalSteps = files.length + 3;
    let currentStep = 0;
    const totalSize = files.reduce((sum, f) => sum + f.size, 0);
    let processedBytes = 0;
    const startTime = performance.now();
    const updateProgress = (status, details = "") => {
      currentStep++;
      const percentage = Math.round(currentStep / totalSteps * 100);
      const elapsed = (performance.now() - startTime) / 1e3;
      const speed = elapsed > 0 ? processedBytes / (1024 * 1024 * elapsed) : 0;
      const remaining = totalSize - processedBytes;
      const eta = speed > 0 ? remaining / (1024 * 1024 * speed) : 0;
      if (progressCallback) {
        progressCallback({ percentage, status, details, speed, eta });
      }
      if (cancelToken && cancelToken.canceled) {
        throw new Error("Encryption cancelled");
      }
    };
    updateProgress("Generating encryption key...");
    const key = await generateEncryptionKey(password);
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const payload = {
      nonce: Base64.encode(iv),
      ttl,
      views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading,
      files: []
    };
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }
    if (message && message.trim() !== "") {
      updateProgress("Encrypting message...");
      const encryptedMessage = await encryptData(message, key.key, iv);
      payload.ciphertext = Base64.encode(encryptedMessage);
    } else {
      payload.ciphertext = "";
    }
    for (const file of files) {
      updateProgress(`Encrypting file`, file.name);
      try {
        const fileData = await readFileAsArrayBuffer(file);
        const encryptedFile = await encryptData(fileData, key.key, iv);
        const encodedFile = Base64.encode(encryptedFile);
        payload.files.push({
          data: encodedFile,
          name: file.name,
          type: file.type || "application/octet-stream",
          size: file.size
        });
        processedBytes += file.size;
      } catch (fileError) {
        throw new Error(`Failed to process file "${file.name}": ${fileError.message}`);
      }
    }
    updateProgress("Uploading encrypted data...");
    const response = await CSRFHelper.fetchWithCSRF("/encrypt/finalize", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Upload failed: ${response.status} - ${errorText}`);
    }
    const data = await response.json();
    let link = window.location.origin + "/" + data.id;
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey("raw", key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += "#" + keyBase64;
    }
    updateProgress("Complete!");
    return link;
  } catch (error2) {
    console.error("File encryption error:", error2);
    throw error2;
  }
}
async function generateEncryptionKey(password = "") {
  try {
    if (password) {
      const salt = window.crypto.getRandomValues(new Uint8Array(16));
      const passwordKey = await window.crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(password),
        { name: "PBKDF2" },
        false,
        ["deriveKey"]
      );
      const key = await window.crypto.subtle.deriveKey(
        {
          name: "PBKDF2",
          salt,
          iterations: 1e5,
          hash: "SHA-256"
        },
        passwordKey,
        { name: "AES-GCM", length: 256 },
        true,
        ["encrypt"]
      );
      return { key, salt };
    } else {
      const key = await window.crypto.subtle.generateKey(
        { name: "AES-GCM", length: 256 },
        true,
        ["encrypt"]
      );
      return { key };
    }
  } catch (error2) {
    throw error2;
  }
}
async function encryptData(data, key, iv) {
  try {
    let dataBuffer;
    if (typeof data === "string") {
      dataBuffer = new TextEncoder().encode(data);
    } else {
      dataBuffer = new Uint8Array(data);
    }
    const encrypted = await window.crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      key,
      dataBuffer
    );
    return encrypted;
  } catch (error2) {
    throw error2;
  }
}
function readFileAsArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      resolve(reader.result);
    };
    reader.onerror = () => {
      const errorMsg = `Failed to read file: ${file.name}`;
      reject(new Error(errorMsg));
    };
    reader.readAsArrayBuffer(file);
  });
}
var Base64;
var init_encrypt = __esm({
  "app/javascript/lib/encrypt.js"() {
    Base64 = {
      encode: function(arrayBuffer) {
        try {
          const bytes = new Uint8Array(arrayBuffer);
          const chunkSize = 32768;
          if (bytes.length <= chunkSize) {
            const result2 = btoa(String.fromCharCode.apply(null, bytes));
            return result2;
          }
          let result = "";
          for (let i = 0; i < bytes.length; i += chunkSize) {
            const chunk = bytes.subarray(i, i + chunkSize);
            result += String.fromCharCode.apply(null, chunk);
          }
          const encodedResult = btoa(result);
          return encodedResult;
        } catch (error2) {
          throw new Error(`Base64 encoding failed: ${error2.message}`);
        }
      },
      decode: function(base64) {
        try {
          const binaryString = atob(base64);
          const bytes = new Uint8Array(binaryString.length);
          for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }
          return bytes.buffer;
        } catch (error2) {
          throw new Error(`Base64 decoding failed: ${error2.message}`);
        }
      }
    };
  }
});

// app/javascript/services/cryptography_service.js
var CryptographyService;
var init_cryptography_service = __esm({
  "app/javascript/services/cryptography_service.js"() {
    init_encrypt();
    CryptographyService = class {
      static encryptMessage(...args) {
        return encryptMessage(...args);
      }
      static encryptFiles(...args) {
        return encryptFiles(...args);
      }
    };
  }
});

// app/javascript/services/validation_service.js
var ValidationService;
var init_validation_service = __esm({
  "app/javascript/services/validation_service.js"() {
    ValidationService = class {
      static validate({ message = "", ttl = 0, views = 0 }) {
        if (ttl <= 0) return "Invalid expiration time";
        if (views <= 0) return "Invalid view limit";
        return null;
      }
    };
  }
});

// app/javascript/services/error_service.js
var ErrorService;
var init_error_service = __esm({
  "app/javascript/services/error_service.js"() {
    ErrorService = class {
      static handle(error2) {
        console.error(error2);
        alert("Error: " + error2.message);
      }
    };
  }
});

// app/javascript/controllers/encryption_controller.js
var encryption_controller_default;
var init_encryption_controller = __esm({
  "app/javascript/controllers/encryption_controller.js"() {
    init_stimulus();
    init_cryptography_service();
    init_validation_service();
    init_error_service();
    encryption_controller_default = class extends Controller {
      connect() {
        this.selectedFiles = [];
        if (this.hasFileInputTarget) {
          this.fileInputTarget.addEventListener("change", (e) => this.handleFiles(e.target.files));
        }
        if (this.hasDropAreaTarget) {
          this.dropAreaTarget.addEventListener("click", () => this.fileInputTarget.click());
          this.dropAreaTarget.addEventListener("dragover", (e) => {
            e.preventDefault();
            this.dropAreaTarget.classList.add("dragover");
          });
          this.dropAreaTarget.addEventListener("dragleave", () => this.dropAreaTarget.classList.remove("dragover"));
          this.dropAreaTarget.addEventListener("drop", (e) => {
            e.preventDefault();
            this.dropAreaTarget.classList.remove("dragover");
            this.handleFiles(e.dataTransfer.files);
          });
        }
        if (this.hasPasswordToggleTarget && this.hasPasswordContainerTarget) {
          this.passwordContainerTarget.style.display = this.passwordToggleTarget.checked ? "block" : "none";
          this.passwordToggleTarget.addEventListener("change", () => {
            this.passwordContainerTarget.style.display = this.passwordToggleTarget.checked ? "block" : "none";
            if (!this.passwordToggleTarget.checked) this.passwordInputTarget.value = "";
          });
        }
      }
      handleFiles(files) {
        for (const file of files) {
          this.selectedFiles.push(file);
        }
        this.renderFiles();
      }
      renderFiles() {
        if (!this.hasFilesContainerTarget) return;
        const body = this.filesListBodyTarget;
        body.innerHTML = "";
        this.selectedFiles.forEach((file, index) => {
          const item = document.createElement("div");
          item.className = "gh-file-item";
          item.innerHTML = `${file.name} (${(file.size / 1024 / 1024).toFixed(2)} MB)`;
          const removeBtn = document.createElement("button");
          removeBtn.type = "button";
          removeBtn.className = "btn btn-sm btn-outline-danger ms-2";
          removeBtn.textContent = "Remove";
          removeBtn.addEventListener("click", () => {
            this.selectedFiles.splice(index, 1);
            this.renderFiles();
          });
          item.appendChild(removeBtn);
          body.appendChild(item);
        });
        this.filesContainerTarget.style.display = this.selectedFiles.length ? "" : "none";
      }
      async encrypt(event) {
        event.preventDefault();
        const message = this.hasMessageInputTarget ? this.messageInputTarget.value : "";
        const ttl = this.hasTtlSelectTarget ? parseInt(this.ttlSelectTarget.value, 10) : 0;
        const views = this.hasViewsSelectTarget ? parseInt(this.viewsSelectTarget.value, 10) : 0;
        const burnAfterReading = this.hasBurnToggleTarget ? this.burnToggleTarget.checked : false;
        const validationError = ValidationService.validate({ message, ttl, views });
        if (validationError) {
          ErrorService.handle(new Error(validationError));
          return;
        }
        if (typeof CryptographyService.encryptMessage !== "function" || typeof CryptographyService.encryptFiles !== "function") {
          ErrorService.handle(new Error("Encryption module failed to load."));
          return;
        }
        const usePassword = this.passwordToggleTarget.checked;
        const password = usePassword ? this.passwordInputTarget.value : "";
        this.encryptButtonTarget.classList.add("loading", "btn-progress");
        this.encryptButtonTarget.disabled = true;
        this.progressDotsTarget.classList.remove("d-none");
        const originalText = this.encryptButtonTextTarget.textContent;
        try {
          const update = (p) => {
            let text = p.status;
            if (p.details) text += ` ${p.details}`;
            if (p.percentage !== void 0) text += ` (${p.percentage}%)`;
            if (p.speed) text += ` ${p.speed.toFixed(2)} MB/s`;
            if (p.eta) text += ` ETA: ${p.eta.toFixed(1)}s`;
            this.encryptButtonTextTarget.textContent = text;
          };
          let link;
          if (this.selectedFiles.length > 0) {
            link = await CryptographyService.encryptFiles(
              this.selectedFiles,
              message,
              ttl,
              views,
              password,
              burnAfterReading,
              update
            );
          } else {
            update({ percentage: 50, status: "Encrypting message..." });
            link = await CryptographyService.encryptMessage(message, ttl, views, password, burnAfterReading);
            update({ percentage: 100, status: "Complete!", speed: 0, eta: 0 });
          }
          this.encryptButtonTarget.classList.remove("loading", "btn-progress");
          this.encryptButtonTarget.disabled = false;
          this.encryptButtonTextTarget.textContent = originalText;
          this.progressDotsTarget.classList.add("d-none");
          this.encryptedLinkTarget.value = link;
          if (this.hasQrToggleTarget && this.qrToggleTarget.checked) {
            this.qrTabTarget.style.display = "";
            this.qrPanelTarget.style.display = "";
            this.resultTabsTarget.style.display = "";
            this.qrContainerTarget.innerHTML = "";
            new QRCode(this.qrContainerTarget, {
              text: link,
              width: 256,
              height: 256,
              colorDark: "#000000",
              colorLight: "#ffffff",
              correctLevel: QRCode.CorrectLevel.H
            });
          } else {
            if (this.hasQrTabTarget) this.qrTabTarget.style.display = "none";
            if (this.hasQrPanelTarget) this.qrPanelTarget.style.display = "none";
          }
          this.resultContainerTarget.classList.remove("d-none");
          if (this.resultMessageTarget) {
            if (usePassword) {
              this.resultMessageTarget.textContent = "This link requires a password to access. Share both the link and password separately for maximum security.";
            } else {
              this.resultMessageTarget.textContent = "This link contains the decryption key. Anyone with this link can view your message or download your files.";
            }
          }
          if (this.hasFormTarget) {
            this.formTarget.reset();
          }
          if (document.getElementById("richEditor")) {
            document.getElementById("richEditor").innerHTML = "";
          }
          if (this.hasMessageInputTarget) this.messageInputTarget.value = "";
          this.selectedFiles = [];
          this.renderFiles();
          this.resultContainerTarget.scrollIntoView({ behavior: "smooth" });
        } catch (error2) {
          this.encryptButtonTarget.classList.remove("loading", "btn-progress");
          this.encryptButtonTarget.disabled = false;
          this.encryptButtonTextTarget.textContent = originalText;
          this.progressDotsTarget.classList.add("d-none");
          ErrorService.handle(error2);
        }
      }
      copy() {
        if (!this.hasEncryptedLinkTarget || !this.hasCopyButtonTarget) return;
        const linkInput = this.encryptedLinkTarget;
        linkInput.select();
        document.execCommand("copy");
        const originalText = this.copyButtonTarget.innerHTML;
        this.copyButtonTarget.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path d="M20 6 9 17l-5-5"/></svg> Copied!';
        this.copyButtonTarget.classList.add("btn-success");
        this.copyButtonTarget.classList.remove("btn-outline-primary");
        setTimeout(() => {
          this.copyButtonTarget.innerHTML = originalText;
          this.copyButtonTarget.classList.remove("btn-success");
          this.copyButtonTarget.classList.add("btn-outline-primary");
        }, 2e3);
      }
    };
    __publicField(encryption_controller_default, "targets", [
      "form",
      "passwordToggle",
      "passwordInput",
      "passwordContainer",
      "messageInput",
      "ttlSelect",
      "viewsSelect",
      "burnToggle",
      "fileInput",
      "dropArea",
      "filesContainer",
      "filesListBody",
      "encryptButton",
      "encryptButtonText",
      "progressDots",
      "encryptedLink",
      "copyButton",
      "resultContainer",
      "resultMessage",
      "qrToggle",
      "qrContainer",
      "qrTab",
      "qrPanel",
      "resultTabs"
    ]);
  }
});

// app/javascript/controllers/theme_controller.js
var theme_controller_default;
var init_theme_controller = __esm({
  "app/javascript/controllers/theme_controller.js"() {
    init_stimulus();
    theme_controller_default = class extends Controller {
      connect() {
        const userPrefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
        const savedTheme = localStorage.getItem("theme");
        this.currentTheme = savedTheme || (userPrefersDark ? "dark" : "light");
        document.documentElement.setAttribute("data-bs-theme", this.currentTheme);
        this.updateIcons();
      }
      toggle() {
        this.currentTheme = this.currentTheme === "dark" ? "light" : "dark";
        document.documentElement.setAttribute("data-bs-theme", this.currentTheme);
        localStorage.setItem("theme", this.currentTheme);
        this.updateIcons();
      }
      updateIcons() {
        if (!this.hasSunTarget || !this.hasMoonTarget) return;
        if (this.currentTheme === "dark") {
          this.moonTarget.style.display = "block";
          this.sunTarget.style.display = "none";
        } else {
          this.sunTarget.style.display = "block";
          this.moonTarget.style.display = "none";
        }
      }
    };
    __publicField(theme_controller_default, "targets", ["sun", "moon"]);
  }
});

// app/javascript/controllers/rich_editor_controller.js
var rich_editor_controller_default;
var init_rich_editor_controller = __esm({
  "app/javascript/controllers/rich_editor_controller.js"() {
    init_stimulus();
    rich_editor_controller_default = class extends Controller {
      connect() {
        if (this.hasEditorTarget && this.hasHiddenInputTarget) {
          const buttons = this.toolbarTarget.querySelectorAll(".rich-editor-button");
          buttons.forEach((button) => {
            button.addEventListener("click", (e) => {
              e.preventDefault();
              const command = button.getAttribute("data-command");
              const value = button.getAttribute("data-value") || null;
              if (command === "createLink") {
                const url = prompt("Enter the link URL:");
                if (url) {
                  document.execCommand(command, false, url);
                }
              } else if (command === "formatBlock") {
                document.execCommand(command, false, value);
              } else if (command === "toggleCode") {
                this.toggleCode();
              } else {
                document.execCommand(command, false, null);
              }
              this.updateButtonStates();
              this.updateHiddenInput();
              this.editorTarget.focus();
            });
          });
          this.editorTarget.addEventListener("input", () => this.updateHiddenInput());
          this.editorTarget.addEventListener("keyup", () => this.updateButtonStates());
          this.editorTarget.addEventListener("mouseup", () => this.updateButtonStates());
          setTimeout(() => this.editorTarget.focus(), 100);
        }
        if (this.hasExpandButtonTarget && this.hasContainerTarget) {
          this.expandButtonTarget.addEventListener("click", () => this.toggleExpand());
        }
      }
      updateHiddenInput() {
        if (this.hasHiddenInputTarget && this.hasEditorTarget) {
          this.hiddenInputTarget.value = this.editorTarget.innerHTML;
        }
      }
      updateButtonStates() {
        const buttons = this.toolbarTarget.querySelectorAll(".rich-editor-button");
        buttons.forEach((button) => {
          const command = button.getAttribute("data-command");
          if (command === "formatBlock") {
            const value = button.getAttribute("data-value");
            const formatBlock = document.queryCommandValue("formatBlock");
            button.classList.toggle("active", formatBlock.toLowerCase() === value);
          } else if (command === "toggleCode") {
            let node = document.getSelection().anchorNode;
            let isCode = false;
            while (node && node !== this.editorTarget) {
              if (node.nodeName === "CODE") {
                isCode = true;
                break;
              }
              node = node.parentNode;
            }
            button.classList.toggle("active", isCode);
          } else {
            button.classList.toggle("active", document.queryCommandState(command));
          }
        });
      }
      toggleCode() {
        const selection = window.getSelection();
        if (!selection.rangeCount) return;
        const range = selection.getRangeAt(0);
        let node = selection.anchorNode;
        while (node && node !== this.editorTarget) {
          if (node.nodeName === "CODE") {
            const text = document.createTextNode(node.textContent);
            node.parentNode.replaceChild(text, node);
            range.selectNodeContents(text);
            selection.removeAllRanges();
            selection.addRange(range);
            return;
          }
          node = node.parentNode;
        }
        if (range.collapsed) {
          const codeEl = document.createElement("code");
          range.insertNode(codeEl);
          selection.collapse(codeEl, 0);
        } else {
          const codeEl = document.createElement("code");
          codeEl.textContent = range.toString();
          range.deleteContents();
          range.insertNode(codeEl);
          selection.removeAllRanges();
          const newRange = document.createRange();
          newRange.selectNodeContents(codeEl);
          selection.addRange(newRange);
        }
      }
      toggleExpand() {
        this.containerTarget.classList.toggle("expanded");
        if (this.containerTarget.classList.contains("expanded")) {
          this.expandButtonTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M10.75 1a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 10 4.25v-2.5a.75.75 0 0 1 .75-.75Zm-5.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 4.25 6h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5A.75.75 0 0 1 5.25 1ZM1 10.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Zm9 1c0-.966.784-1.75 1.75-1.75h2.5a.75.75 0 0 1 0 1.5h-2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0Z"/></svg>`;
          this.expandButtonTarget.title = "Collapse editor";
        } else {
          this.expandButtonTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M1.75 10a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 1 13.25v-2.5a.75.75 0 0 1 .75-.75Zm12.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 13.25 15h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 .75-.75ZM2.75 2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0v-2.5C1 1.784 1.784 1 2.75 1h2.5a.75.75 0 0 1 0 1.5ZM10 1.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Z"/></svg>`;
          this.expandButtonTarget.title = "Expand editor";
        }
      }
    };
    __publicField(rich_editor_controller_default, "targets", ["editor", "hiddenInput", "toolbar", "expandButton", "container"]);
  }
});

// app/javascript/controllers/rate_limit_controller.js
var rate_limit_controller_default;
var init_rate_limit_controller = __esm({
  "app/javascript/controllers/rate_limit_controller.js"() {
    init_stimulus();
    rate_limit_controller_default = class extends Controller {
      connect() {
        this.originalFetch = window.fetch.bind(window);
        window.fetch = async (...args) => {
          const response = await this.originalFetch(...args);
          if (response.status === 429) {
            const retryAfter = response.headers.get("Retry-After") || 60;
            this.showRateLimitError(retryAfter);
          }
          return response;
        };
      }
      disconnect() {
        if (this.originalFetch) {
          window.fetch = this.originalFetch;
        }
      }
      showRateLimitError(retryAfter) {
        const alert2 = document.createElement("div");
        alert2.className = "alert alert-danger";
        alert2.role = "alert";
        alert2.innerHTML = `
      <h4 class="alert-heading">Rate limit exceeded</h4>
      <p>You've made too many requests. Please try again after ${retryAfter} seconds.</p>
    `;
        document.body.insertBefore(alert2, document.body.firstChild);
        setTimeout(() => alert2.remove(), 5e3);
      }
    };
  }
});

// app/javascript/lib/csrf-helper.js
var require_csrf_helper = __commonJS({
  "app/javascript/lib/csrf-helper.js"(exports, module) {
    var CSRFHelper2 = class {
      static getToken() {
        const tokenElement = document.querySelector('meta[name="csrf-token"]');
        return tokenElement ? tokenElement.getAttribute("content") : null;
      }
      static getHeaders(additionalHeaders = {}) {
        const token = this.getToken();
        const headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          ...additionalHeaders
        };
        if (token) {
          headers["X-CSRF-Token"] = token;
        }
        return headers;
      }
      static async fetchWithCSRF(url, options = {}) {
        const defaultOptions = {
          headers: this.getHeaders(options.headers || {})
        };
        const mergedOptions = {
          ...defaultOptions,
          ...options,
          headers: {
            ...defaultOptions.headers,
            ...options.headers || {}
          }
        };
        return fetch(url, mergedOptions);
      }
    };
    window.CSRFHelper = CSRFHelper2;
    if (typeof module !== "undefined" && module.exports) {
      module.exports = CSRFHelper2;
    }
  }
});

// app/javascript/application.js
var require_application = __commonJS({
  "app/javascript/application.js"() {
    init_stimulus();
    init_encryption_controller();
    init_theme_controller();
    init_rich_editor_controller();
    init_rate_limit_controller();
    var import_csrf_helper = __toESM(require_csrf_helper());
    window.Stimulus = Application.start();
    Stimulus.register("encryption", encryption_controller_default);
    Stimulus.register("theme", theme_controller_default);
    Stimulus.register("rich-editor", rich_editor_controller_default);
    Stimulus.register("rate-limit", rate_limit_controller_default);
  }
});
export default require_application();
//# sourceMappingURL=application.js.map
