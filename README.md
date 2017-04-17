Image , you are an integrated circuit designer, at university lab. You took 5 month to design a integrated chip and just get back from fabrication. you are excited to test it. etc  see  whether it will power up and how much power it will consume at certain states.

In order to test it and you need the following configure the chip into certain state.

 - A positive/negative bias voltage to bias the transistor. 
 - A precision bias current for your current mirror.
 - Digital host to load the chip register.
 - Adjustable Voltage supply to power the chip.
 - E load to set current consumptions.

Instead of spending a large amount of time designing all the biasing circuit your self 
or worse, you use a lab equipments such as Aglient power supply,  Total phase digital host, E-load which cost thousands of dollars.

Our Analog IC Equation Platform offers an solution for rapid IC Evaluation.


<img src="https://raw.githubusercontent.com/eddyzhangGit/analog-IC-EVA-board/master/image/2017_ECE496_Poster_final.001.jpeg" 
<img src="https://raw.githubusercontent.com/eddyzhangGit/analog-IC-EVA-board/master/image/2017_ECE496_Poster_final.002.jpeg" 

The board is equipped with 

- 4 x 50 mA and 2 x200 mA power supply 0.5V to 3V with current Sensing ability
- 4 x Positive Bias Voltage 0 -3 V with error less than 0.5mV
- 2 x Negative Bias Voltage -2.5 - 0 V with error less than 1mV
- 4 x Bias current 0 - 1000uA with error less than 0.5%
- 2 Programmable resistor, 2.5K and 10K, 256 taps each
- Digital that allows GPIO and SPI communication.

The board is designed with a accuracy much higher than traditional lab Requirement,  to meet the requirement of IC testing

A MAC OS app is developed to allow user to  configure the board with ease.
Lastly, python functions are available to allow user to write their own scripts for automated testing. 
(Detailed Examples are provided in the USER MANUEL)
 
if you found this board will be beneficial to your project, Feel free to contact me for more information.

Eddy Zhen Zhang
Eddy.zhang@mail.utoronto.ca




￼
