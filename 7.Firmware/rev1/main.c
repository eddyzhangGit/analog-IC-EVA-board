/***************************************
 * File:   main.c
 * Author: Maria
 * Created on November 6, 2016, 2:34 PM
 ***************************************/

#include <msp432.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "driverlib.h"
#include "math.h"

#include "main.h"
#include "spi_rev1.h"
#include "adc_rev1.h"
#include "i2c_rev1.h"
#include "uart_rev1.h"
#include "gpio_rev1.h"

/*************
 * Defines
 *************/
#define BUFLEN			256
#define OUTPUT_NUM		256
#define NUM_RX_CHARS	128
#define	NUM_TX_CHARS	128


/***********
 * Globals
 ***********/
struct uart_data uart_data = {
	0,		// false
	"",
	""
};

uint32_t    systick_idx = 0;

uint16_t    gpio_input_len = 0;
uint8_t		gpio_io_input[17];
uint8_t		gpio_io_output[17];
uint8_t		gpio_edge_rising[17];
uint8_t		gpio_edge_falling[17];

uint8_t		gpio_io_input_counter = 0;
uint8_t		gpio_io_output_counter = 0;
uint8_t		gpio_edge_rising_counter = 0;
uint8_t		gpio_edge_falling_counter = 0;

uint32_t    input_data_counter = 0;

uint8_t     input_clk_source = 0;
uint8_t		output_clk_source = 0;
uint16_t    clk_port = 0;

uint16_t	spi_input_len = 0;
uint8_t		spi_receive[65] = {0};
uint8_t		spi_idx = 0;

struct gpio_info gpio_info [16] = {
	{0,	GPIO_PORT_P2, GPIO_PIN5, 0, 0, 0, 0},
	{1,	GPIO_PORT_P2, GPIO_PIN6, 0, 0, 0, 0},
	{2,	GPIO_PORT_P2, GPIO_PIN7, 0, 0, 0, 0},
	{3,	GPIO_PORT_P10, GPIO_PIN4, 0, 0, 0, 0},
	{4,	GPIO_PORT_P10, GPIO_PIN5, 0, 0, 0, 0},
	{5,	GPIO_PORT_P7, GPIO_PIN4, 0, 0, 0, 0},
	{6,	GPIO_PORT_P7, GPIO_PIN5, 0, 0, 0, 0},
	{7,	GPIO_PORT_P7, GPIO_PIN6, 0, 0, 0, 0},
	{8, GPIO_PORT_P7, GPIO_PIN7, 0, 0, 0, 0},
	{9, GPIO_PORT_P8, GPIO_PIN0, 0, 0, 0, 0},
	{10,GPIO_PORT_P8, GPIO_PIN1, 0, 0, 0, 0},		// not on dev board
	{11, GPIO_PORT_P3, GPIO_PIN0, 0, 0, 0, 0},
	{12, GPIO_PORT_P3, GPIO_PIN1, 0, 0, 0, 0},		// not on dev board
	{13, GPIO_PORT_P3, GPIO_PIN2, 0, 0, 0, 0},
	{14, GPIO_PORT_P3, GPIO_PIN3, 0, 0, 0, 0},
	{15, GPIO_PORT_P3, GPIO_PIN4, 0, 0, 0, 0},		// not on dev board
};

eUSCI_SPI_MasterConfig spiMasterConfig_A2 = {		// for GPIO
		EUSCI_A_SPI_CLOCKSOURCE_SMCLK,				// SMCLK Clock Source
		3000000,									// SMCLK = DCO = 3MHZ
		0,											// SPICLK (desired clock frequency)
		0,											// MSB First
		0,											// Phase
		0,											// High polarity
		EUSCI_A_SPI_3PIN
};

/*
eUSCI_SPI_SlaveConfig spiSlaveConfig_A2 = {		// for GPIO
        0,						// MSB First
        0,  					// Phase
        0,  					// Normal Polarity
		EUSCI_B_SPI_3PIN		// 3wire mode
};
*/

/*******
 * Main
 *******/
