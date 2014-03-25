_ = require 'underscore'
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

      otherCategory = _.clone category
      otherCategory.name.en = 'bar'

      delta = @utils.diff category, otherCategory
      console.error delta
      update = @utils.actionsMap delta

      expect(update).toEqual []
