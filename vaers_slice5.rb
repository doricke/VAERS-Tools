
################################################################################
# Author::      Darrell O. Ricke, Ph.D.  (mailto: d_ricke@yahoo.com)
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
class VaersSlice4

################################################################################
DOSE_NAMES = ["All", "1", "2", "3", "4", "5", "6", "7+", "UNK", "N/A"]
DOSE_NAMES4 = ["All", "1", "2", "3", "4"]
DOSE_NAMES_ALL = ["All"]
GENDERS = ["M", "F"]
MAX_SHOTS = 25

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
          else
            data[ vaers_id ][ :other_symptoms ][ tokens[i] ] = true if ! tokens[i].nil? && tokens[i].size > 0
          end  # if
        end # for
      end  # if
    end  # if
  end  # do
  in_file.close_file

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
      order     = tokens[8].to_i
      if order < 2
        vaers_id  = tokens[0].to_i
        vax_type  = tokens[1]
        vax_manu  = tokens[2]
        vax_lot   = tokens[3]
        vax_lot   = "blank" if tokens[3].nil? || tokens[3].size < 1
        vax_dose  = tokens[4]
        vax_route = tokens[5]
        vax_site  = tokens[6]
        vax_name  = tokens[7]
        # vax_name = vax_type
        data[vaers_id] = {} if data[vaers_id].nil?
        vax_record = { :vax_name => vax_name, :vax_type => vax_type, :vax_dose => vax_dose, :vax_manu => vax_manu, :vax_lot => vax_lot, :vax_route => vax_route, :vax_site => vax_site }
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
      order = tokens[35].to_i
      if order < 2
        vaers_id = tokens[0].to_i
        data[ vaers_id ] = {} if data[ vaers_id ].nil?
        data[ vaers_id ][ :state ] = tokens[2]
        data[ vaers_id ][ :age ] = tokens[3]
        data[ vaers_id ][ :age ] = -1 if tokens[3].nil? || tokens[3].size < 1
        data[ vaers_id ][ :gender ] = tokens[ 6 ]
        # data[ vaers_id ][ :symptom_text ] = tokens[ 8 ]
        data[ vaers_id ][ :died ] = tokens[9]
        data[ vaers_id ][ :onset ] = tokens[20].to_i
        data[ vaers_id ][ :onset ] = -1 if tokens[20].size < 1
        # data[ vaers_id ][ :lab_data ] = tokens[ 21 ]
        # tokens[22] V_ADMINBY
        parts = tokens[1].split( "/" )    # RECVDATE
        data[ vaers_id ][ :year ] = parts[2].to_i
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
  shots = {}
  yearly_shots = {}
  shots_gender = {}
  data.keys.each do |id|
    if ! data[id][:vax].nil?
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        vax_type = vax_record[:vax_type]
        vax_year = data[id][:year]
        gender = data[id][ :gender ]
        v_names[ vax_name ] = true
        shots[ vax_name ] = {} if shots[ vax_name ].nil?
        shots[ vax_name ][ id ] = true
        yearly_shots[ vax_name ] = {} if yearly_shots[ vax_name ].nil?
        yearly_shots[ vax_name ][ vax_year ] = {} if yearly_shots[ vax_name ][ vax_year ].nil?
        yearly_shots[ vax_name ][ vax_year ][ id ] = true

        shots_gender[ vax_name ] = {} if shots_gender[ vax_name ].nil?
        shots_gender[ vax_name ][ gender ] = {} if shots_gender[ vax_name ][ gender ].nil?
        shots_gender[ vax_name ][ gender ][ id ] = true
      end  # do
    end  # if
  end  # do

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_dose = vax_record[:vax_dose]
          vax_type = vax_record[:vax_type]
          vax_year = data[id][:year]
          gender = data[id][ :gender ]

          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ vax_dose ] = {} if tally[ vax_name ][ vax_dose ].nil?
          tally[ vax_name ][ vax_dose ][ id ] = true
          tally[ vax_name ][ "All" ] = {} if tally[ vax_name ][ "All" ].nil?
          tally[ vax_name ][ "All" ][ id ] = true
          tally[ vax_name ][ vax_year ] = {} if tally[ vax_name ][ vax_year ].nil?
          tally[ vax_name ][ vax_year ][ id ] = true

          tally[ vax_name ][ gender ] = {} if tally[ vax_name ][ gender ].nil?
          tally[ vax_name ][ gender ][ vax_dose ] = {} if tally[ vax_name ][ gender ][ vax_dose ].nil?
          tally[ vax_name ][ gender ][ vax_dose ][ id ] = true
          tally[ vax_name ][ gender ][ "All" ] = {} if tally[ vax_name ][ gender ][ "All" ].nil?
          tally[ vax_name ][ gender ][ "All" ][ id ] = true

          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
        end  # do
      end  # if
    end  # do
  end  # do

  print "Vaccine Name\tShots\tFrequency\tFemale:Male"
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name}"
  end  # do
  print "\tMale shots\tMale freq."
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} male"
  end  # do
  print "\tFemale shots\tFemale freq."
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} female"
  end  # do
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name} Unknown"
  end  # do
  print "\n"

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  vax_names.each do |vax_name, c|
    print "#{vax_name}\t#{shots[vax_name].keys.size}"

    count = 0
    count = tally[ vax_name ][ "All" ].keys.size if ! tally[ vax_name ][ "All" ].nil?
    freq = (count * 100000) / shots[vax_name].keys.size
    print "\t#{freq}"
    gender_ratio = 0.0
    if ! tally[ vax_name ][ "M" ].nil? && ! tally[ vax_name ][ "F" ].nil? && (tally[ vax_name ][ "M" ][ "All" ].keys.size > 0)
      gender_ratio = tally[ vax_name ][ "F" ][ "All" ].keys.size.to_f / tally[ vax_name ][ "M" ][ "All" ].keys.size.to_f
    end  # if
    print "\t%.2f" % [gender_ratio]
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ dose_name ].keys.size if ! tally[ vax_name ][ dose_name ].nil?
      print "\t#{count}"
    end  # do

    count = 0
    count = shots_gender[ vax_name ][ "M" ].keys.size if ! shots_gender[ vax_name ][ "M" ].nil?
    freq = 0.0
    freq = (tally[ vax_name ][ "M" ][ "All" ].keys.size * 100000) / count if count > 0 && ! tally[ vax_name ][ "M" ].nil? && ! tally[ vax_name ][ "M" ][ "All" ].nil?
    print "\t#{count}\t#{freq}"
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "M" ][ dose_name ].keys.size if ! tally[ vax_name ][ "M" ].nil?  && ! tally[ vax_name ][ "M" ][ dose_name ].nil?
      print "\t#{count}"
    end  # do

    count = 0
    count = shots_gender[ vax_name ][ "F" ].keys.size if ! shots_gender[ vax_name ][ "F" ].nil?
    freq = 0.0
    freq = (tally[ vax_name ][ "F" ][ "All" ].keys.size * 100000) / count if count > 0 && ! tally[ vax_name ][ "F" ].nil? && ! tally[ vax_name ][ "F" ][ "All" ].nil?
    print "\t#{count}\t#{freq}"
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "F" ][ dose_name ].keys.size if ! tally[ vax_name ][ "F" ].nil?  && ! tally[ vax_name ][ "F" ][ dose_name ].nil?
      print "\t#{count}"
    end  # do
    DOSE_NAMES.each do |dose_name|
      count = 0
      count = tally[ vax_name ][ "U" ][ dose_name ].keys.size if ! tally[ vax_name ][ "U" ].nil?  && ! tally[ vax_name ][ "U" ][ dose_name ].nil?
      print "\t#{count}"
    end  # do
    print "\n"
  end  # do

  # Summary of adverse events by year
  puts "\nYear report"
  print "Vaccine Name\tAll"
  for year in (2024..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    print "\t#{tally[vax_name]['All'].keys.size}"
    for year in (2024..1990).step(-1) do
      count = 0
      count = tally[ vax_name ][ year ].keys.size if ! tally[ vax_name ][ year ].nil?
      print "\t#{count}"
    end  # for
    print "\n"
  end  # do

  # Yearly number of shots
  puts "\nYear shots report"
  print "Vaccine Name\tAll"
  for year in (2024..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    print "\t#{shots[vax_name].keys.size}"
    for year in (2024..1990).step(-1) do
      count = 0
      count = yearly_shots[ vax_name ][ year ].keys.size if ! yearly_shots[ vax_name ][ year ].nil?
      print "\t#{count}"
    end  # for
    print "\n"
  end  # do

  # Yearly symptoms frequency
  puts "\nYear frequency report per 100,000 vaccine shots"
  print "Vaccine Name\tAll"
  for year in (2024..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    freq = 0.0
    freq = tally[vax_name]['All'].keys.size.to_f * 100000.0 / shots[vax_name].keys.size.to_f if ! shots[vax_name].nil? && shots[vax_name].keys.size > 0

    print "\t#{'%.1f' % freq}"
    for year in (2024..1990).step(-1) do
      freq = 0.0
      freq = tally[ vax_name ][ year ].keys.size.to_f * 100000.0 / yearly_shots[ vax_name ][ year ].keys.size.to_f if ! yearly_shots[ vax_name ][ year ].nil? && ! tally[ vax_name ][ year ].nil?
      print "\t#{'%.1f' % freq}"
    end  # for
    print "\n"
  end  # do
end  # dose_report

################################################################################
def shots_report( data, select )
  puts "\nVaccine shots report"
  tally = {}
  combo_tally = {}
  combo_shots = {}
  combo_age = {}
  age_tally = {}
  vax_tally = {}
  shots_tally = {}

  # Tally up the vaccine shots by concurrent count by vaccine.
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      age = data[id][:age].to_i
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        v_names[ vax_name ] = true
      end  # do
  
      # Tally all shot combinations
      combo_names = v_names.keys.sort.join( "+" )
      combo_shots[ combo_names ] = 0 if combo_shots[ combo_names ].nil?
      combo_shots[ combo_names ] += 1
  
      vax_shots = data[id][ :vax ].size
      shots_tally[ combo_names ] = {} if shots_tally[ combo_names ].nil?
      shots_tally[ combo_names ][ vax_shots ] = {} if shots_tally[ combo_names ][ vax_shots ].nil?
      shots_tally[ combo_names ][ vax_shots ][ id ] = true
  
      # Tally all shot combinations by age
      age_tally[ combo_names ] = {} if age_tally[ combo_names ].nil?
      age_tally[ combo_names ][age] = 0 if age_tally[ combo_names ][age].nil?
      age_tally[ combo_names ][age] += 1
      age_tally[ combo_names ][:all] = 0 if age_tally[ combo_names ][:all].nil?
      age_tally[ combo_names ][:all] += 1
    end  # if
  end  # do

# Tally up the symptom by number of vaccine shots.
  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        age = data[id][:age].to_i
        v_names = {}
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          v_names[ vax_name ] = true
        end  # do

        combo_names = v_names.keys.sort.join( "+" )
        combo_tally[ combo_names ] = 0 if combo_tally[ combo_names ].nil?
        combo_tally[ combo_names ] += 1

        tally[ combo_names ] = {} if tally[ combo_names ].nil?
        tally[ combo_names ][ "All" ] = {} if tally[ combo_names ][ "All" ].nil?
        tally[ combo_names ][ "All" ][ id ] = true 
        vax_shots = data[id][ :vax ].size
        tally[ combo_names ][ vax_shots ] = {} if tally[ combo_names ][ vax_shots ].nil?
        tally[ combo_names ][ vax_shots ][ id ] = true

        vax_tally[ combo_names ] = 0 if vax_tally[ combo_names ].nil?
        vax_tally[ combo_names ] += 1

        combo_age[ combo_names ] = {} if combo_age[ combo_names ].nil?
        combo_age[ combo_names ][age] = 0 if combo_age[ combo_names ][age].nil?
        combo_age[ combo_names ][age] += 1

        combo_age[ combo_names ][:all] = 0 if combo_age[ combo_names ][:all].nil?
        combo_age[ combo_names ][:all] += 1
      end  # if
    end  # do
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print out the header.
  print "Vaccine\tAll"
  for shots in 1..MAX_SHOTS do
    print "\t#{shots}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    total = 0
    total = tally[ vax_name ][ "All" ].keys.size if ! tally[ vax_name ][ "All" ].nil?
    print "\t#{total}"
    for shots in 1..MAX_SHOTS do
      if tally[ vax_name ][ shots ].nil?
        print "\t0"
      else
        shots_given = 0
        shots_given = shots_tally[ vax_name ][ shots ].keys.size if ! shots_tally[ vax_name ].nil? && ! shots_tally[ vax_name ][ shots ].nil?
        count = tally[ vax_name ][ shots ].keys.size
        freq = count.to_f * 100000.0 / shots_given 
        print "\t#{tally[vax_name][shots].keys.size}|#{shots_given}|#{'%.1f' % freq}"
      end  # if
    end  # do
    print "\n"
  end  # do

  combo_order = combo_tally.keys.sort

  # Print out the header.
  puts "\nVaccine combination shots report by age"
  print "Combination\tAll\tAll"
  for age in 0..100 do
    print "\tAge #{age}\tAge #{age}"
  end  # do
  print "\n"

  # Print out combination tallies by age
  combo_order.each do |c_name|
    tally_age = age_tally[ c_name ][ :all] 
    age_combo = 0
    age_combo = combo_age[ c_name ][ :all ] if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ :all ].nil?
    freq = 0 
    freq = age_combo * 100000.0 / tally_age if tally_age > 0
    print "#{c_name}\t#{age_combo}|#{tally_age}|#{'%.1f' % freq}\t#{'%.1f' % freq}"

    # tally_age = age_tally[ c_name ][ 0 ] if ! age_tally[ c_name ][ 0 ].nil?
    age_combo = 0
    age_combo = combo_age[ c_name ][ 0 ] if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ 0 ].nil?
    for age in 0..100 do
      tally_age = 0
      tally_age = age_tally[ c_name ][ age ] if ! age_tally[ c_name ][ age ].nil?
      age_combo = 0
      age_combo = combo_age[ c_name ][ age ] if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ age ].nil?
      freq = 0 
      freq = age_combo * 100000.0 / tally_age if tally_age > 0
      print "\t#{age_combo}|#{tally_age}|#{'%.1f' % freq}\t#{'%.1f' % freq}"
    end  # do
    print "\n"
  end  # do

