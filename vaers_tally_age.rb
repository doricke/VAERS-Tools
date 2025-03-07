
require 'input_file.rb'
require 'table.rb'
require 'text_tools.rb'

################################################################################
class VaersTally

################################################################################
DOSE_NAMES = ["All", "1", "2", "3", "4", "5", "6", "7+", "UNK", "N/A"]
DOSE_NAMES4 = ["All", "1", "2", "3", "4"]
GENDERS = ["M", "F"]
MAX_SHOTS = 25

################################################################################
def read_symptoms( filename )
  delimiter = ","
  symptoms_table = Table.new
  table1 = symptoms_table.load_table( filename, delimiter )
  return table1
end  # read_symptoms
  
################################################################################
def scan_symptoms( filename, symptoms, data )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line  # skip header line
  while ( ! in_file.is_end_of_file? )
    line = in_file.next_line
    if ( ! line.nil? ) && ( line.length > 0 )
      tokens = TextTools::csv_split( line.chomp )
      vaers_id = tokens[0].to_i
      data[ vaers_id ] = {} if data[ vaers_id ].nil?
      data[ vaers_id ][ :symptoms ] = {} if data[ vaers_id ][ :symptoms ].nil?
      data[ vaers_id ][ :symptoms ][ tokens[1] ] = true if ! tokens[1].nil? && tokens[1].size > 0
      data[ vaers_id ][ :symptoms ][ tokens[3] ] = true if ! tokens[3].nil? && tokens[3].size > 0
      data[ vaers_id ][ :symptoms ][ tokens[5] ] = true if ! tokens[5].nil? && tokens[5].size > 0
      data[ vaers_id ][ :symptoms ][ tokens[7] ] = true if ! tokens[7].nil? && tokens[7].size > 0
      data[ vaers_id ][ :symptoms ][ tokens[9] ] = true if ! tokens[9].nil? && tokens[9].size > 0
    end  # if
  end  # while
  in_file.close_file

  return data 
end  # scan_symptoms

################################################################################
def scan_data( filename, data )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line  # skip header line
  while ( ! in_file.is_end_of_file? )
    line = in_file.next_line
    if ( ! line.nil? ) && ( line.length > 0 )
      tokens = TextTools::csv_split( line )
      vaers_id = tokens[0].to_i
      age = tokens[3].to_i
      age = -1 if tokens[3].size < 1
      died = tokens[9]
      onset = tokens[20]
      onset = -1 if tokens[20].size < 1
      data[vaers_id] = {} if data[vaers_id ].nil?
      sex = tokens[6]
      onset = tokens[20].to_i
      data[ vaers_id ][ :age ] = age
      data[ vaers_id ][ :died ] = died
      data[ vaers_id ][ :sex ] = sex
      data[ vaers_id ][ :onset ] = onset
      # puts "#{vaers_id}\tAge: #{age}\tSex: #{sex}\tOnset: #{onset}"
    end  # if
  end  # while
  in_file.close_file

  return data
end  # scan_data

################################################################################
def scan_vax( filename, data )
  in_file = InputFile.new( filename )
  in_file.open_file
  line = in_file.next_line  # skip header line
  while ( ! in_file.is_end_of_file? )
    line = in_file.next_line
    if ( ! line.nil? ) && ( line.length > 0 )
      tokens = TextTools::csv_split( line )
      vaers_id = tokens[0].to_i
      vax_type = tokens[1]
      vax_dose = tokens[4]
      vax_name = tokens[7]
      # vax_name = vax_type

      vax_rec = { :vax_name => vax_name, :vax_dose => vax_dose }
      data[ vaers_id ][ :vax ] = [] if data[ vaers_id ][ :vax ].nil?
      data[ vaers_id ][ :vax ].push( vax_rec )
    end  # if
  end  # while
  in_file.close_file

  return data
end  # scan_vax

