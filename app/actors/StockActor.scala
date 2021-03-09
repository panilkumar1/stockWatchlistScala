package actors

import akka.actor.{Actor, ActorLogging, ActorRef}
import akka.event.LoggingReceive
import utils.{YahooStockQuote, StockQuote}

import scala.collection.immutable.{HashSet, Queue}
import scala.concurrent.duration._

/**
 * There is one StockActor per stock symbol.  The StockActor maintains a list of users watching the stock and the stock
 * values.  Each StockActor updates a rolling dataset of randomly generated stock values.
 */
class StockActor(symbol: String) extends Actor with ActorLogging {
  private val fetchLatestInterval = 5.seconds

  lazy val stockQuote: StockQuote = new YahooStockQuote

  protected[this] var watchers: HashSet[ActorRef] = HashSet.empty[ActorRef]

  // Fetch the latest stock value every 75ms
  val stockTick = {
    // scheduler should use the system dispatcher
    context.system.scheduler.schedule(Duration.Zero, fetchLatestInterval, self, FetchLatest)(context.system.dispatcher)
  }

  def receive = LoggingReceive {
    case FetchLatest =>
      // add a new stock price to the history and drop the oldest
      val newPrice: Double = stockQuote.newPrice(symbol)
      // notify watchers
      watchers.foreach(_ ! StockUpdate(symbol, newPrice))
    case WatchStock(_) =>
      val newPrice: Double = stockQuote.newPrice(symbol)
      // send the stock history to the user
      sender ! StockHistory(symbol, newPrice)
      // add the watcher to the list
      watchers = watchers + sender
    case UnwatchStock(_) =>
      watchers = watchers - sender
      if (watchers.isEmpty) {
        stockTick.cancel()
        context.stop(self)
      }
  }
}


case object FetchLatest

case class StockUpdate(symbol: String, price: Number)

case class StockHistory(symbol: String, price: Number)

case class WatchStock(symbol: String)

case class UnwatchStock(symbol: Option[String])
