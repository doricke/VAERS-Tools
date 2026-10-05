
################################################################################
# Author::      Darrell O. Ricke, Ph.D.  (mailto: doricke@molecularbioinsights.com)
# Copyright::   Copyright (C) 2026 Darrell O. Ricke, Ph.D., Molecular BioInsights
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
class VaersSlice5

################################################################################
DOSE_NAMES = ["All", "1", "2", "3", "4", "5", "6", "7+", "UNK", "N/A"]
DOSE_NAMES4 = ["All", "1", "2", "3", "4"]
DOSE_NAMES_ALL = ["All"]
GENDERS = ["M", "F"]
MAX_SHOTS = 25

################################################################################
def read_not_symptoms( filename )
  not_aes = {}

  in_file = InputFile.new( filename )
  in_file.open_file
  header = in_file.next_line
  while ( ! in_file.is_end_of_file? )
    line = in_file.next_line

    if ( ! line.nil? ) && ( line.length > 0 )
      tokens = line.chomp.split( "\t" )
      not_aes[ tokens[1] ] = true if ! tokens[2].nil? && (tokens[2].size > 0)
    end  # if
  end  # while
  in_file.close_file

  return not_aes
end  # read_not_symptoms

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
def read_symptoms( filename, select, not_aes, data )
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
      # if match || ! data[ vaers_id ].nil?
      data[ vaers_id ] = {} if data[ vaers_id ].nil?
      data[ vaers_id ][ :symptoms ] = {} if data[ vaers_id ][ :symptoms ].nil?
      data[ vaers_id ][ :other_symptoms ] = {} if data[ vaers_id ][ :other_symptoms ].nil?
      for i in (1..9).step(2) do
        if ! tokens[i].nil? && ! select[ tokens[i] ].nil?
          data[ vaers_id ][ :symptoms ][ tokens[i] ] = true 
        else
          data[ vaers_id ][ :other_symptoms ][ tokens[i] ] = true if ! tokens[i].nil? && tokens[i].size > 0 && not_aes[ tokens[i] ].nil?
        end  # if
      end # for
      # end  # if
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
        vax_lot   = tokens[3].upcase
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
        data[ vaers_id ][ :state ] = tokens[2].upcase 
        data[ vaers_id ][ :age ] = tokens[3]
        data[ vaers_id ][ :age ] = -1 if tokens[3].nil? || tokens[3].size < 1
        data[ vaers_id ][ :gender ] = tokens[ 6 ]
        # data[ vaers_id ][ :symptom_text ] = tokens[ 8 ]
        data[ vaers_id ][ :died ] = tokens[9]
        data[ vaers_id ][ :onset ] = tokens[20].to_i
        data[ vaers_id ][ :onset ] = -1 if tokens[20].size < 1
        # data[ vaers_id ][ :lab_data ] = tokens[ 21 ]
        # tokens[22] V_ADMINBY
        parts = tokens[18].split( "/" ) if tokens[18].size > 4    # VAX_DATE
        parts = tokens[1].split( "/" ) if parts.nil?    # RECVDATE
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
  dose_shots = {}
  yearly_shots = {}
  shots_gender = {}
  data.keys.each do |id|
    if ! data[id][:vax].nil?
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        vax_type = vax_record[:vax_type]
        vax_dose = vax_record[:vax_dose]
        vax_year = data[id][:year]
        gender = data[id][ :gender ]
        v_names[ vax_name ] = true
        shots[ vax_name ] = {} if shots[ vax_name ].nil?
        shots[ vax_name ][ id ] = true

        dose_shots[ vax_name ] = {} if dose_shots[ vax_name ].nil?
        dose_shots[ vax_name ][ vax_dose ] = {} if dose_shots[ vax_name ][ vax_dose ].nil?
        dose_shots[ vax_name ][ vax_dose ][ id ] = true

        dose_shots[ vax_name ][ "All" ] = {} if dose_shots[ vax_name ][ "All" ].nil?
        dose_shots[ vax_name ][ "All" ][ id ] = true

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
      total = 0
      total = dose_shots[ vax_name ][ dose_name ].keys.size if ! dose_shots[ vax_name ].nil? && ! dose_shots[ vax_name ][ dose_name ].nil?
      freq = 0.0
      freq = (count * 100000) / total if count > 0 && total > 0
      print "\t#{count}|#{total}|#{freq}"
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
  for year in (2026..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    print "\t#{tally[vax_name]['All'].keys.size}"
    for year in (2026..1990).step(-1) do
      count = 0
      count = tally[ vax_name ][ year ].keys.size if ! tally[ vax_name ][ year ].nil?
      print "\t#{count}"
    end  # for
    print "\n"
  end  # do

  # Yearly number of shots
  puts "\nYear shots report"
  print "Vaccine Name\tAll"
  for year in (2026..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    print "\t#{shots[vax_name].keys.size}"
    for year in (2026..1990).step(-1) do
      count = 0
      count = yearly_shots[ vax_name ][ year ].keys.size if ! yearly_shots[ vax_name ][ year ].nil?
      print "\t#{count}"
    end  # for
    print "\n"
  end  # do

  # Yearly symptoms frequency
  puts "\nYear frequency report per 100,000 vaccine shots"
  print "Vaccine Name\tAll"
  for year in (2026..1990).step(-1) do
    print "\t#{year}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    freq = 0.0
    freq = tally[vax_name]['All'].keys.size.to_f * 100000.0 / shots[vax_name].keys.size.to_f if ! shots[vax_name].nil? && shots[vax_name].keys.size > 0

    print "\t#{'%.1f' % freq}"
    for year in (2026..1990).step(-1) do
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
  combo_shots = {}
  combo_age = {}
  age_tally = {}
  vax_tally = {}
  shots_tally = {}
  age_total = {}

  other_ae_tally = {}
  other_x = {}
  ror_names = {}

  # Tally up the vaccine shots by concurrent count by vaccine.
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      age = data[id][:age].to_i
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        v_names[ vax_name ] = true
        vax_type = vax_record[:vax_type]
      end  # do
  
      # Tally all shot combinations
      combo_names = v_names.keys.sort.join( "+" )

      # Don't report "NO BRAND NAME" vaccines and combinations.
      if (combo_names.index( "NO BRAND NAME" ) == nil) && 
         (combo_names.index( "FOREIGN" ) == nil) &&
         (combo_names.index( "OTHER" ) == nil) &&
         (combo_names.index( "UNKNOWN" ) == nil)
        combo_shots[ combo_names ] = 0 if combo_shots[ combo_names ].nil?
        combo_shots[ combo_names ] += 1
      end  # if

      vax_shots = data[id][ :vax ].size
      shots_tally[ combo_names ] = {} if shots_tally[ combo_names ].nil?
      shots_tally[ combo_names ][ vax_shots ] = {} if shots_tally[ combo_names ][ vax_shots ].nil?
      shots_tally[ combo_names ][ vax_shots ][ id ] = true
  
      # Tally all shot combinations by age
      age_tally[ combo_names ] = {} if age_tally[ combo_names ].nil?
      age_tally[ combo_names ][age] = {} if age_tally[ combo_names ][age].nil?
      age_tally[ combo_names ][age][id] = true
      age_tally[ combo_names ][:all] = {} if age_tally[ combo_names ][:all].nil?
      age_tally[ combo_names ][:all][id] = true

      age_total[ age ] = 0 if age_total[ age ].nil?
      age_total[ age ] += 1
    end  # if
  end  # do

# Tally up the symptom by number of vaccine shots.
  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? 
        age = data[id][:age].to_i
        v_names = {}
        vax_type = "blank"
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_type = vax_record[:vax_type]
          v_names[ vax_name ] = true
        end  # do
        combo_names = v_names.keys.sort.join( "+" )

        if data[id][:symptoms][symptom]
          tally[ combo_names ] = {} if tally[ combo_names ].nil?
          tally[ combo_names ][ "All" ] = {} if tally[ combo_names ][ "All" ].nil?
          tally[ combo_names ][ "All" ][ id ] = true 
          vax_shots = data[id][ :vax ].size
          tally[ combo_names ][ vax_shots ] = {} if tally[ combo_names ][ vax_shots ].nil?
          tally[ combo_names ][ vax_shots ][ id ] = true
  
          vax_tally[ combo_names ] = 0 if vax_tally[ combo_names ].nil?
          vax_tally[ combo_names ] += 1
  
          combo_age[ combo_names ] = {} if combo_age[ combo_names ].nil?
          combo_age[ combo_names ][age] = {} if combo_age[ combo_names ][age].nil?
          combo_age[ combo_names ][age][ id ] = true
  
          combo_age[ combo_names ][:all] = {} if combo_age[ combo_names ][:all].nil?
          combo_age[ combo_names ][:all][ id ] = true

          # Tally all by age for solo administered vaccines
          if (data[id][:vax].size == 1) && (combo_names.index( "NO BRAND NAME" ) == nil)
            ror_names[ combo_names ] = true
            other_x[ age ] = {} if other_x[ age ].nil?
            other_x[ age ][ id ] = true
          end  # if
        end  # if
      end  # if
    end  # do
  end  # do

  # Tally up the other AE symptoms
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:other_symptoms].nil? && ! data[id][ :vax ].nil?
      age = data[id][:age].to_i
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        v_names[ vax_name ] = true
      end  # do
      combo_names = v_names.keys.sort.join( "+" )

      # Only tally for solo administered vaccines
      if (data[id][:vax].size == 1) && (combo_names.index( "NO BRAND NAME" ) == nil)
        other_ae_tally = {} if other_ae_tally.nil? 
        other_ae_tally[ combo_names ] = {} if other_ae_tally[ combo_names ].nil?
        other_ae_tally[ combo_names ][ age ] = 0 if other_ae_tally[ combo_names ][ age ].nil?
        other_ae_tally[ combo_names ][ age ] += data[id][:other_symptoms].keys.size
  
        other_ae_tally[:all] = {} if other_ae_tally[:all].nil? 
        other_ae_tally[:all][age] = 0 if other_ae_tally[:all][age].nil?
        other_ae_tally[:all][age] += data[id][:other_symptoms].keys.size
      end  # if
    end  # if
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

  combo_order = combo_shots.keys.sort

  # Print out the header.
  puts "\nVaccine combination shots report by age"
  print "Combination\tAll\tAll"
  for age in 0..100 do
    print "\tAge #{age}\tAge #{age}"
  end  # do
  print "\n"

  # Print out combination tallies by age
  combo_order.each do |c_name|
    tally_age = 0
    tally_age = age_tally[ c_name ][ :all].keys.size if ! age_tally[ c_name ].nil? && ! age_tally[ c_name ][ :all ].nil?
    age_combo = 0
    age_combo = combo_age[ c_name ][ :all ].keys.size if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ :all ].nil?
    freq = 0 
    freq = age_combo * 100000.0 / tally_age if tally_age > 0
    print "#{c_name}\t#{age_combo}|#{tally_age}|#{'%.1f' % freq}\t#{'%.1f' % freq}"

    age_combo = 0
    age_combo = combo_age[ c_name ][ 0 ].keys.size if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ 0 ].nil?
    for age in 0..100 do
      tally_age = 0
      tally_age = age_tally[ c_name ][ age ].keys.size if ! age_tally[ c_name ][ age ].nil?
      age_combo = 0
      age_combo = combo_age[ c_name ][ age ].keys.size if ! combo_age[ c_name ].nil? && ! combo_age[ c_name ][ age ].nil?
      freq = 0 
      freq = age_combo * 100000.0 / tally_age if tally_age > 0
      print "\t#{age_combo}|#{tally_age}|#{'%.1f' % freq}\t#{'%.1f' % freq}"
    end  # do
    print "\n"
  end  # do

  # Calculate ROR - Reporting Odds Ratio & PRR - Proportional reporting ratio
  puts "\nVaccine ROR and PRR report by age"
  print "Combination"
  for age in 0..100 do
    print "\tAge #{age}"
  end  # do
  print "\n"

  ror_order = ror_names.keys.sort
  ror_order.each do |s_name|
    print "#{s_name}"
    for age in 0..100 do
      a = 0
      a = combo_age[ s_name ][ age ].keys.size if ! combo_age[ s_name ].nil? && ! combo_age[ s_name ][ age ].nil?
      b = 0
      b = other_ae_tally[ s_name ][ age ] if ! other_ae_tally[ s_name ].nil? && ! other_ae_tally[ s_name ][ age ].nil?
      c = 0
      c = other_x[ age ].keys.size - a if ! other_x[ age ].nil?
      d = 0
      d = other_ae_tally[ :all ][ age ] - b if ! other_ae_tally[ :all ].nil? && ! other_ae_tally[ :all ][ age ].nil?
      ror = 0
      ror = (1.0 * a * d) / (1.0 * b * c) if (b * c) > 0
      prr_d = 0
      prr_d = (1.0 * c) / (c + d) if (c + d) > 0
      prr = 0
      prr = ((1.0 * a) / (a + b)) / prr_d if (a + b) > 0 && prr_d > 0.0
      # print"\t#{a}|#{b}|#{c}|#{d}\t#{ror}\t#{prr}"
      print"\t#{a}|#{b}|#{c}|#{d}"
    end  # for
    print "\n"
  end  # do

end  # shots_report

################################################################################
def shot_reports_by_type
  type_x = {}
  type_other = {}
  type_all = {}      # Other AEs by age
  other_seen = {}    # Count other AEs for each individual only once for coadministered vaccines

        if other_seen[id].nil? 
          # Track for only solo administered vaccines for ROR and PRR calculations 
          if data[id][:vax].size == 1
            ror_names[ vax_type ] = true
            type_other[ vax_type ] = {} if type_other[ vax_type ].nil? 
            type_other[ vax_type ][age] = 0 if type_other[ vax_type ][age].nil?
            type_other[ vax_type ][age] += data[id][:other_symptoms].keys.size if ! data[id][:other_symptoms].nil?

            type_all[:all] = {} if type_all[:all].nil? 
            type_all[:all][age] = 0 if type_all[:all][age].nil?
            type_all[:all][age] += data[id][:other_symptoms].keys.size if ! data[id][:other_symptoms].nil?
          end  # if
        end  # if

        other_seen[id] = true

        # Tracking for only solo administered vaccines for ROR and PRR
        if data[id][:vax].size == 1
          type_x[ vax_type ] = {} if type_x[ vax_type ].nil?
          type_x[ vax_type ][ age ] = {} if type_x[ vax_type ][ age ].nil?
          type_x[ vax_type ][ age ][ id ] = true
  
          type_x[ :all ] = {} if type_x[ :all ].nil?
          type_x[ :all ][ age ] = {} if type_x[ :all ][ age ].nil?
          type_x[ :all ][ age ][ id ] = true
        end  # if

  puts "\nVaccine ROR and PRR by age and vaccine type"
  print "Vaxcine type"
  for age in 0..100 do
    print "\tAge #{age}\tROR #{age}\tPRR #{age}"
  end  # do
  print "\n"

  type_order = type_names.keys.sort
  type_order.each do |t_name|
    print "#{t_name}"
    for age in 0..100 do
      a = 0
      a = type_x[ t_name ][ age ].keys.size if ! type_x[ t_name ].nil? && ! type_x[ t_name ][ age ].nil?
      b = 0
      b = type_other[ t_name ][ age ] if ! type_other[ t_name ].nil? && ! type_other[ t_name ][ age ].nil?
      c = 0
      c = type_x[:all][ age ].keys.size - a if ! type_x[:all][ age ].nil?
      d = 0
      d = type_all[ :all ][ age ] - b if ! type_all[ :all ].nil? && ! type_all[ :all ][ age ].nil?
      ror = 0
      ror = (1.0 * a * d) / (1.0 * b * c) if (b * c) > 0
      prr_d = 0
      prr_d = (1.0 * c) / (c + d) if (c + d) > 0
      prr = 0
      prr = ((1.0 * a) / (a + b)) / prr_d if (a + b) > 0 && prr_d > 0.0
      print"\t#{a}|#{b}|#{c}|#{d}\t#{ror}\t#{prr}"
    end  # for
    print "\n"
  end  # do

end  # shot_reports_by_type

################################################################################
def states_report( data, select )
  puts "\nVaccine states report"

  state_names = {}
  tally_states = {}
  vax_states = {}
  data.keys.each do |id|
    if ! data[id][:vax].nil?
      v_names = {}
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        # vax_type = vax_record[:vax_type]
        state = data[id][ :state ]
        state = "blank" if state.nil? || state.length < 1
        state_names[ state ] = state

        tally_states[ vax_name ] = {} if tally_states[ vax_name ].nil?
        tally_states[ vax_name ][ state ] = {} if tally_states[ vax_name ][ state ].nil?
        tally_states[ vax_name ][ state ][ id ] = true
      end  # do
    end  # if
  end  # do

# Tally up the symptom by state.
  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        state = data[id][ :state ]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          # vax_type = vax_record[:vax_type]
          vax_states[ vax_name ] = {} if vax_states[ vax_name ].nil?
          vax_states[ vax_name ][ state ] = {} if vax_states[ vax_name ][ state ].nil?
          vax_states[ vax_name ][ state ][ id ] = true
        end  # do
      end  # if
    end  # do
  end  # do

  names_states = state_names.keys.sort
  print "Vaccine name"
  names_states.each do |state|
    print "\t#{state}\t#{state}"
  end  # do
  print "\n"

  vax_names = vax_states.keys.sort
  vax_names.each do |vax_name|
    print "#{vax_name}"
    names_states.each do |state|
      total = 0
      total = tally_states[ vax_name ][ state ].keys.size if ! tally_states[ vax_name ].nil? && ! tally_states[ vax_name ][ state ].nil?
      count = 0
      count = vax_states[ vax_name ][ state ].keys.size if ! vax_states[ vax_name ].nil? && ! vax_states[ vax_name ][ state ].nil?
      freq = 0.0
      freq = (count * 100000) / total if total > 0
      print "\t#{count}|#{total}|#{freq}\t#{freq}"
    end  # do
    print "\n"
  end  # do

end  # states_report


################################################################################
def months_report_write( vax_names, dose_names, tally, vax_total )
  # Print out the header.
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  # Print out the month report table.
  for month in 1..24 do
    print "#{month}"
    vax_names.each do |vax_name, count|
      count = 0
      count = tally[ vax_name ][ month ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ month ].nil?
      total = 0
      total = vax_total[ vax_name ][ month ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ month ].nil?
      freq = 0.0
      freq = (count * 100000) / total if count > 0 && total > 0
      print "\t#{count}|#{total}|#{freq}"
    end  # do
    print "\n"
  end  # do
end  # months_report_write

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
def age_report_frequency_age_groups( vax_names, tally, vax_total )
  puts "\nAge report frequency normalized to 100,000 shots with symptoms by age group"

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
  age_groups = ["age_0-1", "age_2-6", "age_7-12", "age_13-17", "age_18-49", "age_50-64", "age_65+"]
  age_groups.each do |age_group|
    print "#{age_group}"
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      count = tally[ vax_name ][ "All" ][ age_group ].keys.size if ! tally[ vax_name ][ "All" ][ age_group ].nil?
      total = vax_total[ vax_name ][ age_group ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ age_group ].nil? 
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do

    # Calculate for males
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      count = tally[ vax_name ][ "All" ][ "M" ][ age_group ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ].nil? && ! tally[ vax_name ][ "All" ][ "M" ][ age_group ].nil?
      total = vax_total[ vax_name ][ "M" ][ age_group ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "M" ].nil? && ! vax_total[ vax_name ][ "M" ][ age_group ].nil? 
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
      
    # Calculate for females
    vax_names.each do |vax_name, count|
      freq = 0.0
      count = 0
      total = 0
      count += tally[ vax_name ][ "All" ][ "F" ][ age_group ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ "All" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ].nil? && ! tally[ vax_name ][ "All" ][ "F" ][ age_group ].nil?
      total += vax_total[ vax_name ][ "F" ][ age_group ].keys.size if ! vax_total[ vax_name ].nil? && ! vax_total[ vax_name ][ "F" ].nil? && ! vax_total[ vax_name ][ "F" ][ age_group ].nil? 
      freq = count.to_f * 100000.0 / total if total > 0
      print "\t#{count}|#{total}|#{'%.0f' % freq}"
    end  # do
    print "\n"
  end  # do
