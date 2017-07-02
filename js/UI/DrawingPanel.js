// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['coffee', 'typeahead'], function(CoffeeScript) {
    var DrawingPanel;
    DrawingPanel = (function() {
      function DrawingPanel() {
        this.cancelDrawing = bind(this.cancelDrawing, this);
        this.cancelDrawingCallback = bind(this.cancelDrawingCallback, this);
        this.modifyDrawing = bind(this.modifyDrawing, this);
        this.modifyDrawingCallback = bind(this.modifyDrawingCallback, this);
        this.submitDrawing = bind(this.submitDrawing, this);
        this.submitDrawingCallback = bind(this.submitDrawingCallback, this);
        this.voteDown = bind(this.voteDown, this);
        this.voteUp = bind(this.voteUp, this);
        this.vote = bind(this.vote, this);
        this.voteCallback = bind(this.voteCallback, this);
        this.hideLoadAnimation = bind(this.hideLoadAnimation, this);
        this.showLoadAnimation = bind(this.showLoadAnimation, this);
        this.close = bind(this.close, this);
        this.onMouseUp = bind(this.onMouseUp, this);
        this.resize = bind(this.resize, this);
        this.setFullSize = bind(this.setFullSize, this);
        this.setHalfSize = bind(this.setHalfSize, this);
        this.onHandleDown = bind(this.onHandleDown, this);
        var closeBtnJ, handleJ, runBtnJ;
        this.drawingPanelJ = $("#drawingPanel");
        this.drawingPanelJ.bind("transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd", this.resize);
        handleJ = this.drawingPanelJ.find(".panel-handle");
        handleJ.mousedown(this.onHandleDown);
        handleJ.find('.handle-right').click(this.setHalfSize);
        handleJ.find('.handle-left').click(this.setFullSize);
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
        this.submitBtnJ = this.drawingPanelJ.find('form.create button.submit');
        this.modifyBtnJ = this.drawingPanelJ.find('form.create button.modify');
        this.cancelBtnJ = this.drawingPanelJ.find('form.create button.cancel');
        this.submitBtnJ.click(this.submitDrawing);
        this.modifyBtnJ.click(this.modifyDrawing);
        this.cancelBtnJ.click(this.cancelDrawing);
        return;
      }


      /* mouse interaction */

      DrawingPanel.prototype.onHandleDown = function() {
        this.draggingEditor = true;
        $("body").css({
          'user-select': 'none'
        });
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
        if (this.draggingEditor) {
          this.drawingPanelJ.css({
            left: Math.max(265, event.pageX)
          });
        }
      };

      DrawingPanel.prototype.onMouseUp = function(event) {
        this.draggingEditor = false;
        $("body").css({
          'user-select': 'text'
        });
      };


      /* open close */

      DrawingPanel.prototype.open = function() {
        this.drawingPanelJ.show();
        this.drawingPanelJ.addClass('visible');
      };

      DrawingPanel.prototype.close = function() {
        this.drawingPanelJ.hide();
        this.drawingPanelJ.removeClass('visible');
      };


      /* set drawing */

      DrawingPanel.prototype.showLoadAnimation = function() {
        this.drawingPanelJ.find('.content').children().hide();
        this.drawingPanelJ.find('.content').children('.loading-animation').show();
      };

      DrawingPanel.prototype.hideLoadAnimation = function() {
        this.drawingPanelJ.find('.content').children().show();
        this.drawingPanelJ.find('.content').children('.loading-animation').hide();
      };

      DrawingPanel.prototype.showSubmitDrawing = function() {
        var contentJ;
        this.open();
        this.hideLoadAnimation();
        this.currentDrawing = null;
        contentJ = this.drawingPanelJ.find('.content');
        contentJ.find('.read').hide();
        contentJ.find('.modify').show();
        contentJ.find('#drawing-title').val('');
        contentJ.find('#drawing-description').val('');
        this.submitBtnJ.show();
        this.modifyBtnJ.hide();
        this.cancelBtnJ.hide();
        this.votesJ.hide();
      };

      DrawingPanel.prototype.setDrawing = function(currentDrawing, drawingData) {
        var contentJ, i, len, liJ, nNegativeVotes, nPositiveVotes, nVotes, negativeVoteListJ, positiveVoteListJ, ref, v, vote;
        this.currentDrawing = currentDrawing;
        this.open();
        this.hideLoadAnimation();
        contentJ = this.drawingPanelJ.find('.content');
        this.currentDrawing.votes = drawingData.votes;
        if (this.currentDrawing.owner === R.me) {
          contentJ.find('.read').hide();
          contentJ.find('.modify').show();
          contentJ.find('#drawing-title').val(this.currentDrawing.title);
          contentJ.find('#drawing-description').val(this.currentDrawing.description);
          this.submitBtnJ.hide();
          this.modifyBtnJ.show();
          this.cancelBtnJ.show();
        } else {
          contentJ.find('.read').show();
          contentJ.find('.modify').hide();
          contentJ.find('.title').html(this.currentDrawing.title);
          contentJ.find('.description').html(this.currentDrawing.description);
          contentJ.find('.author').html(this.currentDrawing.owner);
        }
        this.votesJ.show();
        this.voteUpBtnJ.removeClass('voted');
        this.voteDownBtnJ.removeClass('voted');
        positiveVoteListJ = this.drawingPanelJ.find('.vote-list.positive');
        negativeVoteListJ = this.drawingPanelJ.find('.vote-list.negative');
        positiveVoteListJ.empty();
        negativeVoteListJ.empty();
        nPositiveVotes = 0;
        nNegativeVotes = 0;
        ref = drawingData.votes;
        for (i = 0, len = ref.length; i < len; i++) {
          vote = ref[i];
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
        this.votesJ.find('.n-votes.positive').html(nPositiveVotes);
        this.votesJ.find('.n-votes.negative').html(nNegativeVotes);
        nVotes = nPositiveVotes + nNegativeVotes;
        this.votesJ.find('.n-votes.total').html(nVotes);
        this.votesJ.find('.percentage-votes').html(nVotes > 0 ? 100 * nPositiveVotes / nVotes : 0);
      };


      /* votes */

      DrawingPanel.prototype.hasAlreadyVoted = function() {
        var i, len, ref, vote;
        ref = this.currentDrawing.votes;
        for (i = 0, len = ref.length; i < len; i++) {
          vote = ref[i];
          if (vote.vote.author === R.me) {
            return true;
          }
        }
        return false;
      };

      DrawingPanel.prototype.voteCallback = function(result) {
        if (!R.loader.checkError(result)) {
          return;
        }
        R.alertManager.alert('You successfuly voted', 'success');
      };

      DrawingPanel.prototype.vote = function(positive) {
        var args;
        if (this.currentDrawing.owner === R.me) {
          R.alertManager.alert('You cannot vote for your own drawing', 'error');
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

      DrawingPanel.prototype.submitDrawingCallback = function(result) {
        if (!R.loader.checkError(result)) {
          return;
        }
        R.alertManager.alert("Drawing successfully submitted. It will be drawn if it gets 100 votes.", "success");
      };

      DrawingPanel.prototype.submitDrawing = function() {
        var args, contentJ, i, ids, item, len, ref;
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to submit a drawing.", "error");
          return;
        }
        if (R.selectedItems.length === 0) {
          R.alertManager.alert("You must select some drawings first.", "error");
          return;
        }
        ids = [];
        ref = R.selectedItems;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          ids.push(item.pk);
        }
        contentJ = this.drawingPanelJ.find('.content');
        args = {
          date: Date.now(),
          pathPks: ids,
          title: contentJ.find('#drawing-title').val(),
          description: contentJ.find('#drawing-description').val()
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'saveDrawing',
              args: args
            })
          }
        }).done(this.submitDrawingCallback);
      };

      DrawingPanel.prototype.modifyDrawingCallback = function(result) {
        if (!R.loader.checkError(result)) {
          return;
        }
        R.alertManager.alert("Drawing successfully modified.", "success");
      };

      DrawingPanel.prototype.modifyDrawing = function() {
        var args, contentJ;
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to modify a drawing.", "error");
          return;
        }
        if (this.currentDrawing == null) {
          R.alertManager.alert("You must select a drawing first.", "error");
          return;
        }
        contentJ = this.drawingPanelJ.find('.content');
        args = {
          pk: this.currentDrawing.pk,
          title: contentJ.find('#drawing-title').val(),
          description: contentJ.find('#drawing-description').val()
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'updateDrawing',
              args: args
            })
          }
        }).done(this.modifyDrawingCallback);
      };

      DrawingPanel.prototype.cancelDrawingCallback = function(result) {
        if (!R.loader.checkError(result)) {
          return;
        }
        R.alertManager.alert("Drawing successfully cancelled.", "success");
      };

      DrawingPanel.prototype.cancelDrawing = function() {
        var args;
        if ((R.me == null) || !_.isString(R.me)) {
          R.alertManager.alert("You must be logged in to cancel a drawing.", "error");
          return;
        }
        if (this.currentDrawing == null) {
          R.alertManager.alert("You must select a drawing first.", "error");
          return;
        }
        args = {
          pk: this.currentDrawing.pk
        };
        $.ajax({
          method: "POST",
          url: "ajaxCall/",
          data: {
            data: JSON.stringify({
              "function": 'deleteDrawing',
              args: args
            })
          }
        }).done(this.deleteDrawingCallback);
      };

      return DrawingPanel;

    })();
    return DrawingPanel;
  });

}).call(this);
