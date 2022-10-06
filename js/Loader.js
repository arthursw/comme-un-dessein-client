// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Commands/Command', 'Items/Item', 'UI/ModuleLoader', 'Items/Drawing', 'Items/Discussion', 'Items/Divs/Text', 'UI/Modal'], function(P, R, Utils, Command, Item, ModuleLoader, Drawing, Discussion, Text, Modal) {
    var Loader;
    Loader = (function() {
      Loader.maxNumPoints = 1000;

      Loader.scaleRatio = 4;

      function Loader() {
        this.checkError = bind(this.checkError, this);
        this.displayError = bind(this.displayError, this);
        this.loadCallbackTipibot = bind(this.loadCallbackTipibot, this);
        this.loadCallback = bind(this.loadCallback, this);
        this.loadVotesCallback = bind(this.loadVotesCallback, this);
        this.loadVotes = bind(this.loadVotes, this);
        this.loadDrawingsAndTilesCallback = bind(this.loadDrawingsAndTilesCallback, this);
        this.loadDraftCallback = bind(this.loadDraftCallback, this);
        this.createDrawings = bind(this.createDrawings, this);
        this.hideLoadingBar = bind(this.hideLoadingBar, this);
        this.showLoadingBar = bind(this.showLoadingBar, this);
        this.showLoadingBarCallback = bind(this.showLoadingBarCallback, this);
        this.loadingType = 'tiles';
        this.loadedAreas = [];
        this.debug = false;
        this.pathsToCreate = {};
        this.initializeLoadingBar();
        this.showLoadingBar();
        this.drawingPaths = [];
        this.drawingPk = null;
        this.rasters = new Map();
        return;
      }

      Loader.prototype.initializeTileManager = function() {
        this.tileManager = R.city.mode !== 'ExquisiteCorpse' ? R.tools.choose : R.view.exquisiteCorpseMask;
      };

      Loader.prototype.initializeLoadingBar = function() {
        var opts, target;
        opts = {
          lines: 17,
          length: 13,
          width: 8,
          radius: 0,
          scale: 1.5,
          corners: 0,
          color: '#ccc',
          opacity: 0.15,
          rotate: 0,
          direction: 1,
          speed: 1,
          trail: 38,
          fps: 20,
          zIndex: 2e9,
          className: 'spinner',
          top: '50%',
          left: '130px',
          shadow: false,
          hwaccel: false,
          position: 'relative'
        };
        target = document.getElementById('spinner');
      };

      Loader.prototype.initializeGroups = function(rasterLayer) {
        this.activeRasterGroup = new P.Group();
        this.inactiveRasterGroup = new P.Group();
        rasterLayer.addChild(this.activeRasterGroup);
        rasterLayer.addChild(this.inactiveRasterGroup);
      };

      Loader.prototype.showDrawingBar = function() {
        $("#drawingBar").show();
      };

      Loader.prototype.hideDrawingBar = function() {
        $("#drawingBar").hide();
      };

      Loader.prototype.showLoadingBarCallback = function() {
        $("#loadingBar").show().css({
          opacity: 1
        });
      };

      Loader.prototype.showLoadingBar = function(timeout) {
        if ((timeout != null) && timeout > 0) {
          clearTimeout(this.showLoadingBarTimeoutId);
          $("#loadingBar").show().css({
            opacity: 0
          });
          this.showLoadingBarTimeoutId = setTimeout(this.showLoadingBarCallback, timeout);
        } else {
          this.showLoadingBarCallback();
        }
      };

      Loader.prototype.hideLoadingBar = function() {
        clearTimeout(this.showLoadingBarTimeoutId);
        $("#loadingBar").hide();
      };

      Loader.prototype.areaIsLoaded = function(pos, planet, qZoom) {
        var area, j, len, ref;
        ref = this.loadedAreas;
        for (j = 0, len = ref.length; j < len; j++) {
          area = ref[j];
          if (area.planet.x === planet.x && area.planet.y === planet.y) {
            if (area.pos.x === pos.x && area.pos.y === pos.y) {
              if ((qZoom == null) || area.zoom === qZoom) {
                return true;
              }
            }
          }
        }
        return false;
      };

      Loader.prototype.unload = function() {
        var id, item, ref;
        this.loadedAreas = [];
        ref = R.items;
        for (id in ref) {
          if (!hasProp.call(ref, id)) continue;
          item = ref[id];
          item.remove();
        }
        R.items = {};
        this.previousLoadPosition = null;
      };

      Loader.prototype.getLoadingBounds = function(area) {
        if (area == null) {
          return P.view.bounds;
        }
        return area;
      };

      Loader.prototype.createDrawing = function(itemString, reloadUnderneathRasters) {
        var bounds, date, drawing, item, ref, ref1;
        if (reloadUnderneathRasters == null) {
          reloadUnderneathRasters = false;
        }
        item = JSON.parse(itemString);
        if (((ref = R.pkToDrawing) != null ? ref.get(item._id.$oid) : void 0) != null) {
          return;
        }
        bounds = item.box != null ? R.view.grid.boundsFromBox(item.box) : null;
        date = (ref1 = item.date) != null ? ref1.$date : void 0;
        drawing = new Item.Drawing(null, null, item.clientId, item._id.$oid, item.owner, date, item.title, null, item.status, item.pathList, item.svg, bounds);
        if (reloadUnderneathRasters) {
          this.reloadRasters(drawing.rectangle);
        }
      };

      Loader.prototype.createDrawings = function(results) {
        var itemString, j, len, ref;
        ref = results.items;
        for (j = 0, len = ref.length; j < len; j++) {
          itemString = ref[j];
          this.createDrawing(itemString);
        }
      };

      Loader.prototype.loadDraft = function() {
        var args;
        args = {
          cityName: R.city.name
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadDraft',
              args: args
            })
          }
        }).done(this.loadDraftCallback);
      };

      Loader.prototype.loadCity = function(cityName, url) {
        var args;
        if (url == null) {
          url = '';
        }
        args = {
          cityName: cityName,
          bounds: P.view.bounds,
          rejected: R.loadRejectedDrawings
        };
        $.ajax({
          method: "POST",
          url: url + "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadDrawingsAndTilesFromBounds',
              args: args
            })
          }
        }).done((function(_this) {
          return function(results) {
            _this.loadDrawingsAndTilesCallback(results);
            return typeof callback === "function" ? callback() : void 0;
          };
        })(this));
      };

      Loader.prototype.loadDraftCallback = function(results) {
        if (!this.checkError(results)) {
          return;
        }
        if (results.user != null) {
          this.setMe(results.user);
        }
        this.createDrawings(results);
        this.endLoading();
        R.toolManager.updateButtonsVisibility();
      };

      Loader.prototype.loadDrawingsAndTiles = function(bounds, callback) {
        var args, grid;
        if (callback == null) {
          callback = null;
        }
        grid = R.view.grid;
        args = {
          cityName: R.city.name,
          bounds: bounds,
          rejected: R.loadRejectedDrawings
        };
        if (this.loadingType === 'screen-ignore-loaded' || this.loadingType === 'tiles-ignore-loaded') {
          args.drawingsToIgnore = Array.from(R.pkToDrawing.keys());
          args.tilesToIgnore = this.tileManager.tilePks;
        }
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadDrawingsAndTilesFromBounds',
              args: args
            })
          }
        }).done((function(_this) {
          return function(results) {
            _this.loadDrawingsAndTilesCallback(results);
            return typeof callback === "function" ? callback() : void 0;
          };
        })(this));
      };

      Loader.prototype.loadDrawingsAndTilesCallback = function(results) {
        var discussion, discussions, j, k, len, len1, tile, tiles;
        if (!this.checkError(results)) {
          return;
        }
        this.createDrawings(results);
        if (R.application === 'ESPERO' || R.city.mode === 'ExquisiteCorpse') {
          tiles = results.tiles instanceof Array ? results.tiles : JSON.parse(results.tiles);
          for (j = 0, len = tiles.length; j < len; j++) {
            tile = tiles[j];
            this.tileManager.createTile(tile);
          }
          if (results.discussions != null) {
            discussions = JSON.parse(results.discussions);
            for (k = 0, len1 = discussions.length; k < len1; k++) {
              discussion = discussions[k];
              R.tools.discuss.createDiscussion(discussion);
            }
          }
        }
      };

      Loader.prototype.clearRasters = function() {
        this.rasters.forEach((function(_this) {
          return function(rastersOfScale, s) {
            return rastersOfScale.forEach(function(rastersY, y) {
              return rastersY.forEach(function(rs, x) {
                while (rs.length > 0) {
                  rs.pop().remove();
                }
              });
            });
          };
        })(this));
      };

      Loader.prototype.reloadRasters = function(bounds) {
        this.rasters.forEach((function(_this) {
          return function(rastersOfScale, s) {
            return rastersOfScale.forEach(function(rastersY, y) {
              return rastersY.forEach(function(rs, x) {
                if (rs.length > 0 && rs[0].data.bounds.intersects(bounds)) {
                  while (rs.length > 0) {
                    rs.pop().remove();
                  }
                }
              });
            });
          };
        })(this));
        this.loadRasters(bounds, false);
      };

      Loader.prototype.getScaleNumber = function() {
        var ln4;
        ln4 = Math.log(this.constructor.scaleRatio);
        return Math.max(0, Math.floor(Math.log(1 / P.view.zoom) / ln4));
      };

      Loader.prototype.getScale = function(scaleNumber) {
        return Math.pow(this.constructor.scaleRatio, scaleNumber);
      };

      Loader.prototype.getQuantizedBounds = function(bounds, scaleNumber, scale) {
        var nPixelsPerTile, quantizedBounds;
        if (!(bounds instanceof P.Rectangle)) {
          bounds = new P.Rectangle(bounds);
        }
        if (scaleNumber == null) {
          scaleNumber = this.getScaleNumber();
        }
        if (scale == null) {
          scale = this.getScale(scaleNumber);
        }
        nPixelsPerTile = scale * 1000;
        quantizedBounds = {
          t: Math.floor(bounds.top / nPixelsPerTile),
          l: Math.floor(bounds.left / nPixelsPerTile),
          b: Math.ceil(bounds.bottom / nPixelsPerTile),
          r: Math.ceil(bounds.right / nPixelsPerTile)
        };
        return quantizedBounds;
      };

      Loader.prototype.removeRaster = function(rx, ry) {
        this.rasters.forEach((function(_this) {
          return function(rastersOfScale, s) {
            return rastersOfScale.forEach(function(rastersY, y) {
              return rastersY.forEach(function(rs, x) {
                var results1;
                if (x === rx && y === ry) {
                  results1 = [];
                  while (rs.length > 0) {
                    results1.push(rs.pop().remove());
                  }
                  return results1;
                }
              });
            });
          };
        })(this));
      };

      Loader.prototype.removeRastersXY = function(rs) {
        var raster, rasterBounds;
        rasterBounds = null;
        while (rs.length > 0) {
          raster = rs.pop();
          rasterBounds = raster.data.bounds;
          raster.remove();
        }
        if (rasterBounds != null) {
          R.tools.discuss.removeDisucssionsInRectangle(rasterBounds);
        }
      };

      Loader.prototype.loadRasters = function(bounds, alsoLoadDrawingsAndTiles, callback) {
        var drawingsToLoad, group, j, k, layerName, len, limits, m, n, nPixelsPerTile, o, quantizedBounds, quantizedViewBounds, raster, rasterBounds, rastersOfScale, rastersY, ref, ref1, ref2, ref3, ref4, ref5, rs, scale, scaleNumber;
        if (bounds == null) {
          bounds = P.view.bounds;
        }
        if (alsoLoadDrawingsAndTiles == null) {
          alsoLoadDrawingsAndTiles = true;
        }
        if (callback == null) {
          callback = null;
        }
        if (R.useSVG) {
          if (alsoLoadDrawingsAndTiles) {
            this.loadDrawingsAndTiles(bounds, callback);
          }
          return;
        }
        scaleNumber = this.getScaleNumber();
        scale = this.getScale(scaleNumber);
        nPixelsPerTile = scale * 1000;
        quantizedBounds = this.getQuantizedBounds(bounds, scaleNumber, scale);
        quantizedViewBounds = this.getQuantizedBounds(P.view.bounds, scaleNumber, scale);
        rastersOfScale = this.rasters.get(scaleNumber);
        if (rastersOfScale == null) {
          rastersOfScale = new Map();
          this.rasters.set(scaleNumber, rastersOfScale);
        }
        limits = P.view.bounds.expand(nPixelsPerTile);
        if ((ref = R.pkToDrawing) != null) {
          ref.forEach((function(_this) {
            return function(drawing, pk) {
              var drawingBounds;
              drawingBounds = drawing.getBounds();
              if (drawing.status !== 'draft' && drawing.status !== 'flagged_pending' && (drawingBounds != null) && !drawingBounds.intersects(limits)) {
                return drawing.remove();
              }
            };
          })(this));
        }
        this.tileManager.removeTiles(limits);
        this.rasters.forEach((function(_this) {
          return function(rastersOfScale, s) {
            if (s !== scaleNumber) {
              rastersOfScale.forEach(function(rastersY, y) {
                return rastersY.forEach(function(rs, x) {
                  _this.removeRastersXY(rs);
                });
              });
              return _this.rasters["delete"](s);
            } else {
              return rastersOfScale.forEach(function(rastersY, y) {
                return rastersY.forEach(function(rs, x) {
                  if (y < quantizedViewBounds.t || y > quantizedViewBounds.b || x < quantizedViewBounds.l || x > quantizedViewBounds.r) {
                    _this.removeRastersXY(rs);
                    rastersY["delete"](x);
                  }
                });
              });
            }
          };
        })(this));
        for (n = j = ref1 = quantizedBounds.t, ref2 = quantizedBounds.b - 1; ref1 <= ref2 ? j <= ref2 : j >= ref2; n = ref1 <= ref2 ? ++j : --j) {
          for (m = k = ref3 = quantizedBounds.l, ref4 = quantizedBounds.r - 1; ref3 <= ref4 ? k <= ref4 : k >= ref4; m = ref3 <= ref4 ? ++k : --k) {
            rs = rastersOfScale != null ? (ref5 = rastersOfScale.get(n)) != null ? ref5.get(m) : void 0 : void 0;
            if ((rs == null) || rs.length === 0) {
              drawingsToLoad = [];
              if (R.loadRejectedDrawings) {
                drawingsToLoad.push('inactive');
              }
              if (R.loadActiveDrawings) {
                drawingsToLoad.push('active');
              }
              rs = [];
              for (o = 0, len = drawingsToLoad.length; o < len; o++) {
                layerName = drawingsToLoad[o];
                group = new P.Group();
                raster = new P.Raster(location.origin + '/static/rasters/' + R.city.name + '/' + layerName + '/zoom' + scaleNumber + '/' + m + ',' + n + '.png' + '?version=' + Math.random());
                raster.position.x = (m + 0.5) * nPixelsPerTile;
                raster.position.y = (n + 0.5) * nPixelsPerTile;
                raster.scale(scale * 1.001);
                rasterBounds = new P.Rectangle(m * nPixelsPerTile, n * nPixelsPerTile, nPixelsPerTile, nPixelsPerTile);
                raster.data.bounds = rasterBounds;
                rs.push(raster);
                group.addChild(raster);
                if (alsoLoadDrawingsAndTiles && P.project.view.zoom >= 0.125 && (this.loadingType === 'tiles' || this.loadingType === 'tiles-ignore-loaded')) {
                  this.loadDrawingsAndTiles(rasterBounds);
                }
                if (layerName === 'active') {
                  this.activeRasterGroup.addChild(group);
                } else {
                  this.inactiveRasterGroup.addChild(group);
                }
              }
              rastersY = rastersOfScale.get(n);
              if (rastersY == null) {
                rastersY = new Map();
                rastersOfScale.set(n, rastersY);
              }
              rastersY.set(m, rs);
            }
          }
        }
        if (alsoLoadDrawingsAndTiles && this.loadingType === 'screen' || this.loadingType === 'screen-ignore-loaded') {
          this.loadDrawingsAndTiles(bounds);
        }
      };

      Loader.prototype.loadVotes = function() {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadVotes',
              args: {
                cityName: R.city.name
              }
            })
          }
        }).done(this.loadVotesCallback);
      };

      Loader.prototype.loadVotesCallback = function(results) {
        var j, len, ref, ref1, vote;
        if (results.state !== 'not_logged_in') {
          if (!this.checkError(results)) {
            return;
          }
        }
        if (this.userVotes == null) {
          this.userVotes = new Map();
        }
        if (results.votes != null) {
          ref = results.votes;
          for (j = 0, len = ref.length; j < len; j++) {
            vote = ref[j];
            if (vote.emailConfirmed) {
              this.userVotes.set(vote.pk, vote.positive);
              if ((ref1 = R.items[vote.pk]) != null) {
                ref1.setStrokeColorFromVote(vote.positive);
              }
            }
          }
        }
        if (results.nTiles != null) {
          R.userProfile = {
            nTiles: results.nTiles
          };
        }
      };

      Loader.prototype.dispatchLoadFinished = function() {
        var commandEvent;
        commandEvent = document.createEvent('Event');
        commandEvent.initEvent('command executed', true, true);
        document.dispatchEvent(commandEvent);
      };

      Loader.prototype.setMe = function(user) {
        if ((R.me == null) && (user != null)) {
          R.me = user;
          if ((R.socket.chatJ != null) && R.socket.chatJ.find("#chatUserNameInput").length === 0) {
            R.socket.startChatting(R.me);
          }
        }
      };

      Loader.prototype.removeDeletedItems = function(deletedItems) {
        var deletedItemLastUpdate, id, ref;
        if (deletedItems == null) {
          return;
        }
        for (id in deletedItems) {
          deletedItemLastUpdate = deletedItems[id];
          if ((ref = R.items[id]) != null) {
            ref.remove();
          }
        }
      };

      Loader.prototype.mustLoadItem = function(item) {
        return R.items[item.clientId] == null;
      };

      Loader.prototype.unloadItem = function(item) {};

      Loader.prototype.parseNewItems = function(items) {
        var i, item, itemsToLoad, j, len;
        itemsToLoad = [];
        for (j = 0, len = items.length; j < len; j++) {
          i = items[j];
          item = JSON.parse(i);
          if (!this.mustLoadItem(item)) {
            continue;
          }
          this.unloadItem(item);
          if (item.rType === 'Box' || item.rType === 'Drawing') {
            itemsToLoad.unshift(item);
          } else {
            itemsToLoad.push(item);
          }
        }
        return itemsToLoad;
      };

      Loader.prototype.moduleLoaded = function(args) {
        this.createPath(args);
        delete this.pathsToCreate[args.id];
        if (Utils.isEmpty(this.pathsToCreate)) {
          this.hideDrawingBar();
          this.hideLoadingBar();
        }
      };

      Loader.prototype.loadModuleAndCreatePath = function(args) {
        this.pathsToCreate[args.id] = true;
        ModuleLoader.load(args.path.object_type, (function(_this) {
          return function() {
            return _this.moduleLoaded(args);
          };
        })(this));
      };

      Loader.prototype.createPath = function(args) {
        var drawingId, drawingPk, path, ref, ref1;
        drawingPk = (ref = args.drawing) != null ? ref.$oid : void 0;
        drawingId = drawingPk != null ? Item.Drawing.pkToId[drawingPk] || drawingPk : null;
        path = new R.tools[args.path.object_type].Path(args.date, args.data, args.id, args.pk, args.points, args.lock, args.owner, drawingId);
        path.lastUpdateDate = (ref1 = args.path.lastUpdate) != null ? ref1.$date : void 0;
        return path;
      };

      Loader.prototype.createNewItems = function(itemsToLoad) {
        var args, data, date, drawing, id, item, j, k, len, len1, lock, newItems, newPath, path, pk, planet, point, points, ref, ref1, rpath;
        newItems = [];
        for (j = 0, len = itemsToLoad.length; j < len; j++) {
          item = itemsToLoad[j];
          pk = item._id.$oid;
          id = item.clientId;
          date = (ref = item.date) != null ? ref.$date : void 0;
          data = (item.data != null) && item.data.length > 0 ? JSON.parse(item.data) : null;
          lock = item.lock != null ? R.items[item.lock] : null;
          switch (item.rtype) {
            case 'Path':
              path = item;
              if (path.owner == null) {
                console.error('A path does not have any owner!');
                continue;
              }
              planet = new P.Point(path.planetX, path.planetY);
              if (data != null) {
                data.planet = planet;
              }
              points = [];
              ref1 = path.points.coordinates;
              for (k = 0, len1 = ref1.length; k < len1; k++) {
                point = ref1[k];
                points.push(R.view.grid.geoJSONToProject(point));
              }
              rpath = null;
              newPath = null;
              args = {
                path: path,
                date: date,
                data: data,
                id: id,
                pk: pk,
                points: points,
                lock: lock,
                owner: path.owner,
                drawing: path.drawing
              };
              if (R.tools[path.object_type] != null) {
                newPath = this.createPath(args);
              } else {
                this.loadModuleAndCreatePath(args);
              }
              if (newPath != null) {
                newItems.push(newPath);
              }
              break;
            case 'Drawing':
              drawing = new Item.Drawing(null, data, id, item._id.$oid, item.owner, date, item.title, item.description, item.status, item.pathList, item.svg);
              if (drawing != null) {
                newItems.push(drawing);
              }
              break;
            default:
              continue;
          }
        }
        return newItems;
      };

      Loader.prototype.endLoading = function() {
        if (Utils.isEmpty(this.pathsToCreate)) {
          this.hideLoadingBar();
          this.hideDrawingBar();
        }
        this.dispatchLoadFinished();
      };

      Loader.prototype.loadCallback = function(results, rasterizeItems, rasterizeAreasToUpdate) {
        var itemsToLoad, newItems;
        if (rasterizeItems == null) {
          rasterizeItems = false;
        }
        if (rasterizeAreasToUpdate == null) {
          rasterizeAreasToUpdate = true;
        }
        console.log("load callback");
        console.log(P.project.activeLayer.name);
        if (!this.checkError(results)) {
          return;
        }
        if (results.hasOwnProperty('message') && results.message === 'no_paths') {
          this.dispatchLoadFinished();
          return;
        }
        this.setMe(results.user);
        if (results.qZoom == null) {
          results.qZoom = 1;
        }
        this.removeDeletedItems(results.deletedItems);
        itemsToLoad = this.parseNewItems(results.items);
        newItems = this.createNewItems(itemsToLoad);
        Item.Div.updateZindex(R.sortedDivs);
        this.endLoading();
      };

      Loader.prototype.loadCallbackTipibot = function(results) {
        var controlPath, data, date, i, id, item, itemsToLoad, j, k, len, len1, len2, nPoints, o, path, pk, planet, point, points, ref, ref1, ref2, segment;
        if (!this.checkError(results)) {
          return;
        }
        itemsToLoad = [];
        this.drawingPaths = [];
        this.drawingPk = results.pk;
        nPoints = 0;
        ref = results.items;
        for (j = 0, len = ref.length; j < len; j++) {
          i = ref[j];
          item = JSON.parse(i);
          pk = item._id.$oid;
          id = item.clientId;
          date = (ref1 = item.date) != null ? ref1.$date : void 0;
          data = (item.data != null) && item.data.length > 0 ? JSON.parse(item.data) : null;
          points = data.points;
          planet = data.planet;
          controlPath = new P.Path();
          for (i = k = 0, len1 = points.length; k < len1; i = k += 4) {
            point = points[i];
            controlPath.add(R.view.grid.geoJSONToProject(point));
            controlPath.lastSegment.handleIn = new P.Point(points[i + 1]);
            controlPath.lastSegment.handleOut = new P.Point(points[i + 2]);
            controlPath.lastSegment.rtype = points[i + 3];
          }
          controlPath.flatten(5);
          path = [];
          ref2 = controlPath.segments;
          for (o = 0, len2 = ref2.length; o < len2; o++) {
            segment = ref2[o];
            if (nPoints < this.constructor.maxNumPoints) {
              path.push(segment.point);
            } else {
              this.drawingPaths.push(path);
              path.length = 0;
              path.push(segment.point);
            }
            nPoints++;
          }
          if (path.length > 1) {
            this.drawingPaths.push(path);
          }
          controlPath.remove();
        }
        this.sendNextPathsToTipibot();
      };

      Loader.prototype.sendNextPathsToTipibot = function() {
        var bounds, nPoints, path, paths;
        bounds = R.view.grid.limitCD.bounds;
        paths = [];
        nPoints = 0;
        while (this.drawingPaths.length > 0) {
          path = this.drawingPaths.shift();
          paths.push(path);
          nPoints += path.length;
          if (nPoints >= this.constructor.maxNumPoints) {
            break;
          }
        }
        R.socket.tipibotSocket.send(JSON.stringify({
          bounds: bounds,
          paths: paths,
          type: 'setNextDrawing',
          drawingPk: this.drawingPk
        }));
      };

      Loader.prototype.displayError = function(error) {
        R.alertManager.alert("An error occured, the page will reload in 2 seconds", "error");
        this.showLoadingBar(1000);
        setTimeout((function() {
          return window.location.reload();
        }), 2000);
      };

      Loader.prototype.checkError = function(result) {
        var j, len, manageEmails, modal, option, options, ref;
        if (result == null) {
          return true;
        }
        if (result.state === 'not_logged_in') {
          R.alertManager.alert("You must be logged in to update drawings to the database", "info");
          this.hideLoadingBar();
          return false;
        }
        if (result.state === 'error' || result.status === 'error') {
          if (result.message === 'invalid_url') {
            R.alertManager.alert("Your URL is invalid or does not point to an existing page", "error");
          } else {
            if (result.message === 'Please confirm your email by clicking on the activation link that was sent to your mailbox') {
              this.hideLoadingBar();
              modal = Modal.createModal({
                title: 'Please confirm your email',
                submit: ((function(_this) {
                  return function() {
                    return console.log('confirm');
                  };
                })(this))
              });
              modal.addText(result.message);
              manageEmails = (function(_this) {
                return function() {
                  window.location = '/accounts/email/';
                };
              })(this);
              modal.addButton({
                name: 'Manage emails',
                icon: 'glyphicon-envelope',
                type: 'info',
                submit: manageEmails
              });
              modal.show();
              return;
            }
            options = [];
            if (result.messageOptions != null) {
              ref = result.messageOptions;
              for (j = 0, len = ref.length; j < len; j++) {
                option = ref[j];
                options[option] = result[option];
              }
            }
            R.alertManager.alert(result.message, "error", null, options);
          }
          this.hideLoadingBar();
          return false;
        } else if (result.state === 'system_error' || result.status === 'system_error') {
          console.log(result.message);
          this.hideLoadingBar();
          return false;
        }
        return true;
      };


      /* Debug methods */

      Loader.prototype.updateDebugPaths = function(limit, bounds, t, l, b, r) {
        var ref, ref1, ref2;
        if ((ref = this.unloadRectangle) != null) {
          ref.remove();
        }
        this.unloadRectangle = new P.Path.Rectangle(limit);
        this.unloadRectangle.name = '@debug load unload rectangle';
        this.unloadRectangle.strokeWidth = 1;
        this.unloadRectangle.strokeColor = 'red';
        this.unloadRectangle.dashArray = [10, 4];
        R.view.debugLayer.addChild(this.unloadRectangle);
        if ((ref1 = this.viewRectangle) != null) {
          ref1.remove();
        }
        this.viewRectangle = new P.Path.Rectangle(bounds);
        this.viewRectangle.name = '@debug load view rectangle';
        this.viewRectangle.strokeWidth = 1;
        this.viewRectangle.strokeColor = 'blue';
        R.view.debugLayer.addChild(this.viewRectangle);
        if ((ref2 = this.limitRectangle) != null) {
          ref2.remove();
        }
        this.limitRectangle = new P.Path.Rectangle(new P.Point(l, t), new P.Point(r, b));
        this.limitRectangle.name = '@debug load limit rectangle';
        this.limitRectangle.strokeWidth = 2;
        this.limitRectangle.strokeColor = 'blue';
        this.limitRectangle.dashArray = [10, 4];
        R.view.debugLayer.addChild(this.limitRectangle);
      };

      Loader.prototype.updateDebugArea = function(area) {
        area.rectangle.strokeColor = 'red';
        this.removeDebugRectangle(area.rectangle);
      };

      Loader.prototype.removeDebugRectangle = function(rectangle) {
        var removeRect;
        removeRect = function() {
          return rectangle.remove();
        };
        setTimeout(removeRect, 1500);
      };

      Loader.prototype.createAreaDebugRectangle = function(x, y, scale) {
        var areaRectangle;
        areaRectangle = new P.Path.Rectangle(x, y, scale, scale);
        areaRectangle.name = '@debug load area rectangle';
        areaRectangle.strokeWidth = 1;
        areaRectangle.strokeColor = 'green';
        R.view.debugLayer.addChild(areaRectangle);
        area.rectangle = areaRectangle;
      };

      return Loader;

    })();
    return Loader;
  });

}).call(this);
