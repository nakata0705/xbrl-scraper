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

def generate_json(base_dirname)
    filelist = Dir.glob("#{base_dirname}/*.xbrl");
    if filelist.length != 1
        puts "Unexpected number of xbrl files. #{filelist.length}";
        return "";
    end
    
    #return system("python3 #{$arelledir}/arelleCmdLine.py  --disclosureSystem fsa -f #{filelist[0]} --store-to-XBRL-DB \"jsonFile,,xbrl,xbrl,#{base_dirname}/output.json,,json\"");
    result = system("python3 #{$arelledir}/arelleCmdLine.py  -f #{filelist[0]} --store-to-XBRL-DB \"jsonFile,,xbrl,xbrl,#{base_dirname}/output.json,,json\"");
    if result == false
        return "";
    end
    
    json = File.read("#{base_dirname}/output.json");
    FileUtils.rm_rf("#{base_dirname}/output.json");
    
    return json;
end

def parse_json(json, mongo_client)
    # Extract essential part of JSON (financial report instance)
    filings = json.scan(/\"filings\"\:\s*(?<json>\{([^\{\}]++|\g<json>)*+*\})/i);
    
    json_parsed = JSON.parse(filings[0][0], { :max_nesting => false });
    
    datapoints = FindLabel(json_parsed, 'dataPoints')

    if datapoints == nil
        return false;
    else
        datapoints.each do |doc_key, doc|
            doc.each do |key, value|
                if value.respond_to?(:gsub) == true
                    doc[key] = value.gsub(/^file:\/\/\/.*?([^\/]*?\.xbrl.*?)$/, '\1')
                end
            end
            mongo_client[:edinetdatapoints].bulk_write( [ { :replace_one => { :find => { :baseItem => doc['baseItem'], :contextId => doc['contextId'], :document => doc['document'], :period => doc['period'] }, :replacement => doc, :upsert => true } } ], :ordered => false );
        end
        
        return true;
    end
end

target_dir = ARGV[0];
Mongo::Logger.logger.level = $mongologlevel;
client = Mongo::Client.new([$mongoserver], :database => $mongodb, :user => $mongouser, :password => $mongopass)
client[:edinetdatapoints].indexes.create_one({ :baseItem => 1, :contextUrl => 1, :dataPointUrl => 1, :period => 1 }, :unique => true);

# Scan target directory and call ParseXBRL function for each directory which contains XBRL file.
Dir.foreach(target_dir) do |f|
    if File.ftype("#{target_dir}/#{f}") == "directory" && f != "." && f != ".."
        result = true;
        json = "";
        if File.exist?("#{target_dir}/#{f}/XBRL")
            json = generate_json("#{target_dir}/#{f}/XBRL/PublicDoc");
        else
            json = generate_json("#{target_dir}/#{f}");
        end
        
        if json.length == 0
            print "Warning: couldn't generate valid json.\n";
            return -1;
        end
        
        if parse_json(json, client) == false
            print "Warning: couldn't parse json./n";
        end
    end
end