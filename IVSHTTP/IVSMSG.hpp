//
//  IVSMSG.hpp
//  IVSMSG
//
//  Created by netcanis on 21/07/2017.
//  Copyright © 2017 KAIWEI. All rights reserved.
//

#ifndef IVSMSG_HPP
#define IVSMSG_HPP

#include <stdio.h>
#include <iostream>

#define IVSMSG_MSG_SIZE     4096
#define IVSMSG_BUF_SIZE     32768

#ifndef BYTE
typedef unsigned char       BYTE;
typedef BYTE*               LPBYTE;
#endif//BYTE

#ifndef DWORD
typedef unsigned long       DWORD;
typedef DWORD*              LPDWORD;
#endif//DWORD



class IVSMSG
{
public:
    IVSMSG();
    IVSMSG(DWORD dwId);
    virtual ~IVSMSG();
    
    
    DWORD size() {
        return *_lpSize + (sizeof(DWORD)*2);
    };
    
    DWORD id() {
        return *_lpId;
    };
    
    IVSMSG& setId(DWORD dwId) {
        *_lpId = dwId;
        return *this;
    }
    
    LPBYTE buffer() {
        return _lpBuffer;
    };
    
    void clear() {
        memset(_lpBuffer, 0, sizeof(BYTE)*IVSMSG_BUF_SIZE);
        _lpSize  = (LPDWORD)&_lpBuffer[0];
        _lpId    = (LPDWORD)&_lpBuffer[sizeof(DWORD)];
        _lpRead  = &_lpBuffer[sizeof(DWORD)*2];
        _lpWrite = &_lpBuffer[sizeof(DWORD)*2];
    };
    
    void readData (void* data, DWORD dstLength);
    void writeData(void* data, DWORD srcLength);
    
    template <class T> IVSMSG& operator << (T arg) {
        writeData(&arg, sizeof(T));
        return *this;
    };
    template <class T> IVSMSG& operator >> (T& arg) {
        readData(&arg, sizeof(T));
        return *this;
    };
    
    IVSMSG& operator << (char str[]);
    IVSMSG& operator << (const char str[]);
    IVSMSG& operator >> (char str[]);
    
    IVSMSG& operator << (std::string &str);
    IVSMSG& operator >> (std::string &str);
    
private:
    LPDWORD _lpSize;
    LPDWORD _lpId;
    LPBYTE  _lpBuffer;
    
    LPBYTE  _lpRead;
    LPBYTE  _lpWrite;
};


#endif /* IVSMSG_HPP */
