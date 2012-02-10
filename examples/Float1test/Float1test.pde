/*
 * Microprize DominoEX implimentation       
 *    
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author: 
 *  Andre Geldenhuis <andre@team9.99.org.nz>  
 
 * DDS components based on:
 * DDS Sine Generator mit ATMEGS 168
 * Timer2 generates the  31250 KHz Clock Interrupt
 *
 * KHM 2009 /  Martin Nawrath
 * Kunsthochschule fuer Medien Koeln
 * Academy of Media Arts Cologne
 
 */


#include "avr/pgmspace.h"
#include <DominoEX.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <MemoryFree.h>
#include <TinyGPS.h>

#define DOMINO4 0
#define DOMINO16 1
#define DEFAULT_DOMINO 0
#define FLOATNIC_NUM 1

// table of 256 sine values / one sine period / stored in flash memory
PROGMEM  prog_uchar sine256[]  = {
  127,130,133,136,139,143,146,149,152,155,158,161,164,167,170,173,176,178,181,184,187,190,192,195,198,200,203,205,208,210,212,215,217,219,221,223,225,227,229,231,233,234,236,238,239,240,
  242,243,244,245,247,248,249,249,250,251,252,252,253,253,253,254,254,254,254,254,254,254,253,253,253,252,252,251,250,249,249,248,247,245,244,243,242,240,239,238,236,234,233,231,229,227,225,223,
  221,219,217,215,212,210,208,205,203,200,198,195,192,190,187,184,181,178,176,173,170,167,164,161,158,155,152,149,146,143,139,136,133,130,127,124,121,118,115,111,108,105,102,99,96,93,90,87,84,81,78,
  76,73,70,67,64,62,59,56,54,51,49,46,44,42,39,37,35,33,31,29,27,25,23,21,20,18,16,15,14,12,11,10,9,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,5,6,7,9,10,11,12,14,15,16,18,20,21,23,25,27,29,31,
  33,35,37,39,42,44,46,49,51,54,56,59,62,64,67,70,73,76,78,81,84,87,90,93,96,99,102,105,108,111,115,118,121,124

};

//setup dallas one wire
#define ONE_WIRE_BUS 2
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

float outsideT; //outside temperaure as measured by dallas sensor
double messageNum=0; //indicator of messages sent.

//set up a fast and slow dominoEX mode.
//dominoex myD4(8,4,1500);
dominoex myDomino(8,16,1000);

//start and stop timers for DDS alorithm
#define disableT(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define enableT(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))


char serial_buffer[20];
char messagebuffer[300];
//char outsideTS[20]; //the outside temp string
//char latS[20];
//char lonS[20];
//char ageS[10];
//char altS[20];


char messageNumS[11]; //message number string buffer
char buffer[20]; //a tempbuffer

//some vars for dominoEX
int dominoType = DEFAULT_DOMINO;
int stringpos=0; //position along the char array.
int vericode_pos=0;
unsigned long tonestart=0; //time since the tonestarted.
int couldsendNibble; // this ==1 when ie a symble with a length of 1 nibble has been sent and we are trying to send the 2nd nibble

int ledPin = 13;                 // LED pin 7

boolean stringTxfinished; //indicates to the main loop the string has been compleatly sent.

double dfreq;
// const double refclk=31372.549;  // =16MHz / 510
const double refclk=31376.6;      // measured

// variables used inside interrupt service declared as voilatile
volatile byte icnt;              // var inside interrupt
volatile byte icnt1;             // var inside interrupt
volatile unsigned long c4ms;              // counter incremented all 4ms
volatile unsigned long phaccu;   // pahse accumulator
volatile unsigned long tword_m;  // dds tuning word m


TinyGPS gps;

void gpsdump(TinyGPS &gps);
bool feedgps();
void printFloat(double f, int digits = 2);



void setup()
{
  pinMode(ledPin, OUTPUT);      // sets the digital pin as output


  pinMode(6, OUTPUT);      // sets the digital pin as output
  pinMode(7, OUTPUT);      // sets the digital pin as output
  pinMode(11, OUTPUT);     // pin11= PWM  output / frequency output

  Setup_timer2();


  dfreq=1000.0;                    // initial output frequency = 1000.o Hz
  tword_m=pow(2,32)*dfreq/refclk;  // calulate DDS new tuning word 

  
  //sensors.begin();
    Serial.begin(9600);
	stringTxfinished=1; //to make sure the code runs through the string creating process once
	SetDDSTimers(1);
}
void loop()
{

   stringTxfinished=sendNibble(myDomino,messagebuffer,&stringpos,&vericode_pos);

   if (stringTxfinished==1){ //will shutdown the transmitter.  In future we could make this send idle instead?              
    
    
    SetDDSTimers(0); //switch off dds timers.  and renables timers that do millis() etc.
    sensors.begin(); //startup dallas one wire
    
    switch (dominoType)
    {
        case DOMINO16:
          dominoType = DOMINO4;
          myDomino.init_radio_params(8,4,1000);
          break;
        case DOMINO4:
          dominoType = DOMINO16;
          myDomino.init_radio_params(8,16,1000);
          break;
        default:
           dominoType = DEFAULT_DOMINO;
           break;
    }

    messageNum++; //incrememnt message counter

    dtostrf(messageNum, 0, 0, buffer);
    sprintf(messagebuffer,"*****\n\nMsgNo:%s, ",buffer); //the 0.0f means no trailing spaces and as short as possible.
    if (dominoType == DOMINO4)
       strcat(messagebuffer, "Mode:D4, ");
    if (dominoType == DOMINO16)
       strcat(messagebuffer, "Mode:D16, ");
    sprintf(serial_buffer, "Num Devices: %i\n",sensors.getDeviceCount());
   Serial.println(serial_buffer); 
    if (sensors.getDeviceCount()>0)
    { //if there are temperature devices
      sensors.requestTemperatures();    //read temperature sensor.
      outsideT=sensors.getTempCByIndex(0);

      //convert outsideT to strings.
      dtostrf(outsideT,0,3,buffer);
      sprintf(messagebuffer, "%sFloatnik%i,%s,C",messagebuffer,FLOATNIC_NUM,buffer);
      
      
      



    }
    else{
      

     
      sprintf(messagebuffer,"%sFloatnik1,%i,NaN,C", messagebuffer, FLOATNIC_NUM);
   
    }
    ///Now check gps data.
    gpsdump(gps);
         
    // itoa(freeMemory(), buffer, 10);
    //strcat(messagebuffer, "mem=");
     //strcat(messagebuffer, buffer);
    
    
    
    
    
    strcat(messagebuffer, "##\n\n\n");
    Serial.println(messagebuffer);

    
    stringTxfinished==0; //reset the string Txed complete flag.
    SetDDSTimers(1); //restart the DDS ISR timers.  This shuts down other useful timers.
  }

  //sbi(PORTD,6); // Test / set PORTD,7 high to observe timing with a scope
  //cbi(PORTD,6); // Test /reset PORTD,7 high to observe timing with a scope
}
//******************************************************************




void SetDDSTimers(byte enableCom){
  if(enableCom==1){
    disableT (TIMSK0,TOIE0);   // disable Timer0 !!! delay() is now not available
    enableT (TIMSK2,TOIE2);   // enable Timer2 Interrupt 
  }
  else{
    disableT(TIMSK2,TOIE2); //disable Timer2 Interupt, stops DDS.
    enableT (TIMSK0,TOIE0); //renable Timer0, delay now worls again
  }
}


/*
    Function to send a nibble of a character from a string
 
 Returns true if a string has been completely sent, otherwise returns false
 Must be run untill returns true.
 Also increments output string array position (arraypos) and vericode nibbble position if successfull
 */

boolean sendNibble(dominoex& inobj, char *pmessageString,int *arraypos, int *vericode_pos_l) //this should later be moved into the main DominoEX Class
{
  boolean string_transmitted=0;
  //check if end of message has been meet.  Basically are we in a position to run the comms again.

  if (pmessageString[*arraypos]=='\0') // start again if at the end of the string
  {
    //Serial.println("end of String!");
    string_transmitted = 1;
    *arraypos=0;
  }


  if(c4ms-tonestart >= inobj.tone_ms) // if tone_ms (tone length in ms) has passed since tone start
  {
    //Serial.print(c4ms-tonestart);
    tonestart=c4ms; // mark the time that a new tone started


    //Serial.print(*arraypos);
    //Serial.println(pmessageString[*arraypos]);
    couldsendNibble=inobj.tx_process(pmessageString[*arraypos],*vericode_pos_l);
    //Serial.print(' ');     

    //now set the frequencies for the dds algoritm

    //Serial.println(inobj.f,DEC);
    dfreq=inobj.f; //get the frequncy from the DominoEX object
    tword_m=pow(2,32)*dfreq/refclk;  // calulate DDS new tuning word

    *vericode_pos_l += 1;
    //            char buff[100];
    //            sprintf(buff,"vericode_pos_l: %i", *vericode_pos_l);
    //            Serial.println(buff);




    if (couldsendNibble==0){
      //reset counters and increment outputstring array position
      *vericode_pos_l = 0;
      *arraypos += 1;
      //We don't want to wait this time as we couldn't send this nibble as it doesn't exist
      //so force a chnage to the "end" of a tone.  This is untidy and should be fixed at somepoint.
      tonestart=c4ms+inobj.tone_ms;


    }
    else if (*vericode_pos_l >= VERICODE_MAX_CHAR_LENGTH )// || couldsendNibble==0     
    {
      *vericode_pos_l = 0;
      *arraypos += 1;
    }
  }


  return string_transmitted;
}





