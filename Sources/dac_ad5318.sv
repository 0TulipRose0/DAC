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
    
   logic [5:0]  count = 1'd0;                 //counter
   logic [15:0] din_shift;                    //shift-register at the input
   
   //input registers on every output
   logic [0:9]  inreg  [7:0];
   //Simulation Power-down key's for complition Power-down comand(all in power-off state at begining)
   logic [7:0]  key;
   //DAC registers on every output
   logic [0:9]  DACreg [7:0];
   
   enum 
   logic [1:0] {Control_functions = 2'b00,
                LDAC_control      = 2'b01,
                Power_down        = 2'b10,
                Reset             = 2'b11} control_words;
   
   logic        VDD_bits_A_D, VDD_bits_E_H;   //bits of power supply simulatio
   logic        BUF_bits_A_D, BUF_bits_E_H;   //bits of DAC ref simulation 
   logic        GAIN_bits_A_D, GAIN_bits_E_H; //voltage range simulation bits(0 - Vref, 1 - 2Vref)        
   
   logic        LDAC_reg;                     //some LDAC regs
   logic        LDAC_single = 1'b0;
   logic        LDAC_flag   = 1'b1;
   
//   typedef struct packed       {logic [0:7] inregs [7:0];
   
   
//                                   } chanel;
   
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
                                              
                                        key <= din_shift[7:0]; 
                                        
                                        $display("Power-down mode settings set");
                                        end
         
                                 Reset: begin //control word RESET
                                        if (!din_shift[13]) begin
                                        
                                               for(int i = 0; i < 8; i = i +1) begin                                               
                                               inreg[i] <= 0;                                               
                                               end
                                               
                                               for(int i = 0; i < 8; i = i +1) begin                                              
                                               DACreg[i] <= 0;                                               
                                               end

                                               $display("Reset all DAC and inp. regs");
                                            end else begin
                                            
                                               for(int i = 0; i < 8; i = i +1) begin                                               
                                               inreg[i] <= 0;                                               
                                               end                                               
                                               
                                               for(int i = 0; i < 8; i = i +1) begin                                              
                                               DACreg[i] <= 0;                                               
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
                            inreg[din_shift[14:12]] = din_shift[11:2];
                      end:inreg_transfer              
         end:cnt_16
         if (!LDAC_reg) begin:ldac 
         
         for(int i = 0; i < 8; i = i + 1) begin
            DACreg[i] <= inreg[i];         
         end        

         if (LDAC_single) begin //one-shot transaction
             LDAC_single <= 0;
             LDAC_reg <= 1;
         end
         end:ldac    
            

   end:main_alw   
   
   //Depending on the installation of the key - does the output work or not     
   assign  VoutA = ~key[0]   ? DACreg[0] //A
                            : 10'hZZZ; 
                           
   assign  VoutB = ~key[1]   ? DACreg[1] //B
                            : 10'hZZZ;
                           
   assign  VoutC = ~key[2]   ? DACreg[2] //C
                            : 10'hZZZ; 
                                         
   assign  VoutD = ~key[3]   ? DACreg[3] //D
                            : 10'hZZZ;
                            
   assign  VoutE = ~key[4]   ? DACreg[4] //E
                            : 10'hZZZ;
                             
   assign  VoutF = ~key[5]   ? DACreg[5] //F
                            : 10'hZZZ;
                            
   assign  VoutG = ~key[6]  ? DACreg[6] //G
                            : 10'hZZZ;
                            
   assign  VoutH = ~key[7]   ? DACreg[7] //H
                            : 10'hZZZ;
                   
    
endmodule