end  # shots_report

################################################################################
def age_report_write( vax_names, dose_names, tally )
  # Print out the header.
  vax_names.each do |vax_name, count|
    dose_names.each do |dose_name|
      if dose_name == "All"
        print "\t#{vax_name}"
      else
        print "\t#{dose_name}"
      end  # if
    end  # do 
  end  # do
  print "\n"

  # Print out the age report table.
  for age in -1..120 do
    print "#{age}"
    vax_names.each do |vax_name, count|
      dose_names.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ age ].keys.size if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ age ].nil?
        print "\t#{count}"
      end  # do 

      if dose_names.size > 1
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "M" ][ age ].keys.size if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ][ age ].nil?
          print "\t#{count}"
        end  # do 
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "F" ][ age ].keys.size if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ][ age ].nil?
          print "\t#{count}"
        end  # do 
      end  # if
    end  # do
    print "\n"
  end  # do
end  # age_report_write

################################################################################
def age_report_frequency( vax_names, tally, vax_total )
  puts "\nAge report frequency normalized to 100,000 shots with symptoms by age"

  # Print out the header.
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  vax_names.each do |vax_name, count|
    print "\tM:#{vax_name}"
  end  # do
  vax_names.each do |vax_name, count|
    print "\tF:#{vax_name}"
  end  # do
  print "\n"

  # Print out the age report table with normalized frequencies.
  for age in -1..120 do
    print "#{age}"
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      count = tally[ vax_name ][ "All" ][ age ].keys.size if ! tally[ vax_name ][ "All" ][ age ].nil?
      total = 0
      if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ age ].nil? 
        total = vax_total[ vax_name ][ age ].keys.size
        freq = count.to_f * 100000.0 / total
      end  # if
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do

    # Calculate for males
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      count = tally[ vax_name ][ "All" ][ "M" ][ age ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ][ age ].nil?
      total = vax_total[ vax_name ][ "M" ][ age ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "M" ].nil? && ! vax_total[ vax_name ][ "M" ][ age ].nil? 
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
      
    # Calculate for females
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      count = tally[ vax_name ][ "All" ][ "F" ][ age ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ][ age ].nil?
      total = vax_total[ vax_name ][ "F" ][ age ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "F" ].nil? && ! vax_total[ vax_name ][ "F" ][ age ].nil? 
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
    print "\n"
  end  # do
