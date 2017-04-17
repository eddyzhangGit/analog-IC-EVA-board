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

#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "driverlib.h"
#include "main.h"
#include "adc_rev1.h"


const struct adc_info adc_info [24] = {
	{0,	ADC_MEM0},
	{1,	ADC_MEM1},
	{2,	ADC_MEM2},
	{3,	ADC_MEM3},
	{4,	ADC_MEM4},
	{5,	ADC_MEM5},
	{6,	ADC_MEM6},
	{7,	ADC_MEM7},
	{8, ADC_MEM8},
	{9, 0},
	{10, 0},
	{11, 0},
	{12, ADC_MEM9},
	{13, ADC_MEM10},
	{14, ADC_MEM11},
	{15, ADC_MEM12},
	{16, 0},
	{17, 0},
	{18, 0},
	{19, 0},
	{20, ADC_MEM13},
	{21, ADC_MEM14},
	{22, ADC_MEM15},
	{23, ADC_MEM16},
};

/************************
 * adc initialization
 ************************/
void adc_init (void) {

	// Setting Flash wait state
	FlashCtl_setWaitState(FLASH_BANK0, 2);
	FlashCtl_setWaitState(FLASH_BANK1, 2);

	// Setting DCO to 48MHz
	PCM_setPowerState(PCM_AM_LDO_VCORE1);
	CS_setDCOCenteredFrequency(CS_DCO_FREQUENCY_48);

	// Enabling the FPU for floating point operation
	FPU_enableModule();
	FPU_enableLazyStacking();

	// Initializing ADC (MCLK/1/4)
	ADC14_enableModule();
	ADC14_initModule(ADC_CLOCKSOURCE_MCLK, ADC_PREDIVIDER_1, ADC_DIVIDER_4, 0);

	// Configuring GPIOs
	GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P5, ADC_0|ADC_1|ADC_2|ADC_3|ADC_4|ADC_5, GPIO_TERTIARY_MODULE_FUNCTION);
	GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P4, ADC_6|ADC_7|ADC_8|ADC_12|ADC_13, GPIO_TERTIARY_MODULE_FUNCTION);
	GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P6, ADC_14|ADC_15, GPIO_TERTIARY_MODULE_FUNCTION);
	GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P8, ADC_20|ADC_21|ADC_22|ADC_23, GPIO_TERTIARY_MODULE_FUNCTION);

	// Configuring ADC Memory
	ADC14_configureMultiSequenceMode(ADC_MEM0,  ADC_MEM16,  true);

	// Configure ADC Memory Using MSP432 Internal 2.5V Reference
	#if INTERNAL_REF

		ADC14_configureConversionMemory(ADC_MEM0, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A0, false);
		ADC14_configureConversionMemory(ADC_MEM1, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A1, false);
		ADC14_configureConversionMemory(ADC_MEM2, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A2, false);
		ADC14_configureConversionMemory(ADC_MEM3, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A3, false);
		ADC14_configureConversionMemory(ADC_MEM4, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A4, false);
		ADC14_configureConversionMemory(ADC_MEM5, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A5, false);
		ADC14_configureConversionMemory(ADC_MEM6, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A6, false);
		ADC14_configureConversionMemory(ADC_MEM7, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A7, false);
		ADC14_configureConversionMemory(ADC_MEM8, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A8, false);
		ADC14_configureConversionMemory(ADC_MEM9, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A12, false);
		ADC14_configureConversionMemory(ADC_MEM10, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A13, false);
		ADC14_configureConversionMemory(ADC_MEM11, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A14, false);
		ADC14_configureConversionMemory(ADC_MEM12, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A15, false);
		ADC14_configureConversionMemory(ADC_MEM13, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A20, false);
		ADC14_configureConversionMemory(ADC_MEM14, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A21, false);
		ADC14_configureConversionMemory(ADC_MEM15, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A22, false);
		ADC14_configureConversionMemory(ADC_MEM16, ADC_VREFPOS_INTBUF_VREFNEG_VSS, ADC_INPUT_A23, false);

		// Setting reference voltage to 2.5 and enabling temperature sensor
		REF_A_setReferenceVoltage(REF_A_VREF2_5V);
		REF_A_enableReferenceVoltage();

	#endif

	// Configure ADC Memory Using External Reference
	#if EXTERNAL_REF

		// Configure external Vref+ and Vref-, pins
	    GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P5, EXT_VREF_POS | EXT_VREF_NEG, GPIO_TERTIARY_MODULE_FUNCTION);

		ADC14_configureConversionMemory(ADC_MEM0, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A0, false);
		ADC14_configureConversionMemory(ADC_MEM1, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A1, false);
		ADC14_configureConversionMemory(ADC_MEM2, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A2, false);
		ADC14_configureConversionMemory(ADC_MEM3, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A3, false);
		ADC14_configureConversionMemory(ADC_MEM4, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A4, false);
		ADC14_configureConversionMemory(ADC_MEM5, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A5, false);
		ADC14_configureConversionMemory(ADC_MEM6, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A6, false);
		ADC14_configureConversionMemory(ADC_MEM7, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A7, false);
		ADC14_configureConversionMemory(ADC_MEM8, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A8, false);
		ADC14_configureConversionMemory(ADC_MEM9, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A12, false);
		ADC14_configureConversionMemory(ADC_MEM10, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A13, false);
		ADC14_configureConversionMemory(ADC_MEM11, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A14, false);
		ADC14_configureConversionMemory(ADC_MEM12, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A15, false);
		ADC14_configureConversionMemory(ADC_MEM13, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A20, false);
		ADC14_configureConversionMemory(ADC_MEM14, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A21, false);
		ADC14_configureConversionMemory(ADC_MEM15, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A22, false);
		ADC14_configureConversionMemory(ADC_MEM16, ADC_VREFPOS_EXTPOS_VREFNEG_EXTNEG, ADC_INPUT_A23, false);

	#endif

	// Configuring Sample Timer
	ADC14_enableSampleTimer (ADC_AUTOMATIC_ITERATION);

	// Enabling/Toggling Conversion
	ADC14_enableConversion();
	ADC14_toggleConversionTrigger();

}