// timer2 setup
// set prscaler to 1, PWM mode to phase correct PWM,  16000000/510 = 31372.55 Hz clock
void Setup_timer2() {

  // Timer2 Clock Prescaler to : 1
  enableT (TCCR2B, CS20);
  disableT (TCCR2B, CS21);
  disableT (TCCR2B, CS22);

  // Timer2 PWM Mode set to Phase Correct PWM
  disableT (TCCR2A, COM2A0);  // clear Compare Match
  enableT (TCCR2A, COM2A1);

  enableT (TCCR2A, WGM20);  // Mode 1  / Phase Correct PWM
  disableT (TCCR2A, WGM21);
  disableT (TCCR2B, WGM22);
}



void printFloat(double number, int digits)
{
  // Handle negative numbers
  if (number < 0.0)
  {
     Serial.print('-');
     number = -number;
  }

  // Round correctly so that print(1.999, 2) prints as "2.00"
  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  Serial.print(int_part);

  // Print the decimal point, but only if there are digits beyond
  if (digits > 0)
    Serial.print("."); 

  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    remainder *= 10.0;
    int toPrint = int(remainder);
    Serial.print(toPrint);
    remainder -= toPrint; 
  } 
}

void gpsdump(TinyGPS &gps)
{
  //long lat, lon;
  float flat, flon;
  unsigned long age, date, time, chars;
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned short sentences, failed;

//  gps.get_position(&lat, &lon, &age);
//  Serial.print("Lat/Long(10^-5 deg): "); Serial.print(lat); Serial.print(", "); Serial.print(lon); 
//  Serial.print(" Fix age: "); Serial.print(age); Serial.println("ms.");
  
  feedgps(); // If we don't feed the gps during this long routine, we may drop characters and get checksum errors

  gps.f_get_position(&flat, &flon, &age);
  dtostrf(flat,0,6,buffer);
  sprintf(messagebuffer,"%s,%s", messagebuffer,buffer);
  dtostrf(flon,0,6,buffer);
  sprintf(messagebuffer,"%s,%s", messagebuffer,buffer);

  
  feedgps();
  
  //Serial.print("Alt(cm): "); Serial.print(gps.altitude()); Serial.print(" Course(10^-2 deg): "); Serial.print(gps.course()); Serial.print(" Speed(10^-2 knots): "); Serial.println(gps.speed());
  dtostrf(gps.f_altitude(),0,0,buffer);
  sprintf(messagebuffer,"%s,%s,m", messagebuffer,buffer);
  dtostrf(gps.f_speed_kmph(),0,0,buffer);
  sprintf(messagebuffer,"%s,%s,kph", messagebuffer,buffer);
  
  feedgps();

  //gps.get_datetime(&date, &time, &age);
  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);
  //dtostrf(time,0,0,buffer);
  sprintf(messagebuffer,"%s,%i:%i", messagebuffer,static_cast<int>(hour),(static_cast<int>(minute)));
  dtostrf(age,0,0,buffer);
  sprintf(messagebuffer,"%s,%s", messagebuffer,buffer);
  

//  feedgps();
//
//  gps.stats(&chars, &sentences, &failed);
//  Serial.print("Stats: characters: "); Serial.print(chars); Serial.print(" sentences: "); Serial.print(sentences); Serial.print(" failed checksum: "); Serial.println(failed);
}
  
bool feedgps()
{
  while (Serial.available() ) //while there are chars in the serial buffer.
  {
    if (gps.encode(Serial.read()))
      return true;
  }
  return false;
}











//******************************************************************
// Timer2 Interrupt Service at 31372,550 KHz = 32uSec
// this is the timebase REFCLOCK for the DDS generator
// FOUT = (M (REFCLK)) / (2 exp 32)
// runtime : 8 microseconds ( inclusive push and pop)
ISR(TIMER2_OVF_vect) {

  //sbi(PORTD,7);          // Test / set PORTD,7 high to observe timing with a oscope

  phaccu=phaccu+tword_m; // soft DDS, phase accu with 32 bits
  icnt=phaccu >> 24;     // use upper 8 bits for phase accu as frequency information
  // read value fron ROM sine table and send to PWM DAC
  OCR2A=pgm_read_byte_near(sine256 + icnt);    

  if(icnt1++ >= 125) {  // increment variable c4ms all 4 milliseconds
    c4ms+=4;
    icnt1=0;
  }  

  //cbi(PORTD,7);            // reset PORTD,7
}
 





