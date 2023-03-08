import glm
import math
import sequtils
import matplotnim
import path
import curve
import parsesvg
import coordtransform
import strutils
import std/algorithm
import std/strformat
import cubicroot
import numutils
import os

let precision: float = 1e-6


type
  Intersection* = object
    value*: float
    t*: float
    vind: int

proc newIntersection*(): Intersection =
  result.value = 0.0
  result.t = 0.0
  result.vind = 0

proc newIntersection*(val, t: float, vind: int): Intersection =
  result.value = val
  result.t = t
  result.vind = vind

proc cmp(x, y: Intersection): int =
  if x.t > y.t:
    result = 1
  elif x.t < y.t:
    result = -1

proc `$`*(a: Intersection): string =
  #result = "( " & $a.value & ", " & $a.t & ", " & $a.vind & " )"
  result = "( " & fmt"{a.value:>3.3}" & " " & fmt"{a.t:>3.3}" & " )"



let
  DIR_A* = 0b00000001'i8 # True for right, False for left
  DIR_B* = 0b00000010'i8 # True for right, False for left
  STEP_A* = 0b00000100'i8
  STEP_B* = 0b00001000'i8
  PENUP* = 0b00010000'i8
  PENDOWN* = 0b00100000'i8
  END* = 0b01000000'i8



proc calc_actions_from_intersections(xinter, yinter: var seq[Intersection]): (
    seq[int], seq[float]) =
  var
    inter = newSeq[Intersection]()
    a = newSeq[int]()
    t = newSeq[float]()
    a_buf = 0
    index = 1

  # calc differences in the values of the intersections, first element stays the same
  for i in countdown(len(xinter)-1, 1):
    xinter[i].value = sign(xinter[i].value-xinter[i-1].value)
  for i in countdown(len(yinter)-1, 1):
    yinter[i].value = sign(yinter[i].value-yinter[i-1].value)

  # disable first value from xinter and yinter, else it will be scrambled during merge
  if len(xinter) > 0:
    xinter[0].value = 0
    xinter[0].t = -1
  if len(yinter) > 0:
    yinter[0].value = 0
    yinter[0].t = -1

  # merge x and y intersections by comparing their t-values
  inter.merge(xinter, yinter, cmp)

  while (index < len(inter)):
    a_buf = 0
    # if two steps on different axes (different vind) are happening directly after each other they can be merged into one action
    if (index < (len(inter)-1)) and (inter[index].vind != inter[index+1].vind):

      # check if first step is on vind == 0 and is really a step
      if inter[index].vind == 0 and inter[index].value != 0.0:
        abuf += STEP_A
        # check direction
        if inter[index].value > 0:
          abuf += DIR_A
      # check if first step is on vind == 1 and is really a step
      elif inter[index].vind == 1 and inter[index].value != 0.0:
        abuf += STEP_B
        # check direction
        if inter[index].value > 0:
          abuf += DIR_B

      # check if second step is on vind == 0 and is really a step
      if inter[index+1].vind == 0 and inter[index+1].value != 0.0:
        abuf += STEP_A
        # check direction
        if inter[index+1].value > 0:
          abuf += DIR_A
      # check if second step is on vind == 1 and is really a step
      elif inter[index+1].vind == 1 and inter[index+1].value != 0.0:
        abuf += STEP_B
        # check direction
        if inter[index+1].value > 0:
          abuf += DIR_B

      if abuf > 0:
        a &= abuf
        t.add(inter[index+1].t)
      # skip the two steps that where just merged
      index += 2

    # two steps on the same axis cannot be combined
    elif index < (len(inter)):
      if inter[index].vind == 0 and inter[index].value != 0.0:
        abuf += STEP_A
        if inter[index].value > 0:
          abuf += DIR_A
      elif inter[index].vind == 1 and inter[index].value != 0.0:
        abuf += STEP_B
        if inter[index].value > 0:
          abuf += DIR_B

      if abuf > 0:
        a &= abuf
        t.add(inter[index].t)
      # goto next step
      index += 1

  result = (a, t)


