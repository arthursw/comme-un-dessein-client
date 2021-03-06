// Generated by CoffeeScript 1.12.7
(function() {
  var dependencies,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  dependencies = ['paper', 'R', 'Utils/Utils', 'View/Grid', 'Commands/Command', 'Items/Paths/Path', 'Items/Divs/Div'];

  if (typeof document !== "undefined" && document !== null) {
    dependencies.push('i18next');
    dependencies.push('hammer');
    dependencies.push('mousewheel');
  }

  define('View/View', dependencies, function(P, R, Utils, Grid, Command, Path, Div, i18next, Hammer, mousewheel) {
    var View;
    View = (function() {
      View.thumbnailSize = 300;

      function View() {
        this.mousewheel = bind(this.mousewheel, this);
        this.mouseup = bind(this.mouseup, this);
        this.mousemove = bind(this.mousemove, this);
        this.mousedown = bind(this.mousedown, this);
        this.onWindowResize = bind(this.onWindowResize, this);
        this.onFrame = bind(this.onFrame, this);
        this.onKeyUp = bind(this.onKeyUp, this);
        this.onKeyDown = bind(this.onKeyDown, this);
        this.onMouseUp = bind(this.onMouseUp, this);
        this.onMouseDrag = bind(this.onMouseDrag, this);
        this.onMouseDown = bind(this.onMouseDown, this);
        this.onHashChange = bind(this.onHashChange, this);
        this.updateHash = bind(this.updateHash, this);
        this.addMoveCommand = bind(this.addMoveCommand, this);
        this.showDraftLayer = bind(this.showDraftLayer, this);
        this.hideDraftLayer = bind(this.hideDraftLayer, this);
        var hammertime;
        R.stageJ = $("#stage");
        R.canvasJ = R.stageJ.find("#canvas");
        R.canvas = R.canvasJ[0];
        R.canvas.width = typeof window !== "undefined" && window !== null ? R.stageJ.innerWidth() : R.canvasWidth;
        R.canvas.height = typeof window !== "undefined" && window !== null ? R.stageJ.innerHeight() : R.canvasHeight;
        R.context = R.canvas.getContext('2d');
        paper.setup(R.canvas);
        R.project = P.project;
        this.mainLayer = P.project.activeLayer;
        this.mainLayer.name = 'mainLayer';
        this.createLayers();
        this.debugLayer = new P.Layer();
        this.debugLayer.name = 'debugLayer';
        this.selectionLayer = new P.Layer();
        this.selectionLayer.name = 'selectionLayer';
        this.areasToUpdateLayer = new P.Layer();
        this.areasToUpdateLayer.name = 'areasToUpdateLayer';
        this.backgroundRectangle = null;
        this.areasToUpdateLayer.visible = false;
        paper.settings.hitTolerance = 5;
        R.scale = 1000.0;
        P.view.zoom = 1;
        this.previousPosition = P.view.center;
        this.restrictedArea = null;
        this.entireArea = null;
        this.entireAreas = [];
        this.grid = new Grid();
        this.mainLayer.activate();
        R.canvasJ.dblclick(function(event) {
          var ref;
          return (ref = R.selectedTool) != null ? typeof ref.doubleClick === "function" ? ref.doubleClick(event) : void 0 : void 0;
        });
        R.canvasJ.keydown(function(event) {
          if (event.key === 46) {
            event.preventDefault();
            return false;
          }
        });
        this.tool = new P.Tool();
        this.tool.onMouseDown = this.onMouseDown;
        this.tool.onMouseDrag = this.onMouseDrag;
        this.tool.onMouseUp = this.onMouseUp;
        this.tool.onKeyDown = this.onKeyDown;
        this.tool.onKeyUp = this.onKeyUp;
        P.view.onFrame = this.onFrame;
        R.stageJ.mousewheel(this.mousewheel);
        R.stageJ.mousedown(this.mousedown);
        R.stageJ.on({
          touchstart: this.mousedown
        });
        R.stageJ.on({
          touchmove: this.mousemove
        });
        $(window).on({
          touchmove: function(event) {
            if (!$(event.target).parents('.scroll')[0]) {
              event.stopPropagation();
              event.preventDefault();
              return -1;
            }
          }
        });
        if (typeof window !== "undefined" && window !== null) {
          $(window).mousemove(this.mousemove);
          $(window).mouseup(this.mouseup);
          $(window).on({
            touchend: this.mouseup
          });
          $(window).on({
            touchleave: this.mouseup
          });
          $(window).on({
            touchcancel: this.mouseup
          });
          $(window).resize(this.onWindowResize);
          window.onhashchange = this.onHashChange;
          hammertime = new Hammer(R.canvas);
          hammertime.get('pinch').set({
            enable: true
          });
          hammertime.on('pinch', (function(_this) {
            return function(event) {
              console.log(event.scale);
              R.toolManager.zoom(event.scale, false);
            };
          })(this));
        }
        this.mousePosition = new P.Point();
        this.previousMousePosition = null;
        this.initialMousePosition = null;
        this.firstHashChange = true;
        this.createThumbnailProject();
        return;
      }

      View.prototype.createThumbnailProject = function() {
        this.thumbnailCanvas = document.createElement('canvas');
        this.thumbnailCanvas.width = this.constructor.thumbnailSize;
        this.thumbnailCanvas.height = this.constructor.thumbnailSize;
        $('body').append(this.thumbnailCanvas);
        this.thumbnailProject = new P.Project(this.thumbnailCanvas);
        paper.projects[0].activate();
      };

      View.prototype.getThumbnail = function(drawing, sizeX, sizeY, toDataURL, blackStroke) {
        var i, len, path, rectangle, rectangleRatio, ref, result, viewRatio;
        if (sizeX == null) {
          sizeX = this.constructor.thumbnailSize;
        }
        if (sizeY == null) {
          sizeY = this.constructor.thumbnailSize;
        }
        if (toDataURL == null) {
          toDataURL = false;
        }
        if (blackStroke == null) {
          blackStroke = false;
        }
        this.thumbnailProject.activate();
        this.thumbnailProject.view.viewSize = new P.Size(sizeX, sizeY);
        this.thumbnailCanvas.width = sizeX;
        this.thumbnailCanvas.height = sizeY;
        rectangle = drawing.getBounds();
        if (rectangle == null) {
          return null;
        }
        viewRatio = 1;
        rectangleRatio = rectangle.width / rectangle.height;
        if ((drawing.svg == null) && (drawing.paths != null) && drawing.paths.length > 0) {
          ref = drawing.paths;
          for (i = 0, len = ref.length; i < len; i++) {
            path = ref[i];
            this.thumbnailProject.activeLayer.addChild(path.path);
          }
        }
        if (viewRatio < rectangleRatio) {
          this.thumbnailProject.view.zoom = Math.min(sizeX / rectangle.width, 1);
        } else {
          this.thumbnailProject.view.zoom = Math.min(sizeY / rectangle.height, 1);
        }
        this.thumbnailProject.view.setCenter(rectangle.center);
        this.thumbnailProject.activeLayer.name = 'mainLayer';
        this.thumbnailProject.activeLayer.strokeColor = blackStroke ? 'black' : R.Path.colorMap[drawing.status];
        if (blackStroke) {
          this.thumbnailProject.activeLayer.strokeWidth = 3;
        } else {
          this.thumbnailProject.activeLayer.strokeWidth = R.Path.strokeWidth;
        }
        this.thumbnailProject.view.update();
        this.thumbnailProject.view.draw();
        result = toDataURL ? this.thumbnailCanvas.toDataURL() : this.thumbnailProject.exportSVG();
        if ((drawing.svg != null) && !toDataURL) {
          $(result).find('#mainLayer').append(drawing.svg.cloneNode(true));
        }
        this.thumbnailProject.clear();
        paper.projects[0].activate();
        return result;
      };

      View.prototype.createBackground = function() {
        if (R.drawingMode === 'image' && (this.backgroundImage == null)) {
          this.backgroundImage = new P.Raster('static/images/rennes.jpg');
          this.backgroundImage.onLoad = (function(_this) {
            return function() {
              _this.backgroundImage.width = _this.grid.limitCD.bounds.width;
              _this.backgroundImage.height = _this.grid.limitCD.bounds.height;
            };
          })(this);
          this.backgroundImage.opacity = 0.5;
          P.project.layers[1].addChild(this.backgroundImage);
          this.backgroundImage.sendToBack();
          this.backgroundListJ = this.createLayerListItem('Background', this.backgroundImage, true, false, false);
        } else if (R.drawingMode !== 'image' && (this.backgroundImage != null)) {
          this.backgroundImage.remove();
          this.backgroundImage = null;
          this.backgroundListJ.remove();
        }
      };

      View.prototype.createLayerListItem = function(title, item, noArrow, prepend, badge) {
        var itemListJ, nItemsJ, showBtnJ, titleJ;
        if (noArrow == null) {
          noArrow = false;
        }
        if (prepend == null) {
          prepend = true;
        }
        if (badge == null) {
          badge = true;
        }
        itemListJ = R.templatesJ.find(".layer").clone();
        itemListJ.attr('data-name', item.name);
        nItemsJ = itemListJ.find(".n-items");
        nItemsJ.addClass(title.toLowerCase() + '-color');
        titleJ = itemListJ.find(".title");
        titleJ.attr('data-i18n', title);
        titleJ.text(i18next.t(title));
        if (noArrow) {
          titleJ.addClass('no-arrow');
        }
        if (!noArrow) {
          titleJ.click((function(_this) {
            return function(event) {
              itemListJ.toggleClass('closed');
              if (!event.shiftKey) {
                R.tools.select.deselectAll();
              }
            };
          })(this));
        }
        showBtnJ = itemListJ.find(".show-btn");
        item.data.setVisibility = (function(_this) {
          return function(visible) {
            var SVGLayerJ, base, base1, child, eyeIconJ, i, len, ref;
            R.tools.select.deselectAll();
            item.visible = visible;
            ref = item.children;
            for (i = 0, len = ref.length; i < len; i++) {
              child = ref[i];
              if ((child.controller != null) && child.controller instanceof Path && (child.controller.drawing == null)) {
                if (typeof (base = child.controller).draw === "function") {
                  base.draw();
                }
                if (typeof (base1 = child.controller).rasterize === "function") {
                  base1.rasterize();
                }
              }
            }
            R.rasterizer.refresh();
            SVGLayerJ = document.getElementById(item.name);
            SVGLayerJ.setAttribute('visibility', visible ? 'visible' : 'hidden');
            eyeIconJ = itemListJ.find("span.eye");
            if (item.visible) {
              eyeIconJ.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
            } else {
              eyeIconJ.removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close');
            }
          };
        })(this);
        if (!item.visible) {
          itemListJ.find("span.eye").removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close');
        }
        showBtnJ.mousedown((function(_this) {
          return function(event) {
            item.data.setVisibility(!item.visible);
            event.preventDefault();
            event.stopPropagation();
            return -1;
          };
        })(this));
        if (prepend) {
          R.sidebar.itemListsJ.prepend(itemListJ);
        } else {
          R.sidebar.itemListsJ.append(itemListJ);
        }
        if (!badge) {
          itemListJ.find('span.badge').hide();
        }
        return itemListJ;
      };

      View.prototype.hideDraftLayer = function() {
        this.mainLayer.data.setVisibility(false);
      };

      View.prototype.showDraftLayer = function() {
        this.mainLayer.data.setVisibility(true);
      };

      View.prototype.createLayers = function() {
        this.rejectedLayer = new P.Layer();
        this.rejectedLayer.name = 'rejectedLayer';
        this.rejectedLayer.visible = false;
        this.rejectedLayer.strokeColor = Path.colorMap['rejected'];
        this.rejectedLayer.strokeWidth = Path.strokeWidth;
        this.pendingLayer = new P.Layer();
        this.pendingLayer.name = 'pendingLayer';
        this.pendingLayer.strokeColor = Path.colorMap['pending'];
        this.pendingLayer.strokeWidth = Path.strokeWidth;
        this.drawingLayer = new P.Layer();
        this.drawingLayer.name = 'drawingLayer';
        this.drawingLayer.strokeColor = Path.colorMap['drawing'];
        this.drawingLayer.strokeWidth = Path.strokeWidth;
        this.drawnLayer = new P.Layer();
        this.drawnLayer.name = 'drawnLayer';
        this.drawnLayer.strokeColor = Path.colorMap['drawn'];
        this.drawnLayer.strokeWidth = Path.strokeWidth;
        this.draftLayer = new P.Layer();
        this.draftLayer.name = 'draftLayer';
        this.draftLayer.strokeColor = Path.colorMap['draft'];
        this.draftLayer.strokeWidth = Path.strokeWidth;
        this.flaggedLayer = new P.Layer();
        this.flaggedLayer.name = 'flaggedLayer';
        this.flaggedLayer.strokeWidth = Path.strokeWidth;
        if (R.city.finished) {
          this.pendingLayer.visible = false;
        }
        this.flaggedLayer.visible = false;
        if (!R.administrator) {
          this.rejectedLayer.visible = false;
        } else {
          this.testLayer = new P.Layer();
          this.testLayer.name = 'testLayer';
          this.testLayer.strokeColor = Path.colorMap['test'];
          this.testLayer.strokeWidth = Path.strokeWidth;
          this.flaggedLayer.strokeColor = Path.colorMap['flagged'];
        }
        this.draftListJ = this.createLayerListItem('Draft', this.draftLayer, true);
        this.pendingListJ = this.createLayerListItem('Pending', this.pendingLayer);
        this.pendingListJ.removeClass('closed');
        this.drawingListJ = this.createLayerListItem('Drawing', this.drawingLayer);
        this.drawnListJ = this.createLayerListItem('Drawn', this.drawnLayer);
        this.rejectedListJ = this.createLayerListItem('Rejected', this.rejectedLayer);
        this.flaggedListJ = this.createLayerListItem('Flagged', this.flaggedLayer);
        if (R.administrator) {
          this.testListJ = this.createLayerListItem('Test', this.testLayer);
        }
        this.rejectedListJ.find(".show-btn").click((function(_this) {
          return function(event) {
            _this.loadRejectedDrawings();
            event.preventDefault();
            event.stopPropagation();
            return -1;
          };
        })(this));
        if (!R.administrator) {
          this.flaggedListJ.hide();
        }
      };

      View.prototype.loadRejectedDrawings = function() {
        var bounds, date, drawing, i, item, len, ref, ref1, ref2;
        if (R.rejectedDrawingsLoaded) {
          return;
        }
        R.rejectedDrawingsLoaded = true;
        ref = R.rejectedDrawings;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (((ref1 = R.pkToDrawing) != null ? ref1[item._id.$oid] : void 0) != null) {
            continue;
          }
          bounds = item.bounds != null ? JSON.parse(item.bounds) : null;
          date = (ref2 = item.date) != null ? ref2.$date : void 0;
          drawing = new R.Drawing(null, null, item.clientId, item._id.$oid, item.owner, date, item.title, null, item.status, item.pathList, item.svg, bounds);
        }
      };

      View.prototype.getViewBounds = function(considerPanels) {
        var bottomRight, drawingPanelWidth, sidebarWidth, topLeft;
        if (R.stageJ.innerWidth() < 600) {
          considerPanels = false;
        }
        if (considerPanels) {
          sidebarWidth = R.sidebar.isOpened() ? R.sidebar.sidebarJ.outerWidth() : 0;
          drawingPanelWidth = R.drawingPanel.isOpened() ? R.drawingPanel.drawingPanelJ.outerWidth() : 0;
          topLeft = P.view.viewToProject(new P.Point(sidebarWidth, R.stageJ.offset().top));
          bottomRight = P.view.viewToProject(new P.Point(R.stageJ.innerWidth() - drawingPanelWidth, R.stageJ.innerHeight() - R.stageJ.offset().top));
          return new P.Rectangle(topLeft, bottomRight);
        }
        return P.view.bounds;
      };

      View.prototype.moveTo = function(pos, delay, addCommand, preventLoad, updateHash) {
        var somethingToLoad;
        if (delay == null) {
          delay = null;
        }
        if (addCommand == null) {
          addCommand = true;
        }
        if (preventLoad == null) {
          preventLoad = false;
        }
        if (updateHash == null) {
          updateHash = true;
        }
        if (pos == null) {
          pos = new P.Point();
        }
        somethingToLoad = this.moveBy(pos.subtract(P.view.center), addCommand, preventLoad, updateHash);
        return somethingToLoad;
      };

      View.prototype.moveBy = function(delta, addCommand, preventLoad, updateHash) {
        var area, div, i, j, len, len1, newEntireArea, newView, previousCenter, ref, ref1, ref2, restrictedAreaShrinked, somethingToLoad;
        if (addCommand == null) {
          addCommand = true;
        }
        if (preventLoad == null) {
          preventLoad = false;
        }
        if (updateHash == null) {
          updateHash = true;
        }
        if (this.restrictedArea != null) {
          if (!this.restrictedArea.contains(P.view.center)) {
            delta = this.restrictedArea.center.subtract(P.view.center);
          } else {
            newView = this.getViewBounds(true);
            previousCenter = newView.center.clone();
            newView.center.x += delta.x;
            newView.center.y += delta.y;
            if (!this.restrictedArea.contains(newView)) {
              restrictedAreaShrinked = this.restrictedArea.expand(newView.size.multiply(-1));
              if (restrictedAreaShrinked.width < 0) {
                restrictedAreaShrinked.left = restrictedAreaShrinked.right = this.restrictedArea.center.x;
              }
              if (restrictedAreaShrinked.height < 0) {
                restrictedAreaShrinked.top = restrictedAreaShrinked.bottom = this.restrictedArea.center.y;
              }
              newView.center.x = Utils.clamp(restrictedAreaShrinked.left, newView.center.x, restrictedAreaShrinked.right);
              newView.center.y = Utils.clamp(restrictedAreaShrinked.top, newView.center.y, restrictedAreaShrinked.bottom);
              delta = newView.center.subtract(previousCenter);
            }
          }
        }
        if (this.previousPosition == null) {
          this.previousPosition = P.view.center;
        }
        P.view.scrollBy(new P.Point(delta.x, delta.y));
        this.updateSVG();
        ref = R.divs;
        for (i = 0, len = ref.length; i < len; i++) {
          div = ref[i];
          div.updateTransform();
        }
        R.rasterizer.move();
        this.grid.update();
        newEntireArea = null;
        ref1 = this.entireAreas;
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          area = ref1[j];
          if ((ref2 = area.getBounds()) != null ? ref2.contains(P.view.center) : void 0) {
            newEntireArea = area;
            break;
          }
        }
        if ((this.entireArea == null) && (newEntireArea != null)) {
          this.entireArea = newEntireArea.getBounds();
        } else if ((this.entireArea != null) && (newEntireArea == null)) {
          this.entireArea = null;
        }
        somethingToLoad = false;
        R.socket.updateRoom();
        if (updateHash) {
          Utils.deferredExecution(this.updateHash, 'updateHash', 500);
        }
        return somethingToLoad;
      };

      View.prototype.fitRectangle = function(rectangle, considerPanels, zoom, updateHash) {
        var drawingPanelWidth, offset, rectangleRatio, sidebarWidth, viewRatio, visibleViewCenterInView, windowCenterInView, windowSize;
        if (considerPanels == null) {
          considerPanels = false;
        }
        if (zoom == null) {
          zoom = null;
        }
        if (updateHash == null) {
          updateHash = true;
        }
        windowSize = new P.Size(R.stageJ.innerWidth(), R.stageJ.innerHeight());
        if (windowSize.width < 600) {
          considerPanels = false;
        }
        sidebarWidth = considerPanels && R.sidebar.isOpened() ? R.sidebar.sidebarJ.outerWidth() : 0;
        drawingPanelWidth = considerPanels && R.drawingPanel.isOpened() ? R.drawingPanel.drawingPanelJ.outerWidth() : 0;
        windowSize.width = windowSize.width - sidebarWidth - drawingPanelWidth;
        viewRatio = windowSize.width / windowSize.height;
        rectangleRatio = rectangle.width / rectangle.height;
        if (zoom == null) {
          if (viewRatio < rectangleRatio) {
            P.view.zoom = Math.min(windowSize.width / rectangle.width, 1);
          } else {
            P.view.zoom = Math.min(windowSize.height / rectangle.height, 1);
          }
        } else {
          P.view.zoom = zoom;
        }
        if (considerPanels) {
          windowCenterInView = P.view.viewToProject(new P.Point(windowSize.width / 2, windowSize.height / 2));
          visibleViewCenterInView = P.view.viewToProject(new P.Point(sidebarWidth + windowSize.width / 2, windowSize.height / 2));
          offset = visibleViewCenterInView.subtract(windowCenterInView);
          this.moveTo(rectangle.center.subtract(offset), null, true, false, updateHash);
        } else {
          this.moveTo(rectangle.center, null, true, false, updateHash);
        }
        this.updateSVG();
      };

      View.prototype.updateSVG = function() {
        var transform;
        if (R.svgJ != null) {
          transform = Utils.getSVGTransform(P.view.matrix);
          R.svgJ.find('g:first').attr('transform', transform.transform);
        }
      };

      View.prototype.addMoveCommand = function() {
        R.commandManager.add(new Command.MoveView(this.previousPosition, P.view.center));
        this.previousPosition = null;
      };

      View.prototype.updateHash = function() {
        var hashParameters;
        hashParameters = {};
        if (R.repository.commit != null) {
          hashParameters['repository-owner'] = R.repository.owner;
          hashParameters['repository-commit'] = R.repository.commit;
        }
        hashParameters['location'] = Utils.pointToString(P.view.center);
        hashParameters['zoom'] = P.view.zoom.toFixed(3).replace(/\.?0+$/, '');
        if (R.administrator) {
          hashParameters['administrator'] = true;
        }
        if (R.tipibot != null) {
          hashParameters['tipibot'] = true;
        }
        this.ignoreHashChange = true;
        location.hash = Utils.URL.setParameters(hashParameters);
      };

      View.prototype.setPositionFromString = function(positionString) {
        this.moveTo(Utils.stringToPoint(positionString));
      };

      View.prototype.onHashChange = function(event, reloadIfNecessary) {
        var drawingPk, drawingPrefixIndex, mustReload, p, parameters, ref, zoom;
        if (reloadIfNecessary == null) {
          reloadIfNecessary = true;
        }
        if (this.ignoreHashChange) {
          this.ignoreHashChange = false;
          return;
        }
        parameters = Utils.URL.getParameters(document.location.hash);
        if ((R.repository.commit != null) && (R.repository.owner !== parameters['repository-owner'] || R.repository.commit !== parameters['repository-commit'])) {
          location.reload();
          return;
        }
        if (parameters['location'] != null) {
          p = Utils.stringToPoint(parameters['location']);
        }
        if (parameters['zoom'] != null) {
          zoom = parseFloat(parameters['zoom']);
          if ((zoom != null) && Number.isFinite(zoom)) {
            P.view.zoom = Math.max(0.125, Math.min(4, zoom));
            if ((ref = R.tracer) != null) {
              ref.update();
            }
          }
        }
        mustReload = false;
        R.tipibot = parameters['tipibot'];
        mustReload |= parameters['style'] !== R.style;
        R.style = parameters['style'];
        if (parameters['administrator'] != null) {
          R.administrator = parameters['administrator'];
        }
        drawingPrefixIndex = location.pathname.indexOf('/drawing-');
        if (drawingPrefixIndex >= 0) {
          drawingPrefixIndex = drawingPrefixIndex + '/drawing-'.length;
        } else {
          drawingPrefixIndex = location.pathname.indexOf('/debug-drawing-');
          if (drawingPrefixIndex >= 0) {
            drawingPrefixIndex = drawingPrefixIndex + '/debug-drawing-'.length;
          }
        }
        if (drawingPrefixIndex >= 0) {
          drawingPk = location.pathname.substring(drawingPrefixIndex);
          R.loader.focusOnDrawing = drawingPk;
        }
        this.moveTo(p, null, !this.firstHashChange, this.firstHashChange, false);
        this.firstHashChange = true;
        if (reloadIfNecessary && mustReload) {
          window.location.reload();
        }
      };

      View.prototype.loadCity = function() {
        this.gird.createFrame();
        this.initializePosition();
      };

      View.prototype.initializePosition = function() {
        var boxRectangle, br, controller, defsJ, folder, folderName, i, len, patternRejectsJ, patternValidateJ, planet, pos, ref, ref1, site, siteString, svg, tl;
        if (R.city == null) {
          R.city = {};
        }
        R.city.city = R.canvasJ.attr("data-city") !== '' ? R.canvasJ.attr("data-city") : void 0;
        if (R.city.name !== 'world') {
          this.restrictedArea = this.grid.limitCD.bounds.expand(100);
        }
        P.view.zoom = 0.5;
        P.view.scrollBy(1, 1);
        svg = P.project.exportSVG();
        R.svgJ = $(svg);
        R.svgJ.insertAfter(R.canvasJ);
        defsJ = $('<defs>');
        patternValidateJ = $("<pattern id='pattern-validate' width='8' height='8' patternUnits='userSpaceOnUse'>");
        patternValidateJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='green' stroke-width='4.5'/>");
        patternRejectsJ = $("<pattern id='pattern-reject' width='8' height='8' patternUnits='userSpaceOnUse'>");
        patternRejectsJ.append("<path d='M-2 10L10 -2ZM10 6L6 10ZM-2 2L2 -2' stroke='red' stroke-width='4.5'/>");
        defsJ.append(patternValidateJ);
        defsJ.append(patternRejectsJ);
        R.svgJ.prepend(defsJ);
        R.svgJ.click((function(_this) {
          return function(event) {
            var drawing, drawingsToSelect, i, j, len, len1, point, rectangle, ref, ref1;
            point = Utils.Event.GetPoint(event);
            point.y -= 62;
            point = P.view.viewToProject(point);
            rectangle = new P.Rectangle(point, point);
            rectangle = rectangle.expand(5);
            drawingsToSelect = [];
            ref = R.drawings;
            for (i = 0, len = ref.length; i < len; i++) {
              drawing = ref[i];
              if (((ref1 = drawing.getBounds()) != null ? ref1.intersects(rectangle) : void 0) && drawing.isVisible()) {
                drawingsToSelect.push(drawing);
              }
            }
            R.tools.select.deselectAll();
            for (j = 0, len1 = drawingsToSelect.length; j < len1; j++) {
              drawing = drawingsToSelect[j];
              drawing.select();
            }
          };
        })(this));
        if (R.loadedBox == null) {
          if (typeof window !== "undefined" && window !== null) {
            window.onhashchange(null, false);
          }
          return;
        }
        planet = new P.Point(R.loadedBox.planetX, R.loadedBox.planetY);
        tl = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][0], planet);
        br = Utils.CS.posOnPlanetToProject(R.loadedBox.box.coordinates[0][2], planet);
        boxRectangle = new P.Rectangle(tl, br);
        pos = boxRectangle.center;
        this.moveTo(pos);
        if (R.loadEntireArea) {
          this.entireArea = boxRectangle;
          R.loader.load(boxRectangle);
        }
        siteString = R.canvasJ.attr("data-site");
        site = JSON.parse(siteString);
        if (site.restrictedArea) {
          this.restrictedArea = boxRectangle;
        }
        R.tools.select.select();
        if (site.disableToolbar) {
          R.sidebar.hide();
        } else {
          R.sidebar.sidebarJ.find("div.panel.panel-default:not(:last)").hide();
          ref = R.gui.__folders;
          for (folderName in ref) {
            folder = ref[folderName];
            ref1 = folder.__controllers;
            for (i = 0, len = ref1.length; i < len; i++) {
              controller = ref1[i];
              if (controller.name !== 'Zoom') {
                folder.remove(controller);
                folder.__controllers.remove(controller);
              }
            }
            if (folder.__controllers.length === 0) {
              R.gui.removeFolder(folderName);
            }
          }
          R.sidebar.handleJ.click();
        }
      };

      View.prototype.contains = function(item, tolerance) {
        if (tolerance == null) {
          tolerance = 0;
        }
        return this.grid.contains(item, tolerance);
      };

      View.prototype.focusIsOnCanvas = function() {
        return $(document.activeElement).is("body");
      };

      View.prototype.onMouseDown = function(event) {
        var ref, ref1;
        if ((ref = R.wacomPenAPI) != null ? ref.isEraser : void 0) {
          this.tool.onKeyUp({
            key: 'delete'
          });
          return;
        }
        $(document.activeElement).blur();
        if ((ref1 = R.selectedTool) != null) {
          ref1.begin(event);
        }
      };

      View.prototype.onMouseDrag = function(event) {
        var ref, ref1;
        if ((ref = R.wacomPenAPI) != null ? ref.isEraser : void 0) {
          return;
        }
        if (R.currentDiv != null) {
          return;
        }
        if ((ref1 = R.selectedTool) != null) {
          ref1.update(event);
        }
      };

      View.prototype.onMouseUp = function(event) {
        var ref, ref1;
        if ((ref = R.wacomPenAPI) != null ? ref.isEraser : void 0) {
          return;
        }
        if (R.currentDiv != null) {
          return;
        }
        if ((ref1 = R.selectedTool) != null) {
          ref1.end(event);
        }
      };

      View.prototype.onKeyDown = function(event) {
        var ref;
        if (!this.focusIsOnCanvas()) {
          return;
        }
        if (event.key === 'delete') {
          event.preventDefault();
          return false;
        }
        if (event.key === 'space' && ((ref = R.selectedTool) != null ? ref.name : void 0) !== 'Move') {
          R.tools.move.select();
        }
        if (event.key === 'z' && (event.modifiers.control || event.modifiers.meta)) {
          R.commandManager.undo();
          event.event.preventDefault();
          event.event.stopPropagation();
          return -1;
        }
        if (event.key === 'y' && (event.modifiers.control || event.modifiers.meta)) {
          R.commandManager["do"]();
          event.event.preventDefault();
          event.event.stopPropagation();
          return -1;
        }
      };

      View.prototype.onKeyUp = function(event) {
        var ref, ref1;
        if (!this.focusIsOnCanvas()) {
          return;
        }
        if ((ref = R.selectedTool) != null) {
          ref.keyUp(event);
        }
        switch (event.key) {
          case 'space':
            if ((ref1 = R.previousTool) != null) {
              ref1.select();
            }
            break;
          case 'v':
            R.tools.select.select();
            break;
          case 't':
            R.showToolBox();
            break;
          case 'r':
            if (event.modifiers.shift) {
              R.rasterizer.rasterizeImmediately();
            }
        }
        event.preventDefault();
      };

      View.prototype.onFrame = function(event) {
        var i, item, len, ref, ref1, ref2;
        if ((ref = R.rasterizer) != null) {
          if (typeof ref.updateLoadingBar === "function") {
            ref.updateLoadingBar(event.time);
          }
        }
        if ((ref1 = R.selectedTool) != null) {
          if (typeof ref1.onFrame === "function") {
            ref1.onFrame(event);
          }
        }
        ref2 = R.animatedItems;
        for (i = 0, len = ref2.length; i < len; i++) {
          item = ref2[i];
          item.onFrame(event);
        }
      };

      View.prototype.onWindowResize = function(event) {
        var ref;
        this.grid.update();
        this.moveBy(new P.Point());
        P.view.viewSize = new P.Size(R.stageJ.innerWidth(), R.stageJ.innerHeight());
        R.svgJ.attr('width', R.stageJ.innerWidth());
        R.svgJ.attr('height', R.stageJ.innerHeight());
        R.toolbar.updateArrowsVisibility();
        R.drawingPanel.onWindowResize();
        if ((ref = R.timelapse) != null) {
          ref.onWindowResize();
        }
      };

      View.prototype.mousedown = function(event) {
        var moveButton, ref, ref1, ref2;
        moveButton = event instanceof MouseEvent ? 2 : ((typeof TouchEvent !== "undefined" && TouchEvent !== null) && event instanceof TouchEvent) ? 0 : 2;
        switch (event.which) {
          case moveButton:
            R.tools.move.select(false, true, true);
            break;
          case 3:
            if ((ref = R.selectedTool) != null) {
              if (typeof ref.finish === "function") {
                ref.finish();
              }
            }
        }
        if (((ref1 = R.selectedTool) != null ? ref1.name : void 0) === 'Move') {
          if ((ref2 = R.selectedTool) != null) {
            ref2.beginNative(event);
          }
          return;
        }
        this.initialMousePosition = Utils.Event.jEventToPoint(event);
        this.previousMousePosition = this.initialMousePosition.clone();
      };

      View.prototype.mousemove = function(event) {
        var base, paperEvent, ref, ref1, ref2, ref3, ref4;
        this.mousePosition.set(Utils.Event.GetPoint(event));
        if (((ref = R.selectedTool) != null ? ref.name : void 0) === 'Move' && R.selectedTool.dragging) {
          R.selectedTool.updateNative(event);
          return;
        }
        if (((ref1 = R.selectedTool) != null ? ref1.name : void 0) === 'Select') {
          paperEvent = Utils.Event.jEventToPaperEvent(event, this.previousMousePosition, this.initialMousePosition, 'mousemove');
          if ((ref2 = R.selectedTool) != null) {
            if (typeof ref2.move === "function") {
              ref2.move(paperEvent);
            }
          }
        }
        Div.updateHiddenDivs(event);
        if ((ref3 = R.codeEditor) != null) {
          ref3.onMouseMove(event);
        }
        if ((ref4 = R.drawingPanel) != null) {
          ref4.onMouseMove(event);
        }
        if (R.currentDiv != null) {
          paperEvent = Utils.Event.jEventToPaperEvent(event, this.previousMousePosition, this.initialMousePosition, 'mousemove');
          if (typeof (base = R.currentDiv).updateSelect === "function") {
            base.updateSelect(paperEvent);
          }
          this.previousMousePosition = paperEvent.point;
        }
      };

      View.prototype.mouseup = function(event) {
        var base, paperEvent, ref, ref1, ref2, ref3, ref4;
        if ((ref = R.tracer) != null) {
          ref.mouseUp();
        }
        if (R.stageJ.hasClass("has-tool-box") && !$(event.target).parents('.tool-box').length > 0) {
          R.hideToolBox();
        }
        if (!$(event.target).parents('#CommeUnDessein_alerts').length > 0) {
          R.alertManager.hideIfNoTimeout();
        }
        if ((ref1 = R.codeEditor) != null) {
          ref1.onMouseUp(event);
        }
        if ((ref2 = R.drawingPanel) != null) {
          ref2.onMouseUp(event);
        }
        if (((ref3 = R.selectedTool) != null ? ref3.name : void 0) === 'Move') {
          R.selectedTool.endNative(event);
          if (event.which === 2) {
            if ((ref4 = R.previousTool) != null) {
              ref4.select(null, null, null, true);
            }
          }
          return;
        }
        if (R.currentDiv != null) {
          paperEvent = Utils.Event.jEventToPaperEvent(event, this.previousMousePosition, this.initialMousePosition, 'mouseup');
          if (typeof (base = R.currentDiv).endSelect === "function") {
            base.endSelect(paperEvent);
          }
          this.previousMousePosition = paperEvent.point;
        }
      };

      View.prototype.mousewheel = function(event) {
        this.moveBy(new P.Point(-event.deltaX, event.deltaY));
      };

      return View;

    })();
    return View;
  });

}).call(this);
