//
// utility functions for modules
//

function appendAll_internal_recursive(modules, name, key, seenValues)
{
    var result = []
    var propertyValue
    var m
    for (m in modules) {
        if (m === name) {
            propertyValue = modules[m][key]
            if (propertyValue instanceof Array) {
                for (var i = 0; i < propertyValue.length; ++i) {
                    var value = propertyValue[i]
                    if (!seenValues[value]) {
                        seenValues[value] = true
                        result.push(value)
                    }
                }
            } else if (propertyValue) {
                if (!seenValues[propertyValue]) {
                    seenValues[propertyValue] = true
                    result.push(propertyValue)
                }
            }
        } else {
            propertyValue = appendAll_internal_recursive(modules[m].modules, name, key, seenValues)
            if (propertyValue.length > 0) {
                result = result.concat(propertyValue)
            }
        }
    }
    return result
}

function appendAll_internal(modules, name, key, seenValues)
{
    if (!seenValues)
        seenValues = []
    return appendAll_internal_recursive(modules, name, key, seenValues)
}

function appendAll(config, key)
{
    return appendAll_internal(config.modules, config.module.name, key)
}

function appendAllFromArtifacts(product, artifacts, moduleName, propertyName)
{
    var seenValues = []
    var result = appendAll_internal(product.modules, moduleName, propertyName, seenValues)
    for (var i in artifacts)
        result = result.concat(appendAll_internal(artifacts[i].modules, moduleName, propertyName, seenValues))
    return result
}

function findFirst(modules, name, property)
{
    var value;
    var module;
    for (var moduleName in modules) {
        module = modules[moduleName];
        if (moduleName === name) {
            value = module[property];
            if (value !== undefined)
                return value;
        }
        value = findFirst(module.modules, name, property);
        if (value !== undefined)
            return value;
    }
    return undefined;
}

function dumpProperty(key, value, level)
{
    var indent = ''
    for (var k=0; k < level; ++k)
        indent += '  '
    print(indent + key + ': ' + value)
}

function traverseObject(obj, func, level)
{
    if (!level)
        level = 0
    var children = {}
    for (var i in obj) {
        if (typeof(obj[i]) == "object" && !(obj[i] instanceof Array))
            children[i] = obj[i]
        else
            func.apply(this, [i, obj[i], level])
    }
    level++
    for (var i in children) {
        func.apply(this, [i, children[i], level - 1])
        traverseObject(children[i], func, level)
    }
    level--
}

function dumpObject(obj, description)
{
    if (!description)
        description = 'object dump'
    print('+++++++++ ' + description + ' +++++++++')
    traverseObject(obj, dumpProperty)
}


//////////////////////////////////////////////////////////
// The EnvironmentVariable class
//
function EnvironmentVariable(name, separator, convertPathSeparators)
{
    if (!name)
        throw "EnvironmentVariable c'tor needs a name as first argument."
    this.name = name
    this.value = getenv(name).toString()
    this.separator = separator || ''
    this.convertPathSeparators = convertPathSeparators || false
}

EnvironmentVariable.prototype.prepend = function(v)
{
    if (this.value.length > 0 && this.value.charAt(0) != this.separator)
        this.value = this.separator + this.value
    if (this.convertPathSeparators)
        v = FileInfo.toWindowsSeparators(v)
    this.value = v + this.value
}

EnvironmentVariable.prototype.append = function(v)
{
    if (this.value.length > 0)
        this.value += this.separator
    if (this.convertPathSeparators)
        v = FileInfo.toWindowsSeparators(v)
    this.value += v
}

EnvironmentVariable.prototype.set = function()
{
    putenv(this.name, this.value)
}

