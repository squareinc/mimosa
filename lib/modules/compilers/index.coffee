path = require 'path'

_ = require 'lodash'

fileUtils =  require '../../util/file'
logger = require '../../util/logger'

baseDirRegex = /([^[\/\\\\]*]*)$/

class CompilerCentral

  all: []

  constructor: ->
    fileNames = fileUtils.glob "#{__dirname}/**/*-compiler.coffee"
    fileNames.push "#{__dirname}/copy.coffee"
    for file in fileNames
      Compiler = require(file)
      Compiler.base = path.basename(file, ".coffee").replace('-compiler', '')
      if Compiler.base isnt "copy"
        Compiler.type = baseDirRegex.exec(path.dirname(file))[0]
      else
        Compiler.type = "copy"
      @all.push(Compiler)

  lifecycleRegistration: (config) ->
    compilers = @getCompilers(config)

    extensionReg = {}
    for compiler in compilers
      for ext in compiler.extentions
        extensionReg[ext] = compiler.compile

    {compile:extensionReg}

  _compilersWithoutCopy: ->
    @all.filter (comp) -> comp.base isnt "copy"

  _compilersWithoutNone: ->
    @all.filter (comp) -> comp.base isnt "none"

  compilersByType: ->
    compilersByType = {css:[], javascript:[], template:[]}
    for comp in @_compilersWithoutCopy()
      compilersByType[comp.type].push(comp)
    compilersByType

  getCompilers: (config) ->
    allOverriddenExtensions = []
    for base, ext of config.compilers.extensionOverrides
      allOverriddenExtensions.push(ext...)

    logger.debug("All overridden extension [[ #{allOverriddenExtensions.join(', ')}]]")

    allCompilers = []
    extHash = {}
    for Compiler in @_compilersWithoutNone()
      extensions = if config.compilers.extensionOverrides[Compiler.base]?
        config.compilers.extensionOverrides[Compiler.base]
      else
        # check and see if an overridden extension conflicts with an existing one
        _.difference Compiler.defaultExtensions, allOverriddenExtensions

      # compiler left without extensions, don't register
      continue if extensions.length is 0 and Compiler.base isnt "copy"

      compiler = new Compiler(config, extensions)
      allCompilers.push compiler
      extHash[ext] = compiler for ext in compiler.extensions
      config.extensions[Compiler.type].push(extensions...)

    for type, extensions of config.extensions
      config.extensions[type] = _.uniq(extensions)

    logger.debug("Compiler/Extension hash \n #{extHash}")

    {compilerExtensionHash:extHash, compilers:allCompilers}

module.exports = new CompilerCentral()