int main(void) 
  {

	/*************
	 * Watch-dog
	 *************/
	WDT_A_holdTimer();	// halt watch-dog

	/**************
	 * Definitions
	 **************/
	char 		rxMsgData[NUM_RX_CHARS] = "";

	uint8_t		spi_id, spi_channel;
	uint16_t	spi_value;

	uint8_t		i2c_id, i2c_channel, i2c_value;

	uint8_t		adc_id;
	uint16_t	adc_val;
	//float		adc_value;
	char		adc_buf[1];

	uint32_t	gpio_freq = 0;
	uint32_t	spi_freq = 0;

	uint8_t 	gpio_id;

	uint8_t		gpio_load_counter = 0, transmission_counter = 0, packets = 0;
	uint32_t	data_idx = 0;

	uint8_t		spi_mode = 0;	// 0 is non-spi, 1 is master, 2 is slave


	/***************************
	 * Peripheral Initialization
	 ***************************/
	spi_init();		// initialize spi
	adc_init();		// initialize adc
	i2c_init();		// initialize i2c
	uart_init();	// initialize uart
	gpio_init();	// initialize gpio

	/********************
	 * Enable Interrupts
	 ********************/

	/* enable uart interrupt */
	UART_enableInterrupt(EUSCI_A0_BASE, EUSCI_A_UART_RECEIVE_INTERRUPT);
	Interrupt_enableInterrupt(INT_EUSCIA0);

	/* enable adc interrupts */
	ADC14_enableInterrupt(ADC_INT16);		// enable all adc interrupts
	Interrupt_enableInterrupt(INT_ADC14);

	/* enable spi interrupt */
	//SPI_enableInterrupt(EUSCI_B0_BASE, EUSCI_B_SPI_RECEIVE_INTERRUPT);
	//Interrupt_enableInterrupt(INT_EUSCIB0);

	/*enable gpio interrupt */
	Interrupt_enableMaster();

	/**** TEST *****/
	//for (i = 0; i<1000; i++);	// delay
	//i2c_write_pot (3, 0x00, 0x33);	// id, channel, value
	//for (i = 0; i<10000; i++);
	//adc_value = adc_read(5)*2.5/16384;	// read adc5
	//adc_value = adc_read(4)*2.5/16384;	// read adc4
	//spi_test ();
	/**** TEST *****/


	/*** TEST ******/
	/*
	int ii;

	while (1) {

		for(ii=0;ii<1000000;ii++)
		        {
		        }

		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P2, GPIO_PIN5);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P2, GPIO_PIN6);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P2, GPIO_PIN7);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P10, GPIO_PIN4);
		MAP_GPIO_tog gleOutputOnPin (GPIO_PORT_P10, GPIO_PIN5);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P7, GPIO_PIN4);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P7, GPIO_PIN5);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P7, GPIO_PIN6);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P7, GPIO_PIN7);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P8, GPIO_PIN0);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P8, GPIO_PIN1);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P3, GPIO_PIN0);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P3, GPIO_PIN1);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P3, GPIO_PIN2);
		MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P3, GPIO_PIN3);
	    MAP_GPIO_toggleOutputOnPin (GPIO_PORT_P3, GPIO_PIN4);
	}
	*/
	/*** TEST ******/


	// blink LED once to indicate everything is okay
	GPIO_setAsOutputPin(GPIO_PORT_P1, GPIO_PIN0);
	GPIO_setOutputHighOnPin(GPIO_PORT_P1, GPIO_PIN0);
	__delay_cycles(3000000);
	GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN0);
	__delay_cycles(1500000);
	GPIO_setOutputHighOnPin(GPIO_PORT_P1, GPIO_PIN0);
	__delay_cycles(3000000);
	GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN0);
	__delay_cycles(1500000);
	GPIO_setOutputHighOnPin(GPIO_PORT_P1, GPIO_PIN0);
	__delay_cycles(5000000);
	GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN0);


	while(1) {


  		if (receiveText(rxMsgData, NUM_RX_CHARS)) {

			switch (rxMsgData[0]) {

				/* ADC */
				case 'A':

					// process
					adc_id = (rxMsgData[1]-'0')*10 + (rxMsgData[2]-'0');
					adc_val = adc_read (adc_id);
					//adc_val2 = (adc_val*2.5) / 16384;

					// prepare string and send back to uart
					strncpy (uart_data.txString, "A", NUM_TX_CHARS);

					if (adc_id<10) {
						strncat (uart_data.txString, "0", NUM_TX_CHARS);
					}
					itoa (adc_id, adc_buf);
					strncat (uart_data.txString, adc_buf, NUM_TX_CHARS);

					//strncat (uart_data.txString, ":", NUM_TX_CHARS);

					itoa (adc_val, adc_buf);
					int p = numPlaces(adc_val);
					int k = 0;
					if (p<5) {
						for (k=0; k<(5-p); k++)
							strncat (uart_data.txString, "0", NUM_TX_CHARS);
					}

					strncat (uart_data.txString, adc_buf, NUM_TX_CHARS);
					strncat (uart_data.txString, "@", NUM_TX_CHARS);
					sendText();		// send data in AXX:DDDDDD, where XX is the ADC number, DDDDDD is the received data value

					break;


				/* DAC */
				case 'D':

					strncpy (uart_data.txString, "DAC", NUM_TX_CHARS);
					strncat (uart_data.txString, "\0", NUM_TX_CHARS);
					sendText();

					if ( 	(rxMsgData[1] != '1') &&
							(rxMsgData[1] != '2') &&
							(rxMsgData[1] != '3') ) {
						break;
					}

					if ( 	(rxMsgData[2] != '1') &&
							(rxMsgData[2] != '2') &&
							(rxMsgData[2] != '3') &&
							(rxMsgData[2] != '4')) {
						break;
					}

					if (	(rxMsgData[3] =='\0') ||
							(rxMsgData[4]=='\0') ||
							(rxMsgData[5]=='\0') ||
							(rxMsgData[6]=='\0') ) {
						break;
					}

					// process
					spi_id 		= char_to_hex(rxMsgData[1]);			// identification of spi
					spi_channel	= char_to_hex(rxMsgData[2]) << 4;		// channel of spi
					spi_value	= (char_to_hex(rxMsgData[3])<<12) +		// value, convert to uint16_t
								  (char_to_hex(rxMsgData[4])<<8) +
								  (char_to_hex(rxMsgData[5])<<4) +
								  char_to_hex(rxMsgData[6]);

					// write to dac
					spi_write_dac (spi_id, spi_channel, spi_value);
					break;


				/* GPIO */
				case 'G':

					strncpy (uart_data.txString, "GPIO", NUM_TX_CHARS);
					strncat (uart_data.txString, "@", NUM_TX_CHARS);
					sendText();

					// ability to set output frequency
					// ability to toggle to value
					// ability to set input/output pins (need to use interrupt)
					// ability to change to spi
					// designated gpio pins: UCA2: STE 3.0, CLK 3.1, MISO 3.2, MOSI 3.3

					if (rxMsgData[1] == 'F') {			// frequency setting (set all 8 digits)

						gpio_freq = 0;
						gpio_freq = char_to_hex(rxMsgData[2])*10000000 +
									char_to_hex(rxMsgData[3])*1000000 +
									char_to_hex(rxMsgData[4])*100000 +
									char_to_hex(rxMsgData[5])*10000 +
									char_to_hex(rxMsgData[6])*1000 +
									char_to_hex(rxMsgData[7])*100 +
									char_to_hex(rxMsgData[8])*10 +
									char_to_hex(rxMsgData[9]);

						gpio_freq = 48000000/gpio_freq;

						// set frequency
						SysTick_setPeriod(gpio_freq);

					}

					else if (rxMsgData[1] == 'C') {     // gpio input length (up to 3900)
					    gpio_input_len = 0;
					    gpio_input_len = char_to_hex(rxMsgData[2])*1000 +
									     char_to_hex(rxMsgData[3])*100 +
									     char_to_hex(rxMsgData[4])*10 +
									     char_to_hex(rxMsgData[5]);
					}

					else if (rxMsgData[1] == 'L') {		// load messages

						// message may be too large for 1 transmission, is message still transmitting?
						if (rxMsgData[2] == 'C') {
							transmission_counter = 3;			// start from index 5 for data
							goto MESSAGE_TRANSMISSION_CONT;		// go straight to transmitting data
						}

						gpio_id = char_to_hex(rxMsgData[2])*10 + char_to_hex(rxMsgData[3]);		// determine gpio id
						gpio_info[gpio_id].data[0] = '\0';                                      // clear data array
						if (gpio_id == 0) {
							input_clk_source = 16;
							// reset all counters
							gpio_io_input_counter = 0;
							gpio_io_output_counter = 0;
							gpio_edge_rising_counter = 0;
							gpio_edge_falling_counter = 0;
							SysTick_disableInterrupt();
						}

						packets = char_to_hex(rxMsgData[7])*10 + char_to_hex(rxMsgData[8]);	// number of packets in total for this pin
						transmission_counter = 9;				// otherwise start from index 7 for data
						data_idx = 0;

						// pin is output
						if (rxMsgData[4] == '0') {
							gpio_info[gpio_id].io = 0;
							gpio_io_output[gpio_io_output_counter] = gpio_id;
							gpio_io_output_counter++;

							GPIO_setAsOutputPin(gpio_info[gpio_id].port, gpio_info[gpio_id].pin);
							GPIO_setOutputLowOnPin(gpio_info[gpio_id].port, gpio_info[gpio_id].pin);
						}
						// pin is input
						else if (rxMsgData[4] == '1') {
							gpio_info[gpio_id].io = 1;
							gpio_io_input[gpio_io_input_counter] = gpio_id;
							gpio_io_input_counter++;

							GPIO_setAsInputPin (gpio_info[gpio_id].port, gpio_info[gpio_id].pin);
							//GPIO_setAsInputPinWithPullUpResistor(gpio_info[gpio_id].port, gpio_info[gpio_id].pin);

							//gpio_info[gpio_id].data = memset;
							memset(&gpio_info[gpio_id].data[0], 0, sizeof(gpio_info[gpio_id].data));

						}

						// pin is sync-ed to board clock
						if (rxMsgData[5] == '0') {
							gpio_info[gpio_id].sync = 0;
						}
						// pin is sync-ed to dut clock
						else if (rxMsgData[5] == '1') {
							gpio_info[gpio_id].sync = 1;
						}

						// pin is rising capture (if input)
						if (rxMsgData[6] == '0') {
							gpio_info[gpio_id].edge = 0;
							gpio_edge_rising[gpio_edge_rising_counter] = gpio_id;
							gpio_edge_rising_counter++;
						}
						// pin is falling capture (if input)
						else if (rxMsgData[6] == '1') {
							gpio_info[gpio_id].edge = 1;
							gpio_edge_falling[gpio_edge_falling_counter] = gpio_id;
							gpio_edge_falling_counter++;
						}
						// pin is input clock source (if input)
						else if (rxMsgData[6] == '2') {
							gpio_info[gpio_id].edge = 2;
							input_clk_source = gpio_id;     // setup interrupt for read gpio inputs based on this value
						}
						// pin is synced to board clock (if input)
						else if (rxMsgData[6] == '3') {
							gpio_info[gpio_id].edge = 3;
						}
						// pin is output
						else if (rxMsgData[6] == '4') {
							gpio_info[gpio_id].edge = 4;
						}
						// pin is output clock source
						else if (rxMsgData[6] == '5') {
							gpio_info[gpio_id].edge = 5;
							output_clk_source = gpio_id;
							GPIO_setOutputLowOnPin(gpio_info[output_clk_source].port, gpio_info[output_clk_source].pin);
						}

						gpio_load_counter++;				// counter for how many pins have data been loaded

						// load data here
						MESSAGE_TRANSMISSION_CONT:
						while ((rxMsgData[transmission_counter]!='\0') && (data_idx<3900)) {		// if not at the end of packet
							gpio_info[gpio_id].data[data_idx] = rxMsgData[transmission_counter];
							data_idx++;
							transmission_counter++;
						}

						packets--;

						if ( (data_idx>=3900) || ( (rxMsgData[transmission_counter]=='\0') && (packets==0) ) ) {
							gpio_info[gpio_id].data[data_idx] = '\0';    // add terminator at end of array
						}

						// check if data for all 16 pins have been loaded and there are not more packets to be transmitted
						if ((gpio_load_counter==16) && (packets==0)) {
							gpio_load_counter = 0;			// reset counter
							input_data_counter = 0;         // reset input counter
							systick_idx = 0;

							// fill in \0 for next element in all array
							gpio_io_input[gpio_io_input_counter] = '\0';
							gpio_io_output[gpio_io_output_counter] = '\0';
							gpio_edge_rising[gpio_edge_rising_counter] = '\0';
							gpio_edge_falling[gpio_edge_falling_counter] = '\0';

							// report back data loading is complete and user is able to press 'start'
							strncpy (uart_data.txString, "GPIO_LOAD:DONE", NUM_TX_CHARS);
							strncat (uart_data.txString, "@", NUM_TX_CHARS);
							sendText();
						}

					}

					else if (rxMsgData[1] == 'B') {		// start output/input

                        // handle outputs
						if (gpio_io_output_counter > 0) {
							systick_idx = 0;
							SysTick_enableInterrupt();      // enable systick interrupt
						}

                        // handle inputs (ignore if no input clock source sp   ecified)
                        if (input_clk_source != 16) {
							GPIO_clearInterruptFlag(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
							GPIO_enableInterrupt(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
							clk_port = (input_clk_source < 3) ? INT_PORT2 : INT_PORT3;      // can only be ports 2 or 3
							SysCtl_enableSRAMBankRetention(SYSCTL_SRAM_BANK1);
							Interrupt_enableInterrupt(clk_port);

							// wait for synchronous input to finish
							/*
							while ((int)input_data_counter < (int)gpio_input_len) {
								__delay_cycles(500);
							}
							*/

                        }

                        // wait for all inputs to be gathered
                        /*
                        if (gpio_io_output_counter > 0) {
                        	while ( (int)systick_idx < (int)gpio_input_len ) {}
                        }
                        */

                        strncpy (uart_data.txString, "GPIO_INPUT:DONE", NUM_TX_CHARS);
                        strncat (uart_data.txString, "@", NUM_TX_CHARS);
                        sendText();

					}

					else if (rxMsgData[1] == 'R') {			// user wants to collect input data
						/*
						if (rxMsgData[2] == 'S') {			// wants to collect spi data
							send_spi_inputs();
						}
						*/
						//else {
							gpio_id = char_to_hex(rxMsgData[2])*10 + char_to_hex(rxMsgData[3]);		// determine gpio id
							send_gpio_inputs (gpio_id);
						//}
					}

					else if (rxMsgData[1] == 'S') {		// spi enable/disable

						// protocol: S 		M 			XXXXXX		X			X		X
						//			 spi	master		frequency	msb first?	phase	clk polarity

						if (rxMsgData[2] == 'M') {			// spi master enable

							spi_mode = 1;

							// configure frequency
							spi_freq = 	char_to_hex(rxMsgData[3])*100000 +
										char_to_hex(rxMsgData[4])*10000 +
										char_to_hex(rxMsgData[5])*1000 +
										char_to_hex(rxMsgData[6])*100 +
										char_to_hex(rxMsgData[7])*10 +
										char_to_hex(rxMsgData[8]);
							spiMasterConfig_A2.desiredSpiClock = spi_freq;

							spiMasterConfig_A2.msbFirst = (char_to_hex(rxMsgData[9])==1) ?
									EUSCI_A_SPI_MSB_FIRST : EUSCI_A_SPI_LSB_FIRST;

							spiMasterConfig_A2.clockPhase = (char_to_hex(rxMsgData[10])==1) ?
									EUSCI_A_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT : EUSCI_A_SPI_PHASE_DATA_CAPTURED_ONFIRST_CHANGED_ON_NEXT;

							spiMasterConfig_A2.clockPolarity = (char_to_hex(rxMsgData[11])==1) ?
									EUSCI_A_SPI_CLOCKPOLARITY_INACTIVITY_LOW : EUSCI_A_SPI_CLOCKPOLARITY_INACTIVITY_HIGH;

							GPIO_setAsPeripheralModuleFunctionInputPin (SPI4_PORT, SPI4_SCLK | SPI4_MISO | SPI4_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
							GPIO_setAsOutputPin (SPI4_PORT, SPI4_CS);
							GPIO_setOutputHighOnPin (SPI4_PORT, SPI4_CS);

							SPI_initMaster(EUSCI_A2_SPI_BASE, &spiMasterConfig_A2);
							SPI_enableModule(EUSCI_A2_SPI_BASE);

						}
/*
						else if (rxMsgData[2] == 'S') {		// spi slave enable (dut as master)

							spi_mode = 2;

							spi_input_len = char_to_hex(rxMsgData[6])*10 + char_to_hex(rxMsgData[7]);

							spiSlaveConfig_A2.msbFirst = (char_to_hex(rxMsgData[3])==1) ?
									EUSCI_A_SPI_MSB_FIRST : EUSCI_A_SPI_LSB_FIRST;

							spiSlaveConfig_A2.clockPhase = (char_to_hex(rxMsgData[4])==1) ?
									EUSCI_A_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT : EUSCI_A_SPI_PHASE_DATA_CAPTURED_ONFIRST_CHANGED_ON_NEXT;

							spiSlaveConfig_A2.clockPolarity = (char_to_hex(rxMsgData[5])==1) ?
									EUSCI_A_SPI_CLOCKPOLARITY_INACTIVITY_LOW : EUSCI_A_SPI_CLOCKPOLARITY_INACTIVITY_HIGH;

							GPIO_setAsPeripheralModuleFunctionInputPin (SPI4_PORT, SPI4_SCLK | SPI4_MISO | SPI4_MOSI , GPIO_PRIMARY_MODULE_FUNCTION);
							SPI_initSlave (EUSCI_A2_BASE, &spiSlaveConfig_A2);
							SPI_enableModule(EUSCI_A2_BASE);

						}
*/

						else if (rxMsgData[2] == 'T') {		// spi disable

							SPI_disableModule (EUSCI_A2_BASE);
							spi_mode = 0;

						}

						else if (rxMsgData[2] == 'D') {		// spi data transfer

							// if in master mode, start sending data (one byte at a time)
							if (spi_mode == 1) {

								int i = 3;
								uint8_t spi_1, spi_2;
								uint8_t combined = 0;

								GPIO_setOutputLowOnPin (SPI4_PORT, SPI4_CS);		// set chip select low

								while (rxMsgData[i] != '\0') {					// start transmitting

									spi_1 = char_to_hex(rxMsgData[i])*16;
									spi_2 = char_to_hex(rxMsgData[i+1]);

									combined = spi_1 + spi_2;

									while (SPI_isBusy(EUSCI_A2_SPI_BASE));

									SPI_transmitData (EUSCI_A2_SPI_BASE, combined);

									__delay_cycles(500);

									i = i + 2;

								}

								__delay_cycles(2000);

								GPIO_setOutputHighOnPin (SPI4_PORT, SPI4_CS);		// set chip select low


							}

							// if in slave mode, enable interrupt to receive data
							/*
							else if (spi_mode == 2) {
								SPI_enableInterrupt(EUSCI_A2_BASE, EUSCI_A_SPI_RECEIVE_INTERRUPT);
								Interrupt_enableInterrupt(INT_EUSCIA2);
							}
							*/

						}

					}


					break;


				/* POT */
				case 'P':

					strncpy (uart_data.txString, "POT", NUM_TX_CHARS);
					strncat (uart_data.txString, "@", NUM_TX_CHARS);
					sendText();

					// process
					i2c_id		= char_to_hex(rxMsgData[1]);		// identification of i2c
					i2c_channel	= (char_to_hex(rxMsgData[2]) == 1) ? 0x00 : 0x80 ;		// channel of i2c, if 1 then channel = 1, else channel 2
					i2c_value = (char_to_hex(rxMsgData[3])*16) + char_to_hex(rxMsgData[4]); // value, convert to uint8_t

					// write to pot
					i2c_write_pot (i2c_id, i2c_channel, i2c_value);

					GPIO_toggleOutputOnPin (GPIO_PORT_P2, GPIO_PIN5);

					break;

			}
		}
	}
}

void ADC14_IRQHandler(void)
{
    uint64_t status = ADC14_getEnabledInterruptStatus();
    ADC14_clearInterruptFlag(status);
}

void EUSCIA0_IRQHandler(void)
{
    uint32_t status = UART_getEnabledInterruptStatus(EUSCI_A0_BASE);
    if(status & EUSCI_A_UART_RECEIVE_INTERRUPT_FLAG)
    {
        char data = UCA0RXBUF;
        uartReceive (data);
        __no_operation();
    }
    UART_clearInterruptFlag (EUSCI_A0_BASE, status);
}

void PORT2_IRQHandler(void)
{
    uint32_t status;
    uint8_t  i=0;

    status = GPIO_getEnabledInterruptStatus(GPIO_PORT_P2);
    GPIO_clearInterruptFlag(GPIO_PORT_P2, status);          	// clear flag

    if(status & gpio_info[input_clk_source].pin)                // is it triggered by the input clock source?
    {

        /*** ON CYCLE ***/

        gpio_info[input_clk_source].data[input_data_counter] = '1';

        // loop through all falling edges if data index is 0
        if (input_data_counter == 0) {
            while (i < gpio_edge_falling_counter) {                   // while not at end of array
                gpio_info[gpio_edge_falling[i]].data[input_data_counter] = '0';
                i++;
            }
        }
        i = 0;

        // loop through all inputs
        while (i < gpio_io_input_counter) {

			// rising edge
			if (gpio_info[gpio_io_input[i]].edge == 0) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = GPIO_getInputPinValue (gpio_info[gpio_io_input[i]].port, gpio_info[gpio_io_input[i]].pin) + '0';
			}
			// falling edge
			if ((gpio_info[gpio_io_input[i]].edge == 1)&&(input_data_counter!=0)) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = gpio_info[gpio_io_input[i]].data[input_data_counter-1];
			}
			i++;

        }

        input_data_counter++;

        if (input_data_counter == gpio_input_len) {                 // disable interrupt if gpio input len achieved
            GPIO_disableInterrupt(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
            return;
        }

        /*** OFF CYCLE ***/

        while (GPIO_getInputPinValue(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin)==1);    // wait for off cycle

        gpio_info[input_clk_source].data[input_data_counter] = '0';

        i = 0;

        while (i < gpio_io_input_counter) {

			// rising edge
			if (gpio_info[gpio_io_input[i]].edge == 0) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = gpio_info[gpio_io_input[i]].data[input_data_counter-1];
			}
			// falling edge
			if (gpio_info[gpio_io_input[i]].edge == 1) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = GPIO_getInputPinValue (gpio_info[gpio_io_input[i]].port, gpio_info[gpio_io_input[i]].pin) + '0';
			}
			i++;

        }

        input_data_counter++;

        if (input_data_counter == gpio_input_len) {                 // disable interrupt if gpio input len achieved
            GPIO_disableInterrupt(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
            return;
        }


    }


}

