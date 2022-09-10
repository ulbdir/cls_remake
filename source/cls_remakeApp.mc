import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Background;

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
		Menu2InputDelegate.initialize();    
    }
    
    function onSelect(item) {
        if ( item.getId() == :Colors ) {
            WatchUi.pushView(new Rez.Menus.ColorSettingsMenu(), new ColorSettingsMenuDelegate(), WatchUi.SLIDE_UP);
        } else if (item.getId() == :GraphStyle) {
			WatchUi.pushView(new Rez.Menus.GraphStyleMenu(), new GraphStyleSettingsMenuDelegate(), WatchUi.SLIDE_UP);
        } else if (item.getId() == :GraphType) {
			WatchUi.pushView(new Rez.Menus.GraphTypeMenu(), new GraphTypeSettingsMenuDelegate(), WatchUi.SLIDE_UP);
		}
    }
}

class ColorSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
		Menu2InputDelegate.initialize();    
    }
    
    function onSelect(item) {
        if ( item.getId() == :White ) {
        	Application.Properties.setValue("Theme", 0);
			getApp().onSettingsChanged();	
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        if ( item.getId() == :Red ) {
        	Application.Properties.setValue("Theme", 1);
        	getApp().onSettingsChanged();
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        if ( item.getId() == :Green ) {
        	Application.Properties.setValue("Theme", 2);
        	getApp().onSettingsChanged();
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}

class GraphStyleSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
		Menu2InputDelegate.initialize();    
    }
    
    function onSelect(item) {
        if ( item.getId() == :Line ) {
        	Application.Properties.setValue("GraphStyle", 0);
			getApp().onSettingsChanged();	
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        if ( item.getId() == :Candles ) {
        	Application.Properties.setValue("GraphStyle", 1);
        	getApp().onSettingsChanged();
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}

class GraphTypeSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
		Menu2InputDelegate.initialize();    
    }
    
    function onSelect(item) {
        if ( item.getId() == :Steps ) {
        	Application.Properties.setValue("GraphType", 1);
			getApp().onSettingsChanged();	
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        if ( item.getId() == :FTX ) {
        	Application.Properties.setValue("GraphType", 0);
        	getApp().onSettingsChanged();
        	WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}


class cls_remakeApp extends Application.AppBase {

	var ScreenColor = 0xFFFFFF;
	var ScreenColorLightShade = 0xAAAAAA;
	var ScreenColorDarkShade = 0x555555;

	var LineGraph = true;
	var GraphTypeFTX = true;

	var m_View = null;

	function loadColors() {
	    var theme = Application.Properties.getValue("Theme") as Number;
	    
	    switch (theme) {
	    	case 0:
				// White
	        	ScreenColor=0xFFFFFF;
	        	ScreenColorLightShade=Graphics.COLOR_LT_GRAY;
	        	ScreenColorDarkShade=Graphics.COLOR_DK_GRAY;
	    		break;
	    	case 1:
	    		// Red
	        	ScreenColor=0xFFAA00;
	        	ScreenColorLightShade=Graphics.COLOR_DK_GRAY;
	        	ScreenColorDarkShade=Graphics.COLOR_DK_GRAY;
	    		break;
	    	default:
	    	case 2:
	    		// Green
	        	ScreenColor = 0x00FF00;
	        	ScreenColorLightShade = 0x00AA00;
	        	ScreenColorDarkShade = Graphics.COLOR_DK_GRAY;
	    }
	}

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
		loadColors();
		LineGraph = Application.Properties.getValue("GraphStyle") as Number == 0;
		GraphTypeFTX = Application.Properties.getValue("GraphType") as Number == 0;
		m_View = new cls_remakeView();

     	Background.registerForTemporalEvent(new Time.Duration(10*60));

        return [ m_View ] as Array<Views or InputDelegates>;
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        loadColors();
        reloadIcons();
		LineGraph = Application.Properties.getValue("GraphStyle") as Number == 0;
		GraphTypeFTX = Application.Properties.getValue("GraphType") as Number == 0;
        WatchUi.requestUpdate();
    }

	function screenColor() {
		return ScreenColor;
	}

	function screenColorLightShade() {
		return ScreenColorLightShade;
	}

	function screenColorDarkShade() {
		return ScreenColorDarkShade;
	}

	function getSettingsView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates> {
		return [new Rez.Menus.SettingsMenu(), new SettingsMenuDelegate()];
	}

	function reloadIcons() {
		m_View.reloadIcons();
	}

	function lineGraphEnabled() {
		return LineGraph;
	}

	function graphTypeFTX() {
		return GraphTypeFTX;
	}

	function onBackgroundData(data) {
		if(data instanceof Number) {
			//indicates there was an error, and "data" is the error code
			System.println("onBackground: " + data.toString());
		} else {
			var candle_data = data["candles"];
			
			if (candle_data) {
				var candles = new [candle_data.size()];
				for (var i=0; i<candle_data.size(); i++) {
					var candle = {};
					candle["low"] = candle_data[i][2];
					candle["high"] = candle_data[i][3];
					candle["open"] = candle_data[i][0];
					candle["close"] = candle_data[i][1];
					candles[i] = candle;
				}

				if (m_View) {
					m_View.setCandleStickData(candles);
					m_View.setCandleStickDataRefreshed(true);
				}

				System.println("onBackground: received candle data: " + candles.size().toString());
			} else {
				System.println("onBackground: got no candles");
				if (m_View) {
					m_View.setCandleStickDataRefreshed(false);
				}
			}

			var market_data = data["market"];
			if (market_data) {
				var market = {};
				market["name"]    = market_data["name"];
				market["price"]     = market_data["price"];
				market["change24h"] = market_data["change24h"];

				if (m_View) {
					m_View.setMarketData(market);
					m_View.setMarketDataRefreshed(true);
				}

				System.println("onBackground: received market data: " + market["name"] + ", " + market["price"].toString() + ", " + market["change24h"].toString());
			} else {
				System.println("onBackground: got no market data");
				if (m_View) {
					m_View.setMarketDataRefreshed(false);
				}
			}

			WatchUi.requestUpdate();
		}
	}

 public function getServiceDelegate() as ServiceDelegate{
        System.println("getServiceDelegate");
		return [new BgServiceDelegate()];
    }
}

function getApp() as cls_remakeApp {
    return Application.getApp() as cls_remakeApp;
}