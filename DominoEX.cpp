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
#include "WProgram.h"
#include "DominoEX.h"
#include <stdio.h>  //do we need this?
#include "DDS.h"

unsigned long tonestart=0; //time since the tonestarted.
int couldsendNibble; // this ==1 when ie a symble with a length of 1 nibble has been sent and we are trying to send the 2nd nibble

//These used to be passed externally (early in repo), tidier to do here
int arraypos=0;  //how far though the input string we are
int vericode_pos_l=0; //Which of the 3 values making up the character are we at

extern volatile unsigned long c4ms;  //kinda gross.  increments every 4ms while DDSTimers are on

//Define the primary alphabet only.
static unsigned char varicode[][3] = {
	/* Primary alphabet */
	{ 1,15, 9}, { 1,15,10}, { 1,15,11}, { 1,15,12}, { 1,15,13}, { 1,15,14}, { 1,15,15}, { 2, 8, 8},
	{ 2,12, 0}, { 2, 8, 9}, { 2, 8,10}, { 2, 8,11}, { 2, 8,12}, { 2,13, 0}, { 2, 8,13}, { 2, 8,14},
	{ 2, 8,15}, { 2, 9, 8}, { 2, 9, 9}, { 2, 9,10}, { 2, 9,11}, { 2, 9,12}, { 2, 9,13}, { 2, 9,14},
	{ 2, 9,15}, { 2,10, 8}, { 2,10, 9}, { 2,10,10}, { 2,10,11}, { 2,10,12}, { 2,10,13}, { 2,10,14},
	{ 0, 0, 0}, { 7,11, 0}, { 0, 8,14}, { 0,10,11}, { 0, 9,10}, { 0, 9, 9}, { 0, 8,15}, { 7,10, 0},
	{ 0, 8,12}, { 0, 8,11}, { 0, 9,13}, { 0, 8, 8}, { 2,11, 0}, { 7,14, 0}, { 7,13, 0}, { 0, 8, 9},
	{ 3,15, 0}, { 4,10, 0}, { 4,15, 0}, { 5, 9, 0}, { 6, 8, 0}, { 5,12, 0}, { 5,14, 0}, { 6,12, 0},
	{ 6,11, 0}, { 6,14, 0}, { 0, 8,10}, { 0, 8,13}, { 0,10, 8}, { 7,15, 0}, { 0, 9,15}, { 7,12, 0},
	{ 0, 9, 8}, { 3, 9, 0}, { 4,14, 0}, { 3,12, 0}, { 3,14, 0}, { 3, 8, 0}, { 4,12, 0}, { 5, 8, 0},
	{ 5,10, 0}, { 3,10, 0}, { 7, 8, 0}, { 6,10, 0}, { 4,11, 0}, { 4, 8, 0}, { 4,13, 0}, { 3,11, 0},
	{ 4, 9, 0}, { 6,15, 0}, { 3,13, 0}, { 2,15, 0}, { 2,14, 0}, { 5,11, 0}, { 6,13, 0}, { 5,13, 0},
	{ 5,15, 0}, { 6, 9, 0}, { 7, 9, 0}, { 0,10,14}, { 0,10, 9}, { 0,10,15}, { 0,10,10}, { 0, 9,12},
	{ 0, 9,11}, { 4, 0, 0}, { 1,11, 0}, { 0,12, 0}, { 0,11, 0}, { 1, 0, 0}, { 0,15, 0}, { 1, 9, 0},
	{ 0,10, 0}, { 5, 0, 0}, { 2,10, 0}, { 1,14, 0}, { 0, 9, 0}, { 0,14, 0}, { 6, 0, 0}, { 3, 0, 0}, 
	{ 1, 8, 0}, { 2, 8, 0}, { 7, 0, 0}, { 0, 8, 0}, { 2, 0, 0}, { 0,13, 0}, { 1,13, 0}, { 1,12, 0}, 
	{ 1,15, 0}, { 1,10, 0}, { 2, 9, 0}, { 0,10,12}, { 0, 9,14}, { 0,10,12}, { 0,11, 8}, { 2,10,15}, 
	{ 2,11, 8}, { 2,11, 9}, { 2,11,10}, { 2,11,11}, { 2,11,12}, { 2,11,13}, { 2,11,14}, { 2,11,15}, 
	{ 2,12, 8}, { 2,12, 9}, { 2,12,10}, { 2,12,11}, { 2,12,12}, { 2,12,13}, { 2,12,14}, { 2,12,15}, 
	{ 2,13, 8}, { 2,13, 9}, { 2,13,10}, { 2,13,11}, { 2,13,12}, { 2,13,13}, { 2,13,14}, { 2,13,15}, 
	{ 2,14, 8}, { 2,14, 9}, { 2,14,10}, { 2,14,11}, { 2,14,12}, { 2,14,13}, { 2,14,14}, { 2,14,15}, 
	{ 0,11, 9}, { 0,11,10}, { 0,11,11}, { 0,11,12}, { 0,11,13}, { 0,11,14}, { 0,11,15}, { 0,12, 8}, 
	{ 0,12, 9}, { 0,12,10}, { 0,12,11}, { 0,12,12}, { 0,12,13}, { 0,12,14}, { 0,12,15}, { 0,13, 8}, 
	{ 0,13, 9}, { 0,13,10}, { 0,13,11}, { 0,13,12}, { 0,13,13}, { 0,13,14}, { 0,13,15}, { 0,14, 8}, 
	{ 0,14, 9}, { 0,14,10}, { 0,14,11}, { 0,14,12}, { 0,14,13}, { 0,14,14}, { 0,14,15}, { 0,15, 8}, 
	{ 0,15, 9}, { 0,15,10}, { 0,15,11}, { 0,15,12}, { 0,15,13}, { 0,15,14}, { 0,15,15}, { 1, 8, 8}, 
	{ 1, 8, 9}, { 1, 8,10}, { 1, 8,11}, { 1, 8,12}, { 1, 8,13}, { 1, 8,14}, { 1, 8,15}, { 1, 9, 8}, 
	{ 1, 9, 9}, { 1, 9,10}, { 1, 9,11}, { 1, 9,12}, { 1, 9,13}, { 1, 9,14}, { 1, 9,15}, { 1,10, 8}, 
	{ 1,10, 9}, { 1,10,10}, { 1,10,11}, { 1,10,12}, { 1,10,13}, { 1,10,14}, { 1,10,15}, { 1,11, 8}, 
	{ 1,11, 9}, { 1,11,10}, { 1,11,11}, { 1,11,12}, { 1,11,13}, { 1,11,14}, { 1,11,15}, { 1,12, 8}, 
	{ 1,12, 9}, { 1,12,10}, { 1,12,11}, { 1,12,12}, { 1,12,13}, { 1,12,14}, { 1,12,15}, { 1,13, 8}, 
	{ 1,13, 9}, { 1,13,10}, { 1,13,11}, { 1,13,12}, { 1,13,13}, { 1,13,14}, { 1,13,15}, { 1,14, 8}, 
	{ 1,14, 9}, { 1,14,10}, { 1,14,11}, { 1,14,12}, { 1,14,13}, { 1,14,14}, { 1,14,15}, { 1,15, 8},

	
};



unsigned char *dominoex_varienc(unsigned char c)
{
	unsigned char *bob=varicode[c];//+ ((secondary) ? 256 : 0)];
	//return varicode[c + ((secondary) ? 256 : 0)];
	//Serial.println(bob[1],DEC);
	return bob;
}

void dominoex::init_radio_params(int mode, double txfreq_woffsetin)
{
	txfreq_woffset=txfreq_woffsetin;

	

	switch (mode) {
// 11.025 kHz modes
	case 5:
		symlen = 2048;
		doublespaced = 2;
		samplerate = 11025;
		tone_ms = 186; //roughly 186 ms tones
		break;

	case 11:
		symlen = 1024;
		doublespaced = 1;
		samplerate = 11025;
		tone_ms =  93; //roughly
		break;

	case 22:
		symlen = 512;
		doublespaced = 1;
		samplerate = 11025;
		tone_ms = 46; //roughly
		break;
// 8kHz modes
	case 4:
		symlen = 2048;
		doublespaced = 2;
		samplerate = 8000;
		tone_ms = 256; //exactly
		break;
	case 8:
		symlen = 1024;
		doublespaced = 2;
		samplerate = 8000;
		tone_ms = 128; //exactly
		break;
	case 16:
		symlen = 512;
		doublespaced = 1;
		samplerate = 8000;
		tone_ms = 64; //exactly 64ms?
		break;
	default: // EX8
		symlen = 1024;
		doublespaced = 2;
		samplerate = 8000;
		tone_ms = 128; //exactly
	}

	tonespacing = 1.0 * samplerate * doublespaced / symlen;
	
	
	bandwidth = NUMTONES * tonespacing;
    txstate=TX_STATE_PREAMBLE;   
        
        txprevtone = 0;
        txstate=TX_STATE_PREAMBLE;  //for safety I think this is best done in the main code

	
}

