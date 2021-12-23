import glm
import math
import sequtils
import matplotnim
import path
import curve
import parsesvg
import coordtransform
import strutils
import algorithm
import stepgen
import numutils


proc add_slow_down(dt: var seq[float], i0, width: int, a: float) =
  for i in 0..<len(dt):
    #dt[i] += quad_peak((float) i, a, (float) i0, (float) width)
    dt[i] += cos_peak((float) i, a, (float) i0, (float) width)
    #dt[i] += tri_peak((float)i, a, (float)i0, (float)width)


proc slow_down_by_curvature(path: Path, dt: var seq[float], t: seq[float]) =
  var
    points = newSeq[Vec2[float]](len(t))
    curvature = newSeq[float](len(t))

  for i in 0..<len(t):
    curvature[i] = path.calc_curvature_t(t[i])

  let
    minval = 1e-2
    maxval = 0.16

  for i in 0..<len(t):
    #echo(curvature[i], "  ",limit_and_normalize(curvature[i],1,1000))
    #dtbuf[i] += limit_and_normalize(curvature[i],0.1,10000)*800
    if dt[i] < 1500:
      add_slow_down(dt, i, 1000, 100*limit_and_normalize(curvature[i],1,20000)) 
    #     if alphas[i-1] > 1e-1: echo(round(alphas[i-1],5))
    #     alphas[i-1] = limit_and_normalize(alphas[i-1], minval, maxval)
    #     add_slow_down(dtbuf, i, 500, 800*alphas[i-1])


proc gen_part(path: Path, distperstep: float, mindt: float, draw: bool = false): (seq[float], seq[int]) =
  var
    t: seq[float]
    dt, dtbuf: seq[float]
    a, abuf: seq[int]
    t_buf: float
    p1, p2: Vec2[float]
    fac: float

  (abuf, t) = calc_actions(path, distperstep)
  dtbuf = repeat(mindt,len(abuf))

  #echo("gen_part start",path.c[0].b0,"   len ",len(t))

  if len(abuf) > 0:

    # add slowdown on corners between curves based on angle of the corner
    for i in 1..<len(t):    
      if floor(t[i]) - floor(t[i-1]) == 1.0:
        #echo(t[i], " ", floor(t[i]), " ", t[i-1]," ", floor(t[i-1]))
        p1 = normalize(path.calc_point_t(t[i])-path.calc_point_t(t[i]-distperstep))
        p2 = normalize(path.calc_point_t(t[i]+distperstep)-path.calc_point_t(t[i]))
        #p1 = normalize(path.calc_point_t(t[i-1])-path.calc_point_t(floor(t[i])))
        #p2 = normalize(path.calc_point_t(floor(t[i]))-path.calc_point_t(t[i-1]))
        #echo(p1," ",p2," ",arccos(abs(dot(p1,p2)))," | ",dot(p1,p2))
        fac = limit_and_normalize(arccos(abs(dot(p1,p2))),0.0,1.0)
        #fac = arccos(abs(dot(p1,p2)))
        #echo(fac)
        if (fac.classify != fcNaN) and (fac.classify != fcInf):
          add_slow_down(dtbuf, i, 1000, 1500*fac)

    # add slow down based on curvature
    slow_down_by_curvature(path, dtbuf, t)

    # add slowdown at start and end of path
    add_slow_down(dtbuf, 0, 1000, 2500)
    add_slow_down(dtbuf, len(dtbuf), 1000, 2500)

    if draw:
      a.add( (int)PENDOWN)
      dt.add(400000)

    a = a & abuf
    dt = dt & dtbuf 

    if draw:
      a.add( (int)PENUP)
      dt.add(400000)

    result = (dt, a)


proc generate_steps*(paths: seq[Path], distperstep: float = 0.00375): (seq[int],
#proc generate_steps*(paths: seq[Path], distperstep: float = 1.0): (seq[int],
    seq[float]) =
  var
    a, abuf: seq[int]
    dt, dtbuf: seq[float]
    pbuf: Path

  a = newSeq[int]()
  dt = newSeq[float]()


  for i in 0..(len(paths)-2):
    echo("--- processing ", i+1, "/", len(paths)," ---")
    (dtbuf, abuf) = gen_part(paths[i], distperstep, 700, draw = true)
    a &=  abuf
    dt &= dtbuf 

    #echo("--- connecting to next path ---")
    #pbuf = connect_path_to_path(paths[i], paths[i+1])
    var
      start, stop: Vec2[float]

    start = paths[i].endpoint()
    #start = round(start/distperstep)*distperstep
    stop = paths[i+1].startpoint()
    #stop = round(stop/distperstep)*distperstep
    #echo("connection: start ",start,"  stop ",stop)
    pbuf = connect_point_to_point(start,stop)
    
    #echo("  start ",paths[i].c[^1].b3)
    #echo("  end ",paths[i+1].c[0].b0)
    #echo("  con ",pbuf.c[0].b0," ",pbuf.c[0].b3," ")
    #echo("  diff ",pbuf.c[0].b0-paths[i].c[^1].b3," ",pbuf.c[0].b3-paths[i+1].c[0].b0," ")

    #(dtbuf, abuf) = gen_part(connect_path_to_path(paths[i], paths[i+1]), distperstep, 300, draw = false)
    (dtbuf, abuf) = gen_part(pbuf, distperstep, 500, draw = false)
    a &= abuf
    dt &= dtbuf


  #echo("--- processing ", len(paths), "/", len(paths)," ---")
  (dtbuf, abuf) = gen_part(paths[^1], distperstep, 700, draw = true)
  a &= abuf
  dt &= dtbuf 

  echo("--- connecting last path to starting point ---")
  (dtbuf, abuf) = gen_part(connect_path_to_point(paths[^1], vec2(3.0, 3.0)), distperstep, 200, draw = false)
  a = a & abuf
  dt = dt & dtbuf 

  echo("--- finished generation of timings ---")

  result = (a, dt)


