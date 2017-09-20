// Generated by CoffeeScript 1.10.0
(function() {
  var dependencies;

  dependencies = ['R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'Tools/MoveTool', 'Tools/SelectTool', 'Tools/PathTool', 'Tools/EraserTool', 'Tools/ItemTool', 'UI/Modal'];

  define('Tools/ToolManager', dependencies, function(R, Utils, Tool, Button, MoveTool, SelectTool, PathTool, EraserTool, ItemTool, Modal) {
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
        this.createInfoButton();
        return;
      }

      ToolManager.prototype.zoom = function(value, snap) {
        var bounds, i, j, len, len1, newZoom, v, zoomValues;
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
            for (i = 0, len = zoomValues.length; i < len; i++) {
              v = zoomValues[i];
              if (P.view.zoom > v) {
                newZoom = v;
              } else {
                break;
              }
            }
          } else {
            for (j = 0, len1 = zoomValues.length; j < len1; j++) {
              v = zoomValues[j];
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
          description: 'Zoom +',
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
          description: 'Zoom -',
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
          iconURL: R.style === 'line' ? 'icones_icon_back.png' : R.style === 'hand' ? 'a-undo.png' : 'glyphicon-share-alt',
          favorite: true,
          category: null,
          description: 'Undo',
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
          iconURL: R.style === 'line' ? 'icones_icon_forward.png' : R.style === 'hand' ? 'a-redo.png' : 'glyphicon-share-alt',
          favorite: true,
          category: null,
          description: 'Redo',
          popover: true,
          order: null
        });
        this.redoBtn.hide();
        this.redoBtn.btnJ.click(function() {
          return R.commandManager["do"]();
        });
      };

      ToolManager.prototype.createInfoButton = function() {
        this.infoBtn = new Button({
          name: 'Info',
          iconURL: 'glyphicon-info-sign',
          favorite: true,
          category: null,
          description: 'Info',
          popover: true,
          order: 1000,
          classes: 'align-end'
        });
        this.infoBtn.btnJ.click(function() {
          var modal, welcomeTextJ;
          welcomeTextJ = $('#welcome-text');
          modal = Modal.createModal({
            title: 'Welcome to Comme Un Dessein',
            submit: (function() {
              return location.pathname = '/accounts/signup/';
            }),
            postSubmit: 'load',
            submitButtonText: 'Sign up',
            submitButtonIcon: 'glyphicon-user',
            cancelButtonText: 'Just visit',
            cancelButtonIcon: 'glyphicon-sunglasses'
          });
          modal.addCustomContent({
            divJ: welcomeTextJ.clone(),
            name: 'welcome-text'
          });
          modal.modalJ.find('[name="cancel"]').removeClass('btn-default').addClass('btn-warning');
          modal.addButton({
            type: 'info',
            name: 'Sign in',
            icon: 'glyphicon-log-in'
          });
          modal.modalJ.find('[name="Sign in"]').attr('data-toggle', 'dropdown').after($('#user-profile').find('.dropdown-menu').clone());
          modal.modalJ.find('.dropdown-menu').find('li.sign-up').hide();
          modal.show();
        });
      };

      ToolManager.prototype.createSubmitButton = function() {
        this.submitButton = new Button({
          name: 'Submit drawing',
          iconURL: 'icones_icon_ok.png',
          classes: 'btn-success displayName',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              R.drawingPanel.submitDrawingClicked();
            };
          })(this)
        });
        this.submitButton.hide();
      };

      ToolManager.prototype.createDeleteButton = function() {
        this.deleteButton = new Button({
          name: 'Delete draft',
          iconURL: 'icones_cancel.png',
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
          R.tools.eraser.btn.show();
        } else {
          this.redoBtn.hide();
          this.undoBtn.hide();
          this.submitButton.hide();
          this.deleteButton.hide();
          R.tools.eraser.btn.hide();
        }
        if (draft == null) {
          draft = R.Drawing.getDraft();
        }
        if ((draft == null) || (draft.paths == null) || draft.paths.length === 0 || R.drawingPanel.visible) {
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