end  # age_report_frequency

################################################################################
def age_report_frequency_years( vax_names, tally, vax_total )
  puts "\nAge report frequency normalized to 100,000 shots with symptoms by age"

  # Print out the header.
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  vax_names.each do |vax_name, count|
    print "\tM:#{vax_name}"
  end  # do
  vax_names.each do |vax_name, count|
    print "\tF:#{vax_name}"
  end  # do
  print "\n"

  # Print out the age report table with normalized frequencies.
  min_age = 0
  for max_age in (10..120).step(10) do
    print "#{min_age} to #{max_age}"
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      for age in min_age..max_age do
        count += tally[ vax_name ][ "All" ][ age ].keys.size if ! tally[ vax_name ][ "All" ][ age ].nil?
        total += vax_total[ vax_name ][ age ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ age ].nil? 
      end  # for
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do

    # Calculate for males
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      for age in min_age..max_age do
        count += tally[ vax_name ][ "All" ][ "M" ][ age ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ][ age ].nil?
        total += vax_total[ vax_name ][ "M" ][ age ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "M" ].nil? && ! vax_total[ vax_name ][ "M" ][ age ].nil? 
      end  # for
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
      
    # Calculate for females
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      for age in min_age..max_age do
        count += tally[ vax_name ][ "All" ][ "F" ][ age ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ][ age ].nil?
        total += vax_total[ vax_name ][ "F" ][ age ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "F" ].nil? && ! vax_total[ vax_name ][ "F" ][ age ].nil? 
      end  # for
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
    print "\n"
    min_age = max_age + 1
  end  # do
end  # age_report_frequency_years

################################################################################
def age_report( data, select )
  tally = {}
  vax_tally = {}
  vax_total = {}

  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]
        if ! data[id][ :age ].nil?
          age = data[id][ :age ].to_i
          gender = data[id][ :gender ]

          # Tally by vaccine and age
          vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
          vax_total[ vax_name ][ age ] = {} if vax_total[ vax_name ][ age ].nil?
          vax_total[ vax_name ][ age ][ id ] = true

          # Tally by vaccine, age, and gender
          vax_total[ vax_name ][ gender ] = {} if vax_total[ vax_name ][ gender ].nil?
          vax_total[ vax_name ][ gender ][ age ] = {} if vax_total[ vax_name ][ gender ][ age ].nil?
          vax_total[ vax_name ][ gender ][ age ][ id ] = true
        end  # if
      end  # do
    end  # if
  end  # do

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][:vax ].each do |vax_record|
          vax_name = vax_record[ :vax_name ]
          vax_dose = vax_record[ :vax_dose ]
          vax_type = vax_record[ :vax_type ]
          age = data[id][ :age ].to_i
          gender = data[id][ :gender ]
  
          # Tally by dose and age
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ vax_dose ] = {} if tally[ vax_name ][ vax_dose ].nil?
          tally[ vax_name ][ vax_dose ][ age ] = {} if tally[ vax_name ][ vax_dose ][ age ].nil?
          tally[ vax_name ][ vax_dose ][ age ][ id ] = true
  
          # Tally for all doses by age
          tally[ vax_name ][ "All" ] = {} if tally[ vax_name ][ "All" ].nil?
          tally[ vax_name ][ "All" ][ age ] = {} if tally[ vax_name ][ "All" ][ age ].nil?
          tally[ vax_name ][ "All" ][ age ][ id ] = true
  
          # Tally by gender
          tally[ vax_name ][ vax_dose ][ gender ] = {} if tally[ vax_name ][ vax_dose ][ gender ].nil?
          tally[ vax_name ][ vax_dose ][ gender ][ age ] = {} if tally[ vax_name ][ vax_dose ][ gender ][ age ].nil?
          tally[ vax_name ][ vax_dose ][ gender ][ age ][ id ] = true
  
          # Tally by gender
          tally[ vax_name ][ "All" ][ gender ] = {} if tally[ vax_name ][ "All" ][ gender ].nil?
          tally[ vax_name ][ "All" ][ gender ][ age ] = {} if tally[ vax_name ][ "All" ][ gender ][ age ].nil?
          tally[ vax_name ][ "All" ][ gender ][ age ][ id ] = true

          # Tally by vaccine
          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
        end  # do
      end  # if
    end  # do
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  puts "\nAge report summary"
  age_report_write( vax_names, DOSE_NAMES_ALL, tally )

  age_report_frequency( vax_names, tally, vax_total )
  age_report_frequency_years( vax_names, tally, vax_total )

  puts "\nAge report details"
  age_report_write( vax_names, DOSE_NAMES4, tally )
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
  for onset in -1..120 do
    print "#{onset}"
    vax_names.each do |vax_name, count|
      dose_names.each do |dose_name|
        count = ""
        count = tally[ vax_name ][ dose_name ][ onset ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ onset ].nil?
        print "\t#{count}"
      end  # do 

      if dose_names.size > 1
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "M" ][ onset ].keys.size if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ].nil? && ! tally[ vax_name ][ dose_name ][ "M" ][ onset ].nil?
          print "\t#{count}"
        end  # do 
        dose_names.each do |dose_name|
          count = ""
          count = tally[ vax_name ][ dose_name ][ "F" ][ onset ].keys.size if ! tally[ vax_name ][ dose_name ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ].nil? && ! tally[ vax_name ][ dose_name ][ "F" ][ onset ].nil?
          print "\t#{count}"
        end  # do 
      end  # if
    end  # do
    print "\n"
  end  # do
