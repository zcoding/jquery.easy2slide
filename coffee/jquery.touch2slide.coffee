defaults =
  # 切换速度
  speed: 200
  # 切换的时间间隔
  interval: 3000

class Slider
  Length = 0
  timer = null
  isRunning = no
  currentIndex = 0
  Interval = defaults.interval
  playing = ()-> false
  _auto = no
  constructor: (Length, playAction) ->
    @Length = Length
    playing = playAction or playing
    @currentIndex = currentIndex

  # 切换到下一张
  next: ->
    if currentIndex is @Length-1 then currentIndex = 0  else currentIndex = currentIndex+1
    playing.apply this, [currentIndex]
    @currentIndex = currentIndex
    return this

  # 切换到上一张
  prev: ->
    if currentIndex is 0 then currentIndex = @Length-1  else currentIndex = currentIndex-1
    playing.apply this, [currentIndex]
    @currentIndex = currentIndex
    return this

  # 切换到某个元素
  # @param {Number} index 该元素在数组中的下标
  play: (index) ->
    if typeof index isnt "undefined"
      index = ~~index
    currentIndex = index or currentIndex
    currentIndex = 0 if currentIndex < 0
    currentIndex = @Length - 1 if currentIndex > @Length - 1
    playing.apply this, [currentIndex]
    @currentIndex = currentIndex
    return this

  # 自动播放
  # @param {Number} interval 自动切换的时间间隔
  autoplay: (interval = Interval) ->
    Interval = interval
    isRunning = yes
    if timer isnt null
      return this
    timer = setInterval (() =>
      if isRunning
        if currentIndex is @Length-1 then currentIndex =  0 else currentIndex = currentIndex+1
        playing.apply this, [currentIndex]
        @currentIndex = currentIndex
      ), Interval
    return this

  # 停止播放（必须先执行autoplay方法才有效）
  stop: ->
    isRunning = no
    if timer is null # 未执行autoplay
      return this
    clearInterval timer
    timer = null
    _auto = yes
    return this

  # 重启自动轮播（必须先执行autoplay和stop方法才有效）
  restart: ->
    isRunning = yes
    if _auto # 必须先执行stop
      # 重新执行autoplay方法
      @autoplay Interval
      # 必须再次执行stop才能执行restart
      _auto = no
    return this

  # 暂停/取消暂停
  # 该方法实现暂停或取消暂停自动播放（必须先执行autoplay方法才有效）
  # 可选的参数cancel表示是否取消暂停，如果cancel为true则表示取消暂停，如果为false表示暂停，该参数如果为其它值，则表示自动切换暂停/取消暂停
  # @return {Boolean} 是否正在播放
  pause: (cancel) ->
    if cancel is yes
      isRunning = yes
      return yes
    if cancel is no
      isRunning = no
      return no
    isRunning = not isRunning
    return isRunning

###

jQuery.fn.touch2slide

options:
  speed: 切换速度

###
$.fn.touch2slide = (options) ->
  options = $.extend {}, defaults, options

  $this = $(this)
  _$img = $this.children('img');

  Width = $this.width()
  Height = $this.height() - 20

  # 将<img>转成<a>
  _$img.replaceWith ()->
    return "<a href=\"javascript:void(0);\" style=\"background-image: url(#{$(this).attr('src')});\" class=\"u-img\"></a>"

  $images = $this.children '.u-img'

  $navigator = $this.children ".j-bullet-nav"
  $bullets = $navigator.children()

  noMore = "<div style=\"display: none;width: 600px;height: 400px;margin: 0;padding: 0;position: absolute;font-size: 32px;color: #888;text-align: center;line-height:#{ Height }px;\" class=\"j-no_more\">^_^ 别拉了！真的没有了 ^_^</div>"

  $this.prepend noMore
  $navigator.before noMore

  $cards = $this.children ".u-img, .j-no_more"

  # 样式初始化
  $navigator.css {
    position: "absolute"
    width: Width
    top: Height
    left: 0
    textAlign: "center"
  }

  $bullets.css({
    display: "inline-block"
    margin: "10px 10px 0 0"
    width: 10
    height: 10
    background: "#AAAAAA"
    borderRadius: 10
  }).eq(0).css {
    background: "#5CC56F"
  }

  # 位置初始化
  $cards.each (index, ele) ->
    $(ele).css {
      display: "block"
      top: 0
      left: (index - 1) * Width
    }

  # 事件初始化
  events =
    start: "touchstart.ztouch"
    move: "touchmove.ztouch"
    end: "touchend.ztouch"
    cstart: "mousedown.ztouch"
    cmove: "mousemove.ztouch"
    cend: "mouseup.z-couth"
  # 清除原有事件
  $this.off events.touch
  $this.off events.move
  $this.off events.end
  $this.off events.ctouch
  $this.off events.cmove
  $this.off events.cend

  speed = options.speed

  player = new Slider($images.length, (ci) ->
    $cards.each (index, ele) =>
      $(ele).animate {
        left: (index - 1 - ci) * Width
      }, speed
    $bullets.css("background", "#AAAAAA").eq(ci).css("background", "#5CC56F")
    true)

  move = (delta) ->
    $cards.each (index, ele) ->
      ele.style.left = "#{(index - player.currentIndex - 1) * Width + delta.sx}px"

  position =
      x: 0
      y: 0

  delta =
    sx: 0
    sy: 0

  startTime = 0

  $this.on events.start, ".u-img", (evt) ->
    touches = evt.originalEvent.touches
    if touches.length is 1
      evt.preventDefault()
      position.x = touches[0].pageX
      position.y = touches[0].pageY
      startTime = new Date()
      # 停止自动轮播
      player.stop()
    return yes

  $this.on events.move, ".u-img", (evt) ->
    touches = evt.originalEvent.touches;
    if touches.length is 1
      evt.preventDefault()
      delta.sx = touches[0].pageX - position.x
      delta.sy = touches[0].pageY - position.y
      _delta = Math.floor Math.sqrt(delta.sx**2 + delta.sy**2)
      if _delta > 10 # 缓冲
        move.apply player, [delta]
    return yes

  $this.on events.end, ".u-img", (evt) ->
    evt.preventDefault()
    # 重启自动轮播
    player.restart()
    if delta.sx is 0
      return yes
    _interval = new Date() - startTime
    if _interval > 100 and -50 < delta.sx < 50 or player.currentIndex is 0 and delta.sx > 0 or player.currentIndex is $cards.length - 3 and delta.sx < 0
      delta.sx = 0
      delta.sy = 0
      player.play()
      return yes
    if delta.sx < 0
      player.next()
    else
      player.prev()
    delta.sx = 0
    delta.sy = 0
    return yes

  return player
