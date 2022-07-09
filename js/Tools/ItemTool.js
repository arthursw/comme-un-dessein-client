// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool'], function(P, R, Utils, Tool) {
    var ItemTool;
    ItemTool = (function(superClass) {
      extend(ItemTool, superClass);

      function ItemTool(Item) {
        this.Item = Item;
        ItemTool.__super__.constructor.call(this, true);
        return;
      }

      ItemTool.prototype.updateParameters = function() {};

      ItemTool.prototype.select = function(deselectItems, updateParameters) {
        if (deselectItems == null) {
          deselectItems = true;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        ItemTool.__super__.select.apply(this, arguments);
      };

      ItemTool.prototype.begin = function(event, from) {
        var point;
        if (from == null) {
          from = R.me;
        }
        point = event.point;
        R.tools.select.deselectAll();
        R.currentPaths[from] = new P.Path.Rectangle(point, point);
        R.currentPaths[from].name = 'div tool rectangle';
        R.currentPaths[from].dashArray = [4, 10];
        R.currentPaths[from].strokeColor = 'black';
        R.view.selectionLayer.addChild(R.currentPaths[from]);
        if ((R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "begin",
            "arguments": [event, R.me, R.currentPaths[from].data]
          });
        }
      };

      ItemTool.prototype.update = function(event, from) {
        var bounds, point;
        if (from == null) {
          from = R.me;
        }
        point = event.point;
        R.currentPaths[from].segments[2].point = point;
        R.currentPaths[from].segments[1].point.x = point.x;
        R.currentPaths[from].segments[3].point.y = point.y;
        R.currentPaths[from].fillColor = null;
        bounds = R.currentPaths[from].bounds;
        if (R.view.grid.rectangleOverlapsTwoPlanets(bounds)) {
          R.currentPaths[from].fillColor = 'red';
        }
        if ((R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "update",
            "arguments": [event, R.me]
          });
        }
      };

      ItemTool.prototype.end = function(event, from) {
        var bounds, point;
        if (from == null) {
          from = R.me;
        }
        if (from !== R.me) {
          R.currentPaths[from].remove();
          delete R.currentPaths[from];
          return false;
        }
        point = event.point;
        R.currentPaths[from].remove();
        bounds = R.currentPaths[from].bounds;
        if (R.view.grid.rectangleOverlapsTwoPlanets(bounds)) {
          R.alertManager.alert('Your item overlaps with two planets', 'error');
          return false;
        }
        if (R.currentPaths[from].bounds.area < 100) {
          R.currentPaths[from].width = 10;
          R.currentPaths[from].height = 10;
        }
        if ((R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "end",
            "arguments": [event, R.me]
          });
        }
        return true;
      };

      return ItemTool;

    })(Tool);
    R.Tools.Item = ItemTool;
    return ItemTool;
  });

}).call(this);
