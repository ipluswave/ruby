//enterprisbug.github.com/grid.js#v1.1
(function(window, document, undefined) {
	function mergeWithDefaultValues(obj) {
		for (var i = 1; i < arguments.length; i++) {
			var def = arguments[i];
			for (var n in def) {
				if (obj[n] === undefined) {
					obj[n] = def[n];
				}
			}
		}
		return obj;
	}

    function px2in(pixels){
        var inches = ((pixels * 3.375) / cardWidth).toFixed(3);

        return inches;
    }

    function px2mm(pixels) {
        var mm = ((pixels * 85.725) / cardWidth).toFixed(3);

        return mm;
    }

	var defaults = {
		distance:   50,
		lineWidth:  1,
		gridColor:  "#000000",
		caption:    true,
		font:       "10px Verdana",
        width:      457,
        height:     288,
        paddingLeft:135,
        paddingTop: 106,
        metric:     "px"
	};
	
	/** The constructor */
	var Grid = function Grid(o) {
		if (!this.draw) return new Grid(o);
		this.opts = mergeWithDefaultValues(o || {}, Grid.defaults, defaults);
	};
	
	Grid.defaults = {};
	mergeWithDefaultValues(Grid.prototype, {
		draw: function(target) {
			var self = this;
			var o = self.opts;
			
			if (target) {
				target.save();

				target.lineWidth = o.lineWidth;
				target.strokeStyle = o.gridColor;
				target.font = o.font;
				
				if (target.canvas.width > target.canvas.height) {
					until = target.canvas.width;
				} else {
					until = target.canvas.height;
				}

                var iter = 0;

				for (var y = topPadding; y <= cardHeight+topPadding; y += o.distance) {
                    iter++;

					target.beginPath();
					if (o.lineWidth == 1.0) { 
						target.moveTo(10, y + 0.5);
						target.lineTo(target.canvas.width, y + 0.5);
					} else { 
						target.moveTo(10, y);
						target.lineTo(target.canvas.width, y);
					}
					target.closePath();
					target.stroke();
					if (o.caption)
					{
                        var showY = y-topPadding;
                        if((o.distance<16 && iter%4==0)||o.distance>15||showY==0)
                        {
                            if(o.metric=="in")
                                showY = parseFloat(px2in(showY)).toFixed(1);
                            else if(o.metric=="mm")
                                showY = Math.round(px2mm(showY));

                            target.fillText(showY, 0, y+10);
                        }
					}
				}

                iter = 0;

				for (var x = leftPadding; x <= cardWidth+leftPadding; x += o.distance) {
                    iter++;

					target.beginPath();
					if (o.lineWidth == 1.0) { 
						target.moveTo(x + 0.5, 10);
						target.lineTo(x + 0.5, target.canvas.height);
					} else {
						target.moveTo(x, 10);
						target.lineTo(x, target.canvas.height);
					}
					target.closePath();
					target.stroke();

					if (o.caption)
					{
                        var showX = x-leftPadding;

                        if((o.distance<20 && iter%4==0)||o.distance>19||showX==0) {
                            if (o.metric == "in")
                                showX = parseFloat(px2in(showX)).toFixed(1);
                            else if (o.metric == "mm")
                                showX = Math.round(px2mm(showX));

                            target.fillText(showX, x, 10);
                        }
					}
				}
				
				target.restore();
			}
		}
	});

  window.Grid = Grid;

})(window, document);