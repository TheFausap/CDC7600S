module fp;
import utils;
import std.math;

U6 BEXPN(U8[] f)
{
	return REGVALN(f,48,58);
}

U6 EXPN(U8[] f)
{
	U6 rr = REGVALN(f,48,57);
	rr *= (f[58] == 0) ? 1 : -1;

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