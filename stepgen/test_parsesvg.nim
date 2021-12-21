import glm
import math
import strutils
import matplotnim
import parsesvg
import path
import coordtransform

let
  num = 20

var
  x: seq[float]
  y: seq[float]

  v = vec2(0.0, 0.0)
  paths: seq[Path]


paths = parsesvg("./Zeichnung.svg")

for p in 0..<len(paths):
  #echo("before conversion   ",paths[p])
  paths[p].convert_all_to_beziers()
  echo("before transform  ", paths[p])
  paths[p].xy_to_ab()
  #echo("after transform   ",paths[p])
  paths[p].ab_to_xy()
  echo("back transform   ", paths[p])
  paths[p].xy_to_ab()


x = @[]
y = @[]

for p in 0..<len(paths):
  for i in 0..<(num+1):
    v = paths[p].calc_point(float(i)/float(num)*paths[p].get_arclength())
    v = ab_to_xy(v)
    x.add(v[0])
    y.add(v[1])

let figure = newFigure(python = "python")
let points = newScatterPlot(x, y)
points.colour = "blue"
figure.add points
figure.save("./beziertest.png")


for p in 0..<len(paths):
  paths[p].ab_to_xy()

x = @[]
y = @[]

for p in 0..<len(paths):
  for i in 0..<(num+1):
    v = paths[p].calc_point(float(i)/float(num)*paths[p].get_arclength())
    v = xy_to_ab(v)
    v = ab_to_xy(v)
    x.add(v[0])
    y.add(v[1])

let figure2 = newFigure(python = "python")
let points2 = newScatterPlot(x, y)
points2.colour = "blue"
figure2.add points2
figure2.save("./beziertest2.png")
