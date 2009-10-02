##########################################################################
# Copyright 2007 Applied Research in Patacriticism and the University of Virginia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

require 'rubygems'
require 'marc'
require 'script/lib/nines_mapping.rb'

# # IS THIS ACTUALLY USED ANYWHERE???
$KCODE = 'UTF8'

class MarcGenreScanner
  
  include NinesMapping
  
  def self.run( files_to_index_dir, forgiving )
    puts "Scanning for genre keywords..."
    start_time = Time.new ## start the clock

    scanner = MarcGenreScanner.new( forgiving )
    scanner.scan_directory(files_to_index_dir)
    scanner.generate_report()

    end_time = Time.new
    time_lapsed = end_time - start_time
    puts "Scan completed in #{time_lapsed} seconds" 
  end
      
  attr_reader :record_count, :no_genre_found
  
  MAPPINGS = (GENRE_MAPPING.values + GEOGRAPHIC_MAPPING.values + FORMAT_MAPPING.values).flatten

  def initialize( forgiving )
    @field_data = {}
    @record_count = 0
    @no_genre_found = 0
    @mapping_found = 0
    @mapped_records_count = 0
    @forgiving = forgiving
  end
  
  def scan_directory( dir )
    ## put all of the .mrc files in the directory into an array
    marc_files = Dir["#{dir}/*.mrc"].entries

    ## go through all the .mrc files in the files_to_index_dir and pull out the genre information
    marc_files.each do |marc_file|
      scan_file(marc_file)
    end
    
    # sort the field data
    @sorted_field_data = @field_data.values.sort { |a,b| a[:count] <=> b[:count] }.reverse  
  end
  
  def code_string( code )
    "#{code[0]}.#{code[1]}"
  end
  
  def generate_report()
    code_list = ""
    SCAN_LIST.each do |code|
      code_list << " " << code_string( code )
    end
    puts
    puts "Scanned for the following MARC record codes: "
    puts code_list
    
    puts
    puts "Scan Summary"
    puts "============"
    puts "#{@mapping_found} keywords were found in the NINES mapping."
    puts "#{@mapped_records_count} MARC records were mapped to NINES genres."
    puts "#{@no_genre_found} MARC records had no data at the specified record codes."
    puts "#{@record_count} MARC records scanned."   
    puts
    puts "Scan Results"
    puts "============"
    puts "* indicates that this keyword was found in the NINES mapping."
    puts "(n) the number of occurrences of this keyword discovered in the MARC data."
    puts 
    @sorted_field_data.each do |data|
      star = data[:mapping] ? "*" : ""
      puts "#{data[:code]} #{data[:field_name]} (#{data[:count]})#{star}"
    end     
    
  end
  
  def scan_file( marc_file )
    puts "Scanning #{marc_file}..."
    reader = MARC::ForgivingReader.new(marc_file) #, { :forgiving => @forgiving })
    for record in reader
      scan_record( record )  
#      break if @record_count >= 1000
    end   
  end
  
  def scan_record( record )
    found = false
    mapped = false
    SCAN_LIST.each do |genre_field|
      field = record[genre_field[0]]
      if field
        subfield = field[genre_field[1]]
        if subfield
          mapped = true if store_field( subfield, code_string(genre_field) ) == true
          found = true
        end
      end
    end    
    @record_count = @record_count + 1
    @no_genre_found = @no_genre_found + 1 if not found
    @mapped_records_count = @mapped_records_count + 1 if mapped
  end
  
  def store_field( field_name, code )
    normalized_field_name = normalize_field_name( field_name )    
    data = @field_data[normalized_field_name]
    mapping = false
    
    if data
      data[:count] = @field_data[normalized_field_name][:count] + 1       
      data[:code] << " " << code unless data[:code].include?(code)
      mapping = true if data[:mapping]
    else
      mapping = MAPPINGS.include? normalized_field_name
      @mapping_found = @mapping_found + 1 if mapping
      @field_data[normalized_field_name] = { :field_name => normalized_field_name, :count => 1, :code => code, :mapping => mapping }
    end
    
    mapping
  end
  
  def normalize_field_name( value )
    normed = value.downcase
    if normed[value.size-1] == 46 # remove '.'
      normed = normed[0..-2]
    end
    normed
  end

end