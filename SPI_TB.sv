`timescale 1ns/100ps

module SPI_TB();

//Parameter declerations
parameter PAUSE=5;                  //Number of clock cycles between transmit and receive
parameter LENGTH_SEND_C=8;          //Length of sent data (Controller->Peripheray
parameter LENGTH_SEND_P=16;         //Length of sent data (Peripheray-->Controller)
parameter LENGTH_RECIEVED_C=16;     //Length of recieved data (Peripheray-->Controller)
parameter LENGTH_RECIEVED_P=8;      //Length of recieved data (Controller-->Periphery)
parameter LENGTH_COUNT_C=5;         //Default: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter
parameter LENGTH_COUNT_P=5;         //Default: LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter


//Internal signals declarations
logic rst;
logic clk;
logic start_comm;           //Rises to logic high upon communication initiation
logic [LENGTH_SEND_C-1:0] data_send_c;
logic [LENGTH_SEND_P-1:0] data_send_p;


integer k;

SPI #(.PAUSE(PAUSE), .LENGTH_SEND_C(LENGTH_SEND_C), .LENGTH_SEND_P(LENGTH_SEND_P), .LENGTH_RECIEVED_C(LENGTH_RECIEVED_C), .LENGTH_RECIEVED_P(LENGTH_RECIEVED_P), .LENGTH_COUNT_C(LENGTH_COUNT_C), .LENGTH_COUNT_P(LENGTH_COUNT_P)) SPI(
				.rst(rst),
				.clk(clk),
				.data_send_c(data_send_c),
				.data_send_p(data_send_p),
				.start_comm(start_comm)
				);
			
//HDL code
//Initial blocks
initial begin
  rst<=1'b0;	
  clk<=1'b0;
  start_comm<=1'b0;
  #1000
  rst<=1'b1;
  #1100
  
  
    //----------------------------------------//
    //Test #1: Random 8-bit words is sent from the controller to the periphary unit which sends back the recieved word concatenated with itself
for(k=0; k<10; k++) begin
  data_send_c= $random%8;                             //8-bit random number to be sent to the periphary
  data_send_p={data_send_c,data_send_c};
  start_comm<=1'b1;                                   //Initial communication
  repeat(LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+4) begin   //wait for the comminication to terminate
    @(posedge clk)
    start_comm<=1'b0;
  end
#1;                                  
if (SPI.CIPO_register == data_send_p) begin
            $display("Data sent from controller to periphary is %b data recieved is %b on iteration number %d-success",data_send_c,SPI.CIPO_register,k);
end
else begin
  $display("Data sent from controller to periphary is %b data recieved is %b on iteration number %d- fail",data_send_c,SPI.CIPO_register,k); 
  $finish;
end
end
$display("\nTest 1 completed successfully\n");
$finish;  
end

//Clock generation
always begin
  #10; 
  clk=~clk;	
end		

endmodule