end  # age_report_frequency_age_groups

################################################################################
def age_report_frequency_years_span( vax_names, year_tally, year_vax_total, year_vax_tally, year_start, year_end, is_triple )
  puts "\nAge report frequency normalized to 100,000 shots with symptoms by age and year"

  vax_names = year_vax_tally[ year_start ].sort_by{ |vax_name, count| -count }

  # Print out the years header.
  vax_names.each do |vax_name, count|
    for target_year in year_start..year_end do
      print "\t#{target_year}"
    end  # do
  end  # do
  print "\n"

  # Print out the header.
  vax_names.each do |vax_name, count|
    for target_year in year_start..year_end do
      print "\t#{vax_name}"
    end  # do
  end  # do
  print "\n"

  # Print out the age report table with normalized frequencies.
  min_age = 0
  for max_age in (10..120).step(10) do
    print "#{min_age} to #{max_age}"
    vax_names.each do |vax_name, count|
      for target_year in year_start..year_end do
        freq = 0.0
        count = 0
        total = 0
        for age in min_age..max_age do
          count += year_tally[ target_year ][ vax_name ][ "All" ][ age ].keys.size if ! year_tally[ target_year ][ vax_name ].nil? && ! year_tally[ target_year ][ vax_name ][ "All" ][ age ].nil?
          total += year_vax_total[ target_year ][ vax_name ][ age ].keys.size if ! year_vax_total[ target_year ][ vax_name ].nil? && ! year_vax_total[ target_year ][ vax_name ][ age ].nil? 
        end  # for
        freq = count.to_f * 100000.0 / total if total > 0
        if is_triple.nil?
          print "\t#{'%.0f' % freq}"
        else
          print "\t#{count}|#{total}|#{'%.0f' % freq}"
        end  # if
      end  # do
    end  # do

    print "\n"
    min_age = max_age + 1
  end  # do
end  # age_report_frequency_years_span

################################################################################
def tally_data( id, vax_record, age, gender, tally )
  vax_name = vax_record[ :vax_name ]
  vax_dose = vax_record[ :vax_dose ]
  vax_type = vax_record[ :vax_type ]
  
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

  return tally
end  # tally_data

################################################################################
def sum_data( id, vax_name, age, gender, vax_total )
  # Tally by vaccine and age
  vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
  vax_total[ vax_name ][ age ] = {} if vax_total[ vax_name ][ age ].nil?
  vax_total[ vax_name ][ age ][ id ] = true

  # Tally by vaccine, age, and gender
  vax_total[ vax_name ][ gender ] = {} if vax_total[ vax_name ][ gender ].nil?
  vax_total[ vax_name ][ gender ][ age ] = {} if vax_total[ vax_name ][ gender ][ age ].nil?
  vax_total[ vax_name ][ gender ][ age ][ id ] = true

  return vax_total
end  # sum_data

################################################################################
def age_bin( age )
  return "age_0-1" if (age == 0) || (age == 1)
  return "age_2-6" if (age >= 2) && (age <= 6)
  return "age_7-12" if (age >= 7) && (age <= 12)
  return "age_13-17" if (age >= 13) && (age <= 17)
  return "age_18-49" if (age >= 18) && (age <= 49)
  return "age_50-64" if (age >= 50) && (age <= 64)
  return "age_65+" if (age >= 65)
  return nil
end  # age_bin

