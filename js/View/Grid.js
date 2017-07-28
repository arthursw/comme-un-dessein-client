// Generated by CoffeeScript 1.10.0
(function() {
  define(['paper', 'R', 'Utils/Utils'], function(P, R, Utils) {
    var Grid;
    Grid = (function() {
      function Grid() {
        var size;
        this.layer = new P.Layer();
        this.grid = new P.Group();
        this.grid.name = 'grid group';
        this.layer.addChild(this.grid);
        size = new P.Size(Utils.CS.mmToPixel(4000), Utils.CS.mmToPixel(3000));
        this.limitCD = new P.Path.Rectangle(size.multiply(-0.5), size);
        this.limitCD.strokeColor = '#33383e';
        this.limitCD.strokeWidth = 10;
        this.limitCD.strokeCap = 'square';
        this.limitCD.dashArray = [10, 14];
        this.layer.addChild(this.limitCD);
        this.update();
        return;
      }

      Grid.prototype.rectangleOverlapsTwoPlanets = function(rectangle) {
        return !this.limitCD.bounds.contains(rectangle);
      };

      Grid.prototype.updateLimitPaths = function() {
        var limit;
        limit = Utils.CS.getLimit();
        this.limitPathV = null;
        this.limitPathH = null;
        if (limit.x >= P.view.bounds.left && limit.x <= P.view.bounds.right) {
          this.limitPathV = new P.Path();
          this.limitPathV.name = 'limitPathV';
          this.limitPathV.strokeColor = 'green';
          this.limitPathV.strokeWidth = 5;
          this.limitPathV.add(limit.x, P.view.bounds.top);
          this.limitPathV.add(limit.x, P.view.bounds.bottom);
          this.grid.addChild(this.limitPathV);
        }
        if (limit.y >= P.view.bounds.top && limit.y <= P.view.bounds.bottom) {
          this.limitPathH = new P.Path();
          this.limitPathH.name = 'limitPathH';
          this.limitPathH.strokeColor = 'green';
          this.limitPathH.strokeWidth = 5;
          this.limitPathH.add(P.view.bounds.left, limit.y);
          this.limitPathH.add(P.view.bounds.right, limit.y);
          this.grid.addChild(this.limitPathH);
        }
      };

      Grid.prototype.update = function() {
        var bounds, halfSize, left, path, px, py, snap, top;
        this.grid.removeChildren();
        this.updateLimitPaths();
        if (P.view.bounds.width > window.innerWidth || P.view.bounds.height > window.innerHeight) {
          halfSize = new P.Point(window.innerWidth * 0.5, window.innerHeight * 0.5);
          bounds = new P.Rectangle(P.view.center.subtract(halfSize), P.view.center.add(halfSize));
          path = new P.Path.Rectangle(bounds);
          path.strokeColor = 'rgba(0, 0, 0, 0.1)';
          path.strokeWidth = 0.1;
          path.dashArray = [10, 4];
          this.grid.addChild(path);
        }
        if (!R.displayGrid) {
          return;
        }
        snap = Utils.Snap.getSnap();
        bounds = Utils.Rectangle.expandRectangleToMultiple(P.view.bounds, snap);
        left = bounds.left;
        top = bounds.top;
        while (left < bounds.right || top < bounds.bottom) {
          px = new P.Path();
          px.name = "grid px";
          py = new P.Path();
          px.name = "grid py";
          px.strokeColor = "#666666";
          if ((left / snap) % 4 === 0) {
            px.strokeColor = "#000000";
            px.strokeWidth = 2;
          }
          py.strokeColor = "#666666";
          if ((top / snap) % 4 === 0) {
            py.strokeColor = "#000000";
            py.strokeWidth = 2;
          }
          px.add(new P.Point(left, P.view.bounds.top));
          px.add(new P.Point(left, P.view.bounds.bottom));
          py.add(new P.Point(P.view.bounds.left, top));
          py.add(new P.Point(P.view.bounds.right, top));
          this.grid.addChild(px);
          this.grid.addChild(py);
          left += snap;
          top += snap;
        }
      };

      return Grid;

    })();
    return Grid;
  });

}).call(this);