# intersect curve with a regular grid of horizontal (vind=1) or vertical (vind=0) lines spaced
# by delta.
proc calc_grid_intersections(c: Curve, delta: float, vind: int): seq[Intersection] =
  var
    val = 0.0
    res: seq[float]
    A, B, C, D: float
    maxval: float
    sorted_ind: seq[int]
    count = 0
    start, stop: float

  result = @[]

  start = c.startpoint()[vind]
  start = round(start/delta)*delta
  stop = c.endpoint()[vind]
  stop = round(stop/delta)*delta

  c.b0[vind] = start
  c.b3[vind] = stop

  if c.kind == ckBezier:

    # calculate coefficients that don't change
    A = -1.0 * c.b0[vind] + 3.0*c.b1[vind] - 3.0 * c.b2[vind] + c.b3[vind]
    B = 3.0*c.b0[vind]-6.0*c.b1[vind]+3.0*c.b2[vind]
    C = -3.0*c.b0[vind]+3.0*c.b1[vind]

    # calculate starting and ending values, based on bounding polygon of the bezier
    val = min(@[c.b0[vind], c.b1[vind], c.b2[vind], c.b3[vind]])-10*delta
    val = round(val/delta)*delta - 2*delta
    maxval = max(@[c.b0[vind], c.b1[vind], c.b2[vind], c.b3[vind]])+10*delta
    maxval = round(maxval/delta)*delta + 2*delta

    # iterate over the grid from smallest mininum val to maxval
    while true:
      # re-calculate coefficient D
      D = c.b0[vind] - val
      # get intersections
      res = calc_root(A, B, C, D)
      for t in res:
        # check for valid solutions
        if t >= (0.0-precision) and t <= (1.0+precision):
          result.add(newIntersection(val, t, vind))

      val += delta
      count += 1
      if val > maxval:
        break
  else:
    echo("stepgen.nim, calc_grid_intersections(c: Curve, delta: float, vind: int): Can't intersect lines with grid, please convert to bezier!")

  # sort solution so that t is ascending (calc_root can give multiple solution for one val)
  result.sort(cmp)

  # add start or end point if not yet in result
  #if len(result) > 1:
  # if len(result) > 0:

  #   while (abs(stop - result[^1].value) >= delta) or (abs(result[0].value -
  #       start) >= delta):
  #     if abs(stop - result[^1].value) >= delta*(1-precision):
  #       result.add(newIntersection(stop, 1.0, vind))

  #     if abs(result[0].value - start) >= delta*(1-precision):
  #       result = newIntersection(start, 0.0, vind) & result


proc calc_actions*(p: Path, delta: float): (seq[int], seq[float]) =
  var
    xinter, yinter = newSeq[Intersection]()
    actions, abuf: seq[int]
    t, tbuf: seq[float]

  for i in 0..<len(p.c):
    xinter = calc_grid_intersections(p.c[i], delta, 0)
    yinter = calc_grid_intersections(p.c[i], delta, 1)

    (abuf, tbuf) = calc_actions_from_intersections(xinter, yinter)
    actions &= abuf
    t &= tbuf

  assert len(actions) == len(t)

  result = (actions, t)


# both paths must only contain cubic bezier curves!
proc connect_path_to_path*(p1, p2: Path): Path =
  var
    c: Curve
    l: float

  #result = newPath()
  #c = newCubicBezier()
  #c.b0 = p1.endpoint()
  #c.b3 = p2.startpoint()
  #l = length(c.b0 - c.b3)
  #c.b1 = c.b0 + (c.b3-c.b0).normalize()*(l/3)
  #c.b2 = c.b1 - (c.b3-c.b0).normalize()*(l/3)
  #result.add(c)

  result = newPath()
  c = newLine()
  c.a = p1.endpoint()
  c.b = p2.startpoint()
  result.add(c)
  result.convert_all_to_beziers()


