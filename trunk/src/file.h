/*
 * Author	Thomas Husterer <thus1@t-online.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 */
#ifndef file_h
#define file_h


/// Filenames
#define FILE_GENERAL   0
#define FILE_MODEL(n) (1+n)

void EeFsFormat();
bool EeFsOpen();
uint16_t EeFsGetFree();

class EFile
{
  uint8_t m_fileId;
  uint16_t pos;
  uint8_t currBlk;
  uint8_t ofs;
  uint8_t bRlc;
  uint8_t read(uint8_t*buf,uint8_t i_len);  ///internal usage, for compressed data
  uint8_t write(uint8_t*buf,uint8_t i_len); ///internal usage, for compressed data
public:
  ///remove contents of given file
  static void rm(uint8_t i_fileId); 
  static void swap(uint8_t i_fileId1,uint8_t i_fileId2); 
  ///return size of compressed file without block overhead
  uint16_t size(); 
  ///open file for reading, no close necessary
  ///for writing use writeRlc
  uint8_t open(uint8_t i_fileId); 
  uint8_t readRlc(uint8_t*buf,uint8_t i_len);///read from opened file
  ///open file, write to file and close it. 
  ///If file existed before, then contents is overwritten. If file was larger before, 
  ///then unused blocks are freed
  uint8_t writeRlc(uint8_t i_fileId, uint8_t typ,uint8_t*buf,uint8_t i_len); 
};

#endif
/*eof*/
