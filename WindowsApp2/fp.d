module fp;
import utils;
import std.math;


U8 _fuadd(U8 a, U8 b, U8 ci, U8 co)
{
	co = (a & b)||(ci & (a ^ b));
	return (a ^ b)^ci;
}

U6 BEXPN(U8[] f)
{
	return REGVALN(f,48,58);
}

///
/// Return the decimal value of the exponent in a packed FP number
///
long EXPN(U8[] f)
{
	U6 rr = REGVALN(f,48,57);
	if ((f[59] == 0) && f[58]==0) {
		rr *= -1;
	} else if ((f[59] == 1) && (f[58]==1)) {
		rr *= -1;
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
/// Valid for normalized numbers
///
void ROUND(U8[] d)
{
	UI i = 0;
	U8[] Z;
	U8[] t1;
	U8 ci = 0;
	U8 co = 0;

	Z.length = d.length;
	t1.length = 48;
	Z[] = 0;
	t1[] = 0;

	if (d == Z) {
		d[47] = 1;
	} else {
		while (d[i] != 1) {
			i++;
		}
		t1[i-1] = 1;
		for (int j=0;j<48;j++) {
			d[j] = _fuadd(d[j],t1[j],ci,co);
			ci = co;
		}
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

U6 NORMALIZE(U8[] d, U8[] f) 
{
	U6 r = 0;
	long e = 0;
	U8[] t;
	t.length = f.length - 2;

	e = EXPN(f);
	t[0..58] = f[0..58];

	if (f[] == ZRO) {
		return 0;
	}

	if (f[59]==1) {
		for(int i=0;i<t.length;i++) {
			t[i]=!t[i];
		}
	}
	
	if (f[59]==0) {
		while(t[47] == f[59]) {
			t[] = RSH(t,1);
			r++;
		}
	} else {
		while(t[47] == !f[59]) {
			t[] = RSH(t,1);
			r++;
		}
	}
	

	if (f[59]==1) {
		e += r;
	} else {
		e -= r;
	}

	for(int i = 48;i<58;i++) {
		t[i] = cast(U8)e % 2;
		e /= 2;
	}


	if (f[59]==1) {
		for(int i=0;i<48;i++) {
			t[i]=!t[i];
		}
	}

	d[0..58] = t[0..58];
	d[58]=f[58];
	d[59]=f[59];

	return r;
}