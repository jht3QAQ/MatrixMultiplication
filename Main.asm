.386
.model flat, stdcall
.stack 4096
option casemap:none

include windows.inc
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
readMatrix proto pStFildData:pFileData

fileData struct
	len 	LONG	0
	pData 	PCHAR	0
fileData ends
pFileData typedef ptr fileData

.code
main proc uses esi
		local 	argc:PINT,argv:PVOID,env:PVOID,dwNewMode:DWORD
		invoke 	crt___getmainargs,addr argc,addr argv,addr env,0,addr dwNewMode
		.if eax != 0
			invoke 	crt_puts,addr s_get_args_error
			invoke 	ExitProcess, -1
		.endif
		.if argc != 4
			invoke 	crt_puts,addr s_arg_error
			invoke 	ExitProcess, -1
		.endif
		mov 	esi,argv
		invoke 	readFile,[esi]+4
		invoke 	readFile,[esi]+8
		invoke 	ExitProcess, 0
main endp

;子程序名:	readFile
;功能:		读取文件并返回文件数据
;入口参数:	lpszFileName=文件名称字符串指针
;出口参数:	eax=fileData结构体指针
readFile proc uses esi,lpszFileName
		local 	pStInputFile:PVOID,pStFileData:pFileData				;文件指针FILE* pStInputFile,文件数据fileData* pStFileData
		invoke 	crt_malloc,sizeof fileData								;为fileData分配内存
		mov pStFileData,eax
		invoke 	crt_printf,addr s_reading_input_file_s,lpszFileName		;pStInputFile=fopen(lpszFileName)
		invoke 	crt_fopen,lpszFileName,addr s_r
		mov 	pStInputFile,eax
		.if pStInputFile == 0
			invoke 	crt_puts,addr s_open_file_error
			invoke 	ExitProcess, -1
		.endif
		mov 	esi,pStFileData											;获取文件大小
		assume 	esi:pFileData
		invoke 	crt_fseek,pStInputFile,0,SEEK_END
		invoke 	crt_ftell,pStInputFile
		mov 	[esi].len,eax
		invoke 	crt_fseek,pStInputFile,0,SEEK_SET
		invoke 	crt_malloc,[esi].len									;为文件数据分配空间
		mov 	[esi].pData,eax
		invoke 	RtlZeroMemory,[esi].pData,[esi].len
		invoke 	crt_fread,[esi].pData,sizeof CHAR,[esi].len,pStInputFile;读取文件数据

		invoke 	crt_puts,[esi].pData

		invoke 	crt_fclose,pStInputFile									;fclose(lpszFileName)
		mov pStFileData
		ret
readFile endp
end main