// Generated by CoffeeScript 1.12.7
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils'], function(P, R, Utils) {
    var Toolbar;
    return Toolbar = (function() {
      function Toolbar() {
        this.stopMove = bind(this.stopMove, this);
        this.hideButtons = bind(this.hideButtons, this);
        this.moveToolbarRight = bind(this.moveToolbarRight, this);
        this.moveToolbarLeft = bind(this.moveToolbarLeft, this);
        this.clearInterval = bind(this.clearInterval, this);
        this.moveToolbar = bind(this.moveToolbar, this);
        this.updateArrowsVisibility = bind(this.updateArrowsVisibility, this);
        this.stopDrag = bind(this.stopDrag, this);
        this.animate = bind(this.animate, this);
        this.drag = bind(this.drag, this);
        this.nullifySpeedIfNotMoved = bind(this.nullifySpeedIfNotMoved, this);
        this.startDrag = bind(this.startDrag, this);
        this.intervalID = null;
        this.dragging = false;
        this.draggingPosition = null;
        this.draggingSpeed = null;
        this.dragTimeoutID = null;
        this.toolListJ = $('#FavoriteTools .tool-list');
        this.leftArrowJ = $('#FavoriteTools button.arrow.left');
        this.rightArrowJ = $('#FavoriteTools button.arrow.right');
        this.leftArrowJ.mousedown(this.moveToolbarLeft).mouseleave(this.stopMove).mouseup(this.stopMove).on({
          touchstart: this.moveToolbarLeft
        }).on({
          touchleave: this.stopMove
        }).on({
          touchend: this.stopMove
        }).on({
          touchcancel: this.stopMove
        });
        this.rightArrowJ.mousedown(this.moveToolbarRight).mouseleave(this.stopMove).mouseup(this.stopMove).on({
          touchstart: this.moveToolbarRight
        }).on({
          touchleave: this.stopMove
        }).on({
          touchend: this.stopMove
        }).on({
          touchcancel: this.stopMove
        });
        requestAnimationFrame(this.animate);
        this.toolListJ.mousedown(this.startDrag).on({
          touchstart: this.startDrag
        });
        $(document).mousemove(this.drag).mouseup(this.stopDrag).on({
          touchmove: this.drag
        }).on({
          touchleave: this.stopDrag
        }).on({
          touchend: this.stopDrag
        }).on({
          touchcancel: this.stopDrag
        });
        this.updateArrowsVisibility();
        return;
      }

      Toolbar.prototype.startDrag = function(event) {
        this.dragging = true;
        this.draggingPosition = event.pageX || event.originalEvent.touches[0].pageX;
      };

      Toolbar.prototype.nullifySpeedIfNotMoved = function() {
        if (this.dragging) {
          this.draggingSpeed = null;
        }
        this.dragTimeoutID = null;
      };

      Toolbar.prototype.drag = function(event) {
        var position;
        if (this.dragging) {
          position = event.pageX || event.originalEvent.touches[0].pageX;
          this.draggingSpeed = position - this.draggingPosition;
          this.moveToolbar(this.draggingSpeed);
          this.draggingPosition = position;
          if (this.dragTimeoutID != null) {
            clearTimeout(this.dragTimeoutID);
            this.dragTimeoutID = null;
          }
          this.dragTimeoutID = setTimeout(this.nullifySpeedIfNotMoved, 100);
        }
      };

      Toolbar.prototype.animate = function() {
        requestAnimationFrame(this.animate);
        if (this.dragging) {
          return;
        }
        if (this.draggingSpeed !== null) {
          this.draggingSpeed *= 0.9;
          this.moveToolbar(this.draggingSpeed);
        }
        if (Math.abs(this.draggingSpeed) < 0.1) {
          this.draggingSpeed = null;
        }
      };

      Toolbar.prototype.stopDrag = function(event) {
        if (this.dragTimeoutID != null) {
          clearTimeout(this.dragTimeoutID);
          this.dragTimeoutID = null;
        }
        this.dragging = false;
        this.draggingStart = null;
        this.stopMove(event);
      };

      Toolbar.prototype.updateArrowsVisibility = function(toollistWidth, windowWidth, positionX) {
        var minX, titleWidth;
        if (toollistWidth == null) {
          toollistWidth = null;
        }
        if (windowWidth == null) {
          windowWidth = null;
        }
        if (positionX == null) {
          positionX = null;
        }
        if (toollistWidth == null) {
          toollistWidth = this.toolListJ.outerWidth();
        }
        if (windowWidth == null) {
          windowWidth = window.innerWidth;
        }
        if (windowWidth > 1300) {
          this.leftArrowJ.css({
            opacity: 0
          });
          this.rightArrowJ.css({
            opacity: 0
          });
          return;
        }
        titleWidth = $('#FavoriteTools h3.title').outerWidth(true);
        minX = 0;
        if (positionX == null) {
          positionX = Math.floor(this.toolListJ.offset().left);
        }
        if (positionX >= minX) {
          this.leftArrowJ.css({
            opacity: 0
          });
        } else {
          this.leftArrowJ.css({
            opacity: 0.8
          }).show();
        }
        if (positionX + toollistWidth <= windowWidth) {
          this.rightArrowJ.css({
            opacity: 0
          });
        } else {
          this.rightArrowJ.css({
            opacity: 0.8
          }).show();
        }
        if (positionX + toollistWidth < windowWidth) {
          if (toollistWidth > windowWidth) {
            positionX = windowWidth - toollistWidth;
          } else {
            positionX = minX;
          }
          this.toolListJ.css('left', positionX, {
            position: 'relative'
          });
        }
      };

      Toolbar.prototype.moveToolbar = function(offset) {
        var minX, positionX, toollistWidth, windowWidth;
        windowWidth = window.innerWidth;
        if (windowWidth > 1300) {
          return;
        }
        toollistWidth = this.toolListJ.outerWidth();
        minX = 0;
        positionX = this.toolListJ.offset().left;
        positionX += offset;
        if (positionX > minX) {
          positionX = minX;
        }
        if (toollistWidth > windowWidth && positionX < -(toollistWidth - windowWidth)) {
          positionX = -(toollistWidth - windowWidth);
        }
        this.toolListJ.css({
          'left': positionX,
          position: 'relative'
        });
        this.updateArrowsVisibility(toollistWidth, windowWidth, positionX);
      };

      Toolbar.prototype.clearInterval = function() {
        if (this.intervalID != null) {
          clearInterval(this.intervalID);
          this.intervalID = null;
        }
      };

      Toolbar.prototype.moveToolbarLeft = function() {
        this.moveToolbar(5);
        this.clearInterval();
        this.intervalID = setInterval(((function(_this) {
          return function() {
            return _this.moveToolbar(5);
          };
        })(this)), 10);
      };

      Toolbar.prototype.moveToolbarRight = function() {
        this.moveToolbar(-5);
        this.clearInterval();
        this.intervalID = setInterval(((function(_this) {
          return function() {
            return _this.moveToolbar(-5);
          };
        })(this)), 10);
      };

      Toolbar.prototype.hideButtons = function() {
        if (this.rightArrowJ.css('opacity') === '0') {
          this.rightArrowJ.hide();
        }
        if (this.leftArrowJ.css('opacity') === '0') {
          this.leftArrowJ.hide();
        }
      };

      Toolbar.prototype.stopMove = function(event) {
        this.clearInterval();
        setTimeout(this.hideButtons, 500);
      };

      return Toolbar;

    })();
  });

}).call(this);
