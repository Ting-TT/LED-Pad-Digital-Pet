---
title: "COMP2300 Assignment Design Document"
author: Ting Tang
email: u7228238@anu.edu.au
---

## _What_ my design is

**My digital pet is a dog. He has three properties: `health_level`, `hunger_level` and `happiness_level`, all stored in memory.**

The initial levels are health=90, hunger=30, happiness=50.

**By using  SysTick_Handler**, every 8 seconds, health-10, hunger+10, happiness-10.

When health=0 or hunger=100, dog is dead, display a cross, disable all interrupts.

**A changing dog pattern** is displayed according to values of three properties.

- Happiness determines brightness of the pattern. Happier the dog, brighter the pattern.

- hunger>=70: the dog pattern blinks to remind you to feed him. Hungrier the dog, quicker the pattern blinks.

- health<=30: a standing dog lying down.
- 30<health<80: a normal-size dog wagging his tail.
- health>=80: a tall dog wagging his tail.


**You can interact with him by pressing buttons or touch the “logo” to trigger  GPIOTE interrupts:**

- Press **Button A** to enter “Feed Mode”: health+5, hunger-10; display an eating face with the mouth keep opening and closing, **audio is played as well**.

- Press **Button B** to enter “Play Mode”: health+5, happiness+10; display a jumping dog for several seconds.

- Touch the logo (**touch sensor**) to enter “Not-able-to-breathe Mode”: health-50, happiness-20; display an unhappy face. **This interrupt can only be triggered after LEDs are displaying “Feed Mode” or “Play Mode”.** Touching the logo at this time means you accidently cover the dog’s nose/mouth, so he cannot breathe. This should not be done on purpose, it only occurs like an incident.

After any of these interrupts, LEDs will display values of dog’s current state. 
row 0th: health, 2nd: hunger, 4th: happiness. The value for each level is number of LEDs turned on in that row out of 5.

  

## _How_ have I implemented my design

### Displaying patterns:

- `write_row_states` modifies a row of LEDs’ states stored in memory.

- `present_pattern` displays a corresponding pattern according to all LEDs’ states stored in the memory. It loops over all five rows, turning each on and off. It has three inputs determining pattern’s display time and brightness.

- `brightness_based_on_happiness` reads happiness level from memory, outputs two values used as inputs for `present_pattern` to control brightness.

### SysTick interrupt:

- **`systick_counts` in memory stores number of systick interrupts being triggered.**
Since it will be triggered every ¼ seconds, so every 8 seconds changing dog’s states means that only when systick counts is 32, `SysTick_Handler` will modify dog’s states in memory.

- It checks if the dog is dead, if so, it disables all interrupts.

### GPIOTE interrupt:

- Channel 0 for button A, channel 1 for button B, channel 2 for touch sensor.

- **Number of times each button/sensor been triggered is stored in the memory.**

- **`GPIOTE_IRQHandler` only finds which event triggered it and modifies its value in memory.**

- In `main`, the program loads values from memory and displays corresponding interactions. Touch sensor is fully enabled only when displaying button A’s or B’s interactions.
  


## _Why_ is my implementation appropriate for the task

  
- **Array is used to store pet’s states** because my dog has three numbers to represent his states and they have **equal length**. Array makes the program **easy to read and modify the data**.

- I choose **not to display interactions in `GPIOTE_IRQHandle`** but only change data in memory and **display interactions in main**, because handlers are meant to be quick in and out, and high-level program flow should not be placed inside. Also, audio cannot work inside handlers.

- However, this leads to a problem I did not manage to solve: **not able to keep track of the order interrupts occurred.**
It only stores the number of times each button/sensor was triggered, so the display order just follows the flow of checking for each button/sensor in `main`.
