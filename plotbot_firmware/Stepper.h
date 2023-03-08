/**
    Stepper.h
	Contains class for controlling a A4983 stepper driver

    @author sei
*/

#ifndef Stepper_h
#define Stepper_h

#include <Arduino.h>

class Stepper {
  public:
	Stepper(int ENABLE,int MS1,int MS2,int SPREAD,int STEP,int DIR, bool flipped);

	void setMicrostepping(int MODE);

	void enableDriver();
	void disableDriver(); 

	void set_dir(bool dir);
	  
	void step();
	
	long get_pos();

	void zero();

	int dir;

	int stepping_factor;

  private:
  	bool flipped;
    int ENBL_pin;
    int MS1_pin;
    int MS2_pin;
    int SPREAD_pin;
    int STEP_pin;
    int DIR_pin;
	long position;
};


#endif
