module LCD1602_controller
#(
    parameter COUNT_MAX = 800000
)
(
    input clk,
    input reset,
    input ready_i,
    input [7:0] sw,

    output reg rs,
    output reg rw,
    output enable,
    output reg [7:0] data
);

//====================================================
// ESTADOS
//====================================================

localparam IDLE        = 3'd0;
localparam CONFIG      = 3'd1;
localparam WRITE_LINE1 = 3'd2;
localparam SET_LINE2   = 3'd3;
localparam WRITE_LINE2 = 3'd4;
localparam WAIT_CHANGE = 3'd5;
localparam SET_LINE1   = 3'd6;

reg [2:0] state;
reg [2:0] next_state;

//====================================================
// COMANDOS LCD
//====================================================

localparam FUNCTION_SET = 8'h38;
localparam ENTRY_MODE   = 8'h06;
localparam DISPLAY_ON   = 8'h0C;
localparam CLEAR_LCD    = 8'h01;
localparam LINE1_ADDR   = 8'h80;
localparam LINE2_ADDR   = 8'hC0;

reg [2:0] cmd_counter;
reg [4:0] char_counter;

//====================================================
// RELOJ 16 ms
//====================================================

reg clk_16ms;
reg [19:0] clk_counter;

always @(posedge clk or negedge reset)
begin
    if(!reset)
    begin
        clk_counter <= 0;
        clk_16ms <= 0;
    end
    else
    begin
        if(clk_counter == COUNT_MAX-1)
        begin
            clk_counter <= 0;
            clk_16ms <= ~clk_16ms;
        end
        else
            clk_counter <= clk_counter + 1;
    end
end

assign enable = clk_16ms;

//====================================================
// DETECCION DE CAMBIO DE SWITCHES
//====================================================

reg [7:0] sw_old;

wire sw_changed;

assign sw_changed = (sw != sw_old);

//====================================================
// BINARIO -> DECIMAL -> ASCII
//====================================================

reg [3:0] centenas;
reg [3:0] decenas;
reg [3:0] unidades;

reg [7:0] ascii_centena;
reg [7:0] ascii_decena;
reg [7:0] ascii_unidad;

always @(*)
begin

    centenas = sw / 100;
    decenas  = (sw % 100) / 10;
    unidades = sw % 10;

    ascii_centena =
        (centenas == 0) ? " " : (centenas + "0");

    ascii_decena =
        ((centenas == 0) && (decenas == 0))
        ? " "
        : (decenas + "0");

    ascii_unidad = unidades + "0";

end

//====================================================
// FSM
//====================================================

always @(posedge clk_16ms or negedge reset)
begin
    if(!reset)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*)
begin

    case(state)

        IDLE:
            next_state =
                ready_i ? CONFIG : IDLE;

        CONFIG:
            next_state =
                (cmd_counter >= 4) ?
                WRITE_LINE1 :
                CONFIG;

        WRITE_LINE1:
            next_state =
                (char_counter == 15) ?
                SET_LINE2 :
                WRITE_LINE1;

        SET_LINE2:
            next_state = WRITE_LINE2;

        SET_LINE1:
            next_state = WRITE_LINE1;

        WRITE_LINE2:
            next_state =
                (char_counter == 15) ?
                WAIT_CHANGE :
                WRITE_LINE2;

        WAIT_CHANGE:
            next_state =
                sw_changed ?
                SET_LINE1 :
                WAIT_CHANGE;

        default:
            next_state = IDLE;

    endcase

end

//====================================================
// SALIDAS
//====================================================

always @(posedge clk_16ms or negedge reset)
begin

    if(!reset)
    begin
        rs <= 0;
        rw <= 0;
        data <= 8'h00;

        cmd_counter <= 0;
        char_counter <= 0;

        sw_old <= 0;
    end

    else
    begin

        rw <= 0;

        case(state)

        IDLE:
        begin
            cmd_counter <= 0;
            char_counter <= 0;
        end

        CONFIG:
        begin

            rs <= 0;

            case(cmd_counter)
                0: data <= FUNCTION_SET;
                1: data <= ENTRY_MODE;
                2: data <= DISPLAY_ON;
                3: data <= CLEAR_LCD;
                default: data <= CLEAR_LCD;
            endcase

            if(cmd_counter < 4)
                cmd_counter <= cmd_counter + 1;

        end

        WRITE_LINE1:
        begin

            rs <= 1;

            case(char_counter)

                0 : data <= "B";
                1 : data <= "a";
                2 : data <= "t";
                3 : data <= "e";
                4 : data <= "r";
                5 : data <= "i";
                6 : data <= "a";
                7 : data <= " ";

                8 : data <= ascii_centena;
                9 : data <= ascii_decena;
                10: data <= ascii_unidad;

                11: data <= " ";
                12: data <= " ";
                13: data <= " ";
                14: data <= " ";
                15: data <= " ";

                default: data <= " ";

            endcase

            char_counter <= char_counter + 1;

        end

        SET_LINE2:
        begin
            rs <= 0;
            data <= LINE2_ADDR;
            char_counter <= 0;
        end

        SET_LINE1:
        begin
            rs <= 0;
            data <= LINE1_ADDR;
            char_counter <= 0;
        end

        WRITE_LINE2:
        begin

            rs <= 1;

            case(char_counter)

                0 : data <= "B";
                1 : data <= "a";
                2 : data <= "t";
                3 : data <= "e";
                4 : data <= "r";
                5 : data <= "i";
                6 : data <= "a";
                7 : data <= " ";

                8 : data <= ascii_centena;
                9 : data <= ascii_decena;
                10: data <= ascii_unidad;

                11: data <= " ";
                12: data <= " ";
                13: data <= " ";
                14: data <= " ";
                15: data <= " ";

                default: data <= " ";

            endcase

            char_counter <= char_counter + 1;

        end

        WAIT_CHANGE:
        begin
            sw_old <= sw;
        end

        endcase

    end

end

endmodule