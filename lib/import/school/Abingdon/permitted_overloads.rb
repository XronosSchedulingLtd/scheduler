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
  #
  #  3rd year private study.
  #
  PermittedOverload.new(/^3H PS/,   /^3H PS/),
  #
  #  4th year private study.
  #
  PermittedOverload.new(/^4[DRS] PS/,   /^4[DRS] PS/),
  #
  #  3rd year rowing.
  #
  PermittedOverload.new(/^3 Row/,   /^3 Row/),
  #
  #  5th year rowing.
  #
  PermittedOverload.new(/^5 Row/,   /^5 Row/),
  #
  #  Lower School Be The Best
  #
  PermittedOverload.new(/^1.*BtB$/, /^1.*BtB$/),
  PermittedOverload.new(/^2.*BtB$/, /^2.*BtB$/),
  #
  #  Invigilation during tutor period.
  #
  PermittedOverload.new(/-Invig/,   / Ass$/),
  PermittedOverload.new(/-Invig/,   / Tu$/),
  PermittedOverload.new(/-Invig/,   / Chap$/),
  #
  #  Merging two tutor/chapel/assembly periods.
  #
  #  Note that it isn't really feasibly to merge those of different types,
  #  but ICF does it anyway.
  #
  PermittedOverload.new(/ (Tu|Ass|Chap)$/, / (Tu|Ass|Chap)$/),
  #
  #  We have two members of staff teaching 7P Ar and sometimes one is
  #  put down as covering the other.
  #
  PermittedOverload.new(/^7P Ar$/,   /^7P Ar$/),
  #
  #  Mindsets
  #
  PermittedOverload.new(/^6 Mi/, /^6 Mi/)

]
