module WindowsApp2;

import std.stdio;
import utils;

int main()
{
    INIT();

    CIW = [1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0,0,1,0,1,1,0,1,1,1,0,1,0,0,0,0,0];

    SETXV(23456,0);
    CPYRRD(X[2],X[0]);
    
    GETPARCEL(DIW,CIW,1,2);

    DUMP();

    return 0;
}
