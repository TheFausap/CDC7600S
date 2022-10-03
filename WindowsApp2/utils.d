module utils;

import std.math;
import core.stdc.stdio;
import std.stdio;
import std.format;
import core.stdc.stdlib : exit;
import std.random;


alias UI=uint;
alias U6=ulong;
alias U8=ubyte;
alias U16=ushort;

enum int HWDSIZE=60;
enum int SMREGSZ=18;
enum int PCLSIZE=15;

enum int SCMSIZE=32768;
enum int LCMSIZE=256000;

UI FLL;
UI FLS;
UI RAL;
UI RAS;

// CONDITION FLAGS
enum int UNFL=0;
enum int OVFL=1;
enum int INDF=2;
enum int STEP=3;
enum int BRKP=4;
enum int PRNG=5;
enum int SCDR=6;
enum int LCDR=7;
enum int SCBR=8;
enum int LCBR=9;
enum int SCMP=10;
enum int LCMP=11;
// MODE FLAGS
enum int mUNFL=12;
enum int mOVFL=13;
enum int mINDF=14;
enum int mSTEP=15;
enum int mMONI=16;
enum int mEXIT=17;

// CIW parsing helper
U8[int] CIWmap;

void CR() {printf("\n");}

// each byte contains only 1 bit. wasted space
// easy to address. 1 more element for string terminator
U8[HWDSIZE][SCMSIZE] SCM;
U8[HWDSIZE][LCMSIZE] LCM;

U8[SMREGSZ][8] A;

U8[SMREGSZ][8] B;

U8[HWDSIZE][8] X;

U8[HWDSIZE] ONE;
U8[HWDSIZE] ZRO;
U8[HWDSIZE] CIW;
UI NEA;
UI EEA;
U8[SMREGSZ] PSD;
UI PAR; // Program Addres Register

U8[PCLSIZE]     SIW;    // Single IW (15 bits) -   1 parcel
U8[2*PCLSIZE]   DIW;    // Double IW (30 bits) -   2 parcels

U8[3]   _IWg;
U8[3]   _IWh;
U8[3]   _IWj;
U8[3]   _IWi;
U8[3]   _IWk;
U8[15]  _IWK;

UI   IWg;
UI   IWh;
UI   IWj;
UI   IWi;
UI   IWk;
UI   IWK;

U8[SMREGSZ] IA;

U8 IWSpos = 11;
U8 IASpos = 11;
U8[HWDSIZE][12] IWS;
U8[SMREGSZ][12] IAS;

static uint _getCount()
{
	asm
	{	naked	;
		rdtsc	;
		ret	;
	}
}

void POPIW()
{
    CIW = IWS[IWSpos];
    IWSpos--;
}

void PUSHIW(U8[] s)
{
    IWSpos++;
    IWS[IWSpos] = s;
}

void POPIA()
{
    IA = IAS[IASpos];
    IASpos--;
}

void PUSHIA(U8[] s)
{
    IASpos++;
    IAS[IASpos] = s;
}

/// <summary>
/// store in d the n parcels starting from st from the CIW
/// </summary>
/// <param name="d">dest reg</param>
/// <param name="s">source reg</param>
/// <param name="st">id of parcel (0,1,2,3)</param>
/// <param name="n">number of parcels (max 2)</param>
void GETPARCEL(U8[] d, U8[] s, U8 st, U8 n)
{
    if (n>2) {
        writeln("Too many parcels!\n");
        exit(-200);
	}
    if (st>3) {
        writeln("No such parcel with id %d",st);
        exit(-210);
	}
    if ((st>2) && (n>1)) {
        writeln("Not enough parcels\n");
        exit(-205);
	}
    int bits = 15 * n;
    int iwsize = HWDSIZE - 1;
    int reliwpos = iwsize - st*15;

    for (int i=bits-1,j=reliwpos;i>=0 && j>=reliwpos-bits;i--,j--) {
        d[i] = s[j];
	}
}

