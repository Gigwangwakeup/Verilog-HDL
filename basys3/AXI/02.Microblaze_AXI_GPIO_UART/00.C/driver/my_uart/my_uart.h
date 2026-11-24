/*
 * my_uart.h
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_MY_UART_MY_UART_H_
#define SRC_DRIVER_MY_UART_MY_UART_H_


#include "xparameters.h"
#include "stdint.h"

typedef struct {
	uint32_t SR;
	uint32_t TDR;
	uint32_t RDR;
	uint32_t CR;
}uart_typedef;

#define UART_BASEADDR	XPAR_UART_0_S00_AXI_BASEADDR
#define UART0			((uart_typedef *)UART_BASEADDR)

void uart_transmit(uart_typedef *uart, uint8_t txd);
uint8_t uart_receive(uart_typedef *uart);
uint8_t uart_rxavalable(uart_typedef *uart);



#endif /* SRC_DRIVER_MY_UART_MY_UART_H_ */