proc write_steps_to_file*(filename: string, dt: seq[float], a: seq[int]) =
  let f = open(filename & ".tmng", fmWrite)
  defer: f.close()
  f.writeLine("# dt action")

  echo("saving timings to file")

  for i in 0..<len(dt):
    f.writeLine( $((int) round(dt[i])) & " " & $(a[i]))
    # if (a[i] and PENUP) or (a[i] and PENDOWN):
    #   f.writeLine( $( 40000.0) & " " & $(a[i]))
    # else:
    #   f.writeLine( $( 1000.0) & " " & $(a[i]))

  echo("finished saving")


if isMainModule:

  var
    paths: seq[Path]


  paths = parsesvg("./test.svg")
  #paths = parsesvg("./test11.svg")

  echo(len(paths[0].c))

  var
    v = paths.min()


  # shift paths to drawable area
  for i in 0..(len(paths)-1):
    echo("len curves path[",i,"]: ",len(paths[i].c))
    #paths[i].shift(vec2(+82.0, 4.0))
    paths[i].shift(vec2(+80.0, 4.0))

  for i in 0..<len(paths):
   paths[i].remove_short_curves(1e-2)


  echo("do coordinate transformation")
  # apply coordiante transformation
  for i in 0..(len(paths)-1):
    paths[i].xy_to_ab()


  #echo("paths start/end:")
  #for i in 0..<len(paths):
  #  # for j in 0..<len(paths.c):
  #  #   echo(startpaths[i].c[j]
  #  echo("start ",paths[i].c[0].b0,"   end ",paths[i].c[^1].b3)


  var
    dt = newSeq[float]()
    a = newSeq[int]()
    dt_buf = newSeq[float]()
    a_buf = newSeq[int]()
    min_ind = 0
    max_ind = 0
    count = 5
    done = false
    distperstep: float = 0.00375
    #distperstep: float = 0.1

  echo("--- connecting starting point to path ---")
  (dtbuf, abuf) = gen_part(connect_point_to_point(vec2(0.0, 0.0), paths[0].startpoint), distperstep, 500, draw = false)
  a = a & abuf
  dt = dt & dtbuf 

  echo("generate timings")
  (a_buf, dt_buf) = generate_steps(paths,distperstep)
  a &= a_buf
  dt &= dt_buf

  # if (len(paths)-1) < count:
  #   max_ind = len(paths)-1
  # else:
  #   max_ind = count

  # while done == false:
  #   if max_ind == len(paths)-1:
  #     done = true

  #   (a_buf, dt_buf) = generate_steps(paths[min_ind..max_ind],distperstep)
  #   a &= a_buf
  #   dt &= dt_buf
  #   a = a & abuf
  #   dt = dt & dtbuf 
  #   max_ind += count
  #   min_ind += count
  #   if max_ind > len(paths)-1:
  #     max_ind = len(paths)-1
  #   if (max_ind < len(paths)-6) and (min_ind > count):
  #     (dtbuf, abuf) = gen_part(connect_path_to_path(paths[min_ind-1], paths[min_ind]), distperstep, 300, draw = false)
  #     a = a & abuf
  #     dt = dt & dtbuf 


  write_steps_to_file("Zeichnung", dt, a)


  # var
  #   x: seq[float]
  #   y: seq[float]

  # for p in paths:
  #   for c in p.c:
  #     x.add(c.b0[0])
  #     y.add(c.b0[1])
  #     x.add(c.b1[0])
  #     y.add(c.b1[1])
  #     x.add(c.b2[0])
  #     y.add(c.b2[1])
  #     x.add(c.b3[0])
  #     y.add(c.b3[1])


  # let figure2 = newFigure(python = "python")
  # let points2 = newScatterPlot(x, y)
  # points2.colour = "orange"
  # figure2.add points2
  # figure2.save("./optimize_points.png")