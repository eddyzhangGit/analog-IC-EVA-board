/*
 * spi.c
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#include <msp432.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#include "driverlib.h"
#include "main.h"
#include "spi_rev1.h"

/*************************************
 * Peripheral Parameter Configurations
 *************************************/

/* spi master A configuration parameters */
const eUSCI_SPI_MasterConfig spiMasterConfig_A =
{
        EUSCI_A_SPI_CLOCKSOURCE_SMCLK,             					// SMCLK Clock Source
        500000,                                   					// SMCLK = DCO = 3MHZ
        100000,                                    					// SPICLK = 500khz
        EUSCI_A_SPI_MSB_FIRST,                     					// MSB First
        EUSCI_A_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT,    // Phase
		EUSCI_A_SPI_CLOCKPOLARITY_INACTIVITY_LOW, 					// High polarity
        EUSCI_A_SPI_3PIN                           					// 3Wire SPI Mode
};


/* spi master B configuration parameters */
const eUSCI_SPI_MasterConfig spiMasterConfig_B =
{
        EUSCI_B_SPI_CLOCKSOURCE_SMCLK,             					// SMCLK Clock Source
        500000,                                   					// SMCLK = DCO = 3MHZ
        100000,                                    					// SPICLK = 500khz
        EUSCI_B_SPI_MSB_FIRST,                     					// MSB First
        EUSCI_B_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT,    // Phase
		EUSCI_B_SPI_CLOCKPOLARITY_INACTIVITY_LOW, 					// High polarity
        EUSCI_B_SPI_3PIN                           					// 3Wire SPI Mode
};

const struct spi_cs spi_cs [5] = {
	{ SPI1_PORT, 	SPI1_CS, 	EUSCI_A1_SPI_BASE },	// spi 1
	{ SPI2_PORT, 	SPI2_CS, 	EUSCI_B0_SPI_BASE },	// spi 2
	{ SPI3_PORT, 	SPI3_CS, 	EUSCI_B3_SPI_BASE },	// spi 3
	{ GPIO_PORT_P4, GPIO_PIN3, 	EUSCI_B0_SPI_BASE},		// spi test (1.5, 1.6, 1.7, 4.3)
	{ SPI4_PORT,	SPI4_CS,	EUSCI_A2_SPI_BASE},		// spi 4 (gpio spi)
};



/************************
 * spi initialization
 ************************/
void spi_init (void) {

	// start and enable LFXT
	GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_PJ, GPIO_PIN0 | GPIO_PIN1, GPIO_PRIMARY_MODULE_FUNCTION);

	// selecting, configuring, enabling pins in SPI1 mode
	#if SPI1
	GPIO_setAsPeripheralModuleFunctionInputPin (SPI1_PORT, SPI1_SCLK | SPI1_MISO | SPI1_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
	GPIO_setAsOutputPin (SPI1_PORT, SPI1_CS);
	GPIO_setOutputHighOnPin (SPI1_PORT, SPI1_CS);
	SPI_initMaster(EUSCI_A1_SPI_BASE, &spiMasterConfig_A);
	SPI_enableModule(EUSCI_A1_SPI_BASE);
	#endif

	// selecting, configuring, enabling pins in SPI2 mode
	#if SPI2
	GPIO_setAsPeripheralModuleFunctionInputPin (SPI2_PORT, SPI2_SCLK | SPI2_MISO | SPI2_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
	GPIO_setAsOutputPin (SPI2_PORT, SPI2_CS);
	GPIO_setOutputHighOnPin (SPI2_PORT, SPI2_CS);
	SPI_initMaster(EUSCI_B0_SPI_BASE, &spiMasterConfig_B);
	SPI_enableModule(EUSCI_B0_SPI_BASE);
	#endif

	// selecting, configuring, enabling pins in SPI3 mode
	#if SPI3
	GPIO_setAsPeripheralModuleFunctionInputPin (SPI3_PORT, SPI3_SCLK | SPI3_MISO | SPI3_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
	GPIO_setAsOutputPin (SPI3_PORT, SPI3_CS);
	GPIO_setOutputHighOnPin (SPI3_PORT, SPI3_CS);
	SPI_initMaster(EUSCI_B3_SPI_BASE, &spiMasterConfig_B);
	SPI_enableModule(EUSCI_B3_SPI_BASE);
	#endif

	#if SPI_TEST
	GPIO_setAsPeripheralModuleFunctionInputPin (SPI2_PORT, SPI2_SCLK | SPI2_MISO | SPI2_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
	GPIO_setAsOutputPin (GPIO_PORT_P4, GPIO_PIN3);
	GPIO_setOutputHighOnPin (GPIO_PORT_P4, GPIO_PIN3);
	SPI_initMaster(EUSCI_B0_SPI_BASE, &spiMasterConfig_B);
	SPI_enableModule(EUSCI_B0_SPI_BASE);
	#endif

}

void spi_write_dac (uint8_t id, uint8_t channel, uint16_t value) {

	uint8_t spi_buf[4];
	int		i;

	// load tx buffer
	spi_buf[0] = SPI_WRITE | SPI_WRITE_UPDATE_DAC_N;
	spi_buf[1] = (channel-16) | ( value >> 12 );			// channel or first 4 bits of value (shift right 12 bits)
	spi_buf[2] = value >> 4;
	spi_buf[3] = value << 4;

	while (SPI_isBusy(spi_cs[id-1].module));

	GPIO_setOutputLowOnPin (spi_cs[id-1].port, spi_cs[id-1].pin);

	for (i=0; i<4; i++) {
		SPI_transmitData(spi_cs[id-1].module, spi_buf[i]);
		__delay_cycles(30);
	}

	__delay_cycles(3000);

	GPIO_setOutputHighOnPin (spi_cs[id-1].port, spi_cs[id-1].pin);

}


void spi_test (void) {

	// enable CS
	GPIO_setOutputLowOnPin (GPIO_PORT_P4, GPIO_PIN3);

	// transmitting data to slave
	SPI_transmitData(EUSCI_B0_SPI_BASE, 0x02);
	SPI_transmitData(EUSCI_B0_SPI_BASE, 0xF9);
	SPI_transmitData(EUSCI_B0_SPI_BASE, 0x99);
	SPI_transmitData(EUSCI_B0_SPI_BASE, 0x90);

	// disable CS
	GPIO_setOutputHighOnPin (GPIO_PORT_P4, GPIO_PIN3);
}

void blink (void) {
	int i;
	GPIO_setAsOutputPin(GPIO_PORT_P1, GPIO_PIN0);
	GPIO_toggleOutputOnPin(GPIO_PORT_P1, GPIO_PIN0);		// toggle LED
	for (i=100000; i>0; i--);								// delay
	GPIO_toggleOutputOnPin(GPIO_PORT_P1, GPIO_PIN0);		// toggle LED
}