end  # onset_report_write

################################################################################
def onset_report_frequency( vax_names, tally, vax_total )
  # Print out the header.
  print "Onset frequency normalized per 100,000 shots with symptoms"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  # Print out the onset table.
  for onset in -1..120 do
    print "#{onset}"
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      if ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ onset ].nil? && ! vax_total[ vax_name ].nil?
        count = tally[ vax_name ][ "All" ][ onset ].keys.size
        freq = count.to_f * 100000.0 / vax_total[ vax_name ].keys.size 
      end  # if
      print "\t#{count}|#{vax_total[vax_name].keys.size}|#{'%.0f' % freq}"
    end  # do
    print "\n"
  end  # do
end  # onset_report_frequency

################################################################################
def onset_report( data, select )
  tally = {}
  vax_tally = {}
  vax_total = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]

        # Total by vaccine 
        vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
        vax_total[ vax_name ][ id ] = true
      end  # do
    end  # if
  end  # do

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][:vax ].each do |vax_record|
          vax_name = vax_record[ :vax_name ]
          vax_dose = vax_record[ :vax_dose ]
          vax_type = vax_record[ :vax_type ]
          # age = data[id][ :age ].to_i
          gender = data[id][ :gender ]
          onset = data[id][ :onset ]
  
          # Tally by dose and onset
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ vax_dose ] = {} if tally[ vax_name ][ vax_dose ].nil?
          tally[ vax_name ][ vax_dose ][ onset ] = {} if tally[ vax_name ][ vax_dose ][ onset ].nil?
          tally[ vax_name ][ vax_dose ][ onset ][ id ] = true
  
          # Tally for all doses.
          tally[ vax_name ][ "All" ] = {} if tally[ vax_name ][ "All" ].nil?
          tally[ vax_name ][ "All" ][ onset ] = {} if tally[ vax_name ][ "All" ][ onset ].nil?
          tally[ vax_name ][ "All" ][ onset ][ id ] = true
  
          # Tally by gender and onset.
          tally[ vax_name ][ vax_dose ][ gender ] = {} if tally[ vax_name ][ vax_dose ][ gender ].nil?
          tally[ vax_name ][ vax_dose ][ gender ][ onset ] = {} if tally[ vax_name ][ vax_dose ][ gender ][ onset ].nil?
          tally[ vax_name ][ vax_dose ][ gender ][ onset ][ id ] = true
  
          # Tally by gender and onset.
          tally[ vax_name ][ "All" ][ gender ] = {} if tally[ vax_name ][ "All" ][ gender ].nil?
          tally[ vax_name ][ "All" ][ gender ][ onset ] = {} if tally[ vax_name ][ "All" ][ gender ][ onset ].nil?
          tally[ vax_name ][ "All" ][ gender ][ onset ][ id ] = true

          # Tally by vaccine 
          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
        end  # do
      end  # if
    end  # do
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  puts "\nOnset report summary"
  onset_report_write( vax_names, DOSE_NAMES_ALL, tally )

  onset_report_frequency( vax_names, tally, vax_total )

  puts "\nOnset report details"
  onset_report_write( vax_names, DOSE_NAMES4, tally )