################################################################################
def age_report( data, select, year_start, year_end )
  # puts ">>> year_start #{year_start}, year_end: #{year_end}"

  tally = {}
  vax_tally = {}
  vax_total = {}
  year_tally = {}
  year_vax_total = {}
  year_vax_tally = {}
  for target_year in year_start..year_end do
    year_tally[ target_year ] = {}
    year_vax_total[ target_year ] = {}
    year_vax_tally[ target_year ] = {}
  end  # for

  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]
        vax_year = data[id][:year]
        if ! data[id][ :age ].nil?
          age = data[id][ :age ].to_i
          gender = data[id][ :gender ]

          # Tally by vaccine and age
          vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
          vax_total[ vax_name ][ age ] = {} if vax_total[ vax_name ][ age ].nil?
          vax_total[ vax_name ][ age ][ id ] = true
      
          # Tally by vaccine and age group 
          age_group = age_bin( age )
          if ! age_group.nil?
            vax_total[ vax_name ][ age_group ] = {} if vax_total[ vax_name ][ age_group ].nil?
            vax_total[ vax_name ][ age_group ][ id ] = true
          end  # if

          # Tally by vaccine, age, and gender
          vax_total[ vax_name ][ gender ] = {} if vax_total[ vax_name ][ gender ].nil?
          vax_total[ vax_name ][ gender ][ age ] = {} if vax_total[ vax_name ][ gender ][ age ].nil?
          vax_total[ vax_name ][ gender ][ age ][ id ] = true

          vax_total[ vax_name ][ gender ][ age_group ] = {} if vax_total[ vax_name ][ gender ][ age_group ].nil?
          vax_total[ vax_name ][ gender ][ age_group ][ id ] = true

          if ! vax_year.nil? && (vax_year >= year_start) && (vax_year <= year_end )
            # year_vax_total[ vax_year ] = sum_data( id, vax_name, age, gender, year_vax_total[ vax_year ] )
            # Tally by vaccine and age
            year_vax_total[ vax_year ][ vax_name ] = {} if year_vax_total[ vax_year ][ vax_name ].nil?
            year_vax_total[ vax_year ][ vax_name ][ age ] = {} if year_vax_total[ vax_year ][ vax_name ][ age ].nil?
            year_vax_total[ vax_year ][ vax_name ][ age ][ id ] = true
          
            # Tally by vaccine, age, and gender
            year_vax_total[ vax_year ][ vax_name ][ gender ] = {} if year_vax_total[ vax_year ][ vax_name ][ gender ].nil?
            year_vax_total[ vax_year ][ vax_name ][ gender ][ age ] = {} if year_vax_total[ vax_year ][ vax_name ][ gender ][ age ].nil?
            year_vax_total[ vax_year ][ vax_name ][ gender ][ age ][ id ] = true
          end  # if
        end  # if
      end  # do
    end  # if
  end  # do

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][:vax ].each do |vax_record|
          age = data[id][ :age ].to_i
          gender = data[id][ :gender ]
          vax_year = data[id][:year]
          age_group = age_bin( age )

          # Tally by vaccine
          vax_name = vax_record[ :vax_name ]
          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
          vax_dose = vax_record[ :vax_dose ]
          vax_type = vax_record[ :vax_type ]
          
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

          if ! age_group.nil?
            tally[ vax_name ][ "All" ][ age_group ] = {} if tally[ vax_name ][ "All" ][ age_group ].nil?
            tally[ vax_name ][ "All" ][ age_group ][ id ] = true

            tally[ vax_name ][ "All" ][ gender ][ age_group ] = {} if tally[ vax_name ][ "All" ][ gender ][ age_group ].nil?
            tally[ vax_name ][ "All" ][ gender ][ age_group ][ id ] = true
          end  # if

          # puts "vax_year: '#{vax_year}'"
          if ! vax_year.nil? && (vax_year >= year_start) && (vax_year <= year_end )
            # Tally by dose and age
            year_tally[ vax_year ][ vax_name ] = {} if year_tally[ vax_year ][ vax_name ].nil?
            year_tally[ vax_year ][ vax_name ][ vax_dose ] = {} if year_tally[ vax_year ][ vax_name ][ vax_dose ].nil?
            year_tally[ vax_year ][ vax_name ][ vax_dose ][ age ] = {} if year_tally[ vax_year ][ vax_name ][ vax_dose ][ age ].nil?
            year_tally[ vax_year ][ vax_name ][ vax_dose ][ age ][ id ] = true
            
            # Tally for all doses by age
            year_tally[ vax_year ][ vax_name ][ "All" ] = {} if year_tally[ vax_year ][ vax_name ][ "All" ].nil?
            year_tally[ vax_year ][ vax_name ][ "All" ][ age ] = {} if year_tally[ vax_year ][ vax_name ][ "All" ][ age ].nil?
            year_tally[ vax_year ][ vax_name ][ "All" ][ age ][ id ] = true
            
            # Tally by gender
            year_tally[ vax_year ][ vax_name ][ vax_dose ][ gender ] = {} if year_tally[ vax_year ][ vax_name ][ vax_dose ][ gender ].nil?
            year_tally[ vax_year ][ vax_name ][ vax_dose ][ gender ][ age ] = {} if year_tally[ vax_year ][ vax_name ][ vax_dose ][ gender ][ age ].nil?
            year_tally[ vax_year ][ vax_name ][ vax_dose ][ gender ][ age ][ id ] = true
            
            # Tally by gender
            year_tally[ vax_year ][ vax_name ][ "All" ][ gender ] = {} if year_tally[ vax_year ][ vax_name ][ "All" ][ gender ].nil?
            year_tally[ vax_year ][ vax_name ][ "All" ][ gender ][ age ] = {} if year_tally[ vax_year ][ vax_name ][ "All" ][ gender ][ age ].nil?
            year_tally[ vax_year ][ vax_name ][ "All" ][ gender ][ age ][ id ] = true

            year_vax_tally[ vax_year ][ vax_name ] = 0 if year_vax_tally[ vax_year ][ vax_name ].nil?
            year_vax_tally[ vax_year ][ vax_name ] += 1
            # puts "year_vax_tally: vax_year (#{vax_year}) vax_name #{vax_name} tally #{year_vax_tally[vax_year][vax_name]}"
          end  # if
        end  # do
      end  # if
    end  # do
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  puts "\nAge report summary"
  age_report_write( vax_names, DOSE_NAMES_ALL, tally )

  age_report_frequency( vax_names, tally, vax_total )
  age_report_frequency_years( vax_names, tally, vax_total )
  age_report_frequency_age_groups( vax_names, tally, vax_total )

  puts "\nAge report details"
  age_report_write( vax_names, DOSE_NAMES4, tally )

  # Summaries by year
  age_report_frequency_years_span( vax_names, year_tally, year_vax_total, year_vax_tally, year_start, year_end, 3 )

  # Summaries by year, frequency only
  age_report_frequency_years_span( vax_names, year_tally, year_vax_total, year_vax_tally, year_start, year_end, nil )
