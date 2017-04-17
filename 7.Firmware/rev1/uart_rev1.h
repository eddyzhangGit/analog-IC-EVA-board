/*
 * uart_rev1.h
 *
 *  Created on: Nov 6, 2016
 *      Author: Maria
 */

#ifndef UART_REV1_H_
#define UART_REV1_H_

struct uart_data {
	unsigned char newStringReceived;
	char          txString [MAX_STR_LENGTH];
	char          rxString [MAX_STR_LENGTH];
};
extern struct uart_data uart_data;

void uart_init (void);

void uartReceive (char data);
bool receiveText(char* data, int maxNumChars);
void sendText (void);

#endif /* UART_REV1_H_ */
