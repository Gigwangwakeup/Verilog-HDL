/*
 * main.c
 *
 *  Created on: 2026. 11. 20.
 *      Author: kccistc
 */

#include "stdio.h"
#include "stdint.h"
#include "xil_printf.h"
#include "sleep.h"

typedef struct {
	uint32_t CR;
	uint32_t ODR;
	uint32_t IDR;
}GPIO_TypeDef;

#define GPIOA_BASEADDR	0x44a00000
#define GPIOB_BASEADDR	0x44a10000
#define GPIOC_BASEADDR	0x44a20000
#define GPIOD_BASEADDR	0x44a30000
#define GPIOE_BASEADDR	0x44a40000

#define GPIOA			((GPIO_TypeDef *)GPIOA_BASEADDR)
#define GPIOB			((GPIO_TypeDef *)GPIOB_BASEADDR)
#define GPIOC			((GPIO_TypeDef *)GPIOC_BASEADDR)
#define GPIOD			((GPIO_TypeDef *)GPIOD_BASEADDR)
#define GPIOE			((GPIO_TypeDef *)GPIOE_BASEADDR)


typedef enum {LED_LEFT = 0, LED_RIGHT}led_state_t;
led_state_t led_dir = LED_RIGHT;

void gpio_init(void){
	GPIOA->CR = 0x0f; // set output mode
	GPIOB->CR = 0x0f;
	GPIOC->CR = 0x0f;
	GPIOD->CR = 0x0f;
	GPIOE->CR = 0x00; // set input mode
}

uint32_t led_direction(uint32_t wait){
	for(int i = 0; i < wait; i++){
		if(GPIOE->IDR == 0x02){
			led_dir = LED_LEFT;
			return 1;
		}
		if(GPIOE->IDR == 0x04){
			led_dir = LED_RIGHT;
			return 1;
		}
		usleep(1000);
	}
	return 0;
}

void led_all_off(void){
	GPIOA->ODR = 0x00;
	GPIOB->ODR = 0x00;
	GPIOC->ODR = 0x00;
	GPIOD->ODR = 0x00;
}

void round_left(void){
	led_all_off();
	GPIOD->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x00;
	GPIOC->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x00;
	GPIOB->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x00;
	GPIOA->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x00;
	if(led_direction(100)) return;
}

void round_right(void){
	led_all_off();
	GPIOA->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOA->ODR = 0x00;
	GPIOB->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOB->ODR = 0x00;
	GPIOC->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOC->ODR = 0x00;
	GPIOD->ODR = 0x01;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x02;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x04;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x08;
	if(led_direction(100)) return;
	GPIOD->ODR = 0x00;
	if(led_direction(100)) return;
}

int main(void){
	gpio_init();
	while(1){
		switch(led_dir)
		{
		case LED_LEFT:
			round_left();
			break;
		case LED_RIGHT:
			round_right();
			break;
		default:
			round_right();
			break;
		}
	}
	return 0;
}
