#!/usr/bin/ruby
#coding: utf-8

require 'json'
require 'mongo'
require 'fileutils'
require 'csv'
require './params.rb'

if File.exist?("#{$workdir_name}") == false
    FileUtils.mkdir_p($workdir_name);
end

result = system("casperjs --ignore-ssl-errors=yes casperjs/getedinetcodelist.js #{$workdir_name}/#{$edinetcodezip_name}");

if result == false || File.exist?("#{$workdir_name}/#{$edinetcodezip_name}") == false
    exit(-1);
end

result = system("unzip -o -q -d #{$workdir_name} #{$workdir_name}/#{$edinetcodezip_name}");
result = system("rm #{$workdir_name}/#{$edinetcodezip_name}");
if result == false || File.exist?("#{$workdir_name}/#{$edinetcodecsv_name}") == false
    exit(-1);
end

result = system("nkf -w -Lu -d #{$workdir_name}/#{$edinetcodecsv_name} > #{$workdir_name}/#{$edinetcodecsv_utf8_name}.tmp");
result = system("rm #{$workdir_name}/#{$edinetcodecsv_name}");

f_in  = File.open("#{$workdir_name}/#{$edinetcodecsv_utf8_name}.tmp", "r:utf-8");
f_out = File.open("#{$workdir_name}/#{$edinetcodecsv_utf8_name}", "w:utf-8");

lines = 0;

f_in.each_line do |line|
    if lines >= 1
      f_out.write(line);
    end
    lines = lines + 1;
end

f_in.close();
f_out.close();

result = system("rm #{$workdir_name}/#{$edinetcodecsv_utf8_name}.tmp");

if File.exist?("#{$workdir_name}/#{$edinetcodecsv_utf8_name}") == false
    exit(-1);
end

client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
client[:edinetcode].indexes.create_one({ :edinetcode => 1 }, :unique => true);

table = CSV.table("#{$workdir_name}/#{$edinetcodecsv_utf8_name}");
table.each do |field|
    doc = {
        :edinetcode     => field[0],
        :type           => field[1],
        :listed         => field[2] == '上場' ? true : false,
        :consolidated   => field[3] == '有' ? true : false,
        :capital        => field[4],
        :earningsdate   => field[5],
        :name_jp        => field[6],
        :name_en        => field[7],
        :name_kana      => field[8],
        :address        => field[9],
        :industry       => field[10],
        :ticker         => field[11]
    }

    #result = client[:edinetcode].insert_one(doc)
    client[:edinetcode].bulk_write( [ { :replace_one => { :find => { :edinetcode => field[0] }, :replacement => doc, :upsert => true } } ], :ordered => false );
end

if $deleteafterprocess
    FileUtils.mkdir_p($workdir_name);
end
