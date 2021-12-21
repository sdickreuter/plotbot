import glm
import math
import numericalnim
import matplotnim

{.experimental: "codeReordering".}


type
  CurveKind* = enum # the different Curve types
    ckLine,         # Line
    ckBezier,       # Cubic bezier

  Curve* = ref object
    arclength: float
    xlength: float
    ylength: float
    case kind*: CurveKind
      of ckLine:
        a*: Vec2[float]
        b*: Vec2[float]
      of ckBezier:
        b0*: Vec2[float]
        b1*: Vec2[float]
        b2*: Vec2[float]
        b3*: Vec2[float]


proc max*(c: Curve): Vec2[float] =
  result = vec2(low(float), low(float))
  case c.kind

    of ckLine:
      if c.a[0] >= c.b[0]:
        result[0] = c.a[0]
      else:
        result[0] = c.b[0]

      if c.a[1] >= c.b[1]:
        result[1] = c.a[1]
      else:
        result[1] = c.b[1]

    of ckBezier:
      # if (c.b0[0] >= c.b1[0]) and (c.b0[0] >= c.b2[0]) and (c.b0[0] >= c.b3[0]):
      #   result[0] = c.b0[0]
      # elif (c.b1[0] >= c.b0[0]) and (c.b1[0] >= c.b2[0]) and (c.b1[0] >= c.b3[0]):
      #   result[0] = c.b1[0]
      # elif (c.b2[0] >= c.b0[0]) and (c.b2[0] >= c.b1[0]) and (c.b2[0] >= c.b3[0]):
      #   result[0] = c.b2[0]
      # elif (c.b3[0] >= c.b0[0]) and (c.b3[0] >= c.b1[0]) and (c.b3[0] >= c.b2[0]):
      #   result[0] = c.b3[0]

      # if (c.b0[1] >= c.b1[1]) and (c.b0[1] >= c.b2[1]) and (c.b0[1] >= c.b3[1]):
      #   result[1] = c.b0[1]
      # elif (c.b1[1] >= c.b0[1]) and (c.b1[1] >= c.b2[1]) and (c.b1[1] >= c.b3[1]):
      #   result[1] = c.b1[1]
      # elif (c.b2[1] >= c.b0[1]) and (c.b2[1] >= c.b1[1]) and (c.b2[1] >= c.b3[1]):
      #   result[1] = c.b2[1]
      # elif (c.b3[1] >= c.b0[1]) and (c.b3[1] >= c.b1[1]) and (c.b3[1] >= c.b2[1]):
      #   result[1] = c.b3[1]
      if c.b0[0] >= c.b3[0]:
        result[0] = c.b0[0]
      else:
        result[0] = c.b3[0]

      if c.b0[1] >= c.b3[1]:
        result[1] = c.b0[1]
      else:
        result[1] = c.b3[1]


proc min*(c: Curve): Vec2[float] =
  result = vec2(0.0, 0.0)
  case c.kind

    of ckLine:
      if c.a[0] <= c.b[0]:
        result[0] = c.a[0]
      else:
        result[0] = c.b[0]

      if c.a[1] <= c.b[1]:
        result[1] = c.a[1]
      else:
        result[1] = c.b[1]

    of ckBezier:
      # if (c.b0[0] <= c.b1[0]) and (c.b0[0] <= c.b2[0]) and (c.b0[0] <= c.b3[0]):
      #   result[0] = c.b0[0]
      # elif (c.b1[0] <= c.b0[0]) and (c.b1[0] <= c.b2[0]) and (c.b1[0] <= c.b3[0]):
      #   result[0] = c.b1[0]
      # elif (c.b2[0] <= c.b0[0]) and (c.b2[0] <= c.b1[0]) and (c.b2[0] <= c.b3[0]):
      #   result[0] = c.b2[0]
      # elif (c.b3[0] <= c.b0[0]) and (c.b3[0] <= c.b1[0]) and (c.b3[0] <= c.b2[0]):
      #   result[0] = c.b3[0]

      # if (c.b0[1] <= c.b1[1]) and (c.b0[1] <= c.b2[1]) and (c.b0[1] <= c.b3[1]):
      #   result[1] = c.b0[1]
      # elif (c.b1[1] <= c.b0[1]) and (c.b1[1] <= c.b2[1]) and (c.b1[1] <= c.b3[1]):
      #   result[1] = c.b1[1]
      # elif (c.b2[1] <= c.b0[1]) and (c.b2[1] <= c.b1[1]) and (c.b2[1] <= c.b3[1]):
      #   result[1] = c.b2[1]
      # elif (c.b3[1] <= c.b0[1]) and (c.b3[1] <= c.b1[1]) and (c.b3[1] <= c.b2[1]):
      #   result[1] = c.b3[1]
      if c.b0[0] <= c.b3[0]:
        result[0] = c.b0[0]
      else:
        result[0] = c.b3[0]

      if c.b0[1] <= c.b3[1]:
        result[1] = c.b0[1]
      else:
        result[1] = c.b3[1]


proc shift*(c: var Curve, v: Vec2[float]) =
  case c.kind
    of ckLine:
      c.a += v
      c.b += v
    of ckBezier:
      c.b0 += v
      c.b1 += v
      c.b2 += v
      c.b3 += v


