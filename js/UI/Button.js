// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'UI/Modal', 'i18next'], function(P, R, Utils, Tool, Modal, i18next) {
    var Button;
    Button = (function() {
      function Button(parameters) {
        this.onClickWhenLoaded = bind(this.onClickWhenLoaded, this);
        this.onClickWhenNotLoaded = bind(this.onClickWhenNotLoaded, this);
        this.fileLoaded = bind(this.fileLoaded, this);
        var categories, category, classes, divType, favorite, favoriteBtnJ, hJ, i, iconRootURL, iconURL, ignoreFavorite, j, len, len1, liJ, name, onClick, order, parentJ, prepend, shortName, shortNameJ, toolNameJ, ulJ, word, words;
        this.visible = true;
        name = parameters.name;
        iconURL = parameters.iconURL;
        favorite = parameters.favorite;
        ignoreFavorite = parameters.ignoreFavorite;
        category = parameters.category;
        order = parameters.order;
        classes = parameters.classes;
        this.file = parameters.file;
        onClick = parameters.onClick;
        divType = parameters.divType || 'li';
        prepend = parameters.prepend;
        parentJ = parameters.parentJ || R.sidebar.allToolsJ;
        if ((category != null) && category !== "") {
          categories = category.split("/");
          for (i = 0, len = categories.length; i < len; i++) {
            category = categories[i];
            ulJ = parentJ.find("li[data-name='" + category + "'] > ul");
            if (ulJ.length === 0) {
              liJ = $("<li data-name='" + category + "'>");
              liJ.addClass('category');
              hJ = $('<h6>');
              hJ.text(category).addClass("title");
              liJ.append(hJ);
              ulJ = $("<ul>");
              ulJ.addClass('folder');
              liJ.append(ulJ);
              hJ.click(this.toggleCategory);
              parentJ.append(liJ);
            }
            parentJ = ulJ;
          }
        }
        this.btnJ = $("<" + divType + ">");
        this.btnJ.attr("data-name", name);
        this.btnJ.attr("alt", name);
        if ((classes != null) && classes.length > 0) {
          this.btnJ.addClass(classes);
        }
        if (parameters.disableHover && this.deviceHasTouch()) {
          this.btnJ.addClass('no-hover');
        }
        if ((iconURL != null) && iconURL !== '') {
          if (iconURL.indexOf('glyphicon') === 0) {
            this.btnJ.append('<span class="glyphicon ' + iconURL + '" alt="' + name + '-icon">');
            if (parameters.transform != null) {
              this.btnJ.find('span.glyphicon').css({
                transform: parameters.transform
              });
            }
          } else {
            iconRootURL = 'static/images/icons/inverted/';
            if (iconURL.indexOf('//') < 0 && iconURL.indexOf(iconRootURL) < 0) {
              iconURL = iconRootURL + iconURL;
            }
            if (iconURL.indexOf(iconRootURL) === 0) {
              iconURL = location.origin + '/' + iconURL;
            }
            this.btnJ.append('<img src="' + iconURL + '" alt="' + name + '-icon">');
          }
        } else {
          this.btnJ.addClass("text-btn");
          words = name.split(" ");
          shortName = "";
          if (words.length > 1) {
            for (j = 0, len1 = words.length; j < len1; j++) {
              word = words[j];
              shortName += word.substring(0, 1);
            }
          } else {
            shortName += name.substring(0, 2);
          }
          shortNameJ = $('<span class="short-name">').text(shortName + ".");
          this.btnJ.append(shortNameJ);
        }
        if (prepend != null) {
          parentJ.prepend(this.btnJ);
        } else {
          parentJ.append(this.btnJ);
        }
        toolNameJ = $('<span class="tool-name">');
        toolNameJ.attr('data-i18n', name).text(i18next.t(name));
        this.btnJ.append(toolNameJ);
        this.btnJ.addClass("tool-btn");
        if (!ignoreFavorite) {
          favoriteBtnJ = $("<button type=\"button\" class=\"btn btn-default favorite-btn\">\n		  			<span class=\"glyphicon glyphicon-star\" aria-hidden=\"true\"></span>\n</button>");
          favoriteBtnJ.click(R.sidebar.toggleToolToFavorite);
          this.btnJ.append(favoriteBtnJ);
        }
        this.btnJ.attr({
          'data-order': order != null ? order : 999
        });
        if (onClick != null) {
          this.btnJ.click(onClick);
        } else {
          this.btnJ.click(this.file != null ? this.onClickWhenNotLoaded : this.onClickWhenLoaded);
        }
        if ((parameters.description != null) || parameters.popover) {
          this.addPopover(parameters);
        }
        if (favorite) {
          R.sidebar.toggleToolToFavorite(null, this.btnJ, this);
        }
        if (parameters.preload) {
          this.onClickWhenNotLoaded();
        }
        return;
      }

      Button.prototype.deviceHasTouch = function() {
        var isIPad, isIPod;
        isIPad = navigator.userAgent.match(/iPad/i) !== null;
        isIPod = navigator.platform.match(/i(Phone|Pod)/i);
        return (document.documentElement.ontouchstart != null) || navigator.maxTouchPoints > 0 || navigator.msMaxTouchPoints > 0 || isIPod || isIPad;
      };

      Button.prototype.click = function() {
        this.btnJ.click();
      };

      Button.prototype.addPopover = function(parameters) {
        var attrs, is_touch_device, prefix;
        is_touch_device = (indexOf.call(window, "ontouchstart") >= 0) || window.DocumentTouch && document instanceof DocumentTouch || window.innerWidth <= 1024;
        if (is_touch_device) {
          return;
        }
        this.btnJ.attr('data-placement', 'bottom');
        this.btnJ.attr('data-container', '#popovers');
        this.btnJ.attr('data-trigger', 'hover');
        this.btnJ.attr('data-delay', {
          show: 500,
          hide: 100
        });
        if ((parameters.description == null) || parameters.description === '') {
          this.btnJ.attr('data-content', i18next.t(parameters.name));
          attrs = this.btnJ.attr('data-i18n');
          prefix = attrs != null ? attrs + ';' : '';
          this.btnJ.attr('data-i18n', prefix + '[data-content]' + parameters.name);
        } else {
          this.btnJ.attr('data-title', i18next.t(parameters.name));
          this.btnJ.attr('data-content', i18next.t(parameters.description));
          attrs = this.btnJ.attr('data-i18n');
          prefix = attrs != null ? attrs + ';' : '';
          this.btnJ.attr('data-i18n', prefix + '[data-title]' + parameters.name + ';[data-content]' + parameters.description);
        }
        this.btnJ.popover();
        this.btnJ.mouseup((function(_this) {
          return function() {
            return setTimeout((function() {
              _this.btnJ.popover('hide');
            }), 500);
          };
        })(this));
      };

      Button.prototype.toggleCategory = function(event) {
        var categoryJ;
        categoryJ = $(this).parent();
        categoryJ.toggleClass('closed');
        categoryJ.children('.folder').children().show();
      };

      Button.prototype.fileLoaded = function() {
        this.btnJ.off('click');
        this.btnJ.click(this.onClickWhenLoaded);
        this.onClickWhenLoaded();
      };

      Button.prototype.onClickWhenNotLoaded = function(event) {
        require([this.file], this.fileLoaded);
      };

      Button.prototype.onClickWhenLoaded = function(event) {
        var ref, ref1, toolName;
        toolName = this.btnJ.attr("data-name");
        if ((ref = R.tools[toolName]) != null) {
          ref.btn = this;
        }
        if ((ref1 = R.tools[toolName]) != null) {
          ref1.select();
        }
      };

      Button.prototype.hide = function() {
        this.visible = false;
        this.btnJ.hide();
        if (this.cloneJ != null) {
          this.cloneJ.hide();
        }
      };

      Button.prototype.show = function() {
        this.visible = true;
        this.btnJ.show();
        if (this.cloneJ != null) {
          this.cloneJ.show();
        }
      };

      Button.prototype.removeClass = function(className) {
        this.btnJ.removeClass(className);
        if (this.cloneJ != null) {
          this.cloneJ.removeClass(className);
        }
      };

      Button.prototype.addClass = function(className) {
        this.btnJ.addClass(className);
        if (this.cloneJ != null) {
          this.cloneJ.addClass(className);
        }
      };

      return Button;

    })();
    R.Button = Button;
    return Button;
  });

}).call(this);

//# sourceMappingURL=Button.js.map
