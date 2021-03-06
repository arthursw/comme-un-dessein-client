// Generated by CoffeeScript 1.12.7
(function() {
  define(['paper', 'R'], function(P, R) {
    var CS;
    CS = {};
    CS.projectToPlanet = function(point) {
      var planet, x, y;
      planet = {};
      x = point.x / R.scale;
      planet.x = Math.floor((x + 180) / 360);
      y = point.y / R.scale;
      planet.y = Math.floor((y + 90) / 180);
      return planet;
    };
    CS.projectToPosOnPlanet = function(point, planet) {
      var pos;
      if (planet == null) {
        planet = CS.projectToPlanet(point);
      }
      pos = {};
      pos.x = point.x / R.scale - 360 * planet.x;
      pos.y = point.y / R.scale - 180 * planet.y;
      return pos;
    };
    CS.projectToPlanetJson = function(point) {
      var planet, pos;
      planet = CS.projectToPlanet(point);
      pos = CS.projectToPosOnPlanet(point, planet);
      return {
        pos: pos,
        planet: planet
      };
    };
    CS.posOnPlanetToProject = function(point, planet) {
      var x, y;
      if ((point.x == null) && (point.y == null)) {
        point = CS.arrayToPoint(point);
      }
      x = planet.x * 360 + point.x;
      y = planet.y * 180 + point.y;
      x *= R.scale;
      y *= R.scale;
      return new P.Point(x, y);
    };
    CS.arrayToPoint = function(array) {
      return new P.Point(array);
    };
    CS.pointToArray = function(point) {
      return [point.x, point.y];
    };
    CS.pointToObj = function(point) {
      return {
        x: point.x,
        y: point.y
      };
    };
    CS.getTopLeftCorner = function() {
      return P.view.viewToProject(new P.Point(0, 0));
    };
    CS.midPoint = function(p1, p2) {
      return new P.Point((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
    };
    CS.viewToProjectRectangle = function(rectangle) {
      return new P.Rectangle(P.view.viewToProject(rectangle.topLeft), P.view.viewToProject(rectangle.bottomRight));
    };
    CS.projectToViewRectangle = function(rectangle) {
      return new P.Rectangle(P.view.projectToView(rectangle.topLeft), P.view.projectToView(rectangle.bottomRight));
    };
    CS.getLimit = function() {
      var planet;
      planet = CS.projectToPlanet(CS.getTopLeftCorner());
      return CS.posOnPlanetToProject(new P.Point(-180, -90), new P.Point(planet.x + 1, planet.y + 1));
    };
    CS.boxFromRectangle = function(rectangle) {
      var brOnPlanet, planet, points, tlOnPlanet;
      planet = CS.pointToObj(CS.projectToPlanet(rectangle.topLeft));
      tlOnPlanet = CS.projectToPosOnPlanet(rectangle.topLeft, planet);
      brOnPlanet = CS.projectToPosOnPlanet(rectangle.bottomRight, planet);
      points = [];
      points.push(CS.pointToArray(tlOnPlanet));
      points.push(CS.pointToArray(CS.projectToPosOnPlanet(rectangle.topRight, planet)));
      points.push(CS.pointToArray(brOnPlanet));
      points.push(CS.pointToArray(CS.projectToPosOnPlanet(rectangle.bottomLeft, planet)));
      points.push(CS.pointToArray(tlOnPlanet));
      return {
        points: points,
        planet: CS.pointToObj(planet),
        tl: tlOnPlanet,
        br: brOnPlanet
      };
    };
    CS.rectangleFromBox = function(box) {
      var br, planet, tl;
      planet = new P.Point(box.planetX, box.planetY);
      tl = CS.posOnPlanetToProject(box.box.coordinates[0][0], planet);
      br = CS.posOnPlanetToProject(box.box.coordinates[0][2], planet);
      return new P.Rectangle(tl, br);
    };
    CS.quantizeZoom = function(zoom) {
      if (zoom < 5) {
        zoom = 1;
      } else if (zoom < 25) {
        zoom = 5;
      } else {
        zoom = 25;
      }
      return zoom;
    };
    CS.pixelsPerMm = 1;
    CS.pixelToMm = function(pixel) {
      return pixel / CS.pixelsPerMm;
    };
    CS.mmToPixel = function(mm) {
      return mm * CS.pixelsPerMm;
    };
    return CS;
  });

}).call(this);
