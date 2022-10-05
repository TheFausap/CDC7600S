module WindowsApp2;

import std.stdio;
import utils;
import fp;
import op;

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

    //SETXV(140737488355328,1);
    //SETXV(219902325555200,1);
    //SETXV(1152701602281291775,1); // Negative number
    //SETXV(175466594061841,1);
    //SETXV(224372305222683,1);
	//SETBV(262096,1); // Negative exponent
    //SETBV(262102,1); // Negative exponent
    //SETBV(262102,1); // Negative exponent
    //SETBV(755,1);
    //SETBV(261256,1);   // Negative exponent

    //FROUND(FP1,X[1]);

    //FPPACK(FP1,B[1],X[1]);

    //REGVALO(FP1,HWDSIZE);
	
	//CPYRRD(X[3],FP1);

    //SETXV(296274432668729407,0);
    //SETXV(280230358996222015,0);
    //SETXV(856647071938117568,0);
    //SETXV(872691145610624960,0);
    //UNPACK(X[0],B[1],X[1]);

    SETXV(296114412467520690,0);
    //SETXV(856807092139326285,0);
    ROUND(X[0]);
    SETBV(NORMALIZE(X[1],X[0]),1);
    

    DUMP();

    return 0;
}
