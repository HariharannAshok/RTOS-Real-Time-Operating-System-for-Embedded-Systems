*-----------------------------------------------------------
* Title      : RTS
* Written by : Meghana,Hariharan,Mahalakshmi
* Date       : Jan 25
* Description: Time Slicing and Multitasking RunTime System 
*-----------------------------------------------------------
                                ; system call equates
sys     equ     0               ; system call trap (trap 0)
syscr   equ     1               ; create new task
sysdel  equ     2               ; delete task
syswtmx equ     3               ; wait on mutex
syssgmx equ     4               ; signal mutex
sysinmx equ     5               ; initialise mutex 
syswttm equ     6               ; wait on timer

usrcode equ     $1000           ;address of user task 0
usrstk  equ     $8000           ;address of user stack


ntcblst equ     8               ;number of records in tcb list

tcb     org     0               ;tcb record
tcbd0   ds.l    1               ; D register save
tcbd1   ds.l    1
tcbd2   ds.l    1
tcbd3   ds.l    1
tcbd4   ds.l    1
tcbd5   ds.l    1
tcbd6   ds.l    1
tcbd7   ds.l    1
tcba0   ds.l    1               ; A register save
tcba1   ds.l    1
tcba2   ds.l    1
tcba3   ds.l    1
tcba4   ds.l    1
tcba5   ds.l    1
tcba6   ds.l    1
tcba7   ds.l    1
tcbsr   ds.l    1               ; SR (status reg) save
tcbpc   ds.l    1               ; PC save          
tcbnext ds.l    1               ; link to next record
tcbused ds.l    1               ; record in use flag
tcbwtim ds.l    1               ; timer wait expiry time
tcblen  equ     $60               ; length of tcb record

;******************************************************************************
rts                                     ;RUNTIME SYSTEM
;******************************************************************************

;******************************************************************************
                                        ;INTERRUPT VECTORS
;******************************************************************************

        org     0
        
        dc.l    usrstk                  ; initial SP
        dc.l    res                     ; reset
        ds.b    $5C
        dc.l    fltint                  ; interrupt 1 (timer)
        ds.b    $18
        dc.l    flsint                  ; trap 0 (system call)
        
;*******************************************************************************        
res                                     ;RESET
;*******************************************************************************

                    or      #%0000011100000000,sr
                    move.l  #0, d0
                    move.l  d0, time
                    move.l  #$1, mutex 
                    
                    move.l  #$12000,a0
                    move.l  d0, tcbwtim(a0)
                    move.l  #0, d0
                    move.l  #ntcblst, d1
                    
init:               move.l  d0, tcbused(a0)
                    move.l  d0, tcbwtim(a0)
                    add.l   #tcblen, a0
                    sub.l   #1, d1
                    bne     init
                    
                    
                    move.l  #$12000,a0
                    move.l  a0,rdytcb
                    move.l  #usrcode, d0
                    move.l  d0, tcbpc(a0)
                    move.l  #$00002000, d0
                    move.l  d0, tcbsr(a0)
                    
                    
                    move.l  #1, d0
                    move.l  d0, tcbused(a0)
                    move.l  #$12000,d0
                    move.l  d0,tcbnext(a0)
                    move.l  #0,wtlsln
                    move.l  #0,wttcb
                    and     #%1111100011111111, sr
                    
                    jmp     usrcode
                    
        
        
;*******************************************************************************        
flih                                    ;FIRST-LEVEL INTERRUPT HANDLER
;*******************************************************************************

fltint                                              ;ENTRY FROM TIMER INTERRUPT  
                    move.l  d0,d0sav                ;save D0
                    move.l  #$0,d0                  ;set id = 0
                    move.l  d0,id
                    move.l  d0sav,d0                ;restore D0
                    move.l  wttcb, a0 
                    
               
                    
                    bra     fl1  

        
     
        
        
        
flsint                                              ;ENTRY FROM TRAP (SOFTWARE INTERRUPT)
                    or      #%0000011100000000,sr   ;disable hardware interrupts
                    move.l  d0,id                   ;store id
                    bra     fl1
       
fl1                 move.l  a0,a0sav                ;save working reg
        
                    move.l  rdytcb,a0               ;A0 ^ 1st ready tcb (ie running tcb)
            
                    move.l  d0,tcbd0(a0)            ;store registers
                    move.l  d1,tcbd1(a0)       
                    move.l  d2,tcbd2(a0)
                    move.l  d3,tcbd3(a0) 
                    move.l  d4,tcbd4(a0)
                    move.l  d5,tcbd5(a0)       
                    move.l  d6,tcbd6(a0)
                    move.l  d7,tcbd7(a0)
                    move.l  a0sav,d0 
                    move.l  d0,tcba0(a0)
                    move.l  a1,tcba1(a0)       
                    move.l  a2,tcba2(a0)
                    move.l  a3,tcba3(a0) 
                    move.l  a4,tcba4(a0)
                    move.l  a5,tcba5(a0)       
                    move.l  a6,tcba6(a0)

                    move    (sp),d0                 ;pop and store SR
                    add.l   #2,sp              
                    move.l  d0,tcbsr(a0)
        
                    move.l  (sp),d0                 ;pop and store PC
                    add.l   #4,sp
                    move.l  d0,tcbpc(a0)
        
                    move.l  a7,tcba7(a0)            ;store SP 
                    
