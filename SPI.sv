
module SPI (rst,clk,data_send_c,data_send_p,start_comm);

//parameters
parameter PAUSE=5;                 //Number of clock cycles between transmit and receive
parameter LENGTH_SEND_C=8;         //Length of sent data (Controller->Peripheray
parameter LENGTH_SEND_P=8;         //Length of sent data (Peripheray-->Controller)
parameter LENGTH_RECIEVED_C=8;     //Length of recieved data (Peripheray-->Controller)
parameter LENGTH_RECIEVED_P=8;     //Length of recieved data (Controller-->Periphery)
parameter LENGTH_COUNT_C=5;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter
parameter LENGTH_COUNT_P=5;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter

//Input signals
input logic rst;                   //Active high loghs							
input logic clk;                   //Controller's clock
input logic [LENGTH_SEND_C-1:0] data_send_c;  //Data to be sent from the controller
input logic [LENGTH_SEND_P-1:0] data_send_p;  //Data to be sent from the periphary unit
input logic start_comm;                       //Rises to logic high upon communication initiation

//Internal signals
logic COPI;                         //Controller-Out Peripheral-In
logic CIPO;                         //Controller-in periphary-out 
logic SCK;                          //Shared serial clock
logic CS;                           //Chip select
logic [LENGTH_SEND_P-1:0] CIPO_register;  //Holds the data received at the controller unit
logic [LENGTH_SEND_C-1:0] COPI_register;  //Holds the data recieved at the peripheral unit


//Controller instantiation
SPI_Controller #(.PAUSE(PAUSE), .LENGTH_SEND(LENGTH_SEND_C), .LENGTH_RECIEVED(LENGTH_RECIEVED_C), .LENGTH_COUNT(LENGTH_COUNT_C)) SPI_C_1(.rst(rst),
																							.clk(clk),
																							.SCK(SCK),
																							.COPI(COPI),
																							.CIPO(CIPO),
																							.data_send(data_send_c),
																							.start_comm(start_comm),
																							.CS(CS),
																							.CIPO_register(CIPO_register)
																							);
							
SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) SPI_P_1(.SCK(SCK),
																							.COPI(COPI),
																							.CIPO(CIPO),
																							.CS(CS),
																							.data_send(data_send_p),		
																							.rst(rst),
																							.COPI_register(COPI_register)
								);
		



							
endmodule


