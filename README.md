# sphere-node-sync [![Build Status](https://secure.travis-ci.org/emmenko/sphere-node-sync.png?branch=master)](http://travis-ci.org/emmenko/sphere-node-sync) [![NPM version](https://badge.fury.io/js/sphere-node-sync.png)](http://badge.fury.io/js/sphere-node-sync) [![Dependency Status](https://gemnasium.com/emmenko/sphere-node-sync.png)](https://gemnasium.com/emmenko/sphere-node-sync)

Quick and easy way to sync your SPHERE.IO Products.

## Getting Started
Install the module with: `npm install sphere-node-sync`

```javascript
var sync = require('sphere-node-sync').Sync
```

## Documentation
TBD


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Releasing
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License
Copyright (c) 2013 Nicola Molinari
Licensed under the MIT license.
