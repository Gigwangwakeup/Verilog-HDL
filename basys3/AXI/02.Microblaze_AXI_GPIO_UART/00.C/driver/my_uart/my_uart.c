/*
 * my_uart.c
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */


#include "my_uart.h"


void uart_transmit(uart_typedef *uart, uint8_t txd)
{
	while (UART0->SR & (1<<0));
	uart->TDR = txd;
}

uint8_t uart_receive(uart_typedef *uart)
{
	while(!(UART0->SR & (1<<1)));
	return (uint8_t)uart->RDR;
}

uint8_t uart_rxavalable(uart_typedef *uart)
{
	return uart->SR & (1 << 1) ? 1 : 0;
}

