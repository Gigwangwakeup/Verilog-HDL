# 02. MicroBlaze GPIO UART

Basys3 보드의 MicroBlaze에 AXI4-Lite 커스텀 UART IP(`uart_1.0`)를 붙이고, C에서 레지스터 구조체로 송수신하는 실습입니다.

- 커스텀 UART(Pmod JB)로 `a`부터 `z`까지 1초에 한 글자씩 보내고, `z` 다음에는 다시 `a`로 돌아갑니다.
- 커스텀 UART로 받은 글자가 있으면 `received x`처럼 USB-UART(AXI UART Lite) 콘솔에 출력합니다.
- 가운데 버튼(BTNC): 시스템 리셋

## 개발 환경

| 항목 | 내용 |
|---|---|
| 보드 | Digilent Basys3 (XC7A35T-1CPG236C) |
| 툴 | Vivado 2020.2, Vitis 2020.2 |
| 언어 | Verilog, C |
| 클럭 | 100MHz (Clocking Wizard) |
| UART | 115200bps, 8N1 |

## 시스템 구성

```
              +------------------+
 sys_clock -->|  Clocking Wizard |--> 100MHz
              +------------------+
                                        +--------> axi_gpio_0 --> FND font 8bit / com 4bit
+------------+    +------------------+  +--------> axi_gpio_1 --> LD0~LD15
| MicroBlaze |--->| AXI Interconnect |--+--------> axi_gpio_2 <-- BTNU, BTNL, BTNR, BTND
+------------+    +------------------+  +--------> axi_gpio_3 <-- SW0~SW15
      |    ^                            +--------> AXI UART Lite --> USB-UART (콘솔)
      |    |                            +--------> uart_0 (커스텀) --> JB1 tx / JB2 rx
  LMB BRAM |
   128KB   +-- AXI INTC <-- In0 axi_gpio_2, In1 AXI UART Lite, In2 uart_0
```

GPIO는 Xilinx AXI GPIO 4개를 쓰고, UART는 USB 콘솔용 AXI UART Lite와 직접 만든 `uart_0` 두 개를 둡니다. `uart_0`의 tx, rx는 Pmod JB 커넥터로 나갑니다.

### 주소 맵

| 장치 | 베이스 주소 | 연결 |
|---|---|---|
| axi_gpio_0 | 0x4000_0000 | 채널1 FND font 8비트, 채널2 FND com 4비트 |
| axi_gpio_1 | 0x4001_0000 | LD0~LD15 |
| axi_gpio_2 | 0x4002_0000 | bit0 BTNU, bit1 BTNL, bit2 BTNR, bit3 BTND |
| axi_gpio_3 | 0x4003_0000 | SW0~SW15 |
| AXI UART Lite | 0x4060_0000 | USB-UART (콘솔, `xil_printf`) |
| AXI INTC | 0x4120_0000 | 인터럽트 컨트롤러 |
| uart_0 | 0x44A0_0000 | JB1(A14) tx, JB2(A16) rx |
| LMB BRAM | 0x0000_0000 | 명령어, 데이터 메모리 128KB |

## UART IP

AXI4-Lite 슬레이브(`uart_v1_0_S00_AXI.v`)에 레지스터 4개를 두고, 같은 파일(`uart_v1_0.v`) 안의 `uart_tx`, `uart_rx` FSM에 연결했습니다.

| 오프셋 | 레지스터 | 접근 | 설명 |
|---|---|---|---|
| 0x0 | SR | R | bit0 `tx_busy`(송신 중), bit1 `rx_flag`(수신 데이터 있음) |
| 0x4 | TDR | R/W | 하위 8비트에 쓰면 그 클럭에 `tx_start` 펄스가 나가 송신 시작 |
| 0x8 | RDR | R | 수신 데이터. 읽으면 `rx_flag`가 0으로 내려감 |
| 0xC | CR | R/W | bit0 `rx_ie`(수신 인터럽트 허용) |

- 송신: start, 데이터 8비트(LSB 먼저), stop 순서로 비트마다 `CLKS_PER_BIT = 100_000_000 / 115200 = 868` 클럭씩 유지합니다.
- 수신: 2단 플립플롭으로 rx를 동기화한 뒤, start 비트에서 반 비트(434클럭)를 기다려 비트 가운데에서 샘플링합니다.
- 인터럽트: `intr = rx_ie & rx_done`이고, AXI INTC의 In2에 연결했습니다.

