---
type: llm
weight: 1
---

PASS if:
- Recognizes that conditionally-rendered icons should animate on enter and exit
- Recommends animating with opacity, scale, and blur together
- Specifies enter animation timing around 200ms with ease-out
- Specifies exit animation timing around 150ms with ease-in
- For enter: opacity 0 to 1, scale 0.8 to 1, blur 4px to 0px
- For exit: opacity 1 to 0, scale 1 to 0.8, blur 0px to 4px
- Can suggest either CSS keyframes or Framer Motion AnimatePresence approach
- Explains that smooth transitions prevent jarring icon swaps

FAIL if:
- Does not recommend any animations (leaves icons swapping abruptly)
- Only includes one animation property (opacity alone, or scale alone)
- Does not mention blur as part of the animation
- Uses timing values significantly different from 200ms/150ms pattern
- Does not explain the principle (contextual icon animations)
- Recommends keep-alive for the icons instead of exit animations
