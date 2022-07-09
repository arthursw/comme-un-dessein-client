// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/Modal', 'i18next'], function(P, R, Utils, Item, Modal, i18next) {
    var Discussion;
    Discussion = (function() {
      Discussion.discussionMargin = 20;

      function Discussion(point, title, id, pk, owner, status) {
        if (title == null) {
          title = 'Enter the title of your discussion';
        }
        this.id = id != null ? id : null;
        this.pk = pk != null ? pk : null;
        this.owner = owner != null ? owner : R.me;
        this.status = status != null ? status : 'draft';
        this.submitCallback = bind(this.submitCallback, this);
        if (this.id == null) {
          this.id = Utils.createId();
        }
        this.pointText = new P.PointText(point);
        this.pointText.content = title;
        this.pointText.justification = 'center';
        this.pointText.fontSize = '24px';
        this.pointText.fontFamily = 'Open Sans';
        this.rectangle = new P.Path.Rectangle(this.pointText.bounds.expand(this.constructor.discussionMargin));
        this.rectangle.strokeColor = R.selectionBlue;
        this.rectangle.strokeScaling = false;
        this.rectangle.fillColor = 'white';
        this.rectangle.opacity = 0.8;
        this.group = new P.Group();
        this.group.addChild(this.rectangle);
        this.group.addChild(this.pointText);
        this.group.data.type = 'discussion';
        R.view.discussionLayer.addChild(this.group);
        this.group.data.discussion = this;
        if (this.pk) {
          this.group.position = point;
        }
        return;
      }

      Discussion.prototype.setPosition = function(point) {
        this.group.position = point;
      };

      Discussion.prototype.defaultCallback = function(result) {
        R.loader.hideLoadingBar();
        if (!R.loader.checkError(result)) {
          return false;
        }
        return true;
      };

      Discussion.prototype.update = function(data) {
        var args;
        this.updateTitle(data.title);
        args = {
          pk: this.pk,
          title: this.pointText.content,
          bounds: this.rectangle.bounds
        };
        R.loader.showLoadingBar();
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'updateDiscussion',
              args: args
            })
          }
        }).done(this.defaultCallback);
      };

      Discussion.prototype.updateTitle = function(text) {
        this.pointText.content = text;
        Utils.Rectangle.updatePathRectangle(this.rectangle, this.pointText.bounds.expand(this.constructor.discussionMargin));
      };

      Discussion.prototype.submit = function() {
        var args;
        args = {
          clientId: this.id,
          title: this.pointText.content,
          bounds: this.rectangle.bounds,
          cityName: R.city.name
        };
        R.loader.showLoadingBar();
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'submitDiscussion',
              args: args
            })
          }
        }).done(this.submitCallback);
      };

      Discussion.prototype.submitCallback = function(result) {
        if (!this.defaultCallback(result)) {
          return;
        }
        this.pk = result.pk;
        this.status = 'submitted';
      };

      Discussion.prototype.remove = function() {
        this.group.remove();
      };

      Discussion.prototype["delete"] = function() {
        var args;
        this.remove();
        args = {
          pk: this.pk
        };
        R.loader.showLoadingBar();
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'deleteDiscussion',
              args: args
            })
          }
        }).done(this.defaultCallback);
      };

      return Discussion;

    })();
    R.Discussion = Discussion;
    return Discussion;
  });

}).call(this);