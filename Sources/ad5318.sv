module ad5318#(
    parameter DIVIDER = 4'd4,   //Divisor only works with even numbers!!
                                //Able to handle division by numbers from 2 to 14 inclusive
    parameter LDAC_VALUE = 1'b1 //parameter responsible for the update value of the DAC registers
                                //(Recommended to keep high,
                                //so that the input registers do not affect the DAC registers at startup)
    )(
    input  logic        clkin,  //clocking signal
    input  logic        rstn,   //reset signal
    
    
    
    //signals in DAC
    output logic        SCLK,
    output logic        DIN,
    output logic        SYNC_b,
    output logic        LDAC_b,
    
    //module signals
    input  logic [15:0] tdata,
    input  logic        tvalid,
    input  logic [2:0]  tuser,
    output logic        tready
    
    );
    
    ////////////////////////
    // Local declarations //
    ////////////////////////
    
    logic [3:0]   div_reg = 0;
    
    logic [15:0]  din_shift;
    
    enum 
    logic        {waiting = 1'b0,
                  busy    = 1'b1} states;      

    logic [5:0]   count_module;
    
    logic         idle_clk;
    
    /////////////////
    // Main module //
    /////////////////
    
    //Frequency divider on registers 
    always_ff @(posedge clkin)
    if (~rstn) begin
        SCLK <= 0;  
        states <= waiting;
        tready <= 1;
        SYNC_b <= 1;
        idle_clk <= 1;
        count_module <= 0;
    end else begin
            div_reg <= div_reg + 1;
            if (div_reg == DIVIDER/2-1) 
                begin
                SCLK <= ~SCLK;
                div_reg <= 0;
                end 
    end  
   

    assign LDAC_b = LDAC_VALUE; //LDAC start setup


    always_ff @(posedge clkin) //state-machine
    
           case (states)
                waiting : begin
                          if (tvalid) begin
                             tready <= 0; 
                             states <= busy; 
                             idle_clk <= 1;  
                                 
                              if (tdata[15]) din_shift <= tdata;
                              else din_shift <= { 1'b0 , tuser[2:0] , tdata[9:0], 2'b00};  
                                                  
                              end

                           end
                   busy : begin
                          if (div_reg == DIVIDER/2 -1 && ~SCLK) begin:sclk
                          DIN <= din_shift[0]; 
                          SYNC_b <= 0;
                          din_shift <= { 1'b0 , din_shift[15:1] };
                          count_module <= count_module + 1;
                          
                             if (count_module == 16) begin
                                 states <= waiting;
                                 count_module <= 0;
                                 tready <= 1;
                                 SYNC_b <= 1;
                                 
                             end
                          end:sclk
                          
                          if (SCLK) idle_clk <= ~idle_clk;
                                                       
                          end
          endcase

endmodule
