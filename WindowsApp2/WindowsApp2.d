module WindowsApp2;

import std.stdio;
import utils;
import fp;

int main()
{
    INIT();

    //CIW = [1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0,0,1,0,1,1,0,1,1,1,0,1,0,0,0,0,0];
    CIW = [0,0,0,0,0,1,0,1,1,1,0,1,1,0,1,0,0,0,1,1,1,1,0,0,0,1,1,0,0,0,0,0,1,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1];

    U8[HWDSIZE] FP1;

    //SETXV(175921932009472,1);

    //SETXV(23456,0);
    //CPYRRD(X[2],X[0]);
    
    //GETPARCEL(DIW,CIW,1,2);

    parseCIW();

    SETXV(140737488355328,1);
    SETBV(32720,1);

    //FROUND(FP1,X[1]);

    FPPACK(FP1,B[1],X[1]);

    REGVALO(FP1,HWDSIZE);
	
	CPYRRD(X[3],FP1);

    DUMP();

    return 0;
}
