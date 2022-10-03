module fp;
import utils;

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

///
/// Returns the rounded coefficient from the FP number in f
///
void ROUND(U8[] d, U8[] f)
{
	COEFF(d,f);
	UI i = 0;
	while (d[i] != 1) {
		i++;
	}
	d[i-1] = 1;
}