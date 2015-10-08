# AVR_ASM_KS0108
Controller and demo for a 128*64 GLCD based on the KS0108 controller, written in pure ASM.

For a quick showcase, see it in action [here](https://www.youtube.com/watch?v=t3iNPR1YJbI)

This library was done for an Atmega16 running on the internal 8MHz oscillator.

You can easily use this library by calling the assembler macros included
RECTANGLE, HORIZONTAL_LINE, VERTICAL_LINE, LCD_ON, DISPLAY_BMP, which are used in the
source code.

To display an image, first convert it to .db notation and include in your code.


Also included is a Proteus ISIS simulation. You can check the connections for the 
DATA and CONTROL ports there or directly in the asm source.

For the source check [here](https://github.com/Ripagood/AVR_ASM_KS0108/blob/master/LCD/LCD/LCD.asm)

If you have any problems with the GLCD, try increasing the value of the delay for the TRIGGER_ENABLE subroutine.
