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

// Note that this is a limited implementation of the DominoEX spec, it
// currently has no support for the secondary alphabet, as such it is good
// practise to continually transmit as this will help the receiver
// maintain sync

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

dominoex myD16(16,1000);
DDS myDDS(1500);

//some vars for dominoEX
int stringpos=0; //position along the char array.
int vericode_pos=0;

int ledPin = 13;                
int testPin = 7;
int t2Pin = 6;
byte bb;

boolean stringTxfinished; //indicates to the main loop that a character has been transmitted

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
  //Send Nibble needs to be called a fair bit faster than the tone transition time
  //for the dominoEX object.  However, dominoEX tone transitions are slow
  //in microprocessor land so feel free to do stuff in between callling sendNibble
  //as long as sendNibble is still called fast enough.
  stringTxfinished=myD16.sendNibble(myDDS,"test! yes this is a test! ",&stringpos,&vericode_pos);
  if (stringTxfinished==1){
		//could do some stuff
    }
  //could also do some stuff
 }
//******************************************************************
