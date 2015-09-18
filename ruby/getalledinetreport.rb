#!/usr/bin/ruby
#coding: utf-8

require 'mongo'
require 'fileutils'
require './params.rb'

Mongo::Logger.logger.level = $mongologlevel;
client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
edinetcodelist = client[:edinetcode].find({ :listed => true }).sort({ :edinetcode => 1 });

counter = 1;
edinetcodelist.each do |edinetcode|
    print "getalledinetreport.rb (#{counter}/#{edinetcodelist.count}): #{edinetcode['edinetcode']} #{edinetcode['name_en']}\n";
    if system("ruby getedinetreport.rb #{edinetcode['edinetcode']}") == false
        print "getalledinetreport.rb: Error\n";
    end
    counter = counter + 1;
end

if $deleteafterprocess
    FileUtils.rm_rf($workdir_name);
end

print "Process completed.\n"