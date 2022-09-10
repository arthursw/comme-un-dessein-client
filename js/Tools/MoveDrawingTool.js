// Generated by CoffeeScript 1.10.0
(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(['paper', 'R', 'Utils/Utils', 'Tools/Tool', 'Commands/Command'], function(P, R, Utils, Tool, Command) {
    var MoveDrawingTool;
    MoveDrawingTool = (function(superClass) {
      extend(MoveDrawingTool, superClass);

      MoveDrawingTool.label = 'Move drawing';

      MoveDrawingTool.description = '';

      MoveDrawingTool.iconURL = 'new 1/Move.svg';

      MoveDrawingTool.favorite = true;

      MoveDrawingTool.category = '';

      MoveDrawingTool.cursor = {
        position: {
          x: 16,
          y: 16
        },
        name: 'move'
      };

      MoveDrawingTool.buttonClasses = 'dark';

      function MoveDrawingTool() {
        MoveDrawingTool.__super__.constructor.call(this, true);
        this.prevPoint = {
          x: 0,
          y: 0
        };
        this.dragging = false;
        return;
      }

      MoveDrawingTool.prototype.select = function(deselectItems, updateParameters, forceSelect, selectedBy) {
        var ref;
        if (deselectItems == null) {
          deselectItems = false;
        }
        if (updateParameters == null) {
          updateParameters = true;
        }
        if (forceSelect == null) {
          forceSelect = false;
        }
        if (selectedBy == null) {
          selectedBy = 'default';
        }
        MoveDrawingTool.__super__.select.call(this, deselectItems, updateParameters, selectedBy);
        if ((ref = R.tracer) != null) {
          ref.hide();
        }
      };

      MoveDrawingTool.prototype.deselect = function() {
        MoveDrawingTool.__super__.deselect.call(this);
      };

      MoveDrawingTool.prototype.begin = function(event) {
        var drawing;
        drawing = !this.moveSelectedDrawing ? R.Drawing.getDraft() : R.s;
        this.duplicateData = drawing != null ? drawing.getDuplicateData() : void 0;
        if (drawing != null) {
          this.dragging = true;
        }
        if (R.useSVG && (drawing.svg != null)) {
          drawing.svg.remove();
          drawing.svg = null;
        }
      };

      MoveDrawingTool.prototype.update = function(event) {
        var drawing, ref;
        if (this.dragging) {
          drawing = !this.moveSelectedDrawing ? R.Drawing.getDraft() : R.s;
          if ((drawing != null) && (drawing.rectangle != null) && ((ref = drawing.group) != null ? ref.children.length : void 0) > 0) {
            drawing.rectangle.x += event.delta.x;
            drawing.rectangle.y += event.delta.y;
            drawing.group.position.x += event.delta.x;
            drawing.group.position.y += event.delta.y;
            R.tools.select.updateSelectionRectangle();
          }
        }
      };

      MoveDrawingTool.prototype.end = function(moved) {
        var drawing, modifyDrawingCommand;
        this.dragging = false;
        drawing = !this.moveSelectedDrawing ? R.Drawing.getDraft() : R.s;
        if (drawing != null) {
          R.tools.select.updateSelectionRectangle();
          if (this.duplicateData != null) {
            if (!this.moveSelectedDrawing) {
              modifyDrawingCommand = new Command.ModifyDrawing(drawing, this.duplicateData);
              R.commandManager.add(modifyDrawingCommand, false);
            }
          }
          drawing.updatePaths(this.moveSelectedDrawing);
        }
      };

      return MoveDrawingTool;

    })(Tool);
    R.Tools.MoveDrawing = MoveDrawingTool;
    return MoveDrawingTool;
  });

}).call(this);
