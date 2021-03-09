$ ->
  ws = new WebSocket $("body").data("ws-url")
  ws.onmessage = (event) ->
    message = JSON.parse event.data
    switch message.type
      when "stockhistory"
        populateStockHistory(message)
      when "stockupdate"
        updateStockChart(message)
      else
        console.log(message)

  $("#addsymbolform").submit (event) ->
    event.preventDefault()
    # send the message to watch the stock
    ws.send(JSON.stringify({symbol: $("#addsymboltext").val(), action: "add"}))
    # reset the form
    $("#addsymboltext").val("")

  @removeStock = (symbol) ->
    ws.send(JSON.stringify({symbol: symbol, action: "remove"}))
    $('#R-' + symbol).remove()

getPricesFromArray = (data) ->
  (v[1] for v in data)

getChartArray = (data) ->
  ([i, v] for v, i in data)

getChartOptions = (data) ->
  series:
    shadowSize: 0
  yaxis:
    min: getAxisMin(data)
    max: getAxisMax(data)
  xaxis:
    show: false

getAxisMin = (data) ->
  Math.min.apply(Math, data) * 0.9

getAxisMax = (data) ->
  Math.max.apply(Math, data) * 1.1

populateStockHistory = (item) ->
  $("#watchlist").append("<tr id='R-" + item.symbol + "'><td>" + item.symbol + "</td><td id='" + item.symbol + "'>" + item.price + "</td><td><button class=\"btn btn-default\" type=\"submit\" onclick='removeStock(\"" + item.symbol + "\")'>Remove</button></td></tr>");

updateStockChart = (item) ->
  if ( $('#' + item.symbol).length )
    $('#' + item.symbol).html(item.price);

handleFlip = (container) ->
  if (container.hasClass("flipped"))
    container.removeClass("flipped")
    container.find(".details-holder").empty()
  else
    container.addClass("flipped")
    # fetch stock details and tweet
    $.ajax
      url: "/sentiment/" + container.children(".flipper").attr("data-content")
      dataType: "json"
      context: container
      success: (data) ->
        detailsHolder = $(this).find(".details-holder")
        detailsHolder.empty()
        switch data.label
          when "pos"
            detailsHolder.append($("<h4>").text("The tweets say BUY!"))
            detailsHolder.append($("<img>").attr("src", "/assets/images/buy.png"))
          when "neg"
            detailsHolder.append($("<h4>").text("The tweets say SELL!"))
            detailsHolder.append($("<img>").attr("src", "/assets/images/sell.png"))
          else
            detailsHolder.append($("<h4>").text("The tweets say HOLD!"))
            detailsHolder.append($("<img>").attr("src", "/assets/images/hold.png"))
      error: (jqXHR, textStatus, error) ->
        detailsHolder = $(this).find(".details-holder")
        detailsHolder.empty()
        detailsHolder.append($("<h2>").text("Error: " + JSON.parse(jqXHR.responseText).error))
    # display loading info
    detailsHolder = container.find(".details-holder")
    detailsHolder.append($("<h4>").text("Determing whether you should buy or sell based on the sentiment of recent tweets..."))
    detailsHolder.append($("<div>").addClass("progress progress-striped active").append($("<div>").addClass("bar").css("width", "100%")))
