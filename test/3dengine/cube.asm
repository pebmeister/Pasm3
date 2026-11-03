CUBE_VERTICES:
        ; Vertex 0: X=-1, Y=-1, Z=-1, W=1
        .word $0000,$FFFF
        .word $0000,$FFFF
        .word $0000,$FFFF
        .word $0000,$0001

        ; Vertex 1: X= 1, Y=-1, Z=-1, W=1
        .word $0000,$0001
        .word $0000,$FFFF
        .word $0000,$FFFF
        .word $0000,$0001

        ; Vertex 2: X= 1, Y= 1, Z=-1, W=1
        .word $0000,$0001
        .word $0000,$0001
        .word $0000,$FFFF
        .word $0000,$0001

        ; Vertex 3: X=-1, Y= 1, Z=-1, W=1
        .word $0000,$FFFF
        .word $0000,$0001
        .word $0000,$FFFF
        .word $0000,$0001

        ; Vertex 4: X=-1, Y=-1, Z= 1, W=1
        .word $0000,$FFFF
        .word $0000,$FFFF
        .word $0000,$0001
        .word $0000,$0001

        ; Vertex 5: X= 1, Y=-1, Z= 1, W=1
        .word $0000,$0001
        .word $0000,$FFFF
        .word $0000,$0001
        .word $0000,$0001

        ; Vertex 6: X= 1, Y= 1, Z= 1, W=1
        .word $0000,$0001
        .word $0000,$0001
        .word $0000,$0001
        .word $0000,$0001

        ; Vertex 7: X=-1, Y= 1, Z= 1, W=1
        .word $0000,$FFFF
        .word $0000,$0001
        .word $0000,$0001
        .word $0000,$0001
        
CUBE_EDGES:
        ; Back face
        .byte 0,1
        .byte 1,2
        .byte 2,3
        .byte 3,0

        ; Front face
        .byte 4,5
        .byte 5,6
        .byte 6,7
        .byte 7,4

        ; Connecting edges
        .byte 0,4
        .byte 1,5
        .byte 2,6
        .byte 3,7

CUBE_VERTEX_COUNT:
        .byte 8

CUBE_EDGE_COUNT:
        .byte 12
        