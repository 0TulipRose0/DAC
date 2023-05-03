module ad5318#(
    parameter DIVIDER = 4'd4,   //Делитель  работает только с четными числами!!
                                //Способен обработать деление на числа от 2 до 14 включительно
    parameter LDAC_VALUE = 1'b1 //параметр, отвечающий за значение обновления регистров DAC
                                //(Рекомендуется держать в высоком состоянии, 
                                //чтоб регистры входа не влияли на DAC-регистры при запуске)
    )(
    input  logic        clkin,  //тактирование
    input  logic        rstn,   //сигнал reset
    
    //сигналы в ЦАП
    output logic        SCLK,
    output logic        DIN,
    output logic        SYNC_b,
    output logic        LDAC_b,
    
    //сигналы модуля
    input  logic [15:0] tdata,
    input  logic        tvalid,
    input  logic [2:0]  tuser,
    output logic        tready
    
    );
    
    ////////////////////////
    //Локальные объявления//
    ////////////////////////
    logic [3:0]   div_reg = 0;
    
    logic [15:0]  din_shift;
    
    enum 
    logic        {waiting = 1'b0,
                  busy    = 1'b1} states;      
    logic         state;
    logic [5:0]   count_module;
    
    //////////////////
    //Главный модуль//
    //////////////////
    
    //Реалиация делителя частоты на регистрах
    always_ff @(posedge clkin)
    if (~rstn) begin
        SCLK <= 0;  
        state <= waiting;
        tready <= 1;
        SYNC_b <= 1;
        count_module <= 0;
    end else begin
            div_reg <= div_reg + 1;
            if (div_reg == DIVIDER/2-1) 
                begin
                SCLK <= ~SCLK;
                div_reg <= 0;
                end 
    end  
   

    assign LDAC_b = LDAC_VALUE; //установка значения LDAC сигнала


    always_ff @(posedge SCLK) //автомат конечных состояний 
//       if (~rstn) begin
                
//       end else
           case (state)
                waiting : begin
                          if (tvalid) begin
                             tready <= 0; 
                             state <= busy;   
                                 
                              if (tdata[15]) din_shift <= tdata;
                              else din_shift <= { 1'b0 , tuser[2:0] , tdata[9:0], 2'b00};  
                                                  
                              end

                           end
                   busy : begin
                          DIN <= din_shift[0]; 
                          SYNC_b <= 0;
                          din_shift <= { 1'b0 , din_shift[15:1] };
                          count_module <= count_module + 1;
                           
                             if (count_module == 16) begin
                                 state <= waiting;
                                 count_module <= 0;
                                 tready <= 1;
                                 SYNC_b <= 1;
                             end
                                                    
                          end
          endcase

endmodule