/// <summary>
/// 9-Complement of the 60 bit registry
/// </summary>
/// <param name="r">registry</param>
void C9D(U8[] r)
{
    for (int i = 0; i < HWDSIZE; i++) {
        r[i] = !r[i];
    }
}

/// <summary>
/// 9-Complement of the 18 bit registry
/// </summary>
/// <param name="r">registry</param>
void C9S(U8[] r)
{
    for (int i = 0; i < HWDSIZE; i++) {
        r[i] = !r[i];
    }
}

/// <summary>
/// Put a numeric decimal value (unsigned) in a registry B0...B7
/// Delete the content of the destination registry!
/// </summary>
/// <param name="v">decimal value</param>
/// <param name="rn">reg number</param>
void SETBV(U6 v, U8 rn)
{
    if ( rn != 0) {
        for (int i = 0; i < SMREGSZ; i++) {
            B[rn][i] = 0;
        }

        for (int i = SMREGSZ - 1; i >= 0; i--) {
            B[rn][i] = (v % 2);
            v /= 2;
        }
	}
}

/// <summary>
/// Put a numeric decimal value (unsigned) in a registry X0...X7
/// Delete the content of the destination registry!
/// </summary>
/// <param name="v">decimal value</param>
/// <param name="rn">reg number</param>
void SETXV(U6 v, U8 rn)
{
    U8 v1 = 0;
    for (int i = 0; i < HWDSIZE; i++) {
        X[rn][i] = 0;
    }

    for (int i = 0; i < HWDSIZE; i++) {
        v1 = v % 2;
        X[rn][i] = v1;
        v /= 2;
    }
}

/// <summary>
/// Put a numerical decimal value (unsigned) into the A0...A7 regs
/// Delete the contents of the registries first!
/// </summary>
/// <param name="v">decimal value</param>
/// <param name="rn">reg number</param>
void SETAV(U6 v, U8 rn)
{
    for (int i = 0; i < SMREGSZ; i++) {
        A[rn][i] = 0;
    }

    for (int i = 0; i < SMREGSZ; i++) {
        A[rn][i] = cast(U8)(v % 2);
        v /= 2;
    }
}

/// <summary>
/// Copy two 60 bit registers
/// </summary>
/// <param name="rnd">dest reg number</param>
/// <param name="rnss">source reg number</param>
void CPYRRD(U8[] d, U8[] s)
{
    for (int i = 0; i < HWDSIZE; i++) {
        d[i] = s[i];
    }
}

/// <summary>
/// Copy two 18 bit registers
/// </summary>
/// <param name="rnd">dest reg number</param>
/// <param name="rnss">source reg number</param>
void CPYRRS(U8[] d, U8[] s)
{
    for (int i = 0; i < SMREGSZ; i++) {
        d[i] = s[i];
    }
}

/// <summary>
/// Copy the memory word at the address in A1..A5 into X1..X5
/// Only lower 16 bits are used
/// </summary>
/// <param name="n">register pair number</param>
void CPYAX(U8 n)
{
    if ((n == 0) || (n>5)) {
        writeln("Cannot use those register pair in the instruction\n");
        exit(-100);
	}
    UI An = cast(UI)REGVAL(A[n],cast(U8)18);
    for (int i=0;i<16;i++) {
        X[n][i] = SCM[An][i];
	}
}

/// <summary>
/// Copy the memory word at X6..X7 into the memory at address specified in A6..A7
/// Only lower 16 bits are used
/// </summary>
/// <param name="n">register pair number</param>
void CPYXA(U8 n)
{
    if ((n == 0) || (n < 6) || (n>7)) {
        writeln("Cannot use those register pair in the instruction\n");
        exit(-110);
	}
    UI An = cast(UI)REGVAL(A[n],cast(U8)18);
    for (int i=0;i<16;i++) {
        SCM[An][i] = X[n][i];
	}
}

