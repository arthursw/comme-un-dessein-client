// Generated by CoffeeScript 1.10.0
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['paper', 'R', 'Utils/Utils', 'Items/Item', 'UI/ModuleLoader', 'jqueryUi', 'scrollbar', 'typeahead'], function(P, R, Utils, Item, ModuleLoader) {
    var Sidebar;
    Sidebar = (function() {
      function Sidebar() {
        this.displayDesiredTool = bind(this.displayDesiredTool, this);
        this.queryDesiredTool = bind(this.queryDesiredTool, this);
        this.toggleSidebar = bind(this.toggleSidebar, this);
        this.toggleToolToFavorite = bind(this.toggleToolToFavorite, this);
        this.sidebarJ = $("#sidebar");
        this.favoriteToolsJ = $("#FavoriteTools .tool-list");
        this.allToolsContainerJ = $("#AllTools");
        this.allToolsJ = this.allToolsContainerJ.find(".all-tool-list");
        this.searchToolInputJ = this.allToolsContainerJ.find('.search-tool');
        this.initializeFavoriteTools();
        this.handleJ = this.sidebarJ.find(".sidebar-handle");
        this.handleJ.click(this.toggleSidebar);
        this.itemListsJ = $("#RItems .layers");
        this.pathListJ = this.itemListsJ.find(".rPath-list");
        this.pathListJ.sortable({
          stop: Item.zIndexSortStop,
          delay: 250
        });
        this.pathListJ.disableSelection();
        this.divListJ = this.itemListsJ.find(".rDiv-list");
        this.divListJ.sortable({
          stop: Item.zIndexSortStop,
          delay: 250
        });
        this.divListJ.disableSelection();
        this.itemListsJ.find('.title').click(function(event) {
          $(this).parent().toggleClass('closed');
        });
        this.sortedPaths = R.sortedPaths;
        this.sortedDivs = R.sortedDivs;
        $(".mCustomScrollbar").mCustomScrollbar({
          keyboard: false
        });
        return;
      }

      Sidebar.prototype.initialize = function() {
        ModuleLoader.initialize();
        this.initializeTypeahead();
      };

      Sidebar.prototype.initializeFavoriteTools = function() {
        var defaultFavoriteTools, error, error1;
        this.favoriteTools = [];
        if (typeof localStorage !== "undefined" && localStorage !== null) {
          try {
            this.favoriteTools = JSON.parse(localStorage.favorites);
          } catch (error1) {
            error = error1;
            console.log(error);
          }
        }
        defaultFavoriteTools = [];
        while (this.favoriteTools.length < 8 && defaultFavoriteTools.length > 0) {
          Utils.Array.pushIfAbsent(this.favoriteTools, defaultFavoriteTools.pop().label);
        }
      };

      Sidebar.prototype.toggleToolToFavorite = function(event, btnJ) {
        var attr, attrName, cloneJ, i, j, len, len1, li, names, ref, ref1, targetJ, toolName;
        if (btnJ == null) {
          event.stopPropagation();
          targetJ = $(event.target);
          btnJ = targetJ.parents("li.tool-btn:first");
        }
        toolName = btnJ.attr("data-name");
        if (btnJ.hasClass("selected")) {
          btnJ.removeClass("selected");
          this.favoriteToolsJ.find("[data-name='" + toolName + "']").remove();
          Utils.Array.remove(this.favoriteTools, toolName);
        } else {
          btnJ.addClass("selected");
          cloneJ = btnJ.clone();
          this.favoriteToolsJ.append(cloneJ);
          cloneJ.click(function() {
            return btnJ.click();
          });
          ref = ['placement', 'container', 'trigger', 'delay', 'content', 'title'];
          for (i = 0, len = ref.length; i < len; i++) {
            attr = ref[i];
            attrName = 'data-' + attr;
            cloneJ.attr(attrName, btnJ.attr(attrName));
            cloneJ.popover();
          }
          cloneJ.css({
            'order': btnJ.attr('data-order')
          });
          this.favoriteTools.push(toolName);
        }
        if (typeof localStorage === "undefined" || localStorage === null) {
          return;
        }
        names = [];
        ref1 = this.favoriteToolsJ.children();
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          li = ref1[j];
          names.push($(li).attr("data-name"));
        }
        localStorage.favorites = JSON.stringify(names);
      };

      Sidebar.prototype.show = function() {
        var ref;
        this.sidebarJ.removeClass("r-hidden");
        if ((ref = R.codeEditor) != null) {
          ref.editorJ.removeClass("r-hidden");
        }
        R.alertManager.alertsContainer.removeClass("r-sidebar-hidden");
        this.handleJ.find("span").removeClass("glyphicon-chevron-right").addClass("glyphicon-chevron-left");
      };

      Sidebar.prototype.hide = function() {
        var ref;
        this.sidebarJ.addClass("r-hidden");
        if ((ref = R.codeEditor) != null) {
          ref.editorJ.addClass("r-hidden");
        }
        R.alertManager.alertsContainer.addClass("r-sidebar-hidden");
        this.handleJ.find("span").removeClass("glyphicon-chevron-left").addClass("glyphicon-chevron-right");
      };

      Sidebar.prototype.toggleSidebar = function(show) {
        if ((show == null) || jQuery.Event.prototype.isPrototypeOf(show)) {
          show = this.sidebarJ.hasClass("r-hidden");
        }
        if (show) {
          this.show();
        } else {
          this.hide();
        }
      };

      Sidebar.prototype.initializeTypeahead = function() {
        var toolValues;
        toolValues = this.allToolsJ.find('.tool-btn,.category').map(function() {
          return {
            value: this.getAttribute('data-name')
          };
        }).get();
        this.typeaheadModuleEngine = new Bloodhound({
          name: 'Tools',
          local: toolValues,
          datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
          queryTokenizer: Bloodhound.tokenizers.whitespace
        });
        this.typeaheadModuleEngine.initialize();
        this.searchToolInputJ = this.allToolsContainerJ.find("input.search-tool");
        this.searchToolInputJ.keyup(this.queryDesiredTool);
      };

      Sidebar.prototype.queryDesiredTool = function(event) {
        var query;
        query = this.searchToolInputJ.val();
        if (query === "") {
          this.allToolsJ.find('.tool-btn').show();
          this.allToolsJ.find('.category').removeClass('closed').show();
          return;
        }
        this.allToolsJ.find('.tool-btn').hide();
        this.allToolsJ.find('.category').addClass('closed').hide();
        this.typeaheadModuleEngine.get(query, this.displayDesiredTool);
      };

      Sidebar.prototype.displayDesiredTool = function(suggestions) {
        var i, len, matchJ, suggestion;
        for (i = 0, len = suggestions.length; i < len; i++) {
          suggestion = suggestions[i];
          matchJ = this.allToolsJ.find("[data-name='" + suggestion.value + "']");
          matchJ.show();
          matchJ.parentsUntil(this.allToolsJ).removeClass('closed').show();
        }
      };

      return Sidebar;

    })();
    return Sidebar;
  });

}).call(this);
