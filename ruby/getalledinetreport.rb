#!/usr/bin/ruby
#coding: utf-8

require 'mongo'
require 'fileutils'
require './params.rb'

Mongo::Logger.logger.level = $mongologlevel;
client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)

max = client[:edinetcode].find({ :listed => true }).sort({ :edinetcode => 1 }).count;
index = 0;
limit = 10;

while index < max
    edinetcodelist = client[:edinetcode].find({ :listed => true }).no_cursor_timeout.sort({ :edinetcode => 1 }).skip(index).limit(limit);
    edinetcodelist.each do |edinetcode|
        print "getalledinetreport.rb (#{index + 1}/#{max}): #{edinetcode['edinetcode']} #{edinetcode['name_jp']}\n";
        
        counter = 0;
        begin
            if system("ruby getedinetreport.rb #{edinetcode['edinetcode']}") == false
                raise;
            end
        rescue
            print "getalledinetreport.rb: (#{index + 1}/#{max}): Error.\n";
            if (counter < $retry_limit)
                counter = counter + 1;
                retry;
            end
        end
        index = index + 1;
    end
end


if $deleteafterprocess
    FileUtils.rm_rf($workdir_name);
end

print "Process completed.\n"