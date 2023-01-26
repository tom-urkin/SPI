//SPI communication with four peripheral devices
module SPI (rst,clk,data_send_c,data_send_p,start_comm,CS_in);

//parameters
parameter PAUSE=5;                 //Number of clock cycles between transmit and receive
parameter LENGTH_SEND_C=8;         //Length of sent data (Controller->Peripheral unit
parameter LENGTH_SEND_P=8;         //Length of sent data (Peripheral unit-->Controller)
parameter LENGTH_RECIEVED_C=8;     //Length of recieved data (Peripheral unit-->Controller)
parameter LENGTH_RECIEVED_P=8;     //Length of recieved data (Controller-->Peripheral unit)
parameter LENGTH_COUNT_C=5;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter
parameter LENGTH_COUNT_P=5;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter
parameter PERIPHERY_COUNT=4;       //Number of peripherals
parameter PERIPHERY_SELECT=2;      //Peripheral unit select signals (log2 of PERIPHERY_COUNT)

//Input signals
input logic rst;                              //Active high logic
input logic clk;                              //Controller's clock
input logic [LENGTH_SEND_C-1:0] data_send_c;  //Data to be sent from the controller
input logic [LENGTH_SEND_P-1:0] data_send_p;  //Data to be sent from the periphary unit
input logic start_comm;                       //Rises to logic high upon communication initiation
input logic [PERIPHERY_SELECT-1:0] CS_in;     //Chip-select (set in the TB)

//Internal signals
logic COPI;                                   //Controller-Out Peripheral-In
wire CIPO;                                    //Controller-in periphary-out //changed from logic to support multiple drivers
logic SCK;                                    //Shared serial clock
logic CS;                                     //Chip select
logic [LENGTH_SEND_P-1:0] CIPO_register;      //Holds the data received at the controller unit
logic [LENGTH_SEND_C-1:0] COPI_register_0;    //Holds the data recieved at the peripheral unit (SPI_P_0)
logic [LENGTH_SEND_C-1:0] COPI_register_1;    //Holds the data recieved at the peripheral unit (SPI_P_1)
logic [LENGTH_SEND_C-1:0] COPI_register_2;    //Holds the data recieved at the peripheral unit (SPI_P_2)
logic [LENGTH_SEND_C-1:0] COPI_register_3;    //Holds the data recieved at the peripheral unit (SPI_P_3)
logic [PERIPHERY_COUNT-1:0] CS_out;           //One-hot encoding

//Controller instantiation
SPI_Controller #(.PAUSE(PAUSE), .LENGTH_SEND(LENGTH_SEND_C), .LENGTH_RECIEVED(LENGTH_RECIEVED_C), .LENGTH_COUNT(LENGTH_COUNT_C), .PERIPHERY_COUNT(PERIPHERY_COUNT), .PERIPHERY_SELECT(PERIPHERY_SELECT)) SPI_C_0(.rst(rst),
                                .clk(clk),
                                .SCK(SCK),
                                .COPI(COPI),
                                .CIPO(CIPO),
                                .data_send(data_send_c),
                                .start_comm(start_comm),
                                .CS_in(CS_in),
                                .CS_out(CS_out),
                                .CIPO_register(CIPO_register)
);

SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) SPI_P_0(.SCK(SCK),
                                .COPI(COPI),
                                .CIPO(CIPO),
                                .CS(CS_out[0]),
                                .data_send(data_send_p),
                                .rst(rst),
                                .COPI_register(COPI_register_0)
);

SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) SPI_P_1(.SCK(SCK),
                                .COPI(COPI),
                                .CIPO(CIPO),
                                .CS(CS_out[1]),
                                .data_send(data_send_p),
                                .rst(rst),
                                .COPI_register(COPI_register_1)
);

SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) SPI_P_2(.SCK(SCK),
                                .COPI(COPI),
                                .CIPO(CIPO),
                                .CS(CS_out[2]),
                                .data_send(data_send_p),
                                .rst(rst),
                                .COPI_register(COPI_register_2)
);

SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) SPI_P_3(.SCK(SCK),
                                .COPI(COPI),
                                .CIPO(CIPO),
                                .CS(CS_out[3]),
                                .data_send(data_send_p),
                                .rst(rst),
                                .COPI_register(COPI_register_3)
);
endmodule
