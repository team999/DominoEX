/* This is a library which takes in a string and converts it into a varicode bit stream.  It is currently a bit limited but should be easy to extend.
*/

//check if library has already been included
#ifndef DominoEX_h
#define DominoEX_h
/*
 * Microprize DominoEX implimentation       
 *   
 *  Based on Fldigi's dominoEX implimentation
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
    dominoex(int trx_mode, int mode, double txfreq_woffset);
    void init_radio_params(int trx_mode, int mode, double txfreq_woffset);
    void sendtone(int tone, int duration);
    void sendsymbol(int sym);
    int sendchar(unsigned char c, int secondary);
    void sendidle();
    //void sendsecondary();
    void flushtx();
    int tx_process(int char_to_send, int vericode_tuple_pos);
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
    
  
  private:

    bool reverse;  //hmm not sure how this is determined
    int txprevtone;
    
};




#endif
