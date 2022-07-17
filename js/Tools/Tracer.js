// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils', 'UI/Button', 'UI/Modal', 'Tools/Vectorizer', 'Tools/ImageProcessor', 'Tools/Camera', 'Tools/PathTool', 'Commands/Command', 'i18next', 'cropper'], function(P, R, Utils, Button, Modal, Vectorizer, ImageProcessor, Camera, PathTool, Command, i18next, Cropper) {
    var Tracer;
    Tracer = (function() {
      Tracer.handleColor = '#42b3f4';

      Tracer.maxRasterSize = 3 * R.Tools.Path.maxDraftSize;

      function Tracer() {
        this.handleFiles = bind(this.handleFiles, this);
        this.fileDropped = bind(this.fileDropped, this);
        this.autoTraceCallback = bind(this.autoTraceCallback, this);
        this.autoTraceSized = bind(this.autoTraceSized, this);
        this.autoTrace = bind(this.autoTrace, this);
        this.appendSVG = bind(this.appendSVG, this);
        this.createRasterController = bind(this.createRasterController, this);
        this.filterImage = bind(this.filterImage, this);
        this.ignoreCropImage = bind(this.ignoreCropImage, this);
        this.cropImage = bind(this.cropImage, this);
        this.setEditImageMode = bind(this.setEditImageMode, this);
        this.createImagePreview = bind(this.createImagePreview, this);
        this.addRasterCropControls = bind(this.addRasterCropControls, this);
        this.rasterOnError = bind(this.rasterOnError, this);
        this.drawHandles = bind(this.drawHandles, this);
        this.drawCorners = bind(this.drawCorners, this);
        this.drawMoves = bind(this.drawMoves, this);
        this.removeRaster = bind(this.removeRaster, this);
        this.updateImageURLfromInputDeferred = bind(this.updateImageURLfromInputDeferred, this);
        this.updateImageURLfromInput = bind(this.updateImageURLfromInput, this);
        this.openImageModal = bind(this.openImageModal, this);
        this.onModalSubmit = bind(this.onModalSubmit, this);
        this.restoreImageOrOpenModal = bind(this.restoreImageOrOpenModal, this);
        this.onDragOver = bind(this.onDragOver, this);
        this.onDragEnter = bind(this.onDragEnter, this);
        this.tracerGroup = null;
        this.tracerBtn = null;
        this.vectorizer = new Vectorizer();
        this.createTracerButton();
        this.initializeGlobalDragAndDrop();
        this.imageProcessor = new ImageProcessor();
        return;
      }

      Tracer.prototype.onDragEnter = function() {
        event.stopPropagation();
        event.preventDefault();
      };

      Tracer.prototype.onDragOver = function() {
        event.stopPropagation();
        event.preventDefault();
      };

      Tracer.prototype.initializeGlobalDragAndDrop = function() {
        document.body.addEventListener('dragenter', (function(_this) {
          return function(event) {
            event.stopPropagation();
            event.preventDefault();
            event.dataTransfer.effectAllowed = "move";
            console.log('dragenter');
            R.alertManager.alert('Drop your image here to trace it', 'info');
          };
        })(this));
        document.body.addEventListener('dragover', (function(_this) {
          return function(event) {
            event.stopPropagation();
            event.preventDefault();
          };
        })(this));
        document.body.addEventListener('dragleave', (function(_this) {
          return function(event) {
            event.stopPropagation();
            event.preventDefault();
            console.log('dragleave');
          };
        })(this));
        document.body.addEventListener('drop', this.fileDropped, false);
      };

      Tracer.prototype.createTracerButton = function() {
        this.tracerBtn = new Button({
          name: 'Trace',
          iconURL: 'new 1/Image.svg',
          classes: 'dark',
          favorite: true,
          category: null,
          disableHover: true,
          popover: true,
          order: null
        });
        this.tracerBtn.hide();
        this.tracerBtn.btnJ.click(this.restoreImageOrOpenModal);
      };

      Tracer.prototype.restoreImageOrOpenModal = function() {
        var closedRaster, rasterBounds, rasterBoundsJSON, ref;
        if ((ref = this.tracerGroup) != null ? ref.visible : void 0) {
          this.openImageModal(false, true);
          return;
        }
        this.imageURL = localStorage.getItem('rater-url');
        closedRaster = localStorage.getItem('closed-raster') === 'true';
        if (!closedRaster && (this.imageURL != null) && this.imageURL !== '') {
          rasterBoundsJSON = localStorage.getItem('rater-bounds');
          if (rasterBoundsJSON != null) {
            rasterBounds = JSON.parse(rasterBoundsJSON);
            this.createRasterController(new P.Rectangle(rasterBounds));
          } else {
            this.openImageModal(closedRaster);
          }
        } else {
          this.openImageModal(closedRaster);
        }
      };

      Tracer.prototype.onModalSubmit = function() {
        this.createRasterController();
      };

      Tracer.prototype.openImageModal = function(closedRaster, keepRaster) {
        var elemJ, inputJ, j, len, marginContainerJ, ref;
        if (keepRaster == null) {
          keepRaster = false;
        }
        if (!keepRaster) {
          this.removeRaster();
        }
        this.imageFile = null;
        this.imageURL = null;
        this.modal = Modal.createModal({
          id: 'import-image',
          title: "Import image to trace",
          submit: this.onModalSubmit,
          submitButtonText: 'Trace'
        });
        inputJ = $('<input type="file" multiple accept="image/*">');
        this.modal.addCustomContent({
          name: 'tracerFileInput',
          divJ: inputJ
        });
        inputJ.css({
          margin: 'auto'
        });
        inputJ.get(0).addEventListener('change', this.handleFiles, false);
        inputJ.hide();
        this.photoFromCameraButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'success',
          name: 'Take a photo with the camera',
          icon: 'glyphicon-facetime-video'
        });
        this.photoFromCameraButtonJ.click(Camera.initialize);
        this.imageFromComputerButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'warning',
          name: 'Select an image on your computer',
          icon: 'glyphicon-folder-open'
        });
        this.imageFromComputerButtonJ.click((function(_this) {
          return function() {
            inputJ.click();
          };
        })(this));
        this.imageFromURLButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'info',
          name: 'Import image from URL',
          icon: 'glyphicon-link'
        });
        if (closedRaster) {
          this.reloadPreviousImageButtonJ = this.modal.addButton({
            addToBody: true,
            type: 'primary',
            name: 'Reload previous image',
            icon: 'glyphicon-picture'
          });
          this.reloadPreviousImageButtonJ.click((function(_this) {
            return function() {
              localStorage.setItem('closed-raster', 'false');
              _this.restoreImageOrOpenModal();
            };
          })(this));
        }
        this.dragDropTextJ = this.modal.addText('or drop and image on this page', 'or drop and image on this page');
        this.dragDropTextJ.css({
          'text-align': 'center'
        });
        ref = [this.photoFromCameraButtonJ, this.imageFromComputerButtonJ, this.imageFromURLButtonJ, this.reloadPreviousImageButtonJ];
        for (j = 0, len = ref.length; j < len; j++) {
          elemJ = ref[j];
          if (elemJ == null) {
            continue;
          }
          elemJ.css({
            'margin-bottom': '10px',
            'font-size': 'large'
          }).find('.glyphicon').css({
            'padding-right': '10px'
          });
          elemJ.addClass('btn-lg');
        }
        this.urlInputJ = this.modal.addTextInput({
          name: 'imageURL',
          placeholder: 'http://exemple.fr/belle-image.png',
          type: 'url',
          submitShortcut: true,
          label: 'Import image from URL',
          required: true,
          errorMessage: i18next.t('The URL is invalid')
        });
        this.urlInputJ.hide();
        this.imageFromURLButtonJ.click((function(_this) {
          return function() {
            var ref1;
            _this.urlInputJ.show();
            _this.photoFromCameraButtonJ.hide();
            _this.imageFromComputerButtonJ.hide();
            _this.imageFromURLButtonJ.hide();
            if ((ref1 = _this.reloadPreviousImageButtonJ) != null) {
              ref1.hide();
            }
            _this.dragDropTextJ.hide();
            _this.modal.modalJ.find(".modal-footer").show();
          };
        })(this));
        this.urlInputJ.find('input').change(this.updateImageURLfromInputDeferred).bind("paste", this.updateImageURLfromInputDeferred).keyup(this.updateImageURLfromInputDeferred);
        this.imageContainerJ = this.modal.addCustomContent({
          divJ: $('<div id="processed-image">')
        });
        marginContainerJ = $('<div class="margin-container">');
        marginContainerJ.css({
          'max-width': '100%',
          'max-height': '100%',
          'display': 'flex',
          'flex': 'auto',
          'min-height': '0px'
        });
        this.imageContainerJ.append(marginContainerJ);
        this.ignoreCropButtonJ = this.modal.addButton({
          type: 'info',
          name: 'Use full size image'
        });
        this.cropButtonJ = this.modal.addButton({
          type: 'success',
          name: 'Crop image'
        });
        this.cropButtonJ.click(this.cropImage);
        this.ignoreCropButtonJ.click(this.ignoreCropImage);
        this.cropButtonJ.hide();
        this.ignoreCropButtonJ.hide();
        this.modal.modalBodyJ.css({
          'display': 'flex',
          'flex-direction': 'column'
        });
        this.modal.show();
        this.modal.modalJ.find(".modal-footer").hide();
      };

      Tracer.prototype.updateImageURLfromInput = function() {
        this.imageURL = this.urlInputJ.find('input').val();
        console.log(this.imageURL);
        this.createImagePreview();
      };

      Tracer.prototype.updateImageURLfromInputDeferred = function() {
        Utils.deferredExecution(this.updateImageURLfromInput, 'updateImageURLfromInput', 200);
      };

      Tracer.prototype.removeRaster = function() {
        var ref, ref1, ref2;
        if (this.moves != null) {
          this.moves.remove();
        }
        if (this.corners != null) {
          this.corners.remove();
        }
        if ((ref = this.raster) != null) {
          ref.remove();
        }
        if ((ref1 = this.tracerGroup) != null) {
          ref1.remove();
        }
        if ((ref2 = R.toolManager) != null) {
          ref2.hideTracerButtons();
        }
      };

      Tracer.prototype.saveBoundsToLocalStorage = function() {
        localStorage.setItem('rater-bounds', JSON.stringify(this.raster.bounds.toJSON()));
      };

      Tracer.prototype.drawMoves = function(bounds, size, sign, signRotations, signOffsets) {
        var arrow, base, handle, handlePath, handlePos, handleSize, j, len, pos, ref;
        if (this.moves != null) {
          this.moves.remove();
        }
        this.moves = new P.Group();
        this.tracerGroup.addChild(this.moves);
        ref = ['topCenter', 'rightCenter', 'bottomCenter', 'leftCenter'];
        for (j = 0, len = ref.length; j < len; j++) {
          pos = ref[j];
          handle = new P.Group();
          handle.name = 'handle-move-' + pos;
          handleSize = size.clone();
          if (pos === 'topCenter' || pos === 'bottomCenter') {
            handleSize.width = bounds.width - size.width;
          } else {
            handleSize.height = bounds.height - size.height;
          }
          handlePos = bounds[pos].subtract(handleSize.divide(2));
          handlePath = new P.Path.Rectangle(handlePos, handleSize);
          handlePath.fillColor = this.constructor.handleColor;
          handlePath.strokeColor = 'white';
          handlePath.strokeWidth = 1;
          handlePath.strokeScaling = false;
          handlePath.opacity = 0.5;
          handle.addChild(handlePath);
          arrow = sign.clone();
          arrow.position = bounds[pos].add(signOffsets[pos]);
          arrow.rotation = signRotations[pos];
          handle.addChild(arrow);
          if ((base = this.raster).data == null) {
            base.data = {};
          }
          this.raster.data[pos] = handle;
          handle.applyMatrix = false;
          handle.on('mousedown', (function(_this) {
            return function(event) {
              _this.draggingImage = true;
            };
          })(this));
          handle.on('mousedrag', (function(_this) {
            return function(event) {
              if (!_this.draggingImage) {
                return;
              }
              if (!_this.scalingImage) {
                _this.tracerGroup.position = _this.tracerGroup.position.add(event.delta);
                _this.saveBoundsToLocalStorage();
                _this.draggingImage = true;
              }
            };
          })(this));
          handle.on('mouseup', (function(_this) {
            return function(event) {
              _this.draggingImage = false;
            };
          })(this));
          handle.on('mouseenter', (function(_this) {
            return function(event) {
              var ref1;
              if (!((ref1 = R.selectedTool) != null ? ref1.using : void 0)) {
                R.stageJ.css('cursor', 'move');
              }
            };
          })(this));
          handle.on('mouseleave', (function(_this) {
            return function(event) {
              var ref1;
              if ((ref1 = R.selectedTool) != null) {
                ref1.updateCursor();
              }
            };
          })(this));
          this.moves.addChild(handle);
        }
      };

      Tracer.prototype.drawCorners = function(bounds, size, sign, signRotations, signOffsets) {
        var arrow, base, box, cross1, cross2, handle, handlePath, handlePos, j, len, pos, ref;
        if (this.corners != null) {
          this.corners.remove();
        }
        this.corners = new P.Group();
        this.tracerGroup.addChild(this.corners);
        ref = ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'];
        for (j = 0, len = ref.length; j < len; j++) {
          pos = ref[j];
          handle = new P.Group();
          handle.name = 'handle-corner-' + pos;
          handlePos = bounds[pos].subtract(size.divide(2));
          handlePath = new P.Path.Rectangle(handlePos, size);
          handlePath.fillColor = this.constructor.handleColor;
          handlePath.strokeColor = 'white';
          handlePath.strokeWidth = 1;
          handlePath.strokeScaling = false;
          handlePath.opacity = 0.5;
          handle.addChild(handlePath);
          box = handlePath.bounds.expand(-15 / P.view.zoom);
          if ((base = this.raster).data == null) {
            base.data = {};
          }
          this.raster.data[pos] = handle;
          if (pos === 'topRight') {
            cross1 = new P.Path();
            cross1.add(box.topLeft);
            cross1.add(box.bottomRight);
            cross1.strokeWidth = 2;
            cross1.strokeScaling = false;
            cross1.strokeColor = 'black';
            handle.addChild(cross1);
            cross2 = new P.Path();
            cross2.add(box.topRight);
            cross2.add(box.bottomLeft);
            cross2.strokeWidth = 2;
            cross2.strokeScaling = false;
            cross2.strokeColor = 'black';
            handle.addChild(cross2);
            handle.on('mousedown', (function(_this) {
              return function() {
                _this.draggingImage = true;
                _this.removeRaster();
                localStorage.setItem('closed-raster', 'true');
              };
            })(this));
            handle.on('mouseenter', (function(_this) {
              return function(event) {
                var ref1;
                if (!((ref1 = R.selectedTool) != null ? ref1.using : void 0)) {
                  R.stageJ.css('cursor', 'pointer');
                }
              };
            })(this));
            handle.on('mouseleave', (function(_this) {
              return function(event) {
                var ref1;
                if ((ref1 = R.selectedTool) != null) {
                  ref1.updateCursor();
                }
              };
            })(this));
          } else {
            arrow = sign.clone();
            arrow.position = bounds[pos];
            arrow.rotation = signRotations[pos];
            handle.addChild(arrow);
            handle.on('mousedown', (function(_this) {
              return function(event) {
                _this.draggingImage = true;
                _this.scalingImage = true;
              };
            })(this));
            handle.on('mousedrag', (function(_this) {
              return function(event) {
                var center, i, k, len1, newLength, previousLength, ref1;
                if (!_this.draggingImage) {
                  return;
                }
                center = bounds.center;
                previousLength = event.point.subtract(event.delta).getDistance(center);
                newLength = event.point.getDistance(center);
                bounds = _this.raster.bounds.expand(size);
                _this.drawMoves(bounds, size, sign, signRotations, signOffsets);
                _this.raster.scaling = _this.raster.scaling.multiply(newLength / previousLength);
                ref1 = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'];
                for (i = k = 0, len1 = ref1.length; k < len1; i = ++k) {
                  pos = ref1[i];
                  _this.raster.data[pos].position = bounds[pos];
                }
                _this.corners.bringToFront();
                if (_this.rasterParts != null) {
                  _this.createRasterParts();
                }
                _this.saveBoundsToLocalStorage();
              };
            })(this));
            handle.on('mouseup', (function(_this) {
              return function(event) {
                _this.draggingImage = false;
                _this.scalingImage = false;
              };
            })(this));
            handle.on('mouseenter', (function(_this) {
              return function(event) {
                var ref1, vector;
                if (!((ref1 = R.selectedTool) != null ? ref1.using : void 0)) {
                  vector = bounds.center.subtract(event.point);
                  R.stageJ.css('cursor', vector.x > 0 && vector.y < 0 ? 'nesw-resize' : 'nwse-resize');
                }
              };
            })(this));
            handle.on('mouseleave', (function(_this) {
              return function(event) {
                var ref1;
                if ((ref1 = R.selectedTool) != null) {
                  ref1.updateCursor();
                }
              };
            })(this));
          }
          this.corners.addChild(handle);
        }
      };

      Tracer.prototype.drawHandles = function() {
        var bounds, sign, signOffsets, signRotations, size;
        if (this.tracerGroup == null) {
          return;
        }
        size = new paper.Size(30 / P.view.zoom, 30 / P.view.zoom);
        bounds = this.raster.bounds.expand(size);
        sign = new P.Path();
        sign.add(12 / P.view.zoom, 0);
        sign.add(0, 0);
        sign.add(0, 12 / P.view.zoom);
        sign.strokeWidth = 2;
        sign.strokeColor = 'black';
        sign.strokeScaling = false;
        sign.pivot = new paper.Point(6 / P.view.zoom, 6 / P.view.zoom);
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
          'topCenter': new paper.Point(0, 4 / P.view.zoom),
          'rightCenter': new paper.Point(-4 / P.view.zoom, 0),
          'bottomCenter': new paper.Point(0, -4 / P.view.zoom),
          'leftCenter': new paper.Point(4 / P.view.zoom, 0)
        };
        this.drawMoves(bounds, size, sign, signRotations, signOffsets);
        this.drawCorners(bounds, size, sign, signRotations, signOffsets);
      };

      Tracer.prototype.rasterOnLoad = function(bounds) {
        var ref, viewBounds;
        if (bounds == null) {
          bounds = null;
        }
        R.loader.hideLoadingBar();
        if (bounds != null) {
          this.raster.fitBounds(bounds);
        } else {
          viewBounds = R.view.getViewBounds();
          this.raster.position = viewBounds.center;
          if (this.raster.bounds.width > viewBounds.width) {
            this.raster.scaling = new paper.Point(viewBounds.width / (this.raster.bounds.width + this.raster.bounds.width * 0.25));
          }
          if (this.raster.bounds.height > viewBounds.height) {
            this.raster.scaling = this.raster.scaling.multiply(viewBounds.height / (this.raster.bounds.height + this.raster.bounds.height * 0.25));
          }
        }
        this.raster.applyMatrix = false;
        localStorage.setItem('rater-url', this.raster.source);
        this.saveBoundsToLocalStorage();
        this.drawHandles();
        if ((ref = R.toolManager) != null) {
          ref.showTracerButtons();
        }
      };

      Tracer.prototype.rasterOnError = function(event) {
        var ref;
        R.loader.hideLoadingBar();
        this.removeRaster();
        if ((ref = R.toolManager) != null) {
          ref.hideTracerButtons();
        }
        R.alertManager.alert('Could not load the image', 'error');
      };

      Tracer.prototype.setFullscreen = function() {
        this.modal.modalJ.find('.modal-dialog').css({
          position: 'absolute',
          top: '60px',
          bottom: 0,
          width: '100%'
        });
        this.modal.modalJ.find('.modal-content').css({
          display: 'flex',
          'flex-direction': 'column',
          height: '100%',
          overflow: 'auto'
        });
        this.modal.modalJ.find('.modal-body').css({
          display: 'flex',
          height: '100%',
          flex: '1 1 auto',
          'overflow-y': 'auto',
          'min-height': '0px'
        });
      };

      Tracer.prototype.addRasterCropControls = function() {
        this.rotateImageButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'info',
          name: 'Rotate',
          icon: 'glyphicon-repeat'
        });
        this.flipVImageButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'info',
          name: 'Flip Vertical',
          icon: 'glyphicon-resize-vertical'
        });
        this.flipHImageButtonJ = this.modal.addButton({
          addToBody: true,
          type: 'info',
          name: 'Flip Horizontal',
          icon: 'glyphicon-resize-horizontal'
        });
        this.rotateImageButtonJ.click((function(_this) {
          return function() {
            var ref;
            return (ref = _this.cropper) != null ? ref.rotate(90) : void 0;
          };
        })(this));
        this.flipVImageButtonJ.click((function(_this) {
          return function() {
            var ref;
            return (ref = _this.cropper) != null ? ref.scale(1, -1 * _this.cropper.getData().scaleY) : void 0;
          };
        })(this));
        this.flipHImageButtonJ.click((function(_this) {
          return function() {
            var ref;
            return (ref = _this.cropper) != null ? ref.scale(-1 * _this.cropper.getData().scaleX, 1) : void 0;
          };
        })(this));
      };

      Tracer.prototype.createImagePreview = function() {
        if (this.image == null) {
          this.image = new Image();
        }
        this.image.src = this.imageURL;
        this.imageContainerJ.css({
          'margin': 'auto',
          'max-height': '100%',
          'max-width': '100%',
          'flex': '1 1 auto',
          'overflow-y': 'auto',
          'min-height': '0px',
          'padding': '20px'
        });
        this.imageContainerJ.find('.margin-container').append(this.image);
      };

      Tracer.prototype.setEditImageMode = function() {
        var ref;
        this.modal.modalJ.find('.modal-footer button[name="submit"]').hide();
        this.setFullscreen();
        this.addRasterCropControls();
        this.photoFromCameraButtonJ.hide();
        this.imageFromComputerButtonJ.hide();
        this.imageFromURLButtonJ.hide();
        if ((ref = this.reloadPreviousImageButtonJ) != null) {
          ref.hide();
        }
        this.dragDropTextJ.hide();
        this.modal.modalJ.find(".modal-footer").show();
        this.onModalSubmit();
      };

      Tracer.prototype.cropImage = function(cropData) {
        var cropOptions;
        if (cropData == null) {
          cropData = null;
        }
        if (cropData) {
          this.cropper.setData(cropData);
        }
        cropOptions = {
          minWidth: 200,
          minHeight: 200,
          maxWidth: 750,
          maxHeight: 750,
          fillColor: '#fff',
          imageSmoothingEnabled: true,
          imageSmoothingQuality: 'high'
        };
        this.filterCanvas = this.cropper.getCroppedCanvas(cropOptions);
        this.filterImage();
      };

      Tracer.prototype.ignoreCropImage = function() {
        var imageData;
        imageData = this.cropper.getCanvasData();
        this.cropper.setCropBoxData({
          left: imageData.left,
          top: imageData.top,
          width: imageData.width,
          height: imageData.height
        });
        this.cropImage();
        this.filterImage();
      };

      Tracer.prototype.filterImage = function() {
        this.cropper.destroy();
        this.imageContainerJ.empty();
        this.imageContainerJ.append(this.filterCanvas);
        $(this.filterCanvas).css({
          'max-width': '500px'
        });
        this.cropButtonJ.hide();
        this.ignoreCropButtonJ.hide();
        this.rotateImageButtonJ.hide();
        this.flipVImageButtonJ.hide();
        this.flipHImageButtonJ.hide();
        this.modal.modalJ.find('.modal-footer button[name="submit"]').show();
        this.imageProcessor.processImage(this.filterCanvas);
        this.onModalSubmit();
      };

      Tracer.prototype.createRasterController = function(bounds) {
        var ref;
        if (bounds == null) {
          bounds = null;
        }
        if ((ref = this.modal) != null) {
          ref.hide();
        }
        if (this.imageURL == null) {
          return;
        }
        this.imageFile = null;
        this.removeRaster();
        this.tracerGroup = new P.Group();
        this.raster = new P.Raster(this.imageURL);
        this.raster.opacity = 0.5;
        this.tracerGroup.addChild(this.raster);
        if (bounds != null) {
          this.raster.position = bounds.center;
        } else {
          this.raster.position = R.view.getViewBounds().center;
        }
        R.loader.showLoadingBar();
        R.view.selectionLayer.addChild(this.tracerGroup);
        this.raster.onError = this.rasterOnError;
        this.raster.onLoad = (function(_this) {
          return function() {
            return _this.rasterOnLoad(bounds);
          };
        })(this);
      };

      Tracer.prototype.appendSVG = function(svgstr) {
        var svgContainer;
        svgContainer = this.svgContainerJ.get(0);
        svgContainer.style.display = 'inline-block';
        svgContainer.innerHTML = svgstr;
      };

      Tracer.prototype.createRasterParts = function() {
        var j, k, maxDraftSize, nRectanglesHeight, nRectanglesWidth, nx, ny, rectangle, rectanglePath, ref, ref1, ref2, totalRectangle;
        maxDraftSize = R.Tools.Path.maxDraftSize;
        nRectanglesWidth = Math.floor(this.raster.bounds.width / maxDraftSize) + 1;
        nRectanglesHeight = Math.floor(this.raster.bounds.height / maxDraftSize) + 1;
        totalRectangle = new P.Rectangle(this.raster.bounds.left, this.raster.bounds.top, nRectanglesWidth * maxDraftSize, nRectanglesHeight * maxDraftSize);
        totalRectangle.center = this.raster.bounds.center;
        if ((ref = this.rasterParts) != null) {
          ref.remove();
        }
        this.rasterParts = new P.Group();
        for (nx = j = 0, ref1 = nRectanglesWidth - 1; 0 <= ref1 ? j <= ref1 : j >= ref1; nx = 0 <= ref1 ? ++j : --j) {
          for (ny = k = 0, ref2 = nRectanglesHeight - 1; 0 <= ref2 ? k <= ref2 : k >= ref2; ny = 0 <= ref2 ? ++k : --k) {
            rectangle = new P.Rectangle(totalRectangle.left + nx * maxDraftSize, totalRectangle.top + ny * maxDraftSize, maxDraftSize, maxDraftSize);
            rectangle = this.raster.bounds.intersect(rectangle);
            rectanglePath = P.Path.Rectangle(rectangle);
            rectanglePath.fillColor = this.constructor.handleColor;
            rectanglePath.strokeColor = 'white';
            rectanglePath.opacity = 0.8;
            rectanglePath.on('mouseenter', (function(_this) {
              return function(event) {
                event.target.opacity = 0.05;
                R.stageJ.css('cursor', 'pointer');
              };
            })(this));
            rectanglePath.on('mouseleave', (function(_this) {
              return function(event) {
                var ref3;
                if ((ref3 = R.selectedTool) != null) {
                  ref3.updateCursor();
                }
                event.target.opacity = 0.8;
              };
            })(this));
            rectanglePath.on('mousedown', (function(_this) {
              return function(event) {
                _this.draggingImage = true;
              };
            })(this));
            rectanglePath.on('click', (function(_this) {
              return function(event) {
                _this.autoTraceSized(event.target.bounds);
                _this.rasterParts.remove();
                _this.draggingImage = false;
              };
            })(this));
            this.rasterParts.addChild(rectanglePath);
          }
        }
        this.tracerGroup.addChild(this.rasterParts);
      };

      Tracer.prototype.autoTrace = function() {
        if (this.raster.bounds.width > R.Tools.Path.maxDraftSize || this.raster.bounds.height > R.Tools.Path.maxDraftSize) {
          R.alertManager.alert('The image is too big to fit in one drawing', 'info');
          this.createRasterParts();
          return;
        }
        this.autoTraceSized();
      };

      Tracer.prototype.autoTraceSized = function(bounds) {
        var args, c, color, colors, err, error, j, len, modal, png, ref, ref1;
        if (bounds == null) {
          bounds = null;
        }
        this.rasterPartRectangle = bounds != null ? bounds : this.raster.bounds;
        this.subRasterRectangle = new P.Rectangle(0, 0, this.raster.width, this.raster.height);
        if (bounds != null) {
          this.subRasterRectangle = new P.Rectangle(bounds.topLeft.subtract(this.raster.bounds.topLeft).divide(this.raster.scaling), bounds.bottomRight.subtract(this.raster.bounds.topLeft).divide(this.raster.scaling));
        }
        if ((R.tools["Precise path"].draftLimit != null) && !R.tools["Precise path"].draftLimit.contains(this.subRasterRectangle)) {
          R.tools["Precise path"].constructor.displayDraftIsTooBigError();
          return;
        }
        this.rasterPart = null;
        try {
          this.rasterPart = this.raster.getSubRaster(this.subRasterRectangle);
          console.log(this.rasterPart.width);
          png = this.rasterPart.toDataURL();
          this.rasterPart.remove();
          this.rasterPart = null;
          colors = [];
          ref = R.toolManager.colors;
          for (j = 0, len = ref.length; j < len; j++) {
            color = ref[j];
            c = new paper.Color(color);
            colors.push([Math.round(c.red * 255), Math.round(c.green * 255), Math.round(c.blue * 255), 255]);
          }
          args = {
            png: png,
            colors: colors
          };
          $.ajax({
            method: "POST",
            url: "ajaxCall/",
            data: {
              data: JSON.stringify({
                "function": 'autoTrace',
                args: args
              })
            }
          }).done(this.autoTraceCallback);
        } catch (error) {
          err = error;
          if ((ref1 = this.rasterPart) != null) {
            ref1.remove();
          }
          this.rasterPart = null;
          if (err.code === 18) {
            modal = Modal.createModal({
              id: 'import-image-cross-origin-issue',
              title: "Autotrace does not work with image URL",
              submitButtonText: "Download image",
              submit: function() {
                return window.location = this.imageURL;
              }
            });
            modal.addText('You cannot trace automatically an image from an URL. Please make sure the image copyright allows reusing the image, then download the image on your computer and choose the image from your computer.', 'You cannot trace automatically an image from an URL');
            modal.show();
          }
          return;
        }
      };

      Tracer.prototype.autoTraceCallback = function(result) {
        var ref, ref1;
        if (result.state === "error") {
          if ((ref = this.modal) != null) {
            ref.hide();
          }
          R.alertManager.alert(result.error, "error");
          return;
        }
        if ((ref1 = this.modal) != null) {
          ref1.hide();
        }
        this.addSvgToDraft(result.svg, result.colors);
      };

      Tracer.prototype.addPathsToDraft = function(item, draft) {
        var child, j, len, ref;
        ref = item.children.slice();
        for (j = 0, len = ref.length; j < len; j++) {
          child = ref[j];
          if (child instanceof P.Path) {
            child.strokeWidth = R.Path.strokeWidth;
            if ((item.strokeColor != null) && (child.strokeColor == null)) {
              child.strokeColor = item.strokeColor;
            }
            child.strokeCap = 'round';
            child.strokeJoin = 'round';
            draft.addChild(child, false, false);
          } else if (child.children != null) {
            this.addPathsToDraft(child, draft);
          }
        }
      };

      Tracer.prototype.setStrokeColor = function(item, rasterPart) {
        var child, j, len, path, point, ref;
        if (item.className === 'Shape') {
          path = item.toPath();
          item.remove();
          item = path;
        }
        if (item.className === 'Path') {
          point = rasterPart.globalToLocal(item.getPointAt(item.length / 2));
          item.strokeColor = rasterPart.getPixel(point);
        } else {
          console.log(item.children);
          ref = item.children;
          for (j = 0, len = ref.length; j < len; j++) {
            child = ref[j];
            this.setStrokeColor(child, rasterPart);
          }
        }
      };

      Tracer.prototype.addSvgToDraft = function(svg, colors) {
        var draft, regex, subst, svgPaper;
        svg = svg.replace('<?xml version="1.0" standalone="yes"?>\n', '');
        regex = /style="stroke:([#\d\w]+); fill:none;"/gm;
        subst = 'stroke="$1" stroke-width="' + R.Path.strokeWidth + '"';
        svg = svg.replace(regex, subst);
        svgPaper = P.project.importSVG(svg);
        console.log(svgPaper.exportSVG({
          string: true
        }));
        svgPaper.translate(this.rasterPartRectangle.topLeft);
        svgPaper.scale(this.rasterPartRectangle.width / this.subRasterRectangle.width, this.rasterPartRectangle.topLeft);
        svgPaper.strokeCap = 'round';
        svgPaper.strokeJoin = 'round';
        svgPaper.strokeWidth = R.Path.strokeWidth;
        draft = R.Item.Drawing.getDraft();
        R.commandManager.add(new Command.ModifyDrawing(draft));
        this.addPathsToDraft(svgPaper, draft);
        draft.computeRectangle();
        draft.updatePaths();
        svgPaper.remove();
        R.toolManager.updateButtonsVisibility();
        R.tools["Precise path"].showDraftLimits();
      };

      Tracer.prototype.fileDropped = function(event) {
        var file, j, len, reader, ref;
        event.stopPropagation();
        event.preventDefault();
        if (R.selectedTool !== R.tools['Precise path']) {
          R.tools['Precise path'].select();
        }
        if (R.selectedTool !== R.tools['Precise path']) {
          return;
        }
        ref = event.dataTransfer.files;
        for (j = 0, len = ref.length; j < len; j++) {
          file = ref[j];
          if (file.type.match(/image.*/)) {
            this.imageFile = file;
            reader = new FileReader();
            reader.onload = (function(_this) {
              return function(readerEvent) {
                _this.imageURL = readerEvent.target.result;
                _this.setEditImageMode();
              };
            })(this);
            reader.readAsDataURL(file);
            return;
          }
        }
      };

      Tracer.prototype.handleFiles = function(event) {
        var file, j, len, reader, ref;
        ref = event.target.files;
        for (j = 0, len = ref.length; j < len; j++) {
          file = ref[j];
          if (file.type.match(/image.*/)) {
            this.imageFile = file;
            reader = new FileReader();
            reader.onload = (function(_this) {
              return function(readerEvent) {
                _this.imageURL = readerEvent.target.result;
                _this.setEditImageMode();
              };
            })(this);
            reader.readAsDataURL(file);
            return;
          }
        }
      };

      Tracer.prototype.showButton = function() {
        var ref, ref1;
        if ((ref = this.tracerBtn) != null) {
          ref.show();
        }
        if (this.tracerGroup != null) {
          if ((ref1 = R.toolManager) != null) {
            ref1.showTracerButtons();
          }
        }
      };

      Tracer.prototype.hideButton = function() {
        var ref, ref1;
        if ((ref = this.tracerBtn) != null) {
          ref.hide();
        }
        if ((ref1 = R.toolManager) != null) {
          ref1.hideTracerButtons();
        }
      };

      Tracer.prototype.hide = function() {
        var ref;
        if ((ref = this.tracerGroup) != null) {
          ref.visible = false;
        }
      };

      Tracer.prototype.show = function() {
        var ref;
        if ((ref = this.tracerGroup) != null) {
          ref.visible = true;
        }
      };

      Tracer.prototype.isVisible = function() {
        var ref;
        return ((ref = this.tracerGroup) != null ? ref.visible : void 0) && (this.tracerGroup.parent != null);
      };

      Tracer.prototype.mouseUp = function(event) {
        var ref;
        this.draggingImage = false;
        this.scalingImage = false;
        if ((ref = R.selectedTool) != null) {
          ref.updateCursor();
        }
      };

      Tracer.prototype.update = function() {
        this.drawHandles();
      };

      return Tracer;

    })();
    return Tracer;
  });

}).call(this);
