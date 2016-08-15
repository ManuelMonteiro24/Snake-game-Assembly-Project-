; FILE:    lab03.as
; VERSION: 1.0
; AUTHOR:  Paulo Lopes
; EMAIL:   paulo.lopes@ist.utl.pt

SP_INICIAL      EQU     FDFFh
DELAYVALUE1     EQU     0800h
INT_MASK_ADDR   EQU     FFFAh
INT_MASK        EQU     1000010000000001b
mascara         EQU     1001110000010110b ;NI usado na rotina que gera um
                                          ;numero aleatório
; I/O a partir de FF00H
DISP7S1         EQU     FFF0h
DISP7S2         EQU     FFF1h
DISP7S3         EQU     FFF2h
DISP7S4         EQU     FFF3h
LCD_WRITE	EQU	FFF5h
LCD_CURSOR	EQU	FFF4h	
LEDS            EQU     FFF8h
INTERRUPTORES   EQU     FFF9h
IO_CURSOR       EQU     FFFCh
IO_TECLADO      EQU     FFFFh
IO_TESTET       EQU     FFFDh
IO_WRITE        EQU     FFFEh
TimerValue      EQU     FFF6h
TimerControl    EQU     FFF7h
TimeLong        EQU     0001h
EnableTimer     EQU     0001h
LIMPAR_JANELA   EQU     FFFFh

; Interrupcoes
BOTAO_NI0       EQU     FE00h
BOTAO_NIA       EQU     FE0Ah

XY_INICIAL      EQU     0614h
FIM_TEXTO       EQU     '.'

                ORIG    8000h

VarTexto1       STR     'Prima IO para iniciar o jogo' ,FIM_TEXTO
VarTexto2       STR     '|' ,FIM_TEXTO
VarTexto5       STR     '@' ,FIM_TEXTO
VarTexto3       STR     '-' ,FIM_TEXTO
fim_texto       STR     'GAME OVER' ,FIM_TEXTO
fim_texto_1     STR     'YOU WIN!!!!' ,FIM_TEXTO
LCDinic         STR     '0:00',FIM_TEXTO
Flag_N0         WORD    0
Flag_pausa      WORD    0

Flag_vel0       WORD    0 ;Flags associadas a velociade da cobra
Flag_vel1       WORD    0
Flag_vel2       WORD    0

Flag_right      WORD    0 ;Flags associadas a direcçao da cobra
Flag_left       WORD    0
Flag_down       WORD    0
Flag_up         WORD    0

aletor_numb     WORD    E003h

segundos_0      TAB     1 ;posicoes de memoria que guardam o tempo
segundos_1      TAB     1 ;de jogo
minutos_0       TAB     1
minutos_1       TAB     1

Cobracorpo      TAB     1  ;espaco de memoria onde fica guardado
                           ;o tamanho de do corpo da cobra

Cobracoord      TAB     10 ;espaço de memoria onde estao guardadas
                           ;as 10 posicoes do corpo da cobra 

Apaga           TAB     1  ;espaço de memoria onde fica guardada
                           ;a posicao do corpo da cobra a ser apagado

PosicaoComida   TAB     1  ;espaco de memoria onde fica guardada
                           ;a posicao da comida

Score           TAB     1 ;posicoes de memoria que guardam o score
ScoreLEDS       TAB     1

conta_msegundos TAB     1 
conta_msegundos1 TAB    1
conta_msegundos2 TAB    1

; Tabela de interrupcoes
                ORIG    FE0Fh
INT15           WORD    TimerSub 

; Codigo
                ORIG    0000h
                JMP     Inicio

;===============================================================================
;Rotina_NI0 : Rotina de interrupçao do botao I0, que da inicio ao jogo. A este
;botao associamos a Flag_N0, quando o botao for pressiondo esta passa de 0 a 1 
;===============================================================================
Rotina_NI0:     PUSH R1
                MOV R1,1
                MOV M[Flag_N0],R1
                POP R1 
                RTI
;===============================================================================
;Rotina_timer : Rotina do temporizador, escreve o tempo que decorre desde o
;               inicio do jogo no LCD e permite mudar a velocidade da cobra
;               consoante os interruptores ligados.
;===============================================================================
TimerSub:       PUSH R1
                PUSH R2
                MOV R1,TimeLong
                MOV M[TimerValue],R1
                MOV R1,EnableTimer
                MOV M[TimerControl],R1

                MOV R1,M[Flag_N0] ;Se a flag_N0, associada ao inicio do jogo, ainda
                CMP R1,R0         ;nao estiver a 1 o tempo de jogo nao é incrementado.
                JMP.Z fimtimer

                MOV R1,M[Flag_pausa] ;Se o jogo estiver parado, Flag_pausa a 1,
                CMP R1,R0            ;é também parada a contagem do tempo.
                JMP.NZ fimtimer 
                
                INC M[conta_msegundos1] 
                INC M[conta_msegundos2]


