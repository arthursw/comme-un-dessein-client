// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'i18next'], function(P, R, Utils, Tool, Button, i18next) {
    var PathTool;
    PathTool = (function(superClass) {
      extend(PathTool, superClass);

      PathTool.label = '';

      PathTool.description = '';

      PathTool.iconURL = '';

      PathTool.buttonClasses = 'displayName btn-success';

      PathTool.cursor = {
        position: {
          x: 0,
          y: 32
        },
        name: 'crosshair',
        icon: R.style === 'line' ? 'mouse_draw' : null
      };

      PathTool.drawItems = true;

      PathTool.emitSocket = false;

      PathTool.maxDraftSize = 1000;

      PathTool.computeDraftBounds = function(paths) {
        var ref;
        if (paths == null) {
          paths = null;
        }
        return (ref = R.Drawing.getDraft()) != null ? ref.getBounds() : void 0;
      };

      PathTool.draftIsTooBig = function(paths, tolerance) {
        var draftBounds;
        if (paths == null) {
          paths = null;
        }
        if (tolerance == null) {
          tolerance = 0;
        }
        draftBounds = this.computeDraftBounds(paths);
        return this.draftBoundsIsTooBig(draftBounds, tolerance);
      };

      PathTool.draftBoundsIsTooBig = function(draftBounds, tolerance) {
        if (tolerance == null) {
          tolerance = 0;
        }
        return (draftBounds != null) && draftBounds.width > this.maxDraftSize - tolerance || draftBounds.height > this.maxDraftSize - tolerance;
      };

      PathTool.displayDraftIsTooBigError = function() {
        R.alertManager.alert('Your drawing is too big', 'error');
      };

      function PathTool(Path, justCreated) {
        this.Path = Path;
        if (justCreated == null) {
          justCreated = false;
        }
        this.name = this.Path.label;
        this.constructor.label = this.name;
        if (this.Path.description) {
          this.constructor.description = this.Path.rdescription;
        }
        if (this.Path.iconURL) {
          this.constructor.iconURL = this.Path.iconURL;
        }
        if (this.Path.category) {
          this.constructor.category = this.Path.category;
        }
        if (this.Path.cursor) {
          this.constructor.cursor = this.Path.cursor;
        }
        if (justCreated && (R.tools[this.name] != null)) {
          g[this.Path.constructor.name] = this.Path;
          R.tools[this.name].remove();
          delete R.tools[this.name];
          R.lastPathCreated = this.Path;
        }
        R.tools[this.name] = this;
        this.btnJ = R.sidebar.favoriteToolsJ.find('li[data-name="' + this.name + '"]');
        PathTool.__super__.constructor.call(this, this.btnJ.length === 0);
        if (justCreated) {
          this.select();
        }
        if (R.userAuthenticated == null) {
          R.toolManager.enableDrawingButton(false);
        }
        return;
      }

      PathTool.prototype.remove = function() {
        this.btnJ.remove();
      };

      PathTool.prototype.select = function(deselectItems, updateParameters, forceSelect, fromMiddleMouseButton) {
        var bounds, draft;
        if (deselectItems == null) {
          deselectItems = true;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        if (forceSelect == null) {
          forceSelect = false;
        }
        if (fromMiddleMouseButton == null) {
          fromMiddleMouseButton = false;
        }
        if (!R.userAuthenticated && !forceSelect) {
          R.alertManager.alert('Log in before drawing', 'info');
          return;
        }
        this.showDraftLimits();
        PathTool.__super__.select.call(this, deselectItems, updateParameters, fromMiddleMouseButton);
        R.view.tool.onMouseMove = this.move;
        R.toolManager.enterDrawingMode();
        if (!fromMiddleMouseButton) {
          draft = R.Drawing.getDraft();
          if (draft != null) {
            bounds = draft.getBounds();
            if (bounds != null) {
              R.view.fitRectangle(bounds, false, P.view.zoom < 1 ? 1 : P.view.zoom);
            }
          }
        }
        if (P.view.zoom < 1) {
          R.alertManager.alert('You can zoom in to draw more easily', 'info');
        }
      };

      PathTool.prototype.updateParameters = function() {
        R.controllerManager.setSelectedTool(this.Path);
      };

      PathTool.prototype.deselect = function() {
        PathTool.__super__.deselect.call(this);
        this.finish();
        this.hideDraftLimits();
        R.view.tool.onMouseMove = null;
      };

      PathTool.prototype.begin = function(event, from, data) {
        var ref;
        if (from == null) {
          from = R.me;
        }
        if (data == null) {
          data = null;
        }
        if (event.event.which === 2) {
          return;
        }
        if (100 * P.view.zoom < 10) {
          R.alertManager.alert("You can not draw path at a zoom smaller than 10.", "Info");
          return;
        }
        if ((this.draftLimit != null) && !this.draftLimit.contains(event.point)) {
          this.constructor.displayDraftIsTooBigError();
          return;
        }
        if (!((R.currentPaths[from] != null) && ((ref = R.currentPaths[from].data) != null ? ref.polygonMode : void 0))) {
          R.tools.select.deselectAll(false);
          R.currentPaths[from] = new this.Path(Date.now(), data, null, null, null, null, R.me);
        }
        R.currentPaths[from].beginCreate(event.point, event, false);
        if (this.constructor.emitSocket && (R.me != null) && from === R.me) {
          data = R.currentPaths[from].data;
          data.id = R.currentPaths[from].id;
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "begin",
            "arguments": [event, R.me, data]
          });
        }
      };

      PathTool.prototype.showDraftLimits = function() {
        var child, draftBounds, i, l1, l2, l3, l4, len, path, ref, viewBounds;
        this.hideDraftLimits();
        draftBounds = this.constructor.computeDraftBounds();
        path = R.currentPaths[R.me];
        if (path != null) {
          if (draftBounds != null) {
            draftBounds = draftBounds.unite(path.getDrawingBounds());
          } else {
            draftBounds = path.getDrawingBounds();
          }
        }
        if ((draftBounds == null) || draftBounds.area === 0) {
          return null;
        }
        viewBounds = R.view.grid.limitCD.bounds.clone();
        this.draftLimit = draftBounds.expand(2 * (this.constructor.maxDraftSize - draftBounds.width), 2 * (this.constructor.maxDraftSize - draftBounds.height));
        this.limit = new P.Group();
        l1 = new P.Path.Rectangle(viewBounds.topLeft, new P.Point(viewBounds.right, this.draftLimit.top));
        l2 = new P.Path.Rectangle(new P.Point(viewBounds.left, this.draftLimit.top), new P.Point(this.draftLimit.left, this.draftLimit.bottom));
        l3 = new P.Path.Rectangle(new P.Point(this.draftLimit.right, this.draftLimit.top), new P.Point(viewBounds.right, this.draftLimit.bottom));
        l4 = new P.Path.Rectangle(new P.Point(viewBounds.left, this.draftLimit.bottom), viewBounds.bottomRight);
        this.limit.addChild(l1);
        this.limit.addChild(l2);
        this.limit.addChild(l3);
        this.limit.addChild(l4);
        ref = this.limit.children;
        for (i = 0, len = ref.length; i < len; i++) {
          child = ref[i];
          child.fillColor = new P.Color(0, 0, 0, 0.25);
        }
        R.view.selectionLayer.addChild(this.limit);
        return this.draftLimit;
      };

      PathTool.prototype.hideDraftLimits = function() {
        if (this.limit != null) {
          this.limit.remove();
        }
        this.draftLimit = null;
      };

      PathTool.prototype.update = function(event, from) {
        var draftIsOutsideFrame, draftIsTooBig, draftLimit, p, path;
        if (from == null) {
          from = R.me;
        }
        path = R.currentPaths[from];
        if (path == null) {
          return;
        }
        draftLimit = this.showDraftLimits();
        draftIsTooBig = (draftLimit != null) && !draftLimit.expand(-20).contains(event.point);
        draftIsOutsideFrame = !R.view.contains(event.point);
        if (draftIsTooBig || draftIsOutsideFrame) {
          if (R.drawingMode !== 'line' && R.drawingMode !== 'lineOrthoDiag') {
            if (draftIsTooBig) {
              this.constructor.displayDraftIsTooBigError();
            } else if (draftIsOutsideFrame) {
              R.alertManager.alert('Your path must be in the drawing area', 'error');
            }
            this.end(event, from);
            if (path.path != null) {
              p = path.path.clone();
              p.strokeColor = 'red';
              R.view.mainLayer.addChild(p);
              setTimeout(((function(_this) {
                return function() {
                  return p.remove();
                };
              })(this)), 1000);
            }
            this.showDraftLimits();
          }
          return;
        }
        path.updateCreate(event.point, event, false);
        if (this.constructor.emitSocket && (R.me != null) && from === R.me) {
          R.socket.emit("bounce", {
            tool: this.name,
            "function": "update",
            "arguments": [event, R.me]
          });
        }
      };

      PathTool.prototype.move = function(event) {
        var base, ref, ref1;
        if ((ref = R.currentPaths[R.me]) != null ? (ref1 = ref.data) != null ? ref1.polygonMode : void 0 : void 0) {
          if (typeof (base = R.currentPaths[R.me]).createMove === "function") {
            base.createMove(event);
          }
        }
      };

      PathTool.prototype.createPath = function(event, from) {
        var path;
        path = R.currentPaths[from];
        if (path == null) {
          return;
        }
        if (!path.group) {
          return;
        }
        if ((R.me != null) && from === R.me) {
          if (this.constructor.emitSocket && (R.me != null) && from === R.me) {
            R.socket.emit("bounce", {
              tool: this.name,
              "function": "createPath",
              "arguments": [event, R.me]
            });
          }
          if ((R.me == null) || !_.isString(R.me)) {
            R.alertManager.alert("You must log in before drawing, your drawing won't be saved", "Info");
            return;
          }
          path.save(true);
          path.rasterize();
          R.rasterizer.rasterize(path);
          R.toolManager.updateButtonsVisibility();
        } else {
          path.endCreate(event.point, event);
        }
        delete R.currentPaths[from];
      };

      PathTool.prototype.end = function(event, from) {
        var path, ref;
        if (from == null) {
          from = R.me;
        }
        path = R.currentPaths[from];
        if (path == null) {
          return false;
        }
        if ((this.draftLimit != null) && !this.draftLimit.contains(R.currentPaths[from].controlPath.bounds)) {
          this.constructor.displayDraftIsTooBigError();
          R.currentPaths[from].remove();
          delete R.currentPaths[from];
          return false;
        }
        path.endCreate(event.point, event, false);
        if (!((ref = path.data) != null ? ref.polygonMode : void 0)) {
          this.createPath(event, from);
        }
        R.drawingPanel.showSubmitDrawing();
      };

      PathTool.prototype.finish = function(from) {
        var ref, ref1;
        if (from == null) {
          from = R.me;
        }
        if (!((ref = R.currentPaths[R.me]) != null ? (ref1 = ref.data) != null ? ref1.polygonMode : void 0 : void 0)) {
          return false;
        }
        R.currentPaths[from].finish();
        this.createPath(event, from);
        return true;
      };

      PathTool.prototype.keyUp = function(event) {
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

      return PathTool;

    })(Tool);
    R.Tools.Path = PathTool;
    return PathTool;
  });

}).call(this);
