
################################################################################
# Author::      Darrell O. Ricke, Ph.D.  (mailto: doricke@molecularbioinsights.com)
# Copyright::   Copyright (C) 2022 Darrell O. Ricke, Ph.D., Molecular BioInsights
# License::     GNU GPL license:  http://www.gnu.org/licenses/gpl.html
# Contact::     Molecular BioInsights, 37 Pilgrim Dr., MA 01890
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

require './input_file'
require './table'
require './text_tools'

################################################################################
class VaersSlice

################################################################################
DOSE_NAMES = ["All", "1", "2", "3", "4", "5", "6", "7+", "UNK", "N/A"]
DOSE_NAMES4 = ["All", "1", "2", "3", "4"]
DOSE_NAMES_ALL = ["All"]
GENDERS = ["M", "F"]

################################################################################
def read_select( filename )
  select_table = Table.new
  select = select_table.load_table( filename, "," )
  return select
end  # read_select

################################################################################
def report_select( select )
  puts "Selected VAERS search terms:"
  select.each do |name, line|
    puts line
  end  # do
  puts
end  # report_select

################################################################################
def read_symptoms( filename, select, data )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line
  total = 0
  while ! in_file.is_end_of_file? 
    line = in_file.next_line
    if ! line.nil? && line.length > 0
      tokens = TextTools::csv_split( line.chomp )
      match = false
      for i in (1..9).step(2) do
        match = true if select[ tokens[i] ]
      end  # for

      # Record symptoms if match or previous symptoms matched for this individual
      vaers_id = tokens[0].to_i
      if match || ! data[ vaers_id ].nil?
        data[ vaers_id ] = {} if data[ vaers_id ].nil?
        data[ vaers_id ][ :symptoms ] = {} if data[ vaers_id ][ :symptoms ].nil?
        data[ vaers_id ][ :other_symptoms ] = {} if data[ vaers_id ][ :other_symptoms ].nil?
        for i in (1..9).step(2) do
          if ! tokens[i].nil? && ! select[ tokens[i] ].nil?
            data[ vaers_id ][ :symptoms ][ tokens[i] ] = true 
            total += 1
          else
            data[ vaers_id ][ :other_symptoms ][ tokens[i] ] = true if ! tokens[i].nil? && tokens[i].size > 0
          end  # if
        end # for
      end  # if
    end  # if
  end  # do
  in_file.close_file

  # puts "#{filename} matched #{total}"
  return data
end  # read_symptoms

################################################################################
def read_vax( filename, data, vaccines )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line
  while ! in_file.is_end_of_file? 
    line = in_file.next_line
    if ! line.nil? && line.length > 0
      tokens = TextTools::csv_split( line.chomp )
      vaers_id = tokens[0].to_i
      vax_type = tokens[1]
      vax_dose = tokens[4]
      vax_name = tokens[7]
      # vax_name = vax_type
      if ! data[vaers_id].nil? && (vaccines.keys.size < 1 || vaccines[ vax_type ])
        vax_record = { :vax_name => vax_name, :vax_type => vax_type, :vax_dose => vax_dose }
        data[ vaers_id ][ :vax ] = [] if data[ vaers_id ][ :vax ].nil?
        data[ vaers_id ][ :vax ].push( vax_record )
      end  # if
    end  # if
  end  # do
  in_file.close_file

  return data
end  # read_vax

################################################################################
def read_data( filename, data )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line
  while ! in_file.is_end_of_file? 
    line = in_file.next_line
    if ! line.nil? && line.length > 0
      tokens = TextTools::csv_split( line.chomp )
      vaers_id = tokens[0].to_i
      if ! data[ vaers_id ].nil?
        data[ vaers_id ][ :age ] = tokens[3]
        data[ vaers_id ][ :age ] = -1 if tokens[3].nil? || tokens[3].size < 1
        data[ vaers_id ][ :gender ] = tokens[ 6 ]
        data[ vaers_id ][ :died ] = tokens[9]
        data[ vaers_id ][ :onset ] = tokens[20].to_i
      end  # if
    end  # if
  end  # do
  in_file.close_file

  return data
