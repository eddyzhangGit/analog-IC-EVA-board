/*
 * i2c_rev1.c
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
#include "i2c_rev1.h"



/*************************************
 * Peripheral Parameter Configurations
 *************************************/

const eUSCI_I2C_MasterConfig i2cConfig =
{
        EUSCI_B_I2C_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
        12000000,                               // SMCLK = 24MHz
        EUSCI_B_I2C_SET_DATA_RATE_400KBPS,      // Desired I2C Clock of 100khz
        0,                                      // No byte counter threshold
        EUSCI_B_I2C_NO_AUTO_STOP                // No auto-stop
};

const struct i2c_cs i2c_cs [9] = {
	{ SLAVE_ADDRESS_1, EUSCI_B1_BASE },		// i2c1, 1, 0x58
	{ SLAVE_ADDRESS_2, EUSCI_B1_BASE },		// i2c1, 2, 0x5A
	{ SLAVE_ADDRESS_3, EUSCI_B1_BASE },		// i2c1, 3, 0x5C
	{ SLAVE_ADDRESS_4, EUSCI_B1_BASE },		// i2c1, 4, 0x5E
	{ SLAVE_ADDRESS_1, EUSCI_B2_BASE },		// i2c2, 5, 0x58
	{ SLAVE_ADDRESS_2, EUSCI_B2_BASE },		// i2c2, 6, 0x5A
	{ SLAVE_ADDRESS_3, EUSCI_B2_BASE },		// i2c2, 7, 0x5C
	{ SLAVE_ADDRESS_4, EUSCI_B2_BASE },		// i2c2, 8, 0x5E
	{ SLAVE_ADDRESS_3, EUSCI_B0_BASE },		// i2c test (1.6, 1.7)
};


/***************************************************************************//**
 * @brief  Initializes SPI peripheral
 * @param  None
 * @return None
 ******************************************************************************/
void i2c_init (void) {

	// selecting, configuring, enabling pins in I2C1 mode
	#if I2C1
    	GPIO_setAsPeripheralModuleFunctionOutputPin(I2C1_PORT, I2C1_SDA | I2C1_SCL, GPIO_PRIMARY_MODULE_FUNCTION);
    	I2C_initMaster(EUSCI_B1_BASE, &i2cConfig);
    	I2C_enableModule(EUSCI_B1_BASE);
	#endif

	// selecting, configuring, enabling pins in SPI1 mode
	#if I2C2
    	GPIO_setAsPeripheralModuleFunctionOutputPin(I2C2_PORT, I2C2_SDA | I2C2_SCL, GPIO_PRIMARY_MODULE_FUNCTION);
    	I2C_initMaster(EUSCI_B2_BASE, &i2cConfig);
    	I2C_enableModule(EUSCI_B2_BASE);
	#endif

	// selecting, configuring, enabling pins in SPI1 mode
	#if I2C_TEST
    	GPIO_setAsPeripheralModuleFunctionOutputPin(GPIO_PORT_P1, GPIO_PIN6 | GPIO_PIN7, GPIO_PRIMARY_MODULE_FUNCTION);
    	I2C_initMaster(EUSCI_B0_BASE, &i2cConfig);
    	I2C_enableModule(EUSCI_B0_BASE);
	#endif

}

/***************************************************************************//**
 * @brief  Reads data from the sensor
 * @param  slaveAdr 	- address of slave
 * 		   pointer		- address of register
 * 		   writeByte	- data byte
 * @return None
 ******************************************************************************/
void i2c_write8 (uint8_t slaveAdr, uint8_t pointer, uint8_t writeByte)
{

    // specify slave address for I2C
	I2C_setSlaveAddress(EUSCI_B0_BASE, slaveAdr);

	// enable and clear the interrupt flag
	I2C_clearInterruptFlag(EUSCI_B0_BASE, EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);

    // set master to transmit mode PL
    I2C_setMode(EUSCI_B0_BASE, EUSCI_B_I2C_TRANSMIT_MODE);

    // clear any existing interrupt flag PL
    I2C_clearInterruptFlag(EUSCI_B0_BASE, EUSCI_B_I2C_TRANSMIT_INTERRUPT0);

    // wait until ready to write PL
    while (I2C_isBusBusy(EUSCI_B0_BASE));

    // initiate start and send first character
    I2C_masterSendMultiByteStart(EUSCI_B0_BASE, pointer);

    // send final byte
    I2C_masterSendMultiByteFinish(EUSCI_B0_BASE, (unsigned char)(writeByte&0xFF));

}

void i2c_write_pot (uint8_t id, uint8_t channel, uint8_t value) {

	// write slave address
	I2C_setSlaveAddress(i2c_cs[id-1].module, i2c_cs[id-1].slave_address);

	// enable and clear the interrupt flag
	I2C_clearInterruptFlag(i2c_cs[id-1].module, EUSCI_B_I2C_TRANSMIT_INTERRUPT0 + EUSCI_B_I2C_RECEIVE_INTERRUPT0);

	// set master and transmit mode
	I2C_setMode(i2c_cs[id-1].module, EUSCI_B_I2C_TRANSMIT_MODE);

	// clear any existing interrupt flag PL
	I2C_clearInterruptFlag(i2c_cs[id-1].module, EUSCI_B_I2C_TRANSMIT_INTERRUPT0);

	// wait until read to write
	while (I2C_isBusBusy(i2c_cs[id-1].module));

	// send channel info
	I2C_masterSendMultiByteStart(i2c_cs[id-1].module, channel);

	// send value info
	I2C_masterSendMultiByteFinish(i2c_cs[id-1].module, (unsigned char)(value&0xFF));

}

void i2c_test (void) {
	i2c_write8 (SLAVE_ADDRESS_1, 0x00, 0xFF);	// A0 = GND, A1 = GND, W1&B1, max resistance
}