dominoex::dominoex(int mode, double txfreq_woffsetin)
{
	init_radio_params(mode, txfreq_woffsetin); //moved from main initialisation function to allow reseting of radio paramaters
	
}
void dominoex::sendtone(int tone, int duration)
{
	double phaseincr;
	f = (tone + 0.5) * tonespacing +txfreq_woffset- bandwidth / 2.0; //###modified to remove get_txfreq_woffset()
	phaseincr = TWOPI * f / samplerate;
	
        //We are assuming the the DDS algorith can handle phase continity.
        /*
        for (int j = 0; j < duration; j++) {
		for (int i = 0; i < symlen; i++) {
			outbuf[i] = cos(txphase);
			txphase -= phaseincr;
			if (txphase > M_PI)
				txphase -= TWOPI;
			else if (txphase < M_PI)
				txphase += TWOPI;
		}
		ModulateXmtr(outbuf, symlen);
	} */
}

void dominoex::sendsymbol(int sym)
{
    //static int first = 0;
	//complex z;
	int tone;

	tone = (txprevtone + 2 + sym) % NUMTONES;
	txprevtone = tone;
	if (reverse)
		tone = (NUMTONES - 1) - tone;
	sendtone(tone, 1);
}

int dominoex::sendchar(unsigned char char_to_send, int vericode_tuple_pos) 
{
    //tuple pos must be 0,1 or 2 or bad things will happen
	
	unsigned char *code = dominoex_varienc(char_to_send);
	int symbol_to_send = code[vericode_tuple_pos];
	
	if (vericode_tuple_pos == 0 || symbol_to_send != 0) // don't waste time sending a 0, other than in the first position in the varicode tuple
	{
		//~ if (symbol_to_send==0){
			//~ symbol_to_send=1;
			//~ }
			//Serial.println(symbol_to_send,DEC);
		sendsymbol(symbol_to_send);
		return 1;
	}
	
	return 0;
	
	//char buff[5];
	//sprintf(buff, "%c", c);	
	//sendsymbol(atoi(buff));	
	
	
	//sendsymbol(9);

		//sendsymbol(7);
//		sendsymbol(code[0]);
// Continuation nibbles all have the MSB set
//		for (int sym = 1; sym < 3; sym++) {
			//Serial.println(code[sym],DEC);
//~ 

	
	//sendsymbol(char());
			//~ if (code[sym] != 0){
				//~ Serial.println("The Begining");
				//~ Serial.println(code[sym],DEC);
				//~ Serial.println("****");
				//~ sendsymbol(code[sym]);
				//~ 
			//~ }
			//~ else{
				//~ Serial.println("The End!!");
				//~ Serial.println(code[sym],DEC);
				//~ Serial.println("****");
				//~ break;
			 //~ }
			
			//~ 
			//~ if (code[sym] & 0x8){
				//~ Serial.println(code[sym],DEC);
				//~ sendsymbol(code[sym]);
				//~ 
			//~ }
			//~ else{
				//~ Serial.println("The End!!");
				//~ Serial.println(code[sym],DEC);
				//~ Serial.println("****");
				//~ break;
			//~ }
//		}
	
	//if (!secondary)
		//put_echo_char(c); //###Not sure what this is for!!
}

void dominoex::sendidle()
{
	sendchar(0, 1);	// <NUL>
}

//void dominoex::sendsecondary() //###redundant as the code for this probably doesn't work properly!!
//{
//	int c = get_secondary_char();
//	sendchar(c & 0xFF, 1);
//}

void dominoex::flushtx()
{
// flush the varicode decoder at the receiver end
		for (int i = 0; i < 4; i++)
			sendidle();
}

int dominoex::tx_process(int char_to_send, int vericode_tuple_pos)
{
	//;

	switch (txstate) {
	case TX_STATE_PREAMBLE:
		sendidle();
		txstate = TX_STATE_START;
		break;
	case TX_STATE_START:
		sendchar('\r', 0);
		sendchar(2, 0);		// STX
		sendchar('\r', 0);
		txstate = TX_STATE_DATA;
		break;
	case TX_STATE_DATA:
		//!!!i = get_tx_char();
		//if (i == -1)
			//sendsecondary();
		if (char_to_send == 3)
			txstate = TX_STATE_END;
		else
             return sendchar(char_to_send, vericode_tuple_pos);               
		if (stopflag)
			txstate = TX_STATE_END;
		break;
	case TX_STATE_END:
		sendchar('\r', 0);
		sendchar(4, 0);		// EOT
		sendchar('\r', 0);
		txstate = TX_STATE_FLUSH;
		break;
	case TX_STATE_FLUSH:
		flushtx();
		//cwid();  //### Don't know what this is for, rpesumably a flag for fldigi?
		return -1;
	}
	return 0;
}

/*
    Function to send a nibble of a character from a string
    
    Returns true if a string has been completely sent, otherwise returns false
    Must be run untill returns true.
    Also increments output string array position (arraypos) and vericode nibbble position if successfull
*/



bool dominoex::sendNibble(DDS& inDDS, char *pmessageString) //this should later be moved into the main DominoEX Class
{
  boolean string_transmitted=0;
  //check if end of message has been meet.  Basically are we in a position to run the comms again.

    if (pmessageString[arraypos]=='\0') // start again if at the end of the string
    {
        //Serial.println("end of String!");
        string_transmitted = 1;
        arraypos=0;
    }
    
    //Serial.print("tone start");
    //Serial.println(tonestart,DEC);  
    if(c4ms-tonestart >= tone_ms) // if tone_ms (tone length in ms) has passed since tone start
    {
      //Serial.print(inDDS.c4ms-tonestart);
      tonestart=c4ms; // mark the time that a new tone started
       
      
       // Serial.print(arraypos);
       // Serial.println(pmessageString[arraypos]);
       couldsendNibble=tx_process(pmessageString[arraypos],vericode_pos_l);
        //Serial.print(' ');     
  
       //now set the frequencies for the dds algoritm
       
       //Serial.println(inobj.f,DEC);
       inDDS.SetFreq(f); //get the frequncy from the DominoEX object
    
       vericode_pos_l += 1;
//            char buff[100];
//            sprintf(buff,"vericode_pos_l: %i", *vericode_pos_l);
//            Serial.println(buff);
       


       
       if (couldsendNibble==0){
         //reset counters and increment outputstring array position
         vericode_pos_l = 0;
         arraypos += 1;
         //We don't want to wait this time as we couldn't send this nibble as it doesn't exist
         //so force a chnage to the "end" of a tone.  This is untidy and should be fixed at somepoint.
         tonestart=c4ms+tone_ms;
         
         
       }
       else if (vericode_pos_l >= VERICODE_MAX_CHAR_LENGTH )// || couldsendNibble==0     
       {
         vericode_pos_l = 0;
         arraypos += 1;
       }
     }

    
  return string_transmitted;
}

