// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['Items/Item', 'UI/Modal'], function(Item, Modal) {
    var Drawing;
    Drawing = (function(superClass) {
      extend(Drawing, superClass);

      Drawing.label = 'Drawing';

      Drawing.object_type = 'drawing';

      Drawing.initialize = function(rectangle) {};

      Drawing.initializeParameters = function() {
        var parameters;
        parameters = Drawing.__super__.constructor.initializeParameters.call(this);
        delete parameters['Style'];
        return parameters;
      };

      Drawing.parameters = Drawing.initializeParameters();

      function Drawing(rectangle1, data1, id1, pk, owner, date, title1, description, status) {
        var id, path;
        this.rectangle = rectangle1;
        this.data = data1 != null ? data1 : null;
        this.id = id1 != null ? id1 : null;
        this.pk = pk != null ? pk : null;
        this.owner = owner != null ? owner : null;
        this.date = date;
        this.title = title1;
        this.description = description;
        this.status = status;
        this.select = bind(this.select, this);
        this.update = bind(this.update, this);
        this.saveCallback = bind(this.saveCallback, this);
        this.onLiClick = bind(this.onLiClick, this);
        Drawing.__super__.constructor.call(this, this.data, this.id, this.pk);
        this.drawing = new P.Group();
        this.group.addChild(this.drawing);
        this.votes = [];
        for (id in R.paths) {
          path = R.paths[id];
          if ((path.drawingID != null) === this.id) {
            this.addChild(path);
          }
        }
        this.sortedPaths = [];
        this.addToListItem(this.getListItem());
        return;
      }

      Drawing.prototype.getListItem = function() {
        var itemListJ;
        itemListJ = null;
        switch (this.status) {
          case 'pending':
            R.view.pendingLayer.addChild(this.group);
            itemListJ = R.view.pendingListJ;
            break;
          case 'drawing':
            R.view.drawingLayer.addChild(this.group);
            itemListJ = R.view.drawingListJ;
            break;
          case 'drawn':
            R.view.drawnLayer.addChild(this.group);
            itemListJ = R.view.drawnListJ;
            break;
          case 'rejected':
            R.view.rejectedLayer.addChild(this.group);
            itemListJ = R.view.rejectedListJ;
            break;
          default:
            R.alertManager.alert("Error: drawing status is invalid.", "error");
        }
        return itemListJ;
      };

      Drawing.prototype.addToListItem = function(itemListJ1) {
        var nItemsJ, ref, ref1, title;
        this.itemListJ = itemListJ1;
        title = '' + this.title + ' by ' + this.owner;
        this.liJ = $("<li>");
        this.liJ.html(title);
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
        this.select();
      };

      Drawing.prototype.addChild = function(path) {
        this.drawing.addChild(path.group);
        path.updateStrokeColor();
        this.drawn = false;
        if ((this.raster != null) && this.raster.parent !== null) {
          this.replaceDrawing();
        }
      };

      Drawing.prototype.setParameter = function(name, value, updateGUI, update) {
        Drawing.__super__.setParameter.call(this, name, value, updateGUI, update);
      };

      Drawing.prototype.save = function(addCreateCommand) {
        var args, data, siteData;
        if (addCreateCommand == null) {
          addCreateCommand = true;
        }
        if (R.view.grid.rectangleOverlapsTwoPlanets(this.rectangle)) {
          return;
        }
        if (this.rectangle.area === 0) {
          this.remove();
          R.alertManager.alert("Error: your box is not valid.", "error");
          return;
        }
        data = this.getData();
        siteData = {
          restrictArea: data.restrictArea,
          disableToolbar: data.disableToolbar,
          loadEntireArea: data.loadEntireArea
        };
        args = {
          clientID: this.id,
          city: {
            city: R.city
          },
          box: Utils.CS.boxFromRectangle(this.rectangle),
          object_type: this.constructor.object_type,
          data: JSON.stringify(data),
          siteData: JSON.stringify(siteData),
          siteName: data.siteName
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'saveBox',
              args: args
            })
          }
        }).done(this.saveCallback);
        Drawing.__super__.save.apply(this, arguments);
      };

      Drawing.prototype.saveCallback = function(result) {
        R.loader.checkError(result);
        if (result.pk == null) {
          this.remove();
          return;
        }
        this.owner = result.owner;
        this.setPK(result.pk);
        if (this.updateAfterSave != null) {
          this.update(this.updateAfterSave);
        }
        Drawing.__super__.saveCallback.apply(this, arguments);
      };

      Drawing.prototype.addUpdateFunctionAndArguments = function(args, type) {
        var i, item, len, ref;
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.addUpdateFunctionAndArguments(args, type);
        }
      };

      Drawing.prototype.update = function(type) {
        var args, i, item, itemsToUpdate, len, updateBoxArgs;
        if (this.pk == null) {
          this.updateAfterSave = type;
          return;
        }
        delete this.updateAfterSave;
        if (R.view.grid.rectangleOverlapsTwoPlanets(this.rectangle)) {
          return;
        }
        updateBoxArgs = {
          box: Utils.CS.boxFromRectangle(this.rectangle),
          pk: this.pk,
          object_type: this.object_type,
          name: this.data.name,
          data: this.getStringifiedData(),
          updateType: type
        };
        args = [];
        args.push({
          "function": 'updateBox',
          "arguments": updateBoxArgs
        });
        if (type === 'position' || type === 'rectangle') {
          itemsToUpdate = type === 'position' ? this.children() : [];
          for (i = 0, len = itemsToUpdate.length; i < len; i++) {
            item = itemsToUpdate[i];
            args.push({
              "function": item.getUpdateFunction(),
              "arguments": item.getUpdateArguments()
            });
          }
        }
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'multipleCalls',
              args: {
                functionsAndArguments: args
              }
            })
          }
        }).done(this.updateCallback);
      };

      Drawing.prototype.updateCallback = function(results) {
        var i, len, result;
        for (i = 0, len = results.length; i < len; i++) {
          result = results[i];
          R.loader.checkError(result);
        }
      };

      Drawing.prototype.deleteFromDatabase = function() {
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'deleteBox',
              args: {
                'pk': this.pk
              }
            })
          }
        }).done(R.loader.checkError);
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
        var i, item, len, ref;
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          if (!this.rectangle.contains(item.getBounds())) {
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

      Drawing.prototype.select = function(updateOptions) {
        var args, i, item, len, ref;
        if (updateOptions == null) {
          updateOptions = true;
        }
        if (!Drawing.__super__.select.call(this, updateOptions)) {
          return false;
        }
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          item.deselect();
        }
        R.drawingPanel.showLoadAnimation();
        R.drawingPanel.open();
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
        return true;
      };

      Drawing.prototype.remove = function() {
        var i, len, path, ref;
        ref = this.children();
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          this.removeItem(path);
        }
        Utils.Array.remove(R.drawings, this);
        this.removeFromListItem();
        Drawing.__super__.remove.apply(this, arguments);
      };

      Drawing.prototype.children = function() {
        return this.sortedPaths;
      };

      Drawing.prototype.addItem = function(item) {
        Item.addItemTo(item, this);
        item.drawing = this;
      };

      Drawing.prototype.removeItem = function(item) {
        Item.addItemToStage(item);
        item.drawing = null;
      };

      Drawing.prototype.highlight = function(color) {
        Drawing.__super__.highlight.call(this);
        if (color) {
          this.highlightRectangle.fillColor = color;
          this.highlightRectangle.strokeColor = color;
          this.highlightRectangle.dashArray = [];
        }
      };

      Drawing.prototype.rasterize = function() {
        var base, child, i, len, ref;
        if (this.drawing.children.length === 0) {
          return;
        }
        ref = this.drawing.children;
        for (i = 0, len = ref.length; i < len; i++) {
          child = ref[i];
          if (typeof (base = child.controller).draw === "function") {
            base.draw();
          }
        }
        Drawing.__super__.rasterize.call(this);
      };

      Drawing.prototype.deleteCommand = function() {};

      return Drawing;

    })(Item);
    Item.Drawing = Drawing;
    return Drawing;
  });

}).call(this);