end  # age_report

################################################################################
def determine_month( age )
  age_f = age.to_f
  return 99 if age.nil? || age_f > 2.042
  upper = 0.0
  for month in 1..24 do
    lower = upper
    upper = (month*2.0+1.0)/24.0
    return month if (age_f < upper) && (age_f >= lower)
  end  # for
  return 99
end  # determine_month

################################################################################
def months_report( data, select )
  tally = {}
  vax_tally = {}
  vax_total = {}

  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil? 
      data[id][:vax ].each do |vax_record|
        vax_name = vax_record[ :vax_name ]
        vax_year = data[id][:year]
        if ! data[id][ :age ].nil?
          vaers_age = data[id][ :age ]
          age = determine_month( vaers_age )

          if ! age.nil? && (age < 99)
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
        end  # if
      end  # do
    end  # if
  end  # do

  select.keys.each do |symptom|
    data.keys.each do |id|
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][:vax ].each do |vax_record|
          vaers_age = data[id][ :age ]
          age = determine_month( vaers_age )
          gender = data[id][ :gender ]

          # Tally by vaccine
          vax_name = vax_record[ :vax_name ]
          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
          vax_type = vax_record[ :vax_type ]
          
          # Tally by age
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ age ] = {} if tally[ vax_name ][ age ].nil?
          tally[ vax_name ][ age ][ id ] = true
          
          # Tally by gender
          tally[ vax_name ][ gender ] = {} if tally[ vax_name ][ gender ].nil?
          tally[ vax_name ][ gender ][ age ] = {} if tally[ vax_name ][ gender ][ age ].nil?
          tally[ vax_name ][ gender ][ age ][ id ] = true
        end  # do
      end  # if
    end  # do
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  puts "\nAge in months report summary"
  months_report_write( vax_names, DOSE_NAMES_ALL, tally, vax_total )
