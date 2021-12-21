import glm
import math
import complex

let precision: float=1e-12

# A*t + B = 0
proc calc_root*(A, B: float): seq[float] =
  return @[-B/A]


# A*t^2 + B*t + C = 0
proc calc_root*(A, B, C: float): seq[float] =
  var
    # reduce to 1*t^2+b*t+c=0
    b = B/A
    c = C/A
    Δ = b*b - 4*c

  #echo("                A ",A,"  B ",B,"  C ",C)
  #echo("                b ",b,"  c ",c,"  Δ ",Δ)

  if abs(A) < precision:
    return calc_root(B,C)

  else:
    if Δ > 0.0:
      return @[(-b+sqrt(Δ))/2,(-b-sqrt(Δ))/2]

    elif Δ == 0.0:
      return @[-b/2]


# A*t^3 + B*t^2 + C*t + D = 0, solve with cardanian formulas
# https://de.wikipedia.org/wiki/Cardanische_Formeln
proc calc_root*(A, B, C, D: float): seq[float] =
  var
    a, b, c, p, q, Δ: float

  # reduce to t^3+a*t^2+b*t+c=0
  a = B/A
  b = C/A
  c = D/A

  # transformation t = z -a/3
  # z^3 + p*z +q = 0
  p = b-(a^2)/3
  q = 2*(a^3)/27 - a*(b/3) + c
  # calc discrimant
  Δ =  -(p/3)^3 - (q/2)^2

  if abs(A) < precision:
    return calc_root(B,C,D)

  else:

    if Δ > 0:
      return @[ -sqrt(-(4/3)*p)*cos((1/3)*arccos(-(q/2)*sqrt(-(27/(p^3))))+PI/3)-(B/(3*A)),
                 sqrt(-(4/3)*p)*cos((1/3)*arccos(-(q/2)*sqrt(-(27/(p^3)))))-(B/(3*A)),
                -sqrt(-(4/3)*p)*cos((1/3)*arccos(-(q/2)*sqrt(-(27/(p^3))))-PI/3)-(B/(3*A)) ]
    elif Δ == 0: #TODO: this case has not been checked for correctness yet
      if p == 0:
        return @[-B/(3*A)]
      else:
        return @[3*(q/p)-(B/(3*A)), ((-3*q)/(2*p))-(B/(3*A))]
    else: # Δ < 0
      var
        u = cbrt(-q/2+sqrt(-Δ))
        v = cbrt(-q/2-sqrt(-Δ))
      return @[u+v-B/(3*A)]



if isMainModule:

  echo(calc_root(1.1, -6.1, 4.1, 20.1))
  echo(calc_root(1.0, 1.0, 1.0, -1.0))
