// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Paths/Shapes/Shape'], function(P, R, Utils, Shape) {
    var SpiralShape;
    SpiralShape = (function(superClass) {
      extend(SpiralShape, superClass);

      function SpiralShape() {
        this.onFrame = bind(this.onFrame, this);
        return SpiralShape.__super__.constructor.apply(this, arguments);
      }

      SpiralShape.Shape = P.Path.Ellipse;

      SpiralShape.category = 'Shape/Animated/Spiral';

      SpiralShape.label = 'Spiral';

      SpiralShape.description = "The spiral shape can have an intern radius, and a custom number of sides.";

      SpiralShape.iconURL = 'static/images/icons/inverted/spiral.png';

      SpiralShape.initializeParameters = function() {
        var parameters;
        parameters = SpiralShape.__super__.constructor.initializeParameters.call(this);
        if (parameters['Parameters'] == null) {
          parameters['Parameters'] = {};
        }
        parameters['Parameters'].minRadius = {
          type: 'slider',
          label: 'Minimum radius',
          min: 0,
          max: 100,
          "default": 0
        };
        parameters['Parameters'].nTurns = {
          type: 'slider',
          label: 'Number of turns',
          min: 1,
          max: 50,
          "default": 10
        };
        parameters['Parameters'].nSides = {
          type: 'slider',
          label: 'Sides',
          min: 3,
          max: 100,
          "default": 50
        };
        parameters['Parameters'].animate = {
          type: 'checkbox',
          label: 'Animate',
          "default": false
        };
        parameters['Parameters'].rotationSpeed = {
          type: 'slider',
          label: 'Rotation speed',
          min: -10,
          max: 10,
          "default": 1
        };
        return parameters;
      };

      SpiralShape.parameters = SpiralShape.initializeParameters();

      SpiralShape.createTool(SpiralShape);

      SpiralShape.prototype.initialize = function() {
        this.setAnimated(this.data.animate);
      };

      SpiralShape.prototype.createShape = function() {
        var angle, angleStep, c, hh, hw, i, j, k, radiusStepX, radiusStepY, rectangle, ref, ref1, spiralHeight, spiralWidth, step;
        this.shape = this.addPath();
        rectangle = this.rectangle;
        hw = rectangle.width / 2;
        hh = rectangle.height / 2;
        c = rectangle.center;
        angle = 0;
        angleStep = 360.0 / this.data.nSides;
        spiralWidth = hw - hw * this.data.minRadius / 100.0;
        spiralHeight = hh - hh * this.data.minRadius / 100.0;
        radiusStepX = (spiralWidth / this.data.nTurns) / this.data.nSides;
        radiusStepY = (spiralHeight / this.data.nTurns) / this.data.nSides;
        for (i = j = 0, ref = this.data.nTurns - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
          for (step = k = 0, ref1 = this.data.nSides - 1; 0 <= ref1 ? k <= ref1 : k >= ref1; step = 0 <= ref1 ? ++k : --k) {
            this.shape.add(new P.Point(c.x + hw * Math.cos(angle), c.y + hh * Math.sin(angle)));
            angle += 2.0 * Math.PI * angleStep / 360.0;
            hw -= radiusStepX;
            hh -= radiusStepY;
          }
        }
        this.shape.add(new P.Point(c.x + hw * Math.cos(angle), c.y + hh * Math.sin(angle)));
        this.shape.pivot = this.rectangle.center;
        this.shape.strokeCap = 'round';
      };

      SpiralShape.prototype.onFrame = function(event) {
        this.shape.strokeColor.hue += 1;
        this.shape.rotation += this.rotationSpeed;
      };

      return SpiralShape;

    })(Shape);
    return SpiralShape;
  });

}).call(this);

//# sourceMappingURL=SpiralShape.js.map
