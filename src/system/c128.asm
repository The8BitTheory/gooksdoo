; zero page addresses. we use $0a-$8f ($7a and up is used by vdc-basic)

c_fetch = $02a2
c_fetch_zp = $02aa
c_stash = $02af
c_stash_zp = $02b9

zp_memPtr = $0a ; -$0b      ; generic memory pointer
zp_directoryAddress = $0c ; -$0d    the address where the directory is stored
zp_directoryBank = $0e  ; the bank where the directory is stored


