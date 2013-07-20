#!/usr/bin/perl

# Desc:
#   Gcode-based scanner.
# Use:
#   ????
# TODO
#   PoC with GrblCommander.pm
#   Actual application..
#
# License
#   This file is part of Perl Scanner.
#
#   Perl Scanner is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Perl Scanner is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with Perl Scanner.  If not, see <http://www.gnu.org/licenses/>.
#!/usr/bin/perl

use warnings;
use strict;

use GrblCommander;

my ($shapeOko);

$shapeOko = new GrblCommander("/dev/ttyACM0");
$shapeOko->initialize();
$shapeOko->commandLoop(square());

# Desc: A simple square move with some z-height.
# Return:
#   Sample square move.
sub square {
    return ([
          "G1 X0 Y05 Z5 F5000"
        , "G1 X05 Y05 Z10 F5000"
        , "G1 X05 Y0 Z5 F5000"
        , "G1 X0 Y0 Z0 F5000"
    ]);
}
