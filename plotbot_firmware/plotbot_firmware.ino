/**
    plotbot_firmware.ino
	Firmware for running the plotbot

    @author Simon Dickreuter
*/
#include "Stepper.h"
#include <Bounce2.h>
#include "TeensyTimerTool.h"
using namespace TeensyTimerTool;
#include <PacketSerial.h>
#include <PWMServo.h>
#include "defines.h"
 
#define CIRCULAR_BUFFER_INT_SAFE
#include "CircularBuffer.h"

// Buffer for holding step timings
// Teensy 3.2 has 64 kbytes of RAM
// sizeof(dtData) = 5 bytes
CircularBuffer<dtData, BUFFER_SIZE> timings;

PacketSerial_<COBS, 0, MAX_BUFFER_ELEMENTS*sizeof(dtData)> myPacketSerial;

PWMServo penservo;  // servo object to control up/down of the Pen

// Bounce objects for endswitches
Bounce topright_bounce = Bounce(); 
Bounce topleft_bounce = Bounce(); 
Bounce bottomleft_bounce = Bounce(); 
Bounce bottomright_bounce = Bounce(); 


//Stepper::Stepper(int ENABLE,int MS1,int MS2,int SPREAD,int STEP,int DIR)
Stepper stepper_bottom(TOP_ENABLE, TOP_MS1, TOP_MS2, TOP_SPRD, TOP_STEP, TOP_DIR,true);
Stepper stepper_top(BOTTOM_ENABLE, BOTTOM_MS1, BOTTOM_MS2, BOTTOM_SPRD, BOTTOM_STEP, BOTTOM_DIR,false);


// variable for storing object from buffer
dtData dtbuf;

//OneShotTimer timer(TCK);
OneShotTimer timer;

PeriodicTimer blinktimer;
volatile bool blinking = false;

void blink() {
    if (blinking) digitalWriteFast(13, !digitalReadFast(13));
}


// do a step but check state of endswitches first
void step_top() {
  if (stepper_top.dir < 0) {
    //topright_bounce.update();
    if (topright_bounce.read()==HIGH)  {
      stepper_top.step();
    }
  } else {
    //topleft_bounce.update();
    if (topleft_bounce.read()==HIGH)  {
      stepper_top.step();
    }
  }
}


// do a step but check state of endswitches first
void step_bottom() {
  if (stepper_bottom.dir > 0) {
    //bottomright_bounce.update();
    if (bottomright_bounce.read()==HIGH)  {
      stepper_bottom.step();
    }
  } else {
    //bottomleft_bounce.update();
    if (bottomleft_bounce.read()==HIGH)  {
      stepper_bottom.step();
    }
  }
}

void clear() {
  timings.clear();
}


void update() {
  if (!timings.isEmpty()) {

    blinking = true;

    dtbuf = timings.shift();   

    if (dtbuf.action & DIR_A) {
      stepper_top.set_dir(false);
    }
    else {
      stepper_top.set_dir(true); 
    }

    if (dtbuf.action & DIR_B) {
      stepper_bottom.set_dir(false);
    }
    else {
      stepper_bottom.set_dir(true); 
    }
    

    timer.trigger(dtbuf.dt);


    if (dtbuf.action & STEP_A) {
      //stepper_top.step(); // unsafe stepping
      step_top(); // save stepping, checks the endswitches
    }
    if (dtbuf.action & STEP_B) {
      //stepper_bottom.step(); // unsafe stepping
      step_bottom(); // save stepping, checks the endswitches
    }
    if (dtbuf.action & PENUP) {
      penservo.write(POS_UP);
    }
    if (dtbuf.action & PENDOWN) {
      penservo.write(POS_DOWN);
    }
    if (dtbuf.action & END) {
      clear();
    }

  } else {
    blinking = false;
    timer.trigger(1000);
  }
 
}


void setup() {
  pinMode(13, OUTPUT);

  penservo.attach(SERVO_PWM);
  penservo.write(50);

  pinMode(TOPRIGHT_SWITCH, INPUT);
  pinMode(TOPLEFT_SWITCH, INPUT);
  pinMode(BOTTOMLEFT_SWITCH, INPUT);
  pinMode(BOTTOMRIGHT_SWITCH, INPUT);

  topright_bounce.attach(TOPRIGHT_SWITCH);
  topleft_bounce.attach(TOPLEFT_SWITCH);
  bottomleft_bounce.attach(BOTTOMLEFT_SWITCH);
  bottomright_bounce.attach(BOTTOMRIGHT_SWITCH);

  topright_bounce.interval(1); // interval in ms
  topleft_bounce.interval(1); // interval in ms
  bottomleft_bounce.interval(1); // interval in ms
  bottomright_bounce.interval(1); // interval in ms
    
  // We begin communication with our PacketSerial object by setting the
  // communication speed in bits / second (baud).
  myPacketSerial.begin(115200);

  // If we want to receive packets, we must specify a packet handler function.
  // The packet handler is a custom function with a signature like the
  // onPacketReceived function below.
  myPacketSerial.setPacketHandler(&onPacketReceived);

  blinktimer.begin(blink, 50000);
  blinktimer.start();

  timer.begin(update);
  timer.trigger(1000);
}


