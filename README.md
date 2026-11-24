# Verilog-HDL

Basys3(Xilinx Artix-7) 보드에 MicroBlaze 소프트 프로세서를 올리고, AXI4-Lite 커스텀 IP를 직접 만들어 C로 제어하는 실습 기록입니다.

RTL 설계, SystemVerilog, UVM 검증, RISC-V CPU 기록은 [HDL](https://github.com/Gigwangwakeup/HDL) 저장소에 있습니다.

## 개발 환경

| 항목 | 내용 |
|---|---|
| 보드 | Digilent Basys3 (XC7A35T-1CPG236C) |
| 툴 | Vivado 2020.2, Vitis 2020.2 |
| 언어 | Verilog, C |
| 프로세서 | MicroBlaze, 100MHz, LMB BRAM 128KB |

## 프로젝트 목록

각 프로젝트의 동작, 주소 맵, 레지스터 구성은 폴더 안의 README에 정리되어 있습니다.

| # | 프로젝트 | 내용 | 주요 기술 |
|---|---|---|---|
| 01 | [Microblaze_AXI_GPIO_led_button](basys3/AXI/01.Microblaze_AXI_GPIO_led_button) | 커스텀 GPIO IP 5개로 LED 16개 파도타기, 버튼으로 방향 전환 | AXI4-Lite 슬레이브, CR/ODR/IDR 레지스터, 구조체 포인터 |
| 02 | [Microblaze_AXI_GPIO_UART](basys3/AXI/02.Microblaze_AXI_GPIO_UART) | 커스텀 UART IP로 Pmod JB에 송수신, 받은 글자를 USB 콘솔에 출력 | UART TX/RX FSM, SR/TDR/RDR/CR 레지스터, AXI UART Lite |

## 폴더 공통 구조

```
<Project>/
├── README.md   프로젝트 설명
├── 00.C/       Vitis 애플리케이션 소스 (main.c, driver/)
├── 01.RTL/     AXI4-Lite 커스텀 IP (hdl, component.xml, drivers)
├── 02.xdc/     Basys3 핀 제약
├── 03.bd/      Block Design 재생성 tcl
└── 04.xsa/     비트스트림을 포함한 하드웨어 플랫폼
```

> Vivado, Vitis 생성물(`.runs`, `.cache`, workspace 등)은 올리지 않았습니다. 재현 방법은 각 프로젝트 README에 있습니다.
