#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "index.rb"

class TestFaceDetect < Test::Unit::TestCase
   def test_face_detect
      result = face_detect( [ "http://c0000571.cdn2.cloudfiles.rackspacecloud.com/Springer/JOU=11276/VOL=2010.16/ISU=2/ART=2008_131/MediaObjects/THUMB_11276_2008_131_Figa_HTML.jpg" ] )
      assert( result )
      assert( result[ "photos" ] )
      assert( result[ "photos" ].first[ "tags" ].size > 0 )
   end
end
