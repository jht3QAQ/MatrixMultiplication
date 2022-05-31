.386
.model flat, stdcall
.stack 4096
option casemap:none

include windows.inc
include msvcrt.inc
include masm32.inc
includelib masm32.lib
includelib msvcrt.lib
include Kernel32.inc
includelib Kernel32.lib

.const
s_d db "%d ",0
s_s db "%s",0
s_r db "r",0
s_w db "w",0
s_blank db " ",0
s_arg_error db "args number error",10,0
s_get_args_error db "get args error",10,0
s_reading_input_file_s db "reading input file:%s",10,0
s_open_file_error db "open file error",10,0
s_matrix_format_error db "matrix format error",10,0
s_this_is_a_d_d_matrix db "this is a %d * %d matrix",10,0
s_matrix_cant_be_multiplied db "matrix can't be multiplied",10,0
s_the_answer_is db "the answer is:",10,0
s_saving_to_the_file_s db "saving to the file %s",10,0
s_saved db "saved",10,0

fileData struct
	len 	LONG	0
	pData 	PCHAR	0
fileData ends
pFileData typedef ptr fileData

matrixData struct
	X		DWORD	0
	Y		DWORD	0
	lpData	PVOID	0
matrixData ends
pMatrixData typedef ptr matrixData

main proto
readFile proto lpszFileName:LPSTR
readMatrix proto lpStFileData:pFileData
mulMatrix proto lpSMatrixDataA:pMatrixData,lpSMatrixDataB:pMatrixData
printMatrix proto lpSMatrixData:pMatrixData
saveMatrix proto lpSMatrixData:pMatrixData,lpszFileName:LPSTR

.code
main proc uses esi
		local 	argc:PINT,argv:PVOID,env:PVOID,dwNewMode:DWORD,matrixFileA:pFileData,matrixFileB:pFileData,lpStMatrixDataA:pMatrixData,lpStMatrixDataB:pMatrixData,lpStAns:pMatrixData
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
		mov 	matrixFileA,eax
		invoke 	readMatrix,matrixFileA
		mov 	lpStMatrixDataA,eax
		
		invoke 	readFile,[esi]+8
		mov 	matrixFileB,eax
		invoke 	readMatrix,matrixFileB
		mov 	lpStMatrixDataB,eax

		invoke 	mulMatrix,lpStMatrixDataA,lpStMatrixDataB
		mov 	lpStAns,eax

		invoke 	crt_printf,addr s_the_answer_is
		invoke 	printMatrix,lpStAns
		invoke 	saveMatrix,lpStAns,[esi]+12

		invoke 	ExitProcess, 0
main endp

;子程序名:	readFile
;功能:		读取文件并返回文件数据
;入口参数:	lpszFileName=文件名称字符串指针
;出口参数:	eax=fileData结构体指针
readFile proc uses esi,lpszFileName:LPSTR
		local 	pStInputFile:PVOID,lpStFileData:pFileData				;文件指针FILE* pStInputFile,文件数据fileData* pStFileData
		invoke 	crt_malloc,sizeof fileData								;为fileData分配内存
		mov 	lpStFileData,eax
		invoke 	crt_printf,addr s_reading_input_file_s,lpszFileName		;pStInputFile=fopen(lpszFileName)
		invoke 	crt_fopen,lpszFileName,addr s_r
		mov 	pStInputFile,eax
		.if pStInputFile == 0
			invoke 	crt_puts,addr s_open_file_error
			invoke 	ExitProcess, -1
		.endif
		mov 	esi,lpStFileData											;获取文件大小
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
		mov eax,lpStFileData
		ret
readFile endp

