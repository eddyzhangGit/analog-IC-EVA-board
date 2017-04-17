/*
 * main.h
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#ifndef MAIN_H_
#define MAIN_H_

#define MAX_STR_LENGTH		128

/* struct for storing output information for each hardware module*/
struct module_info {
	char	module_type;	//
	uint8_t module_num;		// identification of ic
	uint8_t channel;		// channel of ic
	float	set_value;		// value set by user
	float	read_value;		// value read from adc for feedback
};

struct spi_cs {
	uint8_t		port;
	uint16_t	pin;
	uint32_t	module;
};

struct i2c_cs {
	uint8_t		slave_address;
	uint32_t	module;
};

struct adc_info {
	uint8_t		pin;
	uint32_t	module;
};

struct gpio_info {
	uint8_t		id;				// gpio: 0-15
	uint8_t		port;			// gpio port
	uint16_t	pin;			// gpio pin
	uint8_t		io;				// data flow: 0 (output), 1 (input)
	uint8_t		sync;			// clock synchronized:  0 (board), 1 (dut)
	uint8_t		edge;			// rising (input only): 0 (rising), 1 (falling)
	uint8_t		data[3901];		// data sent/received
};


// UCA1 SPI1
#define SPI1_PORT	GPIO_PORT_P2
#define SPI1_CS		GPIO_PIN0
#define SPI1_SCLK	GPIO_PIN1
#define SPI1_MISO	GPIO_PIN2
#define SPI1_MOSI	GPIO_PIN3

// UCB0 SPI2
#define SPI2_PORT	GPIO_PORT_P1
#define SPI2_CS		GPIO_PIN4
#define SPI2_SCLK	GPIO_PIN5
#define SPI2_MOSI	GPIO_PIN6
#define SPI2_MISO	GPIO_PIN7

// UCB3 SPI3
#define SPI3_PORT	GPIO_PORT_P10
#define SPI3_CS		GPIO_PIN0
#define SPI3_SCLK	GPIO_PIN1
#define SPI3_MOSI	GPIO_PIN2
#define SPI3_MISO	GPIO_PIN3

// UCA2	SPI4 (GPIO)
#define SPI4_PORT	GPIO_PORT_P3
#define SPI4_CS		GPIO_PIN0
#define SPI4_SCLK	GPIO_PIN1
#define SPI4_MOSI	GPIO_PIN3	// reversed order from SPI1-SPI3
#define SPI4_MISO	GPIO_PIN2

// UCB1 I2C1
#define I2C1_PORT	GPIO_PORT_P6
#define I2C1_SDA	GPIO_PIN4
#define I2C1_SCL	GPIO_PIN5

// UCB2 I2C2
#define I2C2_PORT	GPIO_PORT_P3
#define I2C2_SDA	GPIO_PIN6
#define I2C2_SCL	GPIO_PIN7

// UCA0 UART
#define UART_PORT	GPIO_PORT_P1
#define UART_RXD	GPIO_PIN2
#define UART_TXD	GPIO_PIN3

// ADC
// GPIO_PORT_P5
#define ADC_0	GPIO_PIN5
#define ADC_1	GPIO_PIN4
#define ADC_2	GPIO_PIN3
#define ADC_3	GPIO_PIN2
#define ADC_4	GPIO_PIN1
#define ADC_5	GPIO_PIN0
// GPIO_PORT_P4
#define ADC_6	GPIO_PIN7
#define ADC_7	GPIO_PIN6
#define ADC_8	GPIO_PIN5
#define ADC_12	GPIO_PIN1
#define ADC_13	GPIO_PIN0
// GPIO_PORT_P6
#define ADC_14	GPIO_PIN1
#define ADC_15	GPIO_PIN0
// GPIO_PORT_P8
#define ADC_20	GPIO_PIN5
#define ADC_21	GPIO_PIN4
#define ADC_22	GPIO_PIN3
#define ADC_23	GPIO_PIN2

// Reference
#define EXT_VREF_POS	GPIO_PIN6
#define EXT_VREF_NEG	GPIO_PIN7

// LDO enables
// GPIO_PORT_P6
#define EN1			GPIO_PIN2
// GPIO_PORT_P9
#define EN2			GPIO_PIN2
#define EN5			GPIO_PIN0
// GPIO_PORT_P4
#define EN3			GPIO_PIN3
#define EN4			GPIO_PIN2
// GPIO_PORT_P8
#define EN6			GPIO_PIN7
#define EN7			GPIO_PIN6

// enables
#define SPI1		1
#define SPI2		1
#define SPI3		1
#define I2C1		1
#define I2C2		1
#define UART		1

// dev board test enables
#define SPI_TEST	0
#define I2C_TEST	0
#define UART_TEST	0

// ADC reference
#define INTERNAL_REF	0
#define EXTERNAL_REF	1

// functions
void send_gpio_inputs (uint8_t gpio_id);
//void send_spi_inputs (void);

#endif /* MAIN_H_ */
