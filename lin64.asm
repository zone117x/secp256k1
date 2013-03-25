	.x64
QTEST	EQU 1
	.code
	;;  Register Layout:
	;;  INPUT: 	rdi	= a.n
	;; 	   	rsi  	= b.n
	;; 	   	rdx  	= this.a
	;;  OUTPUT:	[rbx]
	;;  INTERNAL:	rdx:rax  = multiplication accumulator
	;; 		rsi	 = b.n / t9
	;; 		r8:r9    = c
	;; 		r10-r15  = t0-t5
	;; 		rbx	 = t6
	;; 		rcx	 = t7
	;; 		rbp	 = t8
ExSetMult	PROC C PUBLIC USES rbx rbp r12 r13 r14 r15
	push rdx
	mov r14,[rsi+8*0]
	
	;; c=a.n[0] * b.n[0]
   	mov rax,[rdi+0*8]
	mov rbp,0FFFFFFFFFFFFFh
	mul r14			; rsi=b.n[0]
	mov r15,[rsi+1*8]
	mov r10,rbp
	mov r8,rax
	and r10,rax		; only need lower qword
	shrd r8,rdx,52
	xor r9,r9

	;; c+=a.n[0] * b.n[1] + a.n[1] * b.n[0]
	mov rax,[rdi+0*8]
	mul r15			; b.n[1]
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul r14			; b.n[0]
	mov r11,rbp
	mov rbx,[rsi+2*8]
	add r8,rax
	adc r9,rdx
	and r11,r8
	shrd r8,r9,52
	xor r9,r9
	
	;; c+=a.n[0 1 2] * b.n[2 1 0]
	mov rax,[rdi+0*8]
	mul rbx			; b.n[2]
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul r15			; b.n[1]	
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul r14
	mov r12,rbp		; modulus
	mov rcx,[rsi+3*8]
	add r8,rax
	adc r9,rdx
	and r12,r8		; only need lower dword
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[0 1 2 3] * b.n[3 2 1 0]
	mov rax,[rdi+0*8]
	mul rcx			; b.n[3]
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul rbx			; b.n[2]
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul r15			; b.n[1]
	add r8,rax
	adc r9,rdx
	
	mov rax,[rdi+3*8]
	mul r14			; b.n[0]
	mov r13,rbp             ; modulus
	mov rsi,[rsi+4*8]	; load b.n[4] and destroy pointer
	add r8,rax
	adc r9,rdx
	and r13,r8

	shrd r8,r9,52
	xor r9,r9		


	;; c+=a.n[0 1 2 3 4] * b.n[4 3 2 1 0]
	mov rax,[rdi+0*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul rbx			; b.n[2] 
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul r15			; b.n[1]
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul r14			; b.n[0]
	mov r14,rbp             ; modulus
	add r8,rax
	adc r9,rdx
	and r14,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[1 2 3 4] * b.n[4 3 2 1]
	mov rax,[rdi+1*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul rbx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul r15
	mov r15,rbp		; modulus
	add r8,rax
	adc r9,rdx

	and r15,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[2 3 4] * b.n[4 3 2]
	mov rax,[rdi+2*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul rbx
	mov rbx,rbp		; modulus
	add r8,rax
	adc r9,rdx

	and rbx,r8		; only need lower dword
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[3 4] * b.n[4 3]
	mov rax,[rdi+3*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul rcx
	mov rcx,rbp		; modulus
	add r8,rax
	adc r9,rdx
	and rcx,r8		; only need lower dword
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[4] * b.n[4]
	mov rax,[rdi+4*8]
	mul rsi
	;; mov rbp,rbp		; modulus already there!
	add r8,rax
	adc r9,rdx
	and rbp,r8 
	shrd r8,r9,52
	xor r9,r9		

	mov rsi,r8

	;; *******************************************************
common_exit_norm::
	mov rdi,01000003D10h

	mov rax,r15		; get t5
	mul rdi
	add rax,r10    		; +t0
	adc rdx,0
	mov r10,0FFFFFFFFFFFFFh ; modulus
	mov r8,rax		; +c
	and r10,rax
	shrd r8,rdx,52
	xor r9,r9

	mov rax,rbx		; get t6
	mul rdi
	add rax,r11		; +t1
	adc rdx,0
	mov r11,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r11,r8
	shrd r8,r9,52
	xor r9,r9

	mov rax,rcx    		; get t7
	mul rdi
	add rax,r12		; +t2
	adc rdx,0
	pop rbx			; retrieve pointer to this.a.n	
	mov r12,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r12,r8
	mov [rbx+2*8],r12
	shrd r8,r9,52
	xor r9,r9
	
	mov rax,rbp    		; get t8
	mul rdi
	add rax,r13    		; +t3
	adc rdx,0
	mov r13,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r13,r8
	mov [rbx+3*8],r13
	shrd r8,r9,52
	xor r9,r9
	
	mov rax,rsi    		; get t9
	mul rdi
	add rax,r14    		; +t4
	adc rdx,0
	mov r14,0FFFFFFFFFFFFh	; !!!
	add r8,rax		; +c
	adc r9,rdx
	and r14,r8
	mov [rbx+4*8],r14
	shrd r8,r9,48
	xor r9,r9
	
	mov rax,01000003D1h	
	mul r8		
	add rax,r10
	adc rdx,0
	mov r10,0FFFFFFFFFFFFFh ; modulus
	mov r8,rax
	and rax,r10
	shrd r8,rdx,52
	mov [rbx+0*8],rax
	add r8,r11
	mov [rbx+1*8],r8
	ret
ExSetMult	ENDP






	;;  Register Layout:
	;;  INPUT: 	rdi	= a.n
	;; 	   	rsi  	= this.a
	;;  OUTPUT:	[rsi]
	;;  INTERNAL:	rdx:rax  = multiplication accumulator
	;; 		r8:r9    = c
	;; 		r10-r14  = t0-t4
	;; 		r15	 = a.n[0]*2 / t5
	;; 		rbx	 = a.n[1]*2 / t6
	;; 		rcx	 = a.n[2]*2 / t7
	;; 		rbp	 = a.n[3]*2 / t8
	;; 		rsi	 = a.n[4] / t9
ExSetSquare	PROC C PUBLIC USES rbx rbp r12 r13 r14 r15
	push rsi
	mov rsi,0FFFFFFFFFFFFFh
	
	;; c=a.n[0] * a.n[0]
   	mov r15,[rdi+0*8]
	mov r10,rsi		; modulus 
	mov rax,r15
	mul rax  		; rsi=b.n[0]
	mov rbx,[rdi+1*8]	; a.n[1]
	add r15,r15		; r15=2*a.n[0]
	mov r8,rax
	and r10,rax		; only need lower qword
	shrd r8,rdx,52
	xor r9,r9

	;; c+=2*a.n[0] * a.n[1]
	mov rax,r15
	mul rbx 	
	mov rcx,[rdi+2*8]	; rcx=a.n[2]
	mov r11,rsi 		; modulus
	add r8,rax
	adc r9,rdx
	and r11,r8
	shrd r8,r9,52
	xor r9,r9
	
	;; c+=2*a.n[0]*a.n[2]+a.n[1]*a.n[1]
	mov rax,r15
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,rbx
	mov r12,rsi		; modulus
	mul rax
	mov rbp,[rdi+3*8]	; rbp=a.n[3]
	add rbx,rbx		; rbx=a.n[1]*2
	add r8,rax
	adc r9,rdx

	and r12,r8		; only need lower dword
	shrd r8,r9,52
	xor r9,r9		

	;; c+=2*a.n[0]*a.n[3]+2*a.n[1]*a.n[2]
	mov rax,r15
	mul rbp
	add r8,rax
	adc r9,rdx

	mov rax,rbx		; rax=2*a.n[1]
	mov r13,rsi		; modulus
	mul rcx
	mov rsi,[rdi+4*8]	; rsi=a.n[4] / destroy constant
	add r8,rax
	adc r9,rdx
	and r13,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=2*a.n[0]*a.n[4]+2*a.n[1]*a.n[3]+a.n[2]*a.n[2]
	mov rax,r15		; last time we need 2*a.n[0]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,rbx
	mul rbp
	mov r14,0FFFFFFFFFFFFFh ; modulus
	add r8,rax
	adc r9,rdx

	mov rax,rcx
	mul rax
	add rcx,rcx		; rcx=2*a.n[2]
	add r8,rax
	adc r9,rdx
	and r14,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=2*a.n[1]*a.n[4]+2*a.n[2]*a.n[3]
	mov rax,rbx
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,rcx
	mul rbp
	mov r15,0FFFFFFFFFFFFFh ; modulus
	add r8,rax
	adc r9,rdx
	and r15,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=2*a.n[2]*a.n[4]+a.n[3]*a.n[3]
	mov rax,rcx		; 2*a.n[2]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,rbp		; a.n[3]
	mul rax
	mov rbx,0FFFFFFFFFFFFFh ; modulus
	add r8,rax
	adc r9,rdx
	and rbx,r8		; only need lower dword
	lea rax,[2*rbp]
	shrd r8,r9,52
	xor r9,r9		

	;; c+=2*a.n[3]*a.n[4]
	mul rsi
	mov rcx,0FFFFFFFFFFFFFh ; modulus
	add r8,rax
	adc r9,rdx
	and rcx,r8		; only need lower dword
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[4]*a.n[4]
	mov rax,rsi
	mul rax
	mov rbp,0FFFFFFFFFFFFFh ; modulus
	add r8,rax
	adc r9,rdx
	and rbp,r8 
	shrd r8,r9,52
	xor r9,r9		

	mov rsi,r8

	;; *******************************************************
	jmp common_exit_norm
ExSetSquare	ENDP
	end

	