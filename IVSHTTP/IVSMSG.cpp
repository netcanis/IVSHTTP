//
//  IVSMSG.cpp
//  IVSMSG
//
//  Created by netcanis on 21/07/2017.
//  Copyright © 2017 KAIWEI. All rights reserved.
//

#include "IVSMSG.hpp"
#include <string>
#include <assert.h>


#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif//MIN

#ifndef MAX
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif//MAX


IVSMSG::IVSMSG()
{
    _lpBuffer = (LPBYTE)malloc(IVSMSG_MSG_SIZE);
    clear();
}

IVSMSG::IVSMSG(DWORD dwId)
{
    _lpBuffer = (LPBYTE)malloc(IVSMSG_MSG_SIZE);
    clear();
    setId(dwId);
}

IVSMSG::~IVSMSG()
{
    free(_lpBuffer);
}

void IVSMSG::readData (void* data, DWORD dstLength)
{
    unsigned long srcLength = 0;
    memcpy(&srcLength, _lpRead, sizeof(srcLength));
    _lpRead += sizeof(srcLength);

    unsigned long length = MIN(srcLength, dstLength);
    memcpy(data, _lpRead, length);

    _lpRead += srcLength;
}

void IVSMSG::writeData(void* data, DWORD srcLength)
{
    memcpy(_lpWrite, &srcLength, sizeof(srcLength));
    _lpWrite += sizeof(srcLength);
    *_lpSize += sizeof(srcLength);

    memcpy(_lpWrite, data, srcLength);
    _lpWrite += srcLength;
    *_lpSize += srcLength;
}

// char []
IVSMSG& IVSMSG::operator << (char str[])
{
    unsigned long length = strlen(str) + 1;
    writeData((void *)str, length);
    return *this;
}

IVSMSG& IVSMSG::operator << (const char str[])
{
    *this << (char *)str;
    return *this;
}

IVSMSG& IVSMSG::operator >> (char str[])
{
    readData(str, 0xFFFFFFFF);
    return *this;
}

// std::string
IVSMSG& IVSMSG::operator << (std::string &str)
{
    unsigned long length = str.length() + 1;
    writeData((void *)str.c_str(), length);
    return *this;
}

IVSMSG& IVSMSG::operator >> (std::string &str)
{
    char buf[1024] = {0,};
    readData(buf, 0xFFFFFFFF);
    str = buf;
    return *this;
}





