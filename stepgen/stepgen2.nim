import glm
import math
import seqmath
import sequtils
import matplotnim
import path
import curve
import parsesvg
import coordtransform
import strutils
import algorithm
import cubicroot

# https://github.com/nim-lang/Nim/issues/4112
proc argsort[T](a : T) : seq[int] =
  result = arange(0,a.len)
  proc compare(i, j: int) : int {.closure.} = cmp(a[i], a[j])
  sort(result, compare)


# intersect curve with a regular grid of horizontal (vind=1) or vertical (vind=0) lines spaced
# by delta.
proc calc_grid_intersections(c: Curve, delta: float, vind: int): (seq[float], seq[float]) =
  var
    val = 0.0
    ts: seq[float]
    res: seq[float]
    vals: seq[float]
    A, B, C, D: float
    maxval : float
    sorted_ind: seq[int]

  if c.kind == ckBezier:

    # calculate coefficients that don't change
    A = -1.0 * c.b0[vind] + 3.0*c.b1[vind] - 3.0 * c.b2[vind] + c.b3[vind]
    B = 3.0*c.b0[vind]-6.0*c.b1[vind]+3.0*c.b2[vind]
    C = -3.0*c.b0[vind]+3.0*c.b1[vind]

    # calculate starting and ending values, based on bounding polygon of the bezier
    val = min(@[c.b0[vind],c.b1[vind],c.b2[vind],c.b3[vind]])
    if float(sign(c.calc_derivative(0.0)[vind])) > 0:
      val = (round(val/delta)-1.0)*delta # round to delta/distperstep
    else:
      val = (round(val/delta)+1.0)*delta # round to delta/distperstep

    maxval = max(@[c.b0[vind],c.b1[vind],c.b2[vind],c.b3[vind]])

    # iterate over the grid from smallest mininum val to maxval
    while true:
      # re-calculate coefficient D
      D = c.b0[vind] - val
      # get intersections
      res = calc_root(A, B, C, D)

      for t in res:
        # check for valid solutions
        if t >= 0 and t <= 1.0:
          ts.add(t)
          vals.add(val)

      val += delta
      if val > maxval:
        break
  else:
    echo("Can't intersect lines with grid, please convert to bezier!")

  # sort solution so that t is ascending (calc_root can give multiple solution for one val)
  sorted_ind = argsort(ts)
  ts = ts[sorted_ind]
  vals = vals[sorted_ind]

  result = (ts, vals)


# calculate arclength parameter of intersections with a grid of regular (by delta) spaced horizontal/vertical (vind=0/vind=1) lines
proc calc_grid_intersections*(p: Path, delta: float, vind: int): (seq[float], seq[float]) =
  var
    ts: seq[float]
    vals: seq[float]
    tbuf, valbuf: seq[float]
    offset: float = 0.0
        
  for c in p.c:
    (tbuf, valbuf) = calc_grid_intersections(c, delta, vind)
    
    # add offset to values, because in a path might have several curves with different arclengths
    tbuf.apply(proc(x: float): float = x + offset)

    ts.add(tbuf)
    vals.add(valbuf)
    
    # calculate offset for next curve
    offset += c.get_arclength()
    #offset += 1.0

  #echo(ts)
  #echo(vals)
  result = (ts, vals)


proc calc_dt*(p: Path, delta: float, vind: int): (seq[float], seq[float]) =
  var
    ts: seq[float]
    vals: seq[float]
    dir: seq[float]
    dts: seq[float]
    buf: float

  (ts, vals) = calc_grid_intersections(p, delta, vind)

  # add first direction value, same as the second one. might not be the best solution,
  # but at least the test cases are covered
  #dir.add( float(sign( vals[1]-vals[0] )) )

  # calculate directions from the sign of the difference between consecutive values
  for i in 0..(len(ts)-2):
    buf = float(sign( vals[i+1]-vals[i] ))
    if buf != 0.0:
      dir.add(buf)
    else:
      dir.add(-1.0*dir[^1])
    dts.add(ts[i+1]-ts[i])

  for i in 0..(len(dts)-1):
    dts[i] *= dir[i]

  result = (dts, dir)


# both paths must only contain cubic bezier curves!
proc connect_path_to_path*(p1, p2: Path): Path =
  var 
    c : Curve
    l : float

  result = newPath()
  c = newCubicBezier()
  c.b0 = p1.c[^1].b3
  c.b3 = p2.c[0].b0
  l = length( c.b0 - c.b3 ) 
  #c.b1 = c.b0 + p1.calc_derivative(p1.get_arclength()).normalize()*(l/2)
  c.b1 = c.b0 - (c.b0-c.b3).normalize()*(l/2)
  #c.b2 = c.b3 - p2.calc_derivative(0.0).normalize()*(l/3)
  c.b2 =c.b1
  result.add(c)


# path must only contain cubic bezier curves!
proc connect_point_to_path*(a: Vec2[float], p : Path): Path =
  var 
    c : Curve
    l : float

  result = newPath()
  c = newCubicBezier()
  c.b0 = a
  c.b3 = p.c[0].b0
  l = length( c.b0 - c.b3 ) 
  c.b1 = c.b0 - (a-c.b3).normalize()*(l/2)
  c.b2 = c.b3 - p.calc_derivative(0.0).normalize()*(l/2)
  result.add(c)


proc write_steps_to_file*(filename: string, paths: seq[Path], distperstep: float = 0.00375) =
  var 
    ty = newSeq[float]()
    tx = newSeq[float]()
    ydir = newSeq[float]()
    xdir = newSeq[float]()

  let fa = open(filename & "_a.tmng", fmWrite)
  defer: fa.close()
  fa.writeLine("# dta actiona")

  let fb = open(filename & "_b.tmng", fmWrite)
  defer: fb.close()
  fb.writeLine("# dtb actionb")

  proc write_part(path: Path, draw: bool=false) =

    (tx, xdir) = calc_dt(path, distperstep, 0)
    (ty, ydir) = calc_dt(path, distperstep, 1)

    #tx.apply(proc(x: float): float = x * 40000)
    #ty.apply(proc(x: float): float = x * 40000)
    tx.apply(proc(x: float): float = x * 80000)
    ty.apply(proc(x: float): float = x * 80000)

    if draw:
      fa.writeLine( $(xdir[0]*(tx[0])) & " " & $(2)) # 2 means pen down
    else:
      fa.writeLine( $(xdir[0]*(tx[0])) & " " & $(0))

    for i in 1..(len(tx)-3):
      fa.writeLine( $(xdir[i+1]*(tx[i+1]-tx[i])) & " " & $(0))

    if draw:
      fa.writeLine( $(xdir[^1]*(tx[^1]-tx[^2])) & " " & $(1)) # 1 means pen down
    else:
      fa.writeLine( $(xdir[^1]*(tx[^1]-tx[^2])) & " " & $(0))


    fb.writeLine( $(ydir[0]*(ty[0])) & " " & $(0))
    for i in 0..(len(ty)-2):
      fb.writeLine( $(ydir[i+1]*(ty[i+1]-ty[i])) & " " & $(0))


  echo("processing ", 1, "/",len(paths))
  write_part(connect_point_to_path(vec2(0.0, 0.0),paths[0]))

  for i in 0..(len(paths)-2):
    echo("processing ", i+1, "/",len(paths))
    write_part(paths[i], draw=true)
    write_part(connect_path_to_path(paths[i],paths[i+1]))

  echo("processing ", len(paths), "/",len(paths))
  write_part(paths[^1], draw=true)




# very slow, only for debugging use
proc plot_paths(paths: seq[Path]) =
  var 
    x = newSeq[float]()
    y = newSeq[float]()
    xpos: float
    ypos: float
    t: float
    idtx, idty: int  
    ty = newSeq[float]()
    tx = newSeq[float]()
    ydir = newSeq[float]()
    xdir = newSeq[float]()
  
  let
    distperstep = 0.00375

  let figure = newFigure(python = "python")
  
  for p in paths:
    (tx, xdir) = calc_dt(p, distperstep, 0)
    (ty, ydir) = calc_dt(p, distperstep, 1)

    tx.apply(proc(x: float): float = x * 50000)
    ty.apply(proc(x: float): float = x * 50000)

    xpos = p.calc_point(0.0)[0]
    ypos = p.calc_point(0.0)[1]
    x = newSeq[float]()
    y = newSeq[float]()

    xpos = (round(xpos/distperstep))*distperstep
    ypos = (round(ypos/distperstep))*distperstep

    x.add(xpos)
    y.add(ypos)

    idtx = 0
    idty = 0
    t = 0.0

    while true:

      if tx[idtx] < ty[idty]:
        xpos += xdir[idtx]*distperstep
        x.add(xpos)
        y.add(ypos)
        idtx += 1
      else:
        ypos += ydir[idty]*distperstep
        x.add(xpos)
        y.add(ypos)
        idty += 1
          
      if (idty >= len(ty)) or (idtx >= len(tx)):
          break

    figure.add newLinePlot[float,float](x, y)
  
  figure.save("./pathsplot.png")



if isMainModule:

  var
    paths: seq[Path]


  paths = parsesvg("./aff2.svg")

  echo(len(paths[0].c))

  var 
    v = paths.min()


  # shift paths to drawable area
  for i in 0..(len(paths)-1):
    paths[i].shift(vec2(+82.0, 6.0))

  #plot_paths(paths)

  echo("do coordinate transformation")
  # apply coordiante transformation
  for i in 0..(len(paths)-1):
    paths[i].xy_to_ab()

  #plot_paths(paths)

  echo("Writing timings to file")
  write_steps_to_file("Zeichnung",paths)

