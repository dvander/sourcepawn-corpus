#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "DoD Anti-Prone Source",
	author = "FeuerSturm, playboycyberclub",
	description = "Disallow player to go prone (MGs + Snipers can be excluded!)",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net"
}

#define SPEC	1
#define ALLIES	2
#define AXIS	3

new Handle:DoDAPStatus = INVALID_HANDLE
new Handle:DoDAPCPProne = INVALID_HANDLE
new Handle:DoDAPAllowMG = INVALID_HANDLE
new Handle:DoDAPAllowSniper = INVALID_HANDLE
new Handle:DoDAPProneTimer = INVALID_HANDLE
new Handle:DoDAPUseSound = INVALID_HANDLE
new Handle:DoDAPUseMsg = INVALID_HANDLE
new Handle:DoDAPGlobalMsg = INVALID_HANDLE
new Handle:TimerStandUp[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new bool:StandUp[MAXPLAYERS + 1] = { false, ... };
new Float:gLastProne[MAXPLAYERS + 1]
new String:Sound[4][] = { "", "", "player/american/us_changeposition.wav", "player/german/ger_changeposition.wav" }

public OnPluginStart()
{
	CreateConVar("dod_antiprone_version", PLUGIN_VERSION, "DoD AntiProne Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_antiprone_version"),PLUGIN_VERSION)
	DoDAPStatus = CreateConVar("dod_antiprone_status", "1", "<1/0> = enable/disable AntiProne")
	DoDAPCPProne = CreateConVar("dod_antiprone_cpallowprone", "1", "<1/0> = allow/disallow proning at CapturePoints")
	DoDAPAllowMG = CreateConVar("dod_antiprone_mgallowprone", "1", "<1/0> = allow/disallow proning for MGs")
	DoDAPAllowSniper = CreateConVar("dod_antiprone_sniperallowprone", "1", "<1/0> = allow/disallow proning for Snipers")
	DoDAPProneTimer = CreateConVar("dod_antiprone_standuptimer", "0", "<0/#> = time in seconds players are allowed to stay prone  -  0 = immediately stand up again")
	DoDAPUseMsg = CreateConVar("dod_antiprone_displaymessage", "1", "<1/0> = enable/disable displaying message when forcing players to stand up again")
	DoDAPUseSound = CreateConVar("dod_antiprone_playsound", "1", "<1/0> = enable/disable playing sound when forcing players to stand up again")
	DoDAPGlobalMsg = CreateConVar("dod_antiprone_globalmessage", "1", "<1/0> = enable/disable displaying a global message to all players when forcing players to stand up again")
	AutoExecConfig(true, "dod_antiprone_source", "dod_antiprone_source")
	LoadTranslations("dod_antiprone_source.txt")
}

public OnMapStart()
{
	PrecacheSound(Sound[ALLIES])
	PrecacheSound(Sound[AXIS])
}

public OnClientPutInServer(client)
{
	ResetTimer(client)
	gLastProne[client] = GetGameTime()
}

public OnClientDisconnect(client)
{
	ResetTimer(client)
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarInt(DoDAPStatus) == 0)
	{
		return Plugin_Continue
	}
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Proned = GetEntProp(client, Prop_Send, "m_bProne")
		if(Proned == 1)
		{
			new String:CurWeapon[32]
			GetClientWeapon(client, CurWeapon, sizeof(CurWeapon))
			if(((strcmp(CurWeapon, "weapon_mg42", true) == 0 || strcmp(CurWeapon, "weapon_30cal", true) == 0) && GetConVarInt(DoDAPAllowMG) == 1) || ((strcmp(CurWeapon, "weapon_k98_scoped", true) == 0 || strcmp(CurWeapon, "weapon_spring", true) == 0) && GetConVarInt(DoDAPAllowSniper) == 1))
			{
				// DO NOTHING, PRONING ALLOWED!
			}	
			else
			{
				new CPIndex = GetEntProp(client, Prop_Send, "m_iCPIndex")
				if(CPIndex != -1 && GetConVarInt(DoDAPCPProne) == 1)
				{
					ResetTimer(client)
					return Plugin_Continue
				}
				if(GetConVarInt(DoDAPProneTimer) == 0)
				{
					if(gLastProne[client] + 1.5 <= GetGameTime())
					{
						gLastProne[client] = GetGameTime()
						buttons |= IN_ALT1
						SetEntProp(client, Prop_Data, "m_nButtons", buttons)
						if(GetConVarInt(DoDAPUseMsg) == 1)
						{
							DisplayMessage(client)
						}
						if(GetConVarInt(DoDAPUseSound) == 1)
						{
							PlaySound(client)
						}
						if(GetConVarInt(DoDAPGlobalMsg) == 1)
						{
							GlobalMessage(client)
						}
						CreateTimer(1.0, CheckProne, client, TIMER_FLAG_NO_MAPCHANGE)
					}
					return Plugin_Continue
				}
				if(TimerStandUp[client] == INVALID_HANDLE)
				{
					TimerStandUp[client] = CreateTimer(GetConVarFloat(DoDAPProneTimer), StandUpTimer, client, TIMER_FLAG_NO_MAPCHANGE)
					return Plugin_Continue
				}
				if(StandUp[client])
				{
					buttons |= IN_ALT1
					SetEntProp(client, Prop_Data, "m_nButtons", buttons)
					if(GetConVarInt(DoDAPUseMsg) == 1)
					{
						DisplayMessage(client)
					}
					if(GetConVarInt(DoDAPUseSound) == 1)
					{
						PlaySound(client)
					}
					if(GetConVarInt(DoDAPGlobalMsg) == 1)
					{
						GlobalMessage(client)
					}
					StandUp[client] = false
					CreateTimer(1.0, CheckProne, client, TIMER_FLAG_NO_MAPCHANGE)
					return Plugin_Continue
				}
			}
		}
	}
	if(IsClientInGame(client))
	{
		new Proned = GetEntProp(client, Prop_Send, "m_bProne")
		if(Proned != 1)
		{
			ResetTimer(client)
			return Plugin_Continue
		}
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:StandUpTimer(Handle:timer, any:client)
{
	TimerStandUp[client] = INVALID_HANDLE
	StandUp[client] = true
	return Plugin_Handled
}

public ResetTimer(client)
{
	if(TimerStandUp[client] != INVALID_HANDLE)
	{
		CloseHandle(TimerStandUp[client])
		TimerStandUp[client] = INVALID_HANDLE
	}
	StandUp[client] = false
}

public PlaySound(client)
{
	new team = GetClientTeam(client)
	EmitSoundToClient(client, Sound[team], SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
}

public DisplayMessage(client)
{
	decl String:message[256]
	Format(message,sizeof(message), "%T", "StandUpMessage", client)
	PrintHintText(client, message)
}

public GlobalMessage(client)
{
	decl String:message[256]
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Format(message,sizeof(message), "%T", "GlobalMessage", i, client)
			PrintToChat(i, "\x04[AntiProne] \x01%s", message)
		}
	}
}

public Action:CheckProne(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= SPEC)
	{
		return Plugin_Handled
	}
	new Proned = GetEntProp(client, Prop_Send, "m_bProne")
	if(Proned == 1)
	{
		new damage = GetClientHealth(client)
		DealDamage(client, damage+1, client, 0, "AntiProne")
	}
	return Plugin_Handled
}

DealDamage(victim, damage, attacker = 0, dmg_type = 0, String:weapon[]="")
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16]
		IntToString(damage, dmg_str, 16)
		new String:dmg_type_str[32]
		IntToString(dmg_type,dmg_type_str, 32)
		new pointHurt = CreateEntityByName("point_hurt")
		if(pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "killme")
			DispatchKeyValue(pointHurt, "DamageTarget", "killme")
			DispatchKeyValue(pointHurt, "Damage", dmg_str)
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str)
			if(!StrEqual(weapon, ""))
			{
				DispatchKeyValue(pointHurt, "classname", weapon)
			}
			DispatchSpawn(pointHurt)
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1)
			DispatchKeyValue(pointHurt, "classname", "point_hurt")
			DispatchKeyValue(victim, "targetname", "dontkillme")
			RemoveEdict(pointHurt)
		}
	}
}