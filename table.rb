
################################################################################
# Author::      Darrell O. Ricke, Ph.D.  (mailto: d_ricke@yahoo.com)
# Copyright::   Copyright (C) 2022 Darrell O. Ricke, Ph.D.
# License::     GNU GPL license:  http://www.gnu.org/licenses/gpl.html
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

require 'input_file.rb'
         
################################################################################
# This object models a delimited table.
class Table

# data table
attr_accessor :data


###############################################################################
def initialize
  @data = {}
end  # method initialize


################################################################################
# This method loads a file into memory splitting the columns with specified delimiter.
def load_table( table_file, del )
  @data = {}
  in_file = InputFile.new( table_file )
  in_file.open_file
  while ( ! in_file.is_end_of_file? )
    line = in_file.next_line

    if ( ! line.nil? ) && ( line.length > 0 )
      tokens = line.chomp.split( del )
      @data[ tokens[ 0 ] ] = line.chomp
    end  # if
  end  # while
  in_file.close_file

  return @data
end  # load_table


################################################################################

end  # class Table