end  # onset_report

################################################################################
def spider_report( data, select )
  tally = {}
  vax_tally = {}
  vax_total = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]

        # Total by vaccine 
        vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
        vax_total[ vax_name ][ id ] = true

        tally[ vax_name ] = {} if tally[ vax_name ].nil?

        # Total by vaccine and symptom
        select.keys.each do |symptom|
          tally[ vax_name ][ symptom ] = 0 if tally[ vax_name ][ symptom ].nil?
          tally[ vax_name ][ symptom ] += 1 if ! data[id][ :symptoms ].nil? && data[id][ :symptoms ][ symptom ] 
        end  # do
      end  # do
    end  # if
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print out the header.
  print "Spider report frequency normalized per 100,000 shots by symptoms"
  print "Symptom"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  # Print out the onset table.
  select.keys.each do |symptom|
    print "#{symptom}"
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ symptom ].nil? && ! vax_total[ vax_name ].nil?
        count = tally[ vax_name ][ symptom ]
        freq = count.to_f * 100000.0 / vax_total[ vax_name ].keys.size 
      end  # if
      print "\t#{count}|#{vax_total[vax_name].keys.size}|#{'%.0f' % freq}"
    end  # do
    print "\n"
  end  # do
end  # spider_report

################################################################################
def correlation_report( data, select )
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
            tally[ symptom ][ adverse_event ] = {} if tally[ symptom ][ adverse_event ].nil?
            tally[ symptom ][ adverse_event ][ id ] = true  if ! data[id][:symptoms][symptom].nil? && data[id][:symptoms][ symptom ]
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
      if tally[ symptom ].nil? || tally[ symptom ][ adverse_event ].nil?
        print "\t"
      else
        print "\t#{tally[symptom][adverse_event].keys.size}"
      end  # if
    end  # do
    print "\n"
  end  #do
