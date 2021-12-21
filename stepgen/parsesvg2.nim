import glm
import math
import curve
import streams, parsexml, strutils
import matplotnim
import path
import npeg


type PathBuf = ref object
  pen: Vec2[float]
  points: seq[Vec2[float]]
  curves: seq[Curve]
  relative: bool

proc add_coordinates(buf: var PathBuf, x: float, y: float) =
  if buf.relative:
    buf.pen[0] += x
    buf.pen[1] += y
  else:
    buf.pen[0] = x
    buf.pen[1] = y
  buf.points.add(buf.pen)


let data = "m 129.91214,540.46252 1.05833,40.74584 v 32.27915"


let parser = peg("path", buf: PathBuf):
  space <- ' '

  number <- (?'-' * +Digit * '.' * +Digit)

  coordinate_pair <- * >number * ',' * >number * space:
    buf.add_coordinates(parseFloat($1), parseFloat($2))

  moveto_rel <- 'm' * space * >number * ',' * >number * space:
    buf.relative = true
    buf.add_coordinates(parseFloat($1), parseFloat($2))
  
  moveto_abs <- 'M' * space * >number * ',' * >number * space:
    buf.relative = false
    buf.add_coordinates(parseFloat($1), parseFloat($2))
  
  curveto_rel <- 'c' * space * >number * ',' * >number * space:
    buf.relative = true
    buf.add_coordinates(buf.pen[0] + parseFloat($1), buf.pen[1] + parseFloat($2))
  
  curveto_abs <- 'C' * space * >number * ',' * >number * space:
    buf.relative = false
    buf.add_coordinates(parseFloat($1), parseFloat($2))

  command <- (moveto_rel | moveto_abs | curveto_rel | curveto_abs) * *space

  vert_rel <- 'v' * space * >number:
    buf.relative = false
    buf.add_coordinates(buf.pen[0] + parseFloat($1), buf.pen[1])
  vert_abs <- 'V' * space * >number:
    buf.relative = false
    buf.add_coordinates(parseFloat($1), buf.pen[1])
  horz_rel <- 'h' * space * >number:
    buf.relative = false
    buf.add_coordinates(buf.pen[0], buf.pen[1] + parseFloat($1))
  horz_abs <- 'H' * space * >number:
    buf.relative = false
    buf.add_coordinates(buf.pen[0], parseFloat($1))

  stub <- (vert_rel | vert_abs | horz_rel | horz_abs) * *space

  path <- command * *coordinate_pair * *( (stub | command) * *coordinate_pair) 


var buf = new PathBuf


proc newPathBuf(): PathBuf = 
  result = PathBuf()
  result.pen = vec2(0.0, 0.0)
  result.points = @[]
  result.curves = @[]
  result.relative = true


let r = parser.match(data, buf)
echo(r)
echo(buf.points)




#if isMainModule:


