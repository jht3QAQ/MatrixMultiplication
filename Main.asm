.386
.model flat, stdcall
.stack 4096
option casemap:none

include msvcrt.inc
includelib msvcrt.lib
include Kernel32.inc
includelib Kernel32.lib

.code
main proc
	
exit:invoke ExitProcess, 0
main endp

end main