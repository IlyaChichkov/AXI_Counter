# Счетик с AXI Slave/Master

Блок счетчика с интерфейсом AXI-4, имеющий Master и Slave порты, написанный на SystemVerilog.

## Содержание

- [Описание](##описание)
- [Разработка](##разработка)
  - [Полезные ресурсы](##полезные_ресурсы)
- [Автор](##автор)

## Описание

Регистры:
- enable : r/w, запись в него 1 инициализирует burst на мастере (чтобы инициализировать заново нужно записать 0 потом 1)
- addr_w_0 : r/w, нижняя часть для мастера
- addr_w_1 : r/w, верхняя часть для мастера
- length : r/w, общее число байт в burst (awlen = length / awsize), (length % 64 == 0)
- incr : r/w, шаг счетчика
- status : r/o, [статус_произошла_ли_транзакция, bresp], при чтении обнуляется

## Разработка

### Стек

- SystemVerilog
- VS Code
- Xilinx Vivado 2021.2

### Полезные ресурсы

[Статья на Хабр про AXI4](https://habr.com/ru/articles/572926/)
[Спецификация AXI4](https://archive.alvb.in/bsc/TCC/correlatos/amba_axi4.pdf)

## Автор

[Github](https://github.com/IlyaChichkov)

[Email](mailto:ilya.chichkov.dev@gmail.com)
