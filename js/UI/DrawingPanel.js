// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'i18next'], function(P, R, Utils, Item, i18next) {
    var DrawingPanel;
    DrawingPanel = (function() {
      function DrawingPanel() {
        this.cancelDrawing = bind(this.cancelDrawing, this);
        this.modifyDrawing = bind(this.modifyDrawing, this);
        this.submitDrawing = bind(this.submitDrawing, this);
        this.voteDown = bind(this.voteDown, this);
        this.voteUp = bind(this.voteUp, this);
        this.vote = bind(this.vote, this);
        this.voteCallback = bind(this.voteCallback, this);
        this.submitDrawingClicked = bind(this.submitDrawingClicked, this);
        this.submitDrawingClickedCallback = bind(this.submitDrawingClickedCallback, this);
        this.beginDrawingClicked = bind(this.beginDrawingClicked, this);
        this.showContent = bind(this.showContent, this);
        this.showLoadAnimation = bind(this.showLoadAnimation, this);
        this.close = bind(this.close, this);
        this.updateSelection = bind(this.updateSelection, this);
        this.onMouseUp = bind(this.onMouseUp, this);
        this.resize = bind(this.resize, this);
        this.setFullSize = bind(this.setFullSize, this);
        this.setHalfSize = bind(this.setHalfSize, this);
        this.onHandleDown = bind(this.onHandleDown, this);
        var closeBtnJ, descriptionJ, handleJ, runBtnJ;
        this.beginDrawingBtnJ = $('button.begin-drawing');
        this.beginDrawingBtnJ.click(this.beginDrawingClicked);
        this.submitDrawingBtnJ = $('button.submit-drawing');
        this.submitDrawingBtnJ.click(this.submitDrawingClicked);
        this.drawingPanelJ = $("#drawingPanel");
        this.drawingPanelJ.bind("transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", this.resize);
        handleJ = this.drawingPanelJ.find(".panel-handle");
        handleJ.mousedown(this.onHandleDown);
        handleJ.find('.handle-right').click(this.setHalfSize);
        handleJ.find('.handle-left').click(this.setFullSize);
        this.drawingPanelTitleJ = this.drawingPanelJ.find('.drawing-panel-title');
        this.fileNameJ = this.drawingPanelJ.find(".header .fileName input");
        this.linkFileInputJ = this.drawingPanelJ.find("input.link-file");
        this.linkFileInputJ.change(this.linkFile);
        closeBtnJ = this.drawingPanelJ.find("button.close-panel");
        closeBtnJ.click(this.close);
        this.votesJ = this.drawingPanelJ.find('.votes');
        runBtnJ = this.drawingPanelJ.find("button.submit.run");
        runBtnJ.click(this.runFile);
        this.voteUpBtnJ = this.drawingPanelJ.find('.vote-up');
        this.voteUpBtnJ.click(this.voteUp);
        this.voteDownBtnJ = this.drawingPanelJ.find('.vote-down');
        this.voteDownBtnJ.click(this.voteDown);
        this.submitBtnJ = this.drawingPanelJ.find('.action-buttons button.submit');
        this.modifyBtnJ = this.drawingPanelJ.find('.action-buttons button.modify');
        this.cancelBtnJ = this.drawingPanelJ.find('.action-buttons button.cancel');
        this.submitBtnJ.click(this.submitDrawing);
        this.modifyBtnJ.click(this.modifyDrawing);
        this.cancelBtnJ.click(this.cancelDrawing);
        this.contentJ = this.drawingPanelJ.find('.content-container');
        descriptionJ = this.contentJ.find('#drawing-description');
        descriptionJ.keydown((function(_this) {
          return function(event) {
            switch (Utils.specialKeys[event.keyCode]) {
              case 'enter':
                if (event.metaKey || event.ctrlKey) {
                  _this.submitDrawing();
                }
            }
          };
        })(this));
        return;
      }


      /* mouse interaction */

      DrawingPanel.prototype.onHandleDown = function() {
        this.draggingEditor = true;
      };

      DrawingPanel.prototype.setHalfSize = function() {
        this.drawingPanelJ.css({
          left: '70%'
        });
        this.resize();
      };

      DrawingPanel.prototype.setFullSize = function() {
        this.drawingPanelJ.css({
          left: '265px'
        });
        this.resize();
      };

      DrawingPanel.prototype.resize = function() {};

      DrawingPanel.prototype.onMouseMove = function(event) {
        var point;
        if (this.draggingEditor) {
          point = Utils.Event.GetPoint(event);
          this.drawingPanelJ.css({
            left: Math.max(265, point.x)
          });
        }
      };

      DrawingPanel.prototype.onMouseUp = function(event) {
        this.draggingEditor = false;
      };

      DrawingPanel.prototype.updateSelection = function() {
        var drawing;
        if (R.selectedItems.length === 1) {
          this.showLoadAnimation();
          this.open();
          drawing = R.selectedItems[0];
          if (drawing.pk != null) {
            delete drawing.selectAfterSave;
            drawing.updateDrawingPanel();
          } else {
            drawing.selectAfterSave = true;
          }
        } else {
          this.showSelectedDrawings();
          this.open();
        }
      };

      DrawingPanel.prototype.selectionChanged = function() {
        Utils.callNextFrame(this.updateSelection, 'update drawing selection');
      };

      DrawingPanel.prototype.deselectDrawing = function(drawing) {
        if (R.selectedItems.length === 0) {
          this.close();
        }
        if (drawing === this.currentDrawing) {
          this.currentDrawing = null;
        }
      };


      /* open close */

      DrawingPanel.prototype.isOpened = function() {
        return this.drawingPanelJ.hasClass('visible');
      };

      DrawingPanel.prototype.open = function() {
        this.drawingPanelJ.show();
        this.drawingPanelJ.addClass('visible');
      };

      DrawingPanel.prototype.close = function(removeDrawingIfNotSaved) {
        if (removeDrawingIfNotSaved == null) {
          removeDrawingIfNotSaved = true;
        }
        if ((this.currentDrawing != null) && (this.currentDrawing.pk == null)) {
          if (removeDrawingIfNotSaved) {
            this.currentDrawing.removeChildren();
            this.currentDrawing.remove();
          }
        }
        this.drawingPanelJ.hide();
        this.drawingPanelJ.removeClass('visible');
        if (R.selectedItems.length > 0) {
          R.tools.select.deselectAll();
        }
      };


      /* set drawing */

      DrawingPanel.prototype.createSelectionLi = function(selectedDrawingsJ, listJ, item) {
        var contentJ, deselectBtnJ, deselectIconJ, liJ, thumbnailJ, titleJ;
        liJ = $('<li>');
        liJ.addClass('drawing-selection cd-button');
        liJ.addClass('cd-row');
        contentJ = $('<div>');
        contentJ.addClass('cd-column cd-grow');
        titleJ = $('<h4>');
        titleJ.addClass('cd-grow cd-center');
        titleJ.html(item.title);
        thumbnailJ = $('<div>');
        thumbnailJ.addClass('thumbnail drawing-thumbnail');
        thumbnailJ.append(this.getDrawingImage(item));
        deselectBtnJ = $('<button>');
        deselectBtnJ.addClass('btn btn-default icon-only transparent');
        deselectIconJ = $('<span>').addClass('glyphicon glyphicon-remove');
        deselectBtnJ.click(function(event) {
          item.deselect();
          liJ.remove();
          event.preventDefault();
          event.stopPropagation();
          return -1;
        });
        deselectBtnJ.append(deselectIconJ);
        contentJ.append(titleJ);
        contentJ.append(thumbnailJ);
        liJ.append(contentJ);
        liJ.append(deselectBtnJ);
        liJ.click(function() {
          selectedDrawingsJ.hide();
          listJ.empty();
          R.tools.select.deselectAll();
          item.select();
        });
        listJ.append(liJ);
      };

      DrawingPanel.prototype.showSelectedDrawings = function() {
        var item, j, len, listJ, ref, selectedDrawingsJ;
        this.drawingPanelTitleJ.attr('data-i18n', 'Select a single drawing').text(i18next.t('Select a single drawing'));
        this.drawingPanelJ.find('.content-container').children().hide();
        selectedDrawingsJ = this.drawingPanelJ.find('.selected-drawings');
        selectedDrawingsJ.show();
        listJ = selectedDrawingsJ.find('ul.drawing-list');
        listJ.empty();
        ref = R.selectedItems;
        for (j = 0, len = ref.length; j < len; j++) {
          item = ref[j];
          if (item instanceof Item.Drawing) {
            this.createSelectionLi(selectedDrawingsJ, listJ, item);
          }
        }
      };

      DrawingPanel.prototype.showLoadAnimation = function() {
        this.drawingPanelJ.find('.loading-animation').show();
        this.drawingPanelJ.find('.content').hide();
        this.drawingPanelJ.find('.selected-drawings').hide();
      };

      DrawingPanel.prototype.showContent = function() {
        this.drawingPanelJ.find('.content').show();
        this.drawingPanelJ.find('.selected-drawings').hide();
        this.drawingPanelJ.find('.loading-animation').hide();
      };

      DrawingPanel.prototype.showSubmitDrawing = function() {
        this.hideBeginDrawing();
        this.submitDrawingBtnJ.removeClass('hidden');
        this.submitDrawingBtnJ.show();
        this.contentJ.find('#drawing-title').focus();
      };

      DrawingPanel.prototype.hideSubmitDrawing = function() {
        this.submitDrawingBtnJ.hide();
      };

      DrawingPanel.prototype.showBeginDrawing = function() {
        this.beginDrawingBtnJ.show();
      };

      DrawingPanel.prototype.hideBeginDrawing = function() {
        this.beginDrawingBtnJ.hide();
      };

      DrawingPanel.prototype.beginDrawingClicked = function() {
        var id, item, ref;
        R.toolManager.enterDrawingMode();
        this.beginDrawingBtnJ.hide();
        ref = R.items;
        for (id in ref) {
          item = ref[id];
          if (item instanceof Item.Path) {
            if (item.owner === R.me && item.drawingId === null) {
              this.showSubmitDrawing();
              return;
            }
          }
        }
      };

      DrawingPanel.prototype.getDrawingImage = function(drawing) {
        var image, raster;
        image = new Image();
        raster = drawing.getRaster();
        if (raster != null) {
          image.src = raster.toDataURL();
          return image;
        } else {
          return $('<span>').addClass('badge label-default').attr('data-i18n', 'No path loaded').text(i18next.t('No path loaded'));
        }
      };

      DrawingPanel.prototype.setDrawingThumbnail = function() {
        var thumbnailJ;
        thumbnailJ = this.contentJ.find('.drawing-thumbnail');
        thumbnailJ.empty().append(this.getDrawingImage(this.currentDrawing));
      };

      DrawingPanel.prototype.createDrawingFromItems = function(items) {
        var description, drawingId, item, j, len, title;
        drawingId = Utils.createId();
        for (j = 0, len = items.length; j < len; j++) {
          item = items[j];
          if (item instanceof Item.Path) {
            item.drawingId = drawingId;
          }
        }
        title = this.contentJ.find('#drawing-title').val();
        description = this.contentJ.find('#drawing-description').val();
        this.currentDrawing = new Item.Drawing(null, null, drawingId, null, R.me, Date.now(), title, description, 'pending');
        R.view.fitRectangle(this.currentDrawing.rectangle, true);
        this.setDrawingThumbnail();
        this.currentDrawing.select(true, false);
      };

      DrawingPanel.prototype.submitDrawingClickedCallback = function(results) {
        var i, id, item, itemIds, items, itemsToLoad, j, k, len, len1, ref;
        this.submitBtnJ.find('span.glyphicon').removeClass('glyphicon-refresh glyphicon-refresh-animate').addClass('glyphicon-ok');
        if (!R.loader.checkError(results)) {
          return;
        }
        itemsToLoad = [];
        itemIds = [];
        ref = results.items;
        for (j = 0, len = ref.length; j < len; j++) {
          i = ref[j];
          item = JSON.parse(i);
          itemIds.push(item.clientId);
          if (R.items[item.clientId] == null) {
            itemsToLoad.push(item);
          }
        }
        R.loader.createNewItems(itemsToLoad);
        items = [];
        for (k = 0, len1 = itemIds.length; k < len1; k++) {
          id = itemIds[k];
          items.push(R.items[id]);
        }
        if (itemIds.length === 0) {
          R.alertManager.alert('You must draw something before submitting.', 'error');
          this.close();
          return;
        }
        if (R.Tools.Path.draftIsTooBig(items)) {
          R.Tools.Path.displayDraftIsTooBigError();
          this.close();
          return;
        }
        this.createDrawingFromItems(items);
        R.commandManager.clearHistory();
      };

      DrawingPanel.prototype.checkPathToSubmit = function() {
        var id, item, ref;
        ref = R.items;
        for (id in ref) {
          item = ref[id];
          if (item instanceof Item.Path && item.owner === R.me && item.group.parent === R.view.mainLayer) {
            return true;
          }
        }
        return false;
      };

      DrawingPanel.prototype.submitDrawingClicked = function() {
        R.toolManager.leaveDrawingMode(true);
        this.submitDrawingBtnJ.hide();
        this.drawingPanelTitleJ.attr('data-i18n', 'Create drawing').text(i18next.t('Create drawing'));
        this.open();
        this.showContent();
        this.currentDrawing = null;
        this.contentJ.find('#drawing-author').val(R.me);
        this.contentJ.find('#drawing-title').val('');
        this.contentJ.find('#drawing-description').val('');
        this.submitBtnJ.show();
        this.modifyBtnJ.hide();
        this.cancelBtnJ.show();
        this.contentJ.find('#drawing-title').removeAttr('readonly');
        this.contentJ.find('#drawing-description').removeAttr('readonly');
        this.votesJ.hide();
        this.currentDrawing = null;
        if (R.selectedItems.length === 0) {
          this.submitBtnJ.find('span.glyphicon').removeClass('glyphicon-ok').addClass('glyphicon-refresh glyphicon-refresh-animate');
          $.ajax({
            method: "POST",
            url: "ajaxCall/",
            data: {
              data: JSON.stringify({
                "function": 'getDrafts',
                args: {}
              })
            }
          }).done(this.submitDrawingClickedCallback);
          return;
        }
        this.createDrawingFromItems(R.selectedItems);
      };

      DrawingPanel.prototype.setVotes = function() {
        var j, len, liJ, nNegativeVotes, nPositiveVotes, nVotes, negativeVoteListJ, positiveVoteListJ, ref, v, vote;
        this.votesJ.show();
        this.voteUpBtnJ.removeClass('voted');
        this.voteDownBtnJ.removeClass('voted');
        positiveVoteListJ = this.drawingPanelJ.find('.vote-list.positive');
        negativeVoteListJ = this.drawingPanelJ.find('.vote-list.negative');
        positiveVoteListJ.empty();
        negativeVoteListJ.empty();
        nPositiveVotes = 0;
        nNegativeVotes = 0;
        ref = this.currentDrawing.votes;
        for (j = 0, len = ref.length; j < len; j++) {
          vote = ref[j];
          v = JSON.parse(vote.vote);
          liJ = $('<li data-author-pk="' + vote.authorPk + '">' + vote.author + '</li>');
          if (v.positive) {
            nPositiveVotes++;
            positiveVoteListJ.append(liJ);
            if (vote.author === R.me) {
              this.voteUpBtnJ.addClass('voted');
            }
          } else {
            nNegativeVotes++;
            negativeVoteListJ.append(liJ);
            if (vote.author === R.me) {
              this.voteDownBtnJ.addClass('voted');
            }
          }
        }
        if (nPositiveVotes > 0) {
          positiveVoteListJ.removeClass('hidden');
        } else {
          positiveVoteListJ.addClass('hidden');
        }
        if (nNegativeVotes > 0) {
          negativeVoteListJ.removeClass('hidden');
        } else {
          negativeVoteListJ.addClass('hidden');
        }
        this.votesJ.find('.n-votes.positive').html(nPositiveVotes);
        this.votesJ.find('.n-votes.negative').html(nNegativeVotes);
        nVotes = nPositiveVotes + nNegativeVotes;
        this.votesJ.find('.n-votes.total').html(nVotes);
        this.votesJ.find('.percentage-votes').html(nVotes > 0 ? 100 * nPositiveVotes / nVotes : 0);
        this.votesJ.find('.status').html(this.currentDrawing.status);
        this.voteUpBtnJ.removeClass('disabled');
        this.voteDownBtnJ.removeClass('disabled');
        if (this.currentDrawing.owner === R.me || R.administrator) {
          if (this.currentDrawing.status === 'pending') {
            this.voteUpBtnJ.removeClass('disabled');
            this.voteDownBtnJ.removeClass('disabled');
          }
        }
      };

      DrawingPanel.prototype.setDrawing = function(currentDrawing, drawingData) {
        var j, latestDrawing, len, p, path, pathsToLoad, ref;
        this.currentDrawing = currentDrawing;
        this.drawingPanelTitleJ.attr('data-i18n', 'Drawing info').text(i18next.t('Drawing info'));
        this.open();
        this.showContent();
        latestDrawing = JSON.parse(drawingData.drawing);
        this.currentDrawing.votes = drawingData.votes;
        this.currentDrawing.status = latestDrawing.status;
        this.submitBtnJ.hide();
        this.modifyBtnJ.hide();
        this.cancelBtnJ.hide();
        this.contentJ.find('#drawing-author').val(this.currentDrawing.owner);
        this.contentJ.find('#drawing-title').val(this.currentDrawing.title);
        this.contentJ.find('#drawing-description').val(this.currentDrawing.description);
        if (this.currentDrawing.owner === R.me || R.administrator) {
          if (latestDrawing.status === 'pending') {
            this.modifyBtnJ.show();
            this.cancelBtnJ.show();
          }
          this.contentJ.find('#drawing-title').removeAttr('readonly');
          this.contentJ.find('#drawing-description').removeAttr('readonly');
        } else {
          this.contentJ.find('#drawing-title').attr('readonly', true);
          this.contentJ.find('#drawing-description').attr('readonly', true);
        }
        this.setVotes();
        pathsToLoad = [];
        ref = drawingData.paths;
        for (j = 0, len = ref.length; j < len; j++) {
          p = ref[j];
          path = JSON.parse(p);
          if (!R.items[path.clientId]) {
            pathsToLoad.push(path);
          }
        }
        R.loader.createNewItems(pathsToLoad);
        this.setDrawingThumbnail();
      };

      DrawingPanel.prototype.onDrawingChange = function(data) {
        var args, drawing;
        switch (data.type) {
          case 'votes':
            drawing = R.items[data.drawingId];
            if (drawing != null) {
              drawing.votes = data.votes;
              if (this.currentDrawing === drawing) {
                this.setVotes();
              }
            }
            break;
          case 'new':
            args = {
              itemsToLoad: [
                {
                  itemType: 'Drawing',
                  pks: [data.pk]
                }, {
                  itemType: 'Path',
                  pks: [data.pathPks]
                }
              ]
            };
            $.ajax({
              method: "POST",
              url: "ajaxCall/",
              data: {
                data: JSON.stringify({
                  "function": 'loadItems',
                  args: args
                })
              }
            }).done(function(results) {
              R.loader.loadCallback(results, true);
            });
            break;
          case 'description':
            drawing = R.items[data.drawingId];
            if (drawing != null) {
              drawing.title = data.title;
              drawing.description = data.description;
              if (this.currentDrawing === drawing) {
                this.contentJ.find('#drawing-title').val(data.title);
                this.contentJ.find('#drawing-description').val(data.description);
              }
            }
            break;
          case 'delete':
            drawing = R.items[data.drawingId];
            if (drawing != null) {
              drawing.remove();
            }
        }
      };


      /* votes */

      DrawingPanel.prototype.hasAlreadyVoted = function() {
        var j, len, ref, vote;
        ref = this.currentDrawing.votes;
        for (j = 0, len = ref.length; j < len; j++) {
          vote = ref[j];
          if (vote.vote.author === R.me) {
            return true;
          }
        }
        return false;
      };

      DrawingPanel.prototype.voteCallback = function(result) {
        var suffix;
        if (!R.loader.checkError(result)) {
          return;
        }
        this.currentDrawing.updateDrawingPanel();
        if (result.cancelled) {
          R.alertManager.alert('Your vote was successfully cancelled', 'success');
          return;
        }
        this.currentDrawing.votes = result.votes;
        suffix = '';
        if (result.validates) {
          suffix = ', the drawing will be validated in a minute if nobody cancels its vote!';
        } else if (result.rejects) {
          suffix = ', the drawing will be rejected in a minute if nobody cancels its vote!';
        }
        R.alertManager.alert('You successfully voted' + suffix, 'success');
        R.socket.emit("drawing change", {
          type: 'votes',
          votes: this.currentDrawing.votes
        });
      };

      DrawingPanel.prototype.vote = function(positive) {
        var args;
        if (this.currentDrawing.owner === R.me) {
          R.alertManager.alert('You cannot vote for your own drawing', 'error');
          return;
        }
        if (this.currentDrawing.status !== 'pending') {
          R.alertManager.alert('The drawing is already validated.', 'error');
          return;
        }
        if (this.hasAlreadyVoted()) {
          R.alertManager.alert('You already voted for this drawing', 'error');
          return;
        }
        args = {
          pk: this.currentDrawing.pk,
          date: Date.now(),
          positive: positive
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'vote',
              args: args
            })
          }
        }).done(this.voteCallback);
      };

      DrawingPanel.prototype.voteUp = function() {
        this.vote(true);
      };

      DrawingPanel.prototype.voteDown = function() {
        this.vote(false);
      };


      /* submit modify cancel drawing */

      DrawingPanel.prototype.submitDrawing = function() {
        var description, title;
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to submit a drawing.", "error");
          return;
        }
        title = this.contentJ.find('#drawing-title').val();
        description = this.contentJ.find('#drawing-description').val();
        if (title.length === 0) {
          R.alertManager.alert("You must enter a title.", "error");
          return;
        }
        if (description.length === 0) {
          R.alertManager.alert("You must enter a description.", "error");
          return;
        }
        this.currentDrawing.title = title;
        this.currentDrawing.description = description;
        this.currentDrawing.save();
        this.close(false);
      };

      DrawingPanel.prototype.modifyDrawing = function() {
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to modify a drawing.", "error");
          return;
        }
        if (this.currentDrawing == null) {
          R.alertManager.alert("You must select a drawing first.", "error");
          return;
        }
        if (this.currentDrawing.status !== 'pending') {
          R.alertManager.alert("The drawing is already validated, it cannot be modified anymore.", "error");
          return;
        }
        this.currentDrawing.update({
          title: this.contentJ.find('#drawing-title').val(),
          data: this.contentJ.find('#drawing-description').val()
        });
      };

      DrawingPanel.prototype.cancelDrawing = function() {
        if (this.currentDrawing == null) {
          this.close();
          return;
        }
        if (this.currentDrawing.pk == null) {
          this.close();
          return;
        }
        if (this.currentDrawing.status !== 'pending') {
          R.alertManager.alert("The drawing is already validated, it cannot be cancelled anymore.", "error");
          return;
        }
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to cancel a drawing.", "error");
          return;
        }
        this.currentDrawing.deleteCommand();
        this.close();
      };

      return DrawingPanel;

    })();
    return DrawingPanel;
  });

}).call(this);
