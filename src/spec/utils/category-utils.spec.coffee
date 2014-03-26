_ = require 'underscore'
_.mixin deepClone: (obj) -> JSON.parse(JSON.stringify(obj))
CategoryUtils = require '../../lib/utils/category-utils'

describe 'CategoryUtils', ->
  beforeEach ->
    @utils = new CategoryUtils()

  afterEach ->
    @utils = null

  describe 'actionsMap', ->
    it 'should create no actions for the same category', ->
      category =
        id: 'same'
        name:
          de: 'bla'
          en: 'foo'

      delta = @utils.diff category, category
      console.error delta
      update = @utils.actionsMap delta

      expect(update).toEqual []


    it 'should create action to change name', ->
      category =
        id: '123'
        name:
          de: 'bla'
          en: 'foo'

      otherCategory = _.deepClone category
      otherCategory.name.en = 'bar'
      console.log "C", category
      console.log "O", otherCategory

      delta = @utils.diff category, otherCategory
      console.error delta
      update = @utils.actionsMap delta

      expect(update).toEqual []
