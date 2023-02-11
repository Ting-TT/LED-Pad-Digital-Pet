.syntax unified
.global main

.type main, %function
main:
  @ init leds
  bl init_leds
  @ init audio
  bl audio_init

@ set for SysTick interrupt
  @ set the enable bit, TICKINT bit and clock source in SYST_CSR
  ldr r0, =ADR_SYST_CSR
  ldr r1, =(1 << 0 | 1 << 1 | 1 << 2)
  str r1, [r0]
  @ count down from 16000000, so it will go to the interrupt every 1/4 second
  ldr r0, =ADR_SYST_RVR
  ldr r1, =16000000
  str r1, [r0]
  @ set SysTick interrupt priority to 2
  ldr r0, =ADR_SCB_SHPR3
  ldr r1, =(2 << 29)
  str r1, [r0]


@ set for GPIOTE interrupt
  @ 1: configure GPIOTE_CONFIG[0] and GPIOTE_CONFIG[1]
  @ for button A (P0.14)
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_CONFIG0
  ldr r2, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r2, [r0, r1]
  @ for button B (P0.23)
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_CONFIG1
  ldr r2, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
  str r2, [r0, r1]

  @ 2: enable Interrupt for GPIOTE[0], GPIOTE_CONFIG[1] and GPIOTE_CONFIG[2].
  @ GPIOTE_CONFIG[2] will be used for touch sensor which is enabled only 
  @ during GPIOTE interrupt 
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_INTENSET
  ldr r2, =(1 << 0 | 1 << 1 | 1 << 2)
  str r2, [r0, r1]

  @ 3: enable GPIOTE (interrupt #6 = NVIC_GPIOTE_ID) in NVIC_ISER0
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_ISER0
  ldr r2, =(1 << 6)
  str r2, [r0, r1]

  @ 4: set GPIOTE interrupt priority to 1
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_IPR1
  ldr r2, =(1 << 21)
  str r2, [r0, r1]


  @ show interactions or other moving patterns of the dog
  dog_show:

  @ ensure face_touch is disabled
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(0 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]

  @ read the memory to check if any GPIOTE interrupt was triggered
  @ button A was pressed, display feed mode

  ldr r0, =button_A
  ldr r1, [r0]
  cmp r1, 0
  beq check_button_B_state
  @ enable touch sensor/logo (face_touch) (P1.04)
  @ configure GPIOTE_CONFIG[2] for face_touch
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(1 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]
  @ health level plus 5
  ldr r0, =health_level
  ldr r1, [r0]
  add r1, 5
  str r1, [r0]
  @ hunger level minus 10
  ldr r0, =hunger_level
  ldr r1, [r0]
  sub r1, 10
  str r1, [r0]
  @ display an eating face with the mouth keep opening and closing
  @ to show that you are feeding the dog
  mov r5, 3
  eating_mouth_loop:
  ldr r0, =0x40
  ldr r1, =3000
  ldr r2, =0
  bl present_eat1
  ldr r0, =0x40
  ldr r1, =3000
  ldr r2, =0
  bl present_eat2
  sub r5, 1
  cmp r5, 0
  beq end_eating_mouth_loop
  b eating_mouth_loop
  end_eating_mouth_loop:
  @ show current dog states
  ldr r0, =0x1000
  bl present_dog_states
  @ disable face_touch after GPIOTE interrupt is finished
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(0 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]
  @ minus 1 from button A state stored in memory
  ldr r0, =button_A
  ldr r1, [r0]
  sub r1, 1
  str r1, [r0]

  
  @ button B was pressed, display play mode

  check_button_B_state:
  ldr r0, =button_B
  ldr r1, [r0]
  cmp r1, 0
  beq check_touch_sensor_state
  @ enable touch sensor/logo (face_touch) (P1.04)
  @ configure GPIOTE_CONFIG[2] for face_touch
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(1 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]
  @ health level plus 5
  ldr r0, =health_level
  ldr r1, [r0]
  add r1, 5
  str r1, [r0]
  @ happiness level plus 10
  ldr r0, =happiness_level
  ldr r1, [r0]
  add r1, 10
  str r1, [r0]
  @ display a jumping dog to show that you are playing with him
  mov r5, 5
  mov r8, 500
  dog_jump_loop:
  ldr r0, =500
  ldr r1, =1000
  ldr r2, =0
  bl present_dog_n1
  ldr r0, =500
  ldr r1, =1000
  ldr r2, =0
  bl present_dog_jump
  sub r5, 1
  cmp r5, 0
  beq end_dog_jump_loop
  b dog_jump_loop
  end_dog_jump_loop:
  @ show current dog states
  ldr r0, =0x1000
  bl present_dog_states
  @ disable face_touch after GPIOTE interrupt is finished
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(0 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]
  @ minus 1 from button B state stored in memory
  ldr r0, =button_B
  ldr r1, [r0]
  sub r1, 1
  str r1, [r0]


  @ face_touch(logo) was touched, display not-able-to-breathe mode
  
  check_touch_sensor_state:
  ldr r0, =touch_sensor
  ldr r1, [r0]
  cmp r1, 0
  beq check_button_A_again
  @ health level minus 50
  ldr r0, =health_level
  ldr r1, [r0]
  sub r1, 50
  cmp r1, 0
  ble dead
  str r1, [r0]
  @ happiness level minus 20
  ldr r0, =happiness_level
  ldr r1, [r0]
  sub r1, 20
  cmp r1, 0
  bge store_happy
  mov r1, 0  @ keep the minimum number for happiness level be 0
  store_happy:
  str r1, [r0]
  @ display an unhappy face to show that the dog suddenly cannot breathe
  ldr r0, =0x1000
  ldr r1, =1000
  ldr r2, =0
  bl present_unhappy
  @ show current dog states
  ldr r0, =0x1000
  bl present_dog_states
  @ store touch sensor state as 0 in memory
  ldr r0, =touch_sensor
  mov r1, 0
  str r1, [r0]
  
  @ display all GPIOTE interrupts before displaying the dog
  check_button_A_again:
  ldr r0, =button_A
  ldr r1, [r0]
  cmp r1, 0
  beq check_button_B_again
  b dog_show
  
  check_button_B_again:
  ldr r0, =button_A
  ldr r1, [r0]
  cmp r1, 0 @ display the dog after all GPIOTE interrupts have been displayed
  beq dog_current
  b dog_show



  @ after displaying animation for all GPIOTE interrupts,
  @ display dog's current state
  dog_current:

  @ if the dog's health = 0 or hunger >= 100, the dog is dead :(
  @ display a cross sign
  @ no more interactions will happen, disable all interrupts
  ldr r0, =health_level
  ldr r4, [r0] @ save dog's health level into r4
  cmp r4, 0
  ble dead
  ldr r0, =hunger_level
  ldr r5, [r0] @ save dog's hunger level into r5
  cmp r5, 100
  bge death_loop
  b dog_alive
  dead:
  @ disable systick interrupt
  ldr r0, =ADR_SYST_CSR
  ldr r1, =(0 << 0)
  str r1, [r0]
  @ disable the GPIOTE interrupt
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_ICER0
  ldr r2, =(1 << 6)
  str r2, [r0, r1]
  death_loop:
  ldr r0, =0x200
  ldr r1, =1000
  ldr r2, =0
  bl present_dog_dead
  b death_loop
  dog_alive:

  @ if the dog is hungry (hunger >= 70), display a blinking dog pattern
  cmp r5, 70
  blt dog_not_hungry
  mov r0, r5
  bl present_dog_blink
  b dog_show
  dog_not_hungry:

  @ if the dog is not hungry but he is old (health <= 30), 
  @ display a dog lying pattern
  cmp r4, 30
  bgt dog_not_old
  bl brightness_based_on_happiness
  ldr r0, =0x300
  bl present_dog_n1
  bl brightness_based_on_happiness
  ldr r0, =0x700
  bl present_dog_old
  ldr r0, =0x500000
  bl delay
  b dog_show
  dog_not_old:

  @ if the dog is very healthy (health >= 80),
  @ display a tall dog wagging his tail
  cmp r4, 80
  blt dog_normal
  bl brightness_based_on_happiness
  ldr r0, =0x200
  bl present_dog_h1
  bl brightness_based_on_happiness
  ldr r0, =0x200
  bl present_dog_h2
  b dog_show
  dog_normal:

  @ if the dog's health level is between 30 to 80 (30 < health < 80)
  @ display a normal-size dog wagging his tail
  bl brightness_based_on_happiness
  ldr r0, =0x200
  bl present_dog_n1
  bl brightness_based_on_happiness
  ldr r0, =0x200
  bl present_dog_n2
  b dog_show

  b main
.size main, .-main




.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {r4-r12, lr}
  
  ldr r4, =systick_counts
  ldr r5, [r4]
  cmp r5, 32 @ every 8 seconds, change dog's states stored in memory
  bne add_systick_count

  @ every 8 seconds, dog's health level minus 10
  ldr r0, =health_level
  ldr r1, [r0]
  sub r1, 10
  str r1, [r0]
  cmp r1, 0 @ when dog's health level is less than or equal to 0, he is dead.
  ble disable_interrupts

  @ every 8 seconds, dog's hunger level plus 10
  ldr r0, =hunger_level
  ldr r1, [r0]
  add r1, 10
  str r1, [r0]
  cmp r1, 100 @ when dog's health level is greater than or equal to 100, he is dead.
  bge disable_interrupts

  @ every 8 seconds, dog's happiness level minus 10
  ldr r0, =happiness_level
  ldr r1, [r0]
  cmp r1, 10
  ble happiness_zero
  sub r1, 10
  b store_happiness_level
  happiness_zero: @ keep the minimum number for happiness level be 0
  mov r1, 0
  store_happiness_level:
  str r1, [r0]
  b add_systick_count

  disable_interrupts:
  @ disable systick interrupt
  ldr r0, =ADR_SYST_CSR
  ldr r1, =(0 << 0)
  str r1, [r0]
  @ disable the GPIOTE interrupt
  ldr r0, =ADR_NVIC
  ldr r1, =OFS_NVIC_ICER0
  ldr r2, =(1 << 6)
  str r2, [r0, r1]
 
  add_systick_count:
  add r5, 1
  cmp r5, 33
  bne finish_systick_interrupt
  mov r5, 1
  finish_systick_interrupt:
  str r5, [r4]
  pop {r4-r12, lr}
  bx lr
.size SysTick_Handler, .-SysTick_Handler





.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {r4-r12, lr}

  @ check GPIOTE interrupt is triggered by event from which channel
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN0
  ldr r4, [r0, r1]
  cmp r4, 1
  beq feed_mode @ GPIOTE interrupt is triggered by button A from channel 0

  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN1
  ldr r5, [r0, r1]
  cmp r5, 1
  beq play_mode @ GPIOTE interrupt is triggered by button A from channel 1

  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN2
  ldr r6, [r0, r1]
  cmp r6, 1
  beq unable_to_breathe @ interrupt is triggered by face_touch from channel 2


  @ feed mode
  @ GPIOTE interrupt is triggered by button A
  feed_mode:
  ldr r0, =button_A
  ldr r1, [r0]
  add r1, 1
  str r1, [r0]
  b clear_event

  @ play mode
  @ GPIOTE interrupt is triggered by button B
  play_mode:
  ldr r0, =button_B
  ldr r1, [r0]
  add r1, 1
  str r1, [r0]
  b clear_event

  @ unable-to-breathe mode
  @ GPIOTE interrupt is triggered by face_touch
  unable_to_breathe:
  ldr r0, =touch_sensor
  mov r1, 1
  str r1, [r0]

  
  @ clear current event
  clear_event:
  cmp r4, 1
  beq clear_event_in_channel_0
  cmp r5, 1
  beq clear_event_in_channel_1

  @ clear event in channel 2 if face_touch triggered this interrupt
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN2
  ldr r2, =0
  str r2, [r0, r1]
  b end_current_interrupt

  @ clear event in channel 0 if button A triggered this interrupt
  clear_event_in_channel_0:
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN0
  ldr r2, =0
  str r2, [r0, r1]
  b end_current_interrupt
  
  @ clear event in channel 1 if button B triggered this interrupt
  clear_event_in_channel_1:
  ldr r0, =ADR_GPIOTE
  ldr r1, =OFS_GPIOTE_EVENTS_IN1
  ldr r2, =0
  str r2, [r0, r1]

  end_current_interrupt:
  @ ensure face_touch is disabled
  ldr r1, =OFS_GPIOTE_CONFIG2
  ldr r2, =(0 | 4 << 8 | 1 << 13 | 1 << 16)
  str r2, [r0, r1]
  pop {r4-r12, lr}
  bx lr
.size GPIOTE_IRQHandler, .-GPIOTE_IRQHandler




.type write_row_states, %function
@ rewrite the states of a row of leds in the memory
@ --parameters--
@ r0: row number (from 0 to 4)
@ r1: leds' states for this row (states for smaller columns in lower bits)
@ e.g. r1 = 0b00001 : led in column 0 should be turned on, others all turned off
write_row_states:
  push {r4-r12, lr}
  ldr r2, =light_states
  mov r3, 4
  mul r0, r3 @ r0 now is the offset for light states address
  str r1, [r2, r0]
  pop {r4-r12, lr}
  bx lr
.size write_row_states, .-write_row_states


.type present_pattern, %function
@ based on the leds' states stored in the memory, show the current pattern
@ --parameters--
@ r0: counter, how many times to loop over the pattern,
@ which means how long will the pattern be displayed
@ r1: delay time when the lights are on in every row
@ r1 will control the brightness of the pattern (brighter as r1 get larger)
@ r2: delay time when the lights are off in every row
@ r2 will control the brightness of the pattern (dimmer as r2 get larger) 
present_pattern:
  push {r4-r12, lr}

  mov r8, r0 @ save the counter for loop_over_pattern in r8
  mov r9, r1 @ save the delay time after turn on the row lights in r9
  mov r10, r2 @ save the delay time after turn off the row lights in r10

  loop_over_pattern:
  sub r8, 1
  cmp r8, 0
  ble end_present_pattern @ counter = 0, stop presenting the pattern

  mov r4, 0 @ r4: row number
  loop_over_rows:
  cmp r4, 4
  bgt loop_over_pattern @ all five rows have been lit, start from row 0 again
  mov r0, 0b1
  lsl r0, r4
  bl write_row_pins

  ldr r5, =0b11111 @ r5: used to toggle bits
  ldr r1, =light_states
  mov r2, 4
  mul r6, r4, r2 @ r6: offset for getting the light states
  ldr r0, [r1, r6]
  eor r0, r5 @ toggle light states to become the input for wwrite_column_pins
  bl write_column_pins

  @ delay to make pattern brighter
  mov r0, r9
  bl delay

  @ turn off all leds
  ldr r0, =0b00000
  bl write_row_pins
  ldr r0, =0b11111
  bl write_column_pins

  @ delay to make pattern dimmer
  mov r0, r10
  bl delay

  @ move to light next row
  add r4, 1
  b loop_over_rows
  
end_present_pattern:
  pop {r4-r12, lr}
  bx lr
.size present_pattern, .-present_pattern


.type present_dog_n1, %function
@ displaying the normal dog pattern 1
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_n1:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for normal dog pattern 1
  mov r0, 0
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 2
  ldr r1, =0b10011
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01010
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_n1, .-present_dog_n1

.type present_dog_n2, %function
@ displaying the normal dog pattern 2
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_n2:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for normal dog pattern 2
  mov r0, 0
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 2
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 3
  ldr r1, =0b11110
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01010
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_n2, .-present_dog_n2


.type present_dog_h1, %function
@ displaying the healthy dog pattern 1
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_h1:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for healthy dog pattern 1
  mov r0, 0
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 1
  ldr r1, =0b10011
  bl write_row_states
  mov r0, 2
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01010
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_h1, .-present_dog_h1

.type present_dog_h2, %function
@ displaying the healthy dog pattern 2
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_h2:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for healthy dog pattern 2
  mov r0, 0
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 2
  ldr r1, =0b11110
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01010
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_h2, .-present_dog_h2


.type present_dog_old, %function
@ displaying the lying dog pattern which means the dog is old
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_old:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for a lying dog pattern
  mov r0, 0
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 2
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 3
  ldr r1, =0b10011
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01110
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_old, .-present_dog_old

.type present_dog_jump, %function
@ displaying the jumped dog pattern
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_jump:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for jumped dog pattern
  mov r0, 0
  ldr r1, =0b00011
  bl write_row_states
  mov r0, 1
  ldr r1, =0b10011
  bl write_row_states
  mov r0, 2
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 4
  ldr r1, =0b00000
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_jump, .-present_dog_jump


.type present_dog_dead, %function
@ displaying the death of the dog
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_dog_dead:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for death sign of the dog
  mov r0, 0
  ldr r1, =0b10001
  bl write_row_states
  mov r0, 1
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 2
  ldr r1, =0b00100
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 4
  ldr r1, =0b10001
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_dead, .-present_dog_dead



.type present_eat1, %function
@ displaying the eating pattern 1
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_eat1:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for eating pattern 1
  mov r0, 0
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 2
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 4
  ldr r1, =0b01110
  bl write_row_states

  @ light the pattern with sound
  ldr r7, =0xffffff
  ldr r9, =20
  eat1_with_sound:
  cmp r4, 0
  ble mute
  ldr r8, =420
  sound_loop:
  cmp r8, 0
  ble eat1_pattern
  add r7, 1 
  lsr r0, r7, 12
  orr r0, 34
  mul r0, r0, r7
  push {r7}
  bl audio_play_sample
  pop {r7}
  sub r8, 1
  b sound_loop

  eat1_pattern:
  mov r0, 5
  mov r1, r5
  mov r2, r6
  bl present_pattern
  sub r4, 1
  b eat1_with_sound

  mute:
  cmp r9, 0
  beq end_eat1_with_sound
  mov r0, 0
  bl audio_play_sample
  sub r9, 1
  b mute

end_eat1_with_sound:
  pop {r4-r12, lr}
  bx lr
.size present_eat1, .-present_eat1


.type present_eat2, %function
@ displaying the eating pattern 2
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_eat2:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for eating pattern 2
  mov r0, 0
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 1
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 2
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 4
  ldr r1, =0b00000
  bl write_row_states

  @ light the pattern with sound
  ldr r7, =0xffffff
  ldr r9, =20
  eat2_with_sound:
  cmp r4, 0
  ble mute_2

  ldr r8, =420
  sound_loop_2:
  cmp r8, 0
  ble eat2_pattern
  add r7, 1 
  lsr r0, r7, 12
  orr r0, 34
  mul r0, r0, r7
  push {r7}
  bl audio_play_sample
  pop {r7}
  sub r8, 1
  b sound_loop_2

  eat2_pattern:
  mov r0, 5
  mov r1, r5
  mov r2, r6
  bl present_pattern
  sub r4, 1
  b eat2_with_sound

  mute_2:
  cmp r9, 0
  beq end_eat2_with_sound
  mov r0, 0
  bl audio_play_sample
  sub r9, 1
  b mute_2

end_eat2_with_sound:
  pop {r4-r12, lr}
  bx lr
.size present_eat2, .-present_eat2


.type present_unhappy, %function
@ displaying an unhappy face
@ --parameters-- (details see function "present_pattern")
@ r0: how long will the pattern be displayed
@ r1: control brightness of the pattern (brighter as r1 get larger)
@ r2: control brightness of the pattern (dimmer as r2 get larger) 
present_unhappy:
  push {r4-r12, lr}
  mov r4, r0
  mov r5, r1
  mov r6, r2

  @ store light states in memory for an unhappy face
  mov r0, 0
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 1
  ldr r1, =0b01010
  bl write_row_states
  mov r0, 2
  ldr r1, =0b00000
  bl write_row_states
  mov r0, 3
  ldr r1, =0b01110
  bl write_row_states
  mov r0, 4
  ldr r1, =0b10001
  bl write_row_states
  @ light the pattern
  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_unhappy, .-present_unhappy


.type present_dog_blink, %function
@ display a blinking dog pattern
@ pattern blinks quicker as the dog's hunger level is higher
@ --parameters--
@ r0: dog's hunger level
present_dog_blink:
  push {r4-r12, lr}

  @ hunger < 80
  cmp r0, 80
  bge blink_level_2
  bl brightness_based_on_happiness
  ldr r0, =0x350
  bl present_dog_n1
  ldr r0, =0x250000
  bl delay
  bl brightness_based_on_happiness
  ldr r0, =0x350
  bl present_dog_n2
  ldr r0, =0x250000
  bl delay
  b end_present_dog_blink

  @ 80 <= hunger < 90
  blink_level_2:
  cmp r0, 90
  bge blink_level_3
  bl brightness_based_on_happiness
  ldr r0, =0x300
  bl present_dog_n1
  ldr r0, =0x160000
  bl delay
  bl brightness_based_on_happiness
  ldr r0, =0x300
  bl present_dog_n2
  ldr r0, =0x160000
  bl delay
  b end_present_dog_blink

  @ hunger >= 90
  blink_level_3:
  bl brightness_based_on_happiness
  ldr r0, =0x250
  bl present_dog_n1
  ldr r0, =0x100000
  bl delay
  bl brightness_based_on_happiness
  ldr r0, =0x250
  bl present_dog_n2
  ldr r0, =0x100000
  bl delay
  
  end_present_dog_blink:
  pop {r4-r12, lr}
  bx lr
.size present_dog_blink, .-present_dog_blink


.type light_states_based_on_dog_level, %function
@ output a row's light states based on the input health/hunger/happiness level
@ --parameters-- 
@ r0: dog's current health/hunger/happiness level
@ --return--
@ r0: a row's light states to show dog's level
light_states_based_on_dog_level:
  push {r4-r12, lr}
  cmp r0, 0
  bgt one_led
  mov r0, 0
  b end_light_states_based_on_dog_level

  one_led:
  cmp r0, 20
  bgt two_leds
  ldr r0, =0b00001
  b end_light_states_based_on_dog_level

  two_leds:
  cmp r0, 40
  bgt three_leds
  ldr r0, =0b00011
  b end_light_states_based_on_dog_level

  three_leds:
  cmp r0, 60
  bgt four_leds
  ldr r0, =0b00111
  b end_light_states_based_on_dog_level
  
  four_leds:
  cmp r0, 80
  bgt five_leds
  ldr r0, =0b01111
  b end_light_states_based_on_dog_level

  five_leds:
  ldr r0, =0b11111

  end_light_states_based_on_dog_level:
  pop {r4-r12, lr}
  bx lr
.size light_states_based_on_dog_level, .-light_states_based_on_dog_level


.type present_dog_states, %function
@ present dog's health, hunger and happiness levels by no. of leds turned on
@ 0th row: health level out of 5
@ 2th row: hunger level out of 5
@ 4th row: happiness level out of 5
@ --parameters-- 
@ r0: how long will the pattern be displayed
present_dog_states:
  push {r4-r12, lr}
  mov r4, r0

  @ store light states for 0th row based on health level
  ldr r1, =health_level
  ldr r0, [r1]
  bl light_states_based_on_dog_level
  mov r1, r0
  mov r0, 0
  bl write_row_states

  @ store light states for 2nd row based on hunger level
  ldr r1, =hunger_level
  ldr r0, [r1]
  bl light_states_based_on_dog_level
  mov r1, r0
  mov r0, 2
  bl write_row_states

  @ store light states for 4th row based on happiness level
  ldr r1, =happiness_level
  ldr r0, [r1]
  bl light_states_based_on_dog_level
  mov r1, r0
  mov r0, 4
  bl write_row_states

  @ make sure light states for 1st row and 3rd row are both 0
  mov r0, 1
  mov r1, 0
  bl write_row_states
  mov r0, 3
  mov r1, 0
  bl write_row_states

  @ present dog's health, hunger and happiness levels
  mov r0, r4
  ldr r1, =1000
  ldr r2, =0
  bl present_pattern

  pop {r4-r12, lr}
  bx lr
.size present_dog_states, .-present_dog_states


.type brightness_based_on_happiness, %function
@ based on the dog's happiness stored in the memory,
@ it outputs two numbers which will be used for function "present_pattern"
@ to control the brightness of a pattern
@ happier the dog, brighter the pattern
@ --return--
@ r1: delay time when the lights are on in every row
@ r2: delay time when the lights are off in every row
brightness_based_on_happiness:
  push {r4-r12, lr}
  ldr r0, =happiness_level
  ldr r1, [r0]
  cmp r1, 33
  bgt brightness_level_2

  @ brightness level 1
  ldr r1, =50
  ldr r2, =950
  b end_brightness_based_on_happiness

  brightness_level_2:
  cmp r1, 66
  bgt brightness_level_3

  @ brightness level 2
  ldr r1, =400
  ldr r2, =600
  b end_brightness_based_on_happiness

  @ brightness level 3
  brightness_level_3:
  ldr r1, =1000
  ldr r2, =0

  end_brightness_based_on_happiness:
  pop {r4-r12, lr}
  bx lr
.size brightness_based_on_happiness, .-brightness_based_on_happiness


.data

touch_sensor:
.word 0
button_A:
.word 0
button_B:
.word 0

health_level:
.word 90
hunger_level:
.word 30
happiness_level:
.word 50

systick_counts:
.word 1

light_states:
.word 0b00000
.word 0b00000
.word 0b00000
.word 0b00000
.word 0b00000
