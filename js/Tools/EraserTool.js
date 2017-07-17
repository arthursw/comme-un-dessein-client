// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['Tools/Tool', 'UI/Button', 'Commands/Command'], function(Tool, Button, Command) {
    var EraserTool;
    EraserTool = (function(superClass) {
      extend(EraserTool, superClass);

      EraserTool.label = 'Eraser';

      EraserTool.description = 'Erase paths';

      EraserTool.iconURL = 'eraser.png';

      EraserTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'crosshair'
      };

      EraserTool.drawItems = true;

      function EraserTool(Path, justCreated) {
        this.Path = Path;
        if (justCreated == null) {
          justCreated = false;
        }
        this.name = this.constructor.label;
        this.radius = 50;
        R.tools[this.name] = this;
        this.btnJ = R.sidebar.favoriteToolsJ.find('li[data-name="' + this.name + '"]');
        EraserTool.__super__.constructor.call(this, this.btnJ.length === 0);
        this.pathsToDelete = [];
        this.pathsToCreate = [];
        return;
      }

      EraserTool.prototype.remove = function() {
        this.btnJ.remove();
      };

      EraserTool.prototype.select = function(deselectItems, updateParameters) {
        if (deselectItems == null) {
          deselectItems = true;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        R.rasterizer.drawItems();
        EraserTool.__super__.select.apply(this, arguments);
        R.view.tool.onMouseMove = this.move;
      };

      EraserTool.prototype.updateParameters = function() {};

      EraserTool.prototype.deselect = function() {
        EraserTool.__super__.deselect.call(this);
        this.finish();
        this.circle.remove();
        this.circle = null;
        R.view.tool.onMouseMove = null;
      };

      EraserTool.prototype.isPathInCircle = function(path) {
        var circleContainsPoint, i, len, ref, segment, segmentWasFromSplit;
        ref = path.segments;
        for (i = 0, len = ref.length; i < len; i++) {
          segment = ref[i];
          segmentWasFromSplit = (segment.data != null) && segment.data.split;
          circleContainsPoint = segmentWasFromSplit || this.circle.contains(segment.point);
          if (!circleContainsPoint) {
            return false;
          }
        }
        return true;
      };

      EraserTool.prototype.erase = function() {
        var data, i, intersection, intersections, item, itemId, j, k, len, len1, len2, location, newP, p, path, paths, points, refreshRasterizer;
        refreshRasterizer = false;
        for (itemId in R.paths) {
          item = R.paths[itemId];
          if ((item.controlPath != null) && item instanceof R.Tools.Item.Item.PrecisePath && item.owner === R.me && (item.drawingId == null)) {
            if (item.getBounds().intersects(this.circle.bounds)) {
              intersections = this.circle.getCrossings(item.controlPath);
              if (intersections.length > 0) {
                paths = [item.controlPath];
                console.log(intersections);
                this.pathsToDeleteResurectors[item.id] = {
                  data: item.getDuplicateData(),
                  constructor: item.constructor
                };
                for (i = 0, len = intersections.length; i < len; i++) {
                  intersection = intersections[i];
                  for (j = 0, len1 = paths.length; j < len1; j++) {
                    p = paths[j];
                    location = p.getLocationOf(intersection.point);
                    if (location != null) {
                      console.log('split: ' + location.point);
                      newP = p.split(location);
                      p.lastSegment.handleOut = null;
                      p.lastSegment.data = {
                        split: true
                      };
                      if (newP != null) {
                        paths.push(newP);
                        newP.firstSegment.handleIn = null;
                        newP.firstSegment.data = {
                          split: true
                        };
                      }
                    }
                  }
                }
                refreshRasterizer = true;
                item.remove();
                this.pathsToDelete.push(item);
                for (k = 0, len2 = paths.length; k < len2; k++) {
                  p = paths[k];
                  if (this.isPathInCircle(p)) {
                    console.log('remove a path');
                    p.remove();
                  } else {
                    data = R.Tools.Item.Item.PrecisePath.getDataFromPath(p);
                    points = R.Tools.Item.Item.Path.pathOnPlanetFromPath(p);
                    path = new R.Tools.Item.Item.PrecisePath(Date.now(), data, null, null, points, null, R.me);
                    path.draw();
                    this.pathsToCreate.push(path);
                  }
                }
              } else {
                if (this.isPathInCircle(item.controlPath)) {
                  this.pathsToDeleteResurectors[item.id] = {
                    data: item.getDuplicateData(),
                    constructor: item.constructor
                  };
                  item.remove();
                  this.pathsToDelete.push(item);
                  refreshRasterizer = true;
                }
              }
            }
          }
        }
      };

      EraserTool.prototype.begin = function(event, from, data) {
        if (from == null) {
          from = R.me;
        }
        if (data == null) {
          data = null;
        }
        if (event.event.which === 2) {
          return;
        }
        this.circle.position = event.point;
        this.pathsToDelete = [];
        this.pathsToCreate = [];
        this.pathsToDeleteResurectors = {};
        R.rasterizer.disableRasterization();
        if ((R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "begin",
            "arguments": [event, R.me, null]
          });
        }
      };

      EraserTool.prototype.update = function(event, from) {
        if (from == null) {
          from = R.me;
        }
        console.log("update");
        this.circle.position = event.point;
        this.erase();
        if ((R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "update",
            "arguments": [event, R.me]
          });
        }
      };

      EraserTool.prototype.move = function(event) {
        var eraser;
        console.log("move");
        eraser = R.tools.eraser;
        if (eraser.circle == null) {
          eraser.circle = new P.Path.Circle(event.point, eraser.radius);
          eraser.circle.strokeWidth = 1;
          eraser.circle.strokeColor = '#2fa1d6';
          eraser.circle.strokeScaling = false;
          R.view.selectionLayer.addChild(eraser.circle);
        } else {
          eraser.circle.position = event.point;
        }
      };

      EraserTool.prototype.end = function(event, from) {
        var i, j, k, l, len, len1, len2, len3, path, pathsToCreate, pathsToDelete, pathsToDeleteResurectors, ref, ref1;
        if (from == null) {
          from = R.me;
        }
        this.circle.position = event.point;
        this.erase();
        pathsToCreate = [];
        ref = this.pathsToCreate;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          if (this.pathsToDelete.indexOf(path) < 0) {
            pathsToCreate.push(path);
          }
        }
        pathsToDelete = [];
        pathsToDeleteResurectors = {};
        ref1 = this.pathsToDelete;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          path = ref1[j];
          if (path.pk != null) {
            pathsToDelete.push(path);
            pathsToDeleteResurectors[path.id] = this.pathsToDeleteResurectors[path.id];
          }
        }
        if (pathsToDelete.length > 0) {
          R.commandManager.add(new Command.DeleteItems(pathsToDelete, pathsToDeleteResurectors), false);
        }
        if (pathsToCreate.length > 0) {
          R.commandManager.add(new Command.CreateItems(pathsToCreate), false);
        }
        for (k = 0, len2 = pathsToDelete.length; k < len2; k++) {
          path = pathsToDelete[k];
          path["delete"]();
        }
        for (l = 0, len3 = pathsToCreate.length; l < len3; l++) {
          path = pathsToCreate[l];
          path.save();
          if (path.drawing == null) {
            if (typeof path.draw === "function") {
              path.draw();
            }
          }
          if (R.rasterizer.rasterizeItems) {
            if (typeof path.rasterize === "function") {
              path.rasterize();
            }
          }
        }
        R.rasterizer.enableRasterization(false);
      };

      EraserTool.prototype.finish = function(from) {
        if (from == null) {
          from = R.me;
        }
        return true;
      };

      EraserTool.prototype.keyUp = function(event) {
        var finishingPath;
        switch (event.key) {
          case 'enter':
            if (typeof this.finish === "function") {
              this.finish();
            }
            break;
          case 'escape':
            finishingPath = typeof this.finish === "function" ? this.finish() : void 0;
            if (!finishingPath) {
              R.tools.select.deselectAll();
            }
        }
      };

      return EraserTool;

    })(Tool);
    R.Tools.Eraser = EraserTool;
    return EraserTool;
  });

}).call(this);