inc_segundos_0: INC M[conta_msegundos]  ;o temporizador funciona com um tempo
                MOV R1,M[conta_msegundos] ;de 0.1s, para que este conte 1s
                MOV R2,10               ;o timer que fazer 10 contagens.
                CMP R2,R1               ;Entao sempre que o temporizador acaba
                JMP.NZ fimtimer         ;uma contagem, o "conta_msegundos" é incrementado
                MOV M[conta_msegundos],R0 ;quando esta variavel tiver o valor 10
                                        ;este contou 1 segundo e ai entao vai-se incrementar 
                                        ;vai-se incrementar o temporizador do LCD
                MOV R1,M[segundos_0]
                MOV R2,003AH        
                INC R1               
                MOV M[segundos_0],R1
                CMP R1,R2           
                BR.Z inc_segundos_1 
                MOV R2, 8005h       
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
                JMP fimtimer
                
inc_segundos_1: MOV R1,0030h       ;se o primeiro bit dos segundos passou dos 9,
                MOV M[segundos_0],R1 ;a varivel associda a este estiver a 10(3Ah em ASCII)
                MOV R1,M[segundos_1] ;entao vai se incrementar o segundo bit dos segundos
                INC R1               ;e passar a 0 o primeiro bit (0:09 -> 0:10)
                MOV M[segundos_1],R1
                MOV R2,0036h
                CMP R1,R2
                BR.Z inc_minutos_0
                MOV R1,M[segundos_0]
                MOV R2, 8005h
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
                MOV R1,M[segundos_1]
                MOV R2, 8004h
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
                JMP fimtimer

inc_minutos_0:  MOV R1,0030h       ;se o segundo bit dos segundos passou dos 5,
                MOV M[segundos_0],R1 ;a varivel associda a este estiver a 6 (36h em ASCII)
                MOV M[segundos_1],R1 ;entao vai se incrementar o bit dos minutos
                MOV R1,M[minutos_0]  ;e passar os dois bits dos segundos (0:59 -> 1:00)
                INC R1
                MOV M[minutos_0],R1 
                MOV R1,M[segundos_0]
                MOV R2, 8005h
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
                MOV R1,M[segundos_1]
                MOV R2, 8004h
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
                MOV R1,M[minutos_0]
                MOV R2, 8002h
                MOV M[LCD_CURSOR],R2
                MOV M[LCD_WRITE],R1
fimtimer:       POP R2  
                POP R1 
                RTI

;===============================================================================
;Rotina_NIA :Rotina de interrupçao do botao IA, que pausa o jogo. A este
;botao associamos a Flag_pausa, quando o botao for pressiondo se a Flag estiver
;a 1, vai passar a 0, caso esteja a 0 vai passar a 1.
;===============================================================================
Rotina_NIA:     PUSH R1
                MOV R1,M[Flag_pausa]
                CMP R1,1
                BR.NZ para              
                MOV M[Flag_pausa],R0
                BR fim_pausa
para:           MOV R1,1
                MOV  M[Flag_pausa],R1
fim_pausa:      POP R1 
                RTI              
;===============================================================================
; LimpaJanela: Rotina que limpa a janela de texto.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
LimpaJanela:    PUSH R2
                MOV  R2, LIMPAR_JANELA
		MOV  M[IO_CURSOR], R2
                POP  R2
                RET
;===============================================================================
; LimpalCD: Rotina que limpa o LCD.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
LimpaLCD:       PUSH R1
                MOV  R1,8020h
		MOV  M[LCD_CURSOR], R1
                POP  R1
                RET
;===============================================================================
; DELAY: Rotina que permite gerar um atraso.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
DELAY:          PUSH R1
                MOV  R1, DELAYVALUE1
DelayLoop:      DEC  R1
                BR.NZ DelayLoop
                POP  R1
                RET
;===============================================================================
; EscString: Rotina que efectua a escrita de uma cadeia de caracter, terminada
;            pelo caracter FIM_TEXTO, na janela de texto numa posicao 
;            especificada. Pode-se definir como terminador qualquer caracter 
;            ASCII. 
;               Entradas: pilha - posicao para escrita do primeiro carater 
;                         pilha - apontador para o inicio da "string"
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
EscString:      PUSH    R1
                PUSH    R2
		PUSH    R3
                MOV     R2, M[SP+6]   ; Apontador para inicio da "string"
                MOV     R3, M[SP+5]   ; Localizacao do primeiro carater
Ciclo:          MOV     M[IO_CURSOR], R3
                MOV     R1, M[R2]
                CMP     R1, FIM_TEXTO
                BR.Z    FimEsc
                CALL    EscCar
                INC     R2
                INC     R3
                BR      Ciclo
FimEsc:         POP     R3
                POP     R2
                POP     R1
                RETN    2                ; Actualiza STACK
;===============================================================================
; EscCar: Rotina que efectua a escrita de um caracter para o ecran.
;         O caracter pode ser visualizado na janela de texto.
;               Entradas: R1 - Caracter a escrever
;               Saidas: ---
;               Efeitos: alteracao da posicao de memoria M[IO]
;===============================================================================

EscCar:         MOV     M[IO_WRITE], R1
                RET
;===============================================================================
; EscCarLCD: Rotina que efectua a escrita de um caracter para o LCD.
;            O caracter pode ser visualizado no LCD.
;               Entradas: R1 - Caracter a escrever
;               Saidas: ---
;               Efeitos: alteracao da posicao de memoria M[IO]
;===============================================================================
EscCarLCD:      MOV     M[LCD_WRITE], R1
                RET
;===============================================================================
; EscStringLCD: Rotina que efectua a escrita de uma cadeia de caracteres, terminada
;               pelo caracter FIM_TEXTO, no LCD numa posicao 
;               especificada. Pode-se definir como terminador qualquer caracter 
;               ASCII. 
;               Entradas: pilha - posicao para escrita do primeiro carater 
;                         pilha - apontador para o inicio da "string"
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
EscLCD:         PUSH    R1
                PUSH    R2
		PUSH    R3
                MOV     R2, M[SP+6]   ; Apontador para inicio da "string"
                MOV     R3, M[SP+5]   ; Localizacao do primeiro carater
CicloLCD:       MOV     M[LCD_CURSOR], R3
                MOV     R1, M[R2]
                CMP     R1, FIM_TEXTO
                BR.Z    FimEscLCD
                CALL    EscCarLCD
                INC     R2
                INC     R3
                BR      CicloLCD
FimEscLCD:      POP     R3
                POP     R2
                POP     R1
                RETN    2                ; Actualiza STACK
;===============================================================================
; limites_vert: Rotina que desenha os limites verticais do campo, chao e tecto,
;               na janela de texto. Esta rotina vai receber a posicao das colunas
;               em qual vao ser escritas as linhas verticais.
;===============================================================================
limites_vert:  PUSH R1
               PUSH R4
               PUSH R5
               PUSH R6
limites_vert1: MOV R1,R4      ;em R4 esta indicada a coluna onde queremos escrever
               PUSH VarTexto2
               PUSH R1
               CALL EscString ;escreve ponto
               ADD R4,0100h   ;incrementa a coordenada dos y onde vai ser esrcito
                              ;o ponto
               MOV R5,R4
               MOV R6,1700H   ;ultima posicao dos Y (linha 23), adiciona-se a esta
               ADD R6,M[SP+6] ;a coluna onde estamos a escrever
               CMP R5,R6      
               BR.NZ limites_vert1 ;se a posicao incrementada for igual à ultima
               POP R6              ;da linha sai-se do ciclo senao volta-se a incrementar
               POP R5              ;a linha da posicao e escreve-se um novo ponto
               POP R4
               POP R1
               
               RETN 1
;===============================================================================
; limites_horiz: Rotina que desenha os limites horizontais do campo, paredes, 
;                na janela de texto. Esta rotina vai receber a posicao das linhas
;                em qual vao ser escritas as linhas horizontais.
;===============================================================================
limites_horiz: PUSH R1
               PUSH R4
               PUSH R5
               PUSH R6
limites_horiz1:MOV R1,R4        ;em R4 esta indicada a linha onde queremos escrever
               PUSH VarTexto3
               PUSH R1
               CALL EscString   ;escreve ponto
               ADD R4,0001h     ;incrementa a coordenada dos x onde vai ser esrcito                ;
               MOV R5,R4        ;o ponto
               MOV R6,004FH     ;ultima posicao dos X (coluna 80), adiciona-se a esta
               ADD R6,M[SP+6]   ;a linha onde estamos a escrever
               CMP R5,R6
               BR.NZ limites_horiz1 ;se a posicao incrementada for igual à ultima
               POP R6               ;da linha sai-se do ciclo senao volta-se a incrementar
               POP R5               ;a coluna da posicao e escreve-se um novo ponto
               POP R4
               POP R1
               RETN 1
;===============================================================================
; limites_jogo: Rotina que desenha os limites verticais e horizontais do campo
; na janela de texto.
;===============================================================================
limites_jogo:  PUSH R4
               MOV R4,R0          ;primeira linha
               PUSH R4
               CALL limites_horiz ;desenho do chao
               MOV R4,1700h       ;ultima linha
               PUSH R4
               CALL limites_horiz ;desenho do tecto
               MOV R4,R0          ;primeira coluna
               PUSH R4
               CALL limites_vert ;desenho da parede esquerda
               MOV R4,004Fh       ;ultima coluna
               PUSH R4
               CALL limites_vert  ;desenho da parede direita
               POP R4
               RET
;===============================================================================
; EscCobra: Rotina que desenha a um 'o' na posicao da cabeca da cobra e desenha 
; um ' ' (apaga) a ultima posicao do corpo da cobra.              
;===============================================================================
EscCobra:       PUSH    R1
                PUSH    R2
                MOV     R1, 'O' ;caracter do corpo da cobra
                MOV     R2, M[Cobracoord]   
                MOV     M[IO_CURSOR], R2
                MOV     M[IO_WRITE],R1
                MOV     R1,' ' ;um espaco que serve para escrever por cima do 'o'
                MOV     R2,M[Apaga] ;do ultimo corpo da cobra
                
                CMP     R2,R0       ;se a posicao que estiver no apagar for 0
                                    ;nao se escreve na posicao apagar
                BR.Z    fim_esc_cobra
                MOV     M[IO_CURSOR], R2
                MOV     M[IO_WRITE],R1
fim_esc_cobra:  POP     R2
                POP     R1
                RET
;===============================================================================
; mov_cobra: Rotina que faz mover a cobra. em funcao do tamanho da cobra, guardado
;em memória na posicao "Cobracorpo", e um funçao da posicao da cabeca da cobra que
;também e guardada em memória sempre na posicao "Cobracoord".
;===============================================================================
mov_cobra:     PUSH R1
               PUSH R2
               PUSH R3
               MOV R1,M[Cobracorpo]
               DEC R1
               ADD R1,Cobracoord ;em R1 vai ficar o endereço da
                                 ;posicao do ultimo corpo da cobra
               MOV R3,R1
               MOV R2,R1

               MOV R1,M[R1]      
               MOV M[Apaga],R1   ;vai se mover para o posicao de memoria
                                 ;"Apaga" a posicao do ultimo corpo da cobra.
               DEC R3            ;Em R3 vai ficar o endereço da posicao do
                                 ;penultimo corpo da cobra.

rotate:        MOV R1,M[R3]      ;a posicao do penultimo corpo da cobra
               MOV M[R2],R1      ;vai ser passado para o endereco da ultima posicao
               DEC R3            ;do corpo da cobra, esta passagem de posicoes vai
               DEC R2            ;acontecer com todos os corpos da cobra 
                                 ;ate que se chege ao endereço da posicao 
               CMP R2,Cobracoord ;da cabeça da cobra, pois todas as posicoes do corpo já
               BR.NZ rotate      ;foram actualizadas
               POP R3
               POP R2
               POP R1
               RET
;===============================================================================
;start_cobra: Rotina que inicializa a cobra, a comida, os Displays, os LEDS e o LCD
;===============================================================================
start_cobra:  PUSH R1
              PUSH R2
              MOV R2,0925h          ;cobra começa na posicao 0925h
              MOV M[Cobracoord],R2 
              MOV R2,0002h
              MOV M[Cobracorpo],R2  ;cobra começa com o tamanho 2
              MOV R2,0000000000000001b
              MOV M[ScoreLEDS],R2   ;o score dos LEDS começa a 1
              MOV M[Score],R0       ;o score dos displays começa a 0
              MOV M[DISP7S1],R0
              MOV M[DISP7S2],R0
              MOV M[DISP7S3],R0
              MOV M[DISP7S4],R0     ;os displays começam todos a 0
              MOV M[LEDS],R0        ;os LEDS começam todos apagados        
              CALL EscCobra         
              CALL comida_print     ;imprime primeira comida
              MOV R1,M[segundos_1] 
              MOV R2, 8004h
              MOV M[LCD_CURSOR],R2
              MOV M[LCD_WRITE],R1
              MOV R1,003Ah
              MOV R2,8003h
              MOV M[LCD_CURSOR],R2
              MOV M[LCD_WRITE],R1
              MOV R1,M[minutos_0]
              MOV R2,8002h
              MOV M[LCD_CURSOR],R2
              MOV M[LCD_WRITE],R1  ;imprime "0:00" no LCD,
              POP R2
              POP R1
              JMP go_left
;===============================================================================
;game_over: Rotina que limpa a janela de texto e escreve "GAME OVER".
;===============================================================================
game_over:    CALL LimpaJanela
              PUSH fim_texto
              PUSH XY_INICIAL
              CALL EscString ;escreve na janela "GAME OVER"
              CALL DELAY
              CALL DELAY
              MOV M[Flag_N0],R0 ; retorno da Flag_NO a zero 
              JMP Inic ; volta ao inicio ficando a espera que o jogador 
                       ; pressione o botao I0, que a FLag_NO passe a 1
                       ; recomecando assim o jogo 
;===============================================================================
;game_win: Rotina que limpa a janela de texto e escreve "YOU WIN".
;===============================================================================
game_win:     CALL LimpaJanela
              PUSH fim_texto_1
              PUSH XY_INICIAL
              CALL EscString ;escreve na janela "YOU WIN"
              CALL DELAY
              CALL DELAY
              MOV M[Flag_N0],R0 ; retorno da Flag_NO a zero
              JMP Inic ; volta ao inicio ficando a espera que o jogador 
                       ; pressione o botao I0, que a FLag_NO passe a 1
                       ; recomecando assim o jogo 
;===============================================================================
;verif_pausa: Rotina que verifica se a Flag_pausa esta a 1, se assim for o programa
;            mantém-se parado no ciclo, até que a "Flag_pausa" (associada ao botao IA) 
;            volte a 0.
;===============================================================================
verif_pausa:  PUSH R1
verif_pausa1: MOV R1,M[Flag_pausa]
              CMP R1,R0
              BR.NZ verif_pausa1
              POP R1
              RET
;===============================================================================
;velocidades:Rotina que define qual a velocidade da cobra, com base no valor
;            dos interruptores. Nesta rotina utilizamos duas "variaveis" 
;            (conta_msegundos1 e conta_msegundos2) que sao incrementadas a
;            a cada ciclo do timer, de forma conseguirmos contar 0.2s e 0.3s.
;=============================================================================== 
velocidades:  MOV R1,M[INTERRUPTORES]
              MOV R2,R0
              CMP R1,R2
              BR.NZ flag_vel1_2
              MOV M[Flag_vel0],R1
              MOV M[Flag_vel1],R0
              MOV M[Flag_vel2],R0 ;se o estado dos interruptores for 0     
                                  ;a velocidade da cobra vai ser 0.1s
                                  ;e a Flag_vel0 vai passar a 1
flag_vel1_2:  MOV R1,M[INTERRUPTORES]
              MOV R2,00000001b
              CMP R1,R2
              BR.Z vel1           ;se o estado dos interruptores for 1     
                                  ;a velocidade da cobra vai ser 0.2s
                                  ;e a Flag_vel1 vai passar a 1

              MOV R1,M[INTERRUPTORES]
              MOV R2,00000010b
              CMP R1,R2
              BR.Z vel2           ;se o estado dos interruptores for 2     
                                  ;a velocidade da cobra vai ser 0.3s
                                  ;e a Flag_vel2 vai passar a 1.

              MOV R7,M[Flag_vel1] ;se o estado dos interruptores for outro 
              CMP R0,R7           ;do que (0,1 ou 2), vai se verificar com
              BR.NZ vel1          ;velocidade a cobra se deslocava anteriormente
                                  ;através das flags. O programa vai saltar para 
              MOV R7,M[Flag_vel2] ;a rotina de velocidade cujo a flag associada
              CMP R0,R7           ;estiver a 1.
              BR.NZ vel2

              JMP fim_velo

vel1:         MOV R1,1            ;a flag associada a vel1 passa 1, as outras duas
              MOV M[Flag_vel1],R1 ;(vel0 e vel2) passam a 0 
              MOV M[Flag_vel0],R0
              MOV M[Flag_vel2],R0
              MOV R1,M[conta_msegundos1]
              MOV R2,2            ;quando tiverem passado 0.2s, o conta_msegundos1,
              CMP R1,R2           ;(que é incrementado na rotina do timer) vai voltar   
              JMP.N velocidades   ;a 0 e o programa vai proceder para o movimento da 
              MOV M[conta_msegundos1],R0 ;cobra, se ainda nao tiverem passado 0.2s                      
                                  ;o programa vai ficar num ciclo à espera.
              JMP fim_velo

vel2:         MOV R1,1           ;a flag associada a vel2 passa 1, as outras duas
              MOV M[Flag_vel2],R1;(vel1 e vel0) passam a 0 
              MOV M[Flag_vel0],R0
              MOV M[Flag_vel1],R0
              MOV R1,M[conta_msegundos2]
              MOV R2,3           ;quando tiverem passado 0.3s, o conta_msegundos2,
              CMP R1,R2          ;(que é incrementado na rotina do timer) vai voltar
              JMP.N velocidades  ;a 0 e o programa vai proceder para o movimento da 
              MOV M[conta_msegundos2],R0 ;cobra, se ainda nao tiverem passado 0.3s
fim_velo:     RET                ;o programa vai ficar num ciclo à espera.
;===============================================================================
;go_left: Rotina que faz com que a cobra se mova para a esquerda.
;===============================================================================  
go_left:      CMP R0,M[IO_TESTET]
              JMP.NZ key_pressed ;verifica se alguma tecla foi pressionada
             
              MOV R7,M[Flag_right] ;se cobra estiver a mover-se para a direita
              CMP R0,R7            ;(flag_right a 1),ela nao se pode mover para
              JMP.NZ go_right      ;a esquerda entao volta para a rotina onde se
                                   ;move para a direita
              
              CALL velocidades     ;verifica a velocidade da cobra
              CALL mov_cobra       
              MOV R7,M[Cobracoord] ;move a cabeca da cobra uma coluna para a esquerda
              SUB R7, 0001h
              MOV M[Cobracoord],R7
              CALL EscCobra        
              CALL comp_limit      ;verifica se bateu nas paredes
              CALL come_comida     ;verifica se comeu
              CALL comp_cobra      ;verifica se chocou com ela própria
              MOV R7,1
              MOV M[Flag_left],R7 ;passa a flag associada a direcçao esquerda
              MOV M[Flag_up],R0   ;a 1 e as outras a 0
              MOV M[Flag_down],R0
              MOV M[Flag_right],R0
              CALL verif_pausa
              JMP go_left  

;===============================================================================
;go_right: Rotina que faz com que a cobra se mova para a direita.
;===============================================================================
 
go_right:     CMP R0,M[IO_TESTET]
              JMP.NZ key_pressed ;verifica se alguma tecla foi pressionada

              MOV R7,M[Flag_left] ;se cobra estiver a mover-se para a esquerda
              CMP R0,R7           ;(flag_left a 1),ela nao se pode mover para
              JMP.NZ go_left      ;a direita entao volta para a rotina onde se
                                  ;move para a esquerda
              
              CALL velocidades     ;verifica a velocidade da cobra
              CALL mov_cobra
              MOV R7,M[Cobracoord] ;move a cabeca da cobra uma coluna para a direita 
              ADD R7, 0001h
              MOV M[Cobracoord],R7
              CALL EscCobra
              CALL comp_limit
              CALL come_comida
              CALL comp_cobra
              MOV R7,1
              MOV M[Flag_right],R7 ;passa a flag associada a direcçao direita
              MOV M[Flag_up],R0    ;a 1 e as outras a 0
              MOV M[Flag_left],R0
              MOV M[Flag_down],R0
              CALL verif_pausa
              JMP go_right  
;===============================================================================
;go_down: Rotina que faz com que a cobra se mova para baixo.
;===============================================================================

go_down:      CMP R0,M[IO_TESTET]
              JMP.NZ key_pressed
              MOV R7,M[Flag_up] ;se cobra estiver a mover-se para cima
              CMP R0,R7         ;(flag_up a 1),ela nao se pode mover para
              JMP.NZ go_up      ;baixo entao volta para a rotina onde se
                                ;move para cima
              CALL velocidades
              CALL mov_cobra
              MOV R7,M[Cobracoord] ;move a cabeca da cobra uma linha para baixo
              ADD R7, 0100h
              MOV M[Cobracoord],R7
              CALL EscCobra
              CALL comp_limit
              CALL come_comida
              CALL comp_cobra
              MOV R7,1
              MOV M[Flag_down],R7 ;passa a flag associada a direcçao baixo
              MOV M[Flag_up],R0   ;a 1 e as outras a 0
              MOV M[Flag_left],R0
              MOV M[Flag_right],R0
              CALL verif_pausa
              JMP go_down 
;===============================================================================
;go_up: Rotina que faz com que a cobra se mova para cima.
;===============================================================================

go_up:        CMP R0,M[IO_TESTET]
              JMP.NZ key_pressed
              MOV R7,M[Flag_down] ;se cobra estiver a mover-se para baixo
              CMP R0,R7           ;(flag_down a 1),ela nao se pode mover para
              JMP.NZ go_down      ;cima entao volta para a rotina onde se
                                  ;move para baixo
              CALL velocidades
              CALL mov_cobra
              MOV R7,M[Cobracoord]
              SUB R7, 0100h
              MOV M[Cobracoord],R7 ;move a cabeca da cobra uma linha para cima
              CALL EscCobra
              CALL comp_limit
              CALL come_comida
              CALL comp_cobra
              MOV R7,1
              MOV M[Flag_up],R7   ;passa a flag associada a direcçao cima
              MOV M[Flag_down],R0 ;a 1 e as outras a 0
              MOV M[Flag_left],R0
              MOV M[Flag_right],R0
              CALL verif_pausa
              JMP go_up
;===============================================================================
;comp_limit: Rotina que compara a posicao da cabeça da cobra com os limites
;            verticais e laterais, se esta for igual a algum destes  
;            (o jogador perdeu) dá-se um salto para a rotina game_over.
;===============================================================================
comp_limit:       MOV R7,M[Cobracoord]
                  SHR R7,8 ;ficamos apenas com o X da posicao da cabecadacobra
                  CMP R0, R7 ;comparamos com o tecto 
                  JMP.Z game_over
                  MOV R6,0017h 
                  CMP R6,R7 ;comparamos com o chao
                  JMP.Z game_over
                  MOV R7,M[Cobracoord]
                  SHL R7,8
                  SHR R7,8 ;obtemos apena o Y da posicao da cabecadacobra
                  CMP R0,R7 ;comparamos com a parede esquerda
                  JMP.Z game_over
                  MOV R6,004Fh ; comparamos com a parede direita
                  CMP R6,R7
                  JMP.Z game_over
                  RET
;===============================================================================
;comp_cobra: Rotina que compara a posicao da cabeça da cobra com todas a posicoes
;            do resto do seu corpo, se esta dor igual igual a algum destes
;            (o jogador perdeu, a cobra chocou com o seu corpo) dá-se um salto 
;            para a rotina game_over.
;===============================================================================
comp_cobra:     PUSH R1
                PUSH R2
                PUSH R5
                MOV R2,M[Cobracoord]  
                MOV R5, M[Cobracorpo] ;em R5 vai estar o numero de 'O' do corpo da cobra
comp_cobra_die: DEC R5
                CMP R5,R0
                BR.Z fim_comp_cobra ;se a rotina ja verificou todas as posicoes do corpo
                                    ;R5=0 entao dá-se um salto para o vim da rotina
		MOV R1, Cobracoord 
		ADD R1, R5 ;ao endereço da posicao da cabeça da cobra vai-se adicionar
                           ;o numero de corpos da cobra de forma a obter-mos os endereço
                           ;das varias posicoes do corpo da cobra.
		
                CMP M[R1],R2 ;depois comparamos as posicoes de cada 'O' do corpo da cobra
                             ;com a cabeça desta se forem iguais, o programa salta para 
                             ;a rotina "game_over"
		JMP.Z game_over
                BR comp_cobra_die
fim_comp_cobra: POP R5
                POP R2
                POP R1
                RET
;===============================================================================
;come_comida: Rotina que verifica se a posiçao da cabeça da cobra é igual 
;             à posiçao da comida. 
;==============================================================================
come_comida:    MOV R1,M[Cobracoord]
                MOV R2,M[PosicaoComida]
                CMP R2,R1 ;se a posiçao da comida for igual à posicao da cabeça
                          ;entao o programa vai saltar para a rotina "gera_comida" 
                JMP.Z gera_comida
                RET                       
;===============================================================================
;gera_comida: Rotina que aumenta o tamanho da cobra, actualiza o score nos displays
;             actualiza o score nos LEDS e gera uma nova comida.  
;===============================================================================
gera_comida:    INC M[Cobracorpo]
                INC M[Cobracorpo] ;incrementa o comprimento do corpo da cobra
                MOV R7,M[Score]
                MOV R5,4
                CMP R5, R7
                BR.Z ult_ponto    ;verifica se é a ultima comida
                INC R7            ;incrementa o score
                MOV M[Score],R7
                MOV M[DISP7S3],R7 ;actualiza o score nos displays
                MOV R6,M[ScoreLEDS] 
                MOV M[LEDS],R6    ;actualiza o score nos LEDS
                                  
                SHLA R6,0001h     
                OR R6,0001h       
                MOV M[ScoreLEDS],R6 ;actualiza o score dos LEDS
                CALL comida_print   ;escreve uma nova comida
                BR final_comida

ult_ponto:       MOV M[Score],R7   
                 MOV M[DISP7S3],R7  ;actualiza o score nos displays 
                 MOV R6,M[ScoreLEDS]
                 MOV M[LEDS],R6     ;actualiza o score nos LEDS
                 CALL DELAY
                 CALL DELAY
                 JMP game_win       ;o jogador ganhou, o progama salta
                                    ;para a rotina "game_win"              
final_comida:    RET

;===============================================================================
;aleat_posicao: Rotina que gera uma posicao aletória apartir um numero de um NI 
;               inicial.
;==============================================================================

aleat_posicao:  PUSH R1
		PUSH R2
		MOV R1, M[aletor_numb]; NI em R1
		TEST R1, 1 ;verifica-se se o ultimo bit do NI é 1 ou 0
		JMP.Z if_0

if_1:	        MOV R2, M[mascara] ;se o ultimo bit do NI for 1
		XOR R1, R2
		ROR R1, 1
		MOV M[aletor_numb], R1
		BR aleat_pos_fim

if_0:	        ROR R1, 1 ;se o ultimo bit do NI for 0
		MOV M[aletor_numb], R1
aleat_pos_fim:  POP R2
		POP R1
		RET
;===============================================================================
;comida_print: Rotina que verifica se a posiçao aletória é possivel e escreve a 
;              a comida nessa posicao aleatoria. 
;==============================================================================		
comida_print:	CALL	aleat_posicao
		MOV	R7, M[aletor_numb]
		MOV	R6, 0016h
		MUL	R6, R7 ;para que o Y da posicao gerada seja inferior 
                               ;à ultima linha (23), multiplicamos o numero aleatorio
                               ;gerado pela penultima linha, de forma a retirar
                               ;a parte alta do resultado
                CMP     R0,R6
                BR.Z    comida_print ;se a posicao gerada for 0, a rotina volta ao
                                     ;inicio e gera um novo numero aleatório

comida_print1:  CALL	aleat_posicao
		MOV	R5, 004Eh
		MUL	R5, R7 ;para que os X da posicao sejam inferiores 
                               ;à ultima coluna (80),multiplicamos o numero aleatorio
                               ;gerado pela penultima coluna, de forma a retirar
                               ;a parte alta do resultado
       
                CMP     R0,R5
                BR.Z    comida_print1 ;se a posicao gerada for 0, a rotina volta ao
                                      ;inicio e gera um novo numero aleatórioo

                SHL	R6, 8
		ADD	R6, R5               
		MOV	M[PosicaoComida], R6 ;depois de gerados um X e um Y possivel
		                             ;para a posicao da comida jutamo-los
                                             ;os dois numa so coordenada
                MOV     R7, '@'
                MOV     R6, M[PosicaoComida]   
                MOV     M[IO_CURSOR], R6
                MOV     M[IO_WRITE],R7  ;escreve a comida na posicao aleatória
		RET

; Rotina principal
Inicio:         MOV     R7, SP_INICIAL
                MOV     SP, R7
                MOV     R1,Rotina_NI0
                MOV     M[BOTAO_NI0],R1
                MOV     R1,Rotina_NIA
                MOV     M[BOTAO_NIA],R1
                MOV     R7, INT_MASK
                MOV     M[INT_MASK_ADDR], R7
		MOV 	R1,TimeLong
                MOV 	M[TimerValue],R1
                MOV 	R1,1
                MOV	M[TimerControl],R1 ;inicializaçao da mascara,interupçao
                MOV     R1,0030h           ;do botao I0, IA e do timer. 
                ENI
               
Inic:           MOV     M[conta_msegundos],R0
                MOV     M[conta_msegundos1],R0
                MOV     M[conta_msegundos2],R0 ;quando o jogo começa a contagem dos
                                               ;0.2s, 0.3s e 1 segundo é sempre 0
                MOV     R1,0030h               
                MOV     M[segundos_0],R1
                MOV     M[segundos_1],R1
                MOV     M[minutos_0],R1
                MOV     M[minutos_0],R1 ;o tempo começa a "0:00", 0 em ASCII é 
                                        ;30h
                CALL    LimpaJanela    
                PUSH    VarTexto1           
                PUSH    XY_INICIAL          
                CALL    EscString  ;Limpa a janela de texto e escreve "Pessione
                                   ;o botao IO para começar"

espera_inicio:  MOV     R5,M[Flag_N0] ;ciclo que espera ate que o botao I0 seja
                CMP     R5,1          ; pressionadoe que a flag que lhe está 
                BR.NZ   espera_inicio ;associada passe a 1
                CALL    LimpaJanela
                CALL    limites_jogo  ;desenha os caixa de jogo
                CALL    start_cobra

key_pressed:    MOV R7,M[IO_TECLADO]


left:           CMP R7,'A'
                JMP.Z go_left
                CMP R7,'a'
                JMP.Z go_left   ;compara a ultima tecla pressionada com a tecla 'a'
                                ;se estas forem iguais o progama vai saltar para a 
                                ;rotina que move a cobra para a esquerda

right:          CMP R7,'D'
                JMP.Z go_right
                CMP R7,'d'
                JMP.Z go_right  ;compara a ultima tecla pressionada com a tecla 'd'
                                ;se estas forem iguais o progama vai saltar para a 
                                ;rotina que move a cobra para a direita


down:           CMP R7,'S'
                JMP.Z go_down
                CMP R7,'s'
                JMP.Z go_down  ;compara a ultima tecla pressionada com a tecla 'w'
                               ;se estas forem iguais o progama vai saltar para a 
                               ;rotina que move a cobra para cima

up:             CMP R7,'W'
                JMP.Z go_up
                CMP R7,'w'
                JMP.Z go_up    ;compara a ultima tecla pressionada com a tecla 's'
                               ;se estas forem iguais o progama vai saltar para a 
                               ;rotina que move a cobra para baixo

                MOV R7,M[Flag_up] ;se foi pressionada uma tecla mas nao foi nenhuma 
                CMP R0,R7         ;das anteriores (a,d,w,s) entao vai se verificar
                JMP.NZ go_up      ;em que direcçao a cobra se deslocava, através das
                                  ;flags de deslocamento.O programa vai saltar para  
                MOV R7,M[Flag_down] ;rotina de movimento cuja a Flag de deslocamento
                CMP R0,R7           ;que lhe esta associada estiver a 1. 
                JMP.NZ go_down

                MOV R7,M[Flag_left]
                CMP R0,R7
                JMP.NZ go_left

                MOV R7,M[Flag_right]
                CMP R0,R7
                JMP.NZ go_right
 
Fim:		BR	Fim                
