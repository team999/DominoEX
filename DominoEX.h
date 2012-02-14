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

//check if library has already been included
#ifndef DominoEX_h
#define DominoEX_h

#include "DDS.h"

#define NUMTONES 18
#define TWOPI 6.28318530717959
#define TX_STATE_PREAMBLE 1
#define TX_STATE_START 2
#define TX_STATE_DATA 3
#define TX_STATE_END 4
#define TX_STATE_FLUSH 5
#define VERICODE_MAX_CHAR_LENGTH 3 //the vericode contains at most 3 tones per character


class dominoex
{
  public:
    dominoex(int mode, double txfreq_woffset);
    void init_radio_params(int mode, double txfreq_woffset);
    void sendtone(int tone, int duration);
    void sendsymbol(int sym);
    int sendchar(unsigned char c, int secondary);
    void sendidle();
    //void sendsecondary();
    void flushtx();
    int tx_process(int char_to_send, int vericode_tuple_pos);
    bool sendNibble(DDS& inDDS, char *pmessageString); //send a nibble, must be run until it returns true
    int txstate;
    double f;  //the current output frequency
    bool stopflag;
    double txfreq_woffset;
    int symlen;
    int doublespaced;
    int samplerate;
    double tonespacing;
    double bandwidth;
    int tone_ms; //each tone length in ms
	int couldsendNibble; // this ==1 when ie a symble with a length of 1 nibble has been sent and we are trying to send the 2nd nibble
	unsigned long tonestart; //time since the tonestarted.
  private:

    bool reverse;  //hmm not sure how this is determined
    int txprevtone;
    
};




#endif