end  # correlation_report

################################################################################
def symptoms_report( data, select )
  puts "\nSymptoms report"
  tally = {}
  events = {}
  vax_names = {}
  select.keys.each do |symptom|
    tally[ symptom ] = {}
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][:vax].nil?
        data[id][:symptoms].keys.each do |sym|
          if symptom != sym
            tally[ symptom ][ sym ] = {}  if data[id][:symptoms][ symptom ]
            tally[ symptom ][ sym ][ id ] = true if data[id][:symptoms][ symptom ]
            events[ sym ] = true
          end  # if
        end  # do
      end  # if

      if ! data[id].nil? && ! data[id][:other_symptoms].nil? && ! data[id][:vax].nil?
        data[id][:other_symptoms].keys.each do |adverse_event|
          tally[ symptom ][ adverse_event ] = {} if tally[ symptom ][ adverse_event ].nil?
          tally[ symptom ][ adverse_event ][id] = true  if ! data[id][:symptoms][symptom].nil? && data[id][:symptoms][ symptom ]
          events[ adverse_event ] = true
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
      if tally[ symptom ].nil? || tally[ symptom ][ adverse_event ].nil?
        print "\t"
      else
        print "\t#{tally[symptom][adverse_event].keys.size}"
      end  # if
    end  # do
    print "\n"
  end  #do