void update_switches() {
  // update all bounce objects
  topright_bounce.update();
  topleft_bounce.update();
  bottomleft_bounce.update();
  bottomright_bounce.update();     
}


void _home_motors(bool reverse, int delay_mult) {
  // init variables that terminate the while loop
  bool top_finished;
  bool bottom_finished;
  bool finished;
  top_finished = false;
  bottom_finished = false;
  finished = false;

  stepper_top.enableDriver();
  stepper_bottom.enableDriver();

  if (!reverse) {
    // set both steppers so they move to the left
    stepper_top.set_dir(true);
    stepper_bottom.set_dir(true);    
  } else {
    // set both steppers so they move to the right
    stepper_top.set_dir(false);
    stepper_bottom.set_dir(false);       
  }

  while ((!finished)) {
    
    if (!top_finished) {
      stepper_top.step();
    }
    if (!bottom_finished) {
      stepper_bottom.step();
    }
    delayMicroseconds(delay_mult*DELAYMU);

    update_switches();

    if (topright_bounce.read()==LOW)  {
      top_finished = true;
    } 
    if (topleft_bounce.read()==LOW)  {
      top_finished = true;
    } 
    if (bottomleft_bounce.read()==LOW)  {
      bottom_finished = true;
    } 
    if (bottomright_bounce.read()==LOW)  {
      bottom_finished = true;
    }  
    if (bottom_finished) {
      if (top_finished) {
        finished = true;
      }
    }
  }

  if (!reverse) {
    // set both steppers so they move to the right
    stepper_top.set_dir(false);
    stepper_bottom.set_dir(false);
  } else {
    // set both steppers so they move to the left
    stepper_top.set_dir(true);
    stepper_bottom.set_dir(true);  
  }

  // make some steps away from the endswitches
  for (int i = 0; i<128; i++) {
    stepper_top.step();
    stepper_bottom.step();
    delayMicroseconds(delay_mult*DELAYMU);
  }

}

void home_motors(bool reverse) {
  _home_motors(reverse,1);
  for (int i = 0; i < 10; i++) {
    update_switches();
    delayMicroseconds(50);
  }
  _home_motors(reverse,15);
}


void jog(char axis, long steps) {
  
  // // set stepper direction
  // if (steps < 0.0) {
  //     if (axis == 'a') {
  //       stepper_top.set_dir(false);   
  //     } else {
  //       stepper_bottom.set_dir(false);   
  //     }
  //     steps *= -1;
  // } else {
  //     if (axis == 'a') {
  //       stepper_top.set_dir(true);   
  //     } else {
  //       stepper_bottom.set_dir(true);   
  //     }
  // }

  // // do steps
  // if (axis == 'a') {
  //   for (int i = 0; i<steps; i++) {
  //     update_switches();
  //     step_top();
  //     delayMicroseconds(DELAYMU);
  //   }
  // } else {
  //   for (int i = 0; i<steps; i++) {
  //     update_switches();
  //     step_bottom();
  //     delayMicroseconds(DELAYMU);
  //   }
  // }

  dtData buf;
  buf.dt = DELAYMU;
  for (int i = 0; i < abs(steps); i++) {
    if (axis == 'a') {
      buf.action =  STEP_A;
      if (steps < 0.0) {
        buf.action += DIR_A;
      }
    } else {
      buf.action =  STEP_B; 
      if (steps < 0.0) {
        buf.action += DIR_B;
      }
    }

    timings.push(buf);
  }  
  timer.trigger(100);
}


// Helper for converting float to bytes and vice versa
union union_float {
   byte b[4];
   float f;
};

// Helper for converting long to bytes and vice versa
union union_long {
   byte b[4];
   long l;
};

// Helper for converting unsigned long to bytes and vice versa
union union_ulong {
   byte b[4];
   unsigned long l;
};


//uint8_t transmitBuffer[512*4];
uint8_t transmitBuffer[128];

