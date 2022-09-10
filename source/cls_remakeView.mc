import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

enum {
	BATTERY_100,
	BATTERY_80,
	BATTERY_60,
	BATTERY_40,
	BATTERY_20
}

class cls_remakeView extends WatchUi.WatchFace {

	var m_HighPowerMode;
	var m_PhoneIcon;
	var m_StepsIcon;

	var m_LastBatteryIconType;
	var m_BatteryIcon;

	var m_MoveBarIcon;
	var m_LastMoveBarValue;

	var m_AlarmsIcon;	
	var m_LastAlarmsStatus;

	var m_MessagesIcon;	
	var m_LastMessagesStatus;

	var m_Candles;
	var m_Market;

	var m_CandlesRefreshed;
	var m_MarketRefreshed;

	var m_Pattern;

    function initialize() {
        WatchFace.initialize();
        
		System.println("App.initialize");
		
		m_HighPowerMode = true;
		
		m_Candles = new [22];
		for (var i=0; i<22; i++) {
			var candle = {};
			candle["low"] = 0;
			candle["high"] = 0;
			candle["open"] = 0;
			candle["close"] = 0;
			m_Candles[i] = candle;
		}

		m_Market = null;
		m_CandlesRefreshed = false;
		m_MarketRefreshed = false;
    }

	function reloadIcons() {
		m_LastBatteryIconType = null;
		m_LastMoveBarValue = null;
		m_LastAlarmsStatus = null;
		m_LastMessagesStatus = null;
	}

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        m_PhoneIcon = Application.loadResource( Rez.Drawables.phone_icon ) as BitmapResource;
        m_StepsIcon = Application.loadResource( Rez.Drawables.steps_icon ) as BitmapResource;
		m_Pattern = Application.loadResource( Rez.Drawables.pattern ) as BitmapResource;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

		updateTime(dc);
		updateDate(dc);			
		updateWeather(dc);

		updateSteps(dc);
		var view = View.findDrawableById("Top_Label") as Text;
        view.setColor(getApp().screenColor());
		


        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // Draw Phone icon
        if (System.getDeviceSettings().phoneConnected) {
			dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
			dc.fillRectangle(200, 44, 9, 18);
			dc.drawBitmap(200, 44, m_PhoneIcon);        
        }
        
        // Draw battery icon
        updateBatteryIcon(dc);
        
        // Draw move bar
        updateMovebar(dc);
        
		if (getApp().graphTypeFTX()) {
			updatePriceChart(dc);
		} else {
			updateStepCounts(dc);
		}
        updateMarket(dc);

