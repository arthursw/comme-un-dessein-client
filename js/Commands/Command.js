// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  define(['paper', 'R', 'Utils/Utils', 'UI/Controllers/ControllerManager'], function(P, R, Utils, ControllerManager) {
    var AddPointCommand, Command, CreateItemCommand, CreateItemsCommand, DeferredCommand, DeleteItemCommand, DeleteItemsCommand, DeletePointCommand, DeselectCommand, DuplicateItemCommand, ItemCommand, ItemsCommand, ModifyControlPathCommand, ModifyPointCommand, ModifyPointTypeCommand, ModifySpeedCommand, ModifyTextCommand, MoveViewCommand, RotateCommand, ScaleCommand, SelectCommand, SelectionRectangleCommand, SetParameterCommand, TranslateCommand;
    Command = (function() {
      function Command(name) {
        this.click = bind(this.click, this);
        this.name = name;
        this.liJ = $("<li>").text(name);
        this.liJ.click(this.click);
        this.id = Math.random();
        return;
      }

      Command.prototype.superDo = function() {
        this.done = true;
        this.liJ.addClass('done');
      };

      Command.prototype.superUndo = function() {
        this.done = false;
        this.liJ.removeClass('done');
      };

      Command.prototype["do"] = function() {
        this.superDo();
      };

      Command.prototype.undo = function() {
        this.superUndo();
      };

      Command.prototype.click = function() {
        R.commandManager.commandClicked(this);
      };

      Command.prototype.toggle = function() {
        console.log((this.done ? 'undo' : 'do') + ' command: ' + this.name);
        if (this.done) {
          return this.undo();
        } else {
          return this["do"]();
        }
      };

      Command.prototype["delete"] = function() {
        this.liJ.remove();
      };

      Command.prototype.begin = function() {};

      Command.prototype.update = function() {};

      Command.prototype.end = function() {
        this.superDo();
      };

      return Command;

    })();
    ItemsCommand = (function(superClass) {
      extend(ItemsCommand, superClass);

      function ItemsCommand(name, items) {
        ItemsCommand.__super__.constructor.call(this, name);
        this.items = this.mapItems(items);
        return;
      }

      ItemsCommand.prototype.mapItems = function(items) {
        var item, j, len, map;
        map = {};
        for (j = 0, len = items.length; j < len; j++) {
          item = items[j];
          map[item.id] = item;
        }
        return map;
      };

      ItemsCommand.prototype.apply = function(method, args) {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item[method].apply(item, args);
        }
      };

      ItemsCommand.prototype.call = function() {
        var args, method;
        method = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        this.apply(method, args);
      };

      ItemsCommand.prototype.update = function() {};

      ItemsCommand.prototype.end = function() {
        if (this.positionIsValid()) {
          ItemsCommand.__super__.end.call(this);
        } else {
          this.undo();
        }
      };

      ItemsCommand.prototype.positionIsValid = function() {
        var id, item, ref;
        if (this.constructor.disablePositionCheck) {
          return true;
        }
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          if (!item.validatePosition()) {
            return false;
          }
        }
        return true;
      };

      ItemsCommand.prototype.unloadItem = function(item) {
        delete this.items[item.id];
      };

      ItemsCommand.prototype.loadItem = function(item) {
        this.items[item.id] = item;
      };

      ItemsCommand.prototype.resurrectItem = function(item) {
        this.items[item.id] = item;
      };

      ItemsCommand.prototype.itemSaved = function(item) {};

      ItemsCommand.prototype.itemDeleted = function(item) {};

      ItemsCommand.prototype["delete"] = function() {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          Utils.Array.remove(R.commandManager.itemToCommands[id], this);
        }
        ItemsCommand.__super__["delete"].call(this);
      };

      return ItemsCommand;

    })(Command);
    ItemCommand = (function(superClass) {
      extend(ItemCommand, superClass);

      function ItemCommand(name, items) {
        items = Utils.Array.isArray(items) ? items : [items];
        this.item = items[0];
        ItemCommand.__super__.constructor.call(this, name, items);
        return;
      }

      ItemCommand.prototype.unloadItem = function(item) {
        this.item = null;
        ItemCommand.__super__.unloadItem.call(this, item);
      };

      ItemCommand.prototype.loadItem = function(item) {
        this.item = item;
        ItemCommand.__super__.loadItem.call(this, item);
      };

      ItemCommand.prototype.resurrectItem = function(item) {
        console.log('  - resurect item on command ' + this.name + ': ' + item.id, item);
        this.item = item;
        ItemCommand.__super__.resurrectItem.call(this, item);
      };

      return ItemCommand;

    })(ItemsCommand);
    DeferredCommand = (function(superClass) {
      extend(DeferredCommand, superClass);

      DeferredCommand.initialize = function(method) {
        this.method = method;
        this.Method = Utils.capitalizeFirstLetter(method);
        this.beginMethod = 'begin' + this.Method;
        this.updateMethod = 'update' + this.Method;
        this.endMethod = 'end' + this.Method;
      };

      function DeferredCommand(name, items) {
        DeferredCommand.__super__.constructor.call(this, name, items);
        return;
      }

      DeferredCommand.prototype.update = function() {};

      DeferredCommand.prototype.end = function() {
        DeferredCommand.__super__.end.call(this);
        if (!this.commandChanged()) {
          return;
        }
        R.commandManager.add(this);
        this.updateItems();
      };

      DeferredCommand.prototype.commandChanged = function() {};

      DeferredCommand.prototype.updateItems = function(type) {
        var args, id, item, ref;
        if (type == null) {
          type = this.updateType;
        }
        args = [];
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.addUpdateFunctionAndArguments(args, type);
        }
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'multipleCalls',
              args: {
                functionsAndArguments: args
              }
            })
          }
        }).done(this.updateCallback);
      };

      DeferredCommand.prototype.updateCallback = function(results) {
        var j, len, result;
        for (j = 0, len = results.length; j < len; j++) {
          result = results[j];
          R.loader.checkError(result);
        }
      };

      return DeferredCommand;

    })(ItemCommand);
    SelectionRectangleCommand = (function(superClass) {
      extend(SelectionRectangleCommand, superClass);

      SelectionRectangleCommand.create = function(items, state) {
        var command;
        command = new this(items);
        command.state = state;
        return command;
      };

      function SelectionRectangleCommand(items) {
        SelectionRectangleCommand.__super__.constructor.call(this, this.constructor.Method + ' items', items);
        this.updateType = this.constructor.method;
        return;
      }

      SelectionRectangleCommand.prototype.begin = function(event) {
        R.tools.select.selectionRectangle[this.constructor.beginMethod](event);
      };

      SelectionRectangleCommand.prototype.update = function(event) {
        R.tools.select.selectionRectangle[this.constructor.updateMethod](event);
        SelectionRectangleCommand.__super__.update.call(this, event);
      };

      SelectionRectangleCommand.prototype.updateSelectionRectangle = function(rotation) {
        R.tools.select.updateSelectionRectangle(rotation);
      };

      SelectionRectangleCommand.prototype.end = function(event) {
        this.state = R.tools.select.selectionRectangle[this.constructor.endMethod](event);
        SelectionRectangleCommand.__super__.end.call(this, event);
      };

      SelectionRectangleCommand.prototype["do"] = function() {
        this.apply(this.constructor.method, this.newState());
        this.updateSelectionRectangle();
        SelectionRectangleCommand.__super__["do"].call(this);
      };

      SelectionRectangleCommand.prototype.undo = function() {
        this.apply(this.constructor.method, this.previousState());
        this.updateSelectionRectangle();
        SelectionRectangleCommand.__super__.undo.call(this);
      };

      return SelectionRectangleCommand;

    })(DeferredCommand);
    ScaleCommand = (function(superClass) {
      extend(ScaleCommand, superClass);

      function ScaleCommand() {
        return ScaleCommand.__super__.constructor.apply(this, arguments);
      }

      ScaleCommand.initialize('scale');

      ScaleCommand.method = 'setRectangle';

      ScaleCommand.prototype.getItemArray = function() {
        var id, item, ref;
        if (this.itemsArray != null) {
          return this.itemsArray;
        }
        this.itemsArray = [];
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          this.itemsArray.push(item);
        }
        return this.itemsArray;
      };

      ScaleCommand.prototype["do"] = function() {
        R.SelectionRectangle.setRectangle(this.getItemArray(), this.state.previous, this.state["new"], this.state.rotation, false);
        this.updateSelectionRectangle(this.state.rotation);
        this.superDo();
      };

      ScaleCommand.prototype.undo = function() {
        R.SelectionRectangle.setRectangle(this.getItemArray(), this.state["new"], this.state.previous, this.state.rotation, false);
        this.updateSelectionRectangle(this.state.rotation);
        this.superUndo();
      };

      ScaleCommand.prototype.commandChanged = function() {
        return !this.state["new"].equals(this.state.previous);
      };

      return ScaleCommand;

    })(SelectionRectangleCommand);
    RotateCommand = (function(superClass) {
      extend(RotateCommand, superClass);

      function RotateCommand() {
        return RotateCommand.__super__.constructor.apply(this, arguments);
      }

      RotateCommand.initialize('rotate');

      RotateCommand.prototype.newState = function() {
        return [this.state.delta, this.state.center];
      };

      RotateCommand.prototype.previousState = function() {
        return [-this.state.delta, this.state.center];
      };

      RotateCommand.prototype.commandChanged = function() {
        return this.state.delta !== 0;
      };

      return RotateCommand;

    })(SelectionRectangleCommand);
    TranslateCommand = (function(superClass) {
      extend(TranslateCommand, superClass);

      function TranslateCommand() {
        return TranslateCommand.__super__.constructor.apply(this, arguments);
      }

      TranslateCommand.initialize('translate');

      TranslateCommand.prototype.newState = function() {
        return [this.state.delta];
      };

      TranslateCommand.prototype.previousState = function() {
        return [this.state.delta.multiply(-1)];
      };

      TranslateCommand.prototype.commandChanged = function() {
        return !this.state.delta.isZero();
      };

      return TranslateCommand;

    })(SelectionRectangleCommand);

    /*
    		class BeforeAfterCommand extends DeferredCommand
    
    			@initialize: (method, @name)->
    				super(method)
    				return
    
    			constructor: (name, item)->
    				super(name or @constructor.name, item)
    				@beforeArgs = @getState()
    				return
    
    			getState: ()->
    				return
    
    			update: ()->
    				@apply(@constructor.updateMethod, arguments.push(true))
    				return
    
    			commandChanged: ()->
    				for beforeArg, i in @beforeArgs
    					if beforeArg != @afterArgs[i] then return false
    				return true
    
    			do: ()->
    				@apply(@constructor.method, @afterArgs)
    				super()
    				return
    
    			undo: ()->
    				@afterArgs = @getState()
    				@apply(@constructor.method, @beforeArgs)
    				super()
    				return
     */
    ModifyPointCommand = (function(superClass) {
      extend(ModifyPointCommand, superClass);

      function ModifyPointCommand(item) {
        ModifyPointCommand.__super__.constructor.call(this, 'Modify point', item);
        this.index = this.item.selectedSegment.index;
        this.previousPoint = this.getPoint();
        this.updateType = 'points';
        return;
      }

      ModifyPointCommand.prototype.update = function(event) {
        this.item.updateModifyPoint(event);
      };

      ModifyPointCommand.prototype.end = function(event) {
        this.item.endModifyPoint(event);
        this.newPoint = this.getPoint();
        ModifyPointCommand.__super__.end.call(this, event);
      };

      ModifyPointCommand.prototype["do"] = function() {
        this.item.modifyPoint.apply(this.item, this.newPoint);
        ModifyPointCommand.__super__["do"].call(this);
      };

      ModifyPointCommand.prototype.undo = function() {
        this.item.modifyPoint.apply(this.item, this.previousPoint);
        ModifyPointCommand.__super__.undo.call(this);
      };

      ModifyPointCommand.prototype.getPoint = function() {
        var segment;
        segment = this.item.controlPath.segments[this.index];
        return [segment.index, segment.point.clone(), segment.handleIn.clone(), segment.handleOut.clone(), true];
      };

      ModifyPointCommand.prototype.commandChanged = function() {
        var i, j;
        for (i = j = 1; j <= 3; i = ++j) {
          if (!this.previousPoint[i].equals(this.newPoint[i])) {
            return true;
          }
        }
        return false;
      };

      return ModifyPointCommand;

    })(DeferredCommand);
    ModifySpeedCommand = (function(superClass) {
      extend(ModifySpeedCommand, superClass);

      function ModifySpeedCommand(item) {
        ModifySpeedCommand.__super__.constructor.call(this, 'Modify speed', item);
        this.previousSpeeds = this.item.speeds.slice();
        this.updateType = 'speed';
        return;
      }

      ModifySpeedCommand.prototype.update = function(event) {
        this.item.updateModifySpeed(event);
      };

      ModifySpeedCommand.prototype.end = function(event) {
        this.item.endModifySpeed(event);
        ModifySpeedCommand.__super__.end.call(this, event);
      };

      ModifySpeedCommand.prototype["do"] = function() {
        this.item.modifySpeed(this.newSpeeds, true);
        this.updateItems('speed');
        ModifySpeedCommand.__super__["do"].call(this);
      };

      ModifySpeedCommand.prototype.undo = function() {
        if (this.newSpeeds == null) {
          this.newSpeeds = this.item.speeds.slice();
        }
        this.item.modifySpeed(this.previousSpeeds, true);
        this.updateItems('speed');
        ModifySpeedCommand.__super__.undo.call(this);
      };

      ModifySpeedCommand.prototype.commandChanged = function() {
        return true;
      };

      return ModifySpeedCommand;

    })(DeferredCommand);
    SetParameterCommand = (function(superClass) {
      extend(SetParameterCommand, superClass);

      function SetParameterCommand(items, args) {
        var id, item, ref;
        this.name = args[0];
        this.previousValue = args[1];
        SetParameterCommand.__super__.constructor.call(this, 'Change item parameter "' + this.name + '"', items);
        this.updateType = 'parameters';
        this.previousValues = {};
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          this.previousValues[id] = item.data[this.name];
        }
        return;
      }

      SetParameterCommand.prototype["do"] = function() {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.setParameter(this.name, this.newValue);
        }
        R.controllerManager.updateController(this.name, this.newValue);
        this.updateItems(this.name);
        SetParameterCommand.__super__["do"].call(this);
      };

      SetParameterCommand.prototype.undo = function() {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.setParameter(this.name, this.previousValues[id]);
        }
        R.controllerManager.updateController(this.name, this.previousValue);
        this.updateItems(this.name);
        SetParameterCommand.__super__.undo.call(this);
      };

      SetParameterCommand.prototype.update = function(name, value) {
        var id, item, ref;
        this.newValue = value;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.setParameter(name, value);
        }
      };

      SetParameterCommand.prototype.commandChanged = function() {
        return true;
      };

      return SetParameterCommand;

    })(DeferredCommand);
    AddPointCommand = (function(superClass) {
      extend(AddPointCommand, superClass);

      function AddPointCommand(item, location, name) {
        this.location = location;
        if (name == null) {
          name = 'Add point on item';
        }
        AddPointCommand.__super__.constructor.call(this, name, [item]);
        return;
      }

      AddPointCommand.prototype.addPoint = function(update) {
        if (update == null) {
          update = true;
        }
        this.segment = this.item.addPointAt(this.location, update);
      };

      AddPointCommand.prototype.deletePoint = function() {
        this.location = this.item.deletePoint(this.segment);
      };

      AddPointCommand.prototype["do"] = function() {
        this.addPoint();
        AddPointCommand.__super__["do"].call(this);
      };

      AddPointCommand.prototype.undo = function() {
        this.deletePoint();
        AddPointCommand.__super__.undo.call(this);
      };

      return AddPointCommand;

    })(ItemCommand);
    DeletePointCommand = (function(superClass) {
      extend(DeletePointCommand, superClass);

      function DeletePointCommand(item, segment1) {
        this.segment = segment1;
        DeletePointCommand.__super__.constructor.call(this, item, this.segment, 'Delete point on item');
      }

      DeletePointCommand.prototype["do"] = function() {
        this.previousPosition = new P.Point(this.segment.point);
        this.previousHandleIn = new P.Point(this.segment.handleIn);
        this.previousHandleOut = new P.Point(this.segment.handleOut);
        this.deletePoint();
        this.superDo();
      };

      DeletePointCommand.prototype.undo = function() {
        this.addPoint(false);
        this.item.modifyPoint(this.segment, this.previousPosition, this.previousHandleIn, this.previousHandleOut);
        this.superUndo();
      };

      return DeletePointCommand;

    })(AddPointCommand);
    ModifyPointTypeCommand = (function(superClass) {
      extend(ModifyPointTypeCommand, superClass);

      function ModifyPointTypeCommand(item, segment1, rtype) {
        this.segment = segment1;
        this.rtype = rtype;
        this.previousRType = this.segment.rtype;
        this.previousPosition = new P.Point(this.segment.point);
        this.previousHandleIn = new P.Point(this.segment.handleIn);
        this.previousHandleOut = new P.Point(this.segment.handleOut);
        ModifyPointTypeCommand.__super__.constructor.call(this, 'Change point type on item', [item]);
        return;
      }

      ModifyPointTypeCommand.prototype["do"] = function() {
        this.item.modifyPointType(this.segment, this.rtype);
        ModifyPointTypeCommand.__super__["do"].call(this);
      };

      ModifyPointTypeCommand.prototype.undo = function() {
        this.item.modifyPointType(this.segment, this.previousRType, true, false);
        this.item.modifyPoint(this.segment, this.previousPosition, this.previousHandleIn, this.previousHandleOut);
        ModifyPointTypeCommand.__super__.undo.call(this);
      };

      return ModifyPointTypeCommand;

    })(ItemCommand);

    /* --- Custom command for all kinds of command which modifiy the path --- */
    ModifyControlPathCommand = (function(superClass) {
      extend(ModifyControlPathCommand, superClass);

      function ModifyControlPathCommand(item, previousPointsAndPlanet, newPointsAndPlanet) {
        this.previousPointsAndPlanet = previousPointsAndPlanet;
        this.newPointsAndPlanet = newPointsAndPlanet;
        ModifyControlPathCommand.__super__.constructor.call(this, 'Modify path', item);
        this.superDo();
        return;
      }

      ModifyControlPathCommand.prototype["do"] = function() {
        this.item.modifyControlPath(this.newPointsAndPlanet);
        ModifyControlPathCommand.__super__["do"].call(this);
      };

      ModifyControlPathCommand.prototype.undo = function() {
        this.item.modifyControlPath(this.previousPointsAndPlanet);
        ModifyControlPathCommand.__super__.undo.call(this);
      };

      return ModifyControlPathCommand;

    })(ItemCommand);
    MoveViewCommand = (function(superClass) {
      extend(MoveViewCommand, superClass);

      function MoveViewCommand(previousPosition, newPosition) {
        this.previousPosition = previousPosition;
        this.newPosition = newPosition;
        MoveViewCommand.__super__.constructor.call(this, "Move view");
        this.superDo();
        return;
      }

      MoveViewCommand.prototype["do"] = function() {
        var somethingToLoad;
        somethingToLoad = R.view.moveBy(this.newPosition.subtract(this.previousPosition), false);
        MoveViewCommand.__super__["do"].call(this);
        return somethingToLoad;
      };

      MoveViewCommand.prototype.undo = function() {
        var somethingToLoad;
        somethingToLoad = R.view.moveBy(this.previousPosition.subtract(this.newPosition), false);
        MoveViewCommand.__super__.undo.call(this);
        return somethingToLoad;
      };

      return MoveViewCommand;

    })(Command);
    SelectCommand = (function(superClass) {
      extend(SelectCommand, superClass);

      function SelectCommand(items, name, updateOptions) {
        this.updateOptions = updateOptions != null ? updateOptions : true;
        SelectCommand.__super__.constructor.call(this, name || "Select items", items);
        return;
      }

      SelectCommand.prototype.selectItems = function() {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.select(this.updateOptions);
        }
      };

      SelectCommand.prototype.deselectItems = function() {
        var id, item, ref;
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          item.deselect(this.updateOptions);
        }
      };

      SelectCommand.prototype["do"] = function() {
        this.selectItems();
        SelectCommand.__super__["do"].call(this);
      };

      SelectCommand.prototype.undo = function() {
        this.deselectItems();
        SelectCommand.__super__.undo.call(this);
      };

      return SelectCommand;

    })(ItemsCommand);
    DeselectCommand = (function(superClass) {
      extend(DeselectCommand, superClass);

      function DeselectCommand(items, updateOptions) {
        this.updateOptions = updateOptions != null ? updateOptions : true;
        DeselectCommand.__super__.constructor.call(this, items || R.selectedItems.slice(), 'Deselect items', this.updateOptions);
        return;
      }

      DeselectCommand.prototype["do"] = function() {
        this.deselectItems();
        this.superDo();
      };

      DeselectCommand.prototype.undo = function() {
        this.selectItems();
        this.superUndo();
      };

      return DeselectCommand;

    })(SelectCommand);
    CreateItemCommand = (function(superClass) {
      extend(CreateItemCommand, superClass);

      function CreateItemCommand(item, name) {
        if (name == null) {
          name = 'Create item';
        }
        this.itemConstructor = item.constructor;
        CreateItemCommand.__super__.constructor.call(this, name, item);
        this.superDo();
        return;
      }

      CreateItemCommand.prototype.duplicateItem = function() {
        this.item = this.itemConstructor.create(this.duplicateData);
        this.waitingSaveCallback = this.item.id;
        R.commandManager.resurrectItem(this.duplicateData.id, this.item);
        this.item.select();
        return true;
      };

      CreateItemCommand.prototype.deleteItem = function() {
        this.duplicateData = this.item.getDuplicateData();
        this.waitingDeleteCallback = this.item.id;
        this.item["delete"]();
        this.item = null;
        return true;
      };

      CreateItemCommand.prototype["do"] = function() {
        var deffered;
        deffered = this.duplicateItem();
        CreateItemCommand.__super__["do"].call(this);
        return deffered;
      };

      CreateItemCommand.prototype.undo = function() {
        var deffered;
        deffered = this.deleteItem();
        CreateItemCommand.__super__.undo.call(this);
        return deffered;
      };

      CreateItemCommand.prototype.itemSaved = function(item) {
        var event;
        if (item.id === this.waitingSaveCallback) {
          event = new CustomEvent('command executed', {
            detail: this
          });
          Utils.callNextFrame((function() {
            return document.dispatchEvent(event);
          }), 'dispatch command executed');
          this.waitingSaveCallback = null;
        }
      };

      CreateItemCommand.prototype.itemDeleted = function(item) {
        var event;
        if (item.id === this.waitingDeleteCallback) {
          event = new CustomEvent('command executed', {
            detail: this
          });
          Utils.callNextFrame((function() {
            return document.dispatchEvent(event);
          }), 'dispatch command executed');
          this.waitingDeleteCallback = null;
        }
      };

      return CreateItemCommand;

    })(ItemCommand);
    DeleteItemCommand = (function(superClass) {
      extend(DeleteItemCommand, superClass);

      function DeleteItemCommand(item) {
        DeleteItemCommand.__super__.constructor.call(this, item, 'Delete item');
      }

      DeleteItemCommand.prototype["do"] = function() {
        var deferred;
        deferred = this.deleteItem();
        this.superDo();
        return deferred;
      };

      DeleteItemCommand.prototype.undo = function() {
        var deferred;
        deferred = this.duplicateItem();
        this.superUndo();
        return deferred;
      };

      return DeleteItemCommand;

    })(CreateItemCommand);
    CreateItemsCommand = (function(superClass) {
      extend(CreateItemsCommand, superClass);

      function CreateItemsCommand(items, itemResurectors, name) {
        this.itemResurectors = itemResurectors;
        if (name == null) {
          name = 'Create items';
        }
        CreateItemsCommand.__super__.constructor.call(this, name, items);
        this.superDo();
        return;
      }

      CreateItemsCommand.prototype.duplicateItems = function() {
        var id, item, itemResurector, ref;
        this.waitingSaveCallbacks = [];
        ref = this.itemResurectors;
        for (id in ref) {
          itemResurector = ref[id];
          item = itemResurector.constructor.create(itemResurector.data);
          this.items[itemResurector.data.id] = item;
          R.commandManager.resurrectItem(itemResurector.data.id, item);
          item.select();
          this.waitingSaveCallbacks.push(item.id);
        }
        return this.waitingSaveCallbacks.length > 0;
      };

      CreateItemsCommand.prototype.deleteItems = function() {
        var id, idsToRemove, item, j, len, ref;
        this.itemResurectors = {};
        idsToRemove = [];
        this.waitingDeleteCallbacks = [];
        ref = this.items;
        for (id in ref) {
          item = ref[id];
          this.itemResurectors[id] = {
            data: item.getDuplicateData(),
            constructor: item.constructor
          };
          this.waitingDeleteCallbacks.push(item.id);
          item["delete"]();
          idsToRemove.push(id);
        }
        for (j = 0, len = idsToRemove.length; j < len; j++) {
          id = idsToRemove[j];
          delete this.items[id];
        }
        return this.waitingDeleteCallbacks.length > 0;
      };

      CreateItemsCommand.prototype["do"] = function() {
        var deferred;
        deferred = this.duplicateItems();
        CreateItemsCommand.__super__["do"].call(this);
        return deferred;
      };

      CreateItemsCommand.prototype.undo = function() {
        var deferred;
        deferred = this.deleteItems();
        CreateItemsCommand.__super__.undo.call(this);
        return deferred;
      };

      CreateItemsCommand.prototype.itemSaved = function(item) {
        var event, index;
        if (this.waitingSaveCallbacks == null) {
          return;
        }
        index = this.waitingSaveCallbacks.indexOf(item.id);
        if (index >= 0) {
          this.waitingSaveCallbacks.splice(index, 1);
        }
        if (this.waitingSaveCallbacks.length === 0) {
          event = new CustomEvent('command executed', {
            detail: this
          });
          Utils.callNextFrame((function() {
            return document.dispatchEvent(event);
          }), 'dispatch command executed');
        }
      };

      CreateItemsCommand.prototype.itemDeleted = function(item) {
        var event, index;
        if (this.waitingDeleteCallbacks == null) {
          return;
        }
        index = this.waitingDeleteCallbacks.indexOf(item.id);
        if (index >= 0) {
          this.waitingDeleteCallbacks.splice(index, 1);
        }
        if (this.waitingDeleteCallbacks.length === 0) {
          event = new CustomEvent('command executed', {
            detail: this
          });
          Utils.callNextFrame((function() {
            return document.dispatchEvent(event);
          }), 'dispatch command executed');
        }
      };

      return CreateItemsCommand;

    })(ItemsCommand);
    DeleteItemsCommand = (function(superClass) {
      extend(DeleteItemsCommand, superClass);

      function DeleteItemsCommand(items, itemResurectors) {
        this.itemResurectors = itemResurectors;
        DeleteItemsCommand.__super__.constructor.call(this, items, this.itemResurectors, 'Delete items');
      }

      DeleteItemsCommand.prototype["do"] = function() {
        this.deleteItems();
        this.superDo();
        return true;
      };

      DeleteItemsCommand.prototype.undo = function() {
        this.duplicateItems();
        this.superUndo();
        return true;
      };

      return DeleteItemsCommand;

    })(CreateItemsCommand);
    DuplicateItemCommand = (function(superClass) {
      extend(DuplicateItemCommand, superClass);

      function DuplicateItemCommand(item) {
        this.duplicateData = item.getDuplicateData();
        DuplicateItemCommand.__super__.constructor.call(this, item, 'Duplicate item');
      }

      return DuplicateItemCommand;

    })(CreateItemCommand);
    ModifyTextCommand = (function(superClass) {
      extend(ModifyTextCommand, superClass);

      function ModifyTextCommand(items, args) {
        ModifyTextCommand.__super__.constructor.call(this, "Change text", items);
        this.newText = args[0];
        this.previousText = this.item.data.message;
        return;
      }

      ModifyTextCommand.prototype["do"] = function() {
        this.item.data.message = this.newText;
        this.item.contentJ.val(this.newText);
        ModifyTextCommand.__super__["do"].call(this);
      };

      ModifyTextCommand.prototype.undo = function() {
        this.item.data.message = this.previousText;
        this.item.contentJ.val(this.previousText);
        ModifyTextCommand.__super__.undo.call(this);
      };

      ModifyTextCommand.prototype.update = function(newText) {
        this.newText = newText;
        this.item.setText(this.newText, false);
      };

      ModifyTextCommand.prototype.commandChanged = function() {
        return this.newText !== this.previousText;
      };

      return ModifyTextCommand;

    })(DeferredCommand);
    R.Command = Command;
    Command.Scale = ScaleCommand;
    Command.Rotate = RotateCommand;
    Command.Translate = TranslateCommand;
    Command.ModifyPoint = ModifyPointCommand;
    Command.ModifySpeed = ModifySpeedCommand;
    Command.AddPoint = AddPointCommand;
    Command.DeletePoint = DeletePointCommand;
    Command.ModifyPointType = ModifyPointTypeCommand;
    Command.ModifyControlPath = ModifyControlPathCommand;
    Command.SetParameter = SetParameterCommand;
    Command.ModifyText = ModifyTextCommand;
    Command.CreateItem = CreateItemCommand;
    Command.DeleteItem = DeleteItemCommand;
    Command.CreateItems = CreateItemsCommand;
    Command.DeleteItems = DeleteItemsCommand;
    Command.DuplicateItem = DuplicateItemCommand;
    Command.Select = SelectCommand;
    Command.Deselect = DeselectCommand;
    Command.MoveView = MoveViewCommand;
    return Command;
  });

}).call(this);
