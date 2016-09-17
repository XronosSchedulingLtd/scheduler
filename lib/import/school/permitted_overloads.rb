#
#  Each of these indicates a circumstance in which overloaded cover
#  is permitted.
#
#  There are circumstances in which lessons are covered by means of
#  merging two sets.  Typically this happens for PSHCE, Private Study
#  and sport.  This section of code attempts to identify pairs of
#  lesson names where this kind of merging is acceptable, and thus
#  suppresses the warning about cover which would otherwise be generated.
#
#  Each permitted overload consists of two regular expressions which
#  are tested against the two event names (cover event and original
#  commitment).  If a pair matches then the overload is considered
#  acceptable and no warning is issued.
#

PermittedOverload = Struct.new(:cover_event_body, :clash_event_body)


PERMITTED_OVERLOADS = [
  PermittedOverload.new(/^4S PS/,    /^4S PS/),
  PermittedOverload.new(/^S1 Dr/,    /^S1 Dr/),
  PermittedOverload.new(/^S2 Dr/,    /^S2 Dr/),
  PermittedOverload.new(/^S3 Y Dr/,  /^S3 Y Dr/),
  PermittedOverload.new(/^S3 PSHCE/, /^S3 PSHCE/),
  PermittedOverload.new(/^S4 PSHCE/, /^S4 PSHCE/),
  PermittedOverload.new(/^S3 PE /,   /^S3 PE /),
  PermittedOverload.new(/^S4 PE /,   /^S4 PE /),
  PermittedOverload.new(/^S5 PE /,   /^S5 PE /),
  PermittedOverload.new(/^S6 GSCS/,  /^S6 GSCS/),
  PermittedOverload.new(/1.*BtB/,    /S1 H BtB/),
  PermittedOverload.new(/2.*BtB/,    /S2 H BtB/)
]
