class Dashing.Histogram extends Dashing.Widget

  ready: ->
    container = $(@node).parent()
    # Gross hacks. Let's fix this.
    console.log(Dashing.widget_margins)
    width = (Dashing.widget_base_dimensions[0] * container.data("sizex")) + Dashing.widget_margins[0] * 2 * (container.data("sizex") - 1)
    height = (Dashing.widget_base_dimensions[1] * container.data("sizey"))
    @palette = new Rickshaw.Color.Palette(scheme: 'cool' )
    @graph = new Rickshaw.Graph(
      element: @node
      width: width
      height: height
      renderer: @get("graphtype")
      series: [
        {
        color: '#fff'
        data: [{x:0, y:0}]
        }
      ]
    )

    timeUnit = (new Rickshaw.Fixtures.Time()).unit('day')
    timeUnit.formatter = (d) ->
      d3.time.format('%a% %e')(d)
    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph, timeUnit: timeUnit)
    y_axis = new Rickshaw.Graph.Axis.Y(graph: @graph, tickFormat: Rickshaw.Fixtures.Number.formatKMBT)
    if @get("graphtype") != 'bar'
      hoverDetail = new Rickshaw.Graph.HoverDetail
        graph: @graph
        xFormatter: (x) ->
          timeUnit.formatter(new Date(x * 1000))
    else
      @graph.renderer.unstack = true
    @graph.render()

  onData: (event) ->
    if @graph
      @palette.runningIndex = 0  # Reset color selection, to get consistent colors
      (@graph.series.pop() for series in @graph.series)
      (@graph.series.push($.extend(series,{color: series.color || @palette.color()})) for series in event.series)
      @graph.render()