################################################################################
def report_by_age( data )
  puts "\nReport by age"
  tally = {}
  vax_tally = {}
  vax_gender_age = {}
  vax_gender_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil?
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        age = data[id][:age].to_i
        sex = data[ id ][ :sex ]
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][ age ] = 0 if tally[ vax_name ][ age ].nil?
        tally[ vax_name ][ age ] += 1
        vax_gender_age[ vax_name ] = {} if vax_gender_age[ vax_name ].nil?
        vax_gender_age[ vax_name ][ sex ] = {} if vax_gender_age[ vax_name ][ sex ].nil?
        vax_gender_age[ vax_name ][ sex ][ age ] = 0 if vax_gender_age[ vax_name ][ sex ][ age ].nil?
        vax_gender_age[ vax_name ][ sex ][ age ] += 1
        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
        vax_gender_tally[ vax_name ] = {} if vax_gender_tally[ vax_name ].nil?
        vax_gender_tally[ vax_name ][ sex ] = 0 if vax_gender_tally[ vax_name ][ sex ].nil?
        vax_gender_tally[ vax_name ][ sex ] += 1
      end  # do
    end  # if
  end # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print out the header.
  print "Age"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\tFemale"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\tMale"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  # Print out the total counts.
  print "All"
  vax_names.each do |vax_name, count|
    print "\t#{count}"
  end  # do
  print "\tFemale"
  vax_names.each do |vax_name, x|
    count = 0
    count = vax_gender_tally[ vax_name ][ 'F' ] if ! vax_gender_tally[ vax_name ][ 'F' ].nil?
    print "\t#{count}"
  end  # do
  print "\tMale"
  vax_names.each do |vax_name, x|
    count = 0
    count = vax_gender_tally[ vax_name ][ 'M' ] if ! vax_gender_tally[ vax_name ][ 'M' ].nil?
    print "\t#{count}"
  end  # do
  print "\n"

  # Print out the age report table.
  for age in -1..120 do
    print "#{age}"
    vax_names.each do |vax_name, count|
      count = ""
      count = tally[ vax_name ][ age ] if ! tally[ vax_name ].nil? && ! tally[ vax_name ][ age ].nil?
      print "\t#{count}"
    end  # do
    print "\t#{age}"
    vax_names.each do |vax_name, count|
      count = ""
      count = vax_gender_age[ vax_name ][ 'F' ][ age ] if ! vax_gender_age[ vax_name ].nil? && ! vax_gender_age[ vax_name ][ 'F' ].nil? && ! vax_gender_age[ vax_name ][ 'F' ][ age ].nil?
      print "\t#{count}"
    end  # do
    print "\t#{age}"
    vax_names.each do |vax_name, count|
      count = ""
      count = vax_gender_age[ vax_name ][ 'M' ][ age ] if ! vax_gender_age[ vax_name ].nil? && ! vax_gender_age[ vax_name ][ 'M' ].nil? && ! vax_gender_age[ vax_name ][ 'M' ][ age ].nil?
      print "\t#{count}"
    end  # do
    print "\n"
  end  # do
end  # report_by_age

