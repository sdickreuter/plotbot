import glm
import math
import path
import curve


let
  #al = 81.5#arm length [cm]
  al_a = 81.5#8.5 # a arm length [cm]
  al_b = 81.57#85.5 #  arm length [cm]
  fa = 80.0 # y position of rail a [cm] 
  fb = -3.0 # y position of rail b [cm] 
  zero = vec2(70.14271166700073, 41.5) # x/y pos when position on rail a/b is 0.0/0.0
  para_offset = 4.5 # [cm] offset along/parallel arm a
  ortho_offset = 3.0 # [cm] offset away from/orthogonal arm a

# proc ab_to_xy*(p: Vec2[float]): Vec2[float] =
#   var 
#     a,b,h,d : Vec2[float]
#     cl, hl : float

#   a = vec2(p[0],fa) # vector to position on arm a
#   b = vec2(p[1],fb) # vector to position on arm b

#   cl = (b-a).length #distance between a and b

#   #calculate height of triangle which is spanned by the arms
#   hl = 2*((al*al)*(al*al)+(al*al)*(cl*cl)+(cl*cl)*(al*al))-(al^4+al^4+cl^4)

#   if hl > 0:
#       # finish calculation of height
#       hl = math.sqrt(hl)/(2*cl)

#       #vector from a to b
#       d = (b-a)
#       d = d/d.length

#       # turn d around by 90°, h points to tip of triangle
#       h = vec2(d.y,-d.x)

#       # normalize h
#       h = h/h.length

#       # calculate distance to tip set as length of d
#       d *= math.sqrt(al*al - hl*hl)

#       # vector which points to the tip of the triangle
#       result = a+d+h*hl


#https://math.stackexchange.com/a/1033561
proc ab_to_xy*(p: Vec2[float]): Vec2[float] =
  var 
    a,b : Vec2[float]
    x1, x2, y1, y2, d, l, h, dx, dy : float

  a = vec2(p[0],fa) # vector to position on arm a
  b = vec2(p[1],fb) # vector to position on arm b

  dx = b[0]-a[0]
  dy = b[1]-a[1]

  d = sqrt( dx^2 + dy^2)
  l = (al_a^2 - al_b^2 + d^2) / (2.0*d) 
  h = sqrt( al_a^2 - l^2 )

  x1 = (l/d)*dx + (h/d)*dy + a[0] 
  y1 = (l/d)*dy - (h/d)*dx + a[1]

  x2 = (l/d)*dx - (h/d)*dy + a[0] 
  y2 = (l/d)*dy + (h/d)*dx + a[1]

  #echo("x1 ", x1, " x2 ", x2, " |  y1 ",y1, " y2 ",y2)
  if (x2 > x1) or (y2 > y1):
    x1 = x2
    y1 = y2

  result = vec2(x1, y1)

  # # calculate position with offset
  # var
  #   xy2a, perp: Vec2[float] # vector pointing from x/y to a

  # xy2a = a - result
  # xy2a = normalize(xy2a)

  # # get vector clockwise perpendicular to xy2a
  # perp[0] = xy2a[1]
  # perp[1] = -xy2a[0]

  # result += xy2a*para_offset
  # result += xy2a*ortho_offset


# a: point1 on line, b: point2 on line, c: centre of circle, r: radius of circle
# http://mathworld.wolfram.com/Circle-LineIntersection.html
# note: b[0] !> a[0] and b[1] !> a[1] 
# x1 = a[0]-c[0]
# y1 = a[1]-c[1]
# x2 = b[0]-c[0]
# y2 = b[1]-c[1]
proc intersect_line_circle*(a, b ,c: Vec2[float], r: float) : Vec2[float] =
  var
    dx, dy, dr, D, delta, x1,x2, y1,y2, sgndy : float
    p1, p2: Vec2[float]

  #shift circle to 0.0 by shifting points a,b. result is new points p1, p2
  p1 = a - c
  p2 = b - c

  dx = p2[0] - p1[0]
  dy = p2[1] - p1[1]
  dr = sqrt(dx*dx + dy*dy)

  D = p1[0]*p2[1] - p2[0]*p1[1]

  delta = r*r*dr*dr - D*D

  if delta >= 0:
    if dy < 0:
      sgndy = -1.0
    else:
      sgndy = 1.0

    x1 = ( D*dy + sgndy*dx*sqrt(delta) ) / (dr*dr)
    x2 = ( D*dy - sgndy*dx*sqrt(delta) ) / (dr*dr)
    
    y1 = ( -1.0*D*dx + abs(dy)*sqrt(delta) ) / (dr*dr)
    y2 = ( -1.0*D*dx - abs(dy)*sqrt(delta) ) / (dr*dr)

    #echo("x1 ", x1," y1 ", y1," | x2 ", x2," y2 ", y2)
    #echo("dx ",dx," dy ",dy," dr ",dr,"   x1: ", x1, "   x2: ", x2)
    #echo("cx ", c[0]," cy ",c[1]," x1: ", x1, "   x2: ", x2)
    #echo("p1 ", p1, " p2 ", p2, "  r: ", r)

    # choose correct solution
    # if x2 > 0:
    #   if x2 < x1:
    #     x1 = x2
    #     y1 = y2
    # if y2 > 0:
    #   if y2 < y1:
    #     x1 = x2
    #     y1 = y2
    if x2 < x1:
      x1 = x2
      y1 = y2
    if y2 < y1:
      x1 = x2
      y1 = y2

    #x = ( D*dy + dx*sqrt(delta) ) / (dr*dr)
    #y = ( D*dx + abs(dy)*sqrt(delta) ) / (dr*dr)
    result = vec2(x1+c[0], y1+c[1])
    #result = vec2(x1, y1)
  else:
    #result = (delta, vec2(0.0, 0.0)) p.
    #echo("cx ", c[0]," cy ",c[1])
    #echo("p1 ", p1, " p2 ", p2, "  r: ", r)
    echo("WARNING in coordtransform.nim: could not find intersection in proc intersect_line_circle")
    result = vec2(0.0, 0.0)


