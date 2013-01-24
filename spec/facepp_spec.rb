require 'set'
require 'facepp'

RSpec::Matchers.define :be_person do
  match do |actual|
    actual.should have_key 'person_id'
  end
end

describe FacePP do
  let(:api) { FacePP.new 'YOUR_API_KEY', 'YOUR_API_SECRET' }
  let(:face_id1) { api.detection.detect(img: '/tmp/0.jpg')['face'][0]['face_id'] }
  let(:face_id2) { api.detection.detect(img: '/tmp/1.jpg')['face'][0]['face_id'] }

  describe 'recognition' do
    it 'can compare' do
      #puts 'api: ', api
      #puts face_id1, ' ', face_id2
      #puts api.detection.detect(img: '/tmp/0.jpg')['face'][0]['face_id']

      res = api.recognition.compare face_id1: face_id1, face_id2: face_id2
      res.should have_key 'component_similarity'
    end
  end

  describe 'person' do
    let(:name) { "Haskell-#{rand 10}" }

    before :all do
      res = api.person.create(person_name: name)
      res.should be_person
      @person_id = res['person_id']
    end

    it 'can get_info' do
      api.person.get_info(person_id: @person_id).should be_person
      api.person.get_info(person_name: name).should be_person
    end

    it 'can add_face' do
      api.person.add_face(person_id: @person_id, face_id: face_id1).should have_key 'success'
    end

    it 'can remove_face' do
      api.person.remove_face(person_id: @person_id, face_id: face_id1).should have_key 'success'
    end

    it 'can add_face in chunks' do
      api.person.add_face(person_id: @person_id, face_id: [face_id1, face_id2]).should have_key 'success'
    end

    it 'can remove_face in chunks' do
      api.person.remove_face(person_id: @person_id, face_id: [face_id1, face_id2].to_set).should have_key 'success'
    end

    after :all do
      api.person.delete(person_name: name).should have_key 'success'
    end
  end

  describe 'info' do
    it 'can get_group_list' do
      res = api.info.get_group_list
      res.should have_key 'group'
    end

    it 'can get_quota' do
      res = api.info.get_quota
      res.should have_key 'QUOTA_ALL'
      res.should have_key 'QUOTA_SEARCH'
    end
  end
end
