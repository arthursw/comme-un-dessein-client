// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils', 'i18next'], function(P, R, Utils, i18next) {
    var Modal;
    Modal = (function() {
      Modal.modalJ = $('#customModal');

      Modal.modals = [];

      Modal.createModal = function(args) {
        var modal, zIndex;
        modal = new Modal(args);
        if (this.modals.length > 0) {
          zIndex = parseInt(_.last(this.modals).modalJ.css('z-index'));
          modal.modalJ.css('z-index', zIndex + 2);
        }
        this.modals.push(modal);
        return modal;
      };

      Modal.deleteModal = function(modal) {
        modal["delete"]();
      };

      Modal.getModalByTitle = function(title) {
        var j, len, modal, ref;
        ref = this.modals;
        for (j = 0, len = ref.length; j < len; j++) {
          modal = ref[j];
          if (modal.title === title) {
            return modal;
          }
        }
        return null;
      };

      Modal.getModalByName = function(name) {
        var j, len, modal, ref;
        ref = this.modals;
        for (j = 0, len = ref.length; j < len; j++) {
          modal = ref[j];
          if (modal.name === name) {
            return modal;
          }
        }
        return null;
      };

      function Modal(args) {
        this["delete"] = bind(this["delete"], this);
        var iconJ, spanJ;
        this.data = {
          data: args.data
        };
        this.title = args.title;
        this.name = args.name;
        this.validation = args.validation;
        this.postSubmit = args.postSubmit || 'hide';
        this.submitCallback = args.submit;
        this.extractors = [];
        this.modalJ = this.constructor.modalJ.clone();
        this.modalJ.attr('id', 'modal-' + args.id);
        R.templatesJ.find('.modals').append(this.modalJ);
        this.modalBodyJ = this.modalJ.find('.modal-body');
        this.modalBodyJ.empty();
        this.modalJ.find(".modal-footer").show().find(".btn").show();
        this.modalJ.on('shown.bs.modal', (function(_this) {
          return function(event) {
            var zIndex;
            _this.modalJ.find('input.form-control:visible:first').focus();
            zIndex = parseInt(_this.modalJ.css('z-index'));
            return $('body').find('.modal-backdrop:last').css('z-index', zIndex - 1);
          };
        })(this));
        this.modalJ.on('hidden.bs.modal', this["delete"]);
        if (args.submitButtonText != null) {
          spanJ = $('<span>');
          spanJ.attr('data-i18n', args.submitButtonText).append(i18next.t(args.submitButtonText));
          this.modalJ.find('[name="submit"]').removeAttr('data-i18n').html(spanJ);
        }
        if (args.submitButtonIcon != null) {
          iconJ = $('<span>');
          iconJ.addClass('glyphicon ' + args.submitButtonIcon);
          this.modalJ.find('[name="submit"]').prepend(iconJ);
        }
        if (args.cancelButtonText != null) {
          spanJ = $('<span>');
          spanJ.attr('data-i18n', args.cancelButtonText).append(i18next.t(args.cancelButtonText));
          this.modalJ.find('[name="cancel"]').html(spanJ);
        }
        if (args.cancelButtonIcon != null) {
          iconJ = $('<span>');
          iconJ.addClass('glyphicon ' + args.cancelButtonIcon);
          this.modalJ.find('[name="cancel"]').removeAttr('data-i18n').prepend(iconJ);
        }
        this.modalJ.find('.btn-primary').click((function(_this) {
          return function(event) {
            return _this.modalSubmit();
          };
        })(this));
        this.extractors = {};
        this.modalJ.find("h4.modal-title").attr('data-i18n', args.title).html(i18next.t(args.title));
        return;
      }

      Modal.prototype.addText = function(text, textKey, escapeValue, options) {
        var content;
        if (textKey == null) {
          textKey = null;
        }
        if (escapeValue == null) {
          escapeValue = false;
        }
        if (options == null) {
          options = null;
        }
        if (textKey == null) {
          textKey = text;
        }
        if (options == null) {
          options = {};
        }
        if (options.interpolation == null) {
          options.interpolation = {};
        }
        options.interpolation.escapeValue = escapeValue;
        content = i18next.t(textKey, options);
        this.modalBodyJ.append("<p data-i18n-options='" + (JSON.stringify(options)) + "' data-i18n='[html]" + textKey + "'>" + content + "</p>");
      };

      Modal.prototype.addTextInput = function(args) {
        var className, defaultValue, divJ, errorMessage, extractor, id, inputId, inputJ, label, labelJ, name, placeholder, required, submitShortcut, type;
        name = args.name;
        placeholder = args.placeholder;
        type = args.type;
        className = args.className;
        label = args.label;
        submitShortcut = args.submitShortcut;
        id = args.id;
        required = args.required;
        errorMessage = args.errorMessage;
        defaultValue = args.defaultValue;
        if (required) {
          if (errorMessage == null) {
            errorMessage = "<em>" + (label || name) + "</em> is invalid.";
          }
        }
        submitShortcut = submitShortcut ? 'submit-shortcut' : '';
        inputJ = $("<input type='" + type + "' class='" + className + " form-control " + submitShortcut + "'>");
        if ((placeholder != null) && placeholder !== '') {
          inputJ.attr("placeholder", placeholder);
        }
        inputJ.val(defaultValue);
        args = inputJ;
        extractor = function(data, inputJ, name, required) {
          if (required == null) {
            required = false;
          }
          data[name] = inputJ.val();
          return (!required) || (!inputJ.is(':visible')) || ((data[name] != null) && data[name] !== '');
        };
        if (label) {
          inputId = 'modal-' + name + '-' + Math.random().toString();
          inputJ.attr('id', inputId);
          divJ = $("<div id='" + id + "' class='form-group " + className + "-group'></div>");
          labelJ = $(("<label for='" + inputId + "'>") + i18next.t(label) + "</label>");
          labelJ.attr('data-i18n', label);
          divJ.append(labelJ);
          divJ.append(inputJ);
          inputJ = divJ;
        }
        this.addCustomContent({
          name: name,
          divJ: inputJ,
          extractor: extractor,
          args: args,
          required: required,
          errorMessage: errorMessage
        });
        return inputJ;
      };

      Modal.prototype.addCheckbox = function(args) {
        var checkboxJ, defaultValue, divJ, extractor, helpMessage, helpMessageJ, label, name;
        name = args.name;
        label = args.label;
        helpMessage = args.helpMessage;
        defaultValue = args.defaultValue;
        divJ = $("<div>");
        divJ.addClass('checkbox');
        checkboxJ = $("<label><input type='checkbox' form-control>" + label + "</label>");
        if (defaultValue) {
          checkboxJ.find('input').attr('checked', true);
        }
        divJ.append(checkboxJ);
        if (helpMessage) {
          helpMessageJ = $("<p class='help-block'>" + helpMessage + "</p>");
          divJ.append(helpMessageJ);
        }
        extractor = function(data, checkboxJ, name) {
          data[name] = checkboxJ.find('input').is(':checked');
          return true;
        };
        this.addCustomContent({
          name: name,
          divJ: divJ,
          extractor: extractor,
          args: checkboxJ
        });
        return divJ;
      };

      Modal.prototype.addRadioGroup = function(args) {
        var checked, divJ, extractor, inputJ, j, labelJ, len, name, radioButton, radioButtons, radioJ, submitShortcut;
        name = args.name;
        radioButtons = args.radioButtons;
        divJ = $("<div>");
        for (j = 0, len = radioButtons.length; j < len; j++) {
          radioButton = radioButtons[j];
          radioJ = $("<div class='radio'>");
          labelJ = $("<label>");
          checked = radioButton.checked ? 'checked' : '';
          submitShortcut = radioButton.submitShortcut ? 'class="submit-shortcut"' : '';
          inputJ = $("<input type='radio' name='" + name + "' value='" + radioButton.value + "' " + checked + " " + submitShortcut + ">");
          labelJ.append(inputJ);
          labelJ.append(radioButton.label);
          radioJ.append(labelJ);
          divJ.append(radioJ);
        }
        extractor = function(data, divJ, name, required) {
          var choiceJ, ref;
          if (required == null) {
            required = false;
          }
          choiceJ = divJ.find("input[type=radio][name=" + name + "]:checked");
          data[name] = (ref = choiceJ[0]) != null ? ref.value : void 0;
          return (!required) || (!divJ.is(':visible')) || (data[name] != null);
        };
        this.addCustomContent({
          name: name,
          divJ: divJ,
          extractor: extractor
        });
        return divJ;
      };

      Modal.prototype.addTable = function(data) {
        var tableJ, tablePath;
        tableJ = $("<table class='.table'>");
        this.modalBodyJ.append(tableJ);
        tablePath = 'table';
        require([tablePath], function() {
          tableJ.bootstrapTable(data);
        });
        return tableJ;
      };

      Modal.prototype.addImageSelector = function(args) {
        var divJ, dropZone, handleDragOver, handleFileSelect, name;
        name = args.name || 'image-selector';
        divJ = $("<div class=\"form-group url-group\">\n	<label>Add your image</label>\n	<input data-name='" + name + "-file-selector' type=\"file\" class=\"form-control\" name=\"file[]\"/>\n	<div data-name='" + name + "-drop-zone' style=\"border: 2px dashed #bbb;padding: 25px;text-align: center;color: #bbb;\">\n		<div data-name='" + name + "-gallery'></div>\n		Drop your image file here.\n	</div>\n</div>");
        this.data.imageSelector = {
          nRasterLoaded: 0,
          nRastersLoaded: 0,
          rasters: {},
          rastersLoadedCallback: args.rastersLoadedCallback
        };
        handleFileSelect = (function(_this) {
          return function(event) {
            var f, files, i, reader, ref, ref1;
            event.stopPropagation();
            event.preventDefault();
            files = ((ref = event.dataTransfer) != null ? ref.files : void 0) || ((ref1 = event.target) != null ? ref1.files : void 0);
            _this.data.imageSelector.nRasterToLoad = files.length;
            i = 0;
            f = void 0;
            while (f = files[i]) {
              if (_this.data.imageSelector.rasters.hasOwnProperty(f)) {
                continue;
              }
              if (!f.type.match('image.*')) {
                i++;
                continue;
              }
              reader = new FileReader;
              reader.onload = (function(file, data) {
                return function(event) {
                  var SVGLayer, imageSelector, span, svg;
                  imageSelector = data.imageSelector;
                  span = document.createElement('span');
                  span.innerHTML = ['<img class="thumb" src="' + event.target.result + '" title="' + escape(file.name) + '"/>'].join('');
                  divJ.find('[data-name="' + name + '-gallery"]').append(span);
                  if (!args.svg) {
                    imageSelector.rasters[file] = new P.Raster(event.target.result);
                  } else {
                    span.innerHTML = event.target.result;
                    svg = span.querySelector('svg');
                    SVGLayer = new P.Layer();
                    imageSelector.rasters[file] = P.project.importSVG(svg);
                    SVGLayer.remove();
                  }
                  imageSelector.nRasterLoaded++;
                  if (imageSelector.nRasterLoaded === imageSelector.nRasterToLoad) {
                    imageSelector.rastersLoadedCallback(imageSelector.rasters);
                  }
                };
              })(f, _this.data);
              if (!args.svg) {
                reader.readAsDataURL(f);
              } else {
                reader.readAsText(f);
              }
              i++;
            }
          };
        })(this);
        handleDragOver = function(event) {
          event.stopPropagation();
          event.preventDefault();
          event.dataTransfer.dropEffect = 'copy';
        };
        divJ.find('[data-name="' + name + '-file-selector"]').change(handleFileSelect);
        dropZone = divJ.find('[data-name="' + name + '-drop-zone"]')[0];
        dropZone.addEventListener('dragover', handleDragOver, false);
        dropZone.addEventListener('drop', handleFileSelect, false);
        this.addCustomContent({
          name: name,
          divJ: divJ,
          extractor: args.extractor || function() {
            return true;
          }
        });
        return divJ;
      };

      Modal.prototype.addCustomContent = function(args) {
        if (args.args == null) {
          args.args = args.divJ;
        }
        if (args.name != null) {
          args.divJ.attr('id', 'modal-' + args.name);
        }
        this.modalBodyJ.append(args.divJ);
        if (args.extractor != null) {
          this.extractors[args.name] = args;
        }
      };

      Modal.prototype.addButton = function(args) {
        var buttonJ, icon, submitButtonJ, text;
        if (args.type == null) {
          args.type = 'default';
        }
        icon = args.icon != null ? "<span class='glyphicon " + args.icon + "'></span>" : '';
        text = "<span data-i18n='" + args.name + "'>" + (i18next.t(args.name)) + "</span>";
        buttonJ = $(("<button type='button' class='btn btn-" + args.type + "' name='" + args.name + "'>") + icon + text + "</button>");
        if (args.submit != null) {
          buttonJ.click((function(_this) {
            return function(event) {
              args.submit(_this.data);
              buttonJ.remove();
              _this.hide();
            };
          })(this));
        }
        submitButtonJ = this.modalJ.find('.modal-footer .btn-primary[name="submit"]');
        if (submitButtonJ.length > 0) {
          submitButtonJ.before(buttonJ);
        } else {
          this.modalJ.find('.modal-footer .btn-primary').before(buttonJ);
        }
        return buttonJ;
      };

      Modal.prototype.show = function() {
        this.modalJ.find('.submit-shortcut').keypress((function(_this) {
          return function(event) {
            if (event.which === 13) {
              event.preventDefault();
              _this.modalSubmit();
            }
          };
        })(this));
        this.modalJ.modal('show');
        $('#templates').removeClass('hidden').show();
      };

      Modal.prototype.hide = function() {
        this.modalJ.modal('hide');
      };

      Modal.prototype.addProgressBar = function() {
        var progressJ;
        progressJ = $(" <div class=\"progress modal-progress-bar\">\n	<div class=\"progress-bar progress-bar-striped active\" role=\"progressbar\" aria-valuenow=\"100\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 100%\">\n		<span class=\"sr-only\">Loading...</span>\n	</div>\n</div>");
        this.modalBodyJ.append(progressJ);
        return progressJ;
      };

      Modal.prototype.removeProgressBar = function() {
        this.modalBodyJ.find('.modal-progress-bar').remove();
      };

      Modal.prototype.modalSubmit = function() {
        var errorMessage, extractor, name, ref, valid;
        this.modalJ.find(".error-message").remove();
        valid = true;
        ref = this.extractors;
        for (name in ref) {
          extractor = ref[name];
          valid &= extractor.extractor(this.data, extractor.args, name, extractor.required);
          if (!valid) {
            errorMessage = extractor.errorMessage;
            if (errorMessage == null) {
              errorMessage = 'The field "' + name + '"" is invalid.';
            }
            this.modalBodyJ.append("<div class='error-message'>" + errorMessage + "</div>");
          }
        }
        if (!valid || (this.validation != null) && !this.validation(data)) {
          return;
        }
        if (typeof this.submitCallback === "function") {
          this.submitCallback(this.data);
        }
        this.extractors = {};
        switch (this.postSubmit) {
          case 'hide':
            this.modalJ.modal('hide');
            break;
          case 'load':
            this.modalBodyJ.children().hide();
            this.addProgressBar();
        }
      };

      Modal.prototype["delete"] = function() {
        $('#templates').hide();
        this.modalJ.remove();
        Utils.Array.remove(this.constructor.modals, this);
      };

      return Modal;

    })();
    return Modal;
  });

}).call(this);

//# sourceMappingURL=Modal.js.map
