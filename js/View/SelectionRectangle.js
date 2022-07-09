// Generated by CoffeeScript 1.10.0
(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Item', 'Items/Content', 'Items/Drawing', 'Commands/Command'], function(P, R, Utils, Tool, Item, Content, Drawing, Command) {
    var ScreenshotRectangle, SelectionRectangle, SelectionRotationRectangle;
    SelectionRectangle = (function() {
      SelectionRectangle.indexToName = {
        0: 'bottomLeft',
        1: 'left',
        2: 'topLeft',
        3: 'top',
        4: 'topRight',
        5: 'right',
        6: 'bottomRight',
        7: 'bottom'
      };

      SelectionRectangle.oppositeName = {
        'top': 'bottom',
        'bottom': 'top',
        'left': 'right',
        'right': 'left',
        'topLeft': 'bottomRight',
        'topRight': 'bottomLeft',
        'bottomRight': 'topLeft',
        'bottomLeft': 'topRight'
      };

      SelectionRectangle.cornersNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'];

      SelectionRectangle.sidesNames = ['left', 'right', 'top', 'bottom'];

      SelectionRectangle.valueFromName = function(point, name) {
        switch (name) {
          case 'left':
          case 'right':
            return point.xx;
          case 'top':
          case 'bottom':
            return point.y;
          default:
            return point;
        }
      };

      SelectionRectangle.pointFromName = function(rectangle, name) {
        switch (name) {
          case 'left':
          case 'right':
            return new P.Point(rectangle[name], rectangle.center.y);
          case 'top':
          case 'bottom':
            return new P.Point(rectangle.center.x, rectangle[name]);
          default:
            return rectangle[name];
        }
      };

      SelectionRectangle.hitOptions = {
        segments: true,
        stroke: true,
        fill: true,
        tolerance: 5
      };

      SelectionRectangle.create = function() {
        var i, item, len, ref;
        ref = R.selectedItems;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (Drawing.prototype.isPrototypeOf(item)) {
            return new SelectionRectangle(null, true);
          }
          if (!Content.prototype.isPrototypeOf(item)) {
            return new SelectionRectangle();
          }
        }
        return new SelectionRotationRectangle();
      };

      SelectionRectangle.getDelta = function(center, point, rotation) {
        var d, x, y;
        d = point.subtract(center);
        x = new P.Point(1, 0);
        y = new P.Point(0, 1);
        return new P.Point(x.rotate(rotation).dot(d), y.rotate(rotation).dot(d));
      };

      SelectionRectangle.setRectangle = function(items, previousRectangle, rectangle, rotation, update) {
        var delta, i, item, itemRectangle, len, previousCenter, scale;
        scale = new P.Point(rectangle.size.divide(previousRectangle.size));
        previousCenter = previousRectangle.center;
        for (i = 0, len = items.length; i < len; i++) {
          item = items[i];
          itemRectangle = item.rectangle.clone();
          delta = this.getDelta(previousCenter, itemRectangle.center, rotation);
          itemRectangle.center = rectangle.center.add(delta.multiply(scale).rotate(rotation));
          itemRectangle = itemRectangle.scale(scale.x, scale.y);
          item.setRectangle(itemRectangle, update);
        }
      };

      function SelectionRectangle(rectangle1, simple) {
        this.rectangle = rectangle1;
        this.simple = simple != null ? simple : false;
        this.items = this.rectangle == null ? R.selectedItems : [];
        if (this.rectangle == null) {
          this.rectangle = this.getBoundingRectangle(this.items);
        }
        this.translation = new P.Point();
        this.previousRectangle = this.rectangle.clone();
        this.transformState = null;
        this.group = new P.Group();
        this.group.name = "selection rectangle group";
        this.group.controller = this;
        this.path = new P.Path.Rectangle(this.rectangle);
        this.path.name = "selection rectangle path";
        this.path.strokeColor = R.selectionBlue;
        this.path.strokeWidth = 1;
        this.path.selected = true;
        this.path.controller = this;
        if (!this.simple) {
          this.addHandles(this.rectangle);
        }
        this.update();
        this.group.addChild(this.path);
        R.view.selectionLayer.addChild(this.group);
        this.path.pivot = this.rectangle.center;
        return;
      }

      SelectionRectangle.prototype.getBoundingRectangle = function(items) {
        var bounds, i, item, len;
        if (items.length === 0) {
          return;
        }
        bounds = items[0].getBounds();
        for (i = 0, len = items.length; i < len; i++) {
          item = items[i];
          if (bounds == null) {
            bounds = item.getBounds();
          }
          if (bounds != null) {
            bounds = bounds.unite(item.getBounds());
          }
        }
        return bounds.expand(5);
      };

      SelectionRectangle.prototype.addHandles = function(bounds) {
        this.path.insert(1, new P.Point(bounds.left, bounds.center.y));
        this.path.insert(3, new P.Point(bounds.center.x, bounds.top));
        this.path.insert(5, new P.Point(bounds.right, bounds.center.y));
        this.path.insert(7, new P.Point(bounds.center.x, bounds.bottom));
      };

      SelectionRectangle.prototype.getClosestCorner = function(point) {
        var closestCorner, cornerName, distance, i, len, minDistance, ref;
        minDistance = Infinity;
        closestCorner = '';
        ref = this.constructor.cornersNames;
        for (i = 0, len = ref.length; i < len; i++) {
          cornerName = ref[i];
          distance = this.rectangle[cornerName].getDistance(point, true);
          if (distance < minDistance) {
            closestCorner = cornerName;
            minDistance = distance;
          }
        }
        return closestCorner;
      };

      SelectionRectangle.prototype.setTransformState = function(hitResult) {
        switch (hitResult.type) {
          case 'stroke':
            this.transformState = {
              command: 'Translate',
              corner: this.getClosestCorner(hitResult.point)
            };
            break;
          case 'segment':
            this.transformState = {
              command: 'Scale',
              index: hitResult.segment.index
            };
            break;
          default:
            this.transformState = {
              command: 'Translate'
            };
        }
      };

      SelectionRectangle.prototype.hitTest = function(event) {
        var hitResult;
        if (this.simple) {
          return false;
        }
        hitResult = this.path.hitTest(event.point, this.constructor.hitOptions);
        if (hitResult == null) {
          return false;
        }
        this.beginAction(hitResult, event);
        return true;
      };

      SelectionRectangle.prototype.beginAction = function(hitResult, event) {
        this.setTransformState(hitResult);
        R.commandManager.beginAction(new Command[this.transformState.command](R.selectedItems), event);
      };

      SelectionRectangle.prototype.update = function() {
        var i, item, len, ref, visible;
        this.items = R.selectedItems;
        if (this.items.length === 0) {
          this.remove();
          return;
        }
        this.rectangle = this.getBoundingRectangle(this.items);
        this.updatePath();
        Item.updatePositionAndSizeControllers(this.rectangle.point, new paper.Point(this.rectangle.size));
        visible = true;
        ref = this.items;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (item instanceof R.Tools.Item.Item.PrecisePath) {
            visible = false;
            break;
          }
        }
        this.setVisibility(visible);
      };

      SelectionRectangle.prototype.updatePath = function() {
        var i, index, len, name, ref, ref1;
        if (this.simple) {
          index = 0;
          ref = this.constructor.cornersNames;
          for (i = 0, len = ref.length; i < len; i++) {
            name = ref[i];
            this.path.segments[index].point = this.constructor.pointFromName(this.rectangle, name);
            index++;
          }
        } else {
          ref1 = this.constructor.indexToName;
          for (index in ref1) {
            name = ref1[index];
            this.path.segments[index].point = this.constructor.pointFromName(this.rectangle, name);
          }
        }
        this.path.pivot = this.rectangle.center;
        this.path.rotation = this.rotation || 0;
      };

      SelectionRectangle.prototype.show = function() {
        this.group.visible = true;
        this.path.visible = true;
      };

      SelectionRectangle.prototype.hide = function() {
        this.group.visible = false;
        this.path.visible = false;
      };

      SelectionRectangle.prototype.setVisibility = function(show) {
        if (show) {
          this.show();
        } else {
          this.hide();
        }
      };

      SelectionRectangle.prototype.remove = function() {
        this.group.remove();
        this.rectangle = null;
        R.tools.select.selectionRectangle = null;
      };

      SelectionRectangle.prototype.translate = function(delta) {
        var i, item, len, ref;
        this.translation = this.translation.add(delta);
        this.rectangle = this.rectangle.translate(delta);
        this.path.translate(delta);
        ref = this.items;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.translate(delta, false);
        }
      };

      SelectionRectangle.prototype.snapPosition = function(event) {
        var destination;
        if (this.dragOffset == null) {
          this.dragOffset = this.rectangle.center.subtract(event.downPoint);
        }
        destination = Utils.Snap.snap2D(event.point.add(this.dragOffset));
        this.translate(destination.subtract(this.rectangle.center));
      };

      SelectionRectangle.prototype.snapEdgePosition = function(event) {
        var cornerName, destination, rectangle;
        cornerName = this.transformState.corner;
        rectangle = this.rectangle.clone();
        if (this.dragOffset == null) {
          this.dragOffset = rectangle[cornerName].subtract(event.downPoint);
        }
        destination = Utils.Snap.snap2D(event.point.add(this.dragOffset));
        rectangle.moveCorner(cornerName, destination);
        this.translate(rectangle.center.subtract(this.rectangle.center));
      };

      SelectionRectangle.prototype.updatePositionController = function() {
        var position, string;
        position = this.rectangle.topLeft;
        string = '' + position.x.toFixed(2) + ', ' + position.y.toFixed(2);
      };

      SelectionRectangle.prototype.updateSizeController = function() {
        var size, string;
        size = this.rectangle.size;
        string = '' + size.width.toFixed(2) + ', ' + size.height.toFixed(2);
      };

      SelectionRectangle.prototype.beginTranslate = function(event) {
        this.translation = new P.Point();
      };

      SelectionRectangle.prototype.updateTranslate = function(event) {
        if (Utils.Snap.getSnap() <= 1) {
          this.translate(event.delta);
        } else {
          if (this.transformState.corner != null) {
            this.snapEdgePosition(event);
          } else {
            this.snapPosition(event);
          }
        }
        this.updatePositionController();
      };

      SelectionRectangle.prototype.endTranslate = function() {
        this.dragOffset = null;
        this.updatePositionController();
        return {
          delta: this.translation
        };
      };

      SelectionRectangle.prototype.beginScale = function(event) {
        this.previousRectangle = this.rectangle.clone();
      };

      SelectionRectangle.prototype.snapPoint = function(point) {
        return Utils.Snap.snap2D(point);
      };

      SelectionRectangle.prototype.keepAspectRatio = function(event, rectangle, delta, name) {
        if (indexOf.call(this.constructor.cornersNames, name) >= 0 && rectangle.width > 0 && rectangle.height > 0 && (this.items.length > 1 || !event.modifiers.shift)) {
          if (Math.abs(delta.x / rectangle.width) > Math.abs(delta.y / rectangle.height)) {
            delta.x = Utils.sign(delta.x) * Math.abs(rectangle.width * delta.y / rectangle.height);
          } else {
            delta.y = Utils.sign(delta.y) * Math.abs(rectangle.height * delta.x / rectangle.width);
          }
        }
      };

      SelectionRectangle.prototype.moveSelectedSide = function(name, rectangle, center, delta) {
        rectangle[name] = this.constructor.valueFromName(center.add(delta), name);
      };

      SelectionRectangle.prototype.moveOppositeSide = function(name, rectangle, center, delta) {
        rectangle[this.constructor.oppositeName[name]] = this.constructor.valueFromName(center.subtract(delta), name);
      };

      SelectionRectangle.prototype.adjustPosition = function(center) {};

      SelectionRectangle.prototype.adjustPosition = function(rectangle, center) {
        rectangle.center = center.add(rectangle.center.subtract(center).rotate(this.rotation));
      };

      SelectionRectangle.prototype.cancelNegativeSize = function(rectangle, center) {
        if (rectangle.width < 0) {
          rectangle.width = Math.abs(rectangle.width);
          rectangle.center.x = center.x;
        }
        if (rectangle.height < 0) {
          rectangle.height = Math.abs(rectangle.height);
          rectangle.center.y = center.y;
        }
      };

      SelectionRectangle.prototype.updateScale = function(event) {
        var center, delta, name, point, rectangle, rotation;
        point = this.snapPoint(event.point);
        name = this.constructor.indexToName[this.transformState.index];
        rectangle = this.rectangle.clone();
        center = rectangle.center.clone();
        rotation = this.rotation || 0;
        delta = this.constructor.getDelta(center, point, rotation);
        this.keepAspectRatio(event, rectangle, delta, name);
        this.moveSelectedSide(name, rectangle, center, delta);
        if (!R.specialKey(event)) {
          this.moveOppositeSide(name, rectangle, center, delta);
        } else {
          this.adjustPosition(rectangle, center);
        }
        this.cancelNegativeSize(rectangle, center);
        this.constructor.setRectangle(this.items, this.rectangle, rectangle, rotation, false);
        this.rectangle = rectangle;
        this.updatePath();
        this.updateSizeController();
      };

      SelectionRectangle.prototype.endScale = function() {
        this.updateSizeController();
        return {
          previous: this.previousRectangle.clone(),
          "new": this.rectangle.clone(),
          rotation: this.rotation
        };
      };

      SelectionRectangle.prototype.setPosition = function(position) {
        var delta;
        delta = position.subtract(this.rectangle.topLeft);
        R.commandManager.add(Command.Translate.create(R.selectedItems, {
          delta: delta
        }), true);
      };

      SelectionRectangle.prototype.translateBy = function(delta) {
        R.commandManager.add(Command.Translate.create(R.selectedItems, {
          delta: delta
        }), true);
      };

      SelectionRectangle.prototype.setSize = function(newSize) {
        var state;
        state = {
          previous: this.rectangle,
          "new": new P.Rectangle(this.rectangle.topLeft, new P.Size(newSize)),
          rotation: this.rotation || 0
        };
        R.commandManager.add(Command.Scale.create(R.selectedItems, state), true);
      };

      return SelectionRectangle;

    })();
    SelectionRotationRectangle = (function(superClass) {
      extend(SelectionRotationRectangle, superClass);

      SelectionRotationRectangle.indexToName = {
        0: 'bottomLeft',
        1: 'left',
        2: 'topLeft',
        3: 'top',
        4: 'rotation-handle',
        5: 'top',
        6: 'topRight',
        7: 'right',
        8: 'bottomRight',
        9: 'bottom'
      };

      SelectionRotationRectangle.pointFromName = function(rectangle, name) {
        if (name === 'rotation-handle') {
          return new P.Point(rectangle.center.x, rectangle.top - 25);
        } else {
          return SelectionRotationRectangle.__super__.constructor.pointFromName.call(this, rectangle, name);
        }
      };

      function SelectionRotationRectangle() {
        this.rotation = 0;
        this.deltaRotation = 0;
        SelectionRotationRectangle.__super__.constructor.call(this);
        return;
      }

      SelectionRotationRectangle.prototype.addHandles = function(bounds) {
        SelectionRotationRectangle.__super__.addHandles.call(this, bounds);
        this.path.insert(3, new P.Point(bounds.center.x, bounds.top - 25));
        this.path.insert(3, new P.Point(bounds.center.x, bounds.top));
      };

      SelectionRotationRectangle.prototype.update = function(rotation) {
        this.items = R.selectedItems;
        if (rotation) {
          this.rotation = rotation;
        } else if (this.items.length === 1 && Content.prototype.isPrototypeOf(this.items[0])) {
          this.rotation = this.items[0].rotation;
        }
        SelectionRotationRectangle.__super__.update.call(this);
      };

      SelectionRotationRectangle.prototype.setTransformState = function(hitResult) {
        var name;
        if ((hitResult != null ? hitResult.type : void 0) === 'segment') {
          name = this.constructor.indexToName[hitResult.segment.index];
          if (name === 'rotation-handle') {
            this.transformState = {
              command: 'Rotate'
            };
            return;
          }
          if (this.items.length > 1 && indexOf.call(this.constructor.sidesNames, name) >= 0) {
            this.transformState = {
              command: 'Translate'
            };
            return;
          }
        }
        SelectionRotationRectangle.__super__.setTransformState.call(this, hitResult);
      };

      SelectionRotationRectangle.prototype.rotate = function(angle) {
        var i, item, len, ref;
        this.deltaRotation += angle;
        this.rotation += angle;
        this.path.rotate(angle);
        ref = this.items;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.rotate(angle, this.rectangle.center, false);
        }
      };

      SelectionRotationRectangle.prototype.beginRotate = function() {
        this.deltaRotation = 0;
      };

      SelectionRotationRectangle.prototype.updateRotate = function(event) {
        var angle;
        angle = event.point.subtract(this.rectangle.center).angle + 90;
        if (event.modifiers.shift || R.specialKey(event) || Utils.Snap.getSnap() > 1) {
          angle = Utils.roundToMultiple(rotation, event.modifiers.shift ? 10 : 5);
        }
        this.rotate(angle - this.rotation);
      };

      SelectionRotationRectangle.prototype.endRotate = function() {
        return {
          delta: this.deltaRotation,
          center: this.rectangle.center
        };
      };

      SelectionRotationRectangle.prototype.setRotation = function(rotation, center) {
        var delta;
        delta = {
          delta: rotation - this.rotation,
          center: center
        };
        R.commandManager.add(Command.Rotate.create(R.selectedItems, delta), true);
      };

      SelectionRotationRectangle.prototype.rotateBy = function(rotation, center) {
        var delta;
        delta = {
          delta: rotation,
          center: center
        };
        R.commandManager.add(Command.Rotate.create(R.selectedItems, delta), true);
      };

      return SelectionRotationRectangle;

    })(SelectionRectangle);
    ScreenshotRectangle = (function(superClass) {
      extend(ScreenshotRectangle, superClass);

      function ScreenshotRectangle(rectangle1, extractImage) {
        var separatorJ;
        this.rectangle = rectangle1;
        ScreenshotRectangle.__super__.constructor.call(this);
        this.drawing = new P.Path.Rectangle(this.rectangle);
        this.drawing.name = 'selection rectangle background';
        this.drawing.strokeWidth = 1;
        this.drawing.strokeColor = R.selectionBlue;
        this.drawing.controller = this;
        this.group.addChild(this.drawing);
        separatorJ = R.stageJ.find(".text-separator");
        this.buttonJ = R.templatesJ.find(".screenshot-btn").clone().insertAfter(separatorJ);
        this.buttonJ.find('.extract-btn').click(function(event) {
          var redraw;
          redraw = $(this).attr('data-click') === 'redraw-snapshot';
          extractImage(redraw);
        });
        this.updateTransform();
        this.select();
        R.tools.select.select();
        return;
      }

      ScreenshotRectangle.prototype.remove = function() {
        this.removing = true;
        ScreenshotRectangle.__super__.remove.call(this);
        this.buttonJ.remove();
        R.tools.Screenshot.selectionRectangle = null;
      };

      ScreenshotRectangle.prototype.deselect = function() {
        if (!ScreenshotRectangle.__super__.deselect.call(this)) {
          return false;
        }
        if (!this.removing) {
          this.remove();
        }
        return true;
      };

      ScreenshotRectangle.prototype.setRectangle = function(rectangle, update) {
        if (update == null) {
          update = true;
        }
        ScreenshotRectangle.__super__.setRectangle.call(this, rectangle, update);
        Utils.Rectangle.updatePathRectangle(this.drawing, rectangle);
        this.updateTransform();
      };

      ScreenshotRectangle.prototype.moveTo = function(position, update) {
        ScreenshotRectangle.__super__.moveTo.call(this, position, update);
        this.updateTransform();
      };

      ScreenshotRectangle.prototype.updateTransform = function() {
        var transfrom, viewPos;
        viewPos = P.view.projectToView(this.rectangle.center);
        transfrom = 'translate(' + viewPos.x + 'px,' + viewPos.y + 'px)';
        transfrom += 'translate(-50%, -50%)';
        this.buttonJ.css({
          'position': 'absolute',
          'transform': transfrom,
          'top': 0,
          'left': 0,
          'transform-origin': '50% 50%',
          'z-index': 999
        });
      };

      ScreenshotRectangle.prototype.update = function() {};

      return ScreenshotRectangle;

    })(SelectionRectangle);
    R.SelectionRectangle = SelectionRectangle;
    return SelectionRectangle;
  });

}).call(this);