/************************
 * read specified adc value
 ************************/
uint16_t adc_read (uint8_t adc_id) {
	return ADC14_getResult (adc_info[adc_id].module);
}

/************************
 * convert int to string
 ************************/
void itoa (uint16_t n, char s[])
{
	int i, sign;

	if ((sign = n) < 0)  // record sign
		n = -n;          // make n positive

	i = 0;
	do {       // generate digits in reverse order
		s[i++] = n % 10 + '0';   // get next digit
	} while ((n /= 10) > 0);     // delete it

	if (sign < 0)
		s[i++] = '-';

	s[i] = '\0';
	reverse(s);
}

/************************
 * reverse string
 ************************/
void reverse(char s[])
{
	int i, j;
	char c;

	for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}

/************************
 * convert hex to string
 ************************/
char* hex2str(int num, char* str)
{
    int i = 0;
    bool isNegative = false;

    /* Handle 0 explicitely, otherwise empty string is printed for 0 */
    if (num == 0)
    {
        str[i++] = '0';
        str[i] = '\0';
        return str;
    }

    // In standard itoa(), negative numbers are handled only with
    // base 10. Otherwise numbers are considered unsigned.
    if (num < 0 && 16 == 10)
    {
        isNegative = true;
        num = -num;
    }

    // Process individual digits
    while (num != 0)
    {
        int rem = num % 16;
        str[i++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        num = num/16;
    }

    // If number is negative, append '-'
    if (isNegative)
        str[i++] = '-';

    str[i] = '\0'; // Append string terminator

    // Reverse the string
    reverse(str);

    return str;
}


/************************
 * convert char to hex
 ************************/
uint8_t char_to_hex (char s) {

	uint8_t result = s - '0';

	if (result > 9) {
		result = 9 + (s - '@');
	}

	return result;
}


int numPlaces (int n) {
    if (n < 0) return numPlaces ((n == 0) ? 16385 : -n);
    if (n < 10) return 1;
    return 1 + numPlaces (n / 10);
}
