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
        var draft;
        draft = R.Drawing.getDraft();
        this.duplicateData = draft != null ? draft.getDuplicateData() : void 0;
        if (draft != null) {
          this.dragging = true;
        }
      };

      MoveDrawingTool.prototype.update = function(event) {
        var draft;
        if (this.dragging) {
          draft = R.Drawing.getDraft();
          if (draft != null) {
            draft.rectangle.x += event.delta.x;
            draft.rectangle.y += event.delta.y;
            draft.group.position.x += event.delta.x;
            draft.group.position.y += event.delta.y;
          }
        }
      };

      MoveDrawingTool.prototype.end = function(moved) {
        var draft, modifyDrawingCommand;
        this.dragging = false;
        draft = R.Drawing.getDraft();
        if (draft != null) {
          if (this.duplicateData != null) {
            modifyDrawingCommand = new Command.ModifyDrawing(draft, this.duplicateData);
            R.commandManager.add(modifyDrawingCommand, false);
          }
          draft.updatePaths();
        }
      };

      return MoveDrawingTool;

    })(Tool);
    R.Tools.MoveDrawing = MoveDrawingTool;
    return MoveDrawingTool;
  });

}).call(this);