end  # read_data

################################################################################
def dose_report( data, select )
  puts "Dose report"
  tally = {}
  vax_tally = {}
  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_dose = vax_record[:vax_dose]
          vax_type = vax_record[:vax_type]
          gender = data[id][ :gender ]
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ vax_dose ] = 0 if tally[ vax_name ][ vax_dose ].nil?
          tally[ vax_name ][ vax_dose ] += 1 
          tally[ vax_name ][ "All" ] = 0 if tally[ vax_name ][ "All" ].nil?
          tally[ vax_name ][ "All" ] += 1 

          tally[ vax_name ][ gender ] = {} if tally[ vax_name ][ gender ].nil?
          tally[ vax_name ][ gender ][ vax_dose ] = 0 if tally[ vax_name ][ gender ][ vax_dose ].nil?
          tally[ vax_name ][ gender ][ vax_dose ] += 1 
          tally[ vax_name ][ gender ][ "All" ] = 0 if tally[ vax_name ][ gender ][ "All" ].nil?
          tally[ vax_name ][ gender ][ "All" ] += 1 

          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
        end  # do
      end  # if
    end  # do
  end  # do

  print "Vaccine Name"
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name}"
  end  # do
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} male"
  end  # do
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} female"
  end  # do
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} Unknown"
  end  # do
  print "\n"

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  vax_names.each do |vax_name, count|
  # tally.keys.each do |vax_name|
    print "#{vax_name}"
    DOSE_NAMES.each do |dose_name|
      print "\t#{tally[vax_name][dose_name]}"
    end  # do
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "M" ][ dose_name ] if ! tally[ vax_name ][ "M" ].nil? 
      print "\t#{count}"
    end  # do
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "F" ][ dose_name ] if ! tally[ vax_name ][ "F" ].nil? 
      print "\t#{count}"
    end  # do
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "U" ][ dose_name ] if ! tally[ vax_name ][ "U" ].nil? 
      print "\t#{count}"
    end  # do
    print "\n"
  end  # do
end  # dose_report

################################################################################
def age_report( data )
  puts "\nAge report"
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][:vax].nil?
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]
        vax_dose = vax_record[ :vax_dose ]
        vax_type = vax_record[ :vax_type ]
        age = data[id][ :age ].to_i
        gender = data[id][ :gender ]

        # Tally by dose and age
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][ vax_dose ] = {} if tally[ vax_name ][ vax_dose ].nil?
        tally[ vax_name ][ vax_dose ][ age ] = 0 if tally[ vax_name ][ vax_dose ][ age ].nil?
        tally[ vax_name ][ vax_dose ][ age ] += 1

        # Tally for all doses by age
        tally[ vax_name ][ "All" ] = {} if tally[ vax_name ][ "All" ].nil?
        tally[ vax_name ][ "All" ][ age ] = 0 if tally[ vax_name ][ "All" ][ age ].nil?
        tally[ vax_name ][ "All" ][ age ] += 1

        # Tally by gender
        tally[ vax_name ][ vax_dose ][ gender ] = {} if tally[ vax_name ][ vax_dose ][ gender ].nil?
        tally[ vax_name ][ vax_dose ][ gender ][ age ] = 0 if tally[ vax_name ][ vax_dose ][ gender ][ age ].nil?
        tally[ vax_name ][ vax_dose ][ gender ][ age ] += 1

        # Tally by gender
        tally[ vax_name ][ "All" ][ gender ] = {} if tally[ vax_name ][ "All" ][ gender ].nil?
        tally[ vax_name ][ "All" ][ gender ][ age ] = 0 if tally[ vax_name ][ "All" ][ gender ][ age ].nil?
        tally[ vax_name ][ "All" ][ gender ][ age ] += 1

        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
      end  # do
    end  # if
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print out the header.
  print "Age"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
    DOSE_NAMES4.each do |dose_name|
      print "\t#{dose_name}"
    end  # do 
    DOSE_NAMES4.each do |dose_name|
      print "\t#{dose_name} male"
    end  # do 
    DOSE_NAMES4.each do |dose_name|
      print "\t#{dose_name} female"
    end  # do 
  end  # do
  print "\n"

  # Print out the age report table.
  for age in -1..120 do
    print "#{age}"
    vax_names.each do |vax_name, count|
      print "\t#{vax_name}"
      DOSE_NAMES4.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ age ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ age ].nil?
        print "\t#{count}"
      end  # do 
      DOSE_NAMES4.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ "M" ][ age ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ][ age ].nil?
        print "\t#{count}"
      end  # do 
      DOSE_NAMES4.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ "F" ][ age ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ][ age ].nil?
        print "\t#{count}"
      end  # do 
    end  # do
    print "\n"
  end  # do