void PORT3_IRQHandler(void)
{
    uint32_t status;
    uint8_t  i=0;

    status = MAP_GPIO_getEnabledInterruptStatus(GPIO_PORT_P3);
    MAP_GPIO_clearInterruptFlag(GPIO_PORT_P3, status);

    if(status & gpio_info[input_clk_source].pin)                // is it triggered by the input clock source?
    {

        /*** ON CYCLE ***/

        gpio_info[input_clk_source].data[input_data_counter] = '1';

        // loop through all falling edges if data index is 0
        if (input_data_counter == 0) {
            while (i < gpio_edge_falling_counter) {                   // while not at end of array
                gpio_info[gpio_edge_falling[i]].data[input_data_counter] = '0';
                i++;
            }
        }
        i = 0;

        // loop through all inputs
        while (i < gpio_io_input_counter) {

			// rising edge
			if (gpio_info[gpio_io_input[i]].edge == 0) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = GPIO_getInputPinValue (gpio_info[gpio_io_input[i]].port, gpio_info[gpio_io_input[i]].pin) + '0';
			}
			// falling edge
			if ((gpio_info[gpio_io_input[i]].edge == 1)&&(input_data_counter!=0)) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = gpio_info[gpio_io_input[i]].data[input_data_counter-1];
			}
			i++;

        }

        input_data_counter++;

        if (input_data_counter == gpio_input_len) {                 // disable interrupt if gpio input len achieved
             GPIO_disableInterrupt(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
            return;
        }

        /*** OFF CYCLE ***/

        while (GPIO_getInputPinValue(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin)==1);    // wait for off cycle

        gpio_info[input_clk_source].data[input_data_counter] = '0';

        i = 0;

        while (i < gpio_io_input_counter) {

			// rising edge
			if (gpio_info[gpio_io_input[i]].edge == 0) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = gpio_info[gpio_io_input[i]].data[input_data_counter-1];
			}
			// falling edge
			if (gpio_info[gpio_io_input[i]].edge == 1) {
				gpio_info[gpio_io_input[i]].data[input_data_counter] = GPIO_getInputPinValue (gpio_info[gpio_io_input[i]].port, gpio_info[gpio_io_input[i]].pin) + '0';
			}
			i++;

        }

        input_data_counter++;

        if (input_data_counter == gpio_input_len) {                 // disable interrupt if gpio input len achieved
            GPIO_disableInterrupt(gpio_info[input_clk_source].port, gpio_info[input_clk_source].pin);
            return;
        }

    }

}


