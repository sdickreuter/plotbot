
// max number of elements that can be written to buffer at one time
#define MAX_BUFFER_ELEMENTS 500

// speed for homing
#define DELAYMU 300

// number of steps between endswitches
#define MAX_STEPS 45500

#define POS_UP 50 
#define POS_DOWN 0

// actions
#define  DIR_A   0b00000001 // True for right, False for left
#define  DIR_B   0b00000010 // True for right, False for left
#define  STEP_A  0b00000100
#define  STEP_B  0b00001000
#define  PENUP   0b00010000
#define  PENDOWN 0b00100000
#define  END     0b01000000


#define BUFFER_SIZE 5100

// Pinout for top stepper
#define TOP_ENABLE 19//13   // blau
#define TOP_MS1 14      // grün
#define TOP_MS2 15      // gelb
#define TOP_SPRD 16     // orange
#define TOP_STEP 17     // braun
#define TOP_DIR 18      // grau

// Pinout for bottom stepper
#define BOTTOM_ENABLE 2 // blau
#define BOTTOM_MS1 3    // grün
#define BOTTOM_MS2 4    // gelb
#define BOTTOM_SPRD 5   // orange
#define BOTTOM_STEP 6   // braun
#define BOTTOM_DIR 7    // grau

// Pinout for endswitches
#define TOPRIGHT_SWITCH 8
#define TOPLEFT_SWITCH 10
#define BOTTOMLEFT_SWITCH 11
#define BOTTOMRIGHT_SWITCH 12

// Pinout for servo
#define SERVO_PWM 9

// struct for storing step timings
struct dtData {
  unsigned long dt;
  char action;
};
