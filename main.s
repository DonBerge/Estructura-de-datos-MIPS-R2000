.data 0x10001000
free_slist: .word 0
cclist: .word 0
wclist: .word 0
buffer: .space 104

# MENSAJES
bn: .asciiz "\n"
.align 2
un_asterisco_solitario: .asciiz "*"
.align 2
wclist_mensaje: .asciiz "Categoria en curso: "
.align 2
menu_mensaje:.asciiz "    
    1) Crear una nueva categoria
    2) Pasar a la siguiente categoria
    3) Pasar a la anterior categoria
    4) Mostrar todas las categorias
    5) Borrar la categoria seleccionada
    6) Anexar un objeto a la categoria seleccionada
    7) Borrar un objeto de la categoria seleccionada
    8) Mostrar todos los objetos de la categoria seleccionada
    9) Salir

Seleccione una opcion por su numero: "
.align 2
no_se_vale: .asciiz "Opcion no valida"
.align 2
sin_catego: .asciiz "Antes tiene que crear una categoria"
.align 2
ingrese_palabra: .asciiz "Ingrese una palabra: "
.align 2
ingrese_numero: .asciiz "Ingrese un numero: "
.align 2

.text
.globl main

main:
    lw $t0, wclist
    beqz $t0, mensaje_menu
    li $v0, 4
    la $a0, wclist_mensaje
    syscall
    lw $a0, wclist
    lw $a0, 8($a0)
    syscall

mensaje_menu:
    la $a0, menu_mensaje
    syscall

    li $v0, 5
    syscall

    move $t3, $v0
    li $v0, 4
    la $a0, bn
    syscall
    move $v0, $t3

    li $t3, 0

    beq $v0, 9, main_end
    ble $v0, $0, numero_incorrecto
    bgt $v0, 9,  numero_incorrecto
    b numero_valido

numero_incorrecto:
    li $v0, 4
    la $a0, bn
    syscall
    la $a0, no_se_vale
    syscall
    la $a0, bn
    syscall
    b regreso

numero_valido:
    beq $v0, 1, todo_listo
    lw $a0, cclist
    beqz $a0, no_hay_catego

todo_listo:
    beq $v0, 1, nueva_catego
    beq $v0, 2, siguiente_catego
    beq $v0, 3, anterior_catego
    beq $v0, 4, mostar_categos
    beq $v0, 5, borrar_catego
    beq $v0, 6, nuevo_obje
    beq $v0, 7, borrar_obje
    beq $v0, 8, mostrar_objes

    nueva_catego:       # OPCION UNO
        li $v0, 4
        la $a0, ingrese_palabra
        syscall
        li $v0, 8
        la $a0, buffer
        li $a1, 100
        syscall
        jal newcategory
        b regreso
    siguiente_catego:   # OPCION DOS
        lw $a0, wclist
        jal next
        sw $a0, wclist
        b regreso
    anterior_catego:    # OPCION TRES
        lw $a0, wclist
        jal prev
        sw $a0, wclist
        b regreso
    mostar_categos:     # OPCION CUATRO
        lw $a0, cclist
        la $a1, printnodestring
        lw $a2, wclist
        jal doinlist
        b regreso
    borrar_catego:      # OPCION CINCO
        jal delcategory
        b regreso
    nuevo_obje:         # OPCION SEIS
        li $v0, 4
        la $a0, ingrese_palabra
        syscall
        li $v0, 8
        la $a0, buffer
        li $a1, 100
        syscall
        jal newobject
        b regreso
    borrar_obje:        # OPCION SIETE
        jal delobject
        b regreso
    mostrar_objes:      # OPCION OCHO
        lw $a0, wclist
        lw $a0, 4($a0)
        la $a1, printnodestring
        lw $a2, cclist
        jal doinlist
        b regreso

    no_hay_catego:      # Lista de categorias vacia
    li $v0, 4
    la $a0, sin_catego
    syscall

regreso:
    li $v0, 4
    la $a0, bn
    syscall
    j main

main_end:
    li $v0, 10
    syscall
.end

# MENU:
menu:
    la $a0, menu_mensaje
    li $v0, 4
    syscall
    jr $ra
.end

# CATEGORIAS
newcategory:
    lw $a0, cclist
    li $a1, 0
    li $a2, 0

    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    jal newnode
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    addi $sp, $sp, 8
    sw $a0, cclist

    bnez $t0, newcategory_not_empty
    sw $a0, wclist
    
    newcategory_not_empty:
    jr $ra
.end

delcategory:
    lw $t0, wclist
    lw $t1, cclist
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $a0, 4($t0)
    la $a1, delnode
    jal doinlist

    lw $t0, wclist
    sw $a0, 4($t0)

    move $a0, $t0
    jal delnode
    sw $a0, wclist
    lw $t0, cclist

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    beqz $t0, delcategory_end
    sw $a0, cclist
        
    delcategory_end:
    jr $ra
.end

prevcategory:
    lw $a0, wclist
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal prev
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    sw $a0, wclist

    jr $ra
.end

nextcategory:
    lw $a0, wclist
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal next
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    sw $a0, wclist
    
    jr $ra
.end

# OBJETOS

newobject:
    lw $t0, wclist
    lw $a0, 4($t0)

    # Obtiene el indice del objeto
    bnez $a0, newobject_no_es_primero   # Este es el primer objeto, le corresponde el ID 1
    li $a1, 1
    b newobject_aniadir

    newobject_no_es_primero:
    lw $a1, 0($a0)
    lw $a1, 4($a1)
    addi $a1, $a1, 1    # Indice del ultimo objeto+1

    newobject_aniadir:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal newnode
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    lw $t0, wclist
    sw $a0, 4($t0)

    jr $ra
.end

delobject:
    li $v0, 4
    la $a0, ingrese_numero
    syscall 
    li $v0, 5
    syscall
    move $a2, $v0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $a0, wclist
    lw $a0, 4($a0)

    bne $a2, 1, delobject_not_primi
    
    jal delnode

    b delobject_fin

    delobject_not_primi:
    la $a1, delifequalID
    jal doinlist


    delobject_fin:
    la $a1, asignarnumero
    li $a2, 1
    jal doinlist

    lw $t0, wclist
    sw $a0, 4($t0)
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
.end

# STRINGS
getString:  #void getstring()
    bnez $a0, getString_string_not_null
    
    li $a0, 100
    li $v0, 9
    syscall                             # v0 = malloc(100)
    move $a0, $v0                       #a0=v0

    getString_string_not_null:

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $a1, buffer  #a1=buffer
    
    jal strcpy      #stcpy(v0,buffer)
    
    sb $0, 0($a1)      #a1=NULL

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra
.end

strcpy:
    addi $sp, $sp, -8
    sw $a0, 0($sp)
    sw $a1, 4($sp)

    strcpy_loop:
        lb $t0, 0($a1)
        sb $t0, 0($a0)
        addi $a0, $a0, 1
        addi $a1, $a1, 1
        bnez $t0, strcpy_loop

    lw $a0,0($sp)
    lw $a1,4($sp)
    addi $sp, $sp, 8
    jr $ra
.end

# ITERADORES
prev:
    beqz $a0, prev_is_null
    lw $a0, 0($a0)
    prev_is_null:
    jr $ra
.end

next:
    beqz $a0, next_is_null
    lw $a0, 12($a0)
    next_is_null:
    jr $ra
.end

# NODOS
newnode:
    
    # Llamo a la funcion smalloc para obtener un nuevo nodo y guardo lo que sea necesario en el stack
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)

    jal smalloc
    
    sw $v0, 16($sp)

    lw $a0, 8($v0)  # Mete un string en el nodo
    jal getString
    lw $v0, 16($sp)
    sw $a0, 8($v0)

    lw $ra, 0($sp)
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    lw $a2, 12($sp)
    addi $sp, $sp, 20

    sw $a1, 4($v0)
    sw $a2, 8($sp)

    beqz $a0, newnode_empty # si la lista es vacia entonces va a empty
    
    lw $t3, 0($a0)  # t3 = fin de la lista
    
    beq $a0, $t3, newnode_unique # si hay 1 solo elemento en la lista

    newnode_not_empty:      # slist != NULL and slist != elist (hay 2 o mas elementos)
    sw $v0, 0($a0)  # prev(a0) = newnode
    sw $v0, 12($t3) # next(t3) = newnode
    sw $t3, 0($v0)  # prev(newnode) = t3 
    sw $a0, 12($v0) # next(newnode) = a0
    move $t3, $v0
    jr $ra

    newnode_unique:
    move $t3, $v0   # elist = newnodo
    sw $t3, 0($a0)  # prev(a0) = t3
    sw $t3, 12($a0) # next(a0) = t3
    sw $a0, 0($t3)  # prev(t3) = a0
    sw $a0, 12($t3) # next(t3) = a0
    move $t3, $v0
    jr $ra

    newnode_empty:
    li $t5,10
    move $a0, $v0  # slist = newnode
    move $t3, $v0  # elist = newnode
    sw $a0, 0($t3)
    sw $a0, 12($t3)
    sw $t3, 0($a0)
    sw $t3, 12($a0)
    jr $ra         # return