;******************************************************************************
                    move.l  wttcb,d0
                    move.l  d0,a0
                    cmp     #0,d0
                    beq     serv
DecrementWaitTimes: move.l  tcbwtim(a0),d1          ; Load the wait time of the current task
                    cmp     #0,d1
                    beq     NextTask
                    sub.l   #1, d1                  ; Decrement the wait time
                    move.l  d1, tcbwtim(a0) 
                    
                    cmp     #0,d1
                    bne     NextTask
                    
                    move.l  tcbnext(a0),a1           ; Get the next task in the wait queue
                    move.l  a1, wttcb                ; Update the head of the wait queue
                    move.l  rdytcb,a1
                    move.l  rdytcb, tcbnext(a0)      ; Link the task to the ready queue
                    move.l  a0,tcbnext(a1)
                    move.l  a0, rdytcb  
                    bra     serv 
                    
NextTask:           move.l  tcbnext(a0),a0           ; Move to the next task in the wait queue
                    move.l  a0,d3
                    tst.l   d3                       
                    bne     DecrementWaitTimes
        
;******************************************************************************
serv                                    ;SERVICE ROUTINES
;******************************************************************************

                         move.l  rdytcb,a0
                         move.l  id,d0
                         cmp.l   #1,d0
                         beq     Create_task
                         cmp.l   #2,d0
                         beq     Delete_task
                         cmp.l   #3,d0
                         beq     syswaitmx
                         cmp.l   #4,d0
                         beq     syssiggmx
                         cmp.l   #5,d0
                         beq     sysinimx 
                         cmp.l   #6,d0
                         beq     syswaittime
                         bra     sched
                         
                         
***************************CREATE TASK*****************************************

Create_task:             move.l  id, d0
                         
                         
Search_unused_tcb:       move.l  #$12000,a0
                         move.l  #ntcblst, d2
                           
Search_loop:             cmp.l   #0, tcbused(a0)
                         beq     Tcb_found
                         add.l   #tcblen, a0
                         sub.l   #1, d2
                         bne     Search_loop
                         
Tcb_found:               move.l  d1, tcbpc(a0)
                         move.l  #$00002000, tcbsr(a0)
                         move.l  #1, d3
                         move.l  d3, tcbused(a0)
                         move.l  rdytcb,a1
                         move.l  tcbnext(a1),d0
                         move.l  a0,tcbnext(a1)
                         move.l  d0,tcbnext(a0)
                         move.l #$01000000,tcba7(a0)
                         
                         bra     sched
                         
***************************DELETE TASK*****************************************

Delete_Task:             move.l  #$12000, a0
                         move.l  #ntcblst, d1
                         move.l  #0, d1
                         
Search_Task:             cmp.l   #1,tcbused(a0)
                         beq     Task_Found
                         add.l   #tcblen, a0
                         sub.l   #1, d1
                         bne     Search_Task
                         
Task_Found:              move.l  #0, tcbused(a0)
                         move.l  tcbnext(a0), a1
                         move.l  a0, (a1)
                         move.l  a1, tcbnext(a0)
                         bra     sched      
  
************************WAIT MUTEX*********************************************

syswaitmx:       move.l  #$0,d0
                 move.l  mutex, d0       
                 cmp.l   #1, d0                
                 beq     MutexAvailable       
        
                 move.l  rdytcb, a1
                 move.l  tcbnext(a1),a2
                 
FindTaskLoop:    cmp.l   a2, a0               
                 beq     FoundTask            
                 move.l  a2, a1               
                 move.l  tcbnext(a2),a2 
                 move.l  a2,d4     
                 tst.l   d4                   
                 bne     FindTaskLoop         
                 bra     EndWaitMutex 
                 
FoundTask:       move.l  wtlsln,d0
                 cmp     #0,d0
                 beq     ft1
                 move.l  tcbnext(a2),tcbnext(a1)
                 move.l  wttcb, tcbnext(a0)  
ft1:             move.l  a0, wttcb
                 move.l  wtlsln,d0
                 add     #1,d0
                 move.l  d0,wtlsln           
                 bra     EndWaitMutex         

