// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    hasProp = {}.hasOwnProperty,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['paper', 'R', 'Utils/Utils', 'Commands/Command', 'Items/Item', 'UI/ModuleLoader', 'Items/Drawing', 'Items/Divs/Text'], function(P, R, Utils, Command, Item, ModuleLoader, Drawing, Text) {
    var Loader, RasterizerLoader;
    Loader = (function() {
      Loader.maxNumPoints = 1000;

      function Loader() {
        this.checkError = bind(this.checkError, this);
        this.loadCallbackTipibot = bind(this.loadCallbackTipibot, this);
        this.loadCallback = bind(this.loadCallback, this);
        this.loadVotesCallback = bind(this.loadVotesCallback, this);
        this.loadVotes = bind(this.loadVotes, this);
        this.loadSVGCallback = bind(this.loadSVGCallback, this);
        this.hideLoadingBar = bind(this.hideLoadingBar, this);
        this.showLoadingBar = bind(this.showLoadingBar, this);
        this.showLoadingBarCallback = bind(this.showLoadingBarCallback, this);
        this.loadedAreas = [];
        this.debug = false;
        this.pathsToCreate = {};
        this.initializeLoadingBar();
        this.showLoadingBar();
        this.drawingPaths = [];
        this.drawingPk = null;
        this.focusOnDrawing = null;
        return;
      }

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

      Loader.prototype.showDrawingBar = function() {
        $("#drawingBar").show();
      };

      Loader.prototype.hideDrawingBar = function() {
        $("#drawingBar").hide();
      };

      Loader.prototype.showLoadingBarCallback = function() {
        $("#loadingBar").show();
      };

      Loader.prototype.showLoadingBar = function(timeout) {
        if ((timeout != null) && timeout > 0) {
          clearTimeout(this.showLoadingBarTimeoutId);
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
        var area, k, len, ref;
        ref = this.loadedAreas;
        for (k = 0, len = ref.length; k < len; k++) {
          area = ref[k];
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
        R.rasterizer.clearRasters();
        this.previousLoadPosition = null;
      };

      Loader.prototype.loadRequired = function() {
        if (this.previousLoadPosition != null) {
          if (this.previousLoadPosition.position.subtract(P.view.center).length < 50) {
            if (Math.abs(1 - this.previousLoadPosition.zoom / P.view.zoom) < 0.2) {
              return false;
            }
          }
        }
        return true;
      };

      Loader.prototype.getLoadingBounds = function(area) {
        if (area == null) {
          return P.view.bounds;
        }
        return area;
      };

      Loader.prototype.unloadAreas = function(area, limit, qZoom) {
        var i, id, item, itemsOutsideLimit, j, pos, rectangle, ref, ref1, ref2;
        itemsOutsideLimit = [];
        ref = R.items;
        for (id in ref) {
          if (!hasProp.call(ref, id)) continue;
          item = ref[id];
          if ((!((ref1 = item.getBounds()) != null ? ref1.intersects(limit) : void 0)) && (!item.isDraft())) {
            itemsOutsideLimit.push(item);
          }
        }
        i = this.loadedAreas.length;
        while (i--) {
          area = this.loadedAreas[i];
          pos = Utils.CS.posOnPlanetToProject(area.pos, area.planet);
          rectangle = new P.Rectangle(pos.x, pos.y, R.scale * area.zoom, R.scale * area.zoom);
          if (!rectangle.intersects(limit) || area.zoom !== qZoom) {
            if (this.debug) {
              this.updateDebugArea(area);
            }
            this.loadedAreas.splice(i, 1);
            j = itemsOutsideLimit.length;
            while (j--) {
              item = itemsOutsideLimit[j];
              if ((ref2 = item.getBounds()) != null ? ref2.intersects(rectangle) : void 0) {
                item.remove();
                itemsOutsideLimit.splice(j, 1);
              }
            }
          }
        }
      };

      Loader.prototype.getAreaToLoad = function(areasToLoad, pos, planet, x, y, scale, qZoom) {
        var area;
        if (!this.areaIsLoaded(pos, planet, qZoom)) {
          area = {
            pos: pos,
            planet: planet
          };
          areasToLoad.push(area);
          area.zoom = qZoom;
          if (this.debug) {
            this.createAreaDebugRectangle(x, y, scale);
          }
          this.loadedAreas.push(area);
        }
      };

      Loader.prototype.getAreasToLoad = function(scale, qZoom, t, l, b, r) {
        var areasToLoad, k, m, planet, pos, ref, ref1, ref2, ref3, ref4, ref5, x, y;
        areasToLoad = [];
        for (x = k = ref = l, ref1 = r, ref2 = scale; ref2 > 0 ? k <= ref1 : k >= ref1; x = k += ref2) {
          for (y = m = ref3 = t, ref4 = b, ref5 = scale; ref5 > 0 ? m <= ref4 : m >= ref4; y = m += ref5) {
            planet = Utils.CS.projectToPlanet(new P.Point(x, y));
            pos = Utils.CS.projectToPosOnPlanet(new P.Point(x, y));
            this.getAreaToLoad(areasToLoad, pos, planet, x, y, scale, qZoom);
          }
        }
        return areasToLoad;
      };

      Loader.prototype.nothingToLoad = function(areasToLoad) {
        return areasToLoad.length <= 0;
      };

      Loader.prototype.requestAreas = function(rectangle, areasToLoad, qZoom) {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'load',
              args: {
                rectangle: rectangle,
                areasToLoad: areasToLoad,
                qZoom: qZoom,
                city: R.city
              }
            })
          }
        }).done(this.loadCallback);
      };

      Loader.prototype.loadAll = function() {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadAll',
              args: {
                city: R.city
              }
            })
          }
        }).done((function(_this) {
          return function(results) {
            var draft, drawing, i, k, len, ref, showDrawing;
            if (!R.loader.checkError(results)) {
              return;
            }
            R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(400), true);
            ref = R.drawings;
            for (k = 0, len = ref.length; k < len; k++) {
              drawing = ref[k];
              drawing.remove();
            }
            draft = R.Drawing.getDraft();
            if (draft == null) {
              draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft');
            }
            i = 0;
            showDrawing = function() {
              var item;
              item = results.items[i++];
              if (item == null) {
                return;
              }
              draft.removePaths();
              draft = new Item.Drawing(null, null, null, null, R.me, Date.now(), null, null, 'draft');
              drawing = JSON.parse(item);
              console.log(drawing.pathList);
              draft.addPathsFromPathList(drawing.pathList, true, true);
              setTimeout(showDrawing, 200);
            };
            showDrawing();
          };
        })(this));
      };

      Loader.prototype.loadSVG = function() {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadSVG',
              args: {
                city: R.city
              }
            })
          }
        }).done(this.loadSVGCallback);
      };

      Loader.prototype.loadSVGCallback = function(results) {
        var bounds, date, drawing, drawingPk, item, itemString, k, len, len1, m, ref, ref1, ref2, ref3;
        if (!this.checkError(results)) {
          return;
        }
        if (results.user != null) {
          this.setMe(results.user);
        }
        R.nRejectedDrawings = 0;
        ref = results.items;
        for (k = 0, len = ref.length; k < len; k++) {
          itemString = ref[k];
          item = JSON.parse(itemString);
          if (item.status === 'rejected') {
            if (R.rejectedDrawings == null) {
              R.rejectedDrawings = [];
            }
            R.rejectedDrawings.push(item);
            R.nRejectedDrawings++;
            continue;
          }
          if (((ref1 = R.pkToDrawing) != null ? ref1[item._id.$oid] : void 0) != null) {
            continue;
          }
          bounds = item.bounds != null ? JSON.parse(item.bounds) : null;
          date = (ref2 = item.date) != null ? ref2.$date : void 0;
          drawing = new Item.Drawing(null, null, item.clientId, item._id.$oid, item.owner, date, item.title, null, item.status, item.pathList, item.svg, bounds);
        }
        if (R.view.rejectedListJ != null) {
          R.view.rejectedListJ.find(".n-items").html(R.nRejectedDrawings);
        }
        this.endLoading();
        R.toolManager.updateButtonsVisibility();
        if (this.focusOnDrawing != null) {
          drawingPk = this.focusOnDrawing;
          ref3 = R.drawings;
          for (m = 0, len1 = ref3.length; m < len1; m++) {
            drawing = ref3[m];
            if (drawing.pk === drawingPk) {
              bounds = drawing.getBounds();
              if (bounds != null) {
                R.view.fitRectangle(bounds, true);
              }
              break;
            }
          }
          this.focusOnDrawing = null;
        }
        this.loadVotes();
      };

      Loader.prototype.loadVotes = function() {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadVotes',
              args: {
                city: R.city
              }
            })
          }
        }).done(this.loadVotesCallback);
      };

      Loader.prototype.loadVotesCallback = function(results) {
        var k, len, ref, ref1, vote;
        if (results.state !== 'not_logged_in') {
          if (!this.checkError(results)) {
            return;
          }
        }
        if (results.votes != null) {
          ref = results.votes;
          for (k = 0, len = ref.length; k < len; k++) {
            vote = ref[k];
            if (vote.emailConfirmed) {
              if ((ref1 = R.items[vote.pk]) != null) {
                ref1.setStrokeColorFromVote(vote.positive);
              }
            }
          }
        }
      };

      Loader.prototype.load = function(area) {
        var areasToLoad, b, bounds, l, limit, qZoom, r, rectangle, scale, t, unloadDist;
        if (area == null) {
          area = null;
        }
        if (!this.loadRequired()) {
          return false;
        }
        debugger;
        if (area != null) {
          console.log(area.toString());
        }
        this.previousLoadPosition = {
          position: P.view.center,
          zoom: P.view.zoom
        };
        bounds = this.getLoadingBounds(area);
        unloadDist = Math.round(R.scale / P.view.zoom);
        limit = R.view.entireArea || bounds.expand(unloadDist);
        R.rasterizer.unload(limit);
        qZoom = Utils.CS.quantizeZoom(1.0 / P.view.zoom);
        this.unloadAreas(area, limit, qZoom);
        scale = R.scale * qZoom;
        t = Utils.floorToMultiple(bounds.top, scale);
        l = Utils.floorToMultiple(bounds.left, scale);
        b = Utils.floorToMultiple(bounds.bottom, scale);
        r = Utils.floorToMultiple(bounds.right, scale);
        if (this.debug) {
          this.updateDebugPaths(limit, bounds, t, l, b, r);
        }
        areasToLoad = this.getAreasToLoad(scale, qZoom, t, l, b, r);
        if (this.nothingToLoad(areasToLoad)) {
          return false;
        }
        this.showDrawingBar();
        this.showLoadingBar(500);
        rectangle = {
          left: l / 1000.0,
          top: t / 1000.0,
          right: r / 1000.0,
          bottom: b / 1000.0
        };
        this.requestAreas(rectangle, areasToLoad, qZoom);
        return true;
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
        var i, item, itemsToLoad, k, len;
        itemsToLoad = [];
        for (k = 0, len = items.length; k < len; k++) {
          i = items[k];
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
        var base;
        this.createPath(args);
        delete this.pathsToCreate[args.id];
        if (Utils.isEmpty(this.pathsToCreate)) {
          this.hideDrawingBar();
          this.hideLoadingBar();
          if (typeof (base = R.rasterizer).checkRasterizeAreasToUpdate === "function") {
            base.checkRasterizeAreasToUpdate(true);
          }
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
        var args, data, date, drawing, id, item, k, len, len1, lock, m, newItems, newPath, path, pk, planet, point, points, ref, ref1, rpath;
        newItems = [];
        for (k = 0, len = itemsToLoad.length; k < len; k++) {
          item = itemsToLoad[k];
          pk = item._id.$oid;
          id = item.clientId;
          date = (ref = item.date) != null ? ref.$date : void 0;
          data = (item.data != null) && item.data.length > 0 ? JSON.parse(item.data) : null;
          lock = item.lock != null ? R.items[item.lock] : null;
          switch (item.rType) {
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
              for (m = 0, len1 = ref1.length; m < len1; m++) {
                point = ref1[m];
                points.push(Utils.CS.posOnPlanetToProject(point, planet));
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
            case 'AreaToUpdate':
              R.rasterizer.addAreaToUpdate(Utils.CS.rectangleFromBox(item).expand(5));
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
        if (results.rasters != null) {
          R.rasterizer.load(results.rasters, results.qZoom);
        }
        this.removeDeletedItems(results.deletedItems);
        itemsToLoad = this.parseNewItems(results.items);
        newItems = this.createNewItems(itemsToLoad);
        R.rasterizer.setQZoomToUpdate(results.qZoom);
        if (rasterizeItems) {
          R.rasterizer.rasterize(newItems);
          R.rasterizer.rasterizeRectangle();
        }
        if (rasterizeAreasToUpdate) {
          if ((results.rasters == null) || results.rasters.length === 0) {
            R.rasterizer.checkRasterizeAreasToUpdate();
          }
        }
        Item.Div.updateZindex(R.sortedDivs);
        this.endLoading();
      };

      Loader.prototype.loadCallbackTipibot = function(results) {
        var controlPath, data, date, i, id, item, itemsToLoad, k, len, len1, len2, m, n, nPoints, path, pk, planet, point, points, ref, ref1, ref2, segment;
        if (!this.checkError(results)) {
          return;
        }
        itemsToLoad = [];
        this.drawingPaths = [];
        this.drawingPk = results.pk;
        nPoints = 0;
        ref = results.items;
        for (k = 0, len = ref.length; k < len; k++) {
          i = ref[k];
          item = JSON.parse(i);
          pk = item._id.$oid;
          id = item.clientId;
          date = (ref1 = item.date) != null ? ref1.$date : void 0;
          data = (item.data != null) && item.data.length > 0 ? JSON.parse(item.data) : null;
          points = data.points;
          planet = data.planet;
          controlPath = new P.Path();
          for (i = m = 0, len1 = points.length; m < len1; i = m += 4) {
            point = points[i];
            controlPath.add(Utils.CS.posOnPlanetToProject(point, planet));
            controlPath.lastSegment.handleIn = new P.Point(points[i + 1]);
            controlPath.lastSegment.handleOut = new P.Point(points[i + 2]);
            controlPath.lastSegment.rtype = points[i + 3];
          }
          controlPath.flatten(5);
          path = [];
          ref2 = controlPath.segments;
          for (n = 0, len2 = ref2.length; n < len2; n++) {
            segment = ref2[n];
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

      Loader.prototype.checkError = function(result) {
        var k, len, option, options, ref;
        if (result == null) {
          return true;
        }
        if (result.state === 'not_logged_in') {
          R.alertManager.alert("You must be logged in to update drawings to the database", "info");
          this.hideLoadingBar();
          return false;
        }
        if (result.state === 'error') {
          if (result.message === 'invalid_url') {
            R.alertManager.alert("Your URL is invalid or does not point to an existing page", "error");
          } else {
            options = [];
            if (result.messageOptions != null) {
              ref = result.messageOptions;
              for (k = 0, len = ref.length; k < len; k++) {
                option = ref[k];
                options[option] = result[option];
              }
            }
            R.alertManager.alert(result.message, "error", null, options);
          }
          this.hideLoadingBar();
          return false;
        } else if (result.state === 'system_error') {
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
    RasterizerLoader = (function(superClass) {
      extend(RasterizerLoader, superClass);

      function RasterizerLoader() {
        return RasterizerLoader.__super__.constructor.apply(this, arguments);
      }

      RasterizerLoader.prototype.loadRequired = function() {
        return true;
      };

      RasterizerLoader.prototype.nothingToLoad = function(areasToLoad) {
        return false;
      };

      RasterizerLoader.prototype.getAreaToLoad = function(areasToLoad, pos, planet, x, y, scale, qZoom) {
        var area;
        area = {
          pos: pos,
          planet: planet
        };
        areasToLoad.push(area);
        if (this.debug) {
          this.createAreaDebugRectangle(x, y, scale);
        }
        if (!this.areaIsLoaded(pos, planet)) {
          this.loadedAreas.push(area);
        }
      };

      RasterizerLoader.prototype.createItemsDates = function() {
        var id, item, itemsDates, ref;
        itemsDates = {};
        ref = R.items;
        for (id in ref) {
          item = ref[id];
          itemsDates[id] = item.lastUpdateDate;
        }
        return itemsDates;
      };

      RasterizerLoader.prototype.mustLoadItem = function() {
        return true;
      };

      RasterizerLoader.prototype.unloadItem = function(item) {
        var itemToReplace;
        itemToReplace = R.items[item._id.$oid];
        if (itemToReplace != null) {
          console.log("itemToReplace: " + itemToReplace.id);
          itemToReplace.remove();
        }
      };

      RasterizerLoader.prototype.endLoading = function() {
        if (typeof window.saveOnServer === "function") {
          R.rasterizerBot.rasterizeAndSaveOnServer();
        }
      };

      return RasterizerLoader;

    })(Loader);
    Loader.RasterizerLoader = RasterizerLoader;
    return Loader;
  });

}).call(this);

//# sourceMappingURL=Loader.js.map