end  # months_report

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
  counts = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][ :vax ].nil?
      data[id][ :vax ].each do |vax_record|
        vax_name = vax_record[:vax_name]
        vax_lot  = vax_record[:vax_lot]
        total[ vax_name ] = {} if total[ vax_name ].nil?
        total[ vax_name ][ vax_lot ] = {} if total[ vax_name ][ vax_lot ].nil?
        total[ vax_name ][ vax_lot ][ id ] = true
        counts[ vax_name ] = {} if counts[ vax_name ].nil?
        counts[ vax_name ][ vax_lot ] = 0 if counts[ vax_name ][ vax_lot ].nil?
        counts[ vax_name ][ vax_lot ] += 1
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
          tally[ vax_name ][ vax_lot ] = {} if tally[ vax_name ][ vax_lot ].nil?
          tally[ vax_name ][ vax_lot ][ id ] = true
        end  # do
      end  # if
    end  # do
  end  # do

  print "\nVaccine lot report\n"
  # Report by vaccine x lots
  tally.keys.sort.each do |vax_name|
    # Print the header for this vaccine.
    print "#{vax_name}"

    tally_this = counts[ vax_name ]
    lot_names = tally_this.sort_by{ |vax_lot, count| -count }

    lot_names.each do |vax_lot, count|
      shots = 0
      shots = total[ vax_name ][ vax_lot ].keys.size if ! total[ vax_name ].nil? && ! total[ vax_name ][ vax_lot ].nil?
      print "\t#{vax_lot}" if shots > 0
    end  # do
    print "\n"

    print "#{vax_name}"
    lot_names.each do |vax_lot, count|
      count = 0
      count = tally[ vax_name ][ vax_lot ].keys.size if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ vax_lot ].nil?
      shots = 0
      shots = total[ vax_name ][ vax_lot ].keys.size if ! total[ vax_name ].nil? && ! total[ vax_name ][ vax_lot ].nil?
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
  puts "\nSymptom\tVax name\tVax dose\tVax lot\tVax site\tVax Manuf\tGender\tOnset\tAge\tVaersID\tDied\tState\tOther AEs"

  select.keys.each do |symptom|
    data.keys.each do |id|
      other_aes = 0
      other_aes = data[id][:other_symptoms].size if ! data[id][:other_symptoms].nil?
      if ! data[id].nil? && ! data[id][:symptoms].nil? && ! data[id][ :vax ].nil? && data[id][:symptoms][symptom]
        data[id][ :vax ].each do |vax_record|
          vax_name = vax_record[:vax_name]
          vax_dose = vax_record[:vax_dose]
          vax_type = vax_record[:vax_type]
          vax_manu = vax_record[:vax_manu]
          vax_lot  = vax_record[:vax_lot]
          vax_site = vax_record[:vax_site]

          gender = data[id][ :gender ]
          age = data[id][:age]
          onset = data[id][ :onset ]
          died = data[id][ :died ]
          state = data[id][ :state ]
          # symptom_text = data[id][ :symptom_text ]
          # lab_data = data[id][ :lab_data ]

          # puts "#{symptom}\t#{vax_name}\t#{vax_type}\t#{vax_dose}\t#{vax_lot}\t#{vax_site}\t#{vax_manu}\t#{gender}\t#{onset}\t#{symptom}\t#{age}\t#{id}\t#{died}\t#{state}\t#{symptom_text}\t#{lab_data}"
          puts "#{symptom}\t#{vax_name}\t#{vax_dose}\t#{vax_lot}\t#{vax_site}\t#{vax_manu}\t#{gender}\t#{onset}\t#{age}\t#{id}\t#{died}\t#{state}\t#{other_aes}"
        end  # do
      end  # if
    end  # do
  end  # do
end  # data_report

################################################################################
def load_year( year, select, vaccines, not_aes, data )
  data = read_symptoms( "#{year}VAERSSYMPTOMS.csv", select, not_aes, data )
  data = read_vax( "#{year}VAERSVAX.csv", data, vaccines )
  data = read_data( "#{year}VAERSDATA.csv", data )
  return data
end  # load_year

################################################################################
def vaers_main( select_filename, data_select )
  data = {}
  vaccines = {}
  not_aes = read_not_symptoms( "Not_Symptoms.txt" )

  # Read in the selected VAERS symptoms.
  select = read_select( select_filename )
  report_select( select )

  # Read in the VAERS yearly datafiles.
  if (data_select == "us") || (data_select == "domestic")
    for year in 1990..2026 do
      data = load_year( year.to_s, select, vaccines, not_aes, data )
    end  # for
  end  # if

  if (data_select == "all") || (data_select == "foreign") || 
      (data_select == "fr") || (data_select == "nondomestic") || 
      (data_select == "non-domestic")
    data = load_year( "NonDomestic", select, vaccines, not_aes, data ) 
  end  # if
  not_aes = nil

  # Generate the data analysis reports.
  dose_report( data, select )
  shots_report( data, select )
  states_report( data, select )
  months_report( data, select )
  age_report( data, select, 2021, 2026 )
  onset_report( data, select )
  spider_report( data, select )
  correlation_report( data, select )
  symptoms_report( data, select )
  lot_report( data, select )
  data_report( data, select )
end  # vaers_main 

################################################################################

end  # class VaersSlice5

################################################################################
def main( select_filename, data_select )
  app = VaersSlice5.new
  app.vaers_main( select_filename, data_select )
end  # main

################################################################################

data_select = "domestic"
data_select = ARGV[1].downcase if ! ARGV[1].nil?
main( ARGV[0], data_select )