# path must only contain cubic bezier curves!
proc connect_point_to_path*(a: Vec2[float], p: Path): Path =
  var
    c: Curve
    l: float

  #result = newPath()
  #c = newCubicBezier()
  #c.b0 = a
  #c.b3 = p.c[0].b0
  #l = length(c.b0 - c.b3)
  #c.b1 = c.b0 + (a-c.b3).normalize()*(l/2)
  #c.b2 = c.b1
  #result.add(c)
  result = newPath()
  c = newLine()
  c.a = a
  c.b = p.startpoint()
  result.add(c)
  result.convert_all_to_beziers()

# path must only contain cubic bezier curves!
proc connect_path_to_point*(p: Path, a: Vec2[float]): Path =
  var
    c: Curve
    l: float

  #result = newPath()
  #c = newCubicBezier()
  #c.b0 = p.c[^1].b3
  #c.b3 = a
  #l = length(c.b0 - c.b3)
  #c.b1 = c.b0 + (c.b0-c.b3).normalize()*(l/2)
  #c.b2 = c.b1
  #result.add(c)
  result = newPath()
  c = newLine()
  c.a = p.endpoint()
  c.b = a
  result.add(c)
  result.convert_all_to_beziers()

proc connect_point_to_point*(start, stop: Vec2[float]): Path =
  var
    c: Curve
    l: float

  result = newPath()
  c = newLine()
  c.a = start
  c.b = stop
  result.add(c)
  result.convert_all_to_beziers()
  #result = newPath()
  #c = newCubicBezier()
  #c.b0 = start
  #c.b3 = stop
  #l = length(c.b0 - c.b3)
  #c.b1 = c.b0 + (c.b0-c.b3).normalize()*(l/2)
  #c.b2 = c.b3 - (c.b0-c.b3).normalize()*(l/3)
  #c.b2 = c.b1
  #result.add(c)


#--------------------------------------------------------------------------------
if isMainModule:

  var
    b: Curve
    xvals, yvals = newSeq[float]()
    xinter, yinter, inter: seq[Intersection]
    delta = 0.33

  b = newCubicBezier()
  b.b0 = vec2(1.0, 5.0)
  b.b1 = vec2(2.0, 7.0)
  b.b2 = vec2(3.0, 4.0)
  b.b3 = vec2(4.0, 5.0)

  # calculate grid intersections
  xinter = calc_grid_intersections(b, delta, 0)
  yinter = calc_grid_intersections(b, delta, 1)

  echo("xinter ", xinter)
  echo("yinter ", yinter)

  echo("------ difference -----")

  # calc differences in the values of the intersections, first element stays the same
  for i in countdown(len(xinter)-1, 1):
    xinter[i].value = sign(xinter[i].value-xinter[i-1].value)
  for i in countdown(len(yinter)-1, 1):
    yinter[i].value = sign(yinter[i].value-yinter[i-1].value)

  echo("xinter ", xinter)
  echo("yinter ", yinter)

  echo("------ combine -----")

  # merge x and y intersections by comparing their t-values
  inter = @[]
  inter.merge(xinter, yinter, cmp)

  echo("combined inter ", inter)

  var
    a = newSeq[int]()
    a_buf = 0
    index = 1


  while index < len(inter):
    a_buf = 0
    # if two steps on different axes (different vind) are happening directly after each other they can be merged into one action
    if inter[index].vind != inter[index-1].vind:

      # check if first step is on vind == 0 and is really a step
      if inter[index].vind == 0 and inter[index].value != 0.0:
        abuf += STEP_A
        # check direction
        if inter[index].value > 0:
          abuf += DIR_A
      # check if first step is on vind == 1 and is really a step
      elif inter[index].vind == 1 and inter[index].value != 0.0:
        abuf += STEP_B
        # check direction
        if inter[index].value > 0:
          abuf += DIR_B

      # check if second step is on vind == 0 and is really a step
      if inter[index-1].vind == 0 and inter[index-1].value != 0.0:
        abuf += STEP_A
        # check direction
        if inter[index-1].value > 0:
          abuf += DIR_A
      # check if second step is on vind == 1 and is really a step
      if inter[index-1].vind == 1 and inter[index-1].value != 0.0:
        abuf += STEP_B
        # check direction
        if inter[index-1].value > 0:
          abuf += DIR_B
      a &= abuf

      # skip the two steps that where just merged
      index += 2

    # two steps on the same axis cannot be combined
    else:

      if inter[index].vind == 0 and inter[index].value != 0.0:
        abuf += STEP_A
        if inter[index].value > 0:
          abuf += DIR_A
      if inter[index].vind == 1 and inter[index].value != 0.0:
        abuf += STEP_B
        if inter[index].value > 0:
          abuf += DIR_B
      a &= abuf

      # goto next step
      index += 1


  echo(a)


  echo("------- check ----------")

  var
    startx = round(b.b0[0]/delta)*delta
    starty = round(b.b0[1]/delta)*delta
    endx = round(b.b3[0]/delta)*delta
    endy = round(b.b3[1]/delta)*delta

  echo("start      ", b.calc_point_t(0.0))
  echo("start grid ", startx, " ", starty)

  echo("end        ", b.calc_point_t(1.0))
  echo("end grid   ", endx, " ", endy)


  var
    x, y: seq[float]
    ax, ay: float

  x &= startx
  y &= starty

  for i in 0..<len(a):
    ax = 0.0
    ay = 0.0

    if (a[i] and int(STEP_A)) > 0:
      if (a[i] and int(DIR_A)) > 0:
        ax = delta
      else:
        ax = -delta

    if (a[i] and int(STEP_B)) > 0:
      if (a[i] and int(DIR_B)) > 0:
        ay = delta
      else:
        ay = -delta

    if ax != 0.0 or ay != 0.0:
      x &= x[^1] + ax
      y &= y[^1] + ay

  echo("x ", x)
  echo("y ", y)







