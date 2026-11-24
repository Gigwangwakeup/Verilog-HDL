/*
 * button.c
 *
 *  Created on: 2026. 10. 16.
 *      Author: rhoblack
 */

#include "button.h"
#include "xparameters.h"

#define GPIO_BTN_DEV_ID XPAR_AXI_GPIO_2_DEVICE_ID

void button_init(button_t *btn, XGpio *gpiox, uint16_t GPIO_Pin)
{

	btn->GPIOx = gpiox;
	btn->GPIO_Pin = GPIO_Pin;
	btn->prevState = RELEASED;

	XGpio_Initialize(btn->GPIOx, GPIO_BTN_DEV_ID);
	uint32_t dirData = XGpio_GetDataDirection(btn->GPIOx, 1);
	dirData |= (1<<GPIO_Pin);
	XGpio_SetDataDirection(btn, 1, dirData);

}

button_state_t button_getState(button_t *btn)
{
	int curState;
	curState = (XGpio_DiscreteRead(btn->GPIOx, 1) & (1<<btn->GPIO_Pin)) == 0 ? 0 : 1;
//	curState = HAL_GPIO_ReadPin(btn->GPIOx, btn->GPIO_Pin);

	if ((btn->prevState == RELEASED) && (curState == PUSHED)) {
		btn->prevState = PUSHED;
		usleep(5000); // debounce code
		return ACT_PUSH;
	}
	else if ((btn->prevState == PUSHED) && (curState == RELEASED)) {
		btn->prevState = RELEASED;
		usleep(5000);
//		HAL_Delay(5); // debounce code
		return ACT_RELEASE;
	}
	return NO_ACT;
}
