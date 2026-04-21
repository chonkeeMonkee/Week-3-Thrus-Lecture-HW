
module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// STATES: State of the state machine
localparam DATA_BITS = 8;

    typedef enum logic [2:0] {INIT, IDLE, RX_DATA, STOP} state_t; 

    state_t state = INIT; 
    state_t next_state; 

// CLOCK MULTIPLIER: Instantiate the clock multiplier
wire uart_clock; 

clock_mul  
    #(.SRC_FREQ (SRC_FREQ),
    .OUT_FREQ(BAUDRATE)) clockMult (
        .src_clk(clk),
        .out_clk(uart_clock)
    );
    

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.
logic r1_pulse, r2_pulse, r3_pulse; 

always_ff @(posedge clk) begin
    r1_pulse <= done;
    r2_pulse <= r1_pulse;
    r3_pulse <= r2_pulse;

    if ((r3_pulse == 1'b0) && (r2_pulse == 1'b1)) begin
        rx_ready <= 1'b1; 
    end else begin
        rx_ready <= 1'b0; 
    end 
end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal
logic [2:0] bit_count; 
logic done; 

always_ff @ (posedge uart_clock) begin
    state <= next_state;
end

always_comb begin
    next_state = state;

    case (state)
        INIT : next_state = IDLE;
        IDLE : next_state = state_t' (rx ? IDLE : RX_DATA);
        RX_DATA : next_state = state_t' (bit_count == 7 ? STOP : RX_DATA);
        STOP : next_state = state_t' (rx ? IDLE : STOP);
        default: next_state = INIT;

    endcase
    
end

always_ff @ (posedge uart_clock)begin
    done <= 0; 

    case(state)
        INIT: begin
            rx_data <= 0; 
            bit_count <= 0; 
        end
        IDLE: begin
            bit_count <= 0;
        end
        RX_DATA: begin
            rx_data[bit_count] <= rx; 
            bit_count <= bit_count + 1;      
        end 
        STOP: begin
            if (rx) begin
                done <= 1;
            end 
            bit_count <= 0; 
        end
        default: begin
            bit_count <= 0; 
        end
    endcase
end

endmodule