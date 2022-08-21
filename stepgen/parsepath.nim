import glm
import math
import curve
import streams, strutils
import matplotnim
import path
import npeg, npeg/capture

type
  PathMode = enum # the different Curve types
    PMline,       # Line
    PMcurve,      # Cubic bezier

type
  PathBuf = ref object
    pen: Vec2[float]
    curves: seq[Curve]


proc closepath(buf: var PathBuf) =
  var c = newLine()

  if buf.curves[^1].kind == ckLine:
    c.a = buf.curves[^1].b
  if buf.curves[^1].kind == ckBezier:
    c.a = buf.curves[^1].b3

  if buf.curves[0].kind == ckLine:
    c.b = buf.curves[0].a
  if buf.curves[0].kind == ckBezier:
    c.b = buf.curves[0].b0

  buf.curves.add(c)


proc parse_positions(capture: Captures): seq[float] =
  for i in 1..<len(capture.caplist):
    result.add(parseFloat(capture.caplist[i].s))


let parser = peg("path", buf: PathBuf):

  space <- ' '


  exponent <- ('e'|'E') * ?'-' * +Digit


  number <- ?('-' | '+') * +Digit * ?('.' * +Digit) * ?exponent


  coordinate_pair <- ( > number) * (',' | ' ') * ( > number) * ?space


  vert_rel <- 'h' * ?space * +( > number * ?space):
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = buf.pen + vec2(positions[i], 0.0)
      buf.curves.add(c)
      i += 1

    buf.pen = buf.curves[^1].endpoint()


  vert_abs <- 'H' * ?space * +( > number * ?space):
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = vec2(positions[i], 0.0)
      buf.curves.add(c)
      i += 1

    buf.pen = buf.curves[^1].endpoint()


  horz_rel <- 'v' * ?space * +( > number * ?space):
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = buf.pen + vec2(0.0, positions[i])
      buf.curves.add(c)
      i += 1
      buf.pen = buf.curves[^1].endpoint()



  horz_abs <- 'V' * ?space * +( > number * ?space):
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = vec2(0.0, positions[i])
      buf.curves.add(c)
      i += 1
      buf.pen = buf.curves[^1].endpoint()


  line_rel <- 'l' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = buf.pen + vec2(positions[i], positions[i+1])
      buf.curves.add(c)
      i += 2
      buf.pen = buf.curves[^1].endpoint()


  line_abs <- 'L' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = vec2(positions[i], positions[i+1])
      buf.curves.add(c)
      i += 2
      buf.pen = buf.curves[^1].endpoint()


  moveto_rel <- 'm' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    buf.pen = vec2(positions[i], positions[i+1])
    i += 2

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = buf.pen + vec2(positions[i], positions[i+1])
      buf.curves.add(c)
      i += 2
      buf.pen = buf.curves[^1].endpoint()


  moveto_abs <- 'M' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    buf.pen = vec2(positions[i], positions[i+1])
    i += 2

    while i < len(positions):
      c = newLine()
      c.a = buf.pen
      c.b = vec2(positions[i], positions[i+1])
      buf.curves.add(c)
      i += 2
      buf.pen = buf.curves[^1].endpoint()


  curveto_rel <- 'c' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newCubicBezier()
      c.b0 = buf.pen
      c.b1 = buf.pen + vec2(positions[i], positions[i+1])
      c.b2 = buf.pen + vec2(positions[i+2], positions[i+3])
      c.b3 = buf.pen + vec2(positions[i+4], positions[i+5])
      buf.curves.add(c)
      i += 6
      buf.pen = buf.curves[^1].endpoint()


  curveto_abs <- 'C' * ?space * +coordinate_pair:
    let positions = parse_positions(capture)

    var
      c: Curve
      i: int = 0

    while i < len(positions):
      c = newCubicBezier()
      c.b0 = buf.pen
      c.b1 = vec2(positions[i], positions[i+1])
      c.b2 = vec2(positions[i+2], positions[i+3])
      c.b3 = vec2(positions[i+4], positions[i+5])
      buf.curves.add(c)
      i += 6
      buf.pen = buf.curves[^1].endpoint()



  close_path <- 'Z' | 'z':
    buf.closepath()

  command <- (curveto_rel | curveto_abs | line_rel | line_abs | vert_rel |
      vert_abs | horz_rel | horz_abs)


  path <- (moveto_rel | moveto_abs) * *command * ?close_path



proc newPathBuf(): PathBuf =
  result = PathBuf()
  result.pen = vec2(0.0, 0.0)
  result.curves = @[]


proc parse_path*(data: string): seq[Curve] =
  var buf = newPathBuf()

  let r = parser.match(data, buf)
  result = buf.curves


if isMainModule:
  var curves: seq[Curve]

  #let data = "m 129.91214,540.46252 1.05833,40.74584 v 32.27915"
  #let data = "M 64.216,599.156 V 460.66627 l 115.246619,0"
  #let data = "m 601.83793,578.89747 c -49.03642,-125.49365 13.01104,-241.89522 44.90129,-306.07704 31.89025,-64.18182 96.12174,-37.26159 84.56408,-86.0608"
  #let data = "M 352.47505,578.15794 397.37634,272.0809 c 145.58633,30.71944 96.12174,-37.26159 84.56408,-86.0608"
  #let data = "m 90.351296,89.165883 -10.0,-10.0 -10.0,-10.0 z"
  let data = "m 30,65 c 6.618739,-1.043991 7.442143,-3.193627 15,0 7.557857,3.193627 7.766282,2.291048 15,0 7.233718,-2.291048 10.904607,-1.797718 15,0"

  echo data

  curves = parse_path(data)

  for c in curves:
    echo(c)

  echo(len(curves))
