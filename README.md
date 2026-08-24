# Fight with Daigo

Mod para **Street Fighter III: 3rd Strike** (Fightcade v2.0.91 / FBNeo, ROM `sfiii3nr1` "Japan 990512").

Un script Lua que, en modo dos jugadores, controla a P2 como Ken (traje blanco)
mediante un bot basado en reglas que lee el estado del juego en RAM y decide
inputs frame a frame. No es un modelo entrenado por machine learning.

**Sobre el nombre y el estado actual — para ser honestos:** la base es un bot
de fundamentos genéricos de fighting games (anti-air, bloqueo, zafar agarres,
footsies) — no un modelo entrenado con datos reales de Daigo. Encima de eso
hicimos una investigación real (entrevistas, su libro, análisis de la escena
FGC) buscando tendencias documentadas suyas y no genéricas. Resultado:

- Verificado con cita directa: [Evo Moment 37](https://en.wikipedia.org/wiki/Evo_Moment_37)
  (jugaba Ken, paró el Super Art de Chun-Li con parry, remató con SA3/Shippu
  Jinraikyaku en ese partido puntual — no hay fuente de que sea su elección
  por defecto en general).
- Verificado con cita directa: juega priorizando lecturas y whiff-punish por
  sobre reaccionar por reflejo ([EventHubs, 2023](https://www.eventhubs.com/news/2023/may/14/daigo-umehara-analyzes-wins-sf6/)),
  perfila al rival en los primeros segundos del match ([EventHubs, 2018](https://www.eventhubs.com/news/2018/may/01/chris-tatarian-sits-down-daigo-umehara-discuss-short-sets-dealing-pressure-ume-shoryu-and-more/)),
  y el "Ume-Shoryu" (tirar el reversal como apuesta calculada, no reflejo
  garantizado) es un fenómeno con nombre propio en la escena FGC, mismo enlace.
- Sin fuente encontrada: qué normal prefiere en footsies, preferencia de botón
  para anti-air, o una SA "por defecto" con Ken fuera de Evo Moment 37.

Con esto, el `anti_air.lua` y `block.lua` tienen ahora un delay aleatorio
antes de reaccionar (en vez de reaccionar siempre en el frame exacto), como
primer paso hacia "lee y decide" en vez de "gatillo fijo" — todavía lejos de
modelar reads/perfilado de rival de verdad, que quedó pendiente.

## Estado del proyecto

Funcional como prototipo. P2 se auto-selecciona (Ken, traje blanco, SA3) sin
tocar el control. Durante el combate:

- Anti-air reactivo (shoryuken) con cooldown y delay aleatorio.
- Bloqueo cuerpo a cuerpo y contra hadoukens (lee la lista de proyectiles).
- Zafar agarres a distancia de agarre.
- Footsies: camina o cierra con tatsumaki, y pokea (cr.MK / cr.MP / st.MP al
  azar) cuando el rival entra en rango.

Pendiente: modelar reads/perfilado de rival de verdad (más allá del delay de
reacción), más variedad de movimientos, y más investigación de fuentes reales
sobre Daigo para reemplazar los parámetros genéricos que quedan.

## Requisitos

- Fightcade v2.0.91 (o el cliente que use el mismo build de FBNeo)
- ROM legítima de `sfiii3nr1` (Japan 990512) — **no se distribuye acá, conseguila vos**
- Lua Scripting habilitado en el emulador

## Estructura

```
src/
  main.lua           -- punto de entrada, carga todo lo demás y corre el loop principal
  memory.lua         -- direcciones de memoria y lectura de estado de jugador
  projectiles.lua    -- lectura de la lista de proyectiles activos
  character_select.lua -- fuerza a P2 = Ken (traje blanco, SA3)
  ai/
    decide.lua       -- orquestador: prioridad entre las reglas de abajo
    util.lua          -- helpers compartidos (postura de salto, direcciones)
    anti_air.lua      -- shoryuken reactivo
    block.lua         -- bloqueo cuerpo a cuerpo y contra proyectiles
    throw_tech.lua    -- zafar agarres
    tatsumaki.lua     -- hurricane kick, usado para cerrar distancia
    footsies.lua      -- caminar/pokear en rango medio
```

## Créditos

La investigación de varias direcciones de memoria usadas acá tomó como referencia
el trabajo público de [Grouflon/3rd_training_lua](https://github.com/Grouflon/3rd_training_lua).
El código de este repo es una implementación propia, no una copia.

## Aviso legal

Este proyecto no incluye ni distribuye ROMs ni assets protegidos del juego.
Es un mod/herramienta de terceros para uso personal con una copia legítima del juego.
