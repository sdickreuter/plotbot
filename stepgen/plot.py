import numpy as np
import matplotlib.pyplot as plt


DIR_A   = 0b00000001 # True for right, False for left
DIR_B   = 0b00000010 # True for right, False for left
STEP_A  = 0b00000100
STEP_B  = 0b00001000
PENUP   = 0b00010000
PENDOWN = 0b00100000
END     = 0b01000000
  

# def tri_peak(t, a, t0, width):
#   result = np.zeros(len(t))
#   for i in range(len(t)):
#     if (t[i] < (t0+width/2)) np.sum(np.abs(ddta))and (t[i] > (t0-width/2)):
#       if t[i] < t0:ts
#         result[i] = a*(2/(width))*(t[i]-t0)+a
#       elif t[i] > t0:
#         result[i] = -a*(2/(width))*(t[i]-t0)+a
#       elif t[i] == t0:
#         result[i] = a
#     else:
#       result[i] = 0.0
#   return result

# def tri_peak(t, a, t0, width):
#   result = np.zeros(len(t))
#   for i in range(len(t)):
#     if (t[i] < (t0+width/2)) and (t[i] > (t0-width/2)):
#       if t[i] < t0:
#         result[i] = a/((width/2)**2) * (t[i]-t0)**2 + 2*a/(width/2) * (t[i]-t0) + a
#       elif t[i] > t0:
#         result[i] = a/((width/2)**2) * (t[i]-t0)**2 - 2*a/(width/2) * (t[i]-t0) + a
#       elif t[i] == t0:
#         result[i] = a
#     else:
#       result[i] = 0.0
#   return result


# t = np.linspace(190000,210000)

# ddt = tri_peak(t,1000,200000,1e4)
# print(np.sum(ddt))


# plt.plot(t,ddt)
# plt.show()




filename = "Zeichnung.tmng"

dat = np.loadtxt(filename,delimiter=" ",skiprows=1)

t = dat.astype(int)
print("runtime: " + str(np.round(np.sum(t[:,0])/(60*1e6))) + " minutes")


dt = dat[:,0]
ac = np.array(dat[:,1], dtype = int)

t = []
t.append(0.0)
for i in range(len(dt)):
  t.append(t[-1] + np.abs(dt[i]))
t = np.array(t[1:], dtype=float)




# plt.plot(t[np.bitwise_and(ac,STEP_A)],dt[np.bitwise_and(ac,STEP_A)])
# plt.plot(t[np.bitwise_and(ac,STEP_B)],dt[np.bitwise_and(ac,STEP_B)])
# plt.show()

#plt.plot(t,dt)
#plt.show()

dta = dt[np.bitwise_and(ac,STEP_A)]
dtb = dt[np.bitwise_and(ac,STEP_B)]
ta = t[np.bitwise_and(ac,STEP_A)]
tb = t[np.bitwise_and(ac,STEP_B)]

distperstep = 1 #0.00375

xpos = 0
ypos = 0
x = []
y = []

x.append(xpos)
y.append(ypos)

idta = 0
idtb = 0

# for i in range(len(ac)):

#   if ac[i] & STEP_A:
#     if ac[i] & DIR_A:
#       xpos += distperstep
#     else:
#       xpos -= distperstep

#   if ac[i] & STEP_B:
#     if ac[i] & DIR_B:
#       ypos += distperstep
#     else:
#       ypos -= distperstep

#   if (ac[i] & STEP_A) or (ac[i] & STEP_B):
#     x.append(xpos)
#     y.append(ypos)


xs = []
ys = []
upind = 0
downind = 0
draw = False
for i in range(len(ac)):
  ax = None
  ay = None

  if (ac[i] & STEP_A) > 0:
    if (ac[i] & DIR_A) > 0:
      ax = distperstep
    else:
      ax = -distperstep

  if (ac[i] & STEP_B) > 0:
    if (ac[i] & DIR_B) > 0:
      ay = distperstep
    else:
      ay = -distperstep
  
  if ax is not None:
    x.append(x[-1] + ax)
  else:
    x.append(x[-1])
  if ay is not None:
    y.append(y[-1] + ay)
  else:
    y.append(y[-1])


  if (ac[i] & PENUP) > 0:
   upind = i
   xs.append(x[downind:])
   ys.append(y[downind:])
  elif (ac[i] & PENDOWN) > 0:
   downind = i

  # if (ac[i] & PENUP) > 0:
  #   draw = False
  # elif (ac[i] & PENDOWN) > 0:
  #   draw = True

  # if ax is not None or ay is not None:
  #   if draw:
  #     xs.append(x[-1])
  #     ys.append(y[-1])


print(len(xs))
for i in range(len(xs)):
 #print(min(xs[i]),max(xs[i]),min(ys[i]),max(ys[i]))
 print(len(xs[i]), len(ys[i]))

for i in range(len(xs)):
 plt.plot(xs[i],ys[i])
plt.show()

# plt.plot(xs,ys)
# plt.show()

# for i in range(len(ac)):
#   ax = 0.0
#   ay = 0.0
  
#   if (ac[i] & STEP_A) > 0:
#     if (ac[i] & DIR_A) > 0:
#       ax = distperstep
#     else:
#       ax = -distperstep

#   if (ac[i] & STEP_B) > 0:
#     if (ac[i] & DIR_B) > 0:
#       ay = distperstep
#     else:
#       ay = -distperstep
  
#   if (ax != 0.0) or (ay != 0.0):
#     x.append(x[-1] + ax)
#     y.append(y[-1] + ay)


# phi = np.repeat(np.linspace(0, 1.5*np.pi, 100),int(np.ceil(len(x)/100)))
# phi = phi[:len(x)]
# rgb_cycle = np.vstack((            # Three sinusoids
#     .5*(1.+np.cos(phi          )), # scaled to [0,1]
#     .5*(1.+np.cos(phi+2*np.pi/3)), # 120° phase shifted.
#     .5*(1.+np.cos(phi-2*np.pi/3)))).T # Shape = (60,3)

# print(rgb_cycle.shape)

# x = np.array(x)
# y = np.array(y)

# markers = ['D','s']*int(np.ceil(len(x)/2))

# fig, ax = plt.subplots()
# ax.scatter([x[0]],[[y[0]]],color="black", marker="x", s=500, alpha=1.0)
# ax.scatter([x[-1]],[[y[-1]]],color="red", marker="x", s=500, alpha=1.0)

# # for xp, yp, m, rgb in zip(x, y, markers, rgb_cycle):
# #     ax.scatter([xp],[yp],color=rgb, marker=m, s=500, alpha=0.5)


plt.plot(x,y)
plt.show()

