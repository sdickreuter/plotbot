import time
import sys
import glob
import serial
import struct
from cobs import cobs
import numpy as np
from scipy import signal


# from: https://stackoverflow.com/a/14224477
def serial_ports():
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            pass
    return result


# dtmin should not be smaller than 0.00005!
def generate_sine_movement(t, freq = 0.00008, phase = 0.0,dtmin = 0.0001, dtmax = 0.001):
    y = np.sin(2*np.pi*t*freq+phase)*dtmax
    dt = np.zeros(len(y))
    dt[y < 0] = y[y < 0] + dtmin + dtmax
    dt[y >= 0] = y[y >= 0] - dtmin - dtmax
    return dt

# dtmin should not be smaller than 0.00005!
def generate_triangle_movement(t, freq = 0.00008, phase = 0.0,dtmin = 0.0001, dtmax = 0.001):
    y = signal.sawtooth(2*np.pi*t*freq+phase,0.5)*dtmax
    dt = np.zeros(len(y))
    dt[y < 0] = y[y < 0] + dtmin + dtmax
    dt[y >= 0] = y[y >= 0] - dtmin - dtmax
    return dt



class PlotBot(object):

    def __init__(self, comport=None):
        if comport is None:
            serialports = serial_ports()
            #self.serial = serial.Serial(serialports[0], timeout=0.1)
            self.serial = serial.Serial(serialports[0], timeout=0.1)

        else:
            #self.serial = serial.Serial(comport, timeout=0.1)
            self.serial = serial.Serial(comport, timeout=0.1)

        time.sleep(1) # allow some time for the Arduino to completely reset


    def read(self):
        msg = self.serial.read_until(expected=b'\x00')
        try:
            return cobs.decode(msg[:-1])
        except:
            return b''


    def write(self, msg):
        msg = bytearray(cobs.encode(bytearray(msg)))
        msg.append(0x00)
        self.serial.write(msg)
        self.serial.flush()


    # wait for ok from microcontroller
    def read_ok(self):
        ok = False
        count = 0
        while not ok:
            msg = self.read()
            if len(msg) > 1:
                if msg == b'ok':
                    ok = True
            count += 1
            if count > 120: break
        return ok


    #enable motors
    def enable(self):
        self.write(b'e')

    #disable motors
    def disable(self):
        self.write(b'd')

    #clear buffers
    def clear(self):
        self.write(b'c')

    #start moving
    def start_moving(self):
        self.write(b'm')

    #zero motor positions
    def zero(self):
        self.write(b'z')


    def jog(self, axis, steps):
        reply = b''
        reply += b'j'
        reply += axis
        reply += bytes(struct.pack('<l',steps))
        self.write(reply)

        finished = self.read_ok()
        if finished:
            print("Jogging done.")
        else:
            print("Error while jogging")


    def set_servo(self, pos):
        reply = b''
        reply += b's'
        reply += bytes(struct.pack('B',pos))
        self.write(reply)

    def pen_down(self):
        reply = b''
        reply += b's'
        reply += bytes(struct.pack('B',0))
        self.write(reply)


    def pen_up(self):
        reply = b''
        reply += b's'
        reply += bytes(struct.pack('B',50))
        self.write(reply)


    def write_buffer(self, timings, actions):
        reply = b''
        reply += b'b'
        reply += bytes(struct.pack('<l',len(timings)))
        for i in range(len(timings)):
            reply += bytes(struct.pack("<L", timings[i]))
            reply += bytes(struct.pack("B", actions[i]))
        self.write(reply)

        finished = self.read_ok()
        if finished:
            pass
            #print("Wrote Buffer.")
        else:
            print("Error writing Buffer")



    def read_bufferlength(self):
        msg = b'l'
        self.write(msg)

        c = 0
        msg = b''
        while len(msg) < 1 and c < 50:
            msg = self.read()
            c += 1

        if len(msg) > 1:
            if msg[0] == ord("l"): 
                l = struct.unpack('<l',msg[1:5])[0]
                return l
        return None


    def read_positions(self):
        msg = b'p'
        self.write(msg)

        msg = b''
        while len(msg) < 1:
            msg = self.read()
            time.sleep(0.01)

        if len(msg) > 1:
            if msg[0] == ord("p"): 
                xpos = struct.unpack('<l',msg[2:6])[0]
                ypos = struct.unpack('<l',msg[7:11])[0]
                return xpos, ypos
        return None, None


    def home(self):
        # home motors
        self.write(b'h')
        homed = False
        while not homed:
            homed = self.read_ok()
        if homed:
            print("Steppers are homed.")
        else:
            print("Error while homing.")

    def home_reverse(self):
        # home motors
        self.write(b'r')
        homed = self.read_ok()
        if homed:
            print("Steppers are homed.")
        else:
            print("Error while homing.")



if __name__ == '__main__':
    #bot = PlotBot()
    #bot.home()
    pass