################################################################################
def report_by_dose( data, oldest )
  puts "\nReport by age: combinations"
  aes = {}
  sym_names = {}
  vax_tally = {}
  vax_count = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil?
      age = data[id][ :age ].to_i
      v_names = {}
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        v_names[ vax_name ] = true
      end  # do
      combo_name = v_names.keys.sort.join( "+" )
      i_nbn = combo_name.index( "NO BRAND NAME" )
      i_for = combo_name.index( "FOREIGN" )
      i_unk = combo_name.index( "UNKNOWN" )
      
      if i_nbn.nil? && i_for.nil? && i_unk.nil?
      
        if vax_tally[ combo_name ].nil?
          vax_tally[ combo_name ] = {} 
          vax_count[ combo_name ] = 0
          for yr in -1..120 do
            vax_tally[ combo_name ][ yr] = 0
          end  # for
        end  # if
        vax_tally[ combo_name ][ age ] = 0 if vax_tally[ combo_name ][ age ].nil? 
        vax_tally[ combo_name ][ age ] += 1 
        vax_count[ combo_name ] += 1 
      
        if ! data[id][:symptoms].nil?
          aes[ combo_name ] = {} if aes[ combo_name ].nil? && ! combo_name.nil?
          aes_list = data[id][:symptoms].keys 
          aes_list.each do |ae|
            if ! combo_name.nil? 
              # Tally the adverse events by symptom name
              if sym_names[ ae ].nil?
                sym_names[ ae ] = 1
              else
                sym_names[ ae ] += 1
              end  # if
  
              # Tally the adverse events by vaccine name 
              if aes[ combo_name ][ ae ].nil?
                aes[ combo_name ][ ae ] = {}
                aes[ combo_name ][ ae ][:all] = 1
                for yr in -1..120 do
                  aes[ combo_name ][ ae ][ yr ] = 0
                end  # for
                aes[ combo_name ][ ae ][ age ] = 1
              else
                aes[ combo_name ][ ae ][ age ] = 0 if aes[ combo_name ][ ae ][ age ].nil?
                aes[ combo_name ][ ae ][ age ] += 1
                aes[ combo_name ][ ae ][:all] += 1
              end  # if
            end  # if
          end  # do
        end  # if
      end  # if
    end  # if
  end # do
  
  vax_names = vax_tally.keys.sort

  puts "Adverse Events Summary"
  print "Symptom\tAge"
  vax_names.each do |vax_name, count|
    if vax_count[vax_name] >= 100
      print "\t#{vax_name}\t#{vax_name}" 
    end  # if
  end  #do
  print "\n"

  sym_order = sym_names.keys.sort
 
  sym_order.each do |symptom, all|
    print "#{symptom}\tAll"
    vax_names.each do |vax_name, v_count|
      if vax_count[vax_name] >= 100
        total = vax_count[vax_name]
        count = 0
        count = aes[vax_name][symptom][:all] if ! aes[vax_name][symptom].nil? 
        freq = 0
        freq = (count * 100000)/total if ! total.nil? && total > 0
        print "\t#{count}|#{total}|#{freq.to_i}\t#{freq.to_i}" 
      end  # if
    end  # do
    print "\n"
  end  #do

 
  puts "\nAdverse Events Matrix"
  print "Symptom\tAge"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}\t#{vax_name}" if vax_count[vax_name] >= 100
  end  #do
  print "\n"

  for yr in 0..oldest do
    sym_order.each do |symptom, all|
      print "#{symptom}\t#{yr}"
      vax_names.each do |vax_name, count|
        if vax_count[vax_name] >= 100
          count = aes[vax_name][symptom][ yr ] if ! aes[vax_name].nil? && ! aes[vax_name][symptom].nil? 
          count = 0 if count.nil?
          total = nil
          total = vax_tally[vax_name][ yr ] if ! vax_tally[vax_name].nil?
          freq = 0
          freq = (count * 100000)/total if ! total.nil? && total > 0
          print "\t#{count}|#{total}|#{freq.to_i}\t#{freq.to_i}"
        end  # if
      end  # do
      print "\n"
    end  # do
  end  # do

  # puts "\nAdverse Events Matrix Frequencies"
  # print "Symptom\tAge"
  # vax_names.each do |vax_name|
  #   print "\t#{vax_name}"
  # end  #do
  # print "\n"

  # for yr in 0..oldest do
  #   sym_order.each do |symptom|
  #     print "#{symptom}\t#{yr}"
  #     vax_names.each do |vax_name, count|
  #       count = aes[vax_name][symptom][ yr ] if ! aes[vax_name].nil? && ! aes[vax_name][symptom].nil? 
  #       count = 0 if count.nil?
  #       total = nil
  #       total = vax_tally[vax_name][yr] if ! vax_tally[vax_name].nil?
  #       freq = 0
  #       freq = (count * 100000)/total if ! total.nil? && total > 0
  #       print "\t#{freq.to_i}"
  #     end  # do
  #     print "\n"
  #   end  # do
  # end  # do
end  # report_by_dose

