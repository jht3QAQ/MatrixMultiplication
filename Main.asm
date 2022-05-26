.386
.model flat, stdcall
.stack 4096
option casemap:none

include msvcrt.inc
includelib msvcrt.lib
include Kernel32.inc
includelib Kernel32.lib

.const
s_d db "%d",0
s_s db "%s",0
s_r db "r",0
s_arg_error db "args number error",0
s_get_args_error db "get args error",0
s_reading_input_file_s db "reading input file:%s",10,0
s_open_file_error db "open file error",10,0

main proto
readFile proto lpszFileName:dword

.code
main proc uses esi
	local argc:dword,argv:dword,env:dword,dwNewMode:dword
	invoke crt___getmainargs,addr argc,addr argv,addr env,0,addr dwNewMode
	.if eax != 0
		invoke crt_puts,addr s_get_args_error
		invoke ExitProcess, -1
	.endif
	.if argc != 4
		invoke crt_puts,addr s_arg_error
		invoke ExitProcess, -1
	.endif
	mov esi,argv
	invoke readFile,[esi]+4
	invoke readFile,[esi]+8
	invoke ExitProcess, 0
main endp
readFile proc lpszFileName
	local pStInputFile:dword
	invoke crt_printf,addr s_reading_input_file_s,lpszFileName
	invoke crt_fopen,lpszFileName,addr s_r
	mov pStInputFile,eax
	.if pStInputFile == 0
		invoke crt_puts,addr s_open_file_error
		invoke ExitProcess, -1
	.endif
	invoke crt_fclose,pStInputFile
	xor eax,eax
	ret
readFile endp
end main