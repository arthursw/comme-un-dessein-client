// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Paths/PrecisePaths/SpeedPaths/SpeedPath'], function(P, R, Utils, SpeedPath) {
    var GridPath;
    GridPath = (function(superClass) {
      extend(GridPath, superClass);

      function GridPath() {
        return GridPath.__super__.constructor.apply(this, arguments);
      }

      GridPath.label = 'Grid path';

      GridPath.description = "Draws a grid along the path, the thickness of the grid being function of the speed of the drawing.";

      GridPath.initializeParameters = function() {
        var parameters;
        parameters = GridPath.__super__.constructor.initializeParameters.call(this);
        if (parameters['Parameters'] == null) {
          parameters['Parameters'] = {};
        }
        parameters['Parameters'].step = {
          type: 'slider',
          label: 'Step',
          min: 5,
          max: 100,
          "default": 5,
          simplified: 20,
          step: 1
        };
        parameters['Parameters'].minWidth = {
          type: 'slider',
          label: 'Min width',
          min: 1,
          max: 100,
          "default": 5
        };
        parameters['Parameters'].maxWidth = {
          type: 'slider',
          label: 'Max width',
          min: 1,
          max: 250,
          "default": 200
        };
        parameters['Parameters'].minSpeed = {
          type: 'slider',
          label: 'Min speed',
          min: 1,
          max: 250,
          "default": 1
        };
        parameters['Parameters'].maxSpeed = {
          type: 'slider',
          label: 'Max speed',
          min: 1,
          max: 250,
          "default": 200
        };
        parameters['Parameters'].nLines = {
          type: 'slider',
          label: 'N lines',
          min: 1,
          max: 5,
          "default": 2,
          simplified: 2,
          step: 1
        };
        parameters['Parameters'].symmetric = {
          type: 'dropdown',
          label: 'Symmetry',
          values: ['symmetric', 'top', 'bottom'],
          "default": 'top'
        };
        parameters['Parameters'].speedForWidth = {
          type: 'checkbox',
          label: 'Speed for width',
          "default": true
        };
        parameters['Parameters'].speedForLength = {
          type: 'checkbox',
          label: 'Speed for length',
          "default": false
        };
        parameters['Parameters'].orthoLines = {
          type: 'checkbox',
          label: 'Orthogonal lines',
          "default": true
        };
        parameters['Parameters'].lengthLines = {
          type: 'checkbox',
          label: 'Length lines',
          "default": true
        };
        return parameters;
      };

      GridPath.parameters = GridPath.initializeParameters();

      GridPath.createTool(GridPath);

      GridPath.prototype.beginDraw = function() {
        var i, j, nLines, ref;
        this.initializeDrawing(false);
        if (this.data.lengthLines) {
          this.lines = [];
          nLines = this.data.nLines;
          if (this.data.symmetric === 'symmetric') {
            nLines *= 2;
          }
          for (i = j = 1, ref = nLines; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
            this.lines.push(this.addPath());
          }
        }
        this.lastOffset = 0;
      };

      GridPath.prototype.updateDraw = function(offset, step) {
        var addPoint, midOffset, speed, stepOffset;
        if (!step) {
          return;
        }
        speed = this.speedAt(offset);
        addPoint = (function(_this) {
          return function(offset, speed) {
            var delta, divisor, i, j, k, l, len, len1, len2, line, normal, path, point, ref, ref1, ref2, width;
            point = _this.controlPath.getPointAt(offset);
            normal = _this.controlPath.getNormalAt(offset).normalize();
            if (_this.data.speedForWidth) {
              width = _this.data.minWidth + (_this.data.maxWidth - _this.data.minWidth) * speed / _this.constructor.maxSpeed;
            } else {
              width = _this.data.minWidth;
            }
            if (_this.data.lengthLines) {
              divisor = _this.data.nLines > 1 ? _this.data.nLines - 1 : 1;
              if (_this.data.symmetric === 'symmetric') {
                ref = _this.lines;
                for (i = j = 0, len = ref.length; j < len; i = j += 2) {
                  line = ref[i];
                  _this.lines[i + 0].add(point.add(normal.multiply(i * width * 0.5 / divisor)));
                  _this.lines[i + 1].add(point.add(normal.multiply(-i * width * 0.5 / divisor)));
                }
              } else {
                if (_this.data.symmetric === 'top') {
                  ref1 = _this.lines;
                  for (i = k = 0, len1 = ref1.length; k < len1; i = ++k) {
                    line = ref1[i];
                    line.add(point.add(normal.multiply(i * width / divisor)));
                  }
                } else if (_this.data.symmetric === 'bottom') {
                  ref2 = _this.lines;
                  for (i = l = 0, len2 = ref2.length; l < len2; i = ++l) {
                    line = ref2[i];
                    line.add(point.add(normal.multiply(-i * width / divisor)));
                  }
                }
              }
            }
            if (_this.data.orthoLines) {
              path = _this.addPath();
              delta = normal.multiply(width);
              switch (_this.data.symmetric) {
                case 'symmetric':
                  path.add(point.add(delta));
                  path.add(point.subtract(delta));
                  break;
                case 'top':
                  path.add(point.add(delta));
                  path.add(point);
                  break;
                case 'bottom':
                  path.add(point.subtract(delta));
                  path.add(point);
              }
            }
          };
        })(this);
        if (!this.data.speedForLength) {
          addPoint(offset, speed);
        } else {
          speed = this.data.minSpeed + (speed / this.constructor.maxSpeed) * (this.data.maxSpeed - this.data.minSpeed);
          stepOffset = offset - this.lastOffset;
          if (stepOffset > speed) {
            midOffset = (offset + this.lastOffset) / 2;
            addPoint(midOffset, speed);
            this.lastOffset = offset;
          }
        }
      };

      GridPath.prototype.endDraw = function() {};

      return GridPath;

    })(SpeedPath);
    return GridPath;
  });

}).call(this);

//# sourceMappingURL=GridPath.js.map
