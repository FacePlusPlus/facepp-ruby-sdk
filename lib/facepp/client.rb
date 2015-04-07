require 'rubygems'
require 'json'
require 'mime/types'
require 'net/http'
require 'securerandom'
require 'uri'

unless Object.respond_to? :singleton_class
  class Object
    def singleton_class
      class << self; self; end
    end
  end
end

unless Object.respond_to? :define_singleton_method
  class Object
    def define_singleton_method name, &block
      singleton_class.send :define_method, name, &block
    end
  end
end

unless URI.respond_to? :encode_www_form
  module URI
    TBLENCWWWCOMP_ = {} # :nodoc:
    256.times do |i|
      TBLENCWWWCOMP_[i.chr] = '%%%02X' % i
    end
    TBLENCWWWCOMP_[' '] = '+'
    TBLENCWWWCOMP_.freeze

    def self.encode_www_form_component str
      str.to_s.gsub(/[^*\-.0-9A-Z_a-z]/) {|c| TBLENCWWWCOMP_[c] }
    end

    def self.encode_www_form enum
      enum.map {|k,v| "#{encode_www_form_component k}=#{encode_www_form_component v}" }.join '&'
    end
  end
end

class FacePP
  class MultiPart
    def initialize
      @fields = []
      @files = []
      @boundary = [SecureRandom.random_bytes(15)].pack('m*').chop!
    end

    def add_field name, value
      @fields << [name, value]
    end

    def add_file name, filepath
      @files << [name, filepath]
    end

    def self.guess_mime filename
      res = MIME::Types.type_for(filename)
      res.empty? ? 'application/octet-stream' : res[0]
    end

    def has_file?
      not @files.empty?
    end

    def content_type
      "multipart/form-data; boundary=#{@boundary}"
    end

    def inspect
      res = StringIO.new
      append_boundary = lambda { res.write "--#{@boundary}\r\n" }
      @fields.each do |field|
        append_boundary[]
        res.write "Content-Disposition: form-data; name=\"#{field[0]}\"\r\n\r\n#{field[1]}\r\n"
      end
      @files.each do |file|
        append_boundary[]
        res.write "Content-Disposition: file; name=\"#{file[0]}\"; filename=\"#{file[1]}\"\r\n"
        res.write "Content-Type: #{self.class.guess_mime file[1]}\r\n"
        res.write "Content-Transfer-Encoding: binary\r\n\r\n"
        res.write File.open(file[1]).read
        res.write "\r\n"
      end
      res.write "--#{@boundary}--\r\n"
      res.rewind
      res.read
    end
  end

  APIS = [
    '/detection/detect',
    '/detection/landmark',

    '/train/verify',
    '/train/search',
    '/train/identify',

    '/recognition/compare',
    '/recognition/verify',
    '/recognition/identify',
    '/recognition/search',

    '/grouping/grouping',

    '/person/create',
    '/person/delete',
    '/person/add_face',
    '/person/remove_face',
    '/person/set_info',
    '/person/get_info',

    '/faceset/create',
    '/faceset/delete',
    '/faceset/add_face',
    '/faceset/remove_face',
    '/faceset/set_info',
    '/faceset/get_info',

    '/group/create',
    '/group/delete',
    '/group/add_person',
    '/group/remove_person',
    '/group/set_info',
    '/group/get_info',

    '/info/get_image',
    '/info/get_face',
    '/info/get_person_list',
    '/info/get_faceset_list',
    '/info/get_group_list',
    '/info/get_session',
    '/info/get_app',
  ]

  def initialize(key, secret, options={})
    decode = options.fetch :decode, true
    make_hash = lambda { Hash.new {|h,k| h[k] = make_hash.call make_hash } }

    APIS.each do |api|
      m = self
      breadcrumbs = api.split('/')[1..-1]
      breadcrumbs[0..-2].each do |breadcrumb|
        unless m.instance_variable_defined? "@#{breadcrumb}"
          m.instance_variable_set "@#{breadcrumb}", Object.new
          m.singleton_class.class_eval do
            attr_reader breadcrumb
          end
        end
        m = m.instance_variable_get "@#{breadcrumb}"
      end

      m.define_singleton_method breadcrumbs[-1] do |*args|
        form = MultiPart.new
        fields = {'api_key' => key, 'api_secret' => secret}
        (args[0] || {}).each do |k,v|
          if k.to_s == 'img'  # via POST
            form.add_file k, v
          else
            fields[k] = v.is_a?(Enumerable) ? v.to_a.join(',') : v
          end
        end

        req = Net::HTTP::Post.new "#{api}?#{URI::encode_www_form(fields)}"
        if form.has_file?
          req.set_content_type form.content_type
          req.body = form.inspect
          req['Content-Length'] = req.body.size
        end
        res = Net::HTTP.new('apicn.faceplusplus.com').request(req).body
        decode ? JSON.load(res) : res
      end
    end
  end
end
