## This module contains the Path type and related functions
## The Path type is used to hold several curves which are drawn sequentially without raising the pen
##
## :Author: Simon Dickreuter
## :Copyright: 2021

import glm
import matplotnim
import curve
import math


type Path* = ref object
    ## Holds several curves which are drawn sequentially.
    c*: seq[Curve] ## seq which holds the Curves
    arclength: float ## arc length of all curves combined
    xlength: float ## distance in x direction, sum of a all curves 
    ylength: float ## distance in y direction, sum of a all curves 


proc newPath*(): Path =
    ## Construct new Path object.
    new(result)
    result.c = @[]


proc startpoint*(p: Path): Vec2[float] =
    ## Return starting point of first curve in path.
    return p.c[0].b0


proc endpoint*(p: Path): Vec2[float] =
    ## Return ending point of last curve in path.
    return p.c[^1].b3


proc convert_all_to_beziers*(p: var Path) =
    ## Convert all curves that are Lines to Cubic Beziers.
    var
        buf: Curve
    for i in 0..<len(p.c):
        if p.c[i].kind == ckLine:
            buf = newCubicBezier()
            buf.b0 = p.c[i].a # start point of line and cubic bezier are the same
            buf.b1 = p.c[i].calc_point_t(1/3) # calculate point on line 1/3 from start
            buf.b2 = p.c[i].calc_point_t(2/3) # calculate point on line 2/3 from start
            buf.b3 = p.c[i].b # end point of line and cubic bezier are the same
            p.c[i] = buf


proc remove_short_curves*(p: var Path, min_length: float = 0.01) =
    ## Remove all curves that are shorter than min_length.
    var
        indices = newSeq[int]()
        buf: Vec2[float]

    for i in 0..<len(p.c):
        #echo("remove_short_curves: ",p.c[i].get_arclength())
        if p.c[i].get_arclength() < min_length:
            indices.add(i)

    for i in countdown(len(indices)-1, 0):
        if (indices[i] > 0) and (indices[i] < (len(p.c)-1)):
            buf = vec2( (p.c[indices[i]-1].b3[0]+p.c[indices[i]+1].b0[0])/2, (p.c[indices[i]-1].b0[1]+p.c[indices[i]+1].b3[1])/2)
            p.c[indices[i]-1].b3 = buf
            p.c[indices[i]+1].b0 = buf

        p.c.delete(indices[i])


proc add*(p: Path, c: Curve) =
    ## Add curve to path. Added curve has to start where the last curve ends or undefined will occur!
    p.c.add(c)


proc get_arclength*(p: Path): float =
    ## return p.arclength, calculate and store value if arclength is zero
    if p.arclength == 0.0:
        for c in p.c:
            result += c.calc_arclength(1.0)
        p.arclength = result
    else:
        result = p.arclength


proc calc_arclength*(p: Path, t: float): float =
    ## calculate arclength by summing arclengths of all curves
    for i in 0..<((int)floor(t)):
        result += p.c[i].get_arclength()
    result += p.c[(int)floor(t)].calc_arclength(t-floor(t))


proc get_xlength*(p: Path): float =
    ## return length in x direction, calculate and store value if it is zero
    if p.xlength == 0.0:
        for c in p.c:
            result += c.calc_xlength(1.0)
        p.xlength = result
    else:
        result = p.xlength


proc get_ylength*(p: Path): float =
    ## return length in y direction, calculate and store value if it is zero
    if p.ylength == 0.0:
        for c in p.c:
            result += c.calc_ylength(1.0)
        p.ylength = result
    else:
        result = p.ylength


proc reset_lengths*(p: Path) =
    ## reset all stored length, use this if path is modified between calls of get_arclength and others
    p.arclength = 0.0
    p.xlength = 0.0
    p.ylength = 0.0


proc calc_point*(p: Path, s: float): Vec2[float] =
    ## Calculate point on path at arclength parametrization s
    var
        sum = 0.0

    # s is bigger or equal the arclength, return last point in last curve
    if s >= p.get_arclength():
        var
            c = p.c[^1]
        case c.kind
            of ckLine:
                result = c.b
            of ckBezier:
                result = c.b3
    else: # calculate from sum of the arclengths of curves in the path
        for c in p.c:
            sum += c.get_arclength()
            if s < sum:
                result = c.calc_point_t(c.calc_CurveParameter(
                        s-sum+c.get_arclength()))
                break


proc calc_point_t*(p: Path, t: float): Vec2[float] =
    ## calculate point from path at speed parametrization t
    var
        sum = 0.0

    if t >= float(len(p.c)):
        var
            c = p.c[^1]
        case c.kind
            of ckLine:
                result = c.b
            of ckBezier:
                result = c.b3
    else:
        for i in 0..<len(p.c):
            if t < (float(i+1)):
                result = p.c[i].calc_point_t(t-float(i))
                break


proc calc_derivative*(p: Path, s: float): Vec2[float] =
    ## calculate derivative of path at arclength parametrization s
    var
        sum = 0.0

    if s > p.get_arclength() or s == p.get_arclength():
        result = p.c[^1].calc_derivative(1.0)
    else:
        for c in p.c:
            sum += c.get_arclength()
            if s < sum:
                result = c.calc_derivative(c.calc_CurveParameter(
                        s-sum+c.get_arclength()))
                break


proc calc_derivative_t*(p: Path, t: float): Vec2[float] =
    ## calculate derivative of path at speed parametrization t
    var
        sum = 0.0

    if t >= (float) (len(p.c)):
        result = p.c[^1].calc_derivative(1.0)
    else:
        for c in p.c:
            sum += 1.0
            if t < sum:
                result = c.calc_derivative(t-sum+1.0)
                break


# # calculate second derivative of path at speed parametrization t
# proc calc_derivderiv_t*(p: Path, t: float): Vec2[float] =
#     var
#         sum = 0.0

#     if t >= (float) (len(p.c)):
#         result = p.c[^1].calc_derivative(1.0)
#     else:
#         for c in p.c:
#             sum += 1.0
#             if t < sum:
#                 result = c.calc_derivderiv(t-sum+1.0)
#                 break


proc calc_curvature_t*(p: Path, t: float): float =
    ## calculate curvature of path at speed parametrization t
    var
        sum = 0.0

    if t >= (float) (len(p.c)):
        result = p.c[^1].calc_curvature(1.0)
    else:
        for c in p.c:
            sum += 1.0
            if t < sum:
                result = c.calc_curvature(t-sum+1.0)
                break


proc calc_xderivativex*(p: Path, sx: float): float =
    ## calculate x derivative of path at x length parametrization sx
    var
        sum = 0.0
        v = vec2(0.0, 0.0)

    if sx > p.get_xlength() or sx == p.get_xlength():
        result = p.c[^1].calc_derivative(1.0)[0]
    else:
        for c in p.c:
            sum += c.get_xlength()
            if sx < sum:
                v = c.calc_derivative(c.calc_xCurveParameter(
                        sx-sum+c.get_xlength()))
                #v = v/v.length
                result = v[0]
                break


proc calc_yderivativey*(p: Path, sy: float): float =
    ## calculate x derivative of path at y length parametrization sy
    var
        sum = 0.0
        v = vec2(0.0, 0.0)

    if sy > p.get_ylength() or sy == p.get_ylength():
        result = p.c[^1].calc_derivative(1.0)[1]
    else:
        for c in p.c:
            sum += c.get_ylength()
            if sy < sum:
                v = c.calc_derivative(c.calc_yCurveParameter(
                        sy-sum+c.get_ylength()))
                #v = v/v.length
                result = v[1]
                break


proc calc_pointx*(p: Path, sx: float): Vec2[float] =
    ## calculate point from from path at x length parametrization sx
    var
        sum = 0.0

    if sx > p.get_xlength() or sx == p.get_xlength():
        var
            c = p.c[^1]
        case c.kind
            of ckLine:
                result = c.b
            of ckBezier:
                result = c.b3
    else:
        for c in p.c:
            sum += c.get_xlength()
            if sx < sum:
                result = c.calc_point_t(c.calc_xCurveParameter(
                        sx-sum+c.get_xlength()))
                break


proc calc_pointy*(p: Path, sy: float): Vec2[float] =
    ## calculate point from from path at y length parametrization sy
    var
        sum = 0.0

    if sy > p.get_ylength() or sy == p.get_ylength():
        var
            c = p.c[^1]
        case c.kind
            of ckLine:
                result = c.b
            of ckBezier:
                result = c.b3
    else:
        for c in p.c:
            sum += c.get_ylength()
            if sy < sum:
                result = c.calc_point_t(c.calc_yCurveParameter(
                        sy-sum+c.get_ylength()))
                break


proc `$`*(p: Path): string =
    result = "--- Path ---\n"
    for c in p.c:
        result &= " " & $c & "\n"
    #result &= "\n" & " arclength: " & $p.get_arclength()
    result &= "--- End ---\n"


proc max*(p: Path): Vec2[float] =
    var
        buf = vec2(0.0, 0.0)

    result = p.c[0].max()

    for c in p.c:
        buf = c.max()
        if buf[0] >= result[0]:
            result[0] = buf[0]
        if buf[1] >= result[1]:
            result[1] = buf[1]


proc max*(paths: seq[Path]): Vec2[float] =
    var
        buf = vec2(0.0, 0.0)

    result = paths[0].max()

    for p in paths:
        buf = p.max()
        if buf[0] >= result[0]:
            result[0] = buf[0]
        if buf[1] >= result[1]:
            result[1] = buf[1]


proc min*(p: Path): Vec2[float] =
    var
        buf = vec2(0.0, 0.0)

    result = p.c[0].min()

    for c in p.c:
        buf = c.min()
        if buf[0] <= result[0]:
            result[0] = buf[0]
        if buf[1] <= result[1]:
            result[1] = buf[1]


proc min*(paths: seq[Path]): Vec2[float] =
    var
        buf = vec2(0.0, 0.0)

    result = paths[0].min()

    for p in paths:
        buf = p.max()
        if buf[0] <= result[0]:
            result[0] = buf[0]
        if buf[1] <= result[1]:
            result[1] = buf[1]


proc shift*(p: var Path, v: Vec2[float]) =
    for i in 0..<len(p.c):
        p.c[i].shift(v)


proc scale*(p: var Path, v: Vec2[float]) =
    for i in 0..<len(p.c):
        p.c[i].scale(v)


if isMainModule:


    var
        b: Curve

    b = newCubicBezier()
    b.b0 = vec2(0.0, 0.0)
    b.b1 = vec2(0.0, 1.0)
    b.b2 = vec2(1.0, -1.0)
    b.b3 = vec2(1.0, 0.0)

    var
        b2: Curve

    b2 = newCubicBezier()
    b2.b0 = vec2(1.0, 0.0)
    b2.b1 = vec2(1.0, 1.0)
    b2.b2 = vec2(2.0, -1.0)
    b2.b3 = vec2(2.0, 0.0)


    let
        num = 40

    var
        path: Path
        x = newSeq[float](num+1)
        y = newSeq[float](num+1)
        x2 = newSeq[float](num+1)
        y2 = newSeq[float](num+1)
        x3 = newSeq[float](num+1)
        y3 = newSeq[float](num+1)
        v = vec2(0.0, 0.0)

    path = newPath()
    path.add(b)
    path.add(b2)


    for p in 0..<(num+1):
        v = path.calc_point(float(p)/float(num)*path.get_arclength())
        x[p] = v[0]
        y[p] = v[1]

        v = path.calc_pointx(float(p)/float(num)*path.get_xlength())
        x2[p] = v[0]
        y2[p] = v[1]+0.1

        v = path.calc_pointy(float(p)/float(num)*path.get_ylength())
        x3[p] = v[0]
        y3[p] = v[1]-0.1


    let figure3 = newFigure(python = "python")
    let points6 = newScatterPlot(x, y)
    points6.colour = "orange"
    figure3.add points6
    let points7 = newScatterPlot(x2, y2)
    points7.colour = "blue"
    figure3.add points7
    let points8 = newScatterPlot(x3, y3)
    points8.colour = "green"
    figure3.add points8
    figure3.save("./beziertest3.png")

    path.shift(vec2(2.0, 2.0))
    echo(path)
    path.scale(vec2(2.0, 2.0))
    echo(path)
    echo(path.min())
    echo(path.max())
