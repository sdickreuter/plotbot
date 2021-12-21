import math
import sequtils
import algorithm


# from https://github.com/jlp765/seqmath:
#
# The MIT License (MIT)
#
# Copyright (c) 2015 jlp765
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
proc `[]`*[T](a: openArray[T], inds: seq[int]): seq[T] {.inline.} =
  ## given two openArrays, return a sequence of all elements whose indices
  ## are given in 'inds'
  ## inputs:
  ##    a: seq[T] = the sequence from which we take values
  ##    inds: openArray[int] = the array which contains the indices for the
  ##         arrays, which we take from 'array'
  ## outputs:
  ##    seq[T] = a sequence of all elements s.t. array[ind] in numpy indexing
  result = newSeq[T](inds.len)
  for i, ind in inds:
    result[i] = a[ind]


# funnction for adding a number to all elements of an array
proc `+`*[T](a: openArray[T], b: T): seq[T] {.inline.} =
  result = newSeq[T](a.len)
  for i in 0..<a.len:
    result[i] = a[i] + b


# from https://stackoverflow.com/q/36831528
proc argsort*[T](a : T) : seq[int] =
  result = toSeq(0..a.len - 1)
  sort(result, proc (i, j: int): int = cmp(a[i], a[j]))


proc cos_peak*(t, a, t0, width: float): float =
  if (t > (t0-width/2)) and (t < (t0+width/2)):
    result = a*(cos(2*PI*(t-t0)*(1.0/width))+1.0)/2.0
  else:
    result = 0.0


proc gauß_peak*(t, a, t0, width: float): float =
  result = a*(sqrt(1/(2*PI*width^2))*exp(-(t-t0)^2/(2*width^2)))


proc tri_peak*(t, a, t0, width: float): float =
  if (t < (t0+width/2)) and (t > (t0-width/2)):
    if t < t0:
      result = a*(2/(width))*(t-t0)+a
    elif t > t0:
      result = -a*(2/(width))*(t-t0)+a
    elif t == t0:
      result = a
  else:
    result = 0.0


proc quad_peak*(t, a, t0, width: float): float =
  if (t < (t0+width/2)) and (t > (t0-width/2)):
    if t < t0:
      result = a/((width/2)^2) * (t-t0)^2 + 2*a/(width/2) * (t-t0) + a
    elif t > t0:
      result = a/((width/2)^2) * (t-t0)^2 - 2*a/(width/2) * (t-t0) + a
    elif t == t0:
      result = a
  else:
    result = 0.0


# function to normalize number to an interval and limit it to this interval
proc limit_and_normalize*(x, minval, maxval: float): float =
  result = x
  result -= minval
  result /= maxval
  if result < 0.0:
    result = 0.0
  elif result > 1.0:
    result = 1.0
