/*
 * main.c
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */


#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xgpio.h"
#include "stdint.h"
#include "driver/my_uart/my_uart.h"

#define GPIO_FND_DEV_ID XPAR_AXI_GPIO_0_DEVICE_ID
#define GPIO_LED_DEV_ID XPAR_AXI_GPIO_1_DEVICE_ID
#define GPIO_BTN_DEV_ID XPAR_AXI_GPIO_2_DEVICE_ID
#define GPIO_SW_DEV_ID XPAR_AXI_GPIO_3_DEVICE_ID

XGpio GPIO_LED;
XGpio GPIO_SW;
XGpio GPIO_BTN;

int main(void)
{
	// 1. launch AXI GPIO
	XGpio_Initialize(&GPIO_LED, GPIO_LED_DEV_ID);
	XGpio_Initialize(&GPIO_SW, GPIO_SW_DEV_ID);
	// 2. set IO direction
	XGpio_SetDataDirection(&GPIO_LED, 1, 0x0000); // 0: output mode, 1: input mode
	XGpio_SetDataDirection(&GPIO_SW, 1, 0xffff);

	uint8_t tx_data = 'a';
	uint8_t rx_data;
	while(1)
	{
//		sw_data = XGpio_DiscreteRead(&GPIO_SW, 1);
//		XGpio_DiscreteWrite(&GPIO_LED, 1, sw_data);
//		XGpio_DiscreteWrite(&GPIO_LED, 1, 0xffff);
//		usleep(100000);
//		XGpio_DiscreteWrite(&GPIO_LED, 1, 0x0000);
//		usleep(100000);

//		while (UART0->SR & (1<<0));
//		UART0->TDR = tx_data;
		uart_transmit(UART0, tx_data);
		if(tx_data == 'z') tx_data = 'a';
		else tx_data++;

		sleep(1);

		if(uart_rxavalable(UART0)){
			rx_data = uart_receive(UART0);
			xil_printf("received %c \n\r", rx_data);
		}
//		while(!(UART0->SR & (1<<1)));

	}

	return 0;
}

