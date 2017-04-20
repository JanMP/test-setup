SVG = require "svg.js"

class Point
  constructor : (@x, @y) ->
  copy : -> new Point @x, @y
  subtract : (p) ->
    @x -= p.x
    @y -= p.y
    this
  multiply : (n) ->
    @x *= n
    @y *= n
    this
  distance : (point) ->
    ((@x-point.x)**2 + (@y-point.y)**2)**.5
  length : ->
    @distance(new Point 0, 0)
  normalize : ->
    @multiply 1/@length()
  angle : (origin, otherPoint) ->
    if otherPoint?
      Math.abs((otherPoint.angle origin) - @angle origin)
    else
      Math.atan2((@y-origin.y),(@x-origin.x))*180/Math.PI
  angle1 : (origin, otherPoint) ->
    if otherPoint?
      Math.abs((otherPoint.angle origin) - @angle origin)
    else
      Math.atan((@y-origin.y)/(@x-origin.x))*180/Math.PI
  translate : (v) ->
    @x += v.x
    @y += v.y
    this
  rotate : (phiDeg, fulcrum) ->
    phiRad = phiDeg*Math.PI/180
    fulcrum ?= new Point 0, 0
    newX = fulcrum.x + Math.cos(phiRad) * (@x - fulcrum.x) -
      Math.sin(phiRad) * (@y - fulcrum.y)
    newY = fulcrum.y + Math.sin(phiRad) * (@x - fulcrum.x) +
      Math.cos(phiRad) * (@y - fulcrum.y)
    @x = newX
    @y = newY
    this

exports.Point = Point


class GeoDraw
  constructor : (@selector, @width, @height) ->
    @draw = SVG(@selector).size @width, @height

  clear : -> @draw.clear()

  labeledLine : (p1, p2, labelText) ->
    midX = (p1.x+p2.x)/2
    midY = (p1.y+p2.y)/2
    @draw.line p1.x, p1.y, p2.x, p2.y
      .stroke width : 1
    yOffset = if p2.x > p1.x then -3 else -18
    label = @draw.group()
    label.text labelText
      .attr "x", midX
      .attr "y", midY
      .attr "text-anchor" , "middle"
      .attr "font-size", 11
      .attr "transform" , "translate(0 #{yOffset})"
    label.attr "transform",
      "rotate(#{p1.angle1 p2} #{midX} #{midY})"

  labeledAngle : (fulcrum, prevPoint, nextPoint,
    pointLabelText, angleLabelText) ->
    radius = 30
    arcEndPoint = (lineEndPoint) ->
      lineEndPoint
        .copy()
        .subtract(fulcrum)
        .normalize()
        .multiply(radius)
        .translate(fulcrum)
    angleLabelText ?= "#{Math.round(prevPoint.angle fulcrum, nextPoint)}°"
    startPoint = arcEndPoint prevPoint
    endPoint = arcEndPoint nextPoint
    @draw.path "M#{startPoint.x} #{startPoint.y}\
      A #{radius}, #{radius} 0 0,1 #{endPoint.x},#{endPoint.y}"
      .attr "stroke" : "#000", "stroke-width" : 1, "fill" : "none"
    angleLabelAnchor =
      startPoint
        .copy()
        .translate(
          endPoint.copy().subtract(startPoint).multiply(.5)
        )
        .subtract(fulcrum)
        .normalize()
        .multiply(radius*.7)
        .translate(fulcrum)
    @draw.text angleLabelText
      .attr
        x : angleLabelAnchor.x
        y : angleLabelAnchor.y
      .attr "text-anchor" , "middle"
      .attr "font-size", "11"
      .attr "transform", "translate(0, -11)"
    if pointLabelText?
      pointLabelAnchor =
        startPoint
          .copy()
          .translate(
            endPoint.copy().subtract(startPoint).multiply(.5)
          )
          .subtract(fulcrum)
          .normalize()
          .multiply(-11)
          .translate(fulcrum)
      @draw.text pointLabelText
        .attr
          x : pointLabelAnchor.x
          y : pointLabelAnchor.y
        .attr "text-anchor" , "middle"
        .attr "font-size", "12"
        .attr "transform", "translate(0, -12)"

  labeledPolygon : (arr) ->
    for line, i in arr
      prevLine = if i is 0 then arr[-1..][0] else arr[i-1]
      nextLine = if i < arr.length-1 then arr[i+1] else arr[0]
      @labeledLine line.startPoint, nextLine.startPoint,
        line.lineLabelText
      @labeledAngle line.startPoint,
        prevLine.startPoint, nextLine.startPoint,
        line.pointLabelText, line.angleLabelText

exports.GeoDraw = GeoDraw
