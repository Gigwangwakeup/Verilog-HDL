# 01. MicroBlaze GPIO LED

Basys3 보드에 MicroBlaze 소프트 프로세서를 올리고, 직접 설계한 AXI4-Lite GPIO IP로 LED 파도타기를 버튼으로 제어하는 실습입니다.

- 왼쪽 버튼(BTNL): LED가 왼쪽에서 오른쪽으로 한 칸씩 켜졌다 꺼집니다.
- 오른쪽 버튼(BTNR): LED가 오른쪽에서 왼쪽으로 이동합니다.
- LED가 움직이는 중에 버튼을 누르면 방향을 바꿔 반대쪽 끝부터 다시 시작합니다.
- 가운데 버튼(BTNC): 시스템 리셋

동작 영상: https://youtu.be/Y_DCsP7n9JY

[![동작 영상](https://img.youtube.com/vi/Y_DCsP7n9JY/0.jpg)](https://youtu.be/Y_DCsP7n9JY)

## 개발 환경

| 항목 | 내용 |
|---|---|
| 보드 | Digilent Basys3 (XC7A35T-1CPG236C) |
| 툴 | Vivado 2020.2, Vitis 2020.2 |
| 언어 | Verilog, C |
| 클럭 | 100MHz (Clocking Wizard) |

## 시스템 구성

```
              +------------------+
 sys_clock -->|  Clocking Wizard |--> 100MHz
              +------------------+
                                        +--------> gpio_0 (GPIOA) --> LD0~LD3
+------------+    +------------------+  +--------> gpio_1 (GPIOB) --> LD4~LD7
| MicroBlaze |--->| AXI Interconnect |--+--------> gpio_2 (GPIOC) --> LD8~LD11
+------------+    +------------------+  +--------> gpio_3 (GPIOD) --> LD12~LD15
      |                                 +--------> gpio_4 (GPIOE) <-- BTNU, BTNL, BTNR, BTND
  LMB BRAM 128KB                        +--------> AXI UART Lite (115200bps)
```

Xilinx AXI GPIO 대신 직접 만든 `gpio` IP를 5개 배치했습니다. 4개는 LED 16개, 1개는 버튼 4개에 연결했습니다.

### 주소 맵

| 장치 | 베이스 주소 | 연결 |
|---|---|---|
| gpio_0 (GPIOA) | 0x44A0_0000 | LD0~LD3 |
| gpio_1 (GPIOB) | 0x44A1_0000 | LD4~LD7 |
| gpio_2 (GPIOC) | 0x44A2_0000 | LD8~LD11 |
| gpio_3 (GPIOD) | 0x44A3_0000 | LD12~LD15 |
| gpio_4 (GPIOE) | 0x44A4_0000 | bit0 BTNU, bit1 BTNL, bit2 BTNR, bit3 BTND |
| AXI UART Lite | 0x4060_0000 | USB-UART |
| LMB BRAM | 0x0000_0000 | 명령어, 데이터 메모리 128KB |

## GPIO IP

STM32의 GPIO처럼 방향, 출력, 입력 레지스터 3개를 둔 4비트 양방향 포트입니다.

| 오프셋 | 레지스터 | 접근 | 설명 |
|---|---|---|---|
| 0x0 | CR | R/W | 핀 방향. 비트가 1이면 출력, 0이면 입력 |
| 0x4 | ODR | R/W | 출력값 |
| 0x8 | IDR | R | 핀 입력값 |

핀마다 CR 비트로 출력과 하이 임피던스를 고릅니다.

```verilog
assign io_port[i] = cr[i] ? odr[i] : 1'bz;
assign idr[i]     = ~cr[i] ? io_port[i] : 1'bz;
```

AXI4-Lite 슬레이브(`gpio_v1_0_S00_AXI.v`)에서 slv_reg0을 CR, slv_reg1을 ODR로 쓰고, 0x8을 읽으면 레지스터 대신 `idr` 핀 값을 돌려주도록 고쳤습니다.

## 소프트웨어

Xilinx 드라이버 함수를 쓰지 않고 구조체 포인터로 레지스터에 직접 접근합니다.

```c
typedef struct {
    uint32_t CR;
    uint32_t ODR;
    uint32_t IDR;
} GPIO_TypeDef;

#define GPIOE ((GPIO_TypeDef *)0x44a40000)
```

- `gpio_init()`: GPIOA~D는 CR = 0x0F(출력), GPIOE는 CR = 0x00(입력)
- `round_left()`, `round_right()`: LED를 100ms마다 한 칸씩 옮깁니다.
- `led_direction()`: 1ms마다 GPIOE의 IDR을 읽어(폴링) 왼쪽, 오른쪽 버튼이 눌렸는지 확인합니다. 눌렸으면 방향을 바꾸고 바로 빠져나와 새 방향으로 처음부터 다시 돕니다.

## 폴더 구성

| 폴더 | 내용 |
|---|---|
| `00.C` | Vitis 애플리케이션 `main.c` |
| `01.RTL/gpio_1.0` | 직접 만든 AXI4-Lite GPIO IP (hdl, component.xml) |
| `02.xdc` | Basys3 핀 제약 |
| `03.bd` | Block Design 재생성 tcl |
| `04.xsa` | 비트스트림을 포함한 하드웨어 플랫폼 |

## 재현 방법

1. Vivado 2020.2에서 Basys3 보드로 새 프로젝트를 만듭니다.
2. Settings의 IP Repository에 `01.RTL` 폴더를 추가합니다.
3. Tcl Console에서 `source 03.bd/gpio_design_1.tcl`로 Block Design을 만듭니다.
4. Block Design에서 HDL Wrapper를 만들고 `02.xdc`의 제약 파일을 추가합니다.
5. 비트스트림을 생성하고 File > Export > Export Hardware에서 Include bitstream으로 XSA를 내보냅니다. 1~5단계를 건너뛰려면 `04.xsa`의 파일을 그대로 써도 됩니다.
6. Vitis 2020.2에서 XSA로 Platform Project를 만들고, Empty Application(C)을 만든 뒤 `00.C/main.c`를 넣고 빌드합니다.
7. Program FPGA 후 Run As > Launch Hardware로 실행합니다.

## 참고

- 버튼을 누르고 있는 동안에는 `led_direction()`이 계속 바로 빠져나오기 때문에 LED가 첫 칸에 머뭅니다. 버튼에서 손을 떼면 이동을 시작합니다.
- 버튼 값을 `IDR == 0x02`처럼 정확히 비교하므로 두 버튼을 함께 누르면 무시됩니다.
- 인터럽트로 바꾸려면 IP에 버튼 변화를 알리는 IRQ 출력을 추가하고 AXI INTC를 거쳐 MicroBlaze에 연결해야 합니다.
