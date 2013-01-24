# FacePlusPlus Ruby SDK

A Ruby interface to the FacePlusPlus API.

## Supported Ruby Versions

This sdk has been tested against the following Ruby versions:

- 1.8.7_p370
- 1.9.3_p286

## Installation

```bash
gem build facepp.gemspec
gem install *.gem
```

## Get Started

```ruby
require 'facepp'

api = FacePP.new 'YOUR_API_KEY', 'YOUR_API_SECRET'
puts api.detection.detect url: '/tmp/0.jpg'
puts api.person.create person_name: 'Curry'
puts api.person.add_faces person_name: 'Curry', face_id: ['FACD_ID_0', 'FACE_ID_1']
puts api.person.add_faces person_name: 'Curry', face_id: ['FACD_ID_0', 'FACE_ID_1'].to_set
puts api.person.add_faces person_id: 'PERSON_ID', face_id: 'FACE_ID'
puts api.info.get_quota
```

See the RSpec tests for more examples.

## License

Licensed under the MIT license.
