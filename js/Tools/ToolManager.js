// Generated by CoffeeScript 1.10.0
(function() {
  var dependencies;

  dependencies = ['R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'Tools/MoveTool', 'Tools/SelectTool', 'Tools/PathTool', 'Tools/EraserTool', 'Tools/ItemTool', 'UI/Modal', 'i18next'];

  define('Tools/ToolManager', dependencies, function(R, Utils, Tool, Button, MoveTool, SelectTool, PathTool, EraserTool, ItemTool, Modal, i18next) {
    var ToolManager;
    ToolManager = (function() {
      function ToolManager() {
        var defaultFavoriteTools, error, error1;
        R.ToolsJ = $(".tool-list");
        R.favoriteToolsJ = $("#FavoriteTools .tool-list");
        R.allToolsContainerJ = $("#AllTools");
        R.allToolsJ = R.allToolsContainerJ.find(".all-tool-list");
        R.favoriteTools = [];
        if (typeof localStorage !== "undefined" && localStorage !== null) {
          try {
            R.favoriteTools = JSON.parse(localStorage.favorites);
          } catch (error1) {
            error = error1;
            console.log(error);
          }
        }
        R.tools.move = new R.Tools.Move();
        R.tools.select = new R.Tools.Select();
        R.tools.eraser = new R.Tools.Eraser();
        R.tools.eraser.btn.hide();
        defaultFavoriteTools = [];
        while (R.favoriteTools.length < 8 && defaultFavoriteTools.length > 0) {
          Utils.Array.pushIfAbsent(R.favoriteTools, defaultFavoriteTools.pop().label);
        }
        R.tools.move.select();
        R.wacomPlugin = document.getElementById('wacomPlugin');
        if (R.wacomPlugin != null) {
          R.wacomPenAPI = wacomPlugin.penAPI;
          R.wacomTouchAPI = wacomPlugin.touchAPI;
          R.wacomPointerType = {
            0: 'Mouse',
            1: 'Pen',
            2: 'Puck',
            3: 'Eraser'
          };
        }
        this.createZoombuttons();
        this.createUndoRedoButtons();
        this.createImportImageButton();
        this.createInfoButton();
        return;
      }

      ToolManager.prototype.zoom = function(value, snap) {
        var bounds, j, k, len, len1, newZoom, v, zoomValues;
        if (snap == null) {
          snap = true;
        }
        if (P.view.zoom * value < 0.125 || P.view.zoom * value > 4) {
          return;
        }
        bounds = R.view.getViewBounds(true);
        if (value < 1 && bounds.contains(R.view.grid.limitCD.bounds)) {
          return;
        }
        if (bounds.contains(R.view.grid.limitCD.bounds.scale(value))) {
          R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(200), true);
          return;
        }
        if (snap) {
          newZoom = 1;
          zoomValues = [0.125, 0.25, 0.5, 1, 2, 4];
          if (value < 1) {
            for (j = 0, len = zoomValues.length; j < len; j++) {
              v = zoomValues[j];
              if (P.view.zoom > v) {
                newZoom = v;
              } else {
                break;
              }
            }
          } else {
            for (k = 0, len1 = zoomValues.length; k < len1; k++) {
              v = zoomValues[k];
              if (P.view.zoom < v) {
                newZoom = v;
                break;
              }
            }
          }
          P.view.zoom = newZoom;
        } else {
          P.view.zoom *= value;
        }
        console.log(P.view.zoom);
        R.view.moveBy(new P.Point());
      };

      ToolManager.prototype.createZoombuttons = function() {
        this.zoomInBtn = new Button({
          name: 'Zoom +',
          iconURL: R.style === 'line' ? 'icones_icon_zoomin.png' : R.style === 'hand' ? 'a-zoomIn.png' : 'glyphicon-zoom-in',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: 1
        });
        this.zoomInBtn.btnJ.click((function(_this) {
          return function() {
            return _this.zoom(2);
          };
        })(this));
        this.zoomOutBtn = new Button({
          name: 'Zoom -',
          iconURL: R.style === 'line' ? 'icones_icon_zoomout.png' : R.style === 'hand' ? 'a-zoomOut.png' : 'glyphicon-zoom-out',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: 2
        });
        this.zoomOutBtn.btnJ.click((function(_this) {
          return function() {
            return _this.zoom(0.5);
          };
        })(this));
      };

      ToolManager.prototype.createUndoRedoButtons = function() {
        this.undoBtn = new Button({
          name: 'Undo',
          iconURL: R.style === 'line' ? 'icones_icon_back_02.png' : R.style === 'hand' ? 'a-undo.png' : 'glyphicon-share-alt',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: null,
          transform: 'scaleX(-1)'
        });
        this.undoBtn.hide();
        this.undoBtn.btnJ.click(function() {
          return R.commandManager.undo();
        });
        this.redoBtn = new Button({
          name: 'Redo',
          iconURL: R.style === 'line' ? 'icones_icon_forward_02.png' : R.style === 'hand' ? 'a-redo.png' : 'glyphicon-share-alt',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: null
        });
        this.redoBtn.hide();
        this.redoBtn.btnJ.click(function() {
          return R.commandManager["do"]();
        });
      };

      ToolManager.prototype.createImportImageButton = function() {
        var rasterGroup, removeRaster, submitURL;
        this.importImageBtn = new Button({
          name: 'Trace',
          iconURL: R.style === 'line' ? 'image.png' : R.style === 'hand' ? 'image.png' : 'glyphicon-picture',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: null
        });
        this.importImageBtn.hide();
        rasterGroup = null;
        R.traceGroup = rasterGroup;
        removeRaster = (function(_this) {
          return function() {
            if (rasterGroup != null) {
              rasterGroup.remove();
            }
          };
        })(this);
        submitURL = (function(_this) {
          return function(data) {
            var raster;
            removeRaster();
            rasterGroup = new P.Group();
            R.traceGroup = rasterGroup;
            rasterGroup.opacity = 0.5;
            raster = new P.Raster(data.imageURL);
            raster.position = R.view.getViewBounds().center;
            R.loader.showLoadingBar();
            raster.onError = function(event) {
              R.loader.hideLoadingBar();
              removeRaster();
              R.alertManager.alert('Could not load the image', 'error');
            };
            raster.onLoad = function(event) {
              var arrow, box, cross1, cross2, drawMoves, handle, handlePath, handlePos, j, len, pos, ref, sign, signOffsets, signRotations, size, viewBounds;
              R.loader.hideLoadingBar();
              viewBounds = R.view.getViewBounds();
              raster.position = viewBounds.center;
              if (raster.bounds.width > viewBounds.width) {
                raster.scaling = new paper.Point(viewBounds.width / (raster.bounds.width + raster.bounds.width * 0.25));
              }
              if (raster.bounds.height > viewBounds.height) {
                raster.scaling = raster.scaling.multiply(viewBounds.height / (raster.bounds.height + raster.bounds.height * 0.25));
              }
              rasterGroup.addChild(raster);
              raster.applyMatrix = false;
              size = new paper.Size(15, 15);
              sign = new P.Path();
              sign.add(6, 0);
              sign.add(0, 0);
              sign.add(0, 6);
              sign.strokeWidth = 2;
              sign.strokeColor = 'black';
              sign.pivot = new paper.Point(3, 3);
              sign.remove();
              signRotations = {
                'topCenter': 45,
                'rightCenter': 45 + 90,
                'bottomCenter': 45 + 90 + 90,
                'leftCenter': -45,
                'topRight': 90,
                'topLeft': 0,
                'bottomLeft': -90,
                'bottomRight': 180
              };
              signOffsets = {
                'topCenter': new paper.Point(0, 2),
                'rightCenter': new paper.Point(-2, 0),
                'bottomCenter': new paper.Point(0, -2),
                'leftCenter': new paper.Point(2, 0)
              };
              drawMoves = function() {
                var arrow, handle, handlePath, handlePos, handleSize, j, len, moves, pos, ref, ref1;
                if (((ref = rasterGroup.data) != null ? ref.moves : void 0) != null) {
                  rasterGroup.data.moves.remove();
                }
                moves = new P.Group();
                rasterGroup.addChild(moves);
                if (rasterGroup.data == null) {
                  rasterGroup.data = {};
                }
                rasterGroup.data.moves = moves;
                ref1 = ['topCenter', 'rightCenter', 'bottomCenter', 'leftCenter'];
                for (j = 0, len = ref1.length; j < len; j++) {
                  pos = ref1[j];
                  handle = new P.Group();
                  handleSize = size.clone();
                  if (pos === 'topCenter' || pos === 'bottomCenter') {
                    handleSize.width = raster.bounds.width - 1.25 * size.width;
                  } else {
                    handleSize.height = raster.bounds.height - 1.25 * size.width;
                  }
                  handlePos = raster.bounds[pos].subtract(handleSize.divide(2));
                  handlePath = new P.Path.Rectangle(handlePos, handleSize);
                  handlePath.fillColor = '#42b3f4';
                  handle.addChild(handlePath);
                  arrow = sign.clone();
                  arrow.position = raster.bounds[pos].add(signOffsets[pos]);
                  arrow.rotation = signRotations[pos];
                  handle.addChild(arrow);
                  if (raster.data == null) {
                    raster.data = {};
                  }
                  raster.data[pos] = handle;
                  handle.applyMatrix = false;
                  handle.on('mousedown', function(event) {
                    R.draggingImage = true;
                  });
                  handle.on('mousedrag', function(event) {
                    if (!R.scalingImage) {
                      rasterGroup.position = rasterGroup.position.add(event.delta);
                      R.draggingImage = true;
                    }
                  });
                  handle.on('mouseup', function(event) {
                    R.draggingImage = false;
                  });
                  moves.addChild(handle);
                }
              };
              drawMoves();
              ref = ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'];
              for (j = 0, len = ref.length; j < len; j++) {
                pos = ref[j];
                handle = new P.Group();
                handlePos = raster.bounds[pos].subtract(size.divide(2));
                handlePath = new P.Path.Rectangle(handlePos, size);
                handlePath.fillColor = '#42b3f4';
                handle.addChild(handlePath);
                box = handlePath.bounds.expand(-5);
                if (raster.data == null) {
                  raster.data = {};
                }
                raster.data[pos] = handle;
                if (pos === 'topRight') {
                  cross1 = new P.Path();
                  cross1.add(box.topLeft);
                  cross1.add(box.bottomRight);
                  cross1.strokeWidth = 2;
                  cross1.strokeColor = 'black';
                  handle.addChild(cross1);
                  cross2 = new P.Path();
                  cross2.add(box.topRight);
                  cross2.add(box.bottomLeft);
                  cross2.strokeWidth = 2;
                  cross2.strokeColor = 'black';
                  handle.addChild(cross2);
                  handle.on('mousedown', function() {
                    R.draggingImage = true;
                    removeRaster();
                  });
                } else {
                  arrow = sign.clone();
                  arrow.position = raster.bounds[pos];
                  arrow.rotation = signRotations[pos];
                  handle.addChild(arrow);
                  handle.on('mousedown', function(event) {
                    R.draggingImage = true;
                    R.scalingImage = true;
                  });
                  handle.on('mousedrag', function(event) {
                    var center, i, k, len1, newLength, previousLength, ref1;
                    R.draggingImage = true;
                    center = raster.bounds.center;
                    previousLength = event.point.subtract(event.delta).getDistance(center);
                    newLength = event.point.getDistance(center);
                    raster.scaling = raster.scaling.multiply(newLength / previousLength);
                    ref1 = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'];
                    for (i = k = 0, len1 = ref1.length; k < len1; i = ++k) {
                      pos = ref1[i];
                      raster.data[pos].position = raster.bounds[pos];
                    }
                    drawMoves();
                  });
                  handle.on('mouseup', function(event) {
                    R.draggingImage = false;
                    R.scalingImage = false;
                  });
                }
                rasterGroup.addChild(handle);
              }
            };
            raster.on('mousedrag', function(event) {});
            R.view.selectionLayer.addChild(rasterGroup);
          };
        })(this);
        this.importImageBtn.btnJ.click((function(_this) {
          return function() {
            var modal;
            modal = Modal.createModal({
              id: 'import-image',
              title: "Import image to trace",
              submit: submitURL
            });
            modal.addTextInput({
              name: 'imageURL',
              placeholder: 'http://exemple.fr/belle-image.png',
              type: 'url',
              submitShortcut: true,
              label: 'Image URL',
              required: true,
              errorMessage: i18next.t('The URL is invalid')
            });
            modal.show();
          };
        })(this));
      };

      ToolManager.prototype.createInfoButton = function() {
        this.infoBtn = new Button({
          name: 'Help',
          iconURL: 'icones_info.png',
          favorite: false,
          category: null,
          popover: true,
          order: 1000,
          classes: 'align-end',
          parentJ: $("#user-profile"),
          prepend: true,
          divType: 'div'
        });
        this.infoBtn.btnJ.click(function() {
          var mailJ, modal, welcomeTextJ;
          welcomeTextJ = $('#welcome-text');
          modal = Modal.createModal({
            id: 'info',
            title: 'Welcome to Comme un Dessein',
            submit: (function() {})
          });
          modal.addCustomContent({
            divJ: welcomeTextJ.clone(),
            name: 'welcome-text'
          });
          modal.modalJ.find('[name="cancel"]').hide();
          mailJ = $('<div>' + i18next.t('Contact us at') + ' <a href="mailto:idlv.contact@gmail.com">idlv.contact@gmail.com</a></div>');
          modal.addCustomContent({
            divJ: mailJ
          });
          modal.show();
        });
      };

      ToolManager.prototype.createSubmitButton = function() {
        this.submitButton = new Button({
          name: 'Submit drawing',
          iconURL: 'icones_icon_proposer_02.png',
          classes: 'btn-success displayName',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              var ref;
              if ((ref = R.traceGroup) != null) {
                ref.visible = false;
              }
              R.drawingPanel.submitDrawingClicked();
            };
          })(this)
        });
        this.submitButton.hide();
      };

      ToolManager.prototype.createDeleteButton = function() {
        this.deleteButton = new Button({
          name: 'Delete draft',
          iconURL: 'icones_cancel_02.png',
          classes: 'btn-danger',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              var draft;
              draft = R.Drawing.getDraft();
              if (draft != null) {
                draft.removePaths(true);
              }
              R.tools['Precise path'].showDraftLimits();
            };
          })(this)
        });
        this.deleteButton.hide();
      };

      ToolManager.prototype.updateButtonsVisibility = function(draft) {
        if (draft == null) {
          draft = null;
        }
        if (R.selectedTool === R.tools['Precise path'] || R.selectedTool === R.tools.eraser) {
          this.redoBtn.show();
          this.undoBtn.show();
          this.submitButton.show();
          this.deleteButton.show();
          this.importImageBtn.show();
          R.tools.eraser.btn.show();
        } else {
          this.redoBtn.hide();
          this.undoBtn.hide();
          this.submitButton.hide();
          this.deleteButton.hide();
          this.importImageBtn.hide();
          R.tools.eraser.btn.hide();
        }
        if (draft == null) {
          draft = R.Drawing.getDraft();
        }
        if ((draft == null) || (draft.paths == null) || draft.paths.length === 0 || (R.drawingPanel.opened && R.drawingPanel.status !== 'information')) {
          this.submitButton.hide();
          this.deleteButton.hide();
        } else {
          this.submitButton.show();
          this.deleteButton.show();
        }
      };

      ToolManager.prototype.enterDrawingMode = function() {
        var id, item, ref;
        if (R.selectedTool !== R.tools['Precise path']) {
          R.tools['Precise path'].select();
        }
        ref = R.items;
        for (id in ref) {
          item = ref[id];
          if (R.items[id].owner === R.me) {
            R.drawingPanel.showSubmitDrawing();
            break;
          }
        }
      };

      ToolManager.prototype.leaveDrawingMode = function(selectTool) {
        if (selectTool == null) {
          selectTool = false;
        }
        if (selectTool) {
          R.tools.select.select(false, true, true);
        }
        R.drawingPanel.hideSubmitDrawing();
      };

      ToolManager.prototype.enableDrawingButton = function(enable) {
        if (enable) {
          R.sidebar.favoriteToolsJ.find("[data-name='Precise path']").css({
            opacity: 1
          });
        } else {
          R.sidebar.favoriteToolsJ.find("[data-name='Precise path']").css({
            opacity: 0.25
          });
        }
      };

      return ToolManager;

    })();
    return ToolManager;
  });

}).call(this);
