#NoEnv
SetBatchLines, -1
ListLines, Off
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

Global MacroLigado := false
Global MargemSeguranca := 0  ; Margem de ajuste fino (pode ser negativa)

F6::
MacroLigado := !MacroLigado
if (MacroLigado) {
    SoundBeep, 750, 200
    ToolTip, BOT PESCA: LIGADO (MODO OVERLAP)
    SetTimer, LoopPrincipal, 10
} else {
    SoundBeep, 500, 200
    ToolTip, BOT PESCA: DESLIGADO
    SetTimer, LoopPrincipal, Off
    ToolTip
}
return

F7::ExitApp

; AJUSTE FINO (Se clicar cedo: Seta Baixo | Se clicar tarde: Seta Cima)
~Up:: 
MargemSeguranca += 2
ToolTip, Margem: %MargemSeguranca%
return

~Down:: 
MargemSeguranca -= 2
ToolTip, Margem: %MargemSeguranca%
return

LoopPrincipal:
; 1. LOCALIZA O VERDE (Área central do ecrã)
PixelSearch, Gx, Gy, 850, 450, 1100, 700, 0x41A491, 20, RGB Fast

if (!ErrorLevel) {
    ; ENCONTROU O VERDE!
    ; Vamos descobrir a largura da zona verde (scan horizontal)
    GxFim := Gx
    Loop, 200 {
        PixelGetColor, CorTeste, % Gx + A_Index, %Gy%, RGB
        if (!CorEstaPerto(CorTeste, 0x41A491, 30))
            break
        GxFim := Gx + A_Index
    }
    
    ; Centro e limites da zona verde
    GxCentro := (Gx + GxFim) // 2
    ToolTip, VERDE: X=%Gx% ate X=%GxFim% | Centro=%GxCentro%

    Loop {
        if (!MacroLigado)
            return

        ; 2. ESTRATÉGIA OVERLAP: Procura a barra BRANCA em tempo real
        ;    Faz scan horizontal na mesma linha do verde para encontrar o branco
        BrancoX := 0
        Loop, 300 {
            ScanX := 750 + A_Index  ; Scan de X=751 até X=1050
            PixelGetColor, CorScan, %ScanX%, %Gy%, RGB
            if (CorEstaPerto(CorScan, 0xFFFFFF, 60)) {
                BrancoX := ScanX
                break
            }
        }

        ; 3. VERIFICA SE O BRANCO ESTÁ DENTRO DA ZONA VERDE
        ;    Com margem de ajuste fino
        if (BrancoX > 0) {
            ; O branco está dentro do verde se BrancoX está entre Gx e GxFim
            ; MargemSeguranca positiva = clica mais tarde (mais para a direita)
            ; MargemSeguranca negativa = clica mais cedo (mais para a esquerda)
            LimiteEsq := Gx + MargemSeguranca
            LimiteDrt := GxFim - MargemSeguranca

            ToolTip, BRANCO em X=%BrancoX% | Verde [%LimiteEsq% - %LimiteDrt%]

            if (BrancoX >= LimiteEsq && BrancoX <= LimiteDrt) {
                SoundBeep, 1000, 100  ; Beep para confirmar que chegou aqui
                ToolTip, A CLICAR TECLA 1...
                Sleep, 50
                
                ; Garante que o jogo tem foco
                WinGetActiveTitle, JanelaAtiva
                ToolTip, Janela ativa: %JanelaAtiva%
                Sleep, 100
                
                ; Tenta múltiplos métodos de envio
                Send, {1}
                Sleep, 50
                SendEvent, {1}
                
                ToolTip, PESCA PERFEITA! (Branco em %BrancoX% / Verde %Gx%-%GxFim%)
                Sleep, 3000
                break
            }
        }

        ; 4. Verificação se o minigame fechou (a cada 25 ciclos)
        if (Mod(A_Index, 25) = 0) {
            PixelGetColor, CorBase, %Gx%, %Gy%, RGB
            if (!CorEstaPerto(CorBase, 0x41A491, 30))
                break
        }

        Sleep, 1
    }
}
return

CorEstaPerto(c1, c2, var) {
    r1 := (c1 >> 16) & 0xFF, g1 := (c1 >> 8) & 0xFF, b1 := c1 & 0xFF
    r2 := (c2 >> 16) & 0xFF, g2 := (c2 >> 8) & 0xFF, b2 := c2 & 0xFF
    return (Abs(r1-r2) < var && Abs(g1-g2) < var && Abs(b1-b2) < var)
}
