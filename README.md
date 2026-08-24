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

- Anti-air reactivo: shoryuken (LP/MP/HP al azar, EX si hay meter) el 60% de
  las veces, anti-air normal (st.HP) el resto — para no ser 100% predecible
  ni air-parryable siempre — con cooldown y delay aleatorio.
- Bloqueo cuerpo a cuerpo (por hitbox de ataque real, no distancia) y contra
  hadoukens (lee la lista de proyectiles), con intento de parry antes de
  bloquear (siempre contra proyectiles; ocasional — 18% — contra golpes
  cuerpo a cuerpo, el guiño a Evo Moment 37, con Block de respaldo si falla).
- Zafar agarres a distancia de agarre, variando entre agarre neutral y
  agarre hacia atrás (cruza al rival de lado) para no ser predecible en
  despertar.
- **Whiff punish**: castiga al rival apenas queda en recovery, con un combo
  (cr.MK cancelado en Super Art si hay meter, o en shoryuken si no) en vez
  de un solo golpe — la única regla basada en la investigación real sobre
  Daigo (ver arriba), no en fundamentos genéricos. El timing de la
  cancelación (`combo_punish.lua`) todavía no está confirmado en vivo — no
  sabemos con certeza si conecta como combo real o como 2 golpes separados.
- Footsies: cierra distancia (caminando, dash, tatsumaki, salto ofensivo o
  manteniendo distancia al azar — no siempre en línea recta hacia adelante)
  y pokea (cr.MK / cr.MP / st.MP al azar) cuando el rival entra en rango,
  con retroceso ocasional después de pokear.

Pendiente: modelar reads/perfilado de rival de verdad (más allá del delay de
reacción y el whiff punish), más investigación de fuentes reales sobre Daigo
para reemplazar los parámetros genéricos que quedan, y un easter egg: parry
garantizado si el rival es Chun-Li y tira su SA2 (Houyoku Sen, Evo Moment 37).
Candidato encontrado en el framedata de Chun-Li (move id `5f54`, 17 ventanas
de golpe en 121 frames — encaja con el perfil) pero sin confirmar en vivo
todavía.

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
    block.lua         -- bloqueo cuerpo a cuerpo (hitbox real) y proyectiles
    parry_fireball.lua -- intento de parry antes de que Block bloquee un proyectil
    parry_melee.lua   -- intento ocasional de parry cuerpo a cuerpo (Evo Moment 37)
    throw_tech.lua    -- zafar agarres
    super_art.lua     -- Super Art 3 (Shippu Jinraikyaku), usado por combo_punish
    combo_punish.lua  -- cr.MK cancelado en especial/Super Art, usado por whiff_punish
    whiff_punish.lua  -- castiga al rival en recovery
    tatsumaki.lua     -- hurricane kick, usado para cerrar distancia
    dash.lua          -- dash hacia adelante, usado para cerrar distancia
    jump_in.lua       -- salto ofensivo, usado para cerrar distancia
    footsies.lua      -- caminar/pokear en rango medio, orquesta el acercamiento
```

## Créditos

La investigación de varias direcciones de memoria usadas acá tomó como referencia
el trabajo público de [Grouflon/3rd_training_lua](https://github.com/Grouflon/3rd_training_lua).
El código de este repo es una implementación propia, no una copia.

## Aviso legal

Este proyecto no incluye ni distribuye ROMs ni assets protegidos del juego.
Es un mod/herramienta de terceros para uso personal con una copia legítima del juego.