proc scale*(c: var Curve, v: Vec2[float]) =
  case c.kind
    of ckLine:
      c.a *= v
      c.b *= v
    of ckBezier:
      c.b0 *= v
      c.b1 *= v
      c.b2 *= v
      c.b3 *= v


proc newLine*(): Curve =
  result = Curve(kind: ckLine)
  result.a = vec2(0.0, 0.0)
  result.b = vec2(0.0, 0.0)


proc newCubicBezier*(): Curve =
  result = Curve(kind: ckBezier)
  result.b0 = vec2(0.0, 0.0)
  result.b1 = vec2(0.0, 0.0)
  result.b2 = vec2(0.0, 0.0)
  result.b3 = vec2(0.0, 0.0)


proc get_arclength*(c: Curve): float =
  if c.arclength == 0.0:
    result = c.calc_arclength(1.0)
    c.arclength = result
  else:
    result = c.arclength


proc get_xlength*(c: Curve): float =
  if c.xlength == 0.0:
    result = c.calc_xlength(1.0)
    c.xlength = result
  else:
    result = c.xlength


proc get_ylength*(c: Curve): float =
  if c.ylength == 0.0:
    result = c.calc_ylength(1.0)
    c.ylength = result
  else:
    result = c.ylength


# calculate point from Curve at speed parametrization t
proc calc_point_t*(c: Curve, t: float): Vec2[float] =
  case c.kind
    of ckLine:
      result = vec2(0.0, 0.0)
      result = (c.b - c.a) # save direction in result
      result *= t # normalize direction
      result = c.a + result # calc point on line
    of ckBezier:
      result = vec2(0.0, 0.0)
      result = (1.0-t)^3*c.b0 + 3.0*(1.0-t)^2*t*c.b1 + 3.0*(1-t)*t^2*c.b2 + t^3*c.b3


# calculate derivative of Curve at speed parametrization t
proc calc_derivative*(c: Curve, t: float): Vec2[float] =
  case c.kind
    of ckLine:
      result = vec2(0.0, 0.0)
      result = (c.b - c.a) # save direction in result
    of ckBezier:
      # calculate derivative from cubic bezier at speed parametrization t
      #-3 ((-1 + t)^2 b . b0 + (-1 + 4 t - 3 t^2) b . b1 + t ((-2 + 3 t) b . b2 - t b . b3))
      result = vec2(0.0, 0.0)
      result = -3.0*c.b0*(t^2) + 6.0*c.b0*t - 3.0*c.b0 + 9.0*c.b1*(t^2) -
          12.0*c.b1*t + 3.0*c.b1 - 9.0*c.b2*(t^2) + 6.0*c.b2*t + 3.0*c.b3*(t^2)


# calculate second derivative of Curve at speed parametrization t
proc calc_derivderiv*(c: Curve, t: float): Vec2[float] =
  case c.kind
    of ckLine:
      echo("derivderic for ckLine not yet implemented, please convert to cubic bezier")
    of ckBezier:
      # calculate derivative of the derivative from cubic bezier at speed parametrization t
      result = vec2(0.0, 0.0)
      result = 6.0 * (c.b0*(-t) + c.b0 + c.b1*(-2.0+3.0*t) - 3.0 * c.b2 * t +c.b2 + c.b3*t)


proc calc_curvature*(c: Curve, t: float): float =
  var
    d = calc_derivative(c,t)
    dd = calc_derivderiv(c,t)

  result =  abs(d[0]*dd[1]-d[1]*dd[0])/pow(d[0]*d[0]+d[1]*d[1],3/2)


proc calc_arclength*(c: Curve, t = 1.0): float =
  case c.kind
    of ckLine:
      var
        v = c.b - c.a
      result = sqrt(v[0]*v[0] + v[1]*v[1])*t
    of ckBezier:
      # Arc length calculation
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float, optional: seq[float]): float =
        result = calc_derivative(c, x).length()

      #result = adaptiveGauss(f, 0.0, t)
      result = gaussQuad(f, 0.0, t)


proc calc_xlength*(c: Curve, t = 1.0): float =
  case c.kind
    of ckLine:
      result = abs(c.b[0] - c.a[0])*t
    of ckBezier:
      # x length calculation
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float, optional: seq[float]): float =
        result = abs(calc_derivative(c, x)[0])

      #result = adaptiveGauss(f, 0.0, t)
      result = gaussQuad(f, 0.0, t)


proc calc_ylength*(c: Curve, t = 1.0): float =
  case c.kind
    of ckLine:
      result = abs(c.b[1] - c.a[1])*t
    of ckBezier:
      # x length calculation
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float, optional: seq[float]): float =
        result = abs(calc_derivative(c, x)[1])

      #result = adaptiveGauss(f, 0.0, t)
      result = gaussQuad(f, 0.0, t)


