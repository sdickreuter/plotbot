import glm
import curve
import streams, parsexml, strutils
import path
import parsepath

# proc parseVec2(s: string): Vec2[float] =
#   var
#     buf: seq[string]

#   echo("parseVec2 ", s)
#   result = vec2(0.0, 0.0)
#   buf = s.split(",")
#   result[0] = parseFloat(buf[0])
#   result[1] = parseFloat(buf[1])


proc parseviewbox(s: string): seq[float] =
  var
    buf: seq[string]

  result = @[]
  buf = s.split(" ")
  result.add(parseFloat(buf[0]))
  result.add(parseFloat(buf[1]))
  result.add(parseFloat(buf[2]))
  result.add(parseFloat(buf[3]))


proc parselength(s: string): float =
  var
    buf: seq[string]

  buf = s.split("cm")
  #buf = s.split("pt")
  result = parseFloat(buf[0])



proc parsesvg*(filename: string): seq[Path] =
  var
    s = newFileStream(filename, fmRead)
    xml: XmlParser
    found_data = false
    found_count = 0
    viewbox: seq[float]
    width: float
    height: float
    curves: seq[Curve]

  result = @[]

  if s == nil: quit("cannot open the file " & filename)

  open(xml, s, filename)

  while true:

    xml.next()

    if xml.kind == xmlElementStart or xml.kind == xmlElementOpen:
      if cmpIgnoreCase(xml.elementName, "svg") == 0:
        echo("found svg metadata")
        found_count = 0

        while found_count < 3:
          xml.next()
          if xml.kind == xmlElementEnd or xml.kind == xmlElementClose:
            echo("could not find metadata ...")
            break
          elif xml.kind == xmlAttribute:
            echo(xml.attrKey)
            if cmpIgnoreCase(xml.attrKey, "viewbox") == 0:
              viewbox = parseviewbox(xml.attrValue)
              echo("viewbox ", viewbox)
              found_count += 1
            elif cmpIgnoreCase(xml.attrKey, "height") == 0:
              height = parselength(xml.attrValue)
              echo("height ", height)
              found_count += 1
            elif cmpIgnoreCase(xml.attrKey, "width") == 0:
              width = parselength(xml.attrValue)
              echo("width ", width)
              found_count += 1

      elif cmpIgnoreCase(xml.elementName, "path") == 0:
        echo("found path")
        found_data = false

        while found_data == false:
          xml.next()
          if xml.kind == xmlElementEnd or xml.kind == xmlElementClose:
            echo("could not find data ...")
            break
          elif xml.kind == xmlAttribute:
            if xml.attrKey == "d":
              found_data = true
              curves = parse_path(xml.attrValue)
              if len(curves) > 0:
                result.add(Path(c: curves))
                echo("added ", len(curves), " curves")
                # for c in result[^1].c:
                #   echo(c)
              else:
                echo("skipped path with zero curves")


    elif xml.kind == xmlEof:
      break # end of file reached
    else: discard # ignore other events

  xml.close()

  # convert all paths to cubic beziers
  for i in 0..<len(result):
    result[i].convert_all_to_beziers()

  # convert to proper units
  for i in 0..<len(result):
    result[i].scale(vec2(width/viewbox[2], height/viewbox[3]))

  # # flip up/down
  for i in 0..<len(result):
    result[i].scale(vec2(1.0, -1.0))
    result[i].shift(vec2(0.0, height))



if isMainModule:

  var
    paths: seq[Path]
    x: seq[float]
    y: seq[float]
    v: Vec2[float]
    l = 0.0

  paths = parsesvg("./test15.svg")


  # shift paths to drawable area
  for i in 0..(len(paths)-1):
    #paths[i].shift(vec2(+82.0, 4.0))
    paths[i].shift(vec2(+80.0, 4.0))

  # for i in 0..<len(paths):
  #   paths[i].xy_to_ab()

  #for i in 0..<len(paths):
  #  echo(paths[i])


  for p in paths:
    while true:
      v = p.calc_point(l)
      x.add(v[0])
      y.add(v[1])
      l += 0.1
      if l > p.get_arclength():
        l = 0.0
        break

  let f = open("parsedsvg" & ".csv", fmWrite)
  for i in 0..<len(x):
    f.writeLine( $(x[i]) & ", " & $(y[i]))
  f.close()

  x = newSeq[float]()
  y = newSeq[float]()

  for p in paths:
    for c in p.c:
      x.add(c.b0[0])
      y.add(c.b0[1])
      x.add(c.b1[0])
      y.add(c.b1[1])
      x.add(c.b2[0])
      y.add(c.b2[1])
      x.add(c.b3[0])
      y.add(c.b3[1])


  let f2 = open("svgpoints" & ".csv", fmWrite)
  for i in 0..<len(x):
    f2.writeLine( $(x[i]) & ", " & $(y[i]))
  f2.close()