;子程序名:	readMatrix
;功能:		根据读取到的文件信息转化成数组信息
;入口参数:	pStFileData=fileData结构体指针
;出口参数:	eax=matrixData结构体指针
readMatrix proc uses esi edi ecx,lpStFileData:pFileData
		local 	matrixX:DWORD,matrixY:DWORD,lpArrY:DWORD,lpMatrix:DWORD,matrixSize:DWORD
		mov 	matrixX,0
		mov 	matrixY,0
		mov 	esi,lpStFileData											;获取行数
		assume 	esi:pFileData
		mov 	esi,[esi].pData
		mov 	ecx,0
		.repeat
			LODSB
			.if al == 10
				inc 	ecx
			.endif
		.until 	al == 0
		inc 	ecx
		mov 	matrixY,ecx
		invoke 	crt_calloc,matrixY,sizeof DWORD
		mov 	lpArrY,eax

		mov 	esi,lpStFileData											;储存行
		assume 	esi:pFileData
		mov 	esi,[esi].pData
		mov 	edi,lpArrY
		mov 	[edi],esi
		add 	edi,4
		.repeat
			LODSB
			.if al == 10
				;mov 	byte ptr [esi-1],0
				mov 	[edi],esi
				add 	edi,4
			.endif
		.until 	al == 0

		mov 	ecx,0													;循环每一行 获取列数
		mov 	esi,lpArrY
		.while 	ecx < matrixY
			push 	ecx

			push 	esi
			assume	eax:DWORD
			mov 	eax,esi
			mov 	esi,[eax]
			mov 	ecx,0
			mov 	ebx,0
			.repeat
				lodsb
				.if al != 32 && al != 9
					.if ebx == 0
						inc 	ecx
						inc 	ebx
					.endif
				.else
					xor 	ebx,ebx 	
				.endif
			.until al==0 || al==10
			.if matrixX == 0
				mov matrixX,ecx
			.else
				.if matrixX != ecx
					invoke 	crt_puts,addr s_matrix_format_error
					invoke 	ExitProcess, -1
				.endif
			.endif
			pop 	esi

			add 	esi,4
			pop 	ecx
			inc 	ecx
		.endw

		mov 	eax,matrixX												;为数组分配内存
		mul 	matrixY
		mov 	matrixSize,eax
		invoke 	crt_calloc,matrixSize,sizeof DWORD
		mov 	lpMatrix,eax

		mov 	ecx,0													;向数组写入数字
		mov 	esi,lpStFileData
		assume 	esi:pFileData
		mov 	esi,[esi].pData
		.while 	ecx < matrixSize
			push 	ecx
			
			mov 	eax,4
			mul 	ecx
			add 	eax,lpMatrix
			invoke 	crt_sscanf,esi,addr s_d,eax

			.repeat
				lodsb
			.until al==0 || al==10 || al==32 || al==9
			.repeat
				lodsb
			.until al!=32 || al!=9 || al!=10
			dec 	esi

			pop 	ecx
			inc 	ecx
		.endw

		invoke 	crt_printf,addr s_this_is_a_d_d_matrix,matrixY,matrixX

		invoke 	crt_malloc,sizeof matrixData
		assume 	eax:pMatrixData
		mov 	ebx,matrixY
		mov 	[eax].Y,ebx
		mov 	ebx,matrixX
		mov 	[eax].X,ebx
		mov 	ebx,lpMatrix
		mov 	[eax].lpData,ebx
		ret
readMatrix endp

