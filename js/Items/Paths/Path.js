// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'Items/Content', 'Tools/PathTool', 'Commands/Command'], function(P, R, Utils, Item, Content, PathTool, Command) {
    var Path;
    Path = (function(superClass) {
      extend(Path, superClass);

      Path.label = 'Pen';

      Path.description = "The classic and basic pen tool";

      Path.constructor.secureDistance = 2;

      Path.colorMap = {
        draft: '#808080',
        pending: '#005fb8',
        emailNotConfirmed: '#005fb8',
        notConfirmed: '#E91E63',
        drawing: '#11a74f',
        drawn: 'black',
        test: 'purple',
        rejected: '#EB5A46',
        flagged: '#EE2233'
      };

      Path.strokeWidth = R.strokeWidth || Utils.CS.mmToPixel(7);

      Path.strokeColor = 'black';

      Path.initializeParameters = function() {
        var parameters;
        parameters = Path.__super__.constructor.initializeParameters.call(this);
        parameters['Items'].duplicate = R.parameters.duplicate;
        delete parameters['Style'];
        return parameters;
      };

      Path.parameters = Path.initializeParameters();

      Path.createTool = function(Path) {
        new R.Tools.Path(Path);
      };

      Path.create = function(duplicateData) {
        var copy;
        if (duplicateData == null) {
          duplicateData = this.getDuplicateData();
        }
        copy = new this(duplicateData.date, duplicateData.data, duplicateData.id, null, duplicateData.points, duplicateData.lock, duplicateData.owner);
        copy.draw();
        if (!this.socketAction) {
          copy.save(false);
          R.socket.emit("bounce", {
            itemClass: this.name,
            "function": "create",
            "arguments": [duplicateData]
          });
        }
        return copy;
      };

      Path.getPlanetFromPath = function(path) {
        return Utils.CS.projectToPlanet(path.segments[0].point);
      };

      Path.pathOnPlanetFromPath = function(path) {
        var i, len, p, planet, points, ref, segment;
        points = [];
        planet = this.getPlanetFromPath(path);
        ref = path.segments;
        for (i = 0, len = ref.length; i < len; i++) {
          segment = ref[i];
          p = Utils.CS.projectToPosOnPlanet(segment.point, planet);
          points.push(Utils.CS.pointToArray(p));
        }
        return points;
      };

      function Path(date, data1, id, pk1, points, lock, owner, drawingId) {
        var drawing;
        this.date = date != null ? date : null;
        this.data = data1 != null ? data1 : null;
        this.id = id != null ? id : null;
        this.pk = pk1 != null ? pk1 : null;
        if (points == null) {
          points = null;
        }
        this.lock = lock != null ? lock : null;
        this.owner = owner != null ? owner : null;
        this.drawingId = drawingId != null ? drawingId : null;
        this.sendToSpacebrew = bind(this.sendToSpacebrew, this);
        this.update = bind(this.update, this);
        this.saveCallback = bind(this.saveCallback, this);
        if (!this.lock) {
          Path.__super__.constructor.call(this, this.data, this.id, this.pk, this.date, R.sidebar.pathListJ, R.sortedPaths);
        } else {
          Path.__super__.constructor.call(this, this.data, this.id, this.pk, this.date, this.lock.itemListsJ.find('.rPath-list'), this.lock.sortedPaths);
        }
        R.paths[this.id] = this;
        if (this.drawingId == null) {
          this.addToListItem();
        } else {
          if (R.items[this.drawingId] != null) {
            drawing = R.items[this.drawingId];
            drawing.addChild(this);
          }
        }
        this.selectionHighlight = null;
        this.data.strokeWidth = this.constructor.strokeWidth;
        this.data.strokeColor = this.constructor.strokeColor;
        this.data.fillColor = null;
        if (points != null) {
          this.loadPath(points);
        }
        return;
      }

      Path.prototype.containingLayer = function() {
        var drawing;
        drawing = this.getDrawing();
        if (drawing != null) {
          return drawing.containingLayer();
        } else {
          return this.group.parent;
        }
      };

      Path.prototype.addToListItem = function(itemListJ, name) {
        this.itemListJ = itemListJ != null ? itemListJ : null;
        if (name == null) {
          name = null;
        }
        if (this.itemListJ == null) {
          this.itemListJ = this.getListItem();
        }
        if (name == null) {
          name = this.id.substring(0, 5);
        }
        Path.__super__.addToListItem.call(this, this.itemListJ, name);
      };

      Path.prototype.getDrawing = function() {
        if (this.drawingId != null) {
          return R.items[this.drawingId];
        } else {
          return null;
        }
      };

      Path.prototype.getDuplicateData = function() {
        var data;
        data = Path.__super__.getDuplicateData.call(this);
        data.points = this.pathOnPlanet();
        data.date = this.date;
        return data;
      };

      Path.prototype.getDrawingBounds = function() {
        var ref;
        if (!this.canvasRaster && (this.drawing != null) && this.drawing.strokeBounds.area > 0) {
          if (this.raster != null) {
            return this.raster.bounds;
          }
          return this.drawing.strokeBounds.expand(this.constructor.strokeWidth);
        }
        return (ref = this.getBounds()) != null ? ref.expand(2 * this.constructor.strokeWidth) : void 0;
      };

      Path.prototype.endSetRectangle = function() {
        Path.__super__.endSetRectangle.call(this);
        this.draw();
        this.rasterize();
      };

      Path.prototype.setRectangle = function(rectangle, update) {
        Path.__super__.setRectangle.call(this, rectangle, update);
        this.draw(update);
      };

      Path.prototype.setRotation = function(rotation, center, update) {
        Path.__super__.setRotation.call(this, rotation, center, update);
        this.draw(update);
      };

      Path.prototype.projectToRaster = function(point) {
        return point.subtract(this.canvasRaster.bounds.topLeft);
      };

      Path.prototype.prepareHitTest = function(fullySelected, strokeWidth) {
        var ref;
        Path.__super__.prepareHitTest.call(this);
        this.stateBeforeHitTest = {};
        this.stateBeforeHitTest.groupWasVisible = this.group.visible;
        this.stateBeforeHitTest.controlPathWasVisible = this.controlPath.visible;
        this.stateBeforeHitTest.controlPathWasSelected = this.controlPath.selected;
        this.stateBeforeHitTest.controlPathWasFullySelected = this.controlPath.fullySelected;
        this.stateBeforeHitTest.controlPathStrokeWidth = this.controlPath.strokeWidth;
        this.group.visible = true;
        this.controlPath.visible = true;
        this.controlPath.selected = true;
        if (strokeWidth) {
          this.controlPath.strokeWidth = strokeWidth;
        }
        if (fullySelected) {
          this.controlPath.fullySelected = true;
        }
        if ((ref = this.speedGroup) != null) {
          ref.selected = true;
        }
      };

      Path.prototype.finishHitTest = function(fullySelected) {
        var ref;
        if (fullySelected == null) {
          fullySelected = true;
        }
        Path.__super__.finishHitTest.call(this, fullySelected);
        this.group.visible = this.stateBeforeHitTest.groupWasVisible;
        this.controlPath.visible = this.stateBeforeHitTest.controlPathWasVisible;
        this.controlPath.strokeWidth = this.stateBeforeHitTest.controlPathStrokeWidth;
        this.controlPath.fullySelected = this.stateBeforeHitTest.controlPathWasFullySelected;
        if (!this.controlPath.fullySelected) {
          this.controlPath.selected = this.stateBeforeHitTest.controlPathWasSelected;
        }
        this.stateBeforeHitTest = null;
        if ((ref = this.speedGroup) != null) {
          ref.selected = false;
        }
      };

      Path.prototype.hitTest = function(event) {
        var hitResult, wasSelected;
        wasSelected = this.selected;
        hitResult = Path.__super__.hitTest.call(this, event);
        if (hitResult == null) {
          return;
        }
        if (hitResult.type === 'stroke' || !wasSelected) {
          hitResult.type = 'stroke';
          if (R.tools.select.selectionRectangle != null) {
            R.tools.select.selectionRectangle.beginAction(hitResult, event);
          } else {
            $(R.tools.select).one('selectionRectangleUpdated', function() {
              return R.tools.select.selectionRectangle.beginAction(hitResult, event);
            });
          }
        }
        return hitResult;
      };

      Path.prototype.select = function(updateOptions) {
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (R.me !== this.owner && (this.drawingId == null) && !R.administrator) {
          return false;
        }
        if ((this.drawingId != null) && (R.items[this.drawingId] != null)) {
          R.items[this.drawingId].select();
          return null;
        }
        if ((this.drawingId == null) && !R.administrator) {
          Utils.callNextFrame((function() {
            return R.drawingPanel.submitDrawingClicked();
          }), 'select draft');
          return false;
        }
        if (!R.administrator) {
          return false;
        }
        if (!Path.__super__.select.call(this, updateOptions) || (this.controlPath == null)) {
          return false;
        }
        R.drawingPanel.showSubmitDrawing();
        return true;
      };

      Path.prototype.deselect = function(updateOptions) {
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (!Path.__super__.deselect.call(this, updateOptions)) {
          return false;
        }
        return true;
      };

      Path.prototype.updateSelect = function(event) {
        Path.__super__.updateSelect.call(this, event);
      };

      Path.prototype.doubleClick = function(event) {};

      Path.prototype.loadPath = function(points) {};

      Path.prototype.setParameter = function(name, value, updateGUI, update) {
        Path.__super__.setParameter.call(this, name, value, updateGUI, update);
        if (this.previousBoundingBox == null) {
          this.previousBoundingBox = this.getDrawingBounds();
        }
        this.draw();
      };

      Path.prototype.applyStylesToPath = function(path) {
        path.strokeColor = this.data.strokeColor;
        path.strokeWidth = this.data.strokeWidth;
        path.fillColor = this.data.fillColor;
        if (this.data.dashArray != null) {
          path.dashArray = this.data.dashArray;
        }
        if (this.data.strokeCap != null) {
          this.drawing.strokeCap = this.data.strokeCap;
        }
        if (this.data.strokeJoin != null) {
          this.drawing.strokeJoin = this.data.strokeJoin;
        }
        if (this.data.shadowOffsetY != null) {
          path.shadowOffset = new P.Point(this.data.shadowOffsetX, this.data.shadowOffsetY);
        }
        if (this.data.shadowBlur != null) {
          path.shadowBlur = this.data.shadowBlur;
        }
        if (this.data.shadowColor != null) {
          path.shadowColor = this.data.shadowColor;
        }
      };

      Path.prototype.addPath = function(path, applyStyles) {
        if (applyStyles == null) {
          applyStyles = true;
        }
        if (path == null) {
          path = new P.Path();
        }
        path.controller = this;
        if (applyStyles) {
          this.applyStylesToPath(path);
        }
        this.drawing.addChild(path);
        return path;
      };

      Path.prototype.addControlPath = function(controlPath) {
        this.controlPath = controlPath;
        if (this.lock) {
          this.lock.group.addChild(this.group);
        }
        if (this.controlPath == null) {
          this.controlPath = new P.Path();
        }
        this.group.addChild(this.controlPath);
        this.controlPath.name = "controlPath";
        this.controlPath.controller = this;
        this.controlPath.strokeWidth = 10;
        this.controlPath.strokeColor = R.selectionBlue;
        this.controlPath.strokeColor.alpha = 0.25;
        this.controlPath.strokeCap = 'round';
        this.controlPath.strokeJoin = 'round';
        this.controlPath.visible = false;
      };

      Path.prototype.getStrokeColor = function() {
        var color, d;
        d = this.getDrawing();
        color = new P.Color(d != null ? this.constructor.colorMap[d.status] : this.constructor.colorMap.draft);
        this.data.strokeColor = color;
        return color;
      };

      Path.prototype.updateStrokeColor = function() {
        var ref;
        if ((ref = this.drawing) != null) {
          ref.strokeColor = this.getStrokeColor();
        }
      };

      Path.prototype.initializeDrawing = function(createCanvas) {
        var bounds, canvas, position, ref, ref1, ref2;
        if (createCanvas == null) {
          createCanvas = false;
        }
        if ((ref = this.raster) != null) {
          ref.remove();
        }
        this.raster = null;
        this.controlPath.strokeWidth = 10;
        this.data.strokeColor = this.getStrokeColor();
        if ((ref1 = this.drawing) != null) {
          ref1.remove();
        }
        this.drawing = new P.Group();
        this.drawing.name = "drawing";
        this.drawing.strokeColor = this.data.strokeColor;
        this.drawing.strokeWidth = this.data.strokeWidth;
        if (this.data.dashArray != null) {
          this.drawing.dashArray = this.data.dashArray;
        }
        if (this.data.strokeCap != null) {
          this.drawing.strokeCap = this.data.strokeCap;
        }
        if (this.data.strokeJoin != null) {
          this.drawing.strokeJoin = this.data.strokeJoin;
        }
        this.drawing.fillColor = this.data.fillColor;
        this.drawing.insertBelow(this.controlPath);
        this.drawing.controlPath = this.controlPath;
        this.drawing.controller = this;
        this.group.addChild(this.drawing);
        if (createCanvas) {
          canvas = document.createElement("canvas");
          if (this.rectangle.area < 2) {
            canvas.width = P.view.size.width;
            canvas.height = P.view.size.height;
            position = P.view.center;
          } else {
            bounds = this.getDrawingBounds();
            canvas.width = bounds.width;
            canvas.height = bounds.height;
            position = bounds.center;
          }
          if ((ref2 = this.canvasRaster) != null) {
            ref2.remove();
          }
          this.canvasRaster = new P.Raster(canvas, position);
          this.drawing.addChild(this.canvasRaster);
          this.context = this.canvasRaster.canvas.getContext("2d");
          this.context.strokeStyle = this.data.strokeColor;
          this.context.fillStyle = this.data.fillColor;
          this.context.lineWidth = this.data.strokeWidth;
        }
      };

      Path.prototype.setAnimated = function(animated) {
        if (animated) {
          Utils.Animation.registerAnimation(this);
        } else {
          Utils.Animation.deregisterAnimation(this);
        }
      };

      Path.prototype.draw = function(simplified) {
        if (simplified == null) {
          simplified = false;
        }
      };

      Path.prototype.initialize = function() {};

      Path.prototype.beginCreate = function(point, event) {};

      Path.prototype.updateCreate = function(point, event) {};

      Path.prototype.endCreate = function(point, event) {};

      Path.prototype.insertAbove = function(path, index, update) {
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.zindex = this.group.index;
        Path.__super__.insertAbove.call(this, path, index, update);
      };

      Path.prototype.insertBelow = function(path, index, update) {
        if (index == null) {
          index = null;
        }
        if (update == null) {
          update = false;
        }
        this.zindex = this.group.index;
        Path.__super__.insertBelow.call(this, path, index, update);
      };

      Path.prototype.getData = function() {
        return this.data;
      };

      Path.prototype.getStringifiedData = function() {
        return JSON.stringify(this.getData());
      };

      Path.prototype.getPlanet = function() {
        return Utils.CS.projectToPlanet(this.controlPath.segments[0].point);
      };

      Path.prototype.save = function(addCreateCommand) {
        var args, draft;
        if (addCreateCommand == null) {
          addCreateCommand = true;
        }
        if (this.controlPath == null) {
          return;
        }
        draft = Item.Drawing.getDraft();
        if (draft != null) {
          R.commandManager.add(new Command.ModifyDrawing(draft));
          draft.addChild(this);
          if (draft.pk == null) {
            draft.addPathToSave(this);
          } else {
            args = {
              clientId: draft.id,
              pk: draft.pk,
              points: this.getPoints()
            };
            $.ajax({
              method: "POST",
              url: "ajaxCall/",
              data: {
                data: JSON.stringify({
                  "function": 'addPathToDrawing',
                  args: args
                })
              }
            }).done(this.saveCallback);
          }
        } else {
          draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft');
          R.commandManager.add(new Command.ModifyDrawing(draft));
          draft.points = this.getPoints();
          draft.addChild(this);
          draft.save();
        }
        Path.__super__.save.call(this, false);
      };

      Path.prototype.saveCallback = function(result) {
        R.loader.checkError(result);
        if (result.pk == null) {
          return;
        }
        this.setPK(result.pk);
        this.owner = result.owner;
        if (this.updateAfterSave != null) {
          this.update(this.updateAfterSave);
        }
        Path.__super__.saveCallback.apply(this, arguments);
      };

      Path.prototype.getUpdateFunction = function() {
        return 'updatePath';
      };

      Path.prototype.getUpdateArguments = function(type) {
        var args;
        switch (type) {
          case 'z-index':
            args = {
              pk: this.pk,
              date: this.date
            };
            break;
          default:
            args = {
              pk: this.pk,
              points: this.pathOnPlanet(),
              data: this.getStringifiedData(),
              box: Utils.CS.boxFromRectangle(this.getDrawingBounds())
            };
        }
        return args;
      };

      Path.prototype.update = function(type) {
        if (this.pk == null) {
          this.updateAfterSave = type;
          return;
        }
        delete this.updateAfterSave;
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'updatePath',
              args: this.getUpdateArguments(type)
            })
          }
        }).done(this.updatePathCallback);
      };

      Path.prototype.updatePathCallback = function(result) {
        R.loader.checkError(result);
      };

      Path.prototype.setPK = function(pk) {
        Path.__super__.setPK.apply(this, arguments);
      };

      Path.prototype.isDraft = function() {
        var ref;
        return (this.drawingId == null) || ((ref = R.items[this.drawingId]) != null ? ref.status : void 0) === 'draft';
      };

      Path.prototype.remove = function() {
        if (!this.group) {
          return;
        }
        Utils.Animation.deregisterAnimation();
        this.controlPath = null;
        this.drawing = null;
        if (this.raster == null) {
          this.raster = null;
        }
        if (this.canvasRaster == null) {
          this.canvasRaster = null;
        }
        delete R.paths[this.id];
        Path.__super__.remove.call(this);
      };

      Path.prototype["delete"] = function() {
        var deffered, draft;
        deffered = Path.__super__["delete"].call(this);
        draft = R.Drawing.getDraft();
        if (draft != null) {
          draft.updatePaths();
          R.toolManager.updateButtonsVisibility(draft);
          R.tools['Precise path'].showDraftLimits();
        }
        return deffered;
      };

      Path.prototype.deleteFromDatabase = function() {
        console.log('delete ' + this.id + ' from database');
        if ((this.pk == null) || this.pk === this.id) {
          return;
        }
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'deletePath',
              args: {
                pk: this.pk
              }
            })
          }
        }).done(this.deleteFromDatabaseCallback);
      };

      Path.prototype.pathOnPlanet = function(controlSegments) {
        var i, len, p, planet, points, segment;
        if (controlSegments == null) {
          controlSegments = this.controlPath.segments;
        }
        points = [];
        planet = this.getPlanet();
        for (i = 0, len = controlSegments.length; i < len; i++) {
          segment = controlSegments[i];
          p = Utils.CS.projectToPosOnPlanet(segment.point, planet);
          points.push(Utils.CS.pointToArray(p));
        }
        return points;
      };

      Path.prototype.getPathList = function(item, paths) {
        var child, i, j, len, len1, path, ref, segment, segments;
        switch (item.className) {
          case 'Group':
          case 'CompoundPath':
            ref = item.children;
            for (i = 0, len = ref.length; i < len; i++) {
              child = ref[i];
              this.getPathList(child, paths);
            }
            break;
          case 'Path':
          case 'Shape':
            segments = item.className === 'Shape' ? item.toPath(false).segments : item.segments;
            path = [];
            for (j = 0, len1 = segments.length; j < len1; j++) {
              segment = segments[j];
              path.push(segment.point.toJSON());
            }
            if (item.closed) {
              path.push(item.firstSegment.point.toJSON());
            }
            paths.push(path);
        }
      };

      Path.prototype.requireAndSendToSpacebrew = function() {
        var spacebrewPath;
        if (typeof spacebrew === "undefined" || spacebrew === null) {
          spacebrewPath = 'Spacebrew';
          require([spacebrewPath], this.sendToSpacebrew);
        }
      };

      Path.prototype.sendToSpacebrew = function(spacebrew) {
        var data, i, j, json, len, len1, linkAllPaths, path, paths, point;
        paths = [];
        this.getPathList(this.drawing, paths);
        linkAllPaths = [];
        for (i = 0, len = paths.length; i < len; i++) {
          path = paths[i];
          for (j = 0, len1 = path.length; j < len1; j++) {
            point = path[j];
            linkAllPaths.push(point);
          }
        }
        paths = [linkAllPaths];
        data = {
          paths: paths,
          bounds: paper.view.bounds.toJSON()
        };
        json = JSON.stringify(data);
        spacebrew.send("commands", "string", json);
      };

      Path.prototype.exportToSVG = function(item, filename) {
        var blob, drawing, link, svg, url;
        if (item == null) {
          item = this.drawing;
        }
        if (filename == null) {
          filename = "image.svg";
        }
        drawing = item.clone();
        drawing.position = new P.Point(drawing.bounds.size.multiply(0.5));
        svg = drawing.exportSVG({
          asString: true
        });
        drawing.remove();
        svg = svg.replace(new RegExp('<g', 'g'), '<svg');
        svg = svg.replace(new RegExp('</g', 'g'), '</svg');
        blob = new Blob([svg], {
          type: 'image/svg+xml'
        });
        url = URL.createObjectURL(blob);
        link = document.createElement("a");
        document.body.appendChild(link);
        link.href = url;
        link.download = filename;
        link.text = filename;
        link.click();
        document.body.removeChild(link);
      };

      return Path;

    })(Content);
    Item.Path = Path;
    R.Path = Path;
    return Path;
  });

}).call(this);

//# sourceMappingURL=Path.js.map
