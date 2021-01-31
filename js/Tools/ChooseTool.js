// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Items/Item', 'Commands/Command', 'UI/Modal', 'i18next', 'moment'], function(P, R, Utils, Tool, Item, Command, Modal, i18next, moment) {
    var ChooseTool;
    ChooseTool = (function(superClass) {
      extend(ChooseTool, superClass);

      ChooseTool.paperMargins = 16;

      ChooseTool.paperWidth = 210 - ChooseTool.paperMargins;

      ChooseTool.paperHeight = 297 - ChooseTool.paperMargins;

      ChooseTool.nSheetsPerTile = 2;

      ChooseTool.nSecondsPerTile = 0.25;

      ChooseTool.label = 'Choose a tile';

      ChooseTool.popover = false;

      ChooseTool.iconURL = 'new 1/Checkbox.svg';

      ChooseTool.buttonClasses = 'displayName';

      ChooseTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'pointer'
      };

      function ChooseTool() {
        this.submitCallback = bind(this.submitCallback, this);
        this.chooseTile = bind(this.chooseTile, this);
        this.createChooseTileModal = bind(this.createChooseTileModal, this);
        this.showGrid = bind(this.showGrid, this);
        this.showOddLines = bind(this.showOddLines, this);
        this.hideOddLines = bind(this.hideOddLines, this);
        var activeLayer;
        if (!R.isCommeUnDessein) {
          ChooseTool.__super__.constructor.call(this, true);
        }
        activeLayer = P.project.activeLayer;
        this.tileRectangles = new P.Layer();
        this.tileRectangles.bringToFront();
        this.tileRectangles.visible = false;
        activeLayer.activate();
        this.tiles = new Map();
        this.tilePks = [];
        this.idToTile = new Map();
        return;
      }

      ChooseTool.prototype.hideOddLines = function() {
        var ref;
        if ((ref = this.oddLines) != null) {
          ref.visible = false;
        }
      };

      ChooseTool.prototype.showOddLines = function() {
        var ref, ref1;
        if ((ref = this.oddLines) != null) {
          ref.visible = (ref1 = this.lines) != null ? ref1.visible : void 0;
        }
      };

      ChooseTool.prototype.showGrid = function() {
        var line, n, rectangle, x, y;
        if (R.isCommeUnDessein) {
          return;
        }
        this.tileRectangles.visible = true;
        if (this.lines != null) {
          this.lines.visible = true;
          this.oddLines.visible = Math.floor(Math.log(P.view.zoom) / Math.log(2)) >= -3;
          return;
        } else {
          this.lines = new P.Group();
          this.oddLines = new P.Group();
        }
        rectangle = R.view.grid.limitCDRectangle;
        x = rectangle.left;
        n = 0;
        while (x < rectangle.right) {
          line = new P.Path();
          line.add(x, rectangle.top);
          line.add(x, rectangle.bottom);
          line.strokeWidth = 1;
          line.strokeColor = 'black';
          line.strokeColor.opacity = 0.75;
          line.strokeScaling = false;
          if (n % this.constructor.nSheetsPerTile !== 0) {
            line.dashArray = [2, 2];
            this.oddLines.addChild(line);
          } else {
            this.lines.addChild(line);
          }
          x += this.constructor.paperWidth;
          n++;
        }
        y = rectangle.top;
        n = 0;
        while (y < rectangle.bottom) {
          line = new P.Path();
          line.add(rectangle.left, y);
          line.add(rectangle.right, y);
          line.strokeWidth = 1;
          line.strokeColor = 'black';
          line.strokeColor.opacity = 0.75;
          line.strokeScaling = false;
          if (n % this.constructor.nSheetsPerTile !== 0) {
            line.dashArray = [2, 2];
            this.oddLines.addChild(line);
          } else {
            this.lines.addChild(line);
          }
          y += this.constructor.paperHeight;
          n++;
        }
      };

      ChooseTool.prototype.hideGrid = function() {
        var ref, ref1;
        if (R.isCommeUnDessein) {
          return;
        }
        if ((ref = this.lines) != null) {
          ref.visible = false;
        }
        if ((ref1 = this.oddLines) != null) {
          ref1.visible = false;
        }
        this.tileRectangles.visible = false;
      };

      ChooseTool.prototype.select = function(deselectItems, updateParameters, forceSelect, selectedBy) {
        var ref, ref1;
        if (deselectItems == null) {
          deselectItems = false;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        if (forceSelect == null) {
          forceSelect = false;
        }
        if (selectedBy == null) {
          selectedBy = 'default';
        }
        if (R.isCommeUnDessein) {
          return;
        }
        if ((ref = R.city) != null ? ref.finished : void 0) {
          R.alertManager.alert("Cette édition est terminée, vous ne pouvez plus dessiner.", 'info');
          return;
        }
        if (!R.userAuthenticated && !forceSelect) {
          R.alertManager.alert('Log in before choosing a tile', 'info');
          return;
        }
        if ((ref1 = R.tracer) != null) {
          ref1.hide();
        }
        ChooseTool.__super__.select.call(this, false, updateParameters, selectedBy);
        R.tools.select.deselectAll();
        this.showGrid();
      };

      ChooseTool.prototype.deselect = function() {
        var ref;
        if (R.isCommeUnDessein) {
          return;
        }
        ChooseTool.__super__.deselect.apply(this, arguments);
        this.hideGrid();
        this.deselectTile();
        if ((ref = this.highlight) != null) {
          ref.visible = false;
        }
      };

      ChooseTool.prototype.begin = function(event) {};

      ChooseTool.prototype.update = function(event) {};

      ChooseTool.prototype.move = function(event) {
        var bottom, height, left, margin, ref, right, top, width;
        if (R.isCommeUnDessein) {
          return;
        }
        if (((ref = event.originalEvent) != null ? ref.target : void 0) !== document.getElementById('canvas')) {
          return;
        }
        if (this.ignoreMouseMoves) {
          return;
        }
        width = this.constructor.paperWidth * this.constructor.nSheetsPerTile;
        height = this.constructor.paperHeight * this.constructor.nSheetsPerTile;
        if (this.highlight == null) {
          margin = 5;
          this.highlight = new P.Path.Rectangle(margin, margin, width - margin, height - margin);
          this.highlight.strokeWidth = 5;
          this.highlight.strokeScaling = false;
          this.highlight.strokeColor = R.selectionBlue;
          this.highlight.dashArray = [8, 5];
        }
        left = R.view.grid.limitCDRectangle.left;
        top = R.view.grid.limitCDRectangle.top;
        right = R.view.grid.limitCDRectangle.right;
        bottom = R.view.grid.limitCDRectangle.bottom;
        this.highlight.position.x = left + (Math.floor((event.point.x - left) / width) + 0.5) * width;
        this.highlight.position.y = top + (Math.floor((event.point.y - top) / height) + 0.5) * height;
        this.highlight.visible = true;
        if (event.point.x < left || event.point.x > right || event.point.y < top || event.point.y > bottom) {
          this.highlight.visible = false;
        }
      };

      ChooseTool.prototype.projectToXY = function(point) {
        var height, left, tileX, tileY, top, width;
        width = this.constructor.paperWidth * this.constructor.nSheetsPerTile;
        height = this.constructor.paperHeight * this.constructor.nSheetsPerTile;
        left = R.view.grid.limitCDRectangle.left;
        top = R.view.grid.limitCDRectangle.top;
        tileX = Math.floor((point.x - left) / width);
        tileY = Math.floor((point.y - top) / height);
        return new P.Point(tileX, tileY);
      };

      ChooseTool.prototype.end = function(event) {
        var bottom, drawing, height, i, left, len, nDrawingsOnTile, nTilesPerColumn, nTilesPerRow, ref, ref1, ref2, right, tile, tileLeft, tileNumber, tileTop, tileX, tileY, top, width;
        if (R.isCommeUnDessein) {
          return;
        }
        if (!R.view.grid.limitCDRectangle.contains(event.point)) {
          return;
        }
        width = this.constructor.paperWidth * this.constructor.nSheetsPerTile;
        height = this.constructor.paperHeight * this.constructor.nSheetsPerTile;
        left = R.view.grid.limitCDRectangle.left;
        top = R.view.grid.limitCDRectangle.top;
        right = R.view.grid.limitCDRectangle.right;
        bottom = R.view.grid.limitCDRectangle.bottom;
        nTilesPerRow = Math.ceil((right - left) / width);
        nTilesPerColumn = Math.ceil((bottom - top) / height);
        console.log('num tiles: ' + (nTilesPerColumn * nTilesPerRow));
        tileX = Math.floor((event.point.x - left) / width);
        tileY = Math.floor((event.point.y - top) / height);
        tile = (ref = this.tiles.get(tileY)) != null ? ref.get(tileX) : void 0;
        tileNumber = Math.max(0, tileY - 1) * nTilesPerRow + tileX;
        tileLeft = left + tileX * width;
        tileTop = top + tileY * height;
        this.currentTile = {
          rectangle: new P.Rectangle(tileLeft, tileTop, width, height),
          x: tileX,
          y: tileY,
          number: tileNumber + 1
        };
        if (tile != null) {
          this.selectTile(tile);
          this.loadTile(tile._id.$oid);
          return;
        }
        nDrawingsOnTile = 0;
        ref1 = R.drawings;
        for (i = 0, len = ref1.length; i < len; i++) {
          drawing = ref1[i];
          if (drawing.status !== 'draft' && ((ref2 = drawing.getBounds()) != null ? ref2.intersects(this.currentTile.rectangle) : void 0)) {
            nDrawingsOnTile++;
          }
        }
        this.createChooseTileModal(tileNumber, tileX, tileY);
      };

      ChooseTool.prototype.createChooseTileModal = function(tileNumber, tileX, tileY) {
        var andText, date, divJ, dueTime, hours, minutes, modal, seconds;
        if (R.isCommeUnDessein) {
          return;
        }
        date = $('#canvas').attr('data-city-event-date');
        dueTime = moment(date).add(tileNumber * this.constructor.nSecondsPerTile, 'seconds');
        modal = Modal.createModal({
          id: 'choose-tile',
          title: "Choose tile",
          submit: ((function(_this) {
            return function() {
              return _this.chooseTile(tileNumber + 1, tileX, tileY, _this.currentTile.rectangle);
            };
          })(this))
        });
        modal.addText('Do you really want to paint this tile?', 'Do you want to paint this tile', false, {
          tileNumber: tileNumber + 1
        });
        hours = i18next.t('hours');
        minutes = i18next.t('minutes');
        seconds = i18next.t('seconds');
        andText = i18next.t('and');
        divJ = modal.addText(i18next.t('This tile must be placed'));
        divJ.text(divJ.text() + ' :');
        divJ = modal.addText(i18next.t('on the') + dueTime.format(' dddd D MMMM'));
        divJ.css({
          'text-align': 'center'
        });
        divJ = modal.addText(i18next.t('at precisely'));
        divJ.css({
          'text-align': 'center',
          'font-weight': 900,
          'font-style': 'italic'
        });
        divJ = modal.addText(dueTime.format('H [' + hours + '], m [' + minutes + ' ' + andText + '] s [' + seconds + '.]'));
        divJ.css({
          'text-align': 'center'
        });
        modal.modalJ.on('hidden.bs.modal', (function(_this) {
          return function() {
            return _this.ignoreMouseMoves = false;
          };
        })(this));
        modal.show();
        this.ignoreMouseMoves = true;
      };

      ChooseTool.prototype.getTileColorFromStatus = function(tile) {
        var color, statusToColor;
        statusToColor = {
          'pending': 'gray',
          'created': '#03a9f4',
          'validated': 'rgb(139, 195, 74)',
          'rejected': 'darkRed',
          'flagged': 'red'
        };
        color = statusToColor[tile.status];
        if (color == null) {
          color = 'gray';
        }
        return color;
      };

      ChooseTool.prototype.createTile = function(tile) {
        var height, left, tileRectangle, tilesRow, top, width;
        if (R.isCommeUnDessein) {
          return;
        }
        tilesRow = this.tiles.get(tile.y);
        if ((tilesRow != null) && tilesRow.get(tile.x)) {
          return;
        }
        width = this.constructor.paperWidth * this.constructor.nSheetsPerTile;
        height = this.constructor.paperHeight * this.constructor.nSheetsPerTile;
        left = R.view.grid.limitCDRectangle.left;
        top = R.view.grid.limitCDRectangle.top;
        tileRectangle = P.Path.Rectangle(left + tile.x * width, top + tile.y * height, width, height);
        tileRectangle.fillColor = this.getTileColorFromStatus(tile);
        tileRectangle.fillColor.alpha = 0.25;
        this.tileRectangles.addChild(tileRectangle);
        if (tilesRow == null) {
          tilesRow = new Map();
          this.tiles.set(tile.y, tilesRow);
        }
        tile.rectangle = tileRectangle;
        tilesRow.set(tile.x, tile);
        this.tilePks.push(tile._id.$oid);
        this.idToTile.set(tile.clientId, tile);
        return tile;
      };

      ChooseTool.prototype.updateTileStatus = function(tile, status) {
        var ref, t;
        if (status == null) {
          status = null;
        }
        t = (ref = this.tiles.get(tile.y)) != null ? ref.get(tile.x) : void 0;
        if (t != null) {
          t.status = status != null ? status : tile.status;
          t.rectangle.fillColor = this.getTileColorFromStatus(tile);
          t.rectangle.fillColor.alpha = 0.25;
        }
      };

      ChooseTool.prototype.selectTile = function(tile) {
        if (R.isCommeUnDessein) {
          return;
        }
        if ((this.selectedTile != null) && this.selectedTile !== tile) {
          this.deselectTile();
        }
        tile.rectangle.strokeColor = R.selectionBlue;
        tile.rectangle.strokeWidth = 4;
        tile.rectangle.strokeScaling = false;
        this.selectedTile = tile;
      };

      ChooseTool.prototype.deselectTile = function(updateDrawingPanel) {
        var ref, ref1;
        if (updateDrawingPanel == null) {
          updateDrawingPanel = true;
        }
        if (R.isCommeUnDessein) {
          return;
        }
        if (updateDrawingPanel) {
          R.drawingPanel.deselectTile();
        }
        if ((ref = this.selectedTile) != null) {
          if ((ref1 = ref.rectangle) != null) {
            ref1.strokeWidth = null;
          }
        }
        this.selectedTile = null;
      };

      ChooseTool.prototype.loadTile = function(pk, rectangle, setViewToTile) {
        var args;
        if (rectangle == null) {
          rectangle = this.currentTile.rectangle;
        }
        if (setViewToTile == null) {
          setViewToTile = false;
        }
        if (R.isCommeUnDessein) {
          return;
        }
        args = {
          pk: pk
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'loadTile',
              args: args
            })
          }
        }).done((function(_this) {
          return function(result) {
            if (!R.loader.checkError(result)) {
              return;
            }
            R.drawingPanel.setTile(result, rectangle);
            if (setViewToTile) {
              return R.view.fitRectangle(rectangle, true);
            }
          };
        })(this));
      };

      ChooseTool.prototype.removeTile = function(tileInfo, tile) {
        var ref;
        if (R.isCommeUnDessein) {
          return;
        }
        if (tile == null) {
          tile = (ref = this.tiles.get(tileInfo.y)) != null ? ref.get(tileInfo.x) : void 0;
        }
        if (tile != null) {
          if (tileInfo.clientId === tile.clientId) {
            tile.rectangle.remove();
            this.tiles.get(tileInfo.y)["delete"](tileInfo.x);
            this.tilePks.splice(this.tilePks.indexOf(tile.pk));
            this.idToTile["delete"](tile.clientId);
          }
        }
      };

      ChooseTool.prototype.removeTiles = function(limits) {
        var bottomRight, topLeft;
        if (R.isCommeUnDessein) {
          return;
        }
        topLeft = this.projectToXY(limits.topLeft);
        bottomRight = this.projectToXY(limits.bottomRight);
        this.tiles.forEach((function(_this) {
          return function(tileRow, y) {
            if (y < topLeft.y || y > bottomRight.y) {
              return;
            }
            return tileRow.forEach(function(tile, x) {
              if (x < topLeft.x || x > bottomRight.x) {
                return;
              }
              if (!tile.rectangle.bounds.intersects(limits)) {
                return _this.removeTile(tile);
              }
            });
          };
        })(this));
      };

      ChooseTool.prototype.chooseTile = function(number, x, y, bounds) {
        var args;
        if (R.isCommeUnDessein) {
          return;
        }
        this.ignoreMouseMoves = false;
        R.loader.showLoadingBar(500);
        args = {
          number: number,
          x: x,
          y: y,
          bounds: bounds,
          cityName: R.city.name,
          clientId: Utils.createId()
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'submitTile',
              args: args
            })
          }
        }).done(this.submitCallback);
      };

      ChooseTool.prototype.submitCallback = function(result) {
        var tile;
        R.loader.hideLoadingBar();
        if (!R.loader.checkError(result)) {
          return;
        }
        result.tile = JSON.parse(result.tile);
        tile = this.createTile(result.tile);
        this.selectTile(tile);
        R.drawingPanel.setTile(result, this.currentTile.rectangle);
      };

      ChooseTool.prototype.doubleClick = function(event) {};

      ChooseTool.prototype.keyUp = function(event) {};

      return ChooseTool;

    })(Tool);
    R.Tools.Choose = ChooseTool;
    return ChooseTool;
  });

}).call(this);

//# sourceMappingURL=ChooseTool.js.map