;子程序名:	mulMatrix
;功能:		根据提供的矩阵进行矩阵乘运算
;入口参数:	lpSMatrixDataA=第一个矩阵matrixData结构体指针
;			lpSMatrixDataB=第二个矩阵matrixData结构体指针
;出口参数:	eax=matrixData结构体指针
mulMatrix proc uses ebx ecx edx esi edi,lpSMatrixDataA:pMatrixData,lpSMatrixDataB:pMatrixData
		local X1:DWORD,Y1:DWORD,X2:DWORD,Y2:DWORD,lpMatrix:DWORD,tempX:DWORD,tempY:DWORD,tempXY:DWORD
		mov 	esi,lpSMatrixDataA
		mov 	edi,lpSMatrixDataB
		assume 	esi:pMatrixData
		assume 	edi:pMatrixData
		assume 	eax:DWORD
		mov 	eax,[esi].X
		mov 	X1,eax
		mov 	eax,[esi].Y
		mov 	Y1,eax
		mov 	eax,[edi].X
		mov 	X2,eax
		mov 	eax,[edi].Y
		mov 	Y2,eax
		mov 	esi,[esi].lpData
		mov 	edi,[edi].lpData
		assume 	esi:DWORD
		assume 	edi:DWORD

		mov 	eax,X1
		mov 	ebx,Y2
		.if 	eax != ebx
			invoke 	crt_puts,addr s_matrix_cant_be_multiplied
			invoke 	ExitProcess, -1
		.endif
		
		mov 	eax,Y1
		mul 	X2
		invoke 	crt_calloc,eax,sizeof DWORD
		mov 	lpMatrix,eax

		mov  	tempY,0													;A数组Y
		mov 	tempX,0													;B数组X
		mov 	tempXY,0												;A数组X B数组Y

		mov 	eax,tempY												;矩阵乘法
		.while 	eax<Y1
			mov 	eax,tempX
			.while 	eax<X2
				mov 	eax,tempXY
				.while eax<Y2

					mov 	eax,[tempY]
					mov 	ebx,X1
					mul 	ebx
					add 	eax,[tempXY]
					mov 	ebx,4
					mul 	ebx
					add 	eax,esi
					mov 	eax,[eax]
					push 	eax

					mov 	eax,[tempXY]
					mov 	ebx,X2
					mul 	ebx
					add 	eax,[tempX]
					mov 	ebx,4
					mul 	ebx
					add 	eax,edi
					mov 	eax,[eax]
					push 	eax

					pop 	eax
					pop 	ebx
					
					imul 	ebx
					push 	eax

					mov 	eax,[tempY]
					mov 	ebx,X2
					mul 	ebx
					add 	eax,[tempX]
					mov 	ebx,4
					mul 	ebx
					add 	eax,lpMatrix

					pop 	ebx
					add 	[eax],ebx

					mov 	eax,[eax]

					inc 	tempXY
					mov 	eax,tempXY
				.endw
				mov 	tempXY,0
				inc 	tempX
				mov 	eax,tempX
			.endw
			mov tempX,0
			inc 	tempY
			mov 	eax,tempY
		.endw
		mov 	tempY,0
		
		invoke 	crt_malloc,sizeof matrixData
		assume 	eax:pMatrixData
		mov 	ebx,Y1
		mov 	[eax].Y,ebx
		mov 	ebx,X2
		mov 	[eax].X,ebx
		mov 	ebx,lpMatrix
		mov 	[eax].lpData,ebx

		ret
mulMatrix endp

;子程序名:	printMatrix
;功能:		打印矩阵到屏幕
;入口参数:	lpSMatrixData=需要打印的矩阵
printMatrix proc uses ebx ecx edx esi edi,lpSMatrixData:pMatrixData
		assume 	eax:pMatrixData
		mov 	eax,lpSMatrixData
		mov 	ebx,[eax].X
		mov 	ecx,[eax].Y
		mov 	edx,[eax].lpData

		xor 	esi,esi
		.while 	esi<ecx
			xor 	edi,edi
			.while 	edi<ebx
				mov 	eax,[edx]

				pushad
				invoke 	crt_printf,addr s_d,eax
				popad

				add 	edx,4
				inc 	edi
			.endw

			pushad
			invoke 	crt_putchar,10
			popad

			inc 	esi
		.endw
		ret
printMatrix endp

;子程序名:	saveMatrix
;功能:		保存矩阵到文件
;入口参数:	lpSMatrixData=需要保存的矩阵
;			
saveMatrix proc uses ebx ecx edx esi edi,lpSMatrixData:pMatrixData,lpszFileName:LPSTR
		local pStInputFile:PVOID

		invoke 	crt_printf,addr s_saving_to_the_file_s,lpszFileName

		invoke 	crt_fopen,lpszFileName,addr s_w
		mov 	pStInputFile,eax
		.if pStInputFile == 0
			invoke 	crt_puts,addr s_open_file_error
			invoke 	ExitProcess, -1
		.endif


		assume 	eax:pMatrixData
		mov 	eax,lpSMatrixData
		mov 	ebx,[eax].X
		mov 	ecx,[eax].Y
		mov 	edx,[eax].lpData

		xor 	esi,esi
		.while 	esi<ecx
			xor 	edi,edi
			.while 	edi<ebx
				mov 	eax,[edx]

				pushad
				invoke 	crt_fprintf,pStInputFile,addr s_d,eax
				popad

				add 	edx,4
				inc 	edi
			.endw

			pushad
			invoke 	crt_fputc,10,pStInputFile
			popad

			inc 	esi
		.endw

		invoke 	crt_fclose,pStInputFile

		invoke 	crt_printf,addr s_saved
		ret
saveMatrix endp
end main