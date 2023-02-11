---
title: "Design Proposal"
author: Ting Tang
email: u7228238@anu.edu.au
---

<!-- write your design proposal here -->

Without doing anything, LEDs will display a jumping and moving puppy all the time. 

My pet has three states: health, hungriness and happiness. These will be stored in an array of “integers” in the memory, each occupies a word.

Health level will decrease a certain amount and hungriness will increase a certain amount after some certain period. This probably can be achieved by using SysTick_Handler. (?) After hunger level achieve a number, it can decrease the health level to zero. When health level is zero, a cross will be displayed to indicate that pet is dead.

Button A is like “feeding the puppy”. Button B is like “playing with the puppy”.

Things below will be achieved by GPIOTE_IRQHandler.
After pressing Button A, LEDs will display patterns: a face with a keep-opening-and-closing mouth, then some portions of LEDs turned on to show its health level, and then its hunger level. Pressing Button A will also decrease its hungriness. 
After pressing Button B, LEDs will display patterns: a jumping smiley face, then some portions of LEDs turned on to show its health level, and then its happiness level. Pressing Button B will also increase its happiness level. 
