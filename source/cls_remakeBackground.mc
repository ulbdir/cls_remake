import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class Background extends WatchUi.Drawable {

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);
    }

	function drawPolygon(dc as DC, pts as Lang.Array<Lang.Array<Lang.Numeric> >) as Void {
		if (pts.size() > 2) {
			for (var i=1; i<pts.size(); i++) {
				dc.drawLine(pts[i-1][0], pts[i-1][1], pts[i][0], pts[i][1]);		
			}			
			dc.drawLine(pts[pts.size()-1][0], pts[pts.size()-1][1], pts[0][0], pts[0][1]);
		}
	}

    function draw(dc as Dc) as Void {
    
        // Set the background color then call to clear the screen
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Date display
/*
        var display_top = [[47,31], [189, 31], [192, 34], [192, 65], [197, 70], [222, 70], [227, 78], [228, 86], [72, 86], [56, 70], [32, 70], [32, 46] ];

        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
        dc.fillPolygon(display_top);

        dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);
        drawPolygon(dc, display_top);
*/

        var display_top = [[47,31], [189, 31], [192, 34], [192, 73], [32, 73], [32, 46] ];

        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
        dc.fillPolygon(display_top);

        dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);
        drawPolygon(dc, display_top);


		// Weather display
		//var display_weather = [[9, 90], [58, 90], [64, 96], [64, 139], [56, 147], [9, 147], [8, 146], [8, 91]];
        var display_weather = [[9, 81], [58, 81], [64, 87], [64, 139], [56, 147], [9, 147], [8, 146], [8, 81]];

        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
        dc.fillPolygon(display_weather);

        dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);
        drawPolygon(dc, display_weather);


		// Step bar display
		//var display_steps = [[75, 101], [231, 101], [233, 103], [233, 136], [73, 136], [73, 103]];
        //var display_steps = [[75, 78], [231, 78], [233, 81], [233, 136], [73, 136], [73, 81]];
/*
        var display_steps = [
            [73, 85],  [77, 81], [36, 81], [32, 77], [32, 55], [192, 55], [192, 77], [188, 81], [233, 81], [233, 136], [73, 136], [73, 85]];
*/
        var display_steps = [
            [73, 85],  [77, 81], [233, 81], [233, 136], [73, 136], [73, 85]];


        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
        dc.fillPolygon(display_steps);

        dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);
        drawPolygon(dc, display_steps);

		// Time display
		var display_time = [[72, 149], [211, 149], [211, 192], [191, 192], [187, 196], [187, 208], [44, 208], [32, 196], [32, 173], [39, 166], [55, 166]];

        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
        dc.fillPolygon(display_time);

        dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);
        drawPolygon(dc, display_time);


		// Top decoration
		var top_deco1 = [[16, 76], [22, 76], [27, 81], [14, 81], [13, 80], [13, 79]];
		var top_deco2 = [[27, 76], [32, 76], [37, 81], [32, 81]];
		var top_deco3 = [[36, 76], [39, 76], [44, 81], [41, 81]];
		var top_deco4 = [[43, 76], [45, 76], [50, 81], [48, 81]];
		var top_deco5 = [[49, 76], [50, 76], [55, 81], [54, 81]];
		var top_deco6 = [[54, 76], [55, 76], [72, 93], [230, 93], [231, 94], [72, 94], [54, 76]];

        dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
/*
        dc.fillPolygon(top_deco1);
        dc.fillPolygon(top_deco2);
        dc.fillPolygon(top_deco3);
        dc.fillPolygon(top_deco4);
        dc.fillPolygon(top_deco5);
        dc.fillPolygon(top_deco6);
*/
		dc.drawLine(80, 11, 85, 11);
		dc.drawLine(155, 11, 160, 11);

		dc.drawLine(71, 15, 85, 15);
		dc.drawLine(155, 15, 169, 15);

		dc.drawLine(64, 19, 85, 19);
		dc.drawLine(155, 19, 176, 19);
		
		dc.drawLine(46, 26, 194, 26);
			
		// Bottom decoration
		var bottom_deco1 = [[13, 156], [26, 156], [20, 162], [16, 162], [12,158], [12, 157]];
		var bottom_deco2 = [[30,156], [36,156], [30,162], [24,162]];
		var bottom_deco3 = [[40,156], [43,156], [37,162], [34,162]];
		var bottom_deco4 = [[47,156], [49,156], [43,162], [41,162]];
		var bottom_deco5 = [[53,156], [54,156], [48,162], [47,162]];
		var bottom_deco6 = [[51,162], [72,141], [231,141], [230,142], [72,142], [52,162]];

        dc.fillPolygon(bottom_deco1);
        dc.fillPolygon(bottom_deco2);
        dc.fillPolygon(bottom_deco3);
        dc.fillPolygon(bottom_deco4);
        dc.fillPolygon(bottom_deco5);
        dc.fillPolygon(bottom_deco6);

		dc.drawLine(46, 213, 194, 213);
    }

}
