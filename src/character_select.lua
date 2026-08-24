-- Fuerza a P2 a elegir Ken (traje blanco) en la pantalla de selección de
-- personaje, sin necesidad de tocar el control de P2 a mano. Pensado para
-- el flujo de este proyecto: P2 es el slot que la IA va a pilotar más
-- adelante, así que no hay un jugador humano real al que pisarle el input
-- en esta pantalla.
--
-- La escritura de character_select_color no está confirmada como válida
-- (en el mapeo de referencia solo aparece documentada como lectura) —
-- la probamos igual por ser un byte de RAM normal; si no pega hay que
-- verlo en vivo y ajustar.

CharacterSelect = {}

local PLAYER_ID = 2
local OPPONENT_ID = 1
local NO_PLAYER = 0 -- ver enum en memory.lua (PLAYER_SELECT.state)
local CHARACTER_SELECT_PHASE = 2
local SA_SELECT_PHASE = 4

-- El primer intento de forzar la SA (con y sin delay antes de confirmar)
-- terminó bloqueando SA2 en vez de KEN_DEFAULT_SA. En su momento pensamos que
-- era la dirección siendo de solo lectura, pero en realidad el "Weak Punch"
-- usado para confirmar a Ken en CHARACTER_SELECT_PHASE quedaba pegado en
-- true de un frame a otro (bug de inputs sin limpiar, ya arreglado en
-- main.lua) y confirmaba la SA por defecto antes de que nuestro delay
-- llegara a actuar. Reintentamos ahora que ese bug está resuelto.
local SA_CONFIRM_DELAY_FRAMES = 5
local sa_select_frames = 0

-- Auto-unirse: mientras P2 no tenga jugador (state == 0) y P1 ya haya
-- arrancado el flujo (metió su moneda), le mandamos moneda + start a P2 en
-- vez de esperar a que alguien lo haga a mano. Sin verificar todavía si
-- hace falta el Start o si con la moneda ya alcanza — a probar en vivo.
local JOIN_COIN_FRAMES = 5
local JOIN_START_FRAMES = 5
local join_frames = 0

local function reset()
  sa_select_frames = 0
  join_frames = 0
end

function CharacterSelect.force_ken(input)
  if Memory.is_round_active() then
    reset()
    return
  end

  local select_state = Memory.read_select_state(PLAYER_ID)
  local opponent_select_state = Memory.read_select_state(OPPONENT_ID)
  local addr = Memory.PLAYER_SELECT[PLAYER_ID]

  if select_state.state == NO_PLAYER and opponent_select_state.state ~= NO_PLAYER then
    join_frames = join_frames + 1
    if join_frames <= JOIN_COIN_FRAMES then
      input["P2 Coin"] = true
    elseif join_frames <= JOIN_COIN_FRAMES + JOIN_START_FRAMES then
      input["P2 Start"] = true
    end
  elseif select_state.state == CHARACTER_SELECT_PHASE then
    reset()
    memory.writebyte(addr.row, Memory.KEN_SELECT.row)
    memory.writebyte(addr.col, Memory.KEN_SELECT.col)
    memory.writebyte(addr.color, Memory.KEN_WHITE_GI_COLOR)
    input["P2 Weak Punch"] = true
  elseif select_state.state == SA_SELECT_PHASE then
    memory.writebyte(addr.sa, Memory.KEN_DEFAULT_SA)
    sa_select_frames = sa_select_frames + 1
    if sa_select_frames > SA_CONFIRM_DELAY_FRAMES then
      input["P2 Weak Punch"] = true
    end
  else
    reset()
  end
end