// gpio output interrupt
void SysTick_Handler (void)
{

	uint8_t i = 0;

	if (systick_idx >= 3900) {
		SysTick_disableInterrupt();     // disable interrupt
	}


    while (i < gpio_io_output_counter) {

    	if (gpio_io_output[i] != output_clk_source) {

			if (gpio_info[gpio_io_output[i]].data[systick_idx] == '1') {    // output 1
				GPIO_setOutputHighOnPin (gpio_info[gpio_io_output[i]].port, gpio_info[gpio_io_output[i]].pin);
			}

			else if (gpio_info[gpio_io_output[i]].data[systick_idx] == '0') {   // output 0
				GPIO_setOutputLowOnPin (gpio_info[gpio_io_output[i]].port, gpio_info[gpio_io_output[i]].pin);
			}

    	}

    	i++;

    }

	// toggle clock
	GPIO_toggleOutputOnPin(gpio_info[output_clk_source].port, gpio_info[output_clk_source].pin);


    i= 0;
    if (systick_idx < gpio_input_len) {
		while (i < gpio_io_input_counter) {
			if (gpio_info[gpio_io_input[i]].sync == 0) {
				gpio_info[gpio_io_input[i]].data[systick_idx] = GPIO_getInputPinValue (gpio_info[gpio_io_input[i]].port, gpio_info[gpio_io_input[i]].pin) + '0';
			}
			i++;
		}
    }

    systick_idx++;

	if ((gpio_info[gpio_io_output[0]].data[systick_idx] == '\0') && (systick_idx > gpio_input_len)) {
		GPIO_setOutputLowOnPin(gpio_info[output_clk_source].port, gpio_info[output_clk_source].pin);
		SysTick_disableInterrupt();
	}

}


