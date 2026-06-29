#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

public Plugin myinfo =
{
	name = "DoD Anti-Prone Source",
	author = "FeuerSturm, Micmacx",
	description = "Disallow player to go prone (MGs + Snipers can be excluded!)",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
}

#define SPEC	1
#define ALLIES	2
#define AXIS	3

Handle DoDAPStatus = INVALID_HANDLE
Handle DoDAPCPProne = INVALID_HANDLE
Handle DoDAPAllowMG = INVALID_HANDLE
Handle DoDAPAllowSniper = INVALID_HANDLE
Handle DoDAPProneTimer = INVALID_HANDLE
Handle DoDAPUseSound = INVALID_HANDLE
Handle DoDAPUseMsg = INVALID_HANDLE
Handle DoDAPGlobalMsg = INVALID_HANDLE
Handle TimerStandUp[MAXPLAYERS+1]
bool StandUp[MAXPLAYERS+1]
float gLastProne[MAXPLAYERS+1]
char Sound[4][PLATFORM_MAX_PATH] = { "", "", "player/american/us_changeposition.wav", "player/german/ger_changeposition.wav" }

public void OnPluginStart()
{
	CreateConVar("dod_antiprone_version", PLUGIN_VERSION, "DoD AntiProne Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_antiprone_version"),PLUGIN_VERSION)
	DoDAPStatus = CreateConVar("dod_antiprone_status", "1", "<1/0> = enable/disable AntiProne", _, true, 0.0, true, 1.0)
	DoDAPCPProne = CreateConVar("dod_antiprone_cpallowprone", "1", "<1/0> = allow/disallow proning at CapturePoints", _, true, 0.0, true, 1.0)
	DoDAPAllowMG = CreateConVar("dod_antiprone_mgallowprone", "1", "<1/0> = allow/disallow proning for MGs", _, true, 0.0, true, 1.0)
	DoDAPAllowSniper = CreateConVar("dod_antiprone_sniperallowprone", "0", "<1/0> = allow/disallow proning for Snipers", _, true, 0.0, true, 1.0)
	DoDAPProneTimer = CreateConVar("dod_antiprone_standuptimer", "10", "<0/#> = time in seconds players are allowed to stay prone  -  0 = immediately stand up again", _, true, 0.0)
	DoDAPUseMsg = CreateConVar("dod_antiprone_displaymessage", "1", "<1/0> = enable/disable displaying message when forcing players to stand up again", _, true, 0.0, true, 1.0)
	DoDAPUseSound = CreateConVar("dod_antiprone_playsound", "1", "<1/0> = enable/disable playing sound when forcing players to stand up again", _, true, 0.0, true, 1.0)
	DoDAPGlobalMsg = CreateConVar("dod_antiprone_globalmessage", "1", "<1/0> = enable/disable displaying a global message to all players when forcing players to stand up again", _, true, 0.0, true, 1.0)
	AutoExecConfig(true, "dod_antiprone_source", "dod_antiprone_source")
	LoadTranslations("dod_antiprone_source.txt")
}

public void OnMapStart()
{
	PrecacheSound(Sound[ALLIES])
	PrecacheSound(Sound[AXIS])
	reset_handle()
}

public void OnClientPutInServer(int client)
{
	ResetTimer(client)
	gLastProne[client] = GetGameTime()
}

public void OnClientDisconnect(int client)
{
	ResetTimer(client)
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float vel[3], float angles[3], int &iWeapon)
{
	if(GetConVarInt(DoDAPStatus) == 0)
	{
		return Plugin_Continue
	}
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		int Proned = GetEntProp(client, Prop_Send, "m_bProne")
		if(Proned == 1)
		{
			char CurWeapon[32];
			GetClientWeapon(client, CurWeapon, sizeof(CurWeapon))
			if(((strcmp(CurWeapon, "weapon_mg42", true) == 0 || strcmp(CurWeapon, "weapon_30cal", true) == 0) && GetConVarInt(DoDAPAllowMG) == 1) || ((strcmp(CurWeapon, "weapon_k98_scoped", true) == 0 || strcmp(CurWeapon, "weapon_spring", true) == 0) && GetConVarInt(DoDAPAllowSniper) == 1))
			{
				// DO NOTHING, PRONING ALLOWED!
			}	
			else
			{
				int CPIndex = GetEntProp(client, Prop_Send, "m_iCPIndex")
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
						iButtons |= IN_ALT1
						SetEntProp(client, Prop_Data, "m_nButtons", iButtons)
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
					iButtons |= IN_ALT1
					SetEntProp(client, Prop_Data, "m_nButtons", iButtons)
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
		int Proned = GetEntProp(client, Prop_Send, "m_bProne")
		if(Proned != 1)
		{
			ResetTimer(client)
			return Plugin_Continue
		}
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action StandUpTimer(Handle timer, int client)
{
	TimerStandUp[client] = INVALID_HANDLE
	StandUp[client] = true
	return Plugin_Handled
}

public void ResetTimer(int client)
{
	if(TimerStandUp[client] != INVALID_HANDLE)
	{
		CloseHandle(TimerStandUp[client])
		TimerStandUp[client] = INVALID_HANDLE
	}
	StandUp[client] = false
}

public void PlaySound(int client)
{
	int team = GetClientTeam(client)
	EmitSoundToClient(client, Sound[team], SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
}

public void DisplayMessage(int client)
{
	char message[256]
	Format(message,sizeof(message), "%T", "StandUpMessage", client)
	PrintHintText(client, message)
}

public void GlobalMessage(int client)
{
	char message[256]
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Format(message,sizeof(message), "%T", "GlobalMessage", i, client)
			PrintToChat(i, "\x04[DoD AntiProne] \x01%s", message)
		}
	}
}

public Action CheckProne(Handle timer, int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= SPEC)
	{
		return Plugin_Handled
	}
	int Proned = GetEntProp(client, Prop_Send, "m_bProne")
	if(Proned == 1)
	{
		int damage = GetClientHealth(client)
		DealDamage(client, damage+1, client, 0, "AntiProne")
	}
	return Plugin_Handled
}

void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = 0, char weapon[64])
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		char dmg_str[16]
		IntToString(damage, dmg_str, 16)
		char dmg_type_str[32]
		IntToString(dmg_type,dmg_type_str, 32)
		int pointHurt = CreateEntityByName("point_hurt")
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

void reset_handle()
{
	for(int i = 1; i<sizeof(TimerStandUp); i++)
	{
		if (TimerStandUp[i] != INVALID_HANDLE) 
		{
			CloseHandle(TimerStandUp[i]);
			TimerStandUp[i] = INVALID_HANDLE
		}
	}
	for(int i = 1; i<sizeof(StandUp); i++)
	{
			StandUp[i] = false
	}
}
