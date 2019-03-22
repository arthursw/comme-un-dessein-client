// Generated by CoffeeScript 1.12.7
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool'], function(P, R, Utils, Tool) {
    var GradientTool;
    GradientTool = (function(superClass) {
      extend(GradientTool, superClass);

      GradientTool.label = 'Gradient';

      GradientTool.description = '';

      GradientTool.favorite = false;

      GradientTool.category = '';

      GradientTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'default'
      };

      GradientTool.handleSize = 5;

      function GradientTool() {
        GradientTool.__super__.constructor.call(this, false);
        this.handles = [];
        this.radial = false;
        return;
      }

      GradientTool.prototype.getDefaultGradient = function(color) {
        var bounds, firstColor, gradient, secondColor;
        if (R.selectedItems.length === 1) {
          bounds = R.selectedItems[0].getBounds();
        } else {
          bounds = P.view.bounds.scale(0.25);
        }
        color = color != null ? new P.Color(color) : Utils.Array.random(R.defaultColor);
        firstColor = color.clone();
        firstColor.alpha = 0.2;
        secondColor = color.clone();
        secondColor.alpha = 0.8;
        gradient = {
          origin: bounds.topLeft,
          destination: bounds.bottomRight,
          gradient: {
            stops: [
              {
                color: 'red',
                rampPoint: 0
              }, {
                color: 'blue',
                rampPoint: 1
              }
            ],
            radial: false
          }
        };
        return gradient;
      };

      GradientTool.prototype.initialize = function(updateGradient, updateParameters) {
        var color, delta, destination, handle, i, len, location, origin, position, ref, ref1, ref2, stop, value;
        if (updateGradient == null) {
          updateGradient = true;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        value = this.controller.getValue();
        if ((value != null ? value.gradient : void 0) == null) {
          value = this.getDefaultGradient(value);
        }
        if ((ref = this.group) != null) {
          ref.remove();
        }
        this.handles = [];
        this.radial = (ref1 = value.gradient) != null ? ref1.radial : void 0;
        this.group = new P.Group();
        origin = new P.Point(value.origin);
        destination = new P.Point(value.destination);
        delta = destination.subtract(origin);
        ref2 = value.gradient.stops;
        for (i = 0, len = ref2.length; i < len; i++) {
          stop = ref2[i];
          color = new P.Color(stop.color != null ? stop.color : stop[0]);
          location = parseFloat(stop.rampPoint != null ? stop.rampPoint : stop[1]);
          position = origin.add(delta.multiply(location));
          handle = this.createHandle(position, location, color, true);
          if (location === 0) {
            this.startHandle = handle;
          }
          if (location === 1) {
            this.endHandle = handle;
          }
        }
        if (this.startHandle == null) {
          this.startHandle = this.createHandle(origin, 0, 'red');
        }
        if (this.endHandle == null) {
          this.endHandle = this.createHandle(destination, 1, 'blue');
        }
        this.line = new P.Path();
        this.line.add(this.startHandle.position);
        this.line.add(this.endHandle.position);
        this.group.addChild(this.line);
        this.line.sendToBack();
        this.line.strokeColor = R.selectionBlue;
        this.line.strokeWidth = 1;
        R.view.selectionLayer.addChild(this.group);
        this.selectHandle(this.startHandle);
        if (updateGradient) {
          this.updateGradient(updateParameters);
        }
      };

      GradientTool.prototype.select = function(deselectItems, updateParameters) {
        var ref;
        if (deselectItems == null) {
          deselectItems = true;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        if (R.selectedTool === this) {
          return;
        }
        R.previousTool = R.selectedTool;
        if ((ref = R.selectedTool) != null) {
          ref.deselect();
        }
        R.selectedTool = this;
        this.initialize(true, updateParameters);
      };

      GradientTool.prototype.remove = function() {
        var ref;
        if ((ref = this.group) != null) {
          ref.remove();
        }
        this.handles = [];
        this.startHandle = null;
        this.endHandle = null;
        this.line = null;
        this.controller = null;
      };

      GradientTool.prototype.deselect = function() {
        this.remove();
      };

      GradientTool.prototype.selectHandle = function(handle) {
        var ref;
        if ((ref = this.selectedHandle) != null) {
          ref.selected = false;
        }
        handle.selected = true;
        this.selectedHandle = handle;
        this.controller.setColor(handle.fillColor.toCSS());
      };

      GradientTool.prototype.colorChange = function(color) {
        this.selectedHandle.fillColor = color;
        this.updateGradient();
      };

      GradientTool.prototype.setRadial = function(value) {
        this.select();
        this.radial = value;
        this.updateGradient();
      };

      GradientTool.prototype.updateGradient = function(updateParameters) {
        var gradient, handle, i, len, ref, stops;
        if (updateParameters == null) {
          updateParameters = true;
        }
        if ((this.startHandle == null) || (this.endHandle == null)) {
          return;
        }
        stops = [];
        ref = this.handles;
        for (i = 0, len = ref.length; i < len; i++) {
          handle = ref[i];
          stops.push([handle.fillColor, handle.location]);
        }
        gradient = {
          origin: this.startHandle.position,
          destination: this.endHandle.position,
          gradient: {
            stops: stops,
            radial: this.radial
          }
        };
        console.log(JSON.stringify(gradient));
        if (updateParameters) {
          this.controller.onChange(gradient);
        }
      };

      GradientTool.prototype.createHandle = function(position, location, color, initialization) {
        var handle;
        if (initialization == null) {
          initialization = false;
        }
        handle = new P.Path.Circle(position, this.constructor.handleSize);
        handle.name = 'handle';
        this.group.addChild(handle);
        handle.strokeColor = R.selectionBlue;
        handle.strokeWidth = 1;
        handle.fillColor = color;
        handle.location = location;
        this.handles.push(handle);
        if (!initialization) {
          this.selectHandle(handle);
          this.updateGradient();
        }
        return handle;
      };

      GradientTool.prototype.addHandle = function(event, hitResult) {
        var offset, point;
        offset = hitResult.location.offset;
        point = this.line.getPointAt(offset);
        this.createHandle(point, offset / this.line.length, this.controller.colorInputJ.val());
      };

      GradientTool.prototype.removeHandle = function(handle) {
        if (handle === this.startHandle || handle === this.endHandle) {
          return;
        }
        Utils.Array.remove(this.handles, handle);
        handle.remove();
        this.updateGradient();
      };

      GradientTool.prototype.doubleClick = function(event) {
        var hitResult, point;
        point = P.view.viewToProject(Utils.Event.GetPoint(event));
        hitResult = this.group.hitTest(point);
        if (hitResult) {
          if (hitResult.item === this.line) {
            this.addHandle(event, hitResult);
          } else if (hitResult.item.name === 'handle') {
            this.removeHandle(hitResult.item);
          }
        }
      };

      GradientTool.prototype.begin = function(event) {
        var hitResult;
        hitResult = this.group.hitTest(event.point);
        if (hitResult) {
          if (hitResult.item.name === 'handle') {
            this.selectHandle(hitResult.item);
            this.dragging = true;
          }
        }
      };

      GradientTool.prototype.update = function(event) {
        var handle, i, len, lineLength, ref;
        if (this.dragging) {
          if (this.selectedHandle === this.startHandle || this.selectedHandle === this.endHandle) {
            this.selectedHandle.position.x += event.delta.x;
            this.selectedHandle.position.y += event.delta.y;
            this.line.firstSegment.point = this.startHandle.position;
            this.line.lastSegment.point = this.endHandle.position;
            lineLength = this.line.length;
            ref = this.handles;
            for (i = 0, len = ref.length; i < len; i++) {
              handle = ref[i];
              handle.position = this.line.getPointAt(handle.location * lineLength);
            }
          } else {
            this.selectedHandle.position = this.line.getNearestPoint(event.point);
            this.selectedHandle.location = this.line.getOffsetOf(this.selectedHandle.position) / this.line.length;
          }
          this.updateGradient();
        }
      };

      GradientTool.prototype.end = function(event) {
        this.dragging = false;
      };

      return GradientTool;

    })(Tool);
    R.Tools.Gradient = GradientTool;
    return GradientTool;
  });

}).call(this);
