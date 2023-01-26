//SPI controller

module SPI_Controller(rst,clk,SCK,COPI,CIPO,CIPO_register,CS_in,CS_out,data_send,start_comm);

//Parameter declarations
parameter PAUSE=5;                           //Number of clock cycles between transmit and receive
parameter LENGTH_SEND=8;                     //Length of sent data (Controller->Peripheray)
parameter LENGTH_RECIEVED=8;                 //Length of recieved data (Peripheray-->Controller)
parameter LENGTH_COUNT=5;                    //Default: 8+8+10=26 -->5 bit counter
parameter PERIPHERY_COUNT=4;                 //Number of peripherals
parameter PERIPHERY_SELECT=2;                //Periphery select signals (log2 of PERIPHERY_COUNT)
//Input declarations
input logic clk;                             //Controller clock 
input logic rst;                             //Active high logic

input logic CIPO;                            //Controller-In Peripheral-Out
input logic [LENGTH_SEND-1:0] data_send;     //Data to be sent from the controller to one of the peripherals
input logic start_comm;                      //SPI communication protocol is initiated when start_comm rises to logic high. At this instance the data_send should be valid
input logic [PERIPHERY_SELECT-1:0] CS_in;
//Output declarations
output logic COPI;                           //Controller-Out Peripheral-In
output logic SCK;                            //Shared clock between controller and peripheral units
output logic [PERIPHERY_COUNT-1:0] CS_out;   //Chip-select
output logic [LENGTH_RECIEVED-1:0] CIPO_register;   //Holds the data received from the peripheral unit

//Internal logic signals 
logic start_comm_delayed;                    //One clock cycle delayed start_comm signal
logic start;                                 //Rises to logic high for a single clock cycle upon communication initiation
logic busy;
logic [LENGTH_COUNT-1:0] count_neg;          //Negative-edge counter. The controller modifies the COPI line on the negative edge of the shared clock (peripheral unit samples on rising edge)
logic [LENGTH_COUNT-1:0] count_pos;          //Positive-edge counter - for the SCK generation

logic [LENGTH_SEND-1:0] COPI_register;       //The data to be sent is sampled - used in a shift-register structure
integer i;

//HDL code

always @(posedge clk or negedge rst)
  if (!rst) begin
    start_comm_delayed<=1'b0;
    start<=1'b0;
    busy<=1'b0;
    CIPO_register<='0;
    count_pos<=(LENGTH_COUNT)'(LENGTH_SEND)+(LENGTH_COUNT)'(LENGTH_RECIEVED)+(LENGTH_COUNT)'(1)+(LENGTH_COUNT)'(PAUSE);
    CS_out<='0;
  end
  else begin
    start_comm_delayed<=start_comm;         //Generating a single clock cycle pulse indication initiation of communication
    start<=start_comm&&(~start_comm_delayed)&&(~busy);

    if ((count_neg>(LENGTH_COUNT)'(LENGTH_SEND)+(LENGTH_COUNT)'(1)+(LENGTH_COUNT)'(PAUSE)) && (count_neg<(LENGTH_COUNT)'(LENGTH_SEND)+(LENGTH_COUNT)'(PAUSE)+(LENGTH_COUNT)'(LENGTH_RECIEVED)+(LENGTH_COUNT)'(2)))    //Receiving data from peripheral unit
      CIPO_register<={CIPO,CIPO_register[LENGTH_RECIEVED-1:1]};

    if (start==1'b1) begin
      count_pos<='0;
      busy<=1'b1;

      for (i=0; i<PERIPHERY_COUNT; i++)
        CS_out[i]<=~(CS_in==($bits(CS_in))'(i));
end
    else if (count_pos<(LENGTH_COUNT)'(LENGTH_SEND)+(LENGTH_COUNT)'(LENGTH_RECIEVED)+(LENGTH_COUNT)'(PAUSE)+(LENGTH_COUNT)'(1))
      count_pos<=count_pos+(LENGTH_COUNT)'(1);	
    else
      busy<=1'b0;
end

always @(negedge clk or negedge rst)
  if (!rst) begin
    COPI_register<='0;
    COPI<=1'b0;
    count_neg<=LENGTH_SEND+LENGTH_RECIEVED+2+PAUSE;  //TALK TO IVGENY ON THESE WAARNINGS
  end
  else if (start==1'b1) begin
    count_neg<=0;
    COPI_register<=data_send;  //Sample data to be sent to the peripheral unit
  end
  else if (count_neg<LENGTH_SEND) begin
    COPI<=COPI_register[0];
    COPI_register<=COPI_register>>1;
    count_neg<=count_neg+1;
  end
  else if (count_neg<LENGTH_SEND+LENGTH_RECIEVED+PAUSE+2) begin
    count_neg<=count_neg+1;
  end

//Creating the serial clock shared by the controller and all peripheral units
assign SCK = (count_pos<LENGTH_SEND) ? clk : (count_pos<LENGTH_SEND+PAUSE) ? 1'b1 : (count_pos<LENGTH_SEND+LENGTH_RECIEVED+PAUSE+1) ? clk  : 1'b1;	
endmodule