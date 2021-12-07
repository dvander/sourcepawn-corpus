
#define SOUNDS_WEAPON_FORBIDEN "*ui/weapon_cant_buy.wav"
#define SOUNDS_WEAPON_REMOVED "*ui/bonus_alert_end.wav"
#define SOUNDS_WEAPON_AWARDED "*ui/bonus_alert_start.wav"
#define SOUNDS_WEAPON_TIMER1 "*buttons/blip2.wav"
#define SOUNDS_WEAPON_TIMER2 "*buttons/blip2.wav"
#define SOUNDS_WEAPON_TIMER3 "*ui/beep07.wav"

#define SOUNDS_SPAWN "*commander/commander_comment_22.wav"

stock sounds_OnMapStart()
{
    sounds_PrecacheSound(SOUNDS_WEAPON_REMOVED);
    sounds_PrecacheSound(SOUNDS_WEAPON_AWARDED);
    sounds_PrecacheSound(SOUNDS_WEAPON_TIMER1);
    sounds_PrecacheSound(SOUNDS_WEAPON_TIMER2);
    sounds_PrecacheSound(SOUNDS_WEAPON_TIMER3);
    
    sounds_PrecacheSound(SOUNDS_SPAWN);
}

stock sounds_PrecacheSound(const String:sndPath[])
{
	AddToStringTable(FindStringTable("soundprecache"), sndPath);
}

stock sounds_PlayToClient(clientIndex,
                            const String:sndPath[],
                            entity = SOUND_FROM_PLAYER,
                            channel = SNDCHAN_AUTO,
                            level = SNDLEVEL_NORMAL,
                            flags = SND_NOFLAGS,
                            Float:volume = SNDVOL_NORMAL,
                            pitch = SNDPITCH_NORMAL,
                            speakerentity = -1,
                            const Float:origin[3] = NULL_VECTOR,
                            const Float:dir[3] = NULL_VECTOR,
                            bool:updatePos = true,
                            Float:soundtime = 0.0)
{
   new clients[1];
   
   clients[0] = clientIndex;
   entity = (entity == SOUND_FROM_PLAYER) ? clientIndex : entity;
   
   EmitSound(clients, 1, sndPath, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);	
}

stock sounds_PlayToAll(  const String:sndPath[],
                            entity = SOUND_FROM_PLAYER,
                            channel = SNDCHAN_AUTO,
                            level = SNDLEVEL_NORMAL,
                            flags = SND_NOFLAGS,
                            Float:volume = SNDVOL_NORMAL,
                            pitch = SNDPITCH_NORMAL,
                            speakerentity = -1,
                            const Float:origin[3] = NULL_VECTOR,
                            const Float:dir[3] = NULL_VECTOR,
                            bool:updatePos = true,
                            Float:soundtime = 0.0)
{  
   EmitSoundToAll(sndPath, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);	
}