// This is the packetserial handler callback function.
// When an encoded packet is received and decoded, it will be delivered here.
// The `buffer` is a pointer to the decoded byte array. `size` is the number of
// bytes in the `buffer`.
void onPacketReceived(const uint8_t* buffer, size_t size)
{

  char command = *(buffer);

  // 'b' -> fill buffer with data
  if (command == 'b') {
    dtData data;
    long offset = 1;
    union_long size; 
    for (byte i=0; i<4; i++)     {
      size.b[i] = *(buffer+offset+i);
    }
    offset+=4;

    union_ulong dt;

    if ( size.l < 2000 ) {
      for (long c=0; c<size.l; c++) {
        for (byte i=0; i<4; i++) {
          dt.b[i] = *(buffer+offset+i);
        }
        data.dt = dt.l;
        data.action = *(buffer+offset+4);
        timings.push(data);
        offset += 5;
      }
      transmitBuffer[0] = 'o';
      transmitBuffer[1] = 'k';
      myPacketSerial.send(transmitBuffer, 2);
    }

  // 'j' -> jog motor
  } else if (command == 'j') {
    long offset = 1;
    char axis = *(buffer + offset);
    offset+=1;
    union_long steps; 
    for (byte i=0; i<4; i++)     {
      steps.b[i] = *(buffer+offset+i);
    }

    jog(axis,steps.l);

    transmitBuffer[0] = 'o';
    transmitBuffer[1] = 'k';
    myPacketSerial.send(transmitBuffer, 2);

  // 's' -> set pen-servo
  } else if (command == 's') {
    long offset = 1;
    byte pos = *(buffer + offset);
    penservo.write( (int) pos);

  // 'h' -> home motors
  } else if (command == 'h') {
    home_motors(false);
    transmitBuffer[0] = 'o';
    transmitBuffer[1] = 'k';
    myPacketSerial.send(transmitBuffer, 2);

  // 'r' -> home motors in reverse direction
  } else if (command == 'r') {
    home_motors(true);
    transmitBuffer[0] = 'o';
    transmitBuffer[1] = 'k';
    myPacketSerial.send(transmitBuffer, 2);

  // 'z' -> zero motor positions
  } else if (command == 'z') {
    stepper_top.zero();
    stepper_bottom.zero();

  // 'e' -> enable motors
  } else if (command == 'e') {
    stepper_top.enableDriver();
    stepper_bottom.enableDriver();

  // 'd' -> disable motors
  } else if (command == 'd') {
    stepper_top.disableDriver();
    stepper_bottom.disableDriver();

  // 'l' -> send buffer length
  } else if (command == 'l') {
    long size;
    size = (long) timings.size();
    transmitBuffer[0] = 'l';
    for (int i=0; i<4; i++) {
        transmitBuffer[i+1]=((size>>(i*8)) & 0xff);
    }
    myPacketSerial.send(transmitBuffer, 5);
  
  // 'm' -> start moving
  } else if (command == 'm') {
    /*if (!moving) {}
      timer.trigger(1000);
    }*/ 
  // 'c' -> clear buffers
  } else if (command == 'c') {
    clear();

  // 'p' -> send stepper positions
  } else if (command == 'p') {
    union_long pos;
    int offset = 0;
    transmitBuffer[offset] = 'p';
    offset+=1; 
    transmitBuffer[offset] = 'a';
    offset+=1;    
    pos.l = stepper_top.get_pos();
    transmitBuffer[offset+0] = pos.b[0];
    transmitBuffer[offset+1] = pos.b[1];
    transmitBuffer[offset+2] = pos.b[2];
    transmitBuffer[offset+3] = pos.b[3];
    offset += 4;
    
    transmitBuffer[offset] = 'b';
    offset+=1;    
    pos.l = stepper_bottom.get_pos();
    transmitBuffer[offset+0] = pos.b[0];
    transmitBuffer[offset+1] = pos.b[1];
    transmitBuffer[offset+2] = pos.b[2];
    transmitBuffer[offset+3] = pos.b[3];
    offset += 4;
    
    myPacketSerial.send(transmitBuffer, offset);

  // 'i' -> send infos
  } else if (command == 'i') {
    long max_buffer_size = (long) MAX_BUFFER_ELEMENTS*sizeof(dtData);
    transmitBuffer[0] = 'm';
    transmitBuffer[1] = 'a';
    transmitBuffer[2] = 'x';
    transmitBuffer[3] = 'b';
    transmitBuffer[4] = 'u';
    transmitBuffer[5] = 'f';
    long offset = 6;
    for (int i=0; i<4; i++) {
        transmitBuffer[i+offset]=((max_buffer_size>>(i*8)) & 0xff);
    }
    offset += 4;

    long max_steps = (long) MAX_STEPS;
    transmitBuffer[offset+0] = 'm';
    transmitBuffer[offset+1] = 'a';
    transmitBuffer[offset+2] = 'x';
    transmitBuffer[offset+3] = 's';
    transmitBuffer[offset+4] = 't';
    transmitBuffer[offset+5] = 'p';
    offset += 6;
    for (int i=0; i<4; i++) {
        transmitBuffer[i+offset]=((max_steps>>(i*8)) & 0xff);
    }
    offset += 4;

    myPacketSerial.send(transmitBuffer, offset);
  }
}


void loop() {
  
  update_switches();

  myPacketSerial.update();

}
