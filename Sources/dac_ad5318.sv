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
    
   //регистры входа на каждый из выходов
   logic [9:0]  A_inreg, B_inreg, C_inreg, D_inreg, E_inreg, F_inreg, G_inreg, H_inreg;
   //DAC регистры на каждом из выходов
   logic [9:0]  A_DACreg, B_DACreg, C_DACreg, D_DACreg, E_DACreg, F_DACreg, G_DACreg, H_DACreg;
   //—имул€ци€ Power-down ключей дл€ выполнени€ контрольной команды Power-down(все выключены).
   logic        A_key = 1'b1, B_key = 1'b1, C_key = 1'b1, D_key = 1'b1, E_key = 1'b1, F_key = 1'b1, G_key = 1'b1 , H_key = 1'b1;
   logic [5:0]  count = 1'd0;                 //переменна€ - счетчик
   logic [15:0] din_shift;                    // сдвиговый регистр на входе
   
   enum 
   logic [1:0] {Control_functions = 2'b00,
                LDAC_control      = 2'b01,
                Power_down        = 2'b10,
                Reset             = 2'b11} control_words;
   
   logic        VDD_bits_A_D, VDD_bits_E_H;   //биты симул€ции установки питани€
   logic        BUF_bits_A_D, BUF_bits_E_H;   //биты симул€ции референса DAC 
   logic        GAIN_bits_A_D, GAIN_bits_E_H; //биты симул€ции размаха напр€жени€(0 - Vref, 1 - 2Vref)        
   
   logic        LDAC_reg;                     //необходимые объ€влени€ дл€ LDAC
   logic        LDAC_single = 1'b0;
   logic        LDAC_flag   = 1'b1;
   
   ///////////////////////////
   //Description of the work//
   ///////////////////////////
   
   always_ff @(posedge SCLK or negedge SYNC_b) begin:main_alw
      if (!SYNC_b) begin:sync_if
         count <= count + 1'b1;
         din_shift <= { DIN , din_shift[15:1] };
         end:sync_if
         if (count > 17)
            $error("Over 16 bits!");
            
         if (count == 17) begin:cnt_16
             count <= 0;
             
         if (LDAC_flag) begin
             LDAC_reg <= LDAC_b;
             LDAC_flag <= 0;
         end
             
            if (din_shift[15]) begin:op_15
                case(din_shift[14:13])  
         
                     Control_functions: begin //команда выбора режимов референса
                                        
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
         
                          LDAC_control: begin //настройка работы сигнала LDAC_b
                                        
                                        if (din_shift[1:0] == 0) LDAC_reg <= 0;
                                        
                                        if (din_shift[1:0] == 1) LDAC_reg <= 1;
                                        
                                        if (din_shift[1:0] == 2) begin 
                                            LDAC_single <= 1;
                                            LDAC_reg <= 0;
                                            $display("Single trasaction ");
                                            end
                                        
                                        $display("LDAC new mode set");
                                        end
         
                            Power_down: begin //отключение питани€ выходам ÷јѕ(установка в 1 - выкл, 0 - вкл)
                                              
                                        if (din_shift[0]) A_key <= 1;
                                        else              A_key <= 0;
                                        
                                        if (din_shift[1]) B_key <= 1;
                                        else              B_key <= 0;
                                        
                                        if (din_shift[2]) C_key <= 1;
                                        else              C_key <= 0;
                                        
                                        if (din_shift[3]) D_key <= 1;
                                        else              D_key <= 0;
                                        
                                        if (din_shift[4]) E_key <= 1;
                                        else              E_key <= 0;
                                        
                                        if (din_shift[5]) F_key <= 1;
                                        else              F_key <= 0;
                                        
                                        if (din_shift[6]) G_key <= 1;
                                        else              G_key <= 0;
                                        
                                        if (din_shift[7]) H_key <= 1;
                                        else              H_key <= 0;
                                        
                                        $display("Power-down mode settings set");
                                        end
         
                                 Reset: begin //контрольна€ команда RESET
                                        if (!din_shift[13]) begin
                                               A_inreg <= 0;
                                               B_inreg <= 0;
                                               C_inreg <= 0;
                                               D_inreg <= 0;
                                               E_inreg <= 0;
                                               F_inreg <= 0;
                                               G_inreg <= 0;
                                               H_inreg <= 0;
                                               
                                               A_DACreg <= 0;
                                               B_DACreg <= 0;
                                               C_DACreg <= 0;
                                               D_DACreg <= 0;
                                               E_DACreg <= 0;
                                               F_DACreg <= 0;
                                               G_DACreg <= 0;
                                               H_DACreg <= 0;
                                               $display("Reset all DAC and inp. regs");
                                            end else begin
                                            
                                                A_inreg <= 0;
                                                B_inreg <= 0;
                                                C_inreg <= 0;
                                                D_inreg <= 0;
                                                E_inreg <= 0;
                                                F_inreg <= 0;
                                                G_inreg <= 0;
                                                H_inreg <= 0;
                                                
                                                A_DACreg <= 0;
                                                B_DACreg <= 0;
                                                C_DACreg <= 0;
                                                D_DACreg <= 0;
                                                E_DACreg <= 0;
                                                F_DACreg <= 0;
                                                G_DACreg <= 0;
                                                H_DACreg <= 0;
                                                
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
            end:op_15 else begin:chan_case
                           case (din_shift[14:12])
                        
                                 3'b000:  A_inreg <= din_shift[11:2];
             
                                 3'b001:  B_inreg <= din_shift[11:2];
                      
                                 3'b010:  C_inreg <= din_shift[11:2];
             
                                 3'b011:  D_inreg <= din_shift[11:2];
                              
                                 3'b100:  E_inreg <= din_shift[11:2];
                
                                 3'b101:  F_inreg <= din_shift[11:2];
                              
                                 3'b110:  G_inreg <= din_shift[11:2];
             
                                 3'b111:  H_inreg <= din_shift[11:2];
                              
                          endcase 
                       end:chan_case              
         end:cnt_16
         if (!LDAC_reg) begin:ldac 
         
            A_DACreg <= A_inreg;
            B_DACreg <= B_inreg;
            C_DACreg <= C_inreg;
            D_DACreg <= D_inreg;
            
            E_DACreg <= E_inreg;
            F_DACreg <= F_inreg;
            G_DACreg <= G_inreg;
            H_DACreg <= H_inreg;

         if (LDAC_single) begin //условие на единичную транзакцию
             LDAC_single <= 0;
             LDAC_reg <= 1;
         end
         end:ldac    
            

   end:main_alw   
   
   //¬зависимости от установки ключа - работает выход или нет      
   assign  VoutA = ~A_key   ? A_DACreg
                            : 10'hZZZ; 
                           
   assign  VoutB = ~B_key   ? B_DACreg
                            : 10'hZZZ;
                           
   assign  VoutC = ~C_key   ? C_DACreg
                            : 10'hZZZ; 
                                         
   assign  VoutD = ~D_key   ? D_DACreg
                            : 10'hZZZ;
                            
   assign  VoutE = ~E_key   ? E_DACreg
                            : 10'hZZZ;
                             
   assign  VoutF = ~F_key   ? F_DACreg
                            : 10'hZZZ;
                            
   assign  VoutG = ~G_key   ? G_DACreg
                            : 10'hZZZ;
                            
   assign  VoutH = ~H_key   ? H_DACreg
                            : 10'hZZZ;
                   
    
endmodule