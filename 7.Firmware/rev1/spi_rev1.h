/*
 * spi.h
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#ifndef SPI_REV1_H_
#define SPI_REV1_H_

// DAC80004 Channel Bits
#define SPI_CHANNEL_A	0x00
#define SPI_CHANNEL_B	0x10
#define SPI_CHANNEL_C	0x20
#define SPI_CHANNEL_D	0x30
#define SPI_ALL_CHANNEL	0xF0

// DAC80004 R/W Bits
#define SPI_READ		0x10
#define SPI_WRITE		0x00

// DAC80004 Command Bits
#define SPI_WRITE_BUF_N			0x00
#define SPI_UPDATE_DAC_N		0x01
#define SPI_UPDATE_ALL_DAC		0x02
#define SPI_WRITE_UPDATE_DAC_N	0x03

void spi_init (void);
void spi_write_dac (uint8_t id, uint8_t channel, uint16_t value);

void spi_test (void);
void blink (void);

#endif /* SPI_REV1_H_ */
