.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc
includelib kernel32.lib

.data
    msg db "Hello, world!", 0

.code
start:
    push 0
    call ExitProcess

end start