// It is common for developers to wrap a makeWebRequest() call in a function
// as displayed below. The function defines the variables for each of the
// necessary arguments in a Communications.makeWebRequest() call, then passes
// these variables as the arguments. This allows for a clean layout of your web
// request and expandability.
using Toybox.System;
using Toybox.Communications;
using Toybox.Time;
using Toybox.Background;

(:background)
class BgServiceDelegate extends Toybox.System.ServiceDelegate {

    var m_CandlesReceived;
    var m_MarketReceived;

    var m_CandlesData;
    var m_MarketData;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        System.println("onTemporalEvent");

        m_CandlesReceived = false;
        m_MarketReceived = false;

        updateCandleData();
        updateMarketData();
    }

   // set up the response callback function
   function onReceiveCandles(responseCode, data) {
       m_CandlesReceived = true;
       
       if (responseCode == 200) {
            System.println("Candles received successfully");                   // print success
            var temp = data["result"].slice( data["result"].size() - 22, null);
            m_CandlesData = [];

            for (var i=0; i<temp.size(); i++) {
                var candle = [];
                candle.add(temp[i]["open"].toFloat());
                candle.add(temp[i]["close"].toFloat());
                candle.add(temp[i]["low"].toFloat());
                candle.add(temp[i]["high"].toFloat());
                m_CandlesData.add(candle);
            }
       }
       else {
            System.println("Candles request failed: " + responseCode);            // print response code
            m_CandlesData = null;
       }
    updateWatchface();
   }

   // set up the response callback function
   function onReceiveMarket(responseCode, data) {
        m_MarketReceived = true;

        if (responseCode == 200) {
                System.println("Market received successfully");                   // print success
                m_MarketData = { "price" => data["result"]["price"].toFloat(), "change24h" => data["result"]["change24h"].toFloat(), "name" => data["result"]["name"] };
        }
        else {
                System.println("Market request failed: " + responseCode);            // print response code
                m_MarketData = null;
        }
        updateWatchface();
   }

   function updateWatchface() {
        if (m_CandlesReceived and m_MarketReceived) {
            var result = { "candles" => m_CandlesData, "market" => m_MarketData };
            try {
                Background.exit(result);
            }
            catch (ex) {
                System.println("Exception: " + ex.getErrorMessage());
                ex.printStackTrace();
                
                // remove every 2nd candle
                var temp = [];
                for (var i=0; i<result["candles"].size(); i++) {
                    if (i % 2 == 0) {
                        temp.add(result["candles"][i]);
                    }
                }
                result["candles"] = temp;
                
                try {
                    Background.exit(result);
                }
                catch (ex2) {
                    System.println("Exception again, giving up");
                    Background.exit(null);
                }
            }
        }
   }

   function updateCandleData() {
       System.println("updateCandleData()");
       // https://ftx.com/api/markets/btc-perp/candles?resolution=3600&start_time=1638904858
       
       var url = "https://ftx.com/api/markets/btc-perp/candles";   // set the url

       var start_time = Time.now().value() - (24*3600);

       var params = {                                              // set the parameters
              "resolution" => "3600",
              "start_time" => start_time
       };

       var options = {                                             // set the options
           :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };

       var responseCallback = method(:onReceiveCandles);                  // set responseCallback to
                                                                   // onReceive() method
       // Make the Communications.makeWebRequest() call
       Communications.makeWebRequest(url, params, options, method(:onReceiveCandles));
  }

   function updateMarketData() {
       System.println("updateMarketData()");
       // https://ftx.com/api/markets/btc-perp
       
       var url = "https://ftx.com/api/markets/btc-perp";   // set the url

       var params = { };

       var options = {                                             // set the options
           :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };

       var responseCallback = method(:onReceiveMarket);            // set responseCallback to
                                                                   // onReceive() method
       // Make the Communications.makeWebRequest() call
       Communications.makeWebRequest(url, params, options, method(:onReceiveMarket));
  }


}