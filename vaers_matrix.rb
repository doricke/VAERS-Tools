
require 'input_file.rb'
require 'output_file.rb'
require 'table.rb'
require 'text_tools.rb'

################################################################################
class VaersMatrix

################################################################################
DOSE_NAMES = ["All", "1", "2", "3", "4", "5", "6", "7+", "UNK", "N/A"]
DOSE_NAMES4 = ["All", "1", "2", "3", "4"]
GENDERS = ["M", "F"]

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
      age = tokens[3]
      died = tokens[9]
      onset = tokens[20]
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
      # vax_name = tokens[7]
      vax_name = vax_type
      if ( ! data[ vaers_id ].nil? ) 
        vax_rec = { :vax_name => vax_name, :vax_dose => vax_dose }
        data[ vaers_id ][ :vax ] = [] if data[ vaers_id ][ :vax ].nil?
        data[ vaers_id ][ :vax ].push( vax_rec )
      end  # if
    end  # if
  end  # while
  in_file.close_file

  return data
end  # scan_vax

################################################################################
def scan_vax2( filename, data )
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
      # vax_name = tokens[7]
      vax_name = vax_type

      vax_rec = { :vax_name => vax_name, :vax_dose => vax_dose }
      data[ vaers_id ][ :vax ] = [] if data[ vaers_id ][ :vax ].nil?
      data[ vaers_id ][ :vax ].push( vax_rec )
    end  # if
  end  # while
  in_file.close_file

  return data
end  # scan_vax2

################################################################################
def report_by_dose( data )
  puts "\nReport by dose"
  # Tally up the doses by vaccine manufacturer and by dose
  tally = {}
  aes = {}
  sym_names = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil?
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        vax_dose = vax_rec[:vax_dose]
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][ vax_dose ] = 0 if tally[ vax_name ][ vax_dose ].nil?
        tally[ vax_name ][ vax_dose ] += 1
        tally[ vax_name ][ "All" ] = 0 if tally[ vax_name ][ "All" ].nil?
        tally[ vax_name ][ "All" ] += 1
        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
    
        if ! data[id][:symptoms].nil?
          aes[ vax_name ] = {} if aes[ vax_name ].nil? && ! vax_name.nil?
          aes_list = data[id][:symptoms].keys 
          aes_list.each do |ae|
            if ! vax_name.nil?
              # Tally the adverse events by symptom name
              if sym_names[ ae ].nil?
                sym_names[ ae ] = 1
              else
                sym_names[ ae ] += 1
              end  # if

              # Tally the adverse events by vaccine name 
              if aes[ vax_name ][ ae ].nil?
                aes[ vax_name ][ ae ] = 1
              else
                aes[ vax_name ][ ae ] += 1
              end  # if
            end  # if
          end  # do
        end  # if
      end  # do
    end  # if
  end # do
  
  # Print table header.
  print "Vaccine Name"
  DOSE_NAMES.each do |dose_name|
    print "\t#{dose_name}"
  end  # do
  print "\n"
 
  vax_names = vax_tally.sort_by{ |vax_name, count| -count }
 
  # Print table contents
  vax_names.each do |vax_name, count|
    print "#{vax_name}"
    DOSE_NAMES.each do |dose_name|
      print "\t#{tally[vax_name][dose_name]}"
    end  # do
    print "\n"
  end  # do

  puts "\nAdverse Events Matrix"
  print "Symptom"
  # aes.keys.each do |vax_name|
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  #do
  print "\n"

  sym_order = sym_names.sort_by{ |symptom, count| -count }

  # sym_names.keys.sort.each do |symptom|
  sym_order.each do |symptom, all|
    print "#{symptom}"
    # aes.keys.each do |vax_name|
    vax_names.each do |vax_name, count|
      print "\t#{aes[vax_name][symptom]}"
    end  # do
    print "\n"
  end  # do
end  # report_by_dose

################################################################################
def report_by_onset( data )
  puts "\nReport by onset"
  tally = {}
  vax_tally = {}

  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil? && ! data[id][:symptoms].nil? # && ! data[id][:symptoms]["Vaccination failure"]
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        vax_dose = vax_rec[:vax_dose]
        onset = data[id][:onset].to_i
        onset = 999 if data[id][:onset].size == 0
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][:dose1] = {} if tally[ vax_name ][:dose1].nil?
        tally[ vax_name ][:dose2] = {} if tally[ vax_name ][:dose2].nil?
        tally[ vax_name ][:dose1][onset] = 0 if tally[vax_name][:dose1][onset].nil?
        tally[ vax_name ][:dose2][onset] = 0 if tally[vax_name][:dose2][onset].nil?
        tally[ vax_name ][:dose1][onset] += 1 if vax_dose == "1"
        tally[ vax_name ][:dose2][onset] += 1 if vax_dose == "2"
        tally[ vax_name ][:all] = {} if tally[ vax_name ][:all].nil?
        tally[ vax_name ][:all][onset] = 0 if tally[vax_name][:all][onset].nil?
        tally[ vax_name ][:all][onset] += 1

        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1

        sex = data[id][:sex]
        tally[ vax_name ][:dose1][:male] = {}   if tally[ vax_name ][:dose1][:male].nil?
        tally[ vax_name ][:dose2][:male] = {}   if tally[ vax_name ][:dose2][:male].nil?
        tally[ vax_name ][:dose1][:female] = {} if tally[ vax_name ][:dose1][:female].nil?
        tally[ vax_name ][:dose2][:female] = {} if tally[ vax_name ][:dose2][:female].nil?
  
        tally[ vax_name ][:dose1][:male][onset] = 0   if tally[vax_name][:dose1][:male][onset].nil?
        tally[ vax_name ][:dose2][:male][onset] = 0   if tally[vax_name][:dose2][:male][onset].nil?
        tally[ vax_name ][:dose1][:female][onset] = 0 if tally[vax_name][:dose1][:female][onset].nil?
        tally[ vax_name ][:dose2][:female][onset] = 0 if tally[vax_name][:dose2][:female][onset].nil?
        if sex == "M"
          tally[ vax_name ][:dose1][:male][onset] += 1 if vax_dose == "1"
          tally[ vax_name ][:dose2][:male][onset] += 1 if vax_dose == "2"
        else
          if sex == "F"
            tally[ vax_name ][:dose1][:female][onset] += 1 if vax_dose == "1"
            tally[ vax_name ][:dose2][:female][onset] += 1 if vax_dose == "2"
          end  # if
        end  # if
      end  # do
    end  # if 
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  vax_names.each do |vax_name, count|
    print "Vaccine\tOnset\tTotal\tDose1 all\tDose2 all\tDose1 male\tDose2 male\tDose1 female\tDose2 female\t"
  end  # do
  print "\n"

  for onset in 0..120 do
    vax_names.each do |vax_name, count|
      total = tally[vax_name][:all][onset]
      print "#{vax_name}\t#{onset}\t#{total}\t#{tally[vax_name][:dose1][onset]}\t#{tally[vax_name][:dose2][onset]}\t"
      male1 = tally[vax_name][:dose1][:male][onset]
      male2 = tally[vax_name][:dose2][:male][onset]
      female1 = tally[vax_name][:dose1][:female][onset]
      female2 = tally[vax_name][:dose2][:female][onset]
      print "#{male1}\t#{male2}\t#{female1}\t#{female2}\t"
    end  # do
    print "\n"
  end  # for
end  # report_by_onset

################################################################################
def report_by_onset_all( data )
  puts "\nReport by onset"
  tally = {}
  vax_tally = {}
  data.keys.each do |id|
    if ! data[id].nil? && ! data[id][:vax].nil? && ! data[id][:symptoms].nil? # && ! data[id][:symptoms]["Vaccination failure"]
      data[id][:vax].each do |vax_rec|
        vax_name = vax_rec[:vax_name]
        onset = data[id][:onset].to_i
        onset = 999 if data[id][:onset].size == 0
        tally[ vax_name ] = {} if tally[ vax_name ].nil?
        tally[ vax_name ][:all] = {} if tally[ vax_name ][:all].nil?
        tally[ vax_name ][:all][onset] = 0 if tally[vax_name][:all][onset].nil?
        tally[ vax_name ][:all][onset] += 1

        vax_tally[ vax_name ] = 0 if vax_tally[ vax_name ].nil?
        vax_tally[ vax_name ] += 1
      end  # do
    end  # if 
  end  # do

  vax_names = vax_tally.sort_by{ |vax_name, count| -count }

  # Print table contents by increasing onset.
  print "Onset"
  vax_names.each do |vax_name, count|
    print "\t#{vax_name}"
  end  # do
  print "\n"

  for onset in 0..120 do
    print "#{onset}"
    vax_names.each do |vax_name, count|
      total = 0
      total = tally[vax_name][:all][onset] if ! tally[vax_name].nil? && ! tally[vax_name][:all].nil? && ! tally[vax_name][:all][onset].nil?
      print "\t#{total}"
    end  # do
    print "\n"
  end  # for
end  # report_by_onset_all

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
  data = scan_vax2( "#{year}VAERSVAX.csv", data )
  return data 
end  # load_year

################################################################################

end  # class

################################################################################
def vaers_main()
  data = {}
  app = VaersMatrix.new
  symptoms = {}

  data = app.load_year( "1990", symptoms, data )
  data = app.load_year( "1991", symptoms, data )
  data = app.load_year( "1992", symptoms, data )
  data = app.load_year( "1993", symptoms, data )
  data = app.load_year( "1994", symptoms, data )
  data = app.load_year( "1995", symptoms, data )
  data = app.load_year( "1996", symptoms, data )
  data = app.load_year( "1997", symptoms, data )
  data = app.load_year( "1998", symptoms, data )
  data = app.load_year( "1999", symptoms, data )
  data = app.load_year( "2000", symptoms, data )
  data = app.load_year( "2001", symptoms, data )
  data = app.load_year( "2002", symptoms, data )
  data = app.load_year( "2003", symptoms, data )
  data = app.load_year( "2004", symptoms, data )
  data = app.load_year( "2005", symptoms, data )
  data = app.load_year( "2006", symptoms, data )
  data = app.load_year( "2007", symptoms, data )
  data = app.load_year( "2008", symptoms, data )
  data = app.load_year( "2009", symptoms, data )
  data = app.load_year( "2010", symptoms, data )
  data = app.load_year( "2011", symptoms, data )
  data = app.load_year( "2012", symptoms, data )
  data = app.load_year( "2013", symptoms, data )
  data = app.load_year( "2014", symptoms, data )
  data = app.load_year( "2015", symptoms, data )
  data = app.load_year( "2016", symptoms, data )
  data = app.load_year( "2017", symptoms, data )
  data = app.load_year( "2018", symptoms, data )
  data = app.load_year( "2019", symptoms, data )
  data = app.load_year( "2020", symptoms, data )
  data = app.load_year( "2021", symptoms, data )
  data = app.load_year( "2022", symptoms, data )
  data = app.load_year( "2023", symptoms, data )
  data = app.load_year( "NonDomestic", symptoms, data )
  # data = app.filter_symptoms( data )
  app.report_by_dose( data )
  app.report_by_onset_all( data )
end  # vaers_main

################################################################################
vaers_main()