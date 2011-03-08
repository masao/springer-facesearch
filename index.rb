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

VERSION = "0.1"
TITLE = "Springer Face Search"

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

def http_post( uri, data )
   http = Net::HTTP.new( uri.host, uri.port )
   http.start do |http|
      response, = http.post( uri.request_uri, data,
                             { 'User-Agent'=>USER_AGENT } )
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

def face_detect( url_list )
   urls = url_list[0,30].join( "," )
   uri = URI.parse( "http://api.face.com/faces/detect.json" )
   data = { "api_key" => "7326a34beadd71c1a8fcab9e61c9dc8b",
            "api_secret" => "e30c097912d2f77a15f791e15e0564e9",
	    "urls" => URI.escape( urls ),
	    "detector" => "Normal",
	  }
   param = data.map{|k,v| "#{k}=#{v}" }.join("&")
   uri.query = param
   #p uri.to_s
   response = http_get( uri )
   json = response.body
   JSON.load( json )
end

if $0 == __FILE__
   @cgi = CGI.new
   q = nil
   result = []
   if @cgi.params["q"] and @cgi.params["q"][0] and not @cgi.params["q"][0].empty?
      q = @cgi.params["q"][0]
      files = springer_images_search( q, { :p => 50 } )
      #p files
      urls = files.map{|e| e[:thumb] }
      result = face_detect( urls )
   end
   include ERB::Util
   rhtml = open( "top.rhtml" ){|io| io.read }
   print @cgi.header( "text/html; charset=utf-8" )
   print ERB::new( rhtml, $SAFE, "<>" ).result( binding )
end