################################################################################
def report_by_onset( data, oldest )
  puts "\nReport by onset"
  tally = {}
  vax_tally = {}
  # vax_total = {}

  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil? && ! data[id][:symptoms].nil? # && ! data[id][:symptoms]["Vaccination failure"]
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        vax_dose = vax_rec[:vax_dose]
        age = data[id][ :age ].to_i
        onset = data[id][:onset].to_i
        onset = 999 if data[id][:onset].size == 0
        if age <= oldest && age >= 0
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][ age ] = {} if tally[ vax_name ][ age ].nil?
          tally[ vax_name ][age][:dose1] = {} if tally[vax_name][age][:dose1].nil?
          tally[ vax_name ][age][:dose2] = {} if tally[vax_name][age][:dose2].nil?
          tally[ vax_name ][age][:dose1][onset] = 0 if tally[vax_name][age][:dose1][onset].nil?
          tally[ vax_name ][age][:dose2][onset] = 0 if tally[vax_name][age][:dose2][onset].nil?
          tally[ vax_name ][age][:dose1][onset] += 1 if vax_dose == "1"
          tally[ vax_name ][age][:dose2][onset] += 1 if vax_dose == "2"
          tally[ vax_name ][age][:all] = {} if tally[ vax_name ][age][:all].nil?
          tally[ vax_name ][age][:all][onset] = 0 if tally[vax_name][age][:all][onset].nil?
          tally[ vax_name ][age][:all][onset] += 1
  
          # vax_total[ vax_name ] = {} if vax_total[ vax_name ].nil?
          # vax_total[ vax_name ][:dose1] = 0 if vax_total[ vax_name ][:dose1].nil?
          # vax_total[ vax_name ][:dose2] = 0 if vax_total[ vax_name ][:dose2].nil?
          # vax_total[ vax_name ][:dose1] += 1 if vax_dose == "1"
          # vax_total[ vax_name ][:dose2] += 1 if vax_dose == "2"
          # vax_total[ vax_name ][:all] = 0 if vax_total[ vax_name ][:all].nil?
          # vax_total[ vax_name ][:all] += 1
  
          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
  
          sex = data[id][:sex]
          tally[ vax_name ][age][:dose1][:male] = {}   if tally[ vax_name ][age][:dose1][:male].nil?
          tally[ vax_name ][age][:dose2][:male] = {}   if tally[ vax_name ][age][:dose2][:male].nil?
          tally[ vax_name ][age][:dose1][:female] = {} if tally[ vax_name ][age][:dose1][:female].nil?
          tally[ vax_name ][age][:dose2][:female] = {} if tally[ vax_name ][age][:dose2][:female].nil?
  
          # vax_total[ vax_name ][:dose1][:male] = 0   if vax_total[ vax_name ][:dose1][:male].nil?
          # vax_total[ vax_name ][:dose2][:male] = 0   if vax_total[ vax_name ][:dose2][:male].nil?
          # vax_total[ vax_name ][:dose1][:female] = 0 if vax_total[ vax_name ][:dose1][:female].nil?
          # vax_total[ vax_name ][:dose2][:female] = 0 if vax_total[ vax_name ][:dose2][:female].nil?
    
          tally[ vax_name ][age][:dose1][:male][onset] = 0   if tally[vax_name][age][:dose1][:male][onset].nil?
          tally[ vax_name ][age][:dose2][:male][onset] = 0   if tally[vax_name][age][:dose2][:male][onset].nil?
          tally[ vax_name ][age][:dose1][:female][onset] = 0 if tally[vax_name][age][:dose1][:female][onset].nil?
          tally[ vax_name ][age][:dose2][:female][onset] = 0 if tally[vax_name][age][:dose2][:female][onset].nil?
          if sex == "M"
            tally[ vax_name ][:dose1][:male][onset] += 1 if vax_dose == "1"
            tally[ vax_name ][:dose2][:male][onset] += 1 if vax_dose == "2"
            # vax_total[ vax_name ][:dose1][:male] += 1 if vax_dose == "1"
            # vax_total[ vax_name ][:dose2][:male] += 1 if vax_dose == "2"
          else
            if sex == "F"
              tally[ vax_name ][:dose1][:female][onset] += 1 if vax_dose == "1"
              tally[ vax_name ][:dose2][:female][onset] += 1 if vax_dose == "2"
              # vax_total[ vax_name ][:dose1][:female] += 1 if vax_dose == "1"
              # vax_total[ vax_name ][:dose2][:female] += 1 if vax_dose == "2"
            end  # if
          end  # if
        end  # if
      end  # do
    end  # if 
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  vax_names.each do |vax_name, count|
    print "Vaccine\tAge\tOnset\tTotal\tDose1 all\tDose2 all\tDose1 male\tDose2 male\tDose1 female\tDose2 female\t"
  end  # do
  print "\n"

  for age in 0..oldest do
    for onset in -1..120 do
      vax_names.each do |vax_name, count|
        total = tally[vax_name][age][:all][onset]
        print "#{vax_name}\t#{age}\t#{onset}\t#{total}\t#{tally[vax_name][:dose1][onset]}\t#{tally[vax_name][:dose2][onset]}\t"
        male1 = tally[vax_name][age][:dose1][:male][onset]
        male2 = tally[vax_name][age][:dose2][:male][onset]
        female1 = tally[vax_name][age][:dose1][:female][onset]
        female2 = tally[vax_name][age][:dose2][:female][onset]
        print "#{male1}\t#{male2}\t#{female1}\t#{female2}\t"
      end  # do
      print "\n"
    end  # for
  end  # for
