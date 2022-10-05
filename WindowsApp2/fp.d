module fp;
import utils;
import std.math;

U6 BEXPN(U8[] f)
{
	return REGVALN(f,48,58);
}

///
/// Return the decimal value of the exponent in a packed FP number
///
U6 EXPN(U8[] f)
{
	U6 rr = REGVALN(f,48,57);
	if ((f[59] == 0) && f[58]==0) {
		rr *= -1;
	} else if ((f[59] == 1) && (f[58]==1)) {
		rr *= -11;
	}
	
	return rr;
}

void COEFF(U8[] d, U8[] f)
{
	d[0..48] = f[0..48];
}

void EXP(U8[] d, U8[] f)
{
	d[0..10] = f[48..58];
}

void BEXP(U8[] d, U8[] f)
{
	d[0..11] = f[48..59];
}

void SETEXP(U6 v, U8[] f)
{
	if (v < 0) {
		v = abs(v);
		f[58] = 1;
	} else {
		f[58] = 0;
	}
	for (int i = 48;i<58;i++) {
		f[i] = (f[58] == 1) ? !(v % 2) : (v % 2);
		v /= 2;
	}
}

///
/// Returns the rounded coefficient from the FP number in f
///
void FROUND(U8[] d, U8[] f)
{
	
	UI i = 0;
	U8[HWDSIZE] Z;
	
	d[] = f[];
	Z[] = 0;

	if (d == Z) {
		d[47] = 1;
		SETEXP(EXPN(d)-48,d);
	} else {
		while (d[i] != 1) {
			i++;
		}
		d[i-1] = 1;
	}
}

///
/// Rounds the coefficient stored in d
///
void ROUND(U8[] d)
{
	UI i = 0;
	U8[] Z;

	Z.length = d.length;
	Z[] = 0;

	if (d == Z) {
		d[47] = 1;
	} else {
		while (d[i] != 1) {
			i++;
		}
		d[i-1] = 1;
	}
}

U6 digi(U6 n)
{
	U6 j = 0;
	
	if (n == 0) {
		return 1;
	}

	while (n != 0) {
		n /= 10;
		j++;
	}

	return j;
}

void FPPACK(U8[] f, U8[] e, U8[] c)
{
	long sex = SREGVAL(e,SMREGSZ);
	U6 ex = REGVAL(e,SMREGSZ);
	long sco = SREGVAL(c,HWDSIZE);
	U6 co = REGVAL(c,HWDSIZE);

	if (sex >=0) {
		ex += 1024;
	} else {
		ex = 1023 + sex;
	}
	
	if (sco < 0) {
		if (sex < 0) {
			ex = 4095 - ex;
			f[58] = 1;
		} else {
			ex = 3071 - ex;
		}
	}
	for (int i=0;i<48;i++) {
		f[i] = co % 2;
		co /= 2;
	}
	for (int i=48;i<59;i++) {
		f[i] = (ex % 2);
		ex /= 2;
	}
	
	f[59] = (sco >=0) ? 0 : 1;
}

void UNPACK(U8[] f, U8[] e, U8[] c)
{
	for(int i=0;i<48;i++) {
		c[i] = f[i];
	}
	for(int i=48;i<60;i++) {
		c[i] = f[59];
	}
	e[0..10] = f[48..58];

	if (f[59]==0) {
		e[10] = !f[58]; // removing the bias
	} else {
		if (f[58]==1) {
			for (int k = 0;k<11;k++) {
				e[k] = !e[k];
			}
		} else {
			for (int k = 0;k<10;k++) {
				e[k] = !e[k];
			}
		}
		
	}
	
	for (int i=11;i<18;i++) {
		e[i]=e[10];
	}
}