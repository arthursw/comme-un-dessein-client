// Generated by CoffeeScript 1.10.0
(function() {
  define(['Utils/Utils', 'Utils/Global', 'Utils/FontManager', 'Loader', 'Socket', 'City', 'Rasterizers/RasterizerManager', 'UI/Sidebar', 'UI/Code', 'UI/Editor', 'UI/DrawingPanel', 'UI/Modal', 'UI/AlertManager', 'UI/Controllers/ControllerManager', 'Commands/CommandManager', 'View/View', 'Tools/ToolManager', 'RasterizerBot'], function(Utils, Global, FontManager, Loader, Socket, CityManager, RasterizerManager, Sidebar, FileManager, CodeEditor, DrawingPanel, Modal, AlertManager, ControllerManager, CommandManager, View, ToolManager, RasterizerBot) {
    console.log('Main CommeUnDessein Repository');

    /*
    	 * CommeUnDessein documentation #
    
    	CommeUnDessein is an experiment about freedom, creativity and collaboration.
    
    	tododoc
    	tododoc: define RItems
    
    	The source code is divided in files:
    	 - [main.coffee](http://main.html) which is where the initialization
    	 - [path.coffee](http://path.html)
    	 - etc
    
    	Notations:
    	 - override means that the method extends functionnalities of the inherited method (super is called at some point)
    	 - redefine means that it totally replace the method (super is never called)
     */
    $(document).ready(function() {
      R.catchErrors = false;
      R.ignoreSockets = false;
      R.currentPaths = {};
      R.paths = new Object();
      R.items = new Object();
      R.locks = [];
      R.divs = [];
      R.sortedPaths = [];
      R.sortedDivs = [];
      R.animatedItems = [];
      R.cars = {};
      R.currentDiv = null;
      R.selectedItems = [];
      if (location.pathname === '/rasterizer/') {
        R.rasterizerBot = new RasterizerBot(this);
        R.loader = new Loader.RasterizerLoader();
      } else {
        R.loader = new Loader();
      }
      R.socket = new Socket();
      R.sidebar = new Sidebar();
      R.view = new View();
      R.alertManager = new AlertManager();
      R.controllerManager = new ControllerManager();
      R.controllerManager.createGlobalControllers();
      R.rasterizerManager = new RasterizerManager();
      R.rasterizerManager.initializeRasterizers();
      R.commandManager = new CommandManager();
      R.toolManager = new ToolManager();
      R.drawingPanel = new DrawingPanel();
      R.fontManager = new FontManager();
      R.view.initializePosition();
      R.sidebar.initialize();
      if (typeof window.setPageFullyLoaded === "function") {
        window.setPageFullyLoaded(true);
      }
    });
    R.fsi = function() {
      var ref;
      return (ref = R.selectedItems) != null ? ref[0] : void 0;
    };
    R.fi = function() {
      var itemID;
      if (R.items == null) {
        return null;
      }
      for (itemID in R.items) {
        return R.items[itemID];
      }
    };
  });

}).call(this);
