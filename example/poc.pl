# Desc:
#   Proof of concept to show grblshield movement and movement ack. Moves in
#   a square.
# Use:
#   Change the parameter of setupConn to select the serial device.
# TODO
#   Limit switches.
#   E-stop/disconnect awareness.
#   Homing sequence.
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

use Device::SerialPort;
use Time::HiRes qw/sleep/;

my ($port);

$port = setupConn("/dev/ttyACM0");
initialize($port);
commandLoop($port, square());
done($port);

# Desc: Open a basic serial port connection.
# Parameters:
#   $devFile - Filename of the serial port device.
# Return:
#   $port - Device::SerialPort object.
sub setupConn {
    my ($devFile) = @_;
    my ($port);

    $port =
           Device::SerialPort->new($devFile)
        || die("Unable to open $devFile: $!\n")
    ;

    $port->baudrate(9600);
    $port->databits(8);
    $port->parity("none");
    $port->stopbits(1);

    return($port);
}

# Desc: Pauses and then clears Grbl boot text buffer.
# Parameters:
#   $port - Device::SerialPort object.
# Return:
#   response($port) - Boot text.
# TODO
#   * Confirm that the boot text is what is expected.
#   * Allow grbl configuration, starting with acceleration settings.
sub initialize {
    my ($port) = @_;

    # Spend two seconds clearing the boot-up text.
    # This should be extended to actually check that the full boot text has
    # been received.
    sleep(2);

    print(response($port));
}

# Desc: Loops through and sends out a list of commands. Waits for movement to
#   stop before sending the next command.
# Parameters:
#   $port - Device::SerialPort object.
#   $commands - Reference to an array of gcode/grbl commands.
# Return: N/A
# TODO
#   Handle timeouts and errors from issueCommand and confirmStill.
#   Handle "unknown commands" from confirmCommand.
#   Add callback parameter for move complete.
#   Check for non-trailing newlines in a command. Split command if necessary.
sub commandLoop {
    my ($port, $commands) = @_;
    my ($goHome);

    $goHome = "G0 X0 Y0 Z0";
    print($goHome, "\n");
    issueCommand($port, $goHome);

    while (@$commands) {
        my ($command, $response);

        # Submit command.
        $command = shift(@$commands);
        print("$command\n");
        $response = issueCommand($port, $command);

        # Poll for ok/error.
        confirmCommand($port, $response);

        # Block until move is complete.
        confirmStill($port);
    }
}

# Desc: Shutdown function.
# Parameters:
#   $port - Device::SerialPort object.
# TODO
#   Output confirmation that shutdown has occurred.
sub done {
    my ($port) = @_;

    undef($port);
}

# Desc: Sends command.
# Parameters:
#   $port - Device::SerialPort object.
# Return:
#   $response - grbl response to command.
# TODO
#   * Handle errors from $port->write and response().
sub issueCommand {
    my ($port, $command) = @_;
    my ($response);

    # One and only one terminating newline.
    $command =~ s/\n*$/\n/;

    $port->write($command);
    $response = response($port);

    return($response);
}

# Desc: Check response for "ok".
# Parameters:
#   $port - Device::SerialPort object.
#   $response - grbl response to check.
# TODO
#   * Abstract print output.
#   * Return information for ok/unknown response.
sub confirmCommand {
    my ($port, $response) = @_;

    $response =~ s/\r//;

    if ($response eq "ok") {
        $response = "Unknown response: " . $response;
    }

    print("$response\n");
}

# Desc: Polls for position information to determine if movement has stopped.
# Parameters:
#   $port - Device::SerialPort object.
# TODO
#   * Handle errors from issueCommand.
#   * Abstract print output.
#   * Implement timeouts and error return code.
sub confirmStill {
    my ($port) = @_;
    my ($isStill, $firstResponse, $secondResponse);

    while (!$firstResponse || ($firstResponse ne $secondResponse)) {
        $firstResponse = issueCommand($port, "?\n");
        sleep(0.1);
        $secondResponse = issueCommand($port, "?\n");
        sleep(0.1);
    }

    print("Ceased movement.\n");
}

# Desc: Polls $port for a response.
# Parameters:
#   $port - Device::SerialPort object.
# Return:
#   $response - Output from $port.
# TODO
#   Implement timeouts.
sub response {
    my ($port) = @_;
    my ($count, $response);

    sleep(0.1);

    while (!$count) {
        sleep(0.05);
        ($count, $response) = $port->read(255);
    }

    return($response);
}

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
