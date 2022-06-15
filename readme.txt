编译环境masm32
环境变量include：masm32 include路径
环境变量lib：masm32 lib路径
编译指令：ml /c /coff Main.asm
链接指令：link /subsystem:CONSOLE /out:main.exe Main.obj
运行方式：cmd输入main.exe ./test_file/matrix1.txt ./test_file/matrix2.txt ./test_file/output.txt

输入文件格式说明
矩阵结尾无空行
每行结尾无空格