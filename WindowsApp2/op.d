module op;
import utils;
import fp;
import std.math;



///
/// INSTRUCTION CODES
///
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

void parseCIW()
{
    U8 pno = 0;

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

void O011jK()
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

void O012jK()
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

void O01300()
{
    PAR = NEA & 0xFFFF;
    _O00(mEXIT,0);
}

void O014jk()
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

void O015jk()
{
    U6 daddr = REGVAL(X[IWk],20);
    if (daddr > FLL) {
        PAR = EEA;
        _O00(LCDR,1);
	} else {
        LCM[RAL+daddr] = X[IWj];
	}
}

void O010xK()
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

void O030jk() 
{
    U6 t = REGVAL(X[IWj],59); // no sign bit
    if ((t == 0) || (t == 0x7FFFFFFFFFFFFFF)) {
        PAR = IWK;
	}
}

void O031jk() 
{
    U6 t = REGVAL(X[IWj],59); // no sign bit
    if ((t != 0) && (t != 0x7FFFFFFFFFFFFFF)) {
        PAR = IWK;
	}
}

void O032jk() 
{
    if (X[IWj][59] == 0) {
        PAR = IWK;
	}
}

void O033jk() 
{
    if (X[IWj][59] == 1) {
        PAR = IWK;
	}
}

void O034jk() 
{
    U8[13] t = X[IWj][47..60];
    U6 tv = REGVAL(t,13);

    if ((tv != 2047) && (tv != 2048) &&
		(tv != 1023) && (tv != 3072)) {
			PAR = IWK;
		}
}

void O035jk() 
{
    U8[13] t = X[IWj][47..60];
    U6 tv = REGVAL(t,13);

    if ((tv == 2047) || (tv == 2048) ||
		(tv == 1023) || (tv == 3072)) {
			PAR = IWK;
		}
}

void O036jk() 
{
    U8[13] t = X[IWj][47..60];
    U6 tv = REGVAL(t,13);

    if ((tv != 1023) && (tv != 3072)) {
		PAR = IWK;
	}
}

void O037jk() 
{
    U8[13] t = X[IWj][47..60];
    U6 tv = REGVAL(t,13);

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
    X[IWi][] = X[IWk][];
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
    U8[9] exx;

    X[IWi][0..48] = X[IWk][0..48];
    for (int i=48;i<60;i++) {
        X[IWi][i] = X[IWk][59];
	}

    B[IWj][0..10] = X[IWk][48..58];

    // Exponent sign extended
    for (int i=10;i<18;i++) {
        B[IWj][i] = X[IWk][58];
	}
}

void O27ijk()
{
    X[IWi][48..59] = B[IWj][0 .. 11];
    if (X[IWk][48] == 0) {
        X[IWi][48] = !X[IWi][48];
	} else {
        X[IWi][48..58] = !X[IWi][48..58];
	}
    X[IWi][0..48] = X[IWk][0..48];
}

void O20ijk()
{
    UI t = IWj*7 + IWk;
    U8 t1 = 0;

    t = t % 60;

    for (int j = 0;j<t;j++) {
		t1 = X[IWi][0];
		for(int i = 0;i<HWDSIZE-1;i++) {
			X[IWi][i] =  X[IWi][i+1];
		}
		X[IWi][59] = t1;
    }
}

void O21ijk()
{
    UI t = IWj*7 + IWk;
    U8 t1 = 0;

    for (int j = 0;j<t;j++) {
		for(int i = HWDSIZE-1;i>0;i--) {
			X[IWi][i] =  X[IWi][i-1];
		}
    }
}

void O22ijk()
{
    X[IWi][] = X[IWk][];
    int t = 0;
    U8 t1 = 0;

    if (B[IWj][17] == 0) {
        t = cast(UI)REGVAL(B[IWj],6);
        for (int j = 0;j<t;j++) {
			t1 = X[IWi][0];
			for(int i = 0;i<HWDSIZE-1;i++) {
				X[IWi][i] =  X[IWi][i+1];
			}
			X[IWi][59] = t1;
		}
	} else {
        t = cast(UI)REGVAL(B[IWj],12);
        for (int j = 0;j<t;j++) {
			for(int i = HWDSIZE-1;i>0;i--) {
				X[IWi][i] =  X[IWi][i-1];
			}
		}
	}
}

void O23ijk()
{
    X[IWi][] = X[IWk][];
    int t = 0;
    U8 t1 = 0;

    if (B[IWj][17] == 1) {
        t = cast(UI)REGVAL(B[IWj],6);
        for (int j = 0;j<t;j++) {
			t1 = X[IWi][0];
			for(int i = 0;i<HWDSIZE-1;i++) {
				X[IWi][i] =  X[IWi][i+1];
			}
			X[IWi][59] = t1;
		}
	} else {
        t = cast(UI)REGVAL(B[IWj],12);
        for (int j = 0;j<t;j++) {
			for(int i = HWDSIZE-1;i>0;i--) {
				X[IWi][i] =  X[IWi][i-1];
			}
		}
	}
}

void O43ijk()
{
    UI t = IWj*7 + IWk;

    X[IWi][] = 0;

    if (t >= 60) {
        X[IWi] = 1;
	} else if(t == 0) {
        X[IWi] = 0;
	} else {
        for (int i=0;i<t;i++) {
            X[IWi][(HWDSIZE-1)-i] = 1;
		}
	}
}

void O24ijk()
{
    U8[] co = X[IWk][0..48];
    UI i = 1;
    U6 ex = REGVALN(X[IWk],48,58);

    if ((ex == 2047) || (ex == 2048) || (ex == 1023) || (ex == 3072)) {
        SETBV(0UL,cast(U8)IWj);
        X[IWi] = X[IWk];
	} else {
        ex = REGVALN(X[IWk],48,57);
		ex *= (X[IWk][58] == 0) ? 1 : -1;

		while (co[47] != X[IWk][59]) {
			LSH(co,i);
			i++;
		}
		ex -= i;
		SETBV(cast(U6)i,cast(U8)IWj);
        X[IWi][0..48] = co;
        if (ex < 0) {
            ex = abs(ex);
			for (int ll = 48;ll<59;ll++) {
                X[IWi][ll] = !(ex % 2);
                ex /= 2;
			}
		} else {
			for (int ll = 48;ll<59;ll++) {
                X[IWi][ll] = ex % 2;
                ex /= 2;
			}
		}
		if (ex < -1023) {
			X[IWi][] = X[IWk][59];
		}
		if ((X[IWk] == ZRO) || (X[IWk] == ONE)) {
			SETBV(48UL,cast(U8)IWj);
			X[IWi][] = X[IWk][59];
		}
	}
}

void O25ijk()
{
    U8[] co = X[IWk][0..48];
    ROUND(co);
    UI i = 1;
    U6 ex = REGVALN(X[IWk],48,58);

    if ((ex == 2047) || (ex == 2048) || (ex == 1023) || (ex == 3072)) {
        SETBV(0UL,cast(U8)IWj);
        X[IWi] = X[IWk];
	} else {
        ex = EXPN(X[IWk]);

		while (co[47] != X[IWk][59]) {
			LSH(co,i);
			i++;
		}
		ex -= i;
		SETBV(cast(U6)i,cast(U8)IWj);
        X[IWi][0..48] = co;
        if (ex < 0) {
            ex = abs(ex);
			for (int ll = 48;ll<59;ll++) {
                X[IWi][ll] = !(ex % 2);
                ex /= 2;
			}
		} else {
			for (int ll = 48;ll<59;ll++) {
                X[IWi][ll] = ex % 2;
                ex /= 2;
			}
		}
		if (ex < -1023) {
			X[IWi][] = X[IWk][59];
		}
		if ((X[IWk] == ZRO) || (X[IWk] == ONE)) {
			SETBV(48UL,cast(U8)IWj);
			X[IWi][] = X[IWk][59];
		}
	}
}