end  # report_by_onset

################################################################################
def report_by_onset_all( data, oldest )
  puts "\nReport by onset"
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil? && ! data[id][:symptoms].nil? # && ! data[id][:symptoms]["Vaccination failure"]
      data[id][:vax].each do |vax_rec|
        age = data[id][ :age ].to_i
        vax_name = vax_rec[:vax_name]
        onset = data[id][:onset].to_i
        onset = 999 if data[id][:onset].size == 0
        if age <= oldest && age >= 0
          tally[ vax_name ] = {} if tally[ vax_name ].nil?
          tally[ vax_name ][age] = {} if tally[ vax_name ][ age ].nil?
          tally[ vax_name ][age][:all] = {} if tally[ vax_name ][age][:all].nil?
          tally[ vax_name ][age][:all][onset] = 0 if tally[vax_name][age][:all][onset].nil?
          tally[ vax_name ][age][:all][onset] += 1

          tally[ vax_name ][age][:total] = 0 if tally[vax_name][age][:total].nil?
          tally[ vax_name ][age][:total] += 1

          vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
          vax_tally[ vax_name ] += 1
        end  # if
      end  # do
    end  # if 
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  print "Onset\tAge"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  for age in 0..oldest do
    for onset in -1..120 do
      print "#{onset}\t#{age}"
      vax_names.each do |vax_name, vax_count|
        count = 0
        count = tally[vax_name][age][:all][onset] if ! tally[vax_name].nil? && ! tally[vax_name][age].nil? && ! tally[vax_name][age][:all].nil? && ! tally[vax_name][age][:all][onset].nil?
        total = 0
        total = tally[vax_name][age][:total] if ! tally[vax_name].nil? && ! tally[vax_name][age].nil? && ! tally[vax_name][age][:total].nil?
        freq = 0
        freq = (count * 100000)/total if ! total.nil? && total > 0
        print "\t#{count}|#{total}|#{freq}"
      end  # do
      print "\n"
    end  # for
  end  # for
end  # report_by_onset_all

################################################################################
def report_by_combo_age( data, oldest )
  puts "\nReport by onset"
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil? && ! data[id][:symptoms].nil? # && ! data[id][:symptoms]["Vaccination failure"]
      age = data[id][ :age ].to_i
      if age <= oldest && age >= 0
        v_names = {}
        data[id][:vax].each do |vax_rec|
          vax_name = vax_rec[:vax_name]
          v_names[ vax_name ] = true
        end  # do

        # Tally all shot combinations
        combo_names = v_names.keys.sort.join( "+" )
        tally[ combo_names ] = {} if tally[ combo_names ].nil?
        tally[ combo_names ][age] = 0 if tally[ combo_names ].nil?
        tally[ combo_names ][age] += 1

        # Tally by symptoms
        vax_tally[ combo_names ] = 0 if vax_tally[ combo_names ].nil?
        vax_tally[ combo_names ] += 1
      end  # if
    end  # if 
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  print "Onset\tAge"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  for age in 0..oldest do
    for onset in -1..120 do
      print "#{onset}\t#{age}"
      vax_names.each do |vax_name, vax_count|
        count = 0
        count = tally[vax_name][age][:all][onset] if ! tally[vax_name].nil? && ! tally[vax_name][age].nil? && ! tally[vax_name][age][:all].nil? && ! tally[vax_name][age][:all][onset].nil?
        total = 0
        total = tally[vax_name][age][:total] if ! tally[vax_name].nil? && ! tally[vax_name][age].nil? && ! tally[vax_name][age][:total].nil?
        freq = 0
        freq = (count * 100000)/total if ! total.nil? && total > 0
        print "\t#{count}|#{total}|#{freq}"
      end  # do
      print "\n"
    end  # for
  end  # for
end  # report_by_combo_age

################################################################################
def report_by_shots( data )
  puts "\nReport by shots"
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil?
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        vax_shots = data[id][ :vax ].size
        age = data[id][ :age ].to_i
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][ vax_shots ] = {} if tally[ vax_name ][ vax_shots ].nil?
        tally[ vax_name ][ vax_shots ][ id ] = true
        tally[ vax_name ][ :all ] = {} if tally[ vax_name ][ :all ].nil?
        tally[ vax_name ][ :all ][ id ] = true

        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
      end  # do
    end  # if
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  print "Shots\tAll"
  for shots in 1..MAX_SHOTS do
    print "\t#{shots}"
  end  # for
  print "\n"

  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    total = 0
    total = tally[ vax_name ][ :all ].keys.size if ! tally[ vax_name ][ :all ].nil?
    print "\t#{total}"
    for shots in 1..MAX_SHOTS do
      if tally[ vax_name ][ shots ].nil?
        print "\t"
      else
        print "\t#{tally[vax_name][shots].keys.size}"
      end  # if
    end  # for
    print "\n"
  end  # do
end  # report_by_shots

################################################################################
def filter_symptoms( data )
  # Remove symptoms if patient has a vaccination failure 
  vaers_ids = data.keys
  vaers_ids.each do |vaers_id|
    # puts "#{vaers_id} has Vax failure" if data[ vaers_id ][ :symptoms][ "Vaccination failure" ] 
    if ! data[ vaers_id ].nil? && ! data[ vaers_id ][ :symptoms ].nil?
      data[ vaers_id ] = nil if ! data[ vaers_id ].nil? && data[ vaers_id ][ :symptoms][ "Vaccination failure" ] == true
    end  # if
  end  # do
  return data
end  # filter_symptoms

################################################################################
def load_year( year, symptoms, data )
  data = scan_symptoms( "#{year}VAERSSYMPTOMS.csv", symptoms, data )
  data = scan_data( "#{year}VAERSDATA.csv", data )
  data = scan_vax( "#{year}VAERSVAX.csv", data )
  return data 
end  # load_year

################################################################################

end  # class

################################################################################
def vaers_main()
  data = {}
  app = VaersTally.new
  symptoms = {}

  # Read in the VAERS yearly datafiles.
  for year in 1990..2024 do
    data = app.load_year( year.to_s, symptoms, data )
  end  # for
  data = app.load_year( "NonDomestic", symptoms, data )

  app.report_by_dose( data, 6 )
  # app.report_by_onset_all( data, 1 )
  # app.report_by_age( data )
  # app.report_by_shots( data )
end  # vaers_main

################################################################################
vaers_main()
