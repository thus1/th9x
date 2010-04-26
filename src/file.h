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


/// fileId of general file
#define FILE_GENERAL   0

/// convert model number 0..MAX_MODELS-1  int fileId
#define FILE_MODEL(n) (1+n)

bool EeFsOpen();
int8_t EeFsck();
void EeFsFormat();
uint16_t EeFsGetFree();

class EFile
{
  uint8_t m_fileId;
  uint16_t pos;
  uint8_t currBlk;
  uint8_t ofs;
  uint8_t bRlc;
public:
  /// create a new file with given fileId, 
  /// !!! if this file already exists, then all blocks are reused
  /// and all contents will be overwritten.
  /// after writing closeTrunc has to be called
  void    create(uint8_t i_fileId, uint8_t typ);
  /// close file and truncate the blockchain if to long.
  void    closeTrunc();

  uint8_t read(uint8_t*buf,uint8_t i_len);
  uint8_t write(uint8_t*buf,uint8_t i_len);
  ///remove contents of given file
  static void rm(uint8_t i_fileId); 

  ///remove swap contents of file1 with them of file2
  static void swap(uint8_t i_fileId1,uint8_t i_fileId2); 

  ///return true if the file with given fileid exists
  static bool exists(uint8_t i_fileId); 


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
  bool copy(uint8_t i_fileIdDst, uint8_t i_fileIdSrc); 
};

#endif
/*eof*/
