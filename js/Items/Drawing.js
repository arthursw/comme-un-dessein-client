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

      Drawing.create = function(duplicateData) {
        var copy, i, id, len, ref;
        copy = new this(null, duplicateData.data, duplicateData.id, null, duplicateData.owner, Date.now(), duplicateData.title, duplicateData.description);
        ref = duplicateData.pathIds;
        for (i = 0, len = ref.length; i < len; i++) {
          id = ref[i];
          if (R.items[id] != null) {
            copy.addChild(R.items[id]);
          }
        }
        copy.rasterize();
        R.rasterizer.rasterize(copy, false);
        if (!this.socketAction) {
          copy.save(false);
        }
        return copy;
      };

      Drawing.getDraft = function() {
        return this.draft;
      };

      function Drawing(rectangle1, data1, id1, pk1, owner, date, title1, description, status, pathList, svg, bounds) {
        var jqxhr;
        this.rectangle = rectangle1;
        this.data = data1 != null ? data1 : null;
        this.id = id1 != null ? id1 : null;
        this.pk = pk1 != null ? pk1 : null;
        this.owner = owner != null ? owner : null;
        this.date = date;
        this.title = title1;
        this.description = description;
        this.status = status != null ? status : 'pending';
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
        this.update = bind(this.update, this);
        this.updateCallback = bind(this.updateCallback, this);
        this.submitCallback = bind(this.submitCallback, this);
        this.saveCallback = bind(this.saveCallback, this);
        this.onLiClick = bind(this.onLiClick, this);
        Drawing.__super__.constructor.call(this, this.data, this.id, this.pk);
        if (this.pk != null) {
          this.constructor.pkToId[this.pk] = this.id;
        }
        if (bounds != null) {
          this.bounds = new P.Rectangle(bounds);
        }
        if (R.drawings == null) {
          R.drawings = [];
        }
        R.drawings.push(this);
        if (R.pkToDrawing == null) {
          R.pkToDrawing = {};
        }
        R.pkToDrawing[this.pk] = this;
        this.paths = [];
        this.group.remove();
        this.votes = [];
        this.sortedPaths = [];
        this.addToListItem(this.getListItem());
        if (this.status === 'draft') {
          this.constructor.draft = this;
        }
        if (this.pk != null) {
          jqxhr = $.get(location.origin + '/static/drawings/' + this.pk + '.svg', ((function(_this) {
            return function(result) {
              _this.setSVG(svg);
            };
          })(this))).fail((function(_this) {
            return function() {
              var args;
              if (_this.svg != null) {
                return;
              }
              args = {
                pk: _this.pk,
                svgOnly: true
              };
              return $.ajax({
                method: "POST",
                url: "ajaxCall/",
                data: {
                  data: JSON.stringify({
                    "function": 'loadDrawing',
                    args: args
                  })
                }
              }).done(function(result) {
                var drawing;
                drawing = JSON.parse(result.drawing);
                return _this.setSVG(drawing.svg);
              });
            };
          })(this));
        }
        if (this.status === 'draft') {
          this.addPathsFromPathList(pathList);
        }
        return;
      }

      Drawing.prototype.setPK = function(pk) {
        Drawing.__super__.setPK.call(this, pk);
        if (R.pkToDrawing == null) {
          R.pkToDrawing = {};
        }
        R.pkToDrawing[this.pk] = this;
      };

      Drawing.prototype.getPointLists = function() {
        var i, len, path, pointLists, ref;
        pointLists = [];
        ref = this.paths;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          pointLists.push(path.getPoints());
        }
        return pointLists;
      };

      Drawing.prototype.addPathsFromPathList = function(pathList, parseJSON) {
        var data, i, len, p, path, points;
        if (parseJSON == null) {
          parseJSON = true;
        }
        for (i = 0, len = pathList.length; i < len; i++) {
          p = pathList[i];
          points = parseJSON ? JSON.parse(p) : p;
          if (points == null) {
            continue;
          }
          data = {
            points: points,
            planet: new P.Point(0, 0),
            strokeWidth: Item.Path.strokeWidth
          };
          path = new Item.Path.PrecisePath(Date.now(), data, null, null, null, null, R.me, this.id);
          path.pk = path.id;
          path.loadPath();
          path.draw();
        }
      };

      Drawing.prototype.setSVG = function(svg) {
        var doc, layer, layerName, parser;
        layerName = this.getLayerName();
        layer = document.getElementById(layerName);
        parser = new DOMParser();
        doc = parser.parseFromString(svg, "image/svg+xml");
        doc.documentElement.removeAttribute('visibility');
        doc.documentElement.removeAttribute('xmlns');
        doc.documentElement.removeAttribute('stroke');
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
      };

      Drawing.prototype.setStrokeColorFromVote = function(positive) {
        var colorClass, ref, spanJ;
        if (this.status === 'pending') {
          if ((ref = this.svg) != null) {
            ref.setAttribute('stroke', positive ? '#009688' : '#f44336');
          }
        }
        colorClass = positive ? 'drawing-color' : 'rejected-color';
        spanJ = $('<span class="badge ' + colorClass + '"></span>');
        spanJ.text(i18next.t(positive ? 'voted for' : 'voted against'));
        $('#RItems li[data-id="' + this.id + '"] .badge-container').append(spanJ);
      };

      Drawing.prototype.getPathIds = function() {
        var child, i, len, pathIds, ref;
        pathIds = [];
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          child = ref[i];
          pathIds.push(child.id);
        }
        return pathIds;
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
        if (this.status === 'draft') {
          R.toolManager.updateButtonsVisibility(this);
        }
        this.updatePaths();
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
            itemListJ = R.view.flaggedListJ;
            break;
          default:
            R.alertManager.alert("Error: drawing status is invalid", "error");
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

      Drawing.prototype.addToListItem = function(itemListJ1) {
        var divJ, nItemsJ, ref, ref1, showBtnJ, title;
        this.itemListJ = itemListJ1;
        title = '' + this.title + ' <span data-i18n="by">' + i18next.t('by') + '</span> ' + this.owner;
        this.liJ = $("<li>");
        this.liJ.html(title);
        divJ = $("<div class='cd-row cd-end badge-container'>");
        showBtnJ = $('<button type="button" class="btn btn-default show-btn" aria-label="Show">');
        this.eyeIconJ = $('<span class="glyphicon eye glyphicon-eye-open" aria-hidden="true"></span>');
        showBtnJ.append(this.eyeIconJ);
        showBtnJ.click((function(_this) {
          return function(event) {
            _this.toggleVisibility();
            event.preventDefault();
            event.stopPropagation();
            return -1;
          };
        })(this));
        divJ.append(showBtnJ);
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
          nItemsJ.html(this.itemListJ.find('.rPath-list').children().length);
        }
      };

      Drawing.prototype.removeFromListItem = function() {
        var nItemsJ, ref;
        this.liJ.remove();
        nItemsJ = (ref = this.itemListJ) != null ? ref.find(".n-items") : void 0;
        if ((nItemsJ != null) && nItemsJ.length > 0) {
          nItemsJ.html(this.itemListJ.find('.rPath-list').children().length);
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
        var bounds, i, len, path, ref;
        if (this.bounds != null) {
          this.rectangle = this.bounds.clone();
          return this.rectangle;
        }
        if (this.svg != null) {
          if (this.svg.getBBox != null) {
            this.rectangle = new P.Rectangle(this.svg.getBBox());
          }
          return;
        }
        this.rectangle = null;
        if (this.group.children.length > 0) {
          return this.group.bounds.expand(2 * R.Path.strokeWidth);
        }
        ref = this.paths;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          bounds = path.getDrawingBounds();
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

      Drawing.prototype.addPathToProperLayer = function(path) {
        this.group.addChild(path.path);
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

      Drawing.prototype.addPaths = function() {
        var i, len, path, ref;
        ref = this.paths;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          this.group.addChild(path.path);
          console.log(path.path);
        }
      };

      Drawing.addPaths = function() {
        var drawing, i, len, ref;
        ref = R.drawings;
        for (i = 0, len = ref.length; i < len; i++) {
          drawing = ref[i];
          drawing.addPaths();
        }
      };

      Drawing.prototype.addChild = function(path) {
        var bounds;
        if (this.paths.indexOf(path) >= 0) {
          console.log('path already in drawing');
          return;
        }
        this.paths.push(path);
        path.drawingId = this.id;
        if (this.pathPks == null) {
          this.pathPks = [];
        }
        this.pathPks.push(path.pk);
        this.group.addChild(path.path);
        bounds = path.getDrawingBounds();
        if (bounds != null) {
          if (this.rectangle == null) {
            this.rectangle = bounds.clone();
          }
          this.rectangle = this.rectangle.unite(bounds);
        }
        path.updateStrokeColor();
        path.removeFromListItem();
      };

      Drawing.prototype.replaceDrawing = function() {
        var i, item, len, ref, ref1, ref2;
        if ((this.drawing == null) || (this.drawingRelativePosition == null)) {
          return;
        }
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.drawn = false;
          if ((ref1 = item.drawing) != null) {
            ref1.remove();
          }
          if ((ref2 = item.raster) != null) {
            ref2.remove();
          }
        }
        Drawing.__super__.replaceDrawing.call(this);
      };

      Drawing.prototype.removeChild = function(path, updateRectangle, removeID) {
        var pathIndex, pkIndex, ref;
        if (updateRectangle == null) {
          updateRectangle = false;
        }
        if (removeID == null) {
          removeID = true;
        }
        if (removeID) {
          path.drawingId = null;
        }
        pathIndex = this.paths.indexOf(path);
        if (pathIndex >= 0) {
          this.paths.splice(pathIndex, 1);
        }
        if ((ref = path.path) != null) {
          ref.remove();
        }
        path.drawingId = null;
        pkIndex = this.pathPks.indexOf(path.pk);
        if (pkIndex >= 0) {
          this.pathPks.splice(pkIndex, 1);
        }
        if (updateRectangle) {
          this.computeRectangle();
        }
        path.updateStrokeColor();
        path.addToListItem();
        this.drawn = false;
      };

      Drawing.prototype.setParameter = function(name, value, updateGUI, update) {
        Drawing.__super__.setParameter.call(this, name, value, updateGUI, update);
      };

      Drawing.prototype.save = function(addCreateCommand) {
        var args;
        if (addCreateCommand == null) {
          addCreateCommand = true;
        }
        args = {
          city: R.city,
          clientId: this.id,
          date: Date.now(),
          title: this.title || '' + Math.random(),
          description: this.description || '',
          points: this.points
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'saveDrawing',
              args: args
            })
          }
        }).done(this.saveCallback);
        Drawing.__super__.save.call(this, false);
      };

      Drawing.prototype.saveCallback = function(result) {
        var args, i, len, path, pointLists, ref;
        R.loader.checkError(result);
        if (result.pk == null) {
          this.remove();
          return;
        }
        this.owner = result.owner;
        this.setPK(result.pk);
        if (this.selectAfterSave != null) {
          this.select(true, true, true);
        }
        if (this.updateAfterSave != null) {
          this.update(this.updateAfterSave);
        }
        if (this.pathsToSave != null) {
          pointLists = [];
          ref = this.pathsToSave;
          for (i = 0, len = ref.length; i < len; i++) {
            path = ref[i];
            pointLists.push(path.getPoints());
          }
          args = {
            clientId: this.id,
            pk: this.pk,
            pointLists: pointLists
          };
          this.pathsToSave = [];
          $.ajax({
            method: "POST",
            url: "ajaxCall/",
            data: {
              data: JSON.stringify({
                "function": 'addPathsToDrawing',
                args: args
              })
            }
          }).done(R.loader.checkError);
        }
        Drawing.__super__.saveCallback.apply(this, arguments);
      };

      Drawing.prototype.addPathToSave = function(path) {
        if (this.pathsToSave == null) {
          this.pathsToSave = [];
        }
        this.pathsToSave.push(path);
      };

      Drawing.prototype.getLayerName = function() {
        var statusName;
        statusName = this.status === 'emailNotConfirmed' || this.status === 'notConfirmed' ? 'pending' : this.status;
        return statusName + 'Layer';
      };

      Drawing.prototype.getBounds = function() {
        this.computeRectangle();
        if ((this.svg == null) && this.paths.length === 0) {
          return null;
        }
        return this.rectangle;
      };

      Drawing.prototype.getSVG = function(asString) {
        var i, len, path, ref;
        if (asString == null) {
          asString = true;
        }
        if ((this.paths != null) && this.paths.length > 0) {
          ref = this.paths;
          for (i = 0, len = ref.length; i < len; i++) {
            path = ref[i];
            this.group.addChild(path.path);
          }
          return this.group.exportSVG({
            asString: asString
          });
        } else {
          return this.svg;
        }
      };

      Drawing.prototype.submit = function() {
        var args, bounds, imageURL, svg;
        bounds = this.getBounds();
        svg = this.getSVG();
        this.svgString = svg;
        imageURL = R.view.getThumbnail(this, 1200, 630, true, true);
        args = {
          pk: this.pk,
          clientId: this.id,
          date: Date.now(),
          title: this.title,
          description: this.description,
          svg: svg,
          png: imageURL,
          bounds: JSON.stringify(bounds)
        };
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
        var i, len, path, ref;
        if (addCommand == null) {
          addCommand = false;
        }
        if (addCommand) {
          R.commandManager.add(new R.Command.ModifyDrawing(this));
        }
        ref = this.paths.slice();
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          path.remove();
        }
        if (this.status === 'draft') {
          R.toolManager.updateButtonsVisibility(this);
        }
        if (addCommand) {
          this.updatePaths();
        }
      };

      Drawing.prototype.submitCallback = function(result) {
        var modal;
        if (!R.loader.checkError(result)) {
          return;
        }
        R.commandManager.clearHistory();
        this.status = result.status;
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
            return function() {
              return R.drawingPanel.shareOnFacebook(null, _this);
            };
          })(this)),
          submitButtonText: 'Share on Facebook',
          cancelButtonText: 'No thanks'
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
          type: 'success',
          name: 'See discussion page',
          submit: ((function(_this) {
            return function() {
              $.ajax({
                method: "POST",
                url: "ajaxCall/",
                data: {
                  data: JSON.stringify({
                    "function": 'getDrawingDiscussionId',
                    args: {
                      pk: _this.pk
                    }
                  })
                }
              }).done(function(results) {
                var drawing;
                if (!R.loader.checkError(results)) {
                  return;
                }
                drawing = JSON.parse(results.drawing);
                if (drawing.discussionId != null) {
                  R.drawingPanel.startDiscussion(results.discussionId);
                } else {
                  R.alertManager.alert("The discussion page is not created yet", "error");
                }
              });
            };
          })(this))
        });
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
        modal.addText('A discussion page for this drawing will be created in a few seconds');
        modal.addText('Would you like to share your drawing on Facebook or Twitter');
        modal.show();
      };

      Drawing.prototype.updatePaths = function() {
        var args;
        this.computeRectangle();
        args = {
          clientId: this.id,
          pk: this.pk,
          pointLists: this.getPointLists()
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'setPathsToDrawing',
              args: args
            })
          }
        }).done(R.loader.checkError);
      };

      Drawing.prototype.addUpdateFunctionAndArguments = function(args, type) {
        var i, item, len, ref;
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.addUpdateFunctionAndArguments(args, type);
        }
      };

      Drawing.prototype.updateCallback = function(result) {
        var contentJ;
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

      Drawing.prototype.deleteFromDatabaseCallback = function() {
        var i, id, len, ref;
        id = this.id;
        if (!R.loader.checkError()) {
          if (this.pathIdsBeforeRemove != null) {
            ref = this.pathIdsBeforeRemove;
            for (i = 0, len = ref.length; i < len; i++) {
              id = ref[i];
              if (R.items[id] != null) {
                this.addChild(R.items[id]);
              }
            }
            this.rasterize();
            R.rasterizer.rasterize(this, false);
          }
          return;
        }
        Drawing.__super__.deleteFromDatabaseCallback.call(this);
        R.alertManager.alert("Drawing successfully cancelled", "success");
      };

      Drawing.prototype["delete"] = function() {
        var deffered;
        this.pathIdsBeforeRemove = this.getPathIds();
        deffered = Drawing.__super__["delete"].apply(this, arguments);
        return deffered;
      };

      Drawing.prototype.deleteFromDatabase = function() {
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
        var draft, i, j, len, len1, path, ref, ref1, ref2;
        if (!R.loader.checkError(result)) {
          return;
        }
        ref = this.paths.slice();
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          this.removeChild(path);
        }
        draft = Drawing.getDraft();
        if (draft != null) {
          ref1 = draft.paths;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            path = ref1[j];
            this.addChild(path);
          }
          draft.remove();
        }
        if ((ref2 = this.svg) != null) {
          ref2.remove();
        }
        this.svg = null;
        this.addPathsFromPathList(result.pathList);
        this.updateStatus(result.status);
        this.constructor.draft = this;
      };

      Drawing.prototype.setRectangle = function(rectangle, update) {
        if (update == null) {
          update = true;
        }
        Drawing.__super__.setRectangle.call(this, rectangle, update);
      };

      Drawing.prototype.moveTo = function(position, update) {
        var delta, i, item, len, ref;
        delta = position.subtract(this.rectangle.center);
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.rectangle.center.x += delta.x;
          item.rectangle.center.y += delta.y;
          if (Item.Div.prototype.isPrototypeOf(item)) {
            item.updateTransform();
          }
        }
        Drawing.__super__.moveTo.call(this, position, update);
      };

      Drawing.prototype.containsChildren = function() {
        var bounds, i, item, len, ref;
        bounds = item.getBounds();
        if (bounds == null) {
          return true;
        }
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (!this.rectangle.contains(bounds)) {
            return false;
          }
        }
        return true;
      };

      Drawing.prototype.showChildren = function() {
        var i, item, len, ref, ref1;
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if ((ref1 = item.group) != null) {
            ref1.visible = true;
          }
        }
      };

      Drawing.prototype.updateDrawingPanel = function() {
        var args;
        args = {
          pk: this.pk
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
        var i, layer, layerName, len, path, ref;
        this.status = status;
        this.removeFromListItem();
        this.addToListItem(this.getListItem());
        if (this.svg != null) {
          this.svg.remove();
          layerName = this.getLayerName();
          layer = document.getElementById(layerName);
          this.svg = layer.appendChild(this.svg);
        }
        ref = this.paths;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          path.updateStrokeColor();
        }
      };

      Drawing.prototype.select = function(updateOptions, showPanelAndLoad, force) {
        var i, item, len, ref;
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
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.deselect();
        }
        if (showPanelAndLoad) {
          R.drawingPanel.selectionChanged();
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
        return true;
      };

      Drawing.prototype.remove = function() {
        var i, len, path, ref, ref1;
        ref = this.paths.slice();
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          this.removeChild(path);
        }
        if ((ref1 = this.svg) != null) {
          ref1.remove();
        }
        this.removeFromListItem();
        R.rasterizer.rasterizeRectangle(this.rectangle);
        Drawing.__super__.remove.apply(this, arguments);
      };

      Drawing.prototype.getRaster = function() {
        var group, i, len, path, ref;
        if (this.pathRaster != null) {
          return this.pathRaster;
        }
        if (this.paths.length === 0) {
          return null;
        }
        group = new P.Group();
        ref = this.paths;
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          if (path.raster != null) {
            group.addChild(path.raster.clone());
          } else {
            if (path.drawing == null) {
              path.draw();
            }
            group.addChild(path.drawing.clone());
          }
        }
        this.pathRaster = group.rasterize(P.view.resolution, false);
        group.remove();
        return this.pathRaster;
      };

      Drawing.prototype.children = function() {
        return this.paths;
      };

      Drawing.prototype.highlight = function(color) {
        Drawing.__super__.highlight.call(this);
        if (color) {
          this.highlightRectangle.fillColor = color;
          this.highlightRectangle.strokeColor = color;
          this.highlightRectangle.dashArray = [];
        }
      };

      Drawing.prototype.rasterize = function() {};

      return Drawing;

    })(Item);
    Item.Drawing = Drawing;
    R.Drawing = Drawing;
    return Drawing;
  });

}).call(this);