end  # symptoms_report

################################################################################
def lot_report( data, select )
  total = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil?
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        vax_lot  = vax_record[:vax_lot]
        total[ vax_name ] = {} if total[ vax_name ].nil?
        total[ vax_name ][ vax_lot ] = 0 if total[ vax_name ][ vax_lot ].nil?
        total[ vax_name ][ vax_lot ] += 1
      end  # do
    end  # if
  end  # do

  tally = {}
  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_lot  = vax_record[:vax_lot]
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ vax_lot ] = 0 if tally[ vax_name ][ vax_lot ].nil?
          tally[ vax_name ][ vax_lot ] += 1
        end  # do
      end  # if
    end  # do
  end  # do

  print "\nVaccine lot report\n"
  # Report by vaccine x lots
  tally.keys.sort.each do |vax_name|
    # Print the header for this vaccine.
    print "#{vax_name}"

    tally_this = tally[ vax_name ]
    lot_names = tally_this.sort_by{ |vax_lot, count| -count }

    lot_names.each do |vax_lot, count|
      # count = tally[ vax_name ][ vax_lot ]
      shots = total[ vax_name ][ vax_lot ]
      print "\t#{vax_lot}" if ! count.nil? && ! shots.nil?
    end  # do
    print "\n"

    print "#{vax_name}"
    lot_names.each do |vax_lot, count|
      # puts "vax_name: #{vax_name}, vax_lot: |#{vax_lot}|"
      # count = tally[ vax_name ][ vax_lot ]
      shots = total[ vax_name ][ vax_lot ]
      if ! count.nil? && ! shots.nil? 
        freq = 0.0
        freq = (count * 100000) / shots if shots > 0
        print "\t#{count}|#{shots}|#{'%.0f' % freq}"
      end  # if
    end  # do  
    print "\n"
  end  # do
end  # lot_report

################################################################################
def data_report( data, select )
  puts "\nSymptom\tVax name\tVax dose\tVax lot\tVax site\tVax Manuf\tGender\tOnset\tAge\tVaersID\tDied\tState"

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_dose = vax_record[:vax_dose]
          vax_type = vax_record[:vax_type]
          vax_manu = vax_record[:vax_manu]
          vax_lot  = vax_record[:vax_lot]
          vax_site = vax_record[:vax_site]

          vax_year = data[id][:year]
          gender = data[id][ :gender ]
          age = data[id][:age]
          onset = data[id][ :onset ]
          died = data[id][ :died ]
          state = data[id][ :state ]
          # symptom_text = data[id][ :symptom_text ]
          # lab_data = data[id][ :lab_data ]

          # puts "#{symptom}\t#{vax_name}\t#{vax_type}\t#{vax_dose}\t#{vax_lot}\t#{vax_site}\t#{vax_manu}\t#{gender}\t#{onset}\t#{symptom}\t#{age}\t#{id}\t#{died}\t#{state}\t#{symptom_text}\t#{lab_data}"
          puts "#{symptom}\t#{vax_name}\t#{vax_dose}\t#{vax_lot}\t#{vax_site}\t#{vax_manu}\t#{gender}\t#{onset}\t#{age}\t#{id}\t#{died}\t#{state}"
        end  # do
      end  # if
    end  # do
  end  # do
end  # data_report

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
  # for year in 2022..2024 do
  for year in 1990..2024 do
    data = load_year( year.to_s, select, vaccines, data )
  end  # for
  data = load_year( "NonDomestic", select, vaccines, data )

  # Generate the data analysis reports.
  dose_report( data, select )
  shots_report( data, select )
  age_report( data, select )
  onset_report( data, select )
  spider_report( data, select )
  correlation_report( data, select )
  symptoms_report( data, select )
  lot_report( data, select )
# data_report( data, select )
end  # vaers_main 

################################################################################

end  # class VaersSlice4

################################################################################
def main( select_filename )
  app = VaersSlice4.new
  app.vaers_main( select_filename )
end  # main

################################################################################

main( ARGV[0] )
