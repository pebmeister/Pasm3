; written by Paul Baxter using Pasm3

MODEL_CAPABILITIES:
    ; Bit flags
    MODEL_CAP_WIREFRAME = %00000001
    MODEL_CAP_FACES     = %00000010
    MODEL_CAP_CULLING   = %00000100
    MODEL_CAP_TEXTURES  = %00001000
    
__CUBE_VERTICES:
            ; Vertex 0: X=-1, Y=-1, Z=-1, W=1
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 1: X= 1, Y=-1, Z=-1, W=1
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 2: X= 1, Y= 1, Z=-1, W=1
            .word   $0000,$0001
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 3: X=-1, Y= 1, Z=-1, W=1
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 4: X=-1, Y=-1, Z= 1, W=1
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$0001

            ; Vertex 5: X= 1, Y=-1, Z= 1, W=1
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$0001

            ; Vertex 6: X= 1, Y= 1, Z= 1, W=1
            .word   $0000,$0001
            .word   $0000,$0001
            .word   $0000,$0001
            .word   $0000,$0001

            ; Vertex 7: X=-1, Y= 1, Z= 1, W=1
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$0001
            .word   $0000,$0001

__CUBE_EDGES:
            ; Back face
            .byte   0,1
            .byte   1,2
            .byte   2,3
            .byte   3,0

            ; Front face
            .byte   4,5
            .byte   5,6
            .byte   6,7
            .byte   7,4

            ; Connecting edges
            .byte   0,4
            .byte   1,5
            .byte   2,6
            .byte   3,7

CUBE_VISIBLE:
            .ds     6

__CUBE_FACES:
            ; Front/back faces
            .byte   0, 3, 2, 1
            .byte   4, 5, 6, 7

            ; Top/bottom faces
            .byte   0, 1, 5, 4
            .byte   3, 7, 6, 2

            ; Left/right faces
            .byte   0, 4, 7, 3
            .byte   1, 2, 6, 5


__CUBE_EDGE_FACES:
            ; Back face edges
            .byte   0, 2
            .byte   0, 5
            .byte   0, 3
            .byte   0, 4

            ; Front face edges
            .byte   1, 2
            .byte   1, 5
            .byte   1, 3
            .byte   1, 4

            ; Connecting edges
            .byte   2, 4
            .byte   2, 5
            .byte   3, 5
            .byte   3, 4
            

__CUBE_VERTEX_COUNT:
            .byte   8

__CUBE_EDGE_COUNT:
            .byte   12

__PYRAMID_VERTICES:
            ; Vertex 0: X=-1, Y=-1, Z=-1, W=1
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 1: X= 1, Y=-1, Z=-1, W=1
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001

            ; Vertex 2: X= 1, Y=-1, Z= 1, W=1
            .word   $0000,$0001
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$0001

            ; Vertex 3: X=-1, Y=-1, Z= 1, W=1
            .word   $0000,$FFFF
            .word   $0000,$FFFF
            .word   $0000,$0001
            .word   $0000,$0001

            ; Vertex 4: X= 0, Y= 1, Z= 0, W=1 (Apex)
            .word   $0000,$0000
            .word   $0000,$0001
            .word   $0000,$0000
            .word   $0000,$0001

__PYRAMID_EDGES:
            ; Base
            .byte   0,1
            .byte   1,2
            .byte   2,3
            .byte   3,0

            ; Sides
            .byte   0,4
            .byte   1,4
            .byte   2,4
            .byte   3,4

__PYRAMID_VERTEX_COUNT:
            .byte   5

__PYRAMID_EDGE_COUNT:
            .byte   8

