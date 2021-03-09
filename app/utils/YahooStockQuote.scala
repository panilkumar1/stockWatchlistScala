package utils

import yahoofinance.YahooFinance

class YahooStockQuote extends StockQuote {

  def newPrice(symbol: String): Double = {
    YahooFinance.get(symbol).getQuote().getPrice().doubleValue()
  }
}
