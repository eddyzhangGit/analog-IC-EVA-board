/*
 * uart_rev1.c
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#include <msp432.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#include "string.h"
#include "driverlib.h"
#include "main.h"
#include "uart_rev1.h"

/*************************************
 * Peripheral Parameter Configurations
 *************************************/
const eUSCI_UART_Config uartConfig =
{
        EUSCI_A_UART_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
        78,                                      // BRDIV = 78
        2,                                       // UCxBRF = 2
        0,                                       // UCxBRS = 0
        EUSCI_A_UART_NO_PARITY,                  // No Parity
        EUSCI_A_UART_LSB_FIRST,                  // LSB First
        EUSCI_A_UART_ONE_STOP_BIT,               // One stop bit
        EUSCI_A_UART_MODE,                       // UART mode
        EUSCI_A_UART_OVERSAMPLING_BAUDRATE_GENERATION  // Oversampling
};


/************************
 * uart initialization
 ************************/
void uart_init (void) {

    // Set the core voltage level to VCORE1
	MAP_PCM_setCoreVoltageLevel(PCM_VCORE1);

    // UART DOES NOT WORK FOR more than 24Mhz
	MAP_CS_setDCOCenteredFrequency(CS_DCO_FREQUENCY_24);
	MAP_CS_initClockSignal(CS_MCLK, CS_DCOCLK_SELECT, CS_CLOCK_DIVIDER_2 );
	MAP_CS_initClockSignal(CS_HSMCLK, CS_DCOCLK_SELECT, CS_CLOCK_DIVIDER_2 );
	MAP_CS_initClockSignal(CS_SMCLK, CS_DCOCLK_SELECT, CS_CLOCK_DIVIDER_2 );
	//MAP_CS_initClockSignal(CS_ACLK, CS_REFOCLK_SELECT, CS_CLOCK_DIVIDER_2);

    // selecting, configuring, enabling pins in UART mode
	#if UART
    	GPIO_setAsPeripheralModuleFunctionInputPin(UART_PORT, UART_RXD | UART_TXD , GPIO_PRIMARY_MODULE_FUNCTION);
    	UART_initModule(EUSCI_A0_BASE, &uartConfig);
    	UART_enableModule(EUSCI_A0_BASE);
	#endif

}

void uartReceive (char data) {

	static char rxInProgress = 0;
	static char pieceOfString[MAX_STR_LENGTH] = "";		// Holds the new addition to the string
	static char charCnt = 0;

	if(!rxInProgress){
		if ((data != '\n') ){
			pieceOfString[0] = '\0';
			rxInProgress = 1;
			pieceOfString[0] = data;
			charCnt = 1;
		}
	}
	else { // in progress
		if((data == '\n')){
			rxInProgress = 0;
			if (uart_data.newStringReceived == 0) {		// don't mess with the string while main processes it.
				pieceOfString[charCnt]='\0';
				__no_operation();
				charCnt++;
				strncpy (uart_data.rxString, pieceOfString, charCnt);
				__no_operation();
				uart_data.newStringReceived = 1;
				__no_operation();
			}
		} else {
			if (charCnt >= MAX_STR_LENGTH){
				rxInProgress = 1;
			}else{
				pieceOfString[charCnt++] = data;
			}
		}
	}
}

bool receiveText (char* data, int maxNumChars) {
	bool result = false;
    if (uart_data.newStringReceived == 1) {
    	result = true;
    	strncpy (data, uart_data.rxString, maxNumChars);
    	uart_data.newStringReceived = 0;
    }
    return result;
}

void sendText (void) {
   unsigned int i;

	for (i = 0; i < MAX_STR_LENGTH; ++i)
    {
	   // wait until UART ready
	   while (!(UCA0IFG & UCTXIFG));             // USCI_A0 TX buffer ready?
		   if (uart_data.txString[i] != 0) {
			  EUSCI_A_UART_transmitData (EUSCI_A0_BASE, uart_data.txString[i]);
		  }
		  else {
			  break;
		  }
    }
}
