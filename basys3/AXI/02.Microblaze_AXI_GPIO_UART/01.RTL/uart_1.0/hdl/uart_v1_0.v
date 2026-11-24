
`timescale 1 ns / 1 ps

module uart_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    output tx,
    input  rx,
    output intr,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);
    // ===============================================================
    // signals
    // ===============================================================
    wire tx_start;
    wire [7:0] tx_data;
    wire tx_busy;
    wire tx_done;
    wire [7:0] rx_data;
    wire rx_done;
    wire rx_ie;

	// ===============================================================
    // CL
    // ===============================================================
	assign intr = rx_ie & rx_done;


    // ===============================================================
    // Instantiation
    // ===============================================================
    // Instantiation of Axi Bus Interface S00_AXI
    uart_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) uart_v1_0_S00_AXI_inst (
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_ie(rx_ie),
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // Add user logic here
    uart u_uart (
        .clk     (s00_axi_aclk),
        .rstn    (s00_axi_aresetn),
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .tx      (tx),
        .rx_data (rx_data),
        .rx_done (rx_done),
        .rx      (rx)
    );
    // User logic ends

endmodule


module uart #(    
    parameter CLK_FREQ = 100_000_000,  // 100Mhz
    parameter BAUDRATE = 115200
    )(
    input        clk,
    input        rstn,
    // ===================
    // tx
    // ===================
    // internal signals
    input  [7:0] tx_data,
    input        tx_start,
    output       tx_busy,
    output       tx_done,
    // external port
    output       tx,
    // ===================
    // rx
    // ===================
    // internal signal
    output [7:0] rx_data,
    output       rx_done,
    // external port
    input        rx
    );

    uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUDRATE(BAUDRATE)
    ) u_uart_tx (
    .clk(clk),
    .rstn(rstn),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx_busy(tx_busy),
    .tx_done(tx_done),
    .tx(tx)
    );

    uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUDRATE(BAUDRATE)
    ) u_uart_rx (
    .clk(clk),
    .rstn(rstn),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rx(rx)
    );
endmodule

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,  // 100Mhz
    parameter BAUDRATE = 115200
) (
    input        clk,
    input        rstn,
    // internal signals
    input  [7:0] tx_data,
    input        tx_start,
    output       tx_busy,
    output       tx_done,
    // external port
    output       tx
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUDRATE;
    localparam S_IDLE = 2'd0, S_START = 2'd1, S_TX = 2'd2, S_STOP = 2'd3;
    //    S_D0 = 4'd2, S_D1 = 4'd3, S_D2 = 4'd4, S_D3 = 4'd5, 
    //    S_D4 = 4'd6, S_D5 = 4'd7, S_D6 = 4'd8, S_D7 = 4'd9,
    //    S_STOP = 4'd3;
    // ====================================================================
    // signals
    // ====================================================================
    reg tx_reg, tx_busy_reg, tx_done_reg;
    reg [1:0] state;
    reg [$clog2(CLKS_PER_BIT)-1 : 0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] tx_data_reg;

    // ====================================================================
    // output
    // ====================================================================
    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    // ====================================================================
    // Main logic(FSM)
    // ====================================================================
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            state       <= S_IDLE;
            clk_cnt     <= 0;
            bit_idx     <= 0;
            tx_data_reg <= 0;
            tx_busy_reg <= 1'b0;
            tx_done_reg <= 1'b0;
            tx_reg      <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_reg <= 1'b1;
                    tx_busy_reg <= 1'b0;
                    tx_done_reg <= 1'b0;
                    tx_data_reg <= 0;
                    if (tx_start) begin
                        state <= S_START;
                        tx_data_reg <= tx_data;
                        tx_busy_reg <= 1'b1;
                        clk_cnt <= 0;
                    end
                end
                S_START: begin
                    tx_reg <= 1'b0;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state   <= S_TX;
                    end
                end
                S_TX: begin
                    tx_reg <= tx_data_reg[bit_idx];
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        if (bit_idx < 8 - 1) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state   <= S_STOP;
                        end
                    end
                end
                // S_T0: begin
                //     tx_reg <= tx_data_reg[0];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D1;
                //     end
                // end
                // S_D1: begin
                //     tx_reg <= tx_data_reg[1];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D2;
                //     end
                // end
                // S_D2: begin
                //     tx_reg <= tx_data_reg[2];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D3;
                //     end
                // end
                // S_D3: begin
                //     tx_reg <= tx_data_reg[3];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D4;
                //     end
                // end
                // S_D4: begin
                //     tx_reg <= tx_data_reg[4];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D5;
                //     end
                // end
                // S_D5: begin
                //     tx_reg <= tx_data_reg[5];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D6;
                //     end
                // end
                // S_D6: begin
                //     tx_reg <= tx_data_reg[6];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_D7;
                //     end
                // end
                // S_D7: begin
                //     tx_reg <= tx_data_reg[7];
                //     if (clk_cnt < CLKS_PER_BIT - 1) begin
                //         clk_cnt <= clk_cnt + 1;
                //     end else begin
                //         clk_cnt <= 0;
                //         state   <= S_STOP;
                //     end
                // end
                S_STOP: begin
                    tx_reg <= 1'b1;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        tx_done_reg <= 1'b1;
                        clk_cnt <= 0;
                        state <= S_IDLE;
                    end
                end
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

module uart_rx #(
    parameter CLK_FREQ = 100_000_000,  // 100Mhz
    parameter BAUDRATE = 115200
) (
    input        clk,
    input        rstn,
    // internal signal
    output [7:0] rx_data,
    output       rx_done,
    // external port
    input        rx
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUDRATE;
    localparam HALF_BIT = CLKS_PER_BIT / 2;
    localparam S_IDLE = 2'd0, S_START = 2'd1, S_RX = 2'd2, S_STOP = 2'd3;

    // ====================================================================
    // signals
    // ====================================================================
    reg rx_sync_reg, rx_sync;
    reg rx_done_reg;
    reg [1:0] state;
    reg [$clog2(CLKS_PER_BIT)-1 : 0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] rx_data_reg;

    // ====================================================================
    // output
    // ====================================================================
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;
    // ====================================================================
    // syncronizer
    // ====================================================================
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            rx_sync_reg <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_sync_reg <= rx;
            rx_sync <= rx_sync_reg;
        end
    end
    // ====================================================================
    // Main
    // ====================================================================
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            state <= S_IDLE;
            clk_cnt <= 0;
            bit_idx <= 3'd0;
            rx_done_reg <= 1'b0;
            rx_data_reg <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    rx_done_reg <= 1'b0;
                    if (!rx_sync) begin
                        state   <= S_START;
                        bit_idx <= 0;
                        clk_cnt <= 0;
                    end
                end
                S_START: begin
                    if (clk_cnt < HALF_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state   <= S_RX;
                    end
                end
                S_RX: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        rx_data_reg <= {rx_sync, rx_data_reg[7:1]};
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            bit_idx <= 0;
                            state   <= S_STOP;
                        end
                    end
                end
                S_STOP: begin
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state <= S_IDLE;
                        rx_done_reg <= 1'b1;
                    end
                end
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
