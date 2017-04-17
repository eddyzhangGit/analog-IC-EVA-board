/*
 * adc_rev1.h
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#ifndef ADC_REV1_H_
#define ADC_REV1_H_

void adc_init (void);
uint16_t adc_read (uint8_t adc_id);

void itoa (uint16_t n, char s[]);
void reverse(char s[]);
uint8_t char_to_hex (char s);

char* hex2str(int num, char* str);

int numPlaces (int n);

#endif /* ADC_REV1_H_ */
