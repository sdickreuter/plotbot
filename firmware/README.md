# plotbot_firmware

Firmware for plotbot plotting robot. See [plotbot on hackaday.io](https://hackaday.io/project/4220-plotbot) 
for Informations on the Hardware.

The goal of this firmware is to program as little C as possible while still getting a funktional plotter.
In contrast to most firmwares that steer the movement of stepper motors, this one does not use gcode.
Instead a buffer is filled from a pc with timing data that tells the microntroller when to make the steps.

This firmware uses [PacketSerial](https://github.com/bakercp/PacketSerial) for serial communication, [PITimer](https://github.com/loglow/PITimer) for getting the timing of the steps right and [CircularBuffer](https://github.com/rlogiacco/CircularBuffer) for storing the timings. 
Many thanks to the people who made this libraries, they are awesome!

This firmware is tested on a [Teensy](https://www.pjrc.com/teensy/) 3.1, but it will probably run on others too, 
provided the PITimer library is working.

## Contents
### plotbot_firmware.ino
Main file, where the magic happens.
### Stepper.cpp & Stepper.h
Class for wrapping the basic stepper motor driver control stuff
### plotbot_commander.py
Small gui written in python that offer basic control of the microcontroller and the steppers
### plotbot_utils.py
All the basic control stuff, has a class for controlling the bot in it
