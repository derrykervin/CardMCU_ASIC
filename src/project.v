module tt_um_derrykervin_cardmcu_c0 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [7:0] gpio_out;

    wire uart_tx;

    wire spi_sclk;
    wire spi_mosi;
    wire spi_cs_n;

    wire halted;
    wire [7:0] debug_pc;
    wire [7:0] debug_r0;

    // CardMCU C0
    // 10 MHz / 87 ~= 114942 baud，接近 115200
    card #(
        .UART_CLKS_PER_BIT(87),
        .SPI_CLK_DIV(4)
    ) u_card (
        .clk(clk),
        .reset_n(rst_n),

        .gpio_in(ui_in),
        .gpio_out(gpio_out),

        .uart_rx(uio_in[0]),
        .uart_tx(uart_tx),

        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(uio_in[2]),
        .spi_cs_n(spi_cs_n),

        .halted(halted),
        .debug_pc(debug_pc),
        .debug_r0(debug_r0)
    );

    // Dedicated outputs = GPIO output
    assign uo_out = gpio_out;

    // Bidirectional I/O assignments
    // uio[0] = UART RX     input
    // uio[1] = UART TX     output
    // uio[2] = SPI MISO    input
    // uio[3] = SPI SCLK    output
    // uio[4] = SPI MOSI    output
    // uio[5] = SPI CS_N    output
    // uio[6:7] unused

    assign uio_out[0] = 1'b0;
    assign uio_out[1] = uart_tx;
    assign uio_out[2] = 1'b0;
    assign uio_out[3] = spi_sclk;
    assign uio_out[4] = spi_mosi;
    assign uio_out[5] = spi_cs_n;
    assign uio_out[7:6] = 2'b00;

    assign uio_oe[0] = 1'b0;
    assign uio_oe[1] = 1'b1;
    assign uio_oe[2] = 1'b0;
    assign uio_oe[3] = 1'b1;
    assign uio_oe[4] = 1'b1;
    assign uio_oe[5] = 1'b1;
    assign uio_oe[7:6] = 2'b00;

    // ena currently unused
    wire _unused = ena;

endmodule
