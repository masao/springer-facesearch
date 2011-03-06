#!/usr/bin/env ruby
# $Id$

require "net/http"

require "rubygems"
require "json"
require "erb"
require "cgi"
require "rubygems"
require "json"
require "libxml"

USER_AGENT = "Springer/Facesearch"
SPRINGER_IMAGES_APIKEY = "uwud8n4tbkmr4bqw6zfq8ab8"
SPRINGER_INTERVAL = 0.5

def http_get( uri )
   http = Net::HTTP.new( uri.host, uri.port )
   http.start do |http|
      response, = http.get( uri.request_uri, { 'User-Agent'=>USER_AGENT } )
      case response
      when Net::HTTPSuccess
         response
      when Net::HTTPRedirection
         redirect_uri = URI.parse( response['Location'] )
         STDERR.puts "redirect to #{ redirect_uri } (#{limit})"
         http_get( uri + redirect_uri, limit - 1 )
      else
         response.error!
      end
   end
end

# Springer Image API
## cf. http://dev.springer.com/docs
def springer_images_search( keyword, opts = {} )
   base_uri = "http://api.springer.com/images/xml"
   q = URI.escape( keyword )
   cont = nil
   if not opts.empty?
      opts_s = opts.keys.map do |e|
         "#{ e }=#{ URI.escape( opts[e].to_s ) }"
      end.join( "&" )
   end
   uri = URI.parse( "#{ base_uri }?q=#{ q }&api_key=#{ SPRINGER_IMAGES_APIKEY }&#{ opts_s }" )
   response = http_get( uri )
   cont = response.body
   parser = LibXML::XML::Parser.string( cont )
   doc = parser.parse
   records = doc.find( "//records/record/Image" )
   files = []
   if records
      image_urls = records.each do |e|
         files << {
            :caption => e.find( "./Caption" )[0].content,
            :thumb   => e.find( "./File/Path[@Type='thumb']" )[0].content,
            :url     => e.find( "./Location" )[0].content,
         }
      end
   end
   files
end

if $0 == __FILE__
   files = springer_images_search( ARGV[0] )
   urls = files.map{|e| e[:thumb] }.join(",")
   faceapi_url = "http://api.face.com/faces/detect.json?api_key=4b4b4c6d54c37&api_secret=&urls=#{ URI.escape urls }&detector=Normal"
end
