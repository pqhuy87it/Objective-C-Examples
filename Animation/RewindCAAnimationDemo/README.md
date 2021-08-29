I am trying to pause CABasicAnimation at some point during the animation by setting layers speed property to 0.0 (and adjusting time offset) I then want to be able to resume animation. This bit works fine. I would like to at certain circumstance reverse the direction of the animation and animate to origin. ie setting the speed of layer to -1. No matter what I do I can't get it to animate backwards after pausing the layer. I have now spent on it literally whole days. There examples on how to pause animation and how to resume in documentation, but nothing about rewinding. Can you please tell me how to adjust layers timeOffset and beginTime and Speed so that animation animates backwards. Thank you very much for your time and looking forward to hearing from you.

I have created small sample project witch animates view's layer origin.y form top to bottom of screen.

Please press "Start" to start animation

Please press "Pause" to pause animation

Please press "Resume" to resume animation

Please observe animation continues form point at witch it was paused.

Please press "Start" again.

Please press "Pause"

Please press "Rewind"

Observe animation does not animate to original position (rewind).