# very slow, only for debugging use
# proc plot_paths(paths: seq[Path]) =
#   var
#     x = newSeq[float]()
#     y = newSeq[float]()
#     xpos: float
#     ypos: float
#     t: float
#     idtx, idty: int
#     ty = newSeq[float]()
#     tx = newSeq[float]()
#     ydir = newSeq[float]()
#     xdir = newSeq[float]()

#   let
#     distperstep = 0.00375

#   let figure = newFigure(python = "python")

#   for p in paths:
#     (tx, xdir) = calc_dt(p, distperstep, 0)
#     (ty, ydir) = calc_dt(p, distperstep, 1)

#     tx.apply(proc(x: float): float = x * 50000)
#     ty.apply(proc(x: float): float = x * 50000)

#     xpos = p.calc_point(0.0)[0]
#     ypos = p.calc_point(0.0)[1]
#     x = newSeq[float]()
#     y = newSeq[float]()

#     xpos = (round(xpos/distperstep))*distperstep
#     ypos = (round(ypos/distperstep))*distperstep

#     x.add(xpos)
#     y.add(ypos)

#     idtx = 0
#     idty = 0
#     t = 0.0

#     while true:

#       if tx[idtx] < ty[idty]:
#         xpos += xdir[idtx]*distperstep
#         x.add(xpos)
#         y.add(ypos)
#         idtx += 1
#       else:
#         ypos += ydir[idty]*distperstep
#         x.add(xpos)
#         y.add(ypos)
#         idty += 1

#       if (idty >= len(ty)) or (idtx >= len(tx)):
#         break

#     figure.add newLinePlot[float, float](x, y)

#   figure.save("./pathsplot.png")


# if isMainModule:

#   var
#     paths: seq[Path]


#   paths = parsesvg("./test3.svg")

#   echo(len(paths[0].c))

#   var
#     v = paths.min()


#   # shift paths to drawable area
#   for i in 0..(len(paths)-1):
#     paths[i].shift(vec2(+82.0, 6.0))

#   #plot_paths(paths)

#   echo("do coordinate transformation")
#   # apply coordiante transformation
#   for i in 0..(len(paths)-1):
#     paths[i].xy_to_ab()

#   plot_paths(paths)