void send_gpio_inputs (uint8_t gpio_id) {

    uint32_t    idx = 0;
    uint8_t     packets = 0, packets_sent = 0, packet = 0;
    char		data_temp[1];

	char		gpio_id_char[1];

    packets = gpio_input_len/125;

    if ((gpio_input_len%125)!=0) {
        packets = packets + 1;
    }

    packet = packets;

    while (packet!=0) {

    	// add identification
    	strncpy (uart_data.txString, "GD", NUM_TX_CHARS);
		itoa (gpio_id/10, gpio_id_char);
		strncat (uart_data.txString, gpio_id_char, NUM_TX_CHARS);
		itoa (gpio_id%10, gpio_id_char);
		strncat (uart_data.txString, gpio_id_char, NUM_TX_CHARS);

    	//strncpy (uart_data.txString, "", NUM_TX_CHARS);
        while ( (idx < (125*(packets_sent+1))) && (gpio_info[gpio_id].data[idx] != '\0') ) {
        	itoa (gpio_info[gpio_id].data[idx]-'0', data_temp);
            strncat (uart_data.txString, data_temp, NUM_TX_CHARS);
            //strncat (uart_data.txString, gpio_info[gpio_id].data[idx], NUM_TX_CHARS);
            idx ++ ;
        }
        strncat (uart_data.txString, "@", NUM_TX_CHARS);
        sendText();
		packets_sent++;
		packet--;
    }

}


