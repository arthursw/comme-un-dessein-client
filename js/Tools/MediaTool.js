// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Tools/ItemTool', 'Items/Divs/Media'], function(P, R, Utils, Tool, ItemTool, Media) {
    var MediaTool;
    MediaTool = (function(superClass) {
      extend(MediaTool, superClass);

      MediaTool.label = 'Media';

      MediaTool.description = '';

      MediaTool.iconURL = 'image.png';

      MediaTool.favorite = true;

      MediaTool.category = '';

      MediaTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'default',
        icon: 'image'
      };

      MediaTool.order = 6;

      function MediaTool() {
        MediaTool.__super__.constructor.call(this, Media);
        return;
      }

      MediaTool.prototype.end = function(event, from) {
        if (from == null) {
          from = R.me;
        }
        if (MediaTool.__super__.end.call(this, event, from)) {
          Media.initialize(R.currentPaths[from].bounds);
          delete R.currentPaths[from];
        }
      };

      return MediaTool;

    })(ItemTool);
    R.Tools.Media = MediaTool;
    return MediaTool;
  });

}).call(this);
