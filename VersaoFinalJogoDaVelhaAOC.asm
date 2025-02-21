.data
grid: .byte '1', '2', '3', '4', '5', '6', '7', '8', '9'  # Tabuleiro numérico
turn: .byte 'X'  # Jogador inicial

# mensagens
start_msg: .asciiz "\n=== JOGO DA VELHA ===\n"
turn_msg: .asciiz "\nVez do jogador: "
input_msg: .asciiz "\nEscolha uma posição (1-9): "
invalid_msg: .asciiz "Jogada inválida! Tente novamente.\n"
win_msg: .asciiz "\nJogador "
win_msg2: .asciiz " venceu!\n"
draw_msg: .asciiz "\nEmpate!\n"
play_again_msg: .asciiz "Jogar novamente? (1-Sim/0-Não): "
board_msg: .asciiz "\nTabuleiro atual:\n"
newline: .asciiz "\n"

# configurações de som
duration: .word 300
volume: .word 127
instrument: .word 1
pitch_move: .word 261
pitch_win: .word 523
pitch_draw: .word 130
pitch_invalid: .word 100
pitch_start: .word 294

.text
.globl main

# função principal
main:
    # som de início
    lw $a0, pitch_start
    jal play_sound

    # mensagem inicial
    li $v0, 4
    la $a0, start_msg
    syscall
    
    j game_loop

# loop principal do jogo
game_loop:
    jal displayBoard  # mostra o tabuleiro
    
    # mostra vez do jogador
    li $v0, 4
    la $a0, turn_msg
    syscall
    li $v0, 11
    lb $a0, turn
    syscall
    
input_loop:
    # pede input do jogador
    li $v0, 4
    la $a0, input_msg
    syscall
    
    li $v0, 5  # leitura de número inteiro
    syscall
    move $t0, $v0  # salva número digitado

    # verifica se a entrada é válida (1-9)
    blt $t0, 1, invalid_move
    bgt $t0, 9, invalid_move

    addi $t0, $t0, -1  # austa índice para array (0-8)
    
    # verifica se a posição está ocupada
    la $t1, grid
    add $t1, $t1, $t0
    lb $t2, ($t1)
    beq $t2, 'X', invalid_move
    beq $t2, 'O', invalid_move

    # marca posição no tabuleiro
    lb $t3, turn
    sb $t3, ($t1)

    # som de jogada
    lw $a0, pitch_move
    jal play_sound

    # exibe tabuleiro atualizado
    jal displayBoard

    # verifica vitória
    jal checkWin
    beq $v0, 1, game_won

    # verificar empate
    jal checkDraw
    beq $v0, 1, game_draw

    # alternar jogador
    lb $t3, turn
    beq $t3, 'X', switch_to_O
    li $t3, 'X'
    j update_turn
switch_to_O:
    li $t3, 'O'
update_turn:
    sb $t3, turn
    j game_loop

# mensagem de jogada inválida
invalid_move:
    # som de jogada inválida
    lw $a0, pitch_invalid
    jal play_sound
    
    li $v0, 4
    la $a0, invalid_msg
    syscall
    j input_loop

# verifica vitória
checkWin:
    li $v0, 0  # assume sem vitória
    la $t0, grid

    # linhas
    lb $t1, 0($t0)  
    lb $t2, 1($t0)  
    lb $t3, 2($t0)  
    beq $t1, $t2, row_check_1
    j check_columns
row_check_1:
    beq $t2, $t3, win_detected
    j check_columns

    # colunas
check_columns:
    lb $t1, 0($t0)  
    lb $t2, 3($t0)  
    lb $t3, 6($t0)  
    beq $t1, $t2, col_check_1
    j check_diagonals
col_check_1:
    beq $t2, $t3, win_detected
    j check_diagonals

    # diagonais
check_diagonals:
    lb $t1, 0($t0)  
    lb $t2, 4($t0)  
    lb $t3, 8($t0)  
    beq $t1, $t2, diag_check_1
    j no_win
diag_check_1:
    beq $t2, $t3, win_detected
    j no_win

win_detected:
    li $v0, 1  # retorna verdadeiro
    jr $ra

no_win:
    jr $ra

# verifica empate
checkDraw:
    la $t0, grid
    li $t1, 0
    li $v0, 1  # assume empate

check_draw_loop:
    lb $t2, ($t0)  
    bge $t2, '1', found_number  
    ble $t2, '9', found_number  
    
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    blt $t1, 9, check_draw_loop

    jr $ra  # retorna 1 (empate)

found_number:
    li $v0, 0  # não é empate
    jr $ra

# exibe o tabuleiro
displayBoard:
    li $v0, 4
    la $a0, board_msg
    syscall
    
    la $t0, grid
    li $t1, 0  # Contador geral

print_loop:
    li $v0, 11
    lb $a0, ($t0)
    syscall

    li $v0, 11
    li $a0, ' '
    syscall

    addi $t0, $t0, 1
    addi $t1, $t1, 1

    # Se já imprimiu 3 elementos, insere uma quebra de linha
    rem $t2, $t1, 3   # t2 = t1 % 3
    bne $t2, $zero, continue_print
    
    li $v0, 4
    la $a0, newline
    syscall

continue_print:
    blt $t1, 9, print_loop

    jr $ra
# função para tocar som
play_sound:
    lw $a1, duration
    lw $a2, instrument
    lw $a3, volume
    li $v0, 31
    syscall
    jr $ra

# caso de vitória
game_won:
    lw $a0, pitch_win
    jal play_sound

    li $v0, 4
    la $a0, win_msg
    syscall

    li $v0, 11
    lb $a0, turn
    syscall

    li $v0, 4
    la $a0, win_msg2
    syscall

    j end_game
    
# Funcao para resetar o tabuleiro
resetBoard:
    la $t0, grid  # Endereco base do tabuleiro
    li $t1, '1'   # Primeiro valor do tabuleiro

    sb $t1, 0($t0)
    li $t1, '2'
    sb $t1, 1($t0)
    li $t1, '3'
    sb $t1, 2($t0)
    li $t1, '4'
    sb $t1, 3($t0)
    li $t1, '5'
    sb $t1, 4($t0)
    li $t1, '6'
    sb $t1, 5($t0)
    li $t1, '7'
    sb $t1, 6($t0)
    li $t1, '8'
    sb $t1, 7($t0)
    li $t1, '9'
    sb $t1, 8($t0)

    li $t1, 'X'   # Define o jogador inicial novamente
    sb $t1, turn

    jr $ra        # Retorna para quem chamou
    

# caso de empate
game_draw:
    lw $a0, pitch_draw
    jal play_sound

    li $v0, 4
    la $a0, draw_msg
    syscall

    j end_game

# pergunta se o jogador quer reiniciara
end_game:
    li $v0, 4
    la $a0, play_again_msg
    syscall

    li $v0, 5
    syscall
    beq $v0, 1, restart_game  # Chama a funcao de reset se o jogador escolher jogar novamente

    li $v0, 10   # Finaliza o programa se for 0
    syscall

restart_game:
    jal resetBoard  # Reseta o tabuleiro
    j game_loop     # Retorna ao loop do jogo
