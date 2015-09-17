#!/usr/bin/ruby

require 'fileutils'
require 'mongo'
require './params.rb'

target = ARGV[0];

if target == nil
    exit(-1);
end

if File.exist?("#{$workdir_name}") == false
    FileUtils.mkdir_p($workdir_name);
end

client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
documents = client[:edinetcode].find({ :$or => [ { :edinetcode => target }, { :name_jp => target }, { :ticker => target.to_i }, { :ticker => (target + '0').to_i } ] });

target_edinetcode = '';

documents.each do |document|
    target_edinetcode = document['edinetcode'];
    result = system("casperjs --ignore-ssl-errors=yes casperjs/getedinetreport.js #{target_edinetcode} #{$workdir_name}");
end

if File.exist?("#{$workdir_name}/#{target_edinetcode}.zip") == false
    print "Error: XBRL zipfile download failed\n";
    exit(-1);
end

if system("unzip -o -q #{$workdir_name}/#{target_edinetcode}.zip -d #{$workdir_name}/#{target_edinetcode}") == false
    print "Error: unzip returned -1\n";
    exit(-1);
end

system("rm -f #{$workdir_name}/#{target_edinetcode}.zip");

p "parsexbrl.rb #{$workdir_name}/#{target_edinetcode}";

if system("ruby parsexbrl.rb #{$workdir_name}/#{target_edinetcode}") == false
    print "Error: parsexbrl.rb returned -1\n";
    exit(-1);
else
    print "Success\n"
    if $removeafterprocess
        FileUtils.rm_rf("#{$workdir_name}/#{target_edinetcode}");
    end
    exit(0);
end

