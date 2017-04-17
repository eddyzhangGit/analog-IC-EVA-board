/*
 * gpio_rev1.c
 *
 *  Created on: Nov 8, 2016
 *      Author: Maria
 */


#include <msp432.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#include "driverlib.h"
#include "main.h"
#include "gpio_rev1.h"





/************************
 * gpio initialization
 ************************/
void gpio_init (void) {

    // initialize external 48MHz crystal
    GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_PJ,
            GPIO_PIN3 | GPIO_PIN4, GPIO_PRIMARY_MODULE_FUNCTION);

    // Setting the external clock frequency. This API is optional, but will
    // come in handy if the user ever wants to use the getMCLK/getACLK/etc
    // functions
    CS_setExternalClockSourceFrequency(32000,48000000);

    // Starting HFXT in non-bypass mode without a timeout. Before we start
    // we have to change VCORE to 1 to support the 48MHz frequency
    MAP_PCM_setCoreVoltageLevel(PCM_VCORE1);
    MAP_FlashCtl_setWaitState(FLASH_BANK0, 2);
    MAP_FlashCtl_setWaitState(FLASH_BANK1, 2);
    CS_startHFXT(false);

    // Initializing MCLK to HFXT (effectively 48MHz)
    MAP_CS_initClockSignal(CS_MCLK, CS_HFXTCLK_SELECT, CS_CLOCK_DIVIDER_1);

    // enable systick module
    MAP_SysTick_enableModule();


	SysTick_enableModule();



	GPIO_setAsOutputPin (GPIO_PORT_P2, GPIO_PIN5);
	GPIO_setAsOutputPin (GPIO_PORT_P2, GPIO_PIN6);
	GPIO_setAsOutputPin (GPIO_PORT_P2, GPIO_PIN7);
	GPIO_setAsOutputPin (GPIO_PORT_P10, GPIO_PIN4);
	GPIO_setAsOutputPin (GPIO_PORT_P10, GPIO_PIN5);
	GPIO_setAsOutputPin (GPIO_PORT_P7, GPIO_PIN4);
	GPIO_setAsOutputPin (GPIO_PORT_P7, GPIO_PIN5);
	GPIO_setAsOutputPin (GPIO_PORT_P7, GPIO_PIN6);
	GPIO_setAsOutputPin (GPIO_PORT_P7, GPIO_PIN7);
	GPIO_setAsOutputPin (GPIO_PORT_P8, GPIO_PIN0);
	GPIO_setAsOutputPin (GPIO_PORT_P8, GPIO_PIN1);
	GPIO_setAsOutputPin (GPIO_PORT_P3, GPIO_PIN0);
	GPIO_setAsOutputPin (GPIO_PORT_P3, GPIO_PIN1);
	GPIO_setAsOutputPin (GPIO_PORT_P3, GPIO_PIN2);
	GPIO_setAsOutputPin (GPIO_PORT_P3, GPIO_PIN3);
	GPIO_setAsOutputPin (GPIO_PORT_P3, GPIO_PIN4);

    GPIO_setOutputHighOnPin (GPIO_PORT_P2, GPIO_PIN5);
    GPIO_setOutputHighOnPin (GPIO_PORT_P2, GPIO_PIN6);
    GPIO_setOutputHighOnPin (GPIO_PORT_P2, GPIO_PIN7);
    GPIO_setOutputHighOnPin (GPIO_PORT_P10, GPIO_PIN4);
    GPIO_setOutputHighOnPin (GPIO_PORT_P10, GPIO_PIN5);
    GPIO_setOutputHighOnPin (GPIO_PORT_P7, GPIO_PIN4);
    GPIO_setOutputHighOnPin (GPIO_PORT_P7, GPIO_PIN5);
    GPIO_setOutputHighOnPin (GPIO_PORT_P7, GPIO_PIN6);
    GPIO_setOutputHighOnPin (GPIO_PORT_P7, GPIO_PIN7);
    GPIO_setOutputHighOnPin (GPIO_PORT_P8, GPIO_PIN0);
    GPIO_setOutputHighOnPin (GPIO_PORT_P8, GPIO_PIN1);
    GPIO_setOutputHighOnPin (GPIO_PORT_P3, GPIO_PIN0);
    GPIO_setOutputHighOnPin (GPIO_PORT_P3, GPIO_PIN1);
    GPIO_setOutputHighOnPin (GPIO_PORT_P3, GPIO_PIN2);
    GPIO_setOutputHighOnPin (GPIO_PORT_P3, GPIO_PIN3);
    GPIO_setOutputHighOnPin (GPIO_PORT_P3, GPIO_PIN4);



}
