# DAC

## О самом модуле

Данный модуль написан для ЦАП'а AD5318.

![dac_ad5318](https://github.com/0TulipRose0/DAC/blob/main/Pics%20and%20datasheat/DAC%20ad53xx.png)

Его задача состоит в управлении данным ЦАП'ом и выдаче ему необходимой информации.

```verilog
module ad5318#(
    parameter DIVIDER = 4'd4,   //Делитель работает только с чётными числами!!
                                //Делит на числа от 2 до 14 включительно
    parameter LDAC_VALUE = 1'b1 //параметр, отвечающий на обновление DAC регистров
                                //(Рекомендуется держать в верхнем положении,
                                //чтоб регистры на входе не влияли на DAC регистры при запуске
    )(
    input  logic        clkin,  //тактовый сигнал
    input  logic        rstn,   //сигнал сброса
    
    
    
    //сигналы в цап
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
```
### Про тактирование

Тактовая частота генерируется посредством делителя частоты *на ргистрах*, поскольку таковы технические ограничения, заданные при поставновке задачи.

Соответсвенно, она является параметризованной, но делит **только на чётные числа**, о чём сказано в самом модуле.
### О пересылке данных

Кроме тактирования, модуль также реализует пересылку данных к устройству.
Он записывает их в сдвиговый регистр и каждый так передаёт по битику на сдвиговый регистр, который стоит на входе в самом цапе, как сказано в даташите.

Существует всего 2 шаблона, которые передаёт модуль:
+ *Контрольное слово(команду)*
+ *Данные на один из выходов ЦАП'а*

*Команды* делятся на 4 типа:
+ Выбор референса на выход усилителя
+ Установка сигнала LDAC
+ Отключение/включение каналов
+ Сигнала сброса 

Каждая из них имеет собственный опкод, который подробно описан в даташите *(стр 17.)*

## О цифро аналоговом преобразователе

Сам модуль цапа я постарался снабдить всем необходимым, но он также требует доработок.
Наша версия ЦАП'а способно выставлять 10битные значения на выходы, поэтому стоит иметь в виду, что при передаче значения более, чем 10 бит, он их просто обрежет.
Данный момент обыгран в модуле следующим образом:
```verilog
if (tdata[15]) din_shift <= tdata;
else din_shift <= { 1'b0 , tuser[2:0] , tdata[9:0], 2'b00};
```

Он смотрит: если 1-ый бит будет единичкой, это значит, что передаётся *команда*, поэтому её мы передаем полностью. Если с 0, то это информация в канал, поэтому он берёт только валидные нам 10 бит и записывает их в сдвиговый регистр.

### Что в нём реализовано

Данный модуль способен симулировать цап в полном объёме.
Каждая команда реализвана, каждый канал имеет свой ключ и свой регистр, в котором хранится значение. Свой LDAC и регистр на входе прилагается.

Однако, данный модуль требует серьёзной оптимизации в плане его написания.

## TO DO LIST

- [X] Оптимизировать код(добавить массивы, переделать некотрые сигналы)
- [ ] Подключить интерфейсы
- [ ] Сделать верификационое тестовое окружение на проверку выполнения команд и правильных значений на выходах цап'а
- [X] Сделать каналы структурой 