proc xy_to_ab*(c: Vec2[float]): Vec2[float] =
  var 
    a,b : Vec2[float]

  if (c[1] > fa) or (c[1]) < 0:
    echo("WARNING: Points outside of reachable drawing area!")

  var
    l1, alpha: float
    v1 : Vec2[float]

  l1 = sqrt((al_b - para_offset)^2 + ortho_offset^2)

  # vector pointing to point on rail b
  b = vec2(0.0,fb)
  b[0] = sqrt(l1^2 - (c[1]-b[1])^2)
  b[0] = c[0] + b[0]

  # vector pointing from rail b to c
  v1 = c - b
  v1 = normalize(v1)


  # rotate v1 clockwise aroung angle alpha
  alpha = arcsin(ortho_offset/l1)
  v1[0] =  cos(alpha)*v1[0] + sin(alpha)*v1[1]
  v1[1] = -sin(alpha)*v1[0] + cos(alpha)*v1[1]
   

  # adjust length
  v1 = v1* al_b

  # calculate position of joint
  v1 = v1 + b

  # calculate position on rail a
  a = vec2(0.0,fa)
  a[0] = sqrt(al_a^2 - (a[1]-v1[1])^2) 
  a[0] = v1[0] + a[0]

  a[0] = 180 - a[0]
  b[0] = 180 - b[0]


  result = vec2(a[0],b[0])



# a is b0, d is b3. b is the point on the bezier at t = 1/3, c at t=2/3
# from https://math.stackexchange.com/q/301736
proc get_cubic_bezier_from_points(a,b,c,d: Vec2[float]): Curve = 
  result = newCubicBezier()
  result.b0 = a
  result.b1 = (1/6)*( -5.0*a + 18.0*b - 9.0*c + 2.0*d )
  result.b2 = (1/6)*(  2.0*a -  9.0*b + 18.0*c - 5.0*d )
  result.b3 = d


# transform path from svg coordinate system to ab coordinate system
proc xy_to_ab*(p: var Path) =
  for i in 0..<len(p.c):
    case p.c[i].kind
      of ckLine:
        echo("WARNING in coordtransform.nim: can't transform lines, convert lines to cubic beziers before transformation!")
      of ckBezier:
        p.c[i] = get_cubic_bezier_from_points(p.c[i].b0.xy_to_ab(), p.c[i].calc_point_t(1/3).xy_to_ab()
          , p.c[i].calc_point_t(2/3).xy_to_ab(), p.c[i].b3.xy_to_ab())

  p.reset_lengths()


# transform path from ab coordinate system to svg coordinate system
proc ab_to_xy*(p: var Path) =
  for i in 0..<len(p.c):
    case p.c[i].kind
      of ckLine:
        echo("WARNING in coordtransform.nim: can't transform lines, convert lines to cubic beziers before transformation!")
      of ckBezier:
        p.c[i] = get_cubic_bezier_from_points(p.c[i].b0.ab_to_xy(), p.c[i].calc_point_t(1/3).ab_to_xy()
          , p.c[i].calc_point_t(2/3).ab_to_xy(), p.c[i].b3.ab_to_xy())

  p.reset_lengths()



if isMainModule:
  var
    a1,b1,a2,b2,v1,v2,v3,v4 : Vec2[float] 


  v1 = vec2(1.0,1.0)
  echo(v1, xy_to_ab(v1))
  v1 = vec2(1.0,2.0)
  echo(v1, xy_to_ab(v1))
  echo("")
  v1 = vec2(1.0,40.0)
  echo(v1, xy_to_ab(v1))
  v1 = vec2(1.0,41.0)
  echo(v1, xy_to_ab(v1))
  echo("")
  v1 = vec2(1.0,75.0)
  echo(v1, xy_to_ab(v1))
  v1 = vec2(1.0,76.0)
  echo(v1, xy_to_ab(v1))

  # echo("zero ",ab_to_xy(vec2(0.0,0.0)))

  # v1 = vec2(80.0,0.0)
  # v2 = vec2(0.0,65.0)
  # v3 = vec2(90.0,0.0)
  # v4 = vec2(90.0,65.0)
  
  # echo("v1 ", v1,"  v2 ", v2,"  v3 ", v3,"  v4 ", v4)
  
  # a1 = xy_to_ab(v1)
  # b1 = xy_to_ab(v2)
  # a2 = xy_to_ab(v3)
  # b2 = xy_to_ab(v4)

  # echo("a1 ", a1,"  b1 ", b1,"  a2 ", a2,"  b2 ", b2)
  # echo("a1 ", a1/0.00304,"  b1 ", b1/0.00304,"  a2 ", a2/0.00304,"  b2 ", b2/0.00304)
  
  # v1 = ab_to_xy(a1)
  # v2 = ab_to_xy(b1)
  # v3 = ab_to_xy(a2)
  # v4 = ab_to_xy(b2)
  
  # echo("v1 ", v1,"  v2 ", v2,"  v3 ", v3,"  v4 ", v4)
  
