// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'Items/Divs/Div', 'Commands/Command'], function(P, R, Utils, Item, Div, Command) {
    var Text;
    Text = (function(superClass) {
      extend(Text, superClass);

      Text.label = 'Text';

      Text.modalTitle = "Insert some text";

      Text.modalTitleUpdate = "Modify your text";

      Text.object_type = 'text';

      Text.initializeParameters = function() {
        var parameters;
        parameters = Text.__super__.constructor.initializeParameters.call(this);
        parameters['Font'] = {
          fontName: {
            type: 'input-typeahead',
            label: 'Font name',
            "default": '',
            initializeController: function(controller) {
              var firstItem, input, inputValue, ref, typeaheadJ;
              typeaheadJ = $(controller.datController.domElement);
              input = typeaheadJ.find("input");
              inputValue = null;
              input.typeahead({
                hint: true,
                highlight: true,
                minLength: 1
              }, {
                valueKey: 'value',
                displayKey: 'value',
                source: R.fontManager.typeaheadFontEngine.ttAdapter()
              });
              input.on('typeahead:opened', function() {
                var dropDown;
                dropDown = typeaheadJ.find(".tt-dropdown-menu");
                dropDown.insertAfter(typeaheadJ.parents('.cr:first'));
                dropDown.css({
                  position: 'relative',
                  display: 'inline-block',
                  right: 0
                });
              });
              input.on('typeahead:closed', function() {
                var item, j, len, ref;
                if (inputValue != null) {
                  input.val(inputValue);
                } else {
                  inputValue = input.val();
                }
                ref = R.selectedItems;
                for (j = 0, len = ref.length; j < len; j++) {
                  item = ref[j];
                  if (typeof item.setFontFamily === "function") {
                    item.setFontFamily(inputValue);
                  }
                }
              });
              input.on('typeahead:cursorchanged', function() {
                inputValue = input.val();
              });
              input.on('typeahead:selected', function() {
                inputValue = input.val();
              });
              input.on('typeahead:autocompleted', function() {
                inputValue = input.val();
              });
              firstItem = R.selectedItems[0];
              if ((firstItem != null ? (ref = firstItem.data) != null ? ref.fontFamily : void 0 : void 0) != null) {
                input.val(firstItem.data.fontFamily);
              }
            }
          },
          effect: {
            type: 'dropdown',
            label: 'Effect',
            values: ['none', 'anaglyph', 'brick-sign', 'canvas-print', 'crackle', 'decaying', 'destruction', 'distressed', 'distressed-wood', 'fire', 'fragile', 'grass', 'ice', 'mitosis', 'neon', 'outline', 'puttinggreen', 'scuffed-steel', 'shadow-multiple', 'static', 'stonewash', '3d', '3d-float', 'vintage', 'wallpaper'],
            "default": 'none'
          },
          styles: {
            type: 'button-group',
            label: 'Styles',
            "default": '',
            setValue: function(value) {
              var fontStyleJ, item, j, len, ref, ref1, ref2, ref3, ref4, results;
              fontStyleJ = $("#fontStyle:first");
              ref = R.selectedItems;
              results = [];
              for (j = 0, len = ref.length; j < len; j++) {
                item = ref[j];
                if (((ref1 = item.data) != null ? ref1.fontStyle : void 0) != null) {
                  if (item.data.fontStyle.italic) {
                    fontStyleJ.find("[name='italic']").addClass("active");
                  }
                  if (item.data.fontStyle.bold) {
                    fontStyleJ.find("[name='bold']").addClass("active");
                  }
                  if (((ref2 = item.data.fontStyle.decoration) != null ? ref2.indexOf('underline') : void 0) >= 0) {
                    fontStyleJ.find("[name='underline']").addClass("active");
                  }
                  if (((ref3 = item.data.fontStyle.decoration) != null ? ref3.indexOf('overline') : void 0) >= 0) {
                    fontStyleJ.find("[name='overline']").addClass("active");
                  }
                  if (((ref4 = item.data.fontStyle.decoration) != null ? ref4.indexOf('line-through') : void 0) >= 0) {
                    results.push(fontStyleJ.find("[name='line-through']").addClass("active"));
                  } else {
                    results.push(void 0);
                  }
                } else {
                  results.push(void 0);
                }
              }
              return results;
            },
            initializeController: function(controller) {
              var domElement, fontStyleJ, setStyles;
              domElement = controller.datController.domElement;
              $(domElement).find('input').remove();
              setStyles = function(value) {
                var item, j, len, ref;
                ref = R.selectedItems;
                for (j = 0, len = ref.length; j < len; j++) {
                  item = ref[j];
                  if (typeof item.changeFontStyle === "function") {
                    item.changeFontStyle(value);
                  }
                }
              };
              R.templatesJ.find("#fontStyle").clone().appendTo(domElement);
              fontStyleJ = $("#fontStyle:first");
              fontStyleJ.find("[name='italic']").click(function(event) {
                return setStyles('italic');
              });
              fontStyleJ.find("[name='bold']").click(function(event) {
                return setStyles('bold');
              });
              fontStyleJ.find("[name='underline']").click(function(event) {
                return setStyles('underline');
              });
              fontStyleJ.find("[name='overline']").click(function(event) {
                return setStyles('overline');
              });
              fontStyleJ.find("[name='line-through']").click(function(event) {
                return setStyles('line-through');
              });
              controller.setValue();
            }
          },
          align: {
            type: 'radio-button-group',
            label: 'Align',
            "default": '',
            initializeController: function(controller) {
              var domElement, setStyles, textAlignJ;
              domElement = controller.datController.domElement;
              $(domElement).find('input').remove();
              setStyles = function(value) {
                var item, j, len, ref;
                ref = R.selectedItems;
                for (j = 0, len = ref.length; j < len; j++) {
                  item = ref[j];
                  if (typeof item.changeFontStyle === "function") {
                    item.changeFontStyle(value);
                  }
                }
              };
              R.templatesJ.find("#textAlign").clone().appendTo(domElement);
              textAlignJ = $("#textAlign:first");
              textAlignJ.find(".justify").click(function(event) {
                return setStyles('justify');
              });
              textAlignJ.find(".align-left").click(function(event) {
                return setStyles('left');
              });
              textAlignJ.find(".align-center").click(function(event) {
                return setStyles('center');
              });
              textAlignJ.find(".align-right").click(function(event) {
                return setStyles('right');
              });
            }
          },
          fontSize: {
            type: 'slider',
            label: 'Font size',
            min: 5,
            max: 300,
            "default": 11
          },
          fontColor: {
            type: 'color',
            label: 'Color',
            "default": 'black',
            defaultCheck: true
          }
        };
        return parameters;
      };

      Text.parameters = Text.initializeParameters();

      function Text(bounds, data, id, pk, date, lock) {
        var lockedForMe, message;
        this.data = data != null ? data : null;
        this.id = id != null ? id : null;
        this.pk = pk != null ? pk : null;
        this.date = date;
        this.lock = lock != null ? lock : null;
        this.changeFontStyle = bind(this.changeFontStyle, this);
        this.textChanged = bind(this.textChanged, this);
        this.onBlur = bind(this.onBlur, this);
        this.onFocus = bind(this.onFocus, this);
        Text.__super__.constructor.call(this, bounds, this.data, this.id, this.pk, this.date, this.lock);
        this.contentJ = $("<textarea></textarea>");
        this.contentJ.insertBefore(this.maskJ);
        this.contentJ.val(this.data.message);
        lockedForMe = this.owner !== R.me && (this.lock != null);
        if (lockedForMe) {
          message = this.data.message;
          this.contentJ[0].addEventListener("input", (function() {
            return this.value = message;
          }), false);
        }
        this.setCss();
        this.contentJ.focus(this.onFocus);
        this.contentJ.blur(this.onBlur);
        if (!lockedForMe) {
          this.contentJ.bind('input propertychange', (function(_this) {
            return function(event) {
              return _this.textChanged(event);
            };
          })(this));
        }
        if ((this.data != null) && Object.keys(this.data).length > 0) {
          this.setFont(false);
        }
        return;
      }

      Text.prototype.onFocus = function(event) {
        $(event.target).addClass("selected form-control");
        this.select();
      };

      Text.prototype.onBlur = function(event) {
        $(event.target).removeClass("selected form-control");
      };

      Text.prototype.deselect = function() {
        if (!Text.__super__.deselect.call(this)) {
          return false;
        }
        this.contentJ.blur();
        return true;
      };

      Text.prototype.textChanged = function(event) {
        var newText;
        newText = this.contentJ.val();
        R.commandManager.deferredAction(Command.ModifyText, this, event, newText);
      };

      Text.prototype.setText = function(newText, update) {
        if (update == null) {
          update = false;
        }
        this.data.message = newText;
        this.contentJ.val(newText);
        if (!this.socketAction) {
          if (update) {
            this.update('text');
          }
          R.socket.emit("bounce", {
            itemId: this.id,
            "function": "setText",
            "arguments": [newText, false]
          });
        }
      };

      Text.prototype.setFontFamily = function(fontFamily, update) {
        var available, item, j, len, ref;
        if (update == null) {
          update = true;
        }
        if (fontFamily == null) {
          return;
        }
        available = false;
        ref = R.fontManager.availableFonts;
        for (j = 0, len = ref.length; j < len; j++) {
          item = ref[j];
          if (item.family === fontFamily) {
            available = true;
            break;
          }
        }
        if (!available) {
          return;
        }
        this.data.fontFamily = fontFamily;
        R.fontManager.addFont(fontFamily, this.data.effect);
        R.fontManager.loadFonts();
        this.contentJ.css({
          "font-family": "'" + fontFamily + "', 'Helvetica Neue', Helvetica, Arial, sans-serif"
        });
        if (update) {
          this.update();
        }
      };

      Text.prototype.changeFontStyle = function(value) {
        var base, base1;
        if (value == null) {
          return;
        }
        if (typeof value !== 'string') {
          return;
        }
        if ((base = this.data).fontStyle == null) {
          base.fontStyle = {};
        }
        if ((base1 = this.data.fontStyle).decoration == null) {
          base1.decoration = '';
        }
        switch (value) {
          case 'underline':
            if (this.data.fontStyle.decoration.indexOf(' underline') >= 0) {
              this.data.fontStyle.decoration = this.data.fontStyle.decoration.replace(' underline', '');
            } else {
              this.data.fontStyle.decoration += ' underline';
            }
            break;
          case 'overline':
            if (this.data.fontStyle.decoration.indexOf(' overline') >= 0) {
              this.data.fontStyle.decoration = this.data.fontStyle.decoration.replace(' overline', '');
            } else {
              this.data.fontStyle.decoration += ' overline';
            }
            break;
          case 'line-through':
            if (this.data.fontStyle.decoration.indexOf(' line-through') >= 0) {
              this.data.fontStyle.decoration = this.data.fontStyle.decoration.replace(' line-through', '');
            } else {
              this.data.fontStyle.decoration += ' line-through';
            }
            break;
          case 'italic':
            this.data.fontStyle.italic = !this.data.fontStyle.italic;
            break;
          case 'bold':
            this.data.fontStyle.bold = !this.data.fontStyle.bold;
            break;
          case 'justify':
          case 'left':
          case 'right':
          case 'center':
            this.data.fontStyle.align = value;
        }
        this.setFontStyle(true);
      };

      Text.prototype.setFontStyle = function(update) {
        var ref, ref1, ref2, ref3;
        if (update == null) {
          update = true;
        }
        if (((ref = this.data.fontStyle) != null ? ref.italic : void 0) != null) {
          this.contentJ.css({
            "font-style": this.data.fontStyle.italic ? "italic" : "normal"
          });
        }
        if (((ref1 = this.data.fontStyle) != null ? ref1.bold : void 0) != null) {
          this.contentJ.css({
            "font-weight": this.data.fontStyle.bold ? "bold" : "normal"
          });
        }
        if (((ref2 = this.data.fontStyle) != null ? ref2.decoration : void 0) != null) {
          this.contentJ.css({
            "text-decoration": this.data.fontStyle.decoration
          });
        }
        if (((ref3 = this.data.fontStyle) != null ? ref3.align : void 0) != null) {
          this.contentJ.css({
            "text-align": this.data.fontStyle.align
          });
        }
        if (update) {
          this.update();
        }
      };

      Text.prototype.setFontSize = function(fontSize, update) {
        if (update == null) {
          update = true;
        }
        if (fontSize == null) {
          return;
        }
        this.data.fontSize = fontSize;
        this.contentJ.css({
          "font-size": fontSize + "px"
        });
        if (update) {
          this.update();
        }
      };

      Text.prototype.setFontEffect = function(fontEffect, update) {
        var className, i;
        if (update == null) {
          update = true;
        }
        if (fontEffect == null) {
          return;
        }
        R.fontManager.addFont(this.data.fontFamily, fontEffect);
        i = this.contentJ[0].classList.length - 1;
        while (i >= 0) {
          className = this.contentJ[0].classList[i];
          if (className.indexOf("font-effect-") >= 0) {
            this.contentJ.removeClass(className);
          }
          i--;
        }
        R.fontManager.loadFonts();
        this.contentJ.addClass("font-effect-" + fontEffect);
        if (update) {
          this.update();
        }
      };

      Text.prototype.setFontColor = function(fontColor, update) {
        if (update == null) {
          update = true;
        }
        this.contentJ.css({
          "color": fontColor != null ? fontColor : 'black'
        });
      };

      Text.prototype.setFont = function(update) {
        if (update == null) {
          update = true;
        }
        this.setFontStyle(update);
        this.setFontFamily(this.data.fontFamily, update);
        this.setFontSize(this.data.fontSize, update);
        this.setFontEffect(this.data.effect, update);
        this.setFontColor(this.data.fontColor, update);
      };

      Text.prototype.setParameter = function(name, value) {
        Text.__super__.setParameter.call(this, name, value);
        switch (name) {
          case 'fontStyle':
          case 'fontFamily':
          case 'fontSize':
          case 'effect':
          case 'fontColor':
            this.setFont(false);
            break;
          default:
            this.setFont(false);
        }
      };

      Text.prototype["delete"] = function() {
        if (this.contentJ.hasClass("selected")) {
          return;
        }
        Text.__super__["delete"].call(this);
      };

      return Text;

    })(Div);
    Item.Text = Text;
    return Text;
  });

}).call(this);

//# sourceMappingURL=Text.js.map
