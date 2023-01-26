`timescale 1ns/100ps

module SPI_TB();

//Parameter declerations
parameter PAUSE=5;                  //Number of clock cycles between transmit and receive
parameter LENGTH_SEND_C=8;          //Length of sent data (Controller->Peripheral unit)
parameter LENGTH_SEND_P=16;         //Length of sent data (Peripheral unit-->Controller)
parameter LENGTH_RECIEVED_C=16;     //Length of recieved data (Peripheral unit-->Controller)
parameter LENGTH_RECIEVED_P=8;      //Length of recieved data (Controller-->Peripheral unit)
parameter LENGTH_COUNT_C=5;         //LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter (default settings)
parameter LENGTH_COUNT_P=5;         //LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter (default settings)
parameter PERIPHERY_COUNT=4;        //Number of peripherals
parameter PERIPHERY_SELECT=2;       //Peripheral unit select signals (log2 of PERIPHERY_COUNT)
integer SEED=15;

//Internal signals declarations
logic rst;
logic clk;
logic start_comm;                   //Rises to logic high upon communication initiation
logic [LENGTH_SEND_C-1:0] data_send_c;
logic [LENGTH_SEND_P-1:0] data_send_p;
logic [PERIPHERY_SELECT-1:0] CS_in;
logic [LENGTH_SEND_P-1:0] COPI_register_compare;
integer k;
integer wait_rand;

SPI #(.PAUSE(PAUSE), .LENGTH_SEND_C(LENGTH_SEND_C), .LENGTH_SEND_P(LENGTH_SEND_P), .LENGTH_RECIEVED_C(LENGTH_RECIEVED_C), .LENGTH_RECIEVED_P(LENGTH_RECIEVED_P), .LENGTH_COUNT_C(LENGTH_COUNT_C), .LENGTH_COUNT_P(LENGTH_COUNT_P), .PERIPHERY_COUNT(PERIPHERY_COUNT), .PERIPHERY_SELECT(PERIPHERY_SELECT)) SPI(
            .rst(rst),
            .clk(clk),
            .data_send_c(data_send_c),
            .data_send_p(data_send_p),
            .start_comm(start_comm),
            .CS_in(CS_in)
);

//HDL code
//Initial blocks
initial begin
  rst=1'b0;	
  clk=1'b0;
  start_comm=1'b0;
  CS_in=2'b00;
  wait_rand=0;
  data_send_c='0;
  data_send_p='0;
  #1000
  rst=1'b1;
  #1100
  
//----------------------------------------//
//Test #1: Random 8-bit words is sent from the controller to the periphary. Random 16-bit word is sent from the periphary to the controller. Communication with SPI_P_0.
for(k=0; k<10; k++) begin
  data_send_c= $dist_uniform(SEED,0,2**LENGTH_SEND_C-1);        //8-bit random number to be sent to the periphary
  data_send_p= $dist_uniform(SEED,0,2**LENGTH_SEND_P-1);        //16-bit random number to be sent to the controller

  start_comm<=1'b1;                                             //Initial communication
  
  //Total duration of a communication interval is: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+4
  repeat(LENGTH_SEND_C+PAUSE+LENGTH_SEND_P+4) begin           //Wait for the comminication to terminate
    @(posedge clk)
    start_comm<=1'b0;
  end

#1;
//Verify the data was succesfully sent from the Peripheral unit-->controller
if (SPI.CIPO_register == data_send_p) begin
            $display("\nData sent from periphary is %b data recieved in the controller is %b on iteration number %d-success",data_send_p,SPI.CIPO_register,k);
end
else begin
  $display("\nData sent from Peripheral unit to controller is %b data recieved is %b on iteration number %d- fail",data_send_p,SPI.CIPO_register,k); 
  $finish;
 end
 
//Verify the data was succesfully sent from the controller-->Peripheral unit
if (SPI.COPI_register_0 == data_send_c) begin
            $display("\nData sent from controller is %b data recieved in the Peripheral unit is %b on iteration number %d-success",data_send_c,SPI.COPI_register_0,k);
end
else begin
  $display("\nData sent from controller to periphary is %b data recieved is %b on iteration number %d- fail",data_send_c,SPI.COPI_register_0,k); 
  $finish;  
end

end
$display("\nTest 1 completed successfully\n");

//----------------------------------------//

//Test 2#: Random 8-bit words is sent from the controller to the periphary. Random 16-bit word is sent from the periphary to the controller. Communication with SPI_P_0. start_comm is re-trigerred when busy.
for(k=0; k<10; k++) begin
  data_send_c= $dist_uniform(SEED,0,2**LENGTH_SEND_C-1);                        //8-bit random number to be sent to the periphary
  data_send_p= $dist_uniform(SEED,0,2**LENGTH_SEND_P-1);                        //16-bit random number to be sent to the controller
  wait_rand= $dist_uniform(SEED,0,LENGTH_SEND_C+PAUSE+LENGTH_SEND_P);           //wait period before re-trigerring the 'start comm.' signal

  start_comm<=1'b1;                                                             //Initial communication
  
  //Total duration of a communication interval is: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+4
  repeat(wait_rand) begin                                                       //Wait for the comminication to terminate
    @(posedge clk)
    start_comm<=1'b0;
  end
  
  @(posedge clk)
    start_comm<=1'b1;
  
  repeat(LENGTH_SEND_C+PAUSE+LENGTH_SEND_P+3-wait_rand) begin                   //Wait for the comminication to terminate
    @(posedge clk)
    start_comm<=1'b0;
  end  

  #1;   
  //Verify the data was succesfully sent from the Peripheral unit-->controller
  if (SPI.CIPO_register == data_send_p) begin
    $display("\nData sent from periphary is %b data recieved in the controller is %b on iteration number %d-success",data_send_p,SPI.CIPO_register,k);
  end
  else begin
    $display("\nData sent from Peripheral unit to controller is %b data recieved is %b on iteration number %d- fail",data_send_p,SPI.CIPO_register,k); 
    $finish;
  end

  //Verify the data was succesfully sent from the controller-->Peripheral unit
  if (SPI.COPI_register_0 == data_send_c) begin
            $display("\nData sent from controller is %b data recieved in the Peripheral unit is %b on iteration number %d-success",data_send_c,SPI.COPI_register_0,k);
  end
  else begin
    $display("\nData sent from controller to periphary is %b data recieved is %b on iteration number %d- fail",data_send_c,SPI.COPI_register_0,k); 
    $finish;  
  end

end
$display("\nTest 2 completed successfully\n");
//----------------------------------------//

//Test #3: Random 8-bit words is sent from the controller to the periphary. Random 16-bit word is sent from the periphary to the controller. Randomly change the periphery.
for(k=0; k<20; k++) begin 
  data_send_c= $dist_uniform(SEED,0,2**LENGTH_SEND_C-1);                    //8-bit random number to be sent to the periphary
  data_send_p= $dist_uniform(SEED,0,2**LENGTH_SEND_P-1);                    //16-bit random number to be sent to the controller
  CS_in= $dist_uniform(SEED,0,PERIPHERY_COUNT-1);                           //Randomizing CS signal 
  //CS_in=2'b00;
  start_comm<=1'b1;                                                         //Initial communication

  //Total duration of a communication interval is: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+4
  repeat(LENGTH_SEND_C+PAUSE+LENGTH_SEND_P+4) begin   //wait for the comminication to terminate
    @(posedge clk)
    start_comm<=1'b0;
  end

  #1;
  //Verify the data was succesfully sent from the periphery-->controller                               
  if (SPI.CIPO_register == data_send_p) begin
    $display("\nData sent from periphary number %d is %b data recieved in the controller is %b on iteration number %d-success",CS_in,data_send_p,SPI.CIPO_register,k);
  end
  else begin
    $display("\nData sent from periphery number %d to controller is %b data recieved is %b on iteration number %d- fail",CS_in,data_send_p,SPI.CIPO_register,k); 
    $finish;
   end
 
  //Verify the data was succesfully sent from the controller-->periphery                               
  if (COPI_register_compare == data_send_c) 
    $display("\nData sent from controller is %b data recieved in the periphery number %d is %b on iteration number %d-success",data_send_c,CS_in,COPI_register_compare,k);
  else begin
    $display("\nData sent from controller to periphary number %d is %b data recieved is %b on iteration number %d- fail",CS_in,data_send_c,COPI_register_compare,k); 
    $finish;
  end

end

$display("\nTest 3 completed successfully\n");	
$finish;
end

//HDL Code
assign COPI_register_compare = (CS_in==2'b00) ? SPI.COPI_register_0 : (CS_in==2'b01) ? SPI.COPI_register_1 : (CS_in==2'b10) ? SPI.COPI_register_2 : SPI.COPI_register_3;

//Clock generation
always begin
  #10;
  clk=~clk;
end

endmodule