MutexAvailable:  move.l  #0, mutex 
                 bra     sched
    
EndWaitMutex:    bra     sched


**************************SIGNAL MUTEX******************************************
       
syssiggmx:       move.l  wtlsln, d1           
                 cmp     #0,d1                  
                 beq     ClearWaitList
                 move.l  wttcb, a1

                 move.l  tcbnext(a1),wttcb
                 move.l  tcbnext(a0),tcbnext(a1)
  
                 move.l  a1,tcbnext(a0)
                 move.l  wtlsln,d0
                 sub     #1,d0
                 move.l  d0,wtlsln
                 bra     sched 
                 
ClearWaitList:   clr.l   wttcb                
                

NoWaitingTask:   move.l  #1, mutex

EndSignalMutex:  bra     sched

************************INITIALISE MUTEX****************************************

sysinimx:         move.l  d1, mutex
                  move.l  mutex,d0
                  cmp.l   #1, d0
                  beq     disp
                  cmp.l   #0,d0
                  beq     disp
                  bra     sched


************************WAIT TIME***********************************************

syswaittime:        move.l  rdytcb, a0      
   	                move.l  d1, tcbwtim(a0) 

                    move.l  tcbnext(a0),a1     
                    move.l  a1, rdytcb
                    
                    move.l  a0,d0
syswaittime0        move.l  tcbnext(a0),d1
                    cmp     d0,d1
                    beq     syswaittime1
                    move.l  d1,a0
                    bra     syswaittime0
syswaittime1:       move.l  a0,a1
                    move.l  d0,a0
                    move.l  tcbnext(a0),tcbnext(a1)
                    
                    move.l  wttcb, tcbnext(a0) 
                    move.l  a0, wttcb

                    move.l  wttcb, d4
                    cmp     #0,d4                      
                    beq     NoTasksWaiting 
                    
NoTasksWaiting:
                    
                    bra     sched          

          

       
;*******************************************************************************
sched                                   ;SCHEDULER  
;*******************************************************************************
        move.l   rdytcb,a0
        move.l   tcbnext(a0), a0
        move.l   a0, rdytcb

;*******************************************************************************        
disp                                    ;DISPATCHER 
;*******************************************************************************

        move.l  rdytcb,a0               ;A0 ^ new running tcb
        move.l  tcbd1(a0),d1            ;restore registers      
        move.l  tcbd2(a0),d2
        move.l  tcbd3(a0),d3 
        move.l  tcbd4(a0),d4
        move.l  tcbd5(a0),d5       
        move.l  tcbd6(a0),d6
        move.l  tcbd7(a0),d7
        move.l  tcba1(a0),a1       
        move.l  tcba2(a0),a2
        move.l  tcba3(a0),a3 
        move.l  tcba4(a0),a4
        move.l  tcba5(a0),a5       
        move.l  tcba6(a0),a6
        move.l  tcba7(a0),a7

        sub.l   #4,sp                   ;push PC
        move.l  tcbpc(a0),d0            
        move.l  d0,(sp)   

        sub.l   #2,sp           
        move.l  tcbsr(a0),d0            ;push SR
        move    d0,(sp)
        
        move.l  tcbd0(a0),d0            ;restore remaining registers
        move.l  tcba0(a0),a0
        
        rte                             ;return

;*******************************************************************************
                                        ;RTS variables
;*******************************************************************************

tcblst  ds.b    tcblen*ntcblst          ;tcb list
rdytcb  ds.l    1                       ;^ ready tcb list
wttcb   ds.l    1                       ;^ waiting tcb
a0sav   ds.l    1                       ;A0 temporary save
d0sav   ds.l    1                       ;D0 temporary save
id      ds.l    1                       ;function id
time    ds.l    1                       ;system time
mutex   ds.l    1                       ;mutex value
wtlsln  ds.l    1                       ;holds the length of waiting list
        
;*******************************************************************************
                                        ;USER APPLICATION TASKS
;*******************************************************************************
 org     usrcode

led     equ     $e00010         ;led
sw      equ     $e00014         ;switch

t0:     move.l  #syscr,d0
        move.l  #t1,d1
        move.l  #$4000,d2
        trap    #sys
      
t00:    move.l  #$01,d1
        move.b  d1,led
        bra     t00
 
t1:     move.b  sw,d0
        and.l   #1,d0
        beq     t10
        move.l  #$02,d1
        move.b  d1,led
        bra     t1
t10:    move.l  #$00,d1
        move.b  sw,d0
        and.b   #1,d0
        beq     t10
      
        move.l  #syswttm,d0
        move.l  #3,d1
        trap    #sys
t11:    move.l  #$02,d1
        move.b  d1,led
        bra     t11

  END res
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
