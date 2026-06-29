#include <sourcemod>
#include <cstrike>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <basecomm>

public Plugin:myinfo =
{
	name = "Jail Muter v2",
	author = "rodipm",
	description = "This plugin is for jail servers, it mutes players on round_start and when they die.",
	version = "1.2",
	url = "sourcemod.net"
}

new Handle:jailmuter_ligado;
new Handle:jailmuter_adm;
new Handle:jailmuter_morto;
new Handle:jailmuter_tempo;

public OnPluginStart()
{
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("player_death", player_death);
	
	jailmuter_ligado = CreateConVar("sm_jailmuter_on", "1", "Turns on or off the jailmuter; 0- Off / 1- on");
	jailmuter_adm = CreateConVar("sm_jailmuter_adm", "1", "If activated admins will not be muted and will listen to dead players even alive; 0- Off / 1- On");
	jailmuter_morto = CreateConVar("sm_jailmuter_dead", "1", "If activated dead players will be allowed to talk with another dead players, if not they will be fully muted; 0- Off / 1- On");
	jailmuter_tempo = CreateConVar("sm_jailmuter_time", "15", "Sets the time the players will be muted in round start");
	
	HookConVarChange(jailmuter_ligado, LigadoChanged);
	HookConVarChange(jailmuter_morto, MortoChanged);
	HookConVarChange(jailmuter_adm, AdmChanged);
	HookConVarChange(jailmuter_tempo, TempoChanged);
}

stock bool:AdmMuted(client)
{
	if(BaseComm_IsClientGagged(client))
		return true;
	if(BaseComm_IsClientMuted(client))
		return true;
	
	return false;
}

public LigadoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 sm_jailmuter_on %s", newValue);
}

public MortoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 sm_jailmuter_dead %s", newValue);
}

public AdmChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 sm_jailmuter_adm %s", newValue);
}

public TempoChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 sm_jailmuter_time %s", newValue);
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(jailmuter_ligado) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && !AdmMuted(i))
			{
				if(GetConVarInt(jailmuter_adm) == 1)
				{
					if(GetClientTeam(i) == CS_TEAM_T && IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) == INVALID_ADMIN_ID)
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}
				}
				else
				{
					if(GetClientTeam(i) == CS_TEAM_T && IsClientConnected(i) && IsClientInGame(i))
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}
				}
			}
		}
		new tempo = GetConVarInt(jailmuter_tempo);
		new Float:fTempo = float(tempo);
		PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 All Tr's were muted for \x01%i\x03 seconds!", tempo);
		CreateTimer(fTempo, TimerUnmute);
	}
	else
	{
		PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 The plugin is off!");
	}
}

public Action:TimerUnmute(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !AdmMuted(i))
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
	PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 All players were unmutted");
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(jailmuter_ligado) == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !AdmMuted(i))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
		
		for(new i = 1; i <= MaxClients; i++)
		{
			for(new j = 1; j <= MaxClients; j++)
			{
				if(IsClientConnected(i) && IsClientInGame(i) && IsClientConnected(j) && IsClientInGame(j))
				{
					SetListenOverride(i, j, Listen_Default);
				}
			}
		}
		PrintToChatAll("\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 All players were unmutted");	
	}
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetConVarInt(jailmuter_ligado) == 1 && !AdmMuted(client))
	{
		if(GetConVarInt(jailmuter_morto) == 1)
		{
			if(GetConVarInt(jailmuter_adm) == 1)
			{
				if(GetUserAdmin(client) == INVALID_ADMIN_ID)
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetUserAdmin(i) == INVALID_ADMIN_ID)
						{
							SetListenOverride(i, client, Listen_No);
						}
					}
					PrintToChat(client, "\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 You were muted for alive players, but you can still talk to dead players!");
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
					{
						SetListenOverride(i, client, Listen_No);
					}
				}
				PrintToChat(client, "\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 You were muted for alive players, but you can still talk to dead players!");
			}
		}
		else
		{
			if(GetConVarInt(jailmuter_adm) == 1)
			{
				if(GetUserAdmin(client) == INVALID_ADMIN_ID)
				{
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetUserAdmin(i) == INVALID_ADMIN_ID)
						{
							SetClientListeningFlags(i, VOICE_MUTED);
						}
					}
					PrintToChat(client, "\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 You were muted!");
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}
				}
				PrintToChat(client, "\x04[Jail Muter 2.0 \x01By.:RpM\x04]\x03 You were muted!");
			}
		}
	}
}