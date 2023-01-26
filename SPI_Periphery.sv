//SPI periphery

module SPI_Periphery(rst,SCK,COPI,CIPO,COPI_register,CS,data_send);

//Parameter declarations
parameter LENGTH_SEND=8;                          //Length of sent data (Peripheray-->Controller)
parameter LENGTH_RECIEVED=8;                      //Length of recieved data (Controller-->Periphary)
parameter LENGTH_COUNT=5;                         //Default: 8+10+1=17 --> 5 bit counter
parameter PAUSE=10;	                              //Pause between controller TX and periperal TX 

//Input declarations
input logic SCK;                                  //Serial clock from the controller
input logic COPI;                                 //Controller-output-periphary-input
input logic CS;                                   //Chip-select: active low logic
input logic [LENGTH_SEND-1:0] data_send;          //Data sent to the controller
input rst;                                        //Active low logic

//Output declarations
output logic CIPO;                                //Controller input periphary output signal
output logic [LENGTH_RECIEVED-1:0] COPI_register; //The data recieved from the controller

//Internal logic signals 
logic [LENGTH_SEND-1:0] CIPO_register;            //The data to be sent is sampled
logic [LENGTH_COUNT-1:0] count;
logic rst_internal;                               //The periphary unit is active if both its rst signal and CS signal are logic low

//HDL code

assign rst_internal = rst&&~CS;

always @(posedge SCK or negedge rst_internal)     //Recieving data from the controller on positive edge
  if (!rst_internal) begin
    count<='0;
    COPI_register<='0;
  end
  else if (count<LENGTH_RECIEVED) begin
    COPI_register<={COPI,COPI_register[LENGTH_RECIEVED-1:1]};
    count<=count+1;
  end
  else if (count<LENGTH_RECIEVED+LENGTH_SEND)
    count<=count+1;
  else if (count==LENGTH_RECIEVED+LENGTH_SEND)
    count<=0;

always @(negedge SCK or negedge rst_internal)   //Sending data to the controller on negative edge
  if (!rst_internal) begin
    CIPO<=(~CS) ? 1'b0 : 1'bz;
    CIPO_register<='0;
  end
  else if (count==LENGTH_RECIEVED)  //Sample the data to be sent (perphary-->controller)
    CIPO_register<=data_send;
  else if (count<LENGTH_RECIEVED+LENGTH_SEND+2) begin
    CIPO<=(~CS) ? CIPO_register[0] : 1'bz;
    CIPO_register<=CIPO_register>>1;
  end

endmodule