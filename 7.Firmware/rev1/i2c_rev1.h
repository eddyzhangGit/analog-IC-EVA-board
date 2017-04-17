/*
 * i2c_rev1.h
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#ifndef I2C_REV1_H_
#define I2C_REV1_H_

#define SLAVE_ADDRESS_1		0x58>>1		// A0 = GND, A1 = GND, (VOUT1, VOUT5)
#define SLAVE_ADDRESS_2		0x5A>>1		// A0 = 3V3, A1 = GND, (VOUT2, VOUT6)
#define SLAVE_ADDRESS_3		0x5C>>1		// A0 = GND, A1 = 3V3, (VOUT3, V_IO & POT2K5)
#define SLAVE_ADDRESS_4		0x5E>>1		// A0 = 3V3, A1 = 3V3, (VOUT4, POT10K)

void i2c_init (void);
void i2c_write_pot (uint8_t id, uint8_t channel, uint8_t value);
void i2c_write8 (uint8_t slaveAdr, uint8_t pointer, uint8_t writeByte);
void i2c_test (void);

#endif /* I2C_REV1_H_ */
