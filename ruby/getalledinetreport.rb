#!/usr/bin/ruby
#coding: utf-8

require 'mongo'
require './params.rb'

client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
edinetcodelist = client[:edinetcode].find({ :listed => true }).sort({ :edinetcode => 1 });

edinetcodelist.each do |edinetcode|
    if system("ruby getedinetreport.rb #{edinetcode['edinetcode']}") == false
        print "Warning: getedinetreport failed\n";
    end
end