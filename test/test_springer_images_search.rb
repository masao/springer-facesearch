#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "index.rb"

class TestSpringerFacesearch < Test::Unit::TestCase
   def test_springer_images_search
      result = springer_images_search( "keyword" )
      assert( result )
      assert( result.size > 0 )
   end
end
