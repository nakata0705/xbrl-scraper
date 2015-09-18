#!/usr/bin/ruby

require 'fileutils'
require 'mongo'
require 'json'
require './params.rb'

#$tags = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) };

def FindLabel(object, label)
    if object.respond_to?(:has_key?) != true
        return nil;
    end
    
    if object.has_key?(label) == true
        return object[label];
    end
    
    object.each do |key, value|
        result = FindLabel(value, label);
        if result != nil
            return result;
        end
    end
    
    return nil
end

def generate_json(base_dirname, langarray)
    filelist = Dir.glob("#{base_dirname}/*.xbrl");
    if filelist.length != 1
        puts "Unexpected number of xbrl files. #{filelist.length}";
        return false;
    end
    
    langarray.each do |lang|# EN output
        #result = system("python3 #{$arelledir}/arelleCmdLine.py -f #{filelist[0]} --labelLang #{lang} --facts #{base_dirname}/facts_#{lang}.json --factListCols Label,Name,contextRef,unitRef,Dec,Prec,Lang,Value,EntityScheme,EntityIdentifier,Period,Dimensions --concepts #{base_dirname}/concepts_#{lang}.json --pre #{base_dirname}/pre_#{lang}.json --cal #{base_dirname}/cal_#{lang}.json --dim #{base_dirname}/dim_#{lang}.json --formulae #{base_dirname}/formulae_#{lang}.json --viewArcrole #{base_dirname}/viewArcrole_#{lang}.json --roleTypes #{base_dirname}/roleTypes_#{lang}.json --arcroleTypes #{base_dirname}/arcroleTypes_#{lang}.json");
        result = system("python3 #{$arelledir}/arelleCmdLine.py --logLevel info -f #{filelist[0]} --labelLang #{lang} --facts #{base_dirname}/facts_#{lang}.json --factListCols Label,Name,contextRef,unitRef,Dec,Prec,Lang,Value,EntityScheme,EntityIdentifier,Period,Dimensions");
        if result == false
            return false;
        end
    end
    
    return true;
end

def parse_json(path, mongo_client, langarray)
    langarray.each do |lang|
        json = JSON.parse(File.read(path+"/facts_#{lang}.json"));
        json["factList"].each do |facts|
            fact = facts[2];
            fact["label_#{lang}"] = fact["label"];
            fact.delete("label");
            if fact["value"] =~ /^[\d\,\.]*$/
                fact["value"] = fact["value"].gsub(/(\d),(\d)/, '\1\2').to_f;
            end
            target = {
                :entityIdentifier => fact["entityIdentifier"],
                :name => fact["name"],
                :endInstant => fact["endInstant"],
                :contextRef => fact["contextRef"]
            };
            if fact["start"]
                target["start"] = fact["start"];
            end
            
            mongo_client[:edinetfacts].bulk_write( [ { :update_one => {
                :find => target,
                :update => { "$set" => fact },
                :upsert => true } } ], :ordered => false );
            
        end
    end
    
    if $removeafterprocess
        FileUtils.rm_rf(path + "/*.json");
    end
    
    return true;
end

target_dir = ARGV[0];
Mongo::Logger.logger.level = $mongologlevel;
client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
client[:edinetfacts].indexes.create_one({ :entityIdentifier => 1, :name => 1, :start => 1, :endInstant => 1, :contextRef => 1 }, { :unique => true, :sparse => true });

# Scan target directory and call ParseXBRL function for each directory which contains XBRL file.
Dir.foreach(target_dir) do |f|
    if File.ftype("#{target_dir}/#{f}") == "directory" && f != "." && f != ".."
        result = true;
        json = "";
        if File.exist?("#{target_dir}/#{f}/XBRL")
            path = "#{target_dir}/#{f}/XBRL/PublicDoc";
        else
            path = "#{target_dir}/#{f}";
        end
        
        langarray = ["en-US", "ja-JP"];
        if generate_json(path, langarray)
            if parse_json(path, client, langarray) == false
                print "Warning: couldn't parse json./n";
                exit(-1);
            end
            exit(0);
        end
    end
end