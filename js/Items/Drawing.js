// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'i18next'], function(P, R, Utils, Item, Modal, i18next) {
    var Drawing;
    Drawing = (function(superClass) {
      extend(Drawing, superClass);

      Drawing.label = 'Drawing';

      Drawing.object_type = 'drawing';

      Drawing.pkToId = {};

      Drawing.draft = null;

      Drawing.initialize = function(rectangle) {};

      Drawing.initializeParameters = function() {
        var parameters;
        parameters = Drawing.__super__.constructor.initializeParameters.call(this);
        delete parameters['Style'];
        return parameters;
      };

      Drawing.parameters = Drawing.initializeParameters();

      Drawing.getDraft = function() {
        return this.draft;
      };

      function Drawing(rectangle1, data1, id1, pk1, owner, date, title1, description, status1, pathList, svg, bounds) {
        this.rectangle = rectangle1;
        this.data = data1 != null ? data1 : null;
        this.id = id1 != null ? id1 : null;
        this.pk = pk1 != null ? pk1 : null;
        this.owner = owner != null ? owner : null;
        this.date = date;
        this.title = title1;
        this.description = description;
        this.status = status1 != null ? status1 : 'pending';
        if (pathList == null) {
          pathList = [];
        }
        if (svg == null) {
          svg = null;
        }
        if (bounds == null) {
          bounds = null;
        }
        this.select = bind(this.select, this);
        this.deleteFromDatabaseCallback = bind(this.deleteFromDatabaseCallback, this);
        this.updateCallback = bind(this.updateCallback, this);
        this.update = bind(this.update, this);
        this.submitCallback = bind(this.submitCallback, this);
        this.savePathCallback = bind(this.savePathCallback, this);
        this.onLiClick = bind(this.onLiClick, this);
        this.selectPaths = bind(this.selectPaths, this);
        Drawing.__super__.constructor.call(this, this.data, this.id, this.pk);
        if (this.pk != null) {
          this.constructor.pkToId[this.pk] = this.id;
        }
        if (bounds != null) {
          this.rectangle = new P.Rectangle(bounds);
        }
        R.drawings.push(this);
        this.setPkToDrawing(this.pk);
        this.paths = [];
        this.group.remove();
        this.votes = [];
        this.addToListItem();
        this.addToLayer();
        if (this.status === 'draft') {
          this.constructor.draft = this;
          this.group.shadowColor = 'lightblue';
          this.group.shadowBlur = 10;
          this.group.shadowOffset = new P.Point(0, 0);
        }
        if ((this.status === 'draft' || this.status === 'flagged_pending' || this.status === 'flagged') && pathList) {
          if (this.status === 'flagged_pending' || this.status === 'flagged' && pathList.length === 0) {
            this.loadPathList();
            this.loadSVG();
          } else {
            this.addPathsFromPathList(pathList);
          }
        } else if ((this.pk != null) && R.useSVG) {
          this.loadSVG();
        }
        if (this.status === 'pending' && this.owner !== R.me) {
          this.drawVoteFlag();
        }
        if (this.status === 'flagged_pending') {
          this.drawVoteFlag(true);
        }
        return;
      }

      Drawing.prototype.selectPaths = function() {
        var j, len, path, ref;
        if ((this.paths == null) || this.paths.length === 0) {
          return this.loadPathList((function(_this) {
            return function() {
              if (_this.paths != null) {
                return _this.selectPaths();
              } else {
                return null;
              }
            };
          })(this));
        }
        ref = this.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          path.selected = true;
        }
      };

      Drawing.prototype.deselectPaths = function() {
        var j, len, path, ref;
        if (this.paths == null) {
          return;
        }
        ref = this.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          path.selected = false;
        }
      };

      Drawing.prototype.drawVoteFlag = function(flagged) {
        var bounds;
        if (flagged == null) {
          flagged = false;
        }
        if (R.useSVG) {
          return;
        }
        bounds = this.getBounds();
        this.voteFlag = new P.Raster(!flagged ? '/static/images/icons/envelope.png' : '/static/images/icons/flagged.png');
        this.voteFlag.position = bounds.center;
        this.voteFlag.opacity = 0.75;
        if (R.voteFlags == null) {
          R.voteFlags = [];
        }
        R.voteFlags.push(this.voteFlag);
        this.group.addChild(this.voteFlag);
        if (R.selectedTool !== R.tools.select) {
          this.hideVoteFlag();
        }
      };

      Drawing.prototype.hideVoteFlag = function() {
        var ref;
        if ((ref = this.voteFlag) != null) {
          ref.visible = false;
        }
      };

      Drawing.prototype.showVoteFlag = function() {
        var flagged, ref;
        flagged = this.status === 'flagged_pending' || this.status === 'flagged';
        if ((this.id != null) && (R.loader.userVotes.get(this.id) != null) && !flagged) {
          return;
        }
        if ((ref = this.voteFlag) != null) {
          ref.visible = true;
        }
      };

      Drawing.prototype.setPkToDrawing = function(pk) {
        if (R.pkToDrawing == null) {
          R.pkToDrawing = new Map();
        }
        R.pkToDrawing.set(this.pk, this);
      };

      Drawing.prototype.setPK = function(pk) {
        Drawing.__super__.setPK.call(this, pk);
        this.setPkToDrawing(pk);
      };

      Drawing.prototype.getPathPoints = function(path) {
        var j, len, points, ref, segment;
        points = [];
        ref = path.segments;
        for (j = 0, len = ref.length; j < len; j++) {
          segment = ref[j];
          points.push(R.view.grid.projectToGeoJSON(segment.point));
          points.push(Utils.CS.pointToObj(segment.handleIn));
          points.push(Utils.CS.pointToObj(segment.handleOut));
          points.push(segment.rtype);
        }
        return points;
      };

      Drawing.prototype.getPointLists = function() {
        var j, len, path, pointLists, ref;
        pointLists = [];
        ref = this.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          pointLists.push({
            points: this.getPathPoints(path),
            data: {
              strokeColor: path.strokeColor.toCSS()
            }
          });
        }
        return pointLists;
      };

      Drawing.prototype.createPath = function(points, strokeColor, planet) {
        var i, j, len, path, point;
        if (planet == null) {
          planet = null;
        }
        if (planet == null) {
          planet = new P.Point(0, 0);
        }
        path = new P.Path();
        for (i = j = 0, len = points.length; j < len; i = j += 4) {
          point = points[i];
          path.add(R.view.grid.geoJSONToProject(point));
          path.lastSegment.handleIn = new P.Point(points[i + 1]);
          path.lastSegment.handleOut = new P.Point(points[i + 2]);
          path.lastSegment.rtype = points[i + 3];
        }
        path.strokeWidth = Item.Path.strokeWidth;
        path.strokeColor = strokeColor;
        path.strokeCap = 'round';
        path.strokeJoin = 'round';
        this.addChild(path);
        return path;
      };

      Drawing.prototype.addPathsFromPathList = function(pathList, parseJSON, highlight) {
        var j, len, p, pJSON, path, points, strokeColor;
        if (parseJSON == null) {
          parseJSON = true;
        }
        if (highlight == null) {
          highlight = false;
        }
        for (j = 0, len = pathList.length; j < len; j++) {
          p = pathList[j];
          pJSON = parseJSON ? JSON.parse(p) : p;
          points = pJSON.points;
          strokeColor = pJSON.data != null ? pJSON.data.strokeColor : null;
          if (points == null) {
            points = pJSON;
          }
          if (strokeColor == null) {
            strokeColor = new P.Color('grey');
          }
          path = this.createPath(points, strokeColor);
        }
        this.computeRectangle();
      };

      Drawing.prototype.loadPathList = function(callback) {
        var args;
        args = {
          pk: this.pk,
          loadPathList: true
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadDrawing',
              args: args
            })
          }
        }).done((function(_this) {
          return function(result) {
            var drawingData;
            drawingData = JSON.parse(result.drawing);
            _this.addPathsFromPathList(drawingData.pathList);
            return typeof callback === "function" ? callback() : void 0;
          };
        })(this));
      };

      Drawing.prototype.createSVG = function() {
        this.setSVG({
          documentElement: this.getSVG(false)
        }, false);
      };

      Drawing.prototype.loadSVG = function(callback) {
        var jqxhr;
        jqxhr = $.get(location.origin + '/static/drawings/' + this.pk + '.svg', ((function(_this) {
          return function(result) {
            return _this.setSVG(result, false, callback);
          };
        })(this))).fail((function(_this) {
          return function() {
            return console.log('load drawing svg failed');
          };
        })(this));
      };

      Drawing.prototype.setPathZIndex = function(path, pathIndex, zIndex) {
        this.paths.pop();
        this.paths.splice(pathIndex, 0, path);
        path.parent.insertChild(zIndex, path);
      };

      Drawing.prototype.setSVGRasterMode = function(svg, parse, callback) {
        var doc, parser;
        if (parse == null) {
          parse = true;
        }
        if (callback == null) {
          callback = null;
        }
        parser = new DOMParser();
        doc = null;
        if (parse) {
          parser = new DOMParser();
          doc = parser.parseFromString(svg, "image/svg+xml");
        } else {
          doc = svg;
        }
        doc.documentElement.removeAttribute('visibility');
        doc.documentElement.removeAttribute('xmlns');
        this.svg = doc.documentElement;
        if (typeof callback === "function") {
          callback(this.svg);
        }
      };

      Drawing.prototype.setSVG = function(svg, parse, callback, hide) {
        var doc, layer, layerName, parser;
        if (parse == null) {
          parse = true;
        }
        if (callback == null) {
          callback = null;
        }
        if (hide == null) {
          hide = false;
        }
        if (!R.useSVG) {
          return this.setSVGRasterMode(svg, parse, callback);
        }
        if (this.svg) {
          this.svg.remove();
        }
        layerName = this.getLayerName();
        layer = document.getElementById(layerName);
        doc = null;
        if (!layer) {
          return;
        }
        if (parse) {
          parser = new DOMParser();
          doc = parser.parseFromString(svg, "image/svg+xml");
        } else {
          doc = svg;
        }
        if (doc.documentElement != null) {
          doc.documentElement.removeAttribute('visibility');
          doc.documentElement.removeAttribute('xmlns');
          if (this.status === 'draft') {
            doc.documentElement.setAttribute('id', 'draftDrawing');
          }
          this.svg = layer.appendChild(doc.documentElement);
          this.svg.addEventListener("click", ((function(_this) {
            return function(event) {
              R.tools.select.deselectAll();
              _this.select();
              event.stopPropagation();
              return -1;
            };
          })(this)));
          if (hide) {
            this.svg.setAttribute('visibility', 'hidden');
          }
          this.setStrokeColorFromStatus();
        }
        if (typeof callback === "function") {
          callback(this.svg);
        }
      };

      Drawing.prototype.setStrokeColorFromVote = function(positive) {
        var colorClass, ref, spanJ;
        if (R.useSVG) {
          if (this.status === 'pending') {
            if ((ref = this.svg) != null) {
              ref.setAttribute('stroke', positive ? Item.Path.colorMap.pendingVotedPositive : Item.Path.colorMap.pendingVotedNegative);
            }
          }
        }
        colorClass = positive ? 'drawing-color' : 'rejected-color';
        spanJ = $('<span class="badge ' + colorClass + '"></span>');
        spanJ.text(i18next.t(positive ? 'voted for' : 'voted against'));
        $('#RItems li[data-id="' + this.id + '"] .badge-container').append(spanJ);
      };

      Drawing.prototype.setStrokeColorFromStatus = function() {
        var ref;
        if (!R.useSVG) {
          return;
        }
        if ((ref = this.svg) != null) {
          ref.setAttribute('stroke', Item.Path.colorMap[this.status]);
        }
      };

      Drawing.prototype.getDuplicateData = function() {
        var data;
        data = {
          pointLists: this.getPointLists()
        };
        return data;
      };

      Drawing.prototype.setData = function(data) {
        this.removePaths();
        this.addPathsFromPathList(data.pointLists, false);
        this.updatePaths();
        if (this.status === 'draft') {
          R.toolManager.updateButtonsVisibility(this);
          R.tools['Precise path'].showDraftLimits();
        }
      };

      Drawing.prototype.getListItem = function() {
        var itemListJ;
        itemListJ = null;
        switch (this.status) {
          case 'pending':
          case 'emailNotConfirmed':
          case 'notConfirmed':
            itemListJ = R.view.pendingListJ;
            break;
          case 'drawing':
          case 'validated':
            itemListJ = R.view.drawingListJ;
            break;
          case 'drawn':
            itemListJ = R.view.drawnListJ;
            break;
          case 'rejected':
            itemListJ = R.view.rejectedListJ;
            break;
          case 'draft':
            itemListJ = R.view.draftListJ;
            break;
          case 'flagged':
          case 'flagged_pending':
            itemListJ = R.view.flaggedListJ;
            break;
          default:
            this.group.visible = false;
            if (this.svg != null) {
              $(this.svg).hide();
            }
        }
        return itemListJ;
      };

      Drawing.prototype.toggleVisibility = function() {
        this.group.visible = !this.group.visible;
        if (this.group.visible) {
          this.eyeIconJ.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
        } else {
          this.eyeIconJ.addClass('glyphicon-eye-close').removeClass('glyphicon-eye-open');
        }
        if (this.svg != null) {
          if (this.group.visible) {
            $(this.svg).show();
          } else {
            $(this.svg).hide();
          }
        }
      };

      Drawing.prototype.addToLayer = function() {
        this.getLayer().addChild(this.group);
      };

      Drawing.prototype.addToListItem = function(itemListJ1) {
        var divJ, nChildren, nItemsJ, ref, ref1, title;
        this.itemListJ = itemListJ1 != null ? itemListJ1 : this.getListItem();
        title = '' + this.title + ' <span data-i18n="by">' + i18next.t('by') + '</span> ' + this.owner;
        this.liJ = $("<li>");
        this.liJ.html(title);
        divJ = $("<div class='cd-row cd-end badge-container'>");
        this.liJ.append(divJ);
        this.liJ.attr("data-id", this.id);
        this.liJ.click(this.onLiClick);
        this.liJ.mouseover((function(_this) {
          return function(event) {
            _this.highlight();
          };
        })(this));
        this.liJ.mouseout((function(_this) {
          return function(event) {
            _this.unhighlight();
          };
        })(this));
        this.liJ.rItem = this;
        if ((ref = this.itemListJ) != null) {
          ref.find('.rPath-list').prepend(this.liJ);
        }
        nItemsJ = (ref1 = this.itemListJ) != null ? ref1.find(".n-items") : void 0;
        if ((nItemsJ != null) && nItemsJ.length > 0) {
          nChildren = this.itemListJ.find('.rPath-list').children('li[data-id]').length;
          nItemsJ.html(nChildren);
        }
      };

      Drawing.prototype.removeFromListItem = function() {
        var nChildren, nItemsJ, ref;
        this.liJ.remove();
        nItemsJ = (ref = this.itemListJ) != null ? ref.find(".n-items") : void 0;
        if ((nItemsJ != null) && nItemsJ.length > 0) {
          nChildren = this.itemListJ.find('.rPath-list').children('li[data-id]').length;
          nItemsJ.html(nChildren);
        }
      };

      Drawing.prototype.onLiClick = function(event) {
        var bounds;
        R.tools.select.deselectAll();
        bounds = this.getBounds();
        if (!P.view.bounds.intersects(bounds)) {
          R.view.moveTo(bounds.center, 1000);
        }
        R.drawingPanel.fromGeneralInformation = true;
        this.select();
      };

      Drawing.prototype.computeRectangle = function() {
        var bounds, j, len, path, ref;
        this.rectangle = null;
        ref = this.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          bounds = path.bounds.expand(2 * Item.Path.strokeWidth);
          if (bounds != null) {
            if (this.rectangle == null) {
              this.rectangle = bounds.clone();
            }
            this.rectangle = this.rectangle.unite(bounds);
          }
        }
      };

      Drawing.prototype.getLayer = function() {
        return R.view[this.getLayerName()];
      };

      Drawing.prototype.isVisible = function() {
        var ref;
        return (ref = this.getLayer()) != null ? ref.visible : void 0;
      };

      Drawing.prototype.convertToGroup = function() {
        var item;
        item = P.project.importSVG(this.svg, (function(_this) {
          return function(item, svg) {
            console.log(item.bounds);
          };
        })(this));
        return item;
      };

      Drawing.prototype.addChild = function(path, save, computeRectangle) {
        if (save == null) {
          save = false;
        }
        if (computeRectangle == null) {
          computeRectangle = true;
        }
        if (this.paths.indexOf(path) >= 0) {
          console.log('path already in drawing');
          return;
        }
        this.paths.push(path);
        this.group.addChild(path);
        path.data.drawingId = this.id;
        if (computeRectangle) {
          this.computeRectangle();
        }
        if (save) {
          this.savePath(path);
        }
      };

      Drawing.prototype.savePath = function(path) {
        var args;
        args = {
          clientId: this.id,
          pk: this.pk,
          points: this.getPathPoints(path),
          data: {
            strokeColor: path.strokeColor.toCSS()
          },
          bounds: this.getBounds()
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
      };

      Drawing.prototype.savePathCallback = function(result) {
        R.loader.checkError(result);
      };

      Drawing.prototype.removeChild = function(path, updateRectangle, removeID) {
        var pathIndex;
        if (updateRectangle == null) {
          updateRectangle = false;
        }
        if (removeID == null) {
          removeID = true;
        }
        path.data.drawingId = null;
        pathIndex = this.paths.indexOf(path);
        if (pathIndex >= 0) {
          this.paths.splice(pathIndex, 1);
        }
        path.remove();
      };

      Drawing.prototype.getLayerName = function() {
        var statusName;
        statusName = this.status === 'flagged_pending' || this.status === 'flagged' ? 'flagged' : this.status;
        return statusName + 'Layer';
      };

      Drawing.prototype.getBounds = function() {
        return this.rectangle;
      };

      Drawing.prototype.getBoundsWithFlag = function() {
        if (this.voteFlag != null) {
          return this.rectangle.unite(this.voteFlag.bounds);
        } else {
          return this.rectangle;
        }
      };

      Drawing.prototype.getSVG = function(asString) {
        var j, len, path, ref;
        if (asString == null) {
          asString = true;
        }
        if ((this.paths != null) && this.paths.length > 0) {
          ref = this.paths;
          for (j = 0, len = ref.length; j < len; j++) {
            path = ref[j];
            this.group.addChild(path);
          }
          return this.group.exportSVG({
            asString: asString
          });
        } else {
          return this.svg;
        }
      };

      Drawing.prototype.submit = function() {
        var args, bounds, imageData, svg;
        bounds = this.getBounds();
        svg = this.getSVG();
        this.svgString = svg;
        imageData = R.view.getThumbnail(this, bounds.width, bounds.height, true, false);
        args = {
          pk: this.pk,
          clientId: this.id,
          date: Date.now(),
          title: this.title,
          description: this.description,
          svg: svg,
          png: imageData,
          bounds: bounds
        };
        R.loader.showLoadingBar();
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'submitDrawing',
              args: args
            })
          }
        }).done(this.submitCallback);
      };

      Drawing.prototype.removePaths = function(addCommand) {
        var j, len, path, ref;
        if (addCommand == null) {
          addCommand = false;
        }
        if (addCommand) {
          R.commandManager.add(new R.Command.ModifyDrawing(this));
        }
        ref = this.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          path.remove();
        }
        if ((this.svg != null) && R.useSVG) {
          this.svg.remove();
        }
        this.paths = [];
        if (this.status === 'draft') {
          R.toolManager.updateButtonsVisibility(this);
        }
        if (addCommand) {
          this.updatePaths();
        }
      };

      Drawing.prototype.submitCallback = function(result) {
        var modal;
        R.loader.hideLoadingBar();
        if (!R.loader.checkError(result)) {
          return;
        }
        R.loader.createDrawing(result.draft);
        R.tools['Precise path'].hideDraftLimits();
        R.loader.reloadRasters(this.rectangle);
        R.commandManager.clearHistory();
        this.updateStatus(result.status);
        if (this.constructor.draft === this) {
          this.constructor.draft = null;
        }
        R.toolManager.updateButtonsVisibility();
        this.removePaths();
        this.setSVG(this.svgString);
        this.svgString = null;
        this.status = result.status;
        modal = Modal.createModal({
          id: 'share-facebook',
          title: 'Drawing submitted',
          submit: ((function(_this) {
            return function() {};
          })(this)),
          submitButtonText: 'No thanks'
        });
        modal.addButton({
          type: 'info',
          name: 'Tweet',
          submit: ((function(_this) {
            return function() {
              return R.drawingPanel.shareOnTwitter(null, _this);
            };
          })(this))
        });
        modal.addButton({
          type: 'primary',
          name: 'Share on Facebook',
          submit: ((function(_this) {
            return function() {
              return R.drawingPanel.shareOnFacebook(null, _this);
            };
          })(this))
        });
        modal.modalJ.find('[name="cancel"]').hide();
        modal.modalJ.find('[name="submit"]').removeClass('btn-primary').addClass('btn-default');
        if (this.status === 'emailNotConfirmed') {
          modal.addText("Drawing successfully submitted but email not confirmed", "Drawing successfully submitted but email not confirmed", false, {
            positiveVoteThreshold: result.positiveVoteThreshold
          });
        } else if (this.status === 'notConfirmed') {
          modal.addText("Drawing successfully submitted but not confirmed", "Drawing successfully submitted but not confirmed", false, {
            positiveVoteThreshold: result.positiveVoteThreshold
          });
        } else {
          modal.addText("Drawing successfully submitted", "Drawing successfully submitted", false, {
            positiveVoteThreshold: result.positiveVoteThreshold
          });
        }
        modal.addText('Would you like to share your drawing on Facebook or Twitter');
        modal.show();
      };

      Drawing.prototype.updateBox = function() {
        var args, bounds;
        bounds = this.getBounds();
        args = {
          pk: this.pk,
          clientId: this.id,
          bounds: bounds
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'updateDrawingBox',
              args: args
            })
          }
        }).done(function(result) {
          R.loader.checkError(result);
        });
      };

      Drawing.prototype.updatePaths = function() {
        var args;
        this.computeRectangle();
        args = {
          clientId: this.id,
          pk: this.pk,
          pointLists: this.getPointLists(),
          bounds: this.getBounds()
        };
        R.loader.showLoadingBar(500);
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'setPathsToDrawing',
              args: args
            })
          }
        }).done(function() {
          R.loader.hideLoadingBar();
          R.loader.checkError();
        });
      };

      Drawing.prototype.update = function(data) {
        var args;
        if (this.pk == null) {
          this.updateAfterSave = data;
          return;
        }
        delete this.updateAfterSave;
        this.previousTitle = this.title;
        this.previousDescription = this.description;
        this.title = data.title;
        this.description = data.description;
        args = {
          pk: this.pk,
          title: this.title,
          description: this.description
        };
        R.loader.showLoadingBar(500);
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'updateDrawing',
              args: args
            })
          }
        }).done(this.updateCallback);
      };

      Drawing.prototype.updateCallback = function(result) {
        var contentJ;
        R.loader.hideLoadingBar();
        if (!R.loader.checkError(result)) {
          this.title = this.previousTitle;
          this.description = this.previousDescription;
          contentJ = R.drawingPanel.drawingPanelJ.find('.content');
          contentJ.find('#drawing-title').val(this.title);
          contentJ.find('#drawing-description').val(this.description);
          return;
        }
        R.alertManager.alert("Drawing successfully modified", "success");
      };

      Drawing.prototype.deleteFromDatabaseCallback = function() {
        var id;
        R.loader.hideLoadingBar();
        id = this.id;
        if (!R.loader.checkError()) {
          return;
        }
        Drawing.__super__.deleteFromDatabaseCallback.call(this);
        R.alertManager.alert("Drawing successfully cancelled", "success");
      };

      Drawing.prototype["delete"] = function() {
        var deffered;
        deffered = Drawing.__super__["delete"].apply(this, arguments);
        return deffered;
      };

      Drawing.prototype.deleteFromDatabase = function() {
        R.loader.showLoadingBar(500);
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'deleteDrawing',
              args: {
                'pk': this.pk
              }
            })
          }
        }).done(this.deleteFromDatabaseCallback());
      };

      Drawing.prototype.cancel = function() {
        R.loader.showLoadingBar(500);
        this.cancelling = true;
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'cancelDrawing',
              args: {
                'pk': this.pk
              }
            })
          }
        }).done((function(_this) {
          return function(result) {
            return _this.cancelCallback(result);
          };
        })(this));
      };

      Drawing.prototype.cancelCallback = function(result) {
        var draft, j, k, len, len1, path, ref, ref1;
        R.loader.hideLoadingBar();
        if (!R.loader.checkError(result)) {
          return;
        }
        if (R.administrator && this.owner !== R.me) {
          return;
        }
        R.commandManager.clearHistory();
        draft = Drawing.getDraft();
        if (draft != null) {
          ref = this.paths;
          for (j = 0, len = ref.length; j < len; j++) {
            path = ref[j];
            draft.addChild(path);
          }
          draft.addPathsFromPathList(result.pathList);
          ref1 = this.paths.slice();
          for (k = 0, len1 = ref1.length; k < len1; k++) {
            path = ref1[k];
            this.removeChild(path);
          }
          draft.updateStatus(result.status);
        }
        this.remove();
        draft.setPK(result.pk);
        R.items[result.clientId] = draft;
        R.loader.reloadRasters(this.rectangle);
      };

      Drawing.prototype.setRectangle = function(rectangle, update) {
        if (update == null) {
          update = true;
        }
        Drawing.__super__.setRectangle.call(this, rectangle, update);
      };

      Drawing.prototype.updateDrawingPanel = function() {
        var args;
        args = {
          pk: this.pk,
          loadSVG: R.loadSVG
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadDrawing',
              args: args
            })
          }
        }).done((function(_this) {
          return function(result) {
            return R.drawingPanel.setDrawing(_this, result);
          };
        })(this));
      };

      Drawing.prototype.updateStatus = function(status) {
        var layer, layerName, ref, ref1, voteFlagWasVisible;
        if (this.status === status) {
          return;
        }
        this.status = status;
        this.removeFromListItem();
        this.addToListItem();
        this.addToLayer();
        if ((this.svg != null) && R.useSVG) {
          this.svg.remove();
          layerName = this.getLayerName();
          layer = document.getElementById(layerName);
          this.svg = layer.appendChild(this.svg);
        }
        voteFlagWasVisible = (ref = this.voteFlag) != null ? ref.visible : void 0;
        if ((ref1 = this.voteFlag) != null) {
          ref1.remove();
        }
        if (this.status === 'pending' && this.owner !== R.me) {
          this.drawVoteFlag();
        }
        if (this.status === 'flagged_pending') {
          this.drawVoteFlag(true);
        }
        if (voteFlagWasVisible) {
          this.showVoteFlag();
        }
        this.setStrokeColorFromStatus();
      };

      Drawing.prototype.select = function(updateOptions, showPanelAndLoad, force) {
        var draft, drawing, j, len, ref, ref1;
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (showPanelAndLoad == null) {
          showPanelAndLoad = true;
        }
        if (force == null) {
          force = false;
        }
        if (!this.group.visible) {
          return false;
        }
        if (!Drawing.__super__.select.call(this, updateOptions, force)) {
          return false;
        }
        if (showPanelAndLoad) {
          R.drawingPanel.selectionChanged();
        }
        ref = R.drawings;
        for (j = 0, len = ref.length; j < len; j++) {
          drawing = ref[j];
          if (((ref1 = drawing.getBoundsWithFlag()) != null ? ref1.intersects(this.rectangle) : void 0) && drawing.isVisible()) {
            drawing.hideVoteFlag();
          }
        }
        draft = Drawing.getDraft();
        if (R.administrator && this === draft) {
          this.selectPaths();
        }
        return true;
      };

      Drawing.prototype.deselect = function(updateOptions) {
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (!Drawing.__super__.deselect.call(this, updateOptions)) {
          return false;
        }
        R.drawingPanel.deselectDrawing(this);
        this.showVoteFlag();
        this.deselectPaths();
        return true;
      };

      Drawing.prototype.remove = function() {
        var j, len, path, ref, ref1;
        ref = this.paths.slice();
        for (j = 0, len = ref.length; j < len; j++) {
          path = ref[j];
          this.removeChild(path);
        }
        if ((ref1 = this.svg) != null) {
          ref1.remove();
        }
        R.pkToDrawing["delete"](this.pk);
        this.removeFromListItem();
        Drawing.__super__.remove.apply(this, arguments);
        R.drawings.splice(R.drawings.indexOf(this), 1);
      };

      Drawing.prototype.highlight = function(color) {
        Drawing.__super__.highlight.call(this);
        if (color) {
          this.highlightRectangle.fillColor = color;
          this.highlightRectangle.strokeColor = color;
          this.highlightRectangle.dashArray = [];
        }
      };

      Drawing.prototype.hide = function(SVGonly) {
        var ref;
        if (SVGonly == null) {
          SVGonly = true;
        }
        if (this.svg != null) {
          this.svg.setAttribute('visibility', 'hidden');
        }
        if ((ref = this.group) != null) {
          ref.visible = false;
        }
      };

      Drawing.prototype.show = function(SVGonly) {
        var ref;
        if (SVGonly == null) {
          SVGonly = true;
        }
        if (this.svg != null) {
          this.svg.setAttribute('visibility', 'show');
        }
        if ((ref = this.group) != null) {
          ref.visible = true;
        }
      };

      return Drawing;

    })(Item);
    Item.Drawing = Drawing;
    R.Drawing = Drawing;
    return Drawing;
  });

}).call(this);