```verilog
2'h0 : reg_data_out <= {{30{1'b0}}, rx_flag, tx_busy};
2'h1 : reg_data_out <= uart_tdr;
2'h2 : reg_data_out <= uart_rdr;
2'h3 : reg_data_out <= uart_cr;
```

## 소프트웨어

UART는 Xilinx 드라이버 함수 대신, IP 레지스터 배치에 맞춘 구조체 포인터로 접근합니다(`driver/my_uart`).

```c
typedef struct {
    uint32_t SR;
    uint32_t TDR;
    uint32_t RDR;
    uint32_t CR;
} uart_typedef;

#define UART0 ((uart_typedef *)XPAR_UART_0_S00_AXI_BASEADDR)
```

- `uart_transmit()`: SR bit0(`tx_busy`)가 0이 될 때까지 기다린 뒤 TDR에 씁니다.
- `uart_rxavalable()`: SR bit1(`rx_flag`)을 읽어 받은 데이터가 있는지 확인합니다.
- `uart_receive()`: SR bit1이 설 때까지 기다린 뒤 RDR을 읽습니다.
- `main()`: 1초마다 한 글자를 보내고, 받은 데이터가 있으면 `xil_printf`로 콘솔에 찍습니다. GPIO는 LED와 스위치만 초기화해 두었고, 실제 사용 코드는 주석 처리돼 있습니다.
- `driver/button`: AXI GPIO 드라이버로 버튼 눌림과 뗌을 구분하는 코드입니다. 이번 `main.c`에서는 쓰지 않습니다.

## 폴더 구성

| 폴더 | 내용 |
|---|---|
| `00.C` | Vitis 애플리케이션 `main.c`, `driver/my_uart`, `driver/button` |
| `01.RTL/uart_1.0` | AXI4-Lite UART IP (hdl, component.xml) |
| `02.xdc` | Basys3 핀 제약 |
| `03.bd` | Block Design 재생성 tcl |
| `04.xsa` | 비트스트림을 포함한 하드웨어 플랫폼 |
| `05.tb` | 비어 있음 |

## 재현 방법

1. Vivado 2020.2에서 Basys3 보드로 새 프로젝트를 만듭니다.
2. Settings의 IP Repository에 `01.RTL` 폴더를 추가합니다.
3. Tcl Console에서 `source 03.bd/design_1.tcl`로 Block Design을 만듭니다.
4. Block Design에서 HDL Wrapper를 만들고 `02.xdc`의 제약 파일을 추가합니다.
5. 비트스트림을 생성하고 File > Export > Export Hardware에서 Include bitstream으로 XSA를 내보냅니다. 1~5단계를 건너뛰려면 `04.xsa`의 파일을 그대로 써도 됩니다.
6. Vitis 2020.2에서 XSA로 Platform Project를 만들고, Empty Application(C)을 만든 뒤 `00.C`의 파일을 `src`에 넣고 빌드합니다.
7. JB1(tx), JB2(rx)에 USB-TTL 시리얼 변환기를 연결하거나, JB1과 JB2를 점퍼로 이어 루프백으로 시험합니다.
8. Program FPGA 후 Run As > Launch Hardware로 실행하고, 시리얼 터미널을 115200bps로 엽니다.

## 참고

- `main()`이 `sleep(1)` 동안 RDR을 읽지 않기 때문에, 1초 안에 여러 글자가 들어오면 마지막 글자만 남습니다. RDR이 1바이트라 새 글자가 덮어씁니다.
- `my_uart.c`의 대기 루프가 인자 `uart` 대신 `UART0->SR`을 읽습니다. 지금은 UART가 하나라 동작에는 문제가 없습니다.
- `rx_flag`는 리셋 구문에서 초기화하지 않아, 시뮬레이션에서는 첫 수신 전까지 X로 보입니다.
- 수신 인터럽트(`rx_ie`, `intr`)는 하드웨어에 연결만 되어 있고, 소프트웨어는 폴링으로 확인합니다.