/// <summary>
/// Copy a registry into another one bigger.
/// Extend the sign of the source registry into the destination
/// </summary>
/// <param name="d">dest reg</param>
/// <param name="s">source reg</param>
void EXTND(U8[] d, U8[] s)
{
    for (int i = 0; i < SMREGSZ; i++) {
        d[i] = s[i];
	}

    // extend the sign to the rest of the accumulator
    for (int i = SMREGSZ; i < HWDSIZE; i++) {
        d[i] = s[17];
    }
}

/// <summary>
/// Copy a registry into another one bigger.
/// Extend the sign of the source registry into the destination
/// </summary>
/// <param name="d">dest reg</param>
/// <param name="s">source reg</param>
void EXTNS(U8[] d, U8[] s)
{
    /*
	for (int i = HWDSIZE - 1, j = SMREGSZ - 1; i >= SMREGSZ && j >= 0; i--, j--) {
        d[i] = s[j];
    }
    */

    for (int i = 0; i < SMREGSZ; i++) {
        d[i] = s[i];
	}

    // extend the sign to the rest of the accumulator
    for (int i = SMREGSZ; i < HWDSIZE; i++) {
        d[i] = 0;
    }
}

/// <summary>
/// Convert a regitry into a decimal value
/// </summary>
/// <param name="r">registry</param>
/// <param name="l">registry lenght (HWDSIZE or SMREGSZ)</param>
/// <returns>decimal representation</returns>
U6 REGVAL(U8[] r, U8 l)
{
    U6 rr = 0;

    for (int j = 0; j < l; j++) {
        rr += r[j] * pow(2, j);
    }

    return rr;
}

/// <summary>
/// Convert a regitry into a decimal value
/// </summary>
/// <param name="r">registry</param>
/// <param name="l">registry lenght (HWDSIZE or SMREGSZ)</param>
/// <returns>decimal representation</returns>
U6 REGVALN(U8[] r, U8 s, U8 e)
{
    U6 rr = 0;

    for (int j = s; j < e; j++) {
        rr += r[j] * pow(2, j);
    }

    return rr;
}

/// INSTRUCTION CODES
void _O00(U8 fl, U8 set) 
{
    if (set == 1) {
        PSD[fl] = 1;
	} else {
        PSD[fl] = 0;
	}
    /* INTERNAL USE */
    DUMP();
}

void O11jK()
{
    U6 K = REGVAL(_IWK,SMREGSZ);
    K += REGVAL(B[IWj],SMREGSZ);
    if (K > 1023) {
        K &= 0x003FF;
	}
    U6 saddr = REGVAL(X[0],20);
    if (K+saddr > FLL) {
        PAR = EEA;
        _O00(LCBR,1);
	}
    U6 daddr = REGVAL(A[0],SMREGSZ);
    if (K+daddr > FLS) {
        PAR = EEA;
        _O00(SCBR,1);
	}
    for (int i = 0; i<K;i++) {
        SCM[RAS+daddr+i] = LCM[RAL+saddr+i];
	}
}

void O12jK()
{
    U6 K = REGVAL(_IWK,SMREGSZ);
    K += REGVAL(B[IWj],SMREGSZ);
    if (K > 1023) {
        K &= 0x003FF;
	}
    U6 daddr = REGVAL(X[0],20);
    if (K+daddr > FLL) {
        PAR = EEA;
        _O00(LCBR,1);
	}
    U6 saddr = REGVAL(A[0],SMREGSZ);
    if (K+saddr > FLS) {
        PAR = EEA;
        _O00(SCBR,1);
	}
    for (int i = 0; i<K;i++) {
        LCM[RAL+daddr+i] = SCM[RAS+saddr+i];
	}
}

void O1300()
{
    PAR = NEA & 0xFFFF;
    _O00(mEXIT,0);
}

void O14jk()
{
    U6 saddr = REGVAL(X[IWk],20);
    if (saddr > FLL) {
        PAR = EEA;
        _O00(LCDR,1);
        saddr += RAL;
        saddr &= 0xFFFFF;
        X[IWj] = LCM[RAL+saddr];
	} else {
        X[IWj] = LCM[RAL+saddr];
	}
}

void O15jk()
{
    U6 daddr = REGVAL(X[IWk],20);
    if (daddr > FLL) {
        PAR = EEA;
        _O00(LCDR,1);
	} else {
        LCM[RAL+daddr] = X[IWj];
	}
}

void O10xK()
{
    U8[HWDSIZE] t;
    t[59]=0; t[58]=4;
    UI naddr = PAR + 1;

    for(int i=0;i<18;i++) {
        t[30+i] = naddr % 2;
        naddr /= 2;
	}
    SCM[RAS+IWK] = t;
    PAR = RAL + IWK + 1;
}

void O02xK()
{
    UI daddr = cast(UI)REGVAL(B[IWi],SMREGSZ) + IWK;
    PAR = daddr;
}

void O30jk() 
{
    U6 t = REGVAL(X[IWj],59); // no sign bit
    if ((t == 0) || (t == 0x7FFFFFFFFFFFFFF)) {
        PAR = IWK;
	}
}

void O31jk() 
{
    U6 t = REGVAL(X[IWj],59); // no sign bit
    if ((t != 0) && (t != 0x7FFFFFFFFFFFFFF)) {
        PAR = IWK;
	}
}

void O32jk() 
{
    if (X[IWj][59] == 0) {
        PAR = IWK;
	}
}

void O33jk() 
{
    if (X[IWj][59] == 1) {
        PAR = IWK;
	}
}

void O34jk() 
{
    U8[12] t = X[IWj][47..59];
    U6 tv = REGVAL(t,12);

    if ((tv != 2047) && (tv != 2048) &&
		(tv != 1023) && (tv != 3072)) {
        PAR = IWK;
	}
}

void O35jk() 
{
    U8[12] t = X[IWj][47..59];
    U6 tv = REGVAL(t,12);

    if ((tv == 2047) || (tv == 2048) ||
		(tv == 1023) || (tv == 3072)) {
			PAR = IWK;
		}
}

void O36jk() 
{
    U8[12] t = X[IWj][47..59];
    U6 tv = REGVAL(t,12);

    if ((tv != 1023) && (tv != 3072)) {
			PAR = IWK;
		}
}

void O37jk() 
{
    U8[12] t = X[IWj][47..59];
    U6 tv = REGVAL(t,12);

    if ((tv == 1023) || (tv == 3072)) {
		PAR = IWK;
	}
}

void O04ijK()
{
    if (B[IWi] == B[IWj]) {
        PAR = IWK;
	}
}

void O05ijK()
{
    if (B[IWi] != B[IWj]) {
        PAR = IWK;
	}
}

void O06ijK()
{
    U6 vi = REGVAL(B[IWi],SMREGSZ);
    U6 vj = REGVAL(B[IWj],SMREGSZ);

    if (vi >= vj) {
        PAR = IWK;
	}
}

void O07ijK()
{
    U6 vi = REGVAL(B[IWi],SMREGSZ);
    U6 vj = REGVAL(B[IWj],SMREGSZ);

    if (vi < vj) {
        PAR = IWK;
	}
}

void O10ijk()
{
    CPYRRD(X[IWi],X[IWj]);
}

