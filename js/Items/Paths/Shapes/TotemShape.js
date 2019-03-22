// Generated by CoffeeScript 1.12.7
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Paths/Shapes/Shape'], function(P, R, Utils, Shape) {
    var TotemShape;
    TotemShape = (function(superClass) {
      extend(TotemShape, superClass);

      function TotemShape() {
        return TotemShape.__super__.constructor.apply(this, arguments);
      }

      TotemShape.Shape = P.Path.Rectangle;

      TotemShape.category = 'Shape/Animated/Spiral';

      TotemShape.label = 'Totem';

      TotemShape.description = "The spiral shape can have an intern radius, and a custom number of sides.";

      TotemShape.iconURL = 'static/images/icons/inverted/spiral.png';

      TotemShape.initializeParameters = function() {
        var parameters;
        parameters = TotemShape.__super__.constructor.initializeParameters.call(this);
        if (parameters['Parameters'] == null) {
          parameters['Parameters'] = {};
        }
        parameters['Parameters'].nWidth = {
          type: 'slider',
          label: 'Minimum radius',
          min: 0,
          max: 100,
          "default": 20
        };
        parameters['Parameters'].nHeight = {
          type: 'slider',
          label: 'Number of turns',
          min: 1,
          max: 150,
          "default": 60
        };
        return parameters;
      };

      TotemShape.parameters = TotemShape.initializeParameters();

      TotemShape.createTool(TotemShape);

      TotemShape.prototype.initialize = function() {};

      TotemShape.prototype.motif = function(Rectangle) {
        return this.addPath(new P.Path.Rectangle(Rectangle));
      };

      TotemShape.prototype.createShape = function() {
        var c, hh, hw, i, j, m, r, rectangle, ref, ref1, shapeWidth, x, y;
        this.shape = this.addPath();
        rectangle = this.rectangle;
        hw = rectangle.width / 2;
        hh = rectangle.height / 2;
        c = rectangle.center;
        shapeWidth = rectangle.width / this.data.nWidth;
        shapeWidth = rectangle.height / this.data.nHeight;
        for (x = i = 0, ref = this.data.nWidth; 0 <= ref ? i <= ref : i >= ref; x = 0 <= ref ? ++i : --i) {
          for (y = j = 0, ref1 = this.data.nHeight; 0 <= ref1 ? j <= ref1 : j >= ref1; y = 0 <= ref1 ? ++j : --j) {
            r = new P.Rectangle(rectangle.left + x * shapeWidth / rectangle.width, rectangle.top + y * shapeHeight / rectangle.height);
            m = this.motif(r);
            m.fillColor = 'black';
          }
        }
        this.shape.strokeCap = 'round';
      };

      return TotemShape;

    })(Shape);
    return SpiralShape;
  });

}).call(this);