        updateAlarms(dc);
        updateMessages(dc); 
    }

	function updateMessages(dc as DC) {
		var messagesStatus = (System.getDeviceSettings().notificationCount > 0);
		if (messagesStatus != m_LastMessagesStatus) {
			m_LastMessagesStatus = messagesStatus;
			if (messagesStatus) {
				m_MessagesIcon = Application.loadResource( Rez.Drawables.messages_on ) as BitmapResource;
			} else {
		    	var theme = Application.Properties.getValue("Theme") as Number;
	    
			    switch (theme) {
			    	case 0:
						m_MessagesIcon = Application.loadResource( Rez.Drawables.messages_off_white ) as BitmapResource;
						break;
			    	case 1:
						m_MessagesIcon = Application.loadResource( Rez.Drawables.messages_off_red ) as BitmapResource;
						break;
			    	default:
			    	case 2:
						m_MessagesIcon = Application.loadResource( Rez.Drawables.messages_off_green ) as BitmapResource;
						break;
			    }
			}
		}
		dc.drawBitmap(43, 173, m_MessagesIcon);
	}

	function updateAlarms(dc as DC) {
		var alarmsStatus = (System.getDeviceSettings().alarmCount > 0);
		if (alarmsStatus != m_LastAlarmsStatus) {
			m_LastAlarmsStatus = alarmsStatus;
			if (alarmsStatus) {
				m_AlarmsIcon = Application.loadResource( Rez.Drawables.alarms_on ) as BitmapResource;
			} else {
			    var theme = Application.Properties.getValue("Theme") as Number;
			    switch (theme) {
			    	case 0:
						m_AlarmsIcon = Application.loadResource( Rez.Drawables.alarms_off_white ) as BitmapResource;
						break;
			    	case 1:
						m_AlarmsIcon = Application.loadResource( Rez.Drawables.alarms_off_red ) as BitmapResource;
						break;
			    	default:
			    	case 2:
						m_AlarmsIcon = Application.loadResource( Rez.Drawables.alarms_off_green ) as BitmapResource;
						break;
			    }
			}
		}
		dc.drawBitmap(44, 189, m_AlarmsIcon);
	}

	function drawBarGraph(dc as DC, values, goals, x, y, bar_width, bar_spacing, bar_height) {

		var max_value = 0;
		for (var i=0; i<8; i++) {
			if (values[i] > max_value) {
				max_value = values[i];
			} 			
			if (goals[i] > max_value) {
				max_value = goals[i];
			}	
		}

		if (max_value > 0) {
			var steps_per_pixel = bar_height / max_value.toFloat();
	 
	 		var px = x;
			for (var i=0; i<values.size(); i++) {

				// draw goal bar
				var gh = (goals[i] * steps_per_pixel).toNumber();
	 			dc.setColor(getApp().screenColorLightShade(), Graphics.COLOR_BLACK);
				dc.fillRectangle(px, y - gh, bar_width, gh);
				
				// draw actual value bar
				var h = (values[i] * steps_per_pixel).toNumber();
				dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_BLACK);				
				dc.fillRectangle(px, y - h, bar_width, h);
				
				px += bar_width + bar_spacing;
			}
		}
	}

	function updateStepCounts(dc as DC) {
		
		var history = ActivityMonitor.getHistory();
		
		var values = [0,0,0,0, 0,0,0,0];
		var goals = [0,0,0,0, 0,0,0,0];
		
		// fill steps and step goal for today
		values[0] = ActivityMonitor.getInfo().steps;
		goals[0] = ActivityMonitor.getInfo().stepGoal;		
		
		for (var i=0; i < history.size(); i++) {
			if (history[i] != null) {
				if (history[i].steps != null) {
					values[i+1] = history[i].steps;
				} else {
					values[i+1] = 0;
				}

				if (history[i].stepGoal != null) {
					goals[i+1] = history[i].stepGoal;
				} else {
					goals[i+1] = 0;
				}
			} else {
				values[i+1] = 0;
				goals[i+1] = 0;				
			}
		}

		values = values.reverse();
		goals = goals.reverse();

		drawBarGraph(dc, values, goals, 79, 135, 16, 3, 50);
	}

	function min(a, b) {
		if (a < b) {
			return a;
		} else {
			return b;
		}
	}

	function max(a, b) {
		if (a > b) {
			return a;
		} else {
			return b;
		}
	}

	function drawCandleStickGraph(dc as DC, values, x, y, width, height) {
		var max_value = 0;
		var min_value = 0;

		var candle_width = 5;
		var candle_spacing = 2;

		for (var i=0; i<22; i++) {
			if (i==0) {
				min_value = values[i]["low"];
				min_value = min(min_value, values[i]["high"]);
				min_value = min(min_value, values[i]["close"]);
				min_value = min(min_value, values[i]["open"]);

				max_value = values[i]["low"];
				max_value = max(max_value, values[i]["high"]);
				max_value = max(max_value, values[i]["close"]);
				max_value = max(max_value, values[i]["open"]);
			} else {
				min_value = min(min_value, values[i]["low"]);
				min_value = min(min_value, values[i]["high"]);
				min_value = min(min_value, values[i]["close"]);
				min_value = min(min_value, values[i]["open"]);

				max_value = max(max_value, values[i]["low"]);
				max_value = max(max_value, values[i]["high"]);
				max_value = max(max_value, values[i]["close"]);
				max_value = max(max_value, values[i]["open"]);
			}
		}

		var value_range = max_value - min_value;

		var value_per_pixel = 1;
		
		if (value_range > 0) {
			value_per_pixel = height / value_range.toFloat();
		}

		for (var i=values.size() - 1; i>=0; i--) {
			var candle = values[i];
			if (candle["open"] < candle["close"]) {
				dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);				
			} else {
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
			}
		
			var px = x + (i*(candle_width + candle_spacing));
			
			var ly = y+height - (candle["low"] - min_value) * value_per_pixel;
			var hy = y+height - (candle["high"] - min_value) * value_per_pixel;
			var oy = y+height - (candle["open"] - min_value) * value_per_pixel;
			var cy = y+height - (candle["close"] - min_value) * value_per_pixel;

			var candle_height = (cy-oy).abs();
			if (candle_height < 1) {
				candle_height = 1;
			}

			var candle_top = oy;
			if (cy < oy) {
				candle_top = cy;
			}

			dc.fillRectangle(px, candle_top, candle_width, candle_height);
			dc.drawLine(px+(candle_width / 2), ly, px+(candle_width / 2), hy);
		}
	}

	function drawLineGraph(dc as DC, values, x, y, width, height) {
		var max_value = 0;
		var min_value = 0;

		var candle_width = 5;
		var candle_spacing = 2;

		for (var i=0; i<values.size(); i++) {
			if (i==0) {
				min_value = values[i]["low"];
				min_value = min(min_value, values[i]["high"]);
				min_value = min(min_value, values[i]["close"]);
				min_value = min(min_value, values[i]["open"]);

				max_value = values[i]["low"];
				max_value = max(max_value, values[i]["high"]);
				max_value = max(max_value, values[i]["close"]);
				max_value = max(max_value, values[i]["open"]);
			} else {
				min_value = min(min_value, values[i]["low"]);
				min_value = min(min_value, values[i]["high"]);
				min_value = min(min_value, values[i]["close"]);
				min_value = min(min_value, values[i]["open"]);

				max_value = max(max_value, values[i]["low"]);
				max_value = max(max_value, values[i]["high"]);
				max_value = max(max_value, values[i]["close"]);
				max_value = max(max_value, values[i]["open"]);
			}
		}

		var value_range = max_value - min_value;

		var value_per_pixel = 1;
		
		if (value_range > 0) {
			value_per_pixel = height / value_range.toFloat();
		}

		var px = x + width - 2;
		var dx = (width - 4).toFloat() / (values.size()-1).toFloat();

		var pts = [[px, y+height]];

		for (var i=values.size() - 1; i>=0; i--) {
			var candle = values[i];
			
			var cy = y+height - (candle["close"] - min_value) * value_per_pixel;

			var new_pt = [px, cy];
			pts.add(new_pt);

			px = px - dx;
		}
		pts.add([px+dx, y+height]);
		dc.setColor(getApp().screenColorLightShade(), Graphics.COLOR_WHITE);
		dc.fillPolygon(pts);

		dc.setColor(getApp().screenColorDarkShade(), Graphics.COLOR_WHITE);
		dc.setPenWidth(2);
		for (var i=1; i<pts.size()-2; i++) {
			dc.drawLine(pts[i][0], pts[i][1], pts[i+1][0], pts[i+1][1]);
		}
		dc.setPenWidth(1);
	}


	function updatePriceChart(dc as DC) {
		if (getApp().lineGraphEnabled()) {
			drawLineGraph(dc, m_Candles, 75, 85, 157, 48);
		} else {
			drawCandleStickGraph(dc, m_Candles, 78, 83, 91, 50);
		}
	}

	function updateMarket(dc as DC) {
		var label = View.findDrawableById("CryptoLabel") as Text;
		if (label) {
			if (m_Market) {
				var txt = formatMarketName(m_Market["name"]) + "  " + formatPrice(m_Market["price"]) + "  " + formatChange24h(m_Market["change24h"]);
				
				if (!m_MarketRefreshed or !m_CandlesRefreshed) {
					txt = txt + "!";
				}

				label.setText(txt);
			} else {
				label.setText("");
			}
		}
	}

	function setCandleStickData(data) {
		if (data.size() > 22) {
			m_Candles = data.slice( data.size() - 22, null);
			System.println(m_Candles);
		} else {
			m_Candles = data;
		}
	}

	function setCandleStickDataRefreshed(v) {
		m_CandlesRefreshed = v;
	}

	function formatMarketName(n) {
		var perp = n.find("-PERP");
		if (perp) {
			return n.substring(0, perp);
		}

		return n;
	}

	function formatPrice(p) {
		if (p < 1000) {
			return p.toString();
		} else {
			return (p.toFloat() / 1000).format("%.1f") + "K";
		}
	}

	function formatChange24h(c) {
		return (c * 100).format("%+.1f") + "%";
	}

	function setMarketData(data) {
		m_Market = data;
	}

	function setMarketDataRefreshed(v) {
		m_MarketRefreshed = v;
	}

	function loadBatteryIcon(bat) {
		if (bat == BATTERY_100) {
			return Application.loadResource( Rez.Drawables.battery_100_icon ) as BitmapResource;
		}
	
		if (bat == BATTERY_80) {
			return Application.loadResource( Rez.Drawables.battery_80_icon ) as BitmapResource;
		}
	
		if (bat == BATTERY_60) {
			return Application.loadResource( Rez.Drawables.battery_60_icon ) as BitmapResource;
		}
	
		if (bat == BATTERY_40) {
			return Application.loadResource( Rez.Drawables.battery_40_icon ) as BitmapResource;
		}
	
		if (bat == BATTERY_20) {
			return Application.loadResource( Rez.Drawables.battery_20_icon ) as BitmapResource;
		}
	
		return null;	
	}

	function updateBatteryIcon(dc as DC) {
		var battery_label = View.findDrawableById("Battery_Label") as Text;
		
		var battery_level = System.getSystemStats().battery;
		var battery_icon_type = BATTERY_100;		
		
		if (battery_level > 80) {
			battery_icon_type = BATTERY_100;
		} else {
			if (battery_level > 60) {
				battery_icon_type = BATTERY_80;
			} else {
				if (battery_level > 40) {
				battery_icon_type = BATTERY_60;
				} else {
					if (battery_level > 20) {
						battery_icon_type = BATTERY_40;
					} else {
						battery_icon_type = BATTERY_20;
					}
				}
			}
		} 
		
		if (m_LastBatteryIconType != battery_icon_type or m_BatteryIcon==null) {
			m_BatteryIcon = loadBatteryIcon(battery_icon_type);
        	m_LastBatteryIconType = battery_icon_type;
		} 
		
		dc.drawBitmap(battery_label.locX, battery_label.locY, m_BatteryIcon);
	}

	function loadMoveBarIcon(mbv) {
		if (mbv == 0) {
			return Application.loadResource( Rez.Drawables.movebar_0_icon ) as BitmapResource;
		}	
		if (mbv == 1) {
			return Application.loadResource( Rez.Drawables.movebar_1_icon ) as BitmapResource;
		}	
		if (mbv == 2) {
			return Application.loadResource( Rez.Drawables.movebar_2_icon ) as BitmapResource;
		}	
		if (mbv == 3) {
			return Application.loadResource( Rez.Drawables.movebar_3_icon ) as BitmapResource;
		}	
		if (mbv == 4) {
			return Application.loadResource( Rez.Drawables.movebar_4_icon ) as BitmapResource;
		}	
		if (mbv == 5) {
			return Application.loadResource( Rez.Drawables.movebar_5_icon ) as BitmapResource;
		}	

		return null;
	}

	function updateMovebar(dc as DC) {
		var label = View.findDrawableById("Movebar_Label") as Text;
		var movebar_value = ActivityMonitor.getInfo().moveBarLevel;
		if (movebar_value != m_LastMoveBarValue or m_MoveBarIcon == null) {
			m_MoveBarIcon = loadMoveBarIcon(movebar_value);
			m_LastMoveBarValue = movebar_value;		
		}
		
		dc.setColor(getApp().screenColor(), Graphics.COLOR_BLACK);
		dc.fillRectangle(label.locX, label.locY, 14, 29);
		dc.drawBitmap(label.locX, label.locY, m_MoveBarIcon);
	}

	function updateTime(dc as DC) {
        // Get the current time and format it correctly
        var clockTime = System.getClockTime();
        var timeFormat = "$1$:$2$";
        if (clockTime.sec % 2 == 0)
        {
        	//timeFormat = "$1$ $2$";
        }
        
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Update the view
        var view = View.findDrawableById("TimeLabel") as Text;
        view.setText(timeString);

        view = View.findDrawableById("SecondsLabel") as Text;
		var secondsString = "";
		if (m_HighPowerMode) {
			secondsString = clockTime.sec.format("%02d");
		}
        view.setText(secondsString);
	}

	function updateSteps(dc as DC) {
        var view = View.findDrawableById("Bottom_Label") as Text;
        view.setText(ActivityMonitor.getInfo().steps.format("%u"));
        view.setColor(getApp().screenColor());

        view = View.findDrawableById("Bottom_Label2") as Text;
        view.setColor(getApp().screenColor());
	}

	function updateDate(dc as DC) {
		var date = Gregorian.moment({});
		var info = Gregorian.info(date, Time.FORMAT_SHORT);
		var info_med = Gregorian.info(date, Time.FORMAT_MEDIUM);

		// Year
        var year_label = View.findDrawableById("YearLabel") as Text;
        
		var date_text = info.day.format("%u") + "-" + info.month.format("%u") + "-" + info.year.format("%u");

		year_label.setText(date_text);

/*
		// Day
        var day_label = View.findDrawableById("DayLabel") as Text;
        day_label.setText(info.day.format("%u"));

		// Month
        var month_label = View.findDrawableById("MonthLabel") as Text;
        if (month_label) {
			month_label.setText(info_med.month);
		}
*/
		// Day of week
		/*
		var monday_label = View.findDrawableById("DayOfWeek_Monday_Label") as Text;
		var tuesday_label = View.findDrawableById("DayOfWeek_Tuesday_Label") as Text;
		var wednesday_label = View.findDrawableById("DayOfWeek_Wednesday_Label") as Text;
		var thursday_label = View.findDrawableById("DayOfWeek_Thursday_Label") as Text;
		var friday_label = View.findDrawableById("DayOfWeek_Friday_Label") as Text;
		var saturday_label = View.findDrawableById("DayOfWeek_Saturday_Label") as Text;
		var sunday_label = View.findDrawableById("DayOfWeek_Sunday_Label") as Text;
		
		var selected_label = monday_label;

		var inactive_color = getApp().screenColorLightShade();		
	
		switch(info.day_of_week) {
		case Gregorian.DAY_MONDAY:
			monday_label.setColor(Graphics.COLOR_BLACK);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(inactive_color);
			break; 
		case Gregorian.DAY_TUESDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(Graphics.COLOR_BLACK);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(inactive_color);
			
			selected_label = tuesday_label;
			break; 
		case Gregorian.DAY_WEDNESDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(Graphics.COLOR_BLACK);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(inactive_color);
			
			selected_label = wednesday_label;
			break; 
		case Gregorian.DAY_THURSDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(Graphics.COLOR_BLACK);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(inactive_color);
			selected_label = thursday_label;
			break; 
		case Gregorian.DAY_FRIDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(Graphics.COLOR_BLACK);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(inactive_color);
			selected_label = friday_label;
			break; 
		case Gregorian.DAY_SATURDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(Graphics.COLOR_BLACK);
			sunday_label.setColor(inactive_color);
			selected_label = saturday_label;
			break; 
		case Gregorian.DAY_SUNDAY:
			monday_label.setColor(inactive_color);
			tuesday_label.setColor(inactive_color);
			wednesday_label.setColor(inactive_color);
			thursday_label.setColor(inactive_color);
			friday_label.setColor(inactive_color);
			saturday_label.setColor(inactive_color);
			sunday_label.setColor(Graphics.COLOR_BLACK);
			selected_label = sunday_label;
			break; 
		}
	
	var frame_bitmap = View.findDrawableById("weekday_frame") as Bitmap;
	frame_bitmap.locX = selected_label.locX - 4;
	frame_bitmap.locY = selected_label.locY - 3;
	*/
	}

	function updateWeather(dc as DC) {
		var temperature_label = View.findDrawableById("Temperature_Label") as Text;
		var weather = Weather.getCurrentConditions() as Weather.CurrentConditions;
		if (weather) {
			var temperature = weather.temperature;
			temperature_label.setText(temperature.format("%d") + "°");
		}
		else {
			temperature_label.setText("--°");
		}
	}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
		System.println("onShow");
		m_Candles = Application.Storage.getValue("candles");

		if (m_Candles == null) {
			m_Candles = new [22];
			for (var i=0; i<22; i++) {
				var candle = {};
				candle["low"] = 0;
				candle["high"] = 0;
				candle["open"] = 0;
				candle["close"] = 0;
				m_Candles[i] = candle;
			}
		}

		m_Market = Application.Storage.getValue("market");
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
		System.println("onHide");
		Application.Storage.setValue("candles", m_Candles);
		Application.Storage.setValue("market", m_Market);
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    	m_HighPowerMode = true;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    	m_HighPowerMode = false;
    }

}