void O11ijk()
{
    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] & X[IWk][i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O12ijk()
{
    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] | X[IWk][i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O13ijk()
{
    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] ^ X[IWk][i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O14ik()
{
    X[IWi] = X[IWk];
    C9D(X[IWi]);
}

void O15ik()
{
    U8[HWDSIZE] t = X[IWk];
    C9D(t);

    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] & t[i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O16ik()
{
    U8[HWDSIZE] t = X[IWk];
    C9D(t);

    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] | t[i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O17ik()
{
    U8[HWDSIZE] t = X[IWk];
    C9D(t);

    for (int i = 0;i<HWDSIZE;i++) {
        if ((X[IWj][i] ^ t[i]) == 1) {
            X[IWi][i] = 1;
		} else {
            X[IWi][i] = 0;
		}
	}
}

void O26ijk()
{
    U6 ex;
    U8[10] exx;

    X[IWi][0..47] = X[IWk][0..47];
    for (int i=48;i<60;i++) {
        X[IWi][i] = X[IWk][59];
	}
    
	exx = X[IWk][48..58];
    ex = REGVAL(exx,SMREGSZ);
    ex -= 1024;
    SETBV(ex,cast(U8)IWj);
    for (int i=10;i<18;i++) {
        B[IWj][i] = X[IWk][58];
	}
}

void parseCIW()
{
    U8 pno = 0;
    U8 curparc = 0;
    IWg = cast(U8)REGVALN(CIW,57,59);
    IWh = cast(U8)REGVALN(CIW,54,56);
    if ((IWg == 0) && (IWh == 0)) _O00(mEXIT,1);
    if (IWg == 0) {
        IWi = cast(U8)REGVALN(CIW,51,53);
        pno = CIWmap[800+IWg*10+IWi];
	} else {
        pno = CIWmap[IWg*10+IWh];
	}
    if (pno == 1) 
	{
        GETPARCEL(SIW,CIW,curparc,1);
        curparc++;
	} else {
        GETPARCEL(DIW,CIW,curparc,2);
        curparc++;
        curparc++;
	}
    if (curparc > 3) curparc = 0;
}

void INIT()
{
    alias RASLCG = LinearCongruentialEngine!(uint, 47275, 0, 2_134_483_647);
	alias RALLCG = LinearCongruentialEngine!(uint, 43375, 0, 2_142_484_647);
    B[0] = 0;
    auto rnds = RASLCG(_getCount());
    do {
        RAL = 4095 + (rnds.front % 256000);
	} while (RAL + 8192 > LCMSIZE);
    
    auto rndl = RALLCG(_getCount());
    
    do {
        RAS = 2047 + (rndl.front % 32768);
	} while (RAS + 1024 > SCMSIZE);
    FLL = RAL + 8191;
    FLS = RAS + 1023;

    CIWmap[810] = 2;
    CIWmap[811] = 2;
    CIWmap[812] = 2;
    CIWmap[813] = 12;
    CIWmap[814] = 1;
    CIWmap[815] = 1;
    CIWmap[816] = 1;
    CIWmap[817] = 1;
    CIWmap[82] = 2;
    CIWmap[830] = 2;
    CIWmap[831] = 2;
    CIWmap[832] = 2;
    CIWmap[833] = 2;
    CIWmap[834] = 2;
    CIWmap[835] = 2;
    CIWmap[836] = 2;
    CIWmap[837] = 2;
    CIWmap[84] = 2;
    CIWmap[85] = 1;
    CIWmap[86] = 2;
    CIWmap[87] = 2;
    CIWmap[10] = 1;
    CIWmap[11] = 1;
    CIWmap[12] = 1;
    CIWmap[13] = 1;
    CIWmap[14] = 1;
    CIWmap[15] = 1;
    CIWmap[16] = 1;
    CIWmap[17] = 1;
    CIWmap[20] = 1;
    CIWmap[21] = 1;
    CIWmap[22] = 1;
    CIWmap[23] = 1;
    CIWmap[24] = 1;
    CIWmap[25] = 1;
    CIWmap[26] = 1;
    CIWmap[27] = 1;
    CIWmap[30] = 1;
    CIWmap[31] = 1;
    CIWmap[32] = 1;
    CIWmap[33] = 1;
    CIWmap[34] = 1;
    CIWmap[35] = 1;
    CIWmap[36] = 1;
    CIWmap[37] = 1;
    CIWmap[40] = 1;
    CIWmap[41] = 1;
    CIWmap[42] = 1;
    CIWmap[43] = 1;
    CIWmap[44] = 1;
    CIWmap[45] = 1;
    CIWmap[46] = 1;
    CIWmap[47] = 1;
    CIWmap[50] = 2;
    CIWmap[51] = 2;
    CIWmap[52] = 2;
    CIWmap[53] = 1;
    CIWmap[54] = 1;
    CIWmap[55] = 1;
    CIWmap[56] = 1;
    CIWmap[57] = 1;
    CIWmap[60] = 2;
    CIWmap[61] = 2;
    CIWmap[62] = 2;
    CIWmap[63] = 1;
    CIWmap[64] = 1;
    CIWmap[65] = 1;
    CIWmap[66] = 1;
    CIWmap[67] = 1;
    CIWmap[70] = 2;
    CIWmap[71] = 2;
    CIWmap[72] = 2;
    CIWmap[73] = 1;
    CIWmap[74] = 1;
    CIWmap[75] = 1;
    CIWmap[76] = 1;
    CIWmap[77] = 1;

}

/// <summary>
/// Dump some interesting memory contents on the stdout
/// Value are unsigned
/// </summary>
void DUMP()
{

    U8 hwsz = HWDSIZE - 1;
    U8 resz = SMREGSZ - 1;
    U8 pcsz = PCLSIZE - 1;
    U8 dpcz = 2*PCLSIZE - 1;

    writeln("----");

    writef("\t");
    for (int i = hwsz; i >=0 ; i-=10) {
		writef("%d", i/10);
        write("         ");
	}
    CR;
    writef("\t");
    for (int i = hwsz; i >= 0; i--) {
		writef("%d", i%10);
	}
    writeln("\n\t------------------------------------------------------------");
    for (int j = 0;j<8;j++) {
        writef("X%d:\t",j);
        for (int i = hwsz; i >=0; i--) {
            writef("%d", X[j][i]);
        }
        printf("\t(");
        write(REGVAL(X[j], HWDSIZE));
        printf(")\n");
    }
    writeln("----");
    writef("\t");
    for (int i = resz; i >=0 ; i-=9) {
		writef("%d", i/10);
        write("         ");
	}
    CR;
    writef("\t");
    for (int i = resz; i >= 0; i--) {
		writef("%d", i%10);
	}
    writeln("\n\t------------------");
    for (int j = 0;j<8;j++) {
        printf("A%d:\t",j);
        for (int i =resz; i >=0; i--) {
            printf("%d", A[j][i]);
        }
        printf("\t\t\t\t\t\t(");
        write(REGVAL(A[j], SMREGSZ));
        printf(")\n");
    }
    writeln("----");
    writef("\t");
    for (int i = resz; i >=0 ; i-=9) {
		writef("%d", i/10);
        write("         ");
	}
    CR;
    writef("\t");
    for (int i = resz; i >= 0; i--) {
		writef("%d", i%10);
	}
    writeln("\n\t------------------");
    for (int j = 0;j<8;j++) {
        printf("B%d:\t",j);
        for (int i = resz; i >=0; i--) {
            printf("%d", B[j][i]);
        }
        printf("\t\t\t\t\t\t(");
        write(REGVAL(B[j], SMREGSZ));
        printf(")\n");
	}
     writeln("----");

    writef("\t");
    for (int i = hwsz; i >=0 ; i-=15) {
		writef("%d", i/10);
        write("              ");
	}
    CR;
    writef("\t");
    for (int i = hwsz; i >= 0; i--) {
		writef("%d", i%10);
	}
    writeln("\n\t------------------------------------------------------------");
    writef("CIW:\t");
	for (int i = hwsz; i >=0; i--) {
		writef("%d", CIW[i]);
	}
    CR;
    writef("SIW:\t");
	for (int i = pcsz; i>=0; i--) {
		writef("%d", SIW[i]);
	}
    CR;
    writef("DIW:\t");
	for (int i = dpcz; i >=0; i--) {
		writef("%d", DIW[i]);
	}
    CR;
    writeln("----");
    writef("RAL:\t0%o   ",RAL);
    writef("RAS:\t0%o",RAS);
    writef("\t\t SCM [0 - 0%o]",SCMSIZE-1);
    CR;
    writef("FLL:\t0%o   ",FLL);
    writef("FLS:\t0%o",FLS);
    writef("\t\t LCM [0 - 0%o]",LCMSIZE-1);
    CR;
}
