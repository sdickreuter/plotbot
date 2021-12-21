/**
    Stepper.cpp
	Contains class for controlling a TMC2209 SilentStepStick

    @author Simon Dickreuter
*/

#include "Stepper.h"


Stepper::Stepper(int ENABLE,int MS1,int MS2,int SPREAD,int STEP,int DIR, bool flipped) {
	this->ENBL_pin = ENABLE;
	this->MS1_pin = MS1;
	this->MS2_pin = MS2;
	this->SPREAD_pin = SPREAD;
	this->STEP_pin = STEP;
	this->DIR_pin = DIR;
  this->flipped = flipped;

	pinMode(this->ENBL_pin, OUTPUT);
	pinMode(this->MS1_pin, OUTPUT);
	pinMode(this->MS2_pin, OUTPUT);
	pinMode(this->SPREAD_pin, OUTPUT);
	pinMode(this->STEP_pin, OUTPUT);
	pinMode(this->DIR_pin, OUTPUT);
 
	disableDriver();

	setMicrostepping(0);

	position = 0;
	dir = 1;
}

void Stepper::enableDriver(){
  digitalWriteFast(this->ENBL_pin, LOW);
}

void Stepper::disableDriver(){
  digitalWriteFast(this->ENBL_pin, HIGH);
}

void Stepper::setMicrostepping(int MODE){
 
  switch (MODE) {
    case 0:  					// 1/8  microstep stealthChop
      digitalWriteFast(this->MS1_pin, LOW);
      digitalWriteFast(this->MS2_pin, LOW);
      digitalWriteFast(this->SPREAD_pin, LOW);
      this->stepping_factor = 8;
      break;
    case 1:					// 1/32  microstep stealthChop
      digitalWriteFast(this->MS1_pin, HIGH);
      digitalWriteFast(this->MS2_pin, LOW);
      digitalWriteFast(this->SPREAD_pin, LOW);
      this->stepping_factor = 32;
      break;
    case 2:					// 1/64  microstep stealthChop
      digitalWriteFast(this->MS1_pin, HIGH);
      digitalWriteFast(this->MS2_pin, LOW);
      digitalWriteFast(this->SPREAD_pin, LOW);
      this->stepping_factor = 64;
      break;
  }
}

void Stepper::zero() {
  this->position = 0;
}


long Stepper::get_pos() {
	return position;
}

void Stepper::set_dir(bool dir) {
  if ((dir>0) xor this->flipped) {
    this->dir = 1;
    digitalWriteFast(this->DIR_pin, LOW);
  } else {
  	this->dir = -1;
    digitalWriteFast(this->DIR_pin, HIGH);
  }
}

void Stepper::step() {
	digitalWriteFast(this->STEP_pin, HIGH);
	delayMicroseconds(2);
	digitalWriteFast(this->STEP_pin, LOW);
	delayMicroseconds(2);
	if ((this->dir > 0) xor this->flipped) {
    this->position++;
  } else {
    this->position--;    
  }
}
