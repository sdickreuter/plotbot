import glm
import math
import bezier
import strutils
import matplotnim
import parsesvg
import coordtransform




let
  num = 20

var 
  x = newSeq[float](num+1)
  y = newSeq[float](num+1)
  x2 = newSeq[float](num+1)
  y2 = newSeq[float](num+1)
  v,r = vec2(0.0,0.0)
  paths: seq[Path]


paths = parsesvg("./Zeichnung.svg")


echo("Not transformed:")

echo(paths[0])
echo(paths[1])

paths[0].transform_path()
paths[1].transform_path()

echo("Transformed:")

echo(paths[0])
echo(paths[1])


var 
  buf = 0.0

for p in 0..<(num+1):
    # v = paths[0].calc_point(float(p)/float(num)*paths[0].get_arclength())
    # r = xy_to_ab(v)
    # x[p] = float(p)
    # y[p] = r[0]
    # x2[p] = float(p)
    # y2[p] = r[1]
    # echo(r[1]-buf)
    # buf = r[1]

    v = paths[0].calc_point(float(p)/float(num)*paths[0].get_arclength())
    v = ab_to_xy(v)
    x[p] = v[0]
    y[p] = v[1]

    v = paths[1].calc_point(float(p)/float(num)*paths[1].get_arclength())
    v = ab_to_xy(v)
    x2[p] = v[0]
    y2[p] = v[1]


let figure = newFigure(python="python")
let points = newScatterPlot(x, y)
points.colour = "orange"
figure.add points
let points2 = newScatterPlot(x2, y2)
points2.colour = "blue"
figure.add points2
figure.save("./beziertest.png")