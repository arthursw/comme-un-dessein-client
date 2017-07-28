// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Lock', 'Items/Drawing', 'Commands/Command', 'View/SelectionRectangle'], function(P, R, Utils, Tool, Lock, Drawing, Command, SelectionRectangle) {
    var SelectTool;
    SelectTool = (function(superClass) {
      extend(SelectTool, superClass);

      SelectTool.SelectionRectangle = SelectionRectangle;

      SelectTool.label = 'Select';

      SelectTool.description = '';

      SelectTool.iconURL = 'cursor.png';

      SelectTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'default'
      };

      SelectTool.drawItems = false;

      SelectTool.order = 1;

      SelectTool.hitOptions = {
        stroke: true,
        fill: true,
        handles: true,
        selected: true
      };

      function SelectTool() {
        this.updateSelectionRectangleCallback = bind(this.updateSelectionRectangleCallback, this);
        this.setSelectionRectangleVisibility = bind(this.setSelectionRectangleVisibility, this);
        SelectTool.__super__.constructor.call(this, true);
        this.selectedItem = null;
        this.selectionRectangle = null;
        return;
      }

      SelectTool.prototype.deselectAll = function(updateOptions) {
        var ref;
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (R.selectedItems.length > 0) {
          R.commandManager.add(new Command.Deselect(void 0, updateOptions), true);
          if ((ref = this.selectionRectangle) != null) {
            ref.remove();
          }
          this.selectionRectangle = null;
        }
        P.project.activeLayer.selected = false;
      };

      SelectTool.prototype.setSelectionRectangleVisibility = function(value) {
        var ref;
        if ((ref = this.selectionRectangle) != null) {
          ref.setVisibility(value);
        }
      };

      SelectTool.prototype.updateSelectionRectangle = function(rotation) {
        Utils.callNextFrame(this.updateSelectionRectangleCallback, 'updateSelectionRectangleCallback', [rotation]);
      };

      SelectTool.prototype.updateSelectionRectangleCallback = function() {
        var ref;
        if (R.selectedItems.length > 0) {
          if (this.selectionRectangle == null) {
            this.selectionRectangle = SelectionRectangle.create();
          }
          this.selectionRectangle.update();
          $(this).trigger('selectionRectangleUpdated');
        } else {
          if ((ref = this.selectionRectangle) != null) {
            ref.remove();
          }
          this.selectionRectangle = null;
        }
      };

      SelectTool.prototype.select = function(deselectItems, updateParameters) {
        if (deselectItems == null) {
          deselectItems = false;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        SelectTool.__super__.select.call(this, false, updateParameters);
      };

      SelectTool.prototype.updateParameters = function() {
        R.controllerManager.updateParametersForSelectedItems();
      };

      SelectTool.prototype.highlightItemsUnderRectangle = function(rectangle) {
        var bounds, item, itemsToHighlight, name, ref;
        itemsToHighlight = [];
        ref = R.items;
        for (name in ref) {
          item = ref[name];
          item.unhighlight();
          bounds = item.getBounds();
          if (bounds.intersects(rectangle)) {
            item.highlight();
          }
          if (rectangle.area === 0) {
            break;
          }
        }
      };

      SelectTool.prototype.unhighlightItems = function() {
        var item, name, ref;
        ref = R.items;
        for (name in ref) {
          item = ref[name];
          item.unhighlight();
        }
      };

      SelectTool.prototype.createSelectionHighlight = function(event) {
        var highlightPath, rectangle;
        rectangle = new P.Rectangle(event.downPoint, event.point);
        highlightPath = new P.Path.Rectangle(rectangle);
        highlightPath.name = 'select tool selection rectangle';
        highlightPath.strokeColor = R.selectionBlue;
        highlightPath.strokeScaling = false;
        highlightPath.dashArray = [10, 4];
        R.view.selectionLayer.addChild(highlightPath);
        R.currentPaths[R.me] = highlightPath;
        this.highlightItemsUnderRectangle(rectangle);
      };

      SelectTool.prototype.updateSelectionHighlight = function(event) {
        var rectangle;
        rectangle = new P.Rectangle(event.downPoint, event.point);
        Utils.Rectangle.updatePathRectangle(R.currentPaths[R.me], rectangle);
        this.highlightItemsUnderRectangle(rectangle);
      };

      SelectTool.prototype.populateItemsToSelect = function(itemsToSelect, locksToSelect, rectangle) {
        var item, name, ref;
        ref = R.items;
        for (name in ref) {
          item = ref[name];
          if (item.getBounds().intersects(rectangle) && item.isVisible()) {
            if (Drawing.prototype.isPrototypeOf(item)) {
              itemsToSelect.length = 0;
              itemsToSelect.push(item);
              return true;
            } else {
              itemsToSelect.push(item);
            }
          }
        }
        return false;
      };

      SelectTool.prototype.itemsAreSiblings = function(itemsToSelect) {
        var i, item, itemsAreSiblings, len, parent;
        itemsAreSiblings = true;
        parent = itemsToSelect[0].group.parent;
        for (i = 0, len = itemsToSelect.length; i < len; i++) {
          item = itemsToSelect[i];
          if (item.group.parent !== parent) {
            itemsAreSiblings = false;
            break;
          }
        }
        return itemsAreSiblings;
      };

      SelectTool.prototype.removeLocksChildren = function(itemsToSelect, locksToSelect) {
        var child, i, j, len, len1, lock, ref;
        for (i = 0, len = locksToSelect.length; i < len; i++) {
          lock = locksToSelect[i];
          ref = lock.children();
          for (j = 0, len1 = ref.length; j < len1; j++) {
            child = ref[j];
            Utils.Array.remove(itemsToSelect, child);
          }
        }
      };

      SelectTool.prototype.isDrawingSelected = function() {
        var i, item, len, ref;
        ref = R.selectedItems;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (Drawing.prototype.isPrototypeOf(item)) {
            return true;
          }
        }
        return false;
      };

      SelectTool.prototype.selectItems = function(event) {
        var itemsToSelect, locksToSelect, rectangle, selectDrawing;
        rectangle = new P.Rectangle(event.downPoint, event.point);
        itemsToSelect = [];
        locksToSelect = [];
        selectDrawing = this.populateItemsToSelect(itemsToSelect, locksToSelect, rectangle);
        if (selectDrawing) {
          this.deselectAll();
        }
        if (itemsToSelect.length === 0) {
          itemsToSelect = locksToSelect;
        }
        if (itemsToSelect.length > 0) {
          if (rectangle.area === 0) {
            itemsToSelect = [itemsToSelect[0]];
          }
          R.commandManager.add(new Command.Select(itemsToSelect), true);
        }
      };

      SelectTool.prototype.begin = function(event) {
        var controller, hitResult, itemWasHit, name, path, ref, ref1, ref2;
        if (event.event.which === 2) {
          return;
        }
        itemWasHit = false;
        if (this.selectionRectangle != null) {
          itemWasHit = this.selectionRectangle.hitTest(event);
        }
        if (!itemWasHit) {
          ref = R.paths;
          for (name in ref) {
            path = ref[name];
            path.prepareHitTest();
          }
          hitResult = P.project.hitTest(event.point, this.constructor.hitOptions);
          ref1 = R.paths;
          for (name in ref1) {
            path = ref1[name];
            path.finishHitTest();
          }
          controller = hitResult != null ? hitResult.item.controller : void 0;
          if (controller != null) {
            controller.hitTest(event);
          }
          itemWasHit = controller != null;
        }
        if (!itemWasHit) {
          if (!event.event.shiftKey || this.isDrawingSelected()) {
            this.deselectAll();
          } else {
            if ((ref2 = this.selectionRectangle) != null) {
              ref2.remove();
            }
            this.selectionRectangle = null;
          }
          this.createSelectionHighlight(event);
        }
      };

      SelectTool.prototype.update = function(event) {
        if (this.selectionRectangle != null) {
          R.commandManager.updateAction(event);
        } else if (R.currentPaths[R.me] != null) {
          this.updateSelectionHighlight(event);
        }
      };

      SelectTool.prototype.end = function(event) {
        if (this.selectionRectangle != null) {
          R.commandManager.endAction(event);
        } else if (R.currentPaths[R.me] != null) {
          this.selectItems(event);
          R.currentPaths[R.me].remove();
          delete R.currentPaths[R.me];
          this.unhighlightItems();
        }
      };

      SelectTool.prototype.doubleClick = function(event) {
        var i, item, len, ref;
        ref = R.selectedItems;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (typeof item.doubleClick === "function") {
            item.doubleClick(event);
          }
        }
      };

      SelectTool.prototype.disableSnap = function() {
        return R.currentPaths[R.me] != null;
      };

      SelectTool.prototype.keyUp = function(event) {
        var delta, i, item, j, k, l, len, len1, len2, len3, len4, m, ref, ref1, ref2, ref3, ref4, ref5, selectedItems;
        if ((ref = event.key) === 'left' || ref === 'right' || ref === 'up' || ref === 'down') {
          delta = event.modifiers.shift ? 50 : event.modifiers.option ? 5 : 1;
        }
        switch (event.key) {
          case 'right':
            ref1 = R.selectedItems;
            for (i = 0, len = ref1.length; i < len; i++) {
              item = ref1[i];
              item.moveBy(new P.Point(delta, 0), true);
            }
            break;
          case 'left':
            ref2 = R.selectedItems;
            for (j = 0, len1 = ref2.length; j < len1; j++) {
              item = ref2[j];
              item.moveBy(new P.Point(-delta, 0), true);
            }
            break;
          case 'up':
            ref3 = R.selectedItems;
            for (k = 0, len2 = ref3.length; k < len2; k++) {
              item = ref3[k];
              item.moveBy(new P.Point(0, -delta), true);
            }
            break;
          case 'down':
            ref4 = R.selectedItems;
            for (l = 0, len3 = ref4.length; l < len3; l++) {
              item = ref4[l];
              item.moveBy(new P.Point(0, delta), true);
            }
            break;
          case 'escape':
            this.deselectAll();
            break;
          case 'delete':
          case 'backspace':
            selectedItems = R.selectedItems.slice();
            for (m = 0, len4 = selectedItems.length; m < len4; m++) {
              item = selectedItems[m];
              if (((ref5 = item.selectionState) != null ? ref5.segment : void 0) != null) {
                item.deletePointCommand();
              } else {
                item.deleteCommand();
              }
            }
        }
      };

      return SelectTool;

    })(Tool);
    R.Tools.Select = SelectTool;
    return SelectTool;
  });

}).call(this);
