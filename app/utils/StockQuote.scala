package utils

trait StockQuote {
  def newPrice(symbol: String): Double
}
