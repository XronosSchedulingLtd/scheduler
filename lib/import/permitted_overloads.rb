#
#  Each of these indicates a circumstance in which overloaded cover
#  is permitted.
#

PermittedOverload = Struct.new(:cover_event_body, :clash_event_body)


PERMITTED_OVERLOADS = [
  PermittedOverload.new(/^S1 Dr/,    /^S1 Dr/),
  PermittedOverload.new(/^S2 Dr/,    /^S2 Dr/),
  PermittedOverload.new(/^S3 Y Dr/,  /^S3 Y Dr/),
  PermittedOverload.new(/^S3 PSHCE/, /^S3 PSHCE/),
  PermittedOverload.new(/^S4 PSHCE/, /^S4 PSHCE/),
  PermittedOverload.new(/^S3 PE /,   /^S3 PE /),
  PermittedOverload.new(/^S4 PE /,   /^S4 PE /),
  PermittedOverload.new(/^S5 PE /,   /^S5 PE /),
  PermittedOverload.new(/^S5 Study Skills/,   /^S5 Study Skills/),
  PermittedOverload.new(/^S6 GSCS/,  /^S6 GSCS/),
  PermittedOverload.new(/^S6 Spt/,  /^S7 Spt/),
  PermittedOverload.new(/^S7 Spt/,  /^S6 Spt/),
  PermittedOverload.new(/^S1 Spt/,  /^S2 Spt/),
  PermittedOverload.new(/^S2 Spt/,  /^S1 Spt/),
  PermittedOverload.new(/1.*BtB/,    /S1 H BtB/),
  PermittedOverload.new(/2.*BtB/,    /S2 H BtB/)
]
