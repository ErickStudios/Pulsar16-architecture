
; a,b,c,d,e,f,g,h,i
; A=acum 0          / i=0, v=1
; B=addr 0          / i=1
; C=addr 1          / i=2
; D=data base       / i=3
; E=extra data base / i=4
; F:acum 1          / i=5
; G:acum 2          / i=6
; H:acum 3          / i=7
; I:acum 4          / i=8
; B:C = BC          / ?
; D:BC = addr1      / x=0
; E:BC = addr2      / x=1
; D:FG = addr3      / x=2
; E:FG = addr4      / x=3
; HI = val16        / v=1
; add               / o=0
; sub               / o=1
; mov opr           / o=2
; load              / s=0
; store             / s=1
; 0I XX = {o} r8, XXh
; 1O II = {o} r8, r8
; 2X SV = l/s adr, vr
; 3? XX = j +-/XXh