// ----------------------------------------------------------------------------
// Team 9.99 DominoEX implementation 
// dominoex.cpp  --  DominoEX modem
//
// Copyright (C) 2011-2012
//		Andre Geldenhuis (andre.geldenhuis@gmail.com)
//
// Copyright (C) 2008-2009
//		David Freese (w1hkj@w1hkj.com)
// Copyright (C) 2006
//		Hamish Moffatt (hamish@debian.org)
//
// based on code in fldigi which is in turned based on code in gmfsk
//
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with This program.  If not, see <http://www.gnu.org/licenses/>.

//Note that this is a limited implementation of the DominoEX spec, it 
//currently has no support for the secondary alphabet, as such it is good 
//practise to continually transmit as this will help the receiver
//maintain sync 
 
// DDS components based on:
// DDS Sine Generator mit ATMEGS 168
// Timer2 generates the  31250 KHz Clock Interrupt
//
// KHM 2009 /  Martin Nawrath
// Kunsthochschule fuer Medien Koeln
// Academy of Media Arts Cologne


#include "avr/pgmspace.h"
#include <DominoEX.h>
#include <DDS.h>

dominoex myD16(8,16,1000);
DDS myDDS(1500);

//some vars for dominoEX
int stringpos=0; //position along the char array.
int vericode_pos=0;
unsigned long tonestart=0; //time since the tonestarted.
int couldsendNibble; // this ==1 when ie a symble with a length of 1 nibble has been sent and we are trying to send the 2nd nibble


int ledPin = 13;                 // LED pin 7
int testPin = 7;
int t2Pin = 6;
byte bb;

boolean chartrans; //indicates to the main loop that a character has been transmitted

void setup()
{
  pinMode(ledPin, OUTPUT);      // sets the digital pin as output
  Serial.begin(115200);        // connect to the serial port
  Serial.println("DDS Test");

  pinMode(6, OUTPUT);      // sets the digital pin as output
  pinMode(7, OUTPUT);      // sets the digital pin as output
  pinMode(11, OUTPUT);     // pin11= PWM  output / frequency output

  

}
void loop()
{

  chartrans=sendNibble(myD16,"test! yes this is a test! ",&stringpos,&vericode_pos);
//    char buff[100];
//    sprintf(buff,"d8: %i", myD8.changeme);
//    Serial.println(buff);
  if (chartrans==1){                //if this is a tone transition
      //cbi (TIMSK2,TOIE2);              // disble Timer2 Interrupt
      //Serial.println(c8us/1000-tonestart);
      //dfreq=myD16.f; //get the frequncy from the DominoEX object
      //tword_m=pow(2,32)*dfreq/refclk;  // calulate DDS new tuning word
      //Serial.print(dfreq);
      //Serial.print("  ");
      //Serial.println(tword_m);
      
      //sbi (TIMSK2,TOIE2);              // enable Timer2 Interrupt 
    }
   
   //sbi(PORTD,6); // Test / set PORTD,7 high to observe timing with a scope
   //cbi(PORTD,6); // Test /reset PORTD,7 high to observe timing with a scope
 }
//******************************************************************

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
    
      
    if(myDDS.c4ms-tonestart >= inobj.tone_ms) // if tone_ms (tone length in ms) has passed since tone start
    {
      //Serial.print(c4ms-tonestart);
      tonestart=myDDS.c4ms; // mark the time that a new tone started
       
      
        //Serial.print(*arraypos);
        //Serial.println(pmessageString[*arraypos]);
       couldsendNibble=inobj.tx_process(pmessageString[*arraypos],*vericode_pos_l);
        //Serial.print(' ');     
  
       //now set the frequencies for the dds algoritm
       
       //Serial.println(inobj.f,DEC);
       myDDS.SetFreq(inobj.f); //get the frequncy from the DominoEX object
    
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
         tonestart=myDDS.c4ms+inobj.tone_ms;
         
         
       }
       else if (*vericode_pos_l >= VERICODE_MAX_CHAR_LENGTH )// || couldsendNibble==0     
       {
         *vericode_pos_l = 0;
         *arraypos += 1;
       }
     }

    
  return string_transmitted;
}
