// Generated by CoffeeScript 1.10.0
(function() {
  var dependencies;

  dependencies = ['R', 'Utils/Utils', 'Tools/Tool', 'UI/Button', 'Tools/MoveTool', 'Tools/SelectTool', 'Tools/PathTool', 'Tools/EraserTool', 'Tools/ColorTool', 'Tools/MoveDrawingTool', 'Tools/ItemTool', 'Tools/Tracer', 'Tools/ChooseTool', 'Tools/DiscussTool', 'UI/Modal', 'i18next'];

  define('Tools/ToolManager', dependencies, function(R, Utils, Tool, Button, MoveTool, SelectTool, PathTool, EraserTool, ColorTool, MoveDrawingTool, ItemTool, Tracer, ChooseTool, DiscussTool, Modal, i18next) {
    var ToolManager;
    ToolManager = (function() {
      ToolManager.minZoomPow = -7;

      ToolManager.maxZoomPow = 2;

      ToolManager.minZoom = Math.pow(2, ToolManager.minZoomPow);

      ToolManager.maxZoom = Math.pow(2, ToolManager.maxZoomPow);

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
        this.createColorButtons();
        R.tools.eraser = new R.Tools.Eraser();
        R.tools.eraser.btn.hide();
        R.tools.colorTool = new R.Tools.ColorTool();
        R.tools.colorTool.btn.hide();
        R.tools.moveDrawing = new R.Tools.MoveDrawing();
        R.tools.moveDrawing.btn.hide();
        R.tracer = new Tracer();
        defaultFavoriteTools = [];
        while (R.favoriteTools.length < 8 && defaultFavoriteTools.length > 0) {
          Utils.Array.pushIfAbsent(R.favoriteTools, defaultFavoriteTools.pop().label);
        }
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
        R.tools.choose = new R.Tools.Choose();
        R.tools.discuss = new R.Tools.Discuss();
        this.createInfoButton();
        R.tools.move.select();
        return;
      }

      ToolManager.prototype.clampZoom = function(zoom) {
        return Math.max(this.constructor.minZoom, Math.min(this.constructor.maxZoom, zoom));
      };

      ToolManager.prototype.zoom = function(value, snap) {
        var bounds, ref, zoomPow;
        if (snap == null) {
          snap = true;
        }
        zoomPow = Math.floor(Math.log(P.view.zoom) / Math.log(2));
        zoomPow += value;
        if (snap) {
          if (value < 0 && zoomPow < this.constructor.minZoomPow || value > 0 && zoomPow > this.constructor.maxZoomPow) {
            return;
          }
        } else if (P.view.zoom * value < this.constructor.minZoom || P.view.zoom * value > this.constructor.maxZoom) {
          return;
        }
        bounds = R.view.getViewBounds(true);
        if (value < 1 && bounds.contains(R.view.grid.limitCD.bounds)) {
          return;
        }
        if (value < 1 && bounds.contains(R.view.grid.limitCD.bounds.scale(snap ? Math.pow(value, 2) : value))) {
          R.view.fitRectangle(R.view.grid.limitCD.bounds.expand(200), true);
          return;
        }
        if (snap) {
          P.view.zoom = Math.pow(2, zoomPow);
        } else {
          P.view.zoom *= value;
        }
        if ((ref = R.tracer) != null) {
          ref.update();
        }
        if (zoomPow < -3) {
          R.tools.choose.hideOddLines();
        } else {
          R.tools.choose.showOddLines();
        }
        R.view.moveBy(new P.Point());
      };

      ToolManager.prototype.createZoombuttons = function() {
        this.zoomInBtn = new Button({
          name: 'Zoom +',
          iconURL: 'new 1/Zoom in.svg',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: 1
        });
        this.zoomInBtn.btnJ.click((function(_this) {
          return function() {
            return _this.zoom(1);
          };
        })(this));
        this.zoomOutBtn = new Button({
          name: 'Zoom -',
          iconURL: 'new 1/Zoom out.svg',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: 2
        });
        this.zoomOutBtn.btnJ.click((function(_this) {
          return function() {
            return _this.zoom(-1);
          };
        })(this));
      };

      ToolManager.prototype.createUndoRedoButtons = function() {
        this.undoBtn = new Button({
          name: 'Undo',
          classes: 'dark',
          iconURL: 'new 1/Undo.svg',
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
          classes: 'dark',
          iconURL: 'new 1/Redo.svg',
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

      ToolManager.prototype.createColorButtons = function() {
        var black, blue, brown, closeColorMenu, green, red, yellow;
        red = '#F44336';
        blue = '#448AFF';
        green = '#8BC34A';
        yellow = '#FFC107';
        brown = '#795548';
        black = '#000000';
        this.colors = [red, blue, green, yellow, brown, black];
        R.selectedColor = green;
        this.colorBtn = new Button({
          name: 'Colors',
          classes: 'dark',
          iconSVG: '<svg xmlns="http://www.w3.org/2000/svg" width="43" height="43" viewBox="0 0 43 43" fill="none"> <path class="color" d="M16.7717 20.6433L20.7256 15.5101L23.1807 19.4662L26.4506 24.9596L27.2354 29.8644L25.9928 34.1807L23.7693 36.2734L19.5839 36.6658L16.2789 35.3517L14.352 32.4803V26.7907L16.7717 20.6433Z" fill="#448AFF"/> <path class="color" d="M10.3885 8.25538L12.7428 5.63947L13.8995 7.01282L15.5423 10.8273L16.0232 13.8324L15.2619 16.477L13.8995 17.7592L10.8463 18.6536L9.27675 17.7592L8.12955 15.4352L8.62277 12.1792L10.3885 8.25538Z" fill="#448AFF"/> <path class="color" d="M29.9832 12.6312L32.0347 10.0308L33.0426 11.396L34.4742 15.1879L34.8932 18.1753L34.2298 20.8042L33.0426 22.0788L30.3821 22.9679L29.0144 22.0788L28.0147 19.7685L28.4445 16.5318L29.9832 12.6312Z" fill="#448AFF"/> <path d="M20.603 37.6934H20.5141C19.5791 37.721 18.6483 37.5588 17.7777 37.2168C16.9072 36.8747 16.1149 36.3599 15.4488 35.7032C14.2397 34.4471 13.5235 32.6294 13.3209 30.3007C13.1582 28.3694 13.3882 26.4252 13.9971 24.5853C14.5988 22.9527 15.3956 21.3989 16.3703 19.9576C17.1053 18.8787 17.9088 17.8481 18.7759 16.8722C19.2495 16.3132 19.6965 15.7858 20.0529 15.3268C20.1168 15.2429 20.2 15.1757 20.2955 15.1308C20.3909 15.086 20.4958 15.0648 20.6012 15.0691C20.7064 15.0724 20.8094 15.1006 20.9016 15.1515C20.9937 15.2024 21.0725 15.2745 21.1313 15.3619L21.6849 16.1795C22.6415 17.5898 23.6297 19.0489 24.5602 20.5166C25.6616 22.14 26.5829 23.8787 27.3074 25.7019C27.9169 27.3635 28.1713 29.1345 28.0544 30.9005C28.0217 31.8261 27.8055 32.7361 27.4184 33.5776C27.0314 34.419 26.481 35.1752 25.7994 35.8023C24.3471 37.0302 22.5048 37.7007 20.603 37.6934ZM20.5328 16.8566C20.2995 17.1383 20.0502 17.4342 19.7934 17.7359C18.9673 18.6641 18.2008 19.6436 17.4984 20.6685C16.5828 22.0192 15.8319 23.4745 15.2617 25.0034C14.7098 26.6713 14.5011 28.4336 14.6481 30.1842C14.8258 32.2019 15.4163 33.7478 16.4085 34.7786C16.9561 35.3022 17.6023 35.7117 18.3096 35.9831C19.0168 36.2546 19.7711 36.3827 20.5283 36.36C22.1442 36.3954 23.7164 35.8342 24.9445 34.7835C26.0346 33.7473 26.6737 32.3241 26.724 30.821C26.8292 29.2371 26.601 27.6488 26.054 26.1586C25.3606 24.4273 24.4824 22.7758 23.4347 21.2328C22.5154 19.7821 21.5325 18.3322 20.5816 16.9295L20.5328 16.8566Z" fill="white"/> <path d="M11.2103 19.5341C10.7702 19.5338 10.3328 19.4651 9.91377 19.3306C9.33791 19.1298 8.82855 18.7741 8.44163 18.3027C8.05472 17.8313 7.80523 17.2624 7.72056 16.6584C7.50129 15.4574 7.56119 14.222 7.89563 13.0478C8.14548 12.0113 8.49471 11.0012 8.93847 10.0317C9.89438 8.15852 11.0409 6.38888 12.3598 4.75087C12.4231 4.66772 12.5054 4.60094 12.5997 4.55611C12.6941 4.51127 12.7979 4.48969 12.9023 4.49316C13.0066 4.49572 13.1087 4.52271 13.2006 4.57194C13.2926 4.62118 13.3716 4.69129 13.4315 4.77664C14.7943 6.71569 16.4627 9.62426 16.6751 12.4684C16.8782 15.2032 15.6132 17.7395 13.4533 18.9289C12.7693 19.3182 11.9973 19.5265 11.2103 19.5341ZM12.8543 6.30113C11.8149 7.65188 10.9043 9.09709 10.1346 10.6178C9.72972 11.5107 9.41088 12.4401 9.1824 13.3935C8.90097 14.3717 8.84822 15.4015 9.02822 16.4034C9.07406 16.77 9.21795 17.1175 9.44473 17.4091C9.67151 17.7008 9.97277 17.9259 10.3168 18.0607C10.7302 18.1865 11.1653 18.2249 11.5944 18.1734C12.0234 18.1219 12.4371 17.9817 12.809 17.7617C14.5139 16.8228 15.5087 14.7847 15.3443 12.5675C15.1826 10.3618 13.994 8.05134 12.8552 6.30113H12.8543Z" fill="white"/> <path d="M30.5924 23.8139C30.5035 23.8139 30.4146 23.8108 30.3258 23.8033C29.6813 23.7576 29.0686 23.5062 28.5777 23.0862C28.0868 22.6662 27.7437 22.0997 27.5989 21.4701C26.9262 19.1151 27.6833 16.8313 28.3512 14.8172C28.9935 12.9817 29.8823 11.2421 30.9931 9.64606C31.0476 9.56471 31.1194 9.49635 31.2032 9.44586C31.2871 9.39537 31.3811 9.36398 31.4785 9.35393C31.5759 9.34387 31.6743 9.3554 31.7668 9.38769C31.8592 9.41998 31.9434 9.47224 32.0133 9.54076C34.219 11.7011 35.404 13.7054 35.7421 15.8502C36.1807 18.6237 35.3636 21.0933 33.4974 22.6213C32.6962 23.3431 31.6695 23.7646 30.5924 23.8139ZM31.6539 11.075C30.807 12.3737 30.1225 13.7713 29.6157 15.2366C28.9786 17.1574 28.3201 19.1436 28.8799 21.1044C28.9549 21.4708 29.1473 21.8028 29.4279 22.0501C29.7085 22.2974 30.0621 22.4465 30.4351 22.4747C31.2589 22.4671 32.0501 22.1515 32.6532 21.5901C34.1425 20.369 34.789 18.3518 34.426 16.0551C34.1639 14.3946 33.2774 12.7977 31.6539 11.075Z" fill="white"/> </svg>',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: null
        });
        this.colorBtn.hide();
        closeColorMenu = function() {
          $('#color-picker').remove();
        };
        this.colorBtn.cloneJ.find('.glyphicon').css({
          color: R.selectedColor
        });
        this.colorBtn.btnJ.click((function(_this) {
          return function() {
            var color, height, i, len, liJ, position, ref, ulJ;
            position = _this.colorBtn.cloneJ.offset();
            height = _this.colorBtn.cloneJ.outerHeight();
            ulJ = $('<ul>').attr('id', 'color-picker').css({
              position: 'fixed',
              top: position.top + height,
              left: position.left
            });
            ref = _this.colors;
            for (i = 0, len = ref.length; i < len; i++) {
              color = ref[i];
              liJ = $('<li>').attr('data-color', color).css({
                background: color,
                width: 50,
                height: 50,
                cursor: 'pointer'
              }).mousedown(function(event) {
                color = $(event.target).attr('data-color');
                R.selectedColor = color;
                if (R.selectedTool !== R.tools["Precise path"] && R.selectedTool !== R.tools.colorTool) {
                  R.tools["Precise path"].select();
                }
                _this.colorBtn.cloneJ.find('path.color').attr({
                  fill: R.selectedColor
                });
              });
              ulJ.append(liJ);
            }
            _this.colorBtn.cloneJ.parent().append(ulJ);
          };
        })(this));
        $(window).mouseup(closeColorMenu);
      };

      ToolManager.prototype.createInfoButton = function() {
        this.infoBtn = new Button({
          name: 'Help',
          iconURL: 'new 1/Info.svg',
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
          iconURL: 'new 1/Check.svg',
          classes: 'btn-success displayName',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              var ref;
              if (R.city.mode === 'ExquisiteCorpse' && !R.view.exquisiteCorpseMask.isDraftOnBounds()) {
                R.alertManager.alert('Your path must fit in a single of your tiles', 'error');
                return;
              }
              if ((ref = R.tracer) != null) {
                ref.hide();
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
          iconURL: 'new 1/Cross.svg',
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

      ToolManager.prototype.createChangeImageButton = function() {
        this.changeImageButton = new Button({
          name: 'Change image',
          iconURL: 'new 1/Image.svg',
          classes: 'btn-info displayName',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              var ref;
              if ((ref = R.tracer) != null) {
                ref.openImageModal(false, true);
              }
            };
          })(this)
        });
        this.changeImageButton.hide();
      };

      ToolManager.prototype.createAutoTraceButton = function() {
        this.autoTraceButton = new Button({
          name: 'Trace automatically',
          iconURL: 'new 1/Lightning bolt 1.svg',
          classes: 'btn-warning displayName',
          parentJ: $('#submit-drawing-button'),
          ignoreFavorite: true,
          onClick: (function(_this) {
            return function() {
              var ref;
              if ((ref = R.tracer) != null) {
                ref.autoTrace();
              }
            };
          })(this)
        });
        this.autoTraceButton.hide();
      };

      ToolManager.prototype.showTracerButtons = function() {
        if (R.tracer.isVisible()) {
          this.changeImageButton.show();
          this.autoTraceButton.show();
        }
      };

      ToolManager.prototype.hideTracerButtons = function() {
        this.changeImageButton.hide();
        this.autoTraceButton.hide();
      };

      ToolManager.prototype.updateButtonsVisibility = function(draft) {
        var ref, ref1, ref2, ref3, ref4;
        if (draft == null) {
          draft = null;
        }
        if ((ref = R.view.exquisiteCorpseMask) != null) {
          ref.resetTilesHighlight();
        }
        if (R.selectedTool === R.tools['Precise path'] || R.selectedTool === R.tools.eraser || R.selectedTool === R.tools.moveDrawing || R.selectedTool === R.tools.colorTool) {
          if ((ref1 = this.colorBtn) != null) {
            ref1.show();
          }
          this.redoBtn.show();
          this.undoBtn.show();
          this.submitButton.show();
          this.deleteButton.show();
          if ((ref2 = R.tracer) != null) {
            ref2.showButton();
          }
          R.tools.eraser.btn.show();
          R.tools.colorTool.btn.show();
          R.tools.moveDrawing.btn.show();
        } else {
          if ((ref3 = this.colorBtn) != null) {
            ref3.hide();
          }
          this.redoBtn.hide();
          this.undoBtn.hide();
          this.submitButton.hide();
          this.deleteButton.hide();
          if ((ref4 = R.tracer) != null) {
            ref4.hideButton();
          }
          R.tools.eraser.btn.hide();
          R.tools.colorTool.btn.hide();
          R.tools.moveDrawing.btn.hide();
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
        if (R.selectedTool !== R.tools['Precise path']) {
          R.tools['Precise path'].select();
        }
      };

      ToolManager.prototype.leaveDrawingMode = function(selectTool) {
        if (selectTool == null) {
          selectTool = false;
        }
        if (selectTool) {
          R.tools.select.select(false, true, true);
        }
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
