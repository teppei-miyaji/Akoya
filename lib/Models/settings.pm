package Models::settings;
use Models -base;

has primary_key => 'id';
has updated_at => 'updated_on';

our @DATE_FORMATS = [
  '%Y-%m-%d',
  '%d/%m/%Y',
  '%d.%m.%Y',
  '%d-%m-%Y',
  '%m/%d/%Y',
  '%d %b %Y',
  '%d %B %Y',
  '%b %d, %Y',
  '%B %d, %Y'
];

our @TIME_FORMATS = [
  '%H:%M',
  '%I:%M %p'
];

our @ENCODINGS = qw/
  US-ASCII
  windows-1250
  windows-1251
  windows-1252
  windows-1253
  windows-1254
  windows-1255
  windows-1256
  windows-1257
  windows-1258
  windows-31j
  ISO-2022-JP
  ISO-2022-KR
  ISO-8859-1
  ISO-8859-2
  ISO-8859-3
  ISO-8859-4
  ISO-8859-5
  ISO-8859-6
  ISO-8859-7
  ISO-8859-8
  ISO-8859-9
  ISO-8859-13
  ISO-8859-15
  KOI8-R
  UTF-8
  UTF-16
  UTF-16BE
  UTF-16LE
  EUC-JP
  Shift_JIS
  CP932
  GB18030
  GBK
  ISCII91
  EUC-KR
  Big5
  Big5-HKSCS
  TIS-620
/;

1;
