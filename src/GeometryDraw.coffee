Snap = require "snapsvg-cjs"

class Point
  constructor : (@x, @y) ->

  copy : -> new Point @x, @y

  invert : -> new Point -@x, -@y
  add : (p) -> new Point @x+p.x, @y+p.y
  subtract : (p) -> @add p.invert()
  multiply : (r) -> new Point @x*r, @y*r

  length : -> (@x**2 + @y**2)**.5
  distance : (p) -> @subtract(p).length()
  unit : -> @multiply 1/@length()
  toLength : (r) -> @unit().multiply(r)

  angle : (p, fulcrum) ->
    Snap.angle @x, @y, p.x, p.y, fulcrum?.x, fulcrum?.y

  innerAngle : (p, fulcrum) ->
    innerAngle = (Math.round 180+(fulcrum.angle p)-(@angle fulcrum))%%360
    innerAngle
    # if innerAngle > 0 then innerAngle else innerAngle + 360

  rotate : (phi, fulcrum) ->
    matrix = (new Snap.Matrix()).rotate(phi, fulcrum.x, fulcrum.y)
    new Point matrix.x(@x, @y), matrix.y(@x, @y)

class Line
  constructor : (@p1, @p2) ->
    @unit = @p2.subtract(@p1).unit()
    unless @p1.x is @p2.x
      @slope = (@p2.y-@p1.y)/(@p2.x-@p1.x)
      unless @slope is 0
        @normal = (new Point 1, -1/@slope).toLength 1
      else
        @normal = new Point 0, 1
    else
      @isVertical = true
      @normal = new Point 1, 0
    @length = @p1.distance @p2
    @angle = @p1.angle @p2
    @pathString = "M#{@p1.x} #{@p1.y}L#{@p2.x} #{@p2.y}"

  rotate : (phi, fulcrum) ->
    new Line (p1.rotate phi, fulcrum), (p2.rotate phi, fulcrum)

  extend : ->
    p1 = @p1.subtract(@unit.multiply 1000)
    p2 = @p2.add(@unit.multiply 1000)
    new Line p1, p2

  extend1 : (gap = 0, length = 1000) ->
    p2 = @p1.subtract(@unit.multiply gap)
    p1 = p2.subtract(@unit.multiply length-gap)
    new Line p1, p2

  extend2 : (gap = 0, length = 1000) ->
    p1 = @p2.add(@unit.multiply gap)
    p2 = p1.add(@unit.multiply length-gap)
    new Line p1, p2

class GeometryDraw
  constructor : (id) ->
    @paper = Snap "##{id}"

  lineLabel : (p1, p2, labelText) ->
    mid = p1.add(p2).multiply(.5)
    yOffset = -3
    angle = p1.angle(p2)
    if 90< angle < 270
      angle += 180
      yOffset = 11
    text = @paper
      .text(mid.x, mid.y, labelText)
      .attr
        "text-anchor": "middle"
        "font-size" : 11
        transform : "translate(0 #{yOffset})"
    labelGroup = @paper.g text
    labelGroup.attr
      transform : "rotate(#{angle} #{mid.x} #{mid.y})"
    { text }

  labeledLine : (p1, p2, text) ->
    line = @paper
      .line p1.x, p1.y, p2.x, p2.y
      .attr
        stroke : "black"
        strokeWidth : 1
    lineLabel = @lineLabel p1, p2, text
    { line, lineLabel }

  labeledAngle : (p1, p2, fulcrum, pointLabelText, angleLabelText) ->
    radius = 20
    angle = p1.angle p2, fulcrum
    innerAngle = p1.innerAngle p2, fulcrum
    angleLabelText ?= "#{innerAngle}°"
    largeArcFlag = if (innerAngle) < 180 then 0 else 1
    arcEndPoint = (p) ->
      p.subtract(fulcrum).toLength(radius).add(fulcrum)
    startPoint = arcEndPoint p1
    endPoint = arcEndPoint p2
    labelOffsetVector =
      startPoint
        .add(endPoint).multiply(.5)
        .subtract(fulcrum)
        .toLength if largeArcFlag then -1 else 1
    adjust = switch
      when innerAngle < 60 then .7
      when innerAngle < 120 then .5 + (120-innerAngle)/60*.2
      else .5
    angleLabelAnchor =fulcrum.add labelOffsetVector.multiply(radius*adjust)
    pointLabelAnchor= fulcrum.subtract labelOffsetVector.multiply(radius*.5)
    @paper.path "M#{(arcEndPoint p1).x} #{(arcEndPoint p1).y}\
      A #{radius}, #{radius} 0 #{largeArcFlag},1 \
      #{(arcEndPoint p2).x},#{(arcEndPoint p2).y}"
      .attr "stroke" : "#000", "stroke-width" : 1, "fill" : "none"
    @paper.text  angleLabelAnchor.x, angleLabelAnchor.y+4, angleLabelText
      .attr
        "font-size" : 9
        "text-anchor" : "middle"
    if pointLabelText?
      @paper.text pointLabelAnchor.x, pointLabelAnchor.y+5, pointLabelText
        .attr
          "font-size" : 14
          "text-anchor" : "middle"

  normal : (lStart, lEnd, p, text) ->
    line = new Line lStart, lEnd
    normalLine = (new Line p, p.add(line.normal)).extend()
    line1 = line.extend1()
    line2 = line.extend2()
    anchor = (Snap.path.intersection line.pathString, normalLine.pathString)[0]
    if anchor?
      anchorPoint = new Point anchor.x, anchor.y
    else
      anchor = (Snap.path.intersection line1.pathString,
        normalLine.pathString)[0]
      if anchor?
        anchorPoint = new Point anchor.x, anchor.y
        extension = line.extend1 2, lStart.distance(anchorPoint)+4
      else
        line2 = line.extend2()
        anchor = (Snap.path.intersection line2.pathString,
          normalLine.pathString)[0]
        if anchor?
          anchorPoint = new Point anchor.x, anchor.y
          extension = line.extend2 2, lEnd.distance(anchorPoint)+4
        else
          throw new Errow "normal does not intersect with line"
    if extension?
      extensionLine = @paper.line extension.p1.x, extension.p1.y,
        extension.p2.x, extension.p2.y
      extensionLine.attr stroke : "silver"
    labeledLine = @labeledLine anchorPoint, p, text
    { labeledLine }

  labledPolygon : (lines) ->
    for line, i in lines
      prevLine = if i is 0 then lines[-1..][0] else lines[i-1]
      nextLine = if i < lines.length-1 then lines[i+1] else lines[0]
      @labeledLine line.startPoint, nextLine.startPoint,
        line.lineLabelText
      @labeledAngle prevLine.startPoint, nextLine.startPoint,
        line.startPoint,
        line.pointLabelText, line.angleLabelText

exports.GeometryDraw = GeometryDraw

class TestSetup3
  constructor : ->
  getViews : ->
    [3..26].map (e) ->
      key : e
      id : "drawing-#{e}"
      title : "Drawing #{e}"
      width : "200"
      height : "200"
      renderDrawing : (s) ->
        center = new Point 100, 100
        lines = [1..e].map (i) ->
          startPoint : (new Point 100, 180).rotate -i*360/e, center
          lineLabelText : " abcdefghijklmnopqrstuvwxyz".split("")[i]
          pointLabelText : " ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")[i]
        s.labledPolygon lines
        # lines.forEach (line) ->
        #   s.paper.circle line.startPoint.x, line.startPoint.y, 3
        #     .attr fill : "blue"


exports.TestSetup3 = TestSetup3

class TestSetup2
  constructor : ->
  getViews : ->
    [0..10].map (e) ->
      key : e
      id : "drawing-#{e}"
      title : "Drawing #{e}"
      width : "200"
      height : "200"
      renderDrawing : (s) ->
        paper = s.paper
        p = new Point 100, 10
        lStart = new Point 80, 100
        lEnd = new Point 120, 50+e*10
        line = s.labeledLine lStart, lEnd, "g"
        normal = s.normal lStart, lEnd, p, "h"
        # normal.labeledLine.lineLabel.text.attr stroke : "red"

exports.TestSetup2 = TestSetup2

class TestSetup
  constructor : ->
  getViews : ->
    [0..359].map (e) ->
      key : e
      id : "drawing-#{e}"
      title : "Drawing #{e}"
      width : "200"
      height : "200"
      renderDrawing : (s) ->
        phi1 = Math.round e * .2
        phi2 = e
        origin = new Point 100, 100
        p1 = (new Point 190, 100).rotate phi1, origin
        p2 = (new Point 190, 100).rotate phi2, origin
        alpha = Math.round(p1.angle p2, origin)
        testLine1 = s.labeledLine p1, origin, "#{phi1}°"
        testLine2 = s.labeledLine origin, p2, "#{phi2}° #{alpha}°"
        testLine1.line.attr stroke : "blue"
        testLine1.lineLabel.text.attr stroke : "blue"
        testLine2.line.attr stroke : "red"
        testLine2.lineLabel.text.attr stroke : "red"
        s.paper.circle origin.x, origin.y, 3
          .attr
            fill : "black"
        s.paper.circle p1.x, p1.y, 3
          .attr
            fill : "blue"
        s.paper.circle p2.x, p2.y, 3
          .attr
            fill : "red"
        s.labeledAngle p1, p2, origin, "A"

exports.TestSetup = TestSetup
