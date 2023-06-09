//DAC simulation module
module dac_ad5318(
   input  logic       SCLK,     //clocking signal 
   input  logic       SYNC_b,   //synchronization signal
   input  logic       DIN,      //input data
   input  logic       LDAC_b,   //DAC-registers control signals 
 
   output logic [9:0] VoutA,    //output's
   output logic [9:0] VoutB,
   output logic [9:0] VoutC,
   output logic [9:0] VoutD,
   output logic [9:0] VoutE,
   output logic [9:0] VoutF,
   output logic [9:0] VoutG,
   output logic [9:0] VoutH
);

    ////////////////////////
    // local declarations //
    ////////////////////////
    
   logic [5:0]          count = 1'd0;                 //counter
   logic [15:0]         din_shift;                    //shift-register at the input
   
   enum 
   logic [1:0]         {Control_functions = 2'b00,
                        LDAC_control      = 2'b01,
                        Power_down        = 2'b10,
                        Reset             = 2'b11} control_words;
   
   logic                VDD_bits_A_D, VDD_bits_E_H;   //bits of power supply simulatio
   logic                BUF_bits_A_D, BUF_bits_E_H;   //bits of DAC ref simulation 
   logic                GAIN_bits_A_D, GAIN_bits_E_H; //voltage range simulation bits(0 - Vref, 1 - 2Vref)        
   
   logic                LDAC_reg;                     //some LDAC regs
   logic                LDAC_single = 1'b0;
   logic                LDAC_flag   = 1'b1;
   
   typedef 
   struct packed       {logic [9:0] inreg;           //input registers on every output
                        logic [9:0] DACreg;          //Simulation Power-down key's for complition Power-down comand(all in power-off state at begining)
                        logic       key;             //DAC registers on every output
                        } chanel;
   
   chanel chanels[8];  
   
   ///////////////////////////
   //Description of the work//
   ///////////////////////////
   
   always_ff @(posedge SCLK or negedge SYNC_b) begin:main_alw
      if (!SYNC_b) begin:sync_if
         count <= count + 1'b1;
         din_shift <= { DIN , din_shift[15:1] };
         end:sync_if
         if (count > 16)
            $error("Over 16 bits!");
            
         if (count == 16) begin:cnt_16
             count <= 0;
             
         if (LDAC_flag) begin
             LDAC_reg <= LDAC_b;
             LDAC_flag <= 0;
         end
             
            if (din_shift[15]) begin:op_15
                case(din_shift[14:13])  
         
                     Control_functions: begin //ref select comand
                                        
                                        VDD_bits_A_D <= din_shift[0];
                                        VDD_bits_E_H <= din_shift[1];
                                        
                                        BUF_bits_A_D <= din_shift[2];
                                        BUF_bits_E_H <= din_shift[3];
                                        
                                        GAIN_bits_A_D <= din_shift[4];
                                        GAIN_bits_E_H <= din_shift[5];
                                        
                                        if (din_shift[4]) $display("A-D output set 2Vref range");
                                        else              $display("A-D output set Vref range"); 
                                        
                                        if (din_shift[5]) $display("E-H output set 2Vref range");
                                        else              $display("E-H output set Vref range");
                                        
                                        $display("Ref select mode set");
                                        end
         
                          LDAC_control: begin //setting up the operation of the LDAC_b signal
                                        
                                        if (din_shift[1:0] == 0) LDAC_reg <= 0;
                                        
                                        if (din_shift[1:0] == 1) LDAC_reg <= 1;
                                        
                                        if (din_shift[1:0] == 2) begin 
                                            LDAC_single <= 1;
                                            LDAC_reg <= 0;
                                            $display("Single trasaction ");
                                            end
                                        
                                        $display("LDAC new mode set");
                                        end
         
                            Power_down: begin //power off to DAC outputs (setting to 1 - off, 0 - on)
                                        
                                        for (int i = 0; i < 8; i = i + 1) begin      
                                        chanels[i].key <= din_shift[i];                                         
                                        end
                                        
                                        $display("Power-down mode settings set");
                                        end
         
                                 Reset: begin //control word RESET
                                        if (!din_shift[13]) begin
                                        
                                               for(int i = 0; i < 8; i = i +1) begin                                               
                                               chanels[i].inreg <= 0;                                               
                                               end
                                               
                                               for(int i = 0; i < 8; i = i +1) begin                                              
                                               chanels[i].DACreg <= 0;                                               
                                               end

                                               $display("Reset all DAC and inp. regs");
                                            end else begin
                                            
                                               for(int i = 0; i < 8; i = i +1) begin                                               
                                               chanels[i].inreg <= 0;                                               
                                               end                                               
                                               
                                               for(int i = 0; i < 8; i = i +1) begin                                              
                                               chanels[i].DACreg <= 0;                                               
                                               end
                                                
                                                VDD_bits_A_D <= 0;
                                                VDD_bits_E_H <= 0;
                                        
                                                BUF_bits_A_D <= 0;
                                                BUF_bits_E_H <= 0;
                                        
                                                GAIN_bits_A_D <= 0;
                                                GAIN_bits_E_H <= 0;
                                                
                                                LDAC_flag     <= 1;
                                                
                                                $display("Reset all DAC and all control bits");
                                                
                                                end
                                        end           
                endcase 
            end:op_15 else begin:inreg_transfer
                            chanels[din_shift[14:12]].inreg = din_shift[11:2];
                      end:inreg_transfer              
         end:cnt_16
         if (!LDAC_reg) begin:ldac 
         
         for(int i = 0; i < 8; i = i + 1) begin
            chanels[i].DACreg <= chanels[i].inreg;         
         end        

         if (LDAC_single) begin //one-shot transaction
             LDAC_single <= 0;
             LDAC_reg <= 1;
         end
         end:ldac    
            

   end:main_alw   
   
   //Depending on the installation of the key - does the output work or not     
   assign  VoutA = ~chanels[0].key    ? chanels[0].DACreg //A
                                      : 10'hZZZ; 
                           
   assign  VoutB = ~chanels[1].key    ? chanels[1].DACreg //B
                                      : 10'hZZZ;
                           
   assign  VoutC = ~chanels[2].key    ? chanels[2].DACreg //C
                                      : 10'hZZZ; 
                                         
   assign  VoutD = ~chanels[3].key    ? chanels[3].DACreg //D
                                      : 10'hZZZ;
                            
   assign  VoutE = ~chanels[4].key    ? chanels[4].DACreg //E
                                      : 10'hZZZ;
                             
   assign  VoutF = ~chanels[5].key    ? chanels[5].DACreg //F
                                      : 10'hZZZ;
                            
   assign  VoutG = ~chanels[6].key    ? chanels[6].DACreg //G
                                      : 10'hZZZ;
                            
   assign  VoutH = ~chanels[7].key    ? chanels[7].DACreg //H
                                      : 10'hZZZ;
                   
    
endmodule