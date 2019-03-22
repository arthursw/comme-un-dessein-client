// Generated by CoffeeScript 1.12.7
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Tools/ItemTool', 'Items/Divs/Text'], function(P, R, Utils, Tool, ItemTool, Text) {
    var TextTool;
    TextTool = (function(superClass) {
      extend(TextTool, superClass);

      TextTool.label = 'Text';

      TextTool.description = '';

      TextTool.iconURL = 'text.png';

      TextTool.cursor = {
        position: {
          x: 0,
          y: 0
        },
        name: 'crosshair'
      };

      TextTool.order = 5;

      function TextTool() {
        TextTool.__super__.constructor.call(this, Text);
        return;
      }

      TextTool.prototype.end = function(event, from) {
        var text;
        if (from == null) {
          from = R.me;
        }
        if (TextTool.__super__.end.call(this, event, from)) {
          text = new Text(R.currentPaths[from].bounds);
          text.finish();
          if (!text.group) {
            return;
          }
          text.select();
          text.save(true);
          delete R.currentPaths[from];
        }
      };

      return TextTool;

    })(ItemTool);
    R.Tools.Text = TextTool;
    return TextTool;
  });

}).call(this);