.end

delnode:
    bnez $a0, delnode_not_null # free(NULL) no hace nada
    jr $ra    

    delnode_not_null:
    lw $t0, 0($a0)
    lw $t1, 12($a0)

    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $t0, 8($sp)
    sw $t1, 12($sp)

    jal sfree           # free(a0)

    lw $ra, 0($sp)
    lw $a0, 4($sp)
    lw $t0, 8($sp)
    lw $t1, 12($sp)
    addi $sp, $sp, 16

    #       <-      <-
    #   t0      a0      t1
    #       ->      ->

    beq $t0, $a0, delnode_unique
    sw $t0, 0($t1)
    sw $t1, 12($t0)
    move $a0, $t1
    jr $ra

    delnode_unique:
    li $a0, 0
    jr $ra
.end

# UTILITY

smalloc:
    lw $t0, free_slist
    beqz $t0, sbrk
    move $v0, $t0
    lw $t0, 12($t0)
    sw $t0, free_slist
    jr $ra
    
    sbrk:
    li $a0, 16 # node size fixed 4 words
    li $v0, 9
    syscall # return node address in v0
    jr $ra
.end 

sfree:
    lw $t0, free_slist
    sw $t0, 12($a0)
    sw $a0, free_slist # $a0 node address in unused list
    jr $ra
.end

printnodestring:
    move $t0, $a0
    li $v0, 4
    bne $a0, $a1, printnodestring_esta_no_es
    
    la $a0, un_asterisco_solitario
    syscall

    printnodestring_esta_no_es:
    lw $a0, 8($t0)
    syscall
    move $a0, $t0
    jr $ra
.end

printnodeid:
    move $t0, $a0
    lw $a0, 4($a0)
    li $v0, 1
    syscall
    move $a0, $t0
    jr $ra
.end

asignarnumero:
    sw $a1, 4($a0)
    addi $a1, $a1, 1
    jr $ra
.end

delifequalID:
    lw $t0, 4($a0)
    bne $t0, $a1, delifequalID_fin
    
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a1, 4($sp)
    jal delnode
    lw $ra, 0($sp)
    lw $a1, 4($sp)
    addi $sp, $sp, 8
    
    delifequalID_fin:
    jr $ra
.end

#LISTAS

doinlist:   #(lo_que_sea) doinlist(a0=lista,a1=funcion,a2=lo_que_sea)
            #a1 = (lo_que_sea) funcion(a0=nodo,a1=lo_que_sea)

    bnez $a0, doinlist_lista_no_vacia
    jr $ra
    doinlist_lista_no_vacia:

    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    
    move $t0, $a0 # t0 = inicio
    move $t1, $a1 # t1 = funcion
    move $a1, $a2 # a1 = auxiliar

    # la funcion recibira un nodo y el valor auxiliar

    doinlist_loop:

        jal $t1                     # Hago algo con el nodo
        
        lw $t0, 4($sp)              # Restaura inicio
        lw $t1, 8($sp)              # Restaura funcion
        
        jal next                    # Paso al nodo siguiente
        
        lw $t0, 4($sp)              # Restaura inicio
        lw $t1, 8($sp)              # Restaura funcion

    beq $t0, $a0, doinlist_loopend     # if(a0==0 or inicio==a0) break;
    beqz $a0, doinlist_loopend
    b doinlist_loop

    doinlist_loopend:

    lw $ra, 0($sp)                  # Restaura todo y finaliza
    lw $a1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
.end