proc calc_CurveParameter*(c: Curve, s: float): float =
  case c.kind
    of ckLine:
      result = s / c.get_arclength()
    of ckBezier:
      # calculate curve parameter from arc length s:
      # arc length parametrization (distance travelled on curve) -> speed parametrization
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float): float =
        result = calc_arclength(c, x) - s

      proc df(x: float64): float64 =
        result = calc_derivative(c, x).length()

      if s <= 0.0:
        result = 0.0
      elif s >= c.get_arclength():
        result = 1.0
      else:
        result = newtons(f, df, s/c.get_arclength())


proc calc_xCurveParameter*(c: Curve, sx: float): float =
  case c.kind
    of ckLine:
      result = sx / c.get_xlength()
    of ckBezier:
      # calculate curve parameter from x length sx:
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float): float =
        result = calc_xlength(c, x) - sx

      proc df(x: float64): float64 =
        result = abs(calc_derivative(c, x)[0])

      if sx <= 0.0:
        result = 0.0
      elif sx >= c.get_xlength():
        result = 1.0
      else:
        result = newtons(f, df, sx/c.get_xlength())


proc calc_yCurveParameter*(c: Curve, sy: float): float =
  case c.kind
    of ckLine:
      result = sy / c.get_ylength()
    of ckBezier:
      # calculate curve parameter from y length sy:
      # inspired from https://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
      proc f(x: float): float =
        result = calc_ylength(c, x) - sy

      proc df(x: float64): float64 =
        result = abs(calc_derivative(c, x)[1])

      if sy <= 0.0:
        result = 0.0
      elif sy >= c.get_ylength():
        result = 1.0
      else:
        result = newtons(f, df, sy/c.get_ylength())


proc `$`*(c: Curve): string =
  case c.kind
    of ckLine:
      result = "a: " & $c.a & " b: " & $c.b
    of ckBezier:
      result = "b0: " & $c.b0 & " b1: " & $c.b1 & " b2: " & $c.b2 & " b3: " & $c.b3


###---------------------
### Main for testing
###---------------------

if isMainModule:

  var
    b: Curve

  b = newCubicBezier()
  b.b0 = vec2(0.1, 0.1)
  b.b1 = vec2(0.1, 1.1)
  b.b2 = vec2(1.0, -1.0)
  b.b3 = vec2(1.0, 0.1)

  # b = newLine()
  # b.a = vec2(0.1, 0.2)
  # b.b = vec2(1.3, 1.4)


  discard b.get_arclength()

  echo b.calc_point_t(0.5)

  echo "arclength: ", b.calc_arclength(1.0)

  var
    t = b.calc_CurveParameter(0.5)
  echo "t:", t

  echo b.calc_arclength(t)

  echo "xlength: ", b.get_xlength()
  echo "ylength: ", b.get_ylength()

  let
    num = 40

  var
    x = newSeq[float](num+1)
    y = newSeq[float](num+1)
    x2 = newSeq[float](num+1)
    y2 = newSeq[float](num+1)
    x3 = newSeq[float](num+1)
    y3 = newSeq[float](num+1)
    v = vec2(0.0, 0.0)

  for p in 0..<(num+1):
    v = b.calc_point_t(float(p)/float(num))
    #v = b.calc_derivative(float(p)/100)
    x[p] = v[0]
    y[p] = v[1]

    # x[p] = float(p)
    # y[p] = b.calc_arclength(float(p)/100)
    v = b.calc_point_t(b.calc_CurveParameter(float(p)/float(
        num)*b.get_arclength()))
    #v = b.calc_derivative(float(p)/100)
    x2[p] = v[0]
    y2[p] = v[1]+0.1


  let figure = newFigure(python = "python")
  let points = newScatterPlot(x, y)
  points.colour = "orange"
  figure.add points
  let points2 = newScatterPlot(x2, y2)
  points2.colour = "blue"
  figure.add points2
  figure.save("./beziertest.png")


  for p in 0..<(num+1):
    v = b.calc_point_t(float(p)/float(num))
    #v = b.calc_derivative(float(p)/100)
    x[p] = v[0]
    y[p] = v[1]

    # x[p] = float(p)
    # y[p] = b.calc_arclength(float(p)/100)
    v = b.calc_point_t(b.calc_xCurveParameter(float(p)/float(num)*b.get_xlength()))
    #v = b.calc_derivative(float(p)/100)
    x2[p] = v[0]
    y2[p] = v[1]+0.1

    # x[p] = float(p)
    # y[p] = b.calc_arclength(float(p)/100)
    v = b.calc_point_t(b.calc_yCurveParameter(float(p)/float(num)*b.get_ylength()))
    #v = b.calc_derivative(float(p)/100)
    x3[p] = v[0]
    y3[p] = v[1]-0.1


  let figure2 = newFigure(python = "python")
  let points3 = newScatterPlot(x, y)
  points3.colour = "orange"
  figure2.add points3
  let points4 = newScatterPlot(x2, y2)
  points4.colour = "blue"
  figure2.add points4
  let points5 = newScatterPlot(x3, y3)
  points5.colour = "green"
  figure2.add points5
  figure2.save("./beziertest2.png")

  echo("max", b.max())
  echo("min", b.min())
  b.shift(vec2(2.0, 2.5))
  echo(b)
  b.scale(vec2(2.0, 2.5))
  echo(b)