end  # age_report

################################################################################
def onset_report_write( vax_names, dose_names, tally )
  # Print out the header.
  print "Onset"
  vax_names.each do |vax_name, count|
    dose_names.each do |dose_name|
      if dose_name == "All"
        print "\t#{vax_name}"
      else
        print "\t#{dose_name}"
      end  # if
    end  # do 

    if dose_names.size > 1
      dose_names.each do |dose_name|
        print "\t#{dose_name} male"
      end  # do 
      dose_names.each do |dose_name|
        print "\t#{dose_name} female"
      end  # do 
    end  # if
  end  # do
  print "\n"

  # Print out the onset table.
  for onset in 0..120 do
    print "#{onset}"
    vax_names.each do |vax_name, count|
      dose_names.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ onset ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ onset ].nil?
        print "\t#{count}"
      end  # do 

      if dose_names.size > 1
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "M" ][ onset ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ][ onset ].nil?
          print "\t#{count}"
        end  # do 
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "F" ][ onset ] if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ][ onset ].nil?
          print "\t#{count}"
        end  # do 
      end  # if
    end  # do
    print "\n"
  end  # do
end  # onset_report_write

################################################################################
def onset_report( data )
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][:vax].nil?
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]
        vax_dose = vax_record[ :vax_dose ]
        vax_type = vax_record[ :vax_type ]
        # age = data[id][ :age ].to_i
        gender = data[id][ :gender ]
        onset = data[id][ :onset ].to_i

        # Tally by dose and onset
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][ vax_dose ] = {} if tally[ vax_name ][ vax_dose ].nil?
        tally[ vax_name ][ vax_dose ][ onset ] = 0 if tally[ vax_name ][ vax_dose ][ onset ].nil?
        tally[ vax_name ][ vax_dose ][ onset ] += 1

        # Tally for all doses.
        tally[ vax_name ][ "All" ] = {} if tally[ vax_name ][ "All" ].nil?
        tally[ vax_name ][ "All" ][ onset ] = 0 if tally[ vax_name ][ "All" ][ onset ].nil?
        tally[ vax_name ][ "All" ][ onset ] += 1

        # Tally by gender and onset.
        tally[ vax_name ][ vax_dose ][ gender ] = {} if tally[ vax_name ][ vax_dose ][ gender ].nil?
        tally[ vax_name ][ vax_dose ][ gender ][ onset ] = 0 if tally[ vax_name ][ vax_dose ][ gender ][ onset ].nil?
        tally[ vax_name ][ vax_dose ][ gender ][ onset ] += 1

        # Tally by gender and onset.
        tally[ vax_name ][ "All" ][ gender ] = {} if tally[ vax_name ][ "All" ][ gender ].nil?
        tally[ vax_name ][ "All" ][ gender ][ onset ] = 0 if tally[ vax_name ][ "All" ][ gender ][ onset ].nil?
        tally[ vax_name ][ "All" ][ gender ][ onset ] += 1

        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
      end  # do
    end  # if
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  puts "\nOnset report"
  onset_report_write( vax_names, DOSE_NAMES4, tally )

  puts "\nOnset report summary"
  onset_report_write( vax_names, DOSE_NAMES_ALL, tally )
end  # onset_report

################################################################################
def correlation_report( select, data )
  puts "\nSymptoms report"
  tally = {}
  events = {}
  vax_names = {}
  select.keys.each do |symptom|
    tally[ symptom ] = {}
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:other_symptoms].nil? && ! data[id][:vax].nil?
        data[id][:symptoms].keys.each do |adverse_event|
          if adverse_event != symptom
            tally[ symptom ][ adverse_event ] = 0 if tally[ symptom ][ adverse_event ].nil?
            tally[ symptom ][ adverse_event ] += 1  if ! data[id][:symptoms][symptom].nil? && data[id][:symptoms][ symptom ]
            events[ adverse_event ] = true
          end  # if
        end  # do
      end  # if
    end  # do
  end  # do

  # Print header
  print "Adverse event"
  tally.keys.sort.each do |symptom|
    print "\t#{symptom}"
  end  # do
  print "\n"

  # Report the co-occurence of symptoms
  events.keys.sort.each do |adverse_event|
    print "#{adverse_event}"
    tally.keys.sort.each do |symptom|
      print "\t#{tally[symptom][adverse_event]}"
    end  # do
    print "\n"
  end  #do
end  # correlation_report

################################################################################
def symptoms_report( select, data )
  puts "\nSymptoms report"
  tally = {}
  events = {}
  vax_names = {}
  select.keys.each do |symptom|
    tally[ symptom ] = {}
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:other_symptoms].nil? && ! data[id][:vax].nil?
        data[id][:other_symptoms].keys.each do |adverse_event|
          tally[ symptom ][ adverse_event ] = 0 if tally[ symptom ][ adverse_event ].nil?
          tally[ symptom ][ adverse_event ] += 1  if ! data[id][:symptoms][symptom].nil? && data[id][:symptoms][ symptom ]
          events[ adverse_event ] = true
        end  # do

        data[id][:symptoms].keys.each do |sym|
          if symptom != sym
            tally[ symptom ][ sym ] = 0  if data[id][:symptoms][ symptom ]
            tally[ symptom ][ sym ] += 1 if data[id][:symptoms][ symptom ]
            events[ sym ] = true
          end  # if
        end  # do
      end  # if
    end  # do
  end  # do

  # Print header
  print "Adverse event"
  tally.keys.sort.each do |symptom|
    print "\t#{symptom}"
  end  # do
  print "\n"

  # Report the co-occurence of symptoms
  events.keys.sort.each do |adverse_event|
    print "#{adverse_event}"
    tally.keys.sort.each do |symptom|
      print "\t#{tally[symptom][adverse_event]}"
    end  # do
    print "\n"
  end  #do
end  # symptoms_report

################################################################################
def load_year( year, select, vaccines, data )
  data = read_symptoms( "#{year}VAERSSYMPTOMS.csv", select, data )
  data = read_vax( "#{year}VAERSVAX.csv", data, vaccines )
  data = read_data( "#{year}VAERSDATA.csv", data )
  return data
end  # load_year

################################################################################
def vaers_main( select_filename )
  data = {}
  vaccines = {}

  # Read in the selected VAERS symptoms.
  select = read_select( select_filename )
  report_select( select )

  # Read in the VAERS yearly datafiles.
  for year in 1990..2023 do
    data = load_year( year.to_s, select, vaccines, data )
  end  # for
  data = load_year( "NonDomestic", select, vaccines, data )

  # Generate the data analysis reports.
  dose_report( data, select )
  age_report( data )
  onset_report( data )
  correlation_report( select, data )
  symptoms_report( select, data )
end  # vaers_main 

################################################################################

end  # class VaersSlice

################################################################################
def main( select_filename )
  app = VaersSlice.new
  app.vaers_main( select_filename )
end  # main

################################################################################

main( ARGV[0] )
