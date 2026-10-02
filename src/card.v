// CardMCU v1.0 top-level SoC
// Memory-mapped I/O map:
//   0x00 GPIO_IN   (read)
//   0x01 GPIO_OUT  (read/write)
//   0x10 UART_STATUS bit0=TX ready, bit1=RX valid
//   0x11 UART_DATA   read RX / write TX
//   0x20 SPI_STATUS  bit0=busy
//   0x21 SPI_DATA    read RX / write TX buffer
//   0x30..0x33 TIMER free-running counter bytes [7:0]..[31:24]
//   0x34 TIMER_CTRL  write bit0=1 to clear timer
module card #(
    parameter UART_CLKS_PER_BIT = 434,
    parameter SPI_CLK_DIV       = 4
)(
    input  wire       clk,
    input  wire       reset_n,

    input  wire [7:0] gpio_in,
    output reg  [7:0] gpio_out,

    input  wire       uart_rx,
    output wire       uart_tx,

    output wire       spi_sclk,
    output wire       spi_mosi,
    input  wire       spi_miso,
    output wire       spi_cs_n,

    output wire       halted,
    output wire [7:0] debug_pc,
    output wire [7:0] debug_r0
);
    wire [7:0]  rom_addr;
    wire [15:0] rom_data;
    wire        io_re;
    wire        io_we;
    wire [7:0]  io_addr;
    wire [7:0]  io_wdata;
    reg  [7:0]  io_rdata;

    reg  [31:0] timer_counter;

    wire [7:0] uart_rx_data;
    wire       uart_rx_valid_pulse;
    reg  [7:0] uart_rx_latch;
    reg        uart_rx_pending;
    wire       uart_tx_busy;
    wire       uart_tx_start;

    reg  [7:0] spi_tx_buffer;
    wire [7:0] spi_rx_data;
    wire       spi_busy;
    wire       spi_start;

    assign uart_tx_start = io_we && (io_addr == 8'h11) && !uart_tx_busy;
    assign spi_start     = io_we && (io_addr == 8'h20) && io_wdata[0] && !spi_busy;

    program_rom u_rom(
        .addr(rom_addr),
        .data(rom_data)
    );

    card_cpu u_cpu(
        .clk(clk),
        .reset_n(reset_n),
        .rom_addr(rom_addr),
        .rom_data(rom_data),
        .io_re(io_re),
        .io_we(io_we),
        .io_addr(io_addr),
        .io_wdata(io_wdata),
        .io_rdata(io_rdata),
        .debug_pc(debug_pc),
        .debug_r0(debug_r0),
        .halted(halted)
    );

    uart_tx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_uart_tx(
        .clk(clk),
        .reset_n(reset_n),
        .start(uart_tx_start),
        .data_in(io_wdata),
        .tx(uart_tx),
        .busy(uart_tx_busy)
    );

    uart_rx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_uart_rx(
        .clk(clk),
        .reset_n(reset_n),
        .rx(uart_rx),
        .data_out(uart_rx_data),
        .valid(uart_rx_valid_pulse)
    );

    spi_master #(.CLK_DIV(SPI_CLK_DIV)) u_spi(
        .clk(clk),
        .reset_n(reset_n),
        .start(spi_start),
        .tx_data(spi_tx_buffer),
        .rx_data(spi_rx_data),
        .busy(spi_busy),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );

    always @(*) begin
        case (io_addr)
            8'h00: io_rdata = gpio_in;
            8'h01: io_rdata = gpio_out;
            8'h10: io_rdata = {6'b000000, uart_rx_pending, ~uart_tx_busy};
            8'h11: io_rdata = uart_rx_latch;
            8'h20: io_rdata = {7'b0000000, spi_busy};
            8'h21: io_rdata = spi_rx_data;
            8'h30: io_rdata = timer_counter[7:0];
            8'h31: io_rdata = timer_counter[15:8];
            8'h32: io_rdata = timer_counter[23:16];
            8'h33: io_rdata = timer_counter[31:24];
            default: io_rdata = 8'h00;
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            gpio_out        <= 8'h00;
            timer_counter   <= 32'h00000000;
            uart_rx_latch   <= 8'h00;
            uart_rx_pending <= 1'b0;
            spi_tx_buffer   <= 8'h00;
        end else begin
            timer_counter <= timer_counter + 32'h00000001;

            if (uart_rx_valid_pulse) begin
                uart_rx_latch   <= uart_rx_data;
                uart_rx_pending <= 1'b1;
            end

            // Reading UART_DATA acknowledges the latched receive byte.
            if (io_re && (io_addr == 8'h11))
                uart_rx_pending <= 1'b0;

            if (io_we) begin
                case (io_addr)
                    8'h01: gpio_out <= io_wdata;
                    8'h21: spi_tx_buffer <= io_wdata;
                    8'h34: if (io_wdata[0]) timer_counter <= 32'h00000000;
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule
