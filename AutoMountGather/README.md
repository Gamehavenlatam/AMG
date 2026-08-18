# AutoMountGather

*(English below / Español más abajo)*

---

## English

Addon for World of Warcraft 3.3.5a (Ascension) that automatically remounts you after mining, herb gathering, woodcutting, skinning, or fishing — if you were mounted before dismounting to gather.

**Author:** Mrsose

### Installation

1. Copy the full `AutoMountGather` folder into `Interface/AddOns/`
2. Restart the client or type `/reload`
3. Mount up manually **once** with the mount you want to use, so the addon can detect and save it

### Usage

- Mount normally to go mine/gather/etc.
- The addon detects the gathering cast, waits the configured delay (default 1.5s), and automatically remounts you.
- It will not remount while you're in combat.

### Minimap icon

"AMG" button attached to the minimap (draggable):

- **Left click**: opens the menu (enable/disable, debug mode, remount delay)
- **Right click**: quick toggle for debug mode

### Chat commands

| Command | Function |
|---|---|
| `/amg on` | Enables the addon |
| `/amg off` | Disables the addon |
| `/amg montura` | Shows the currently saved mount |
| `/amg tiempo N` | Sets the remount delay in seconds, e.g. `/amg tiempo 2` |
| `/amg debugcast` | Toggles debug chat messages |
| `/amg debug` | Lists your current buffs (to help diagnose mount detection) |

### How it works

1. While mounted, the addon scans your buffs and saves the name of the one using a mount icon (`Ability_Mount`) into `AutoMountGatherDB` (persists across sessions).
2. When it detects a gathering profession cast (Mining, Herb Gathering, Woodcutting, Skinning, Fishing, and their Spanish equivalents), it records whether you were mounted shortly before.
3. After the configured delay, if you're not in combat and not mounted, it recasts your saved mount spell.

### Notes / limitations

- Profession spell names are localized based on your client language. If your server uses names not already included, enable `/amg debugcast`, gather once, and add the name that appears in chat to the `gatherSpellNames` table inside `AutoMountGather.lua`.
- If your mount is an item (not a spell), this addon can't summon it as-is — `CastSpellByName` would need to be adapted to `UseItemByName`. Let me know if that's your case.

---

## Español

Addon para World of Warcraft 3.3.5a (Ascension) que te vuelve a montar automáticamente después de minar, cosechar hierbas, talar madera, desollar o pescar — si estabas montado antes de bajarte a recolectar.

**Autor:** Mrsose

### Instalación

1. Copiá la carpeta `AutoMountGather` completa a `Interface/AddOns/`
2. Reiniciá el cliente o escribí `/reload`
3. Montate manualmente **una vez** con la montura que querés usar, para que el addon la detecte y la guarde

### Uso

- Montate normalmente para minar/cosechar/etc.
- El addon detecta la recolección, espera el tiempo configurado (por defecto 1.5s) y te vuelve a montar automáticamente.
- No remonta si estás en combate.

### Ícono del minimapa

Botón "AMG" pegado al minimapa (arrastrable):

- **Clic izquierdo**: abre el menú (activar/desactivar, modo debug, tiempo de remonte)
- **Clic derecho**: atajo rápido para prender/apagar el modo debug

### Comandos de chat

| Comando | Función |
|---|---|
| `/amg on` | Activa el addon |
| `/amg off` | Desactiva el addon |
| `/amg montura` | Muestra qué montura tiene guardada |
| `/amg tiempo N` | Configura el tiempo (segundos) antes de remontar, ej: `/amg tiempo 2` |
| `/amg debugcast` | Activa/desactiva mensajes de diagnóstico en el chat |
| `/amg debug` | Lista tus buffs actuales (para diagnosticar detección de montura) |

### Cómo funciona

1. Mientras estás montado, el addon escanea tus buffs y guarda el nombre del que tiene ícono de montura (`Ability_Mount`) en `AutoMountGatherDB` (persiste entre sesiones).
2. Al detectar el cast de una profesión de recolección (Mining, Herb Gathering, Woodcutting, Skinning, Fishing, y sus equivalentes en español), guarda si estabas montado hasta hace poco.
3. Después del tiempo configurado, si no estás en combate y no estás montado, vuelve a lanzar el hechizo de montura guardado.

### Notas / limitaciones

- Los nombres de profesión llegan localizados según el idioma del cliente. Si tu server usa nombres distintos a los ya incluidos, activá `/amg debugcast`, recolectá una vez, y agregá el nombre que aparezca en el chat a la tabla `gatherSpellNames` dentro de `AutoMountGather.lua`.
- Si tu montura es un ítem (no un hechizo), este addon no la va a poder invocar tal cual está — habría que adaptar `CastSpellByName` a `UseItemByName`. Avisar si es el caso.
