#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "FF Announcer",
	author = "Frustian, cravenge",
	description = "Provides Announcements For Friendly Fires.",
	version = "1.5",
	url = ""
};

ConVar hEnabled, hAnnounceMode, hAnnounceType, hReadyCVar;
bool bEnabled;
int iAnnounceMode, iAnnounceType;

int DamageCache[MAXPLAYERS+1][MAXPLAYERS+1];
Handle FFTimer[MAXPLAYERS+1] = INVALID_HANDLE;
bool FFActive[MAXPLAYERS+1];

public void OnPluginStart()
{
	CreateConVar("ff_announcer_version", "1.5", "FF Announcer Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	hEnabled = CreateConVar("ff_announcer_enabled", "1", "Enable/Disable Plugin", FCVAR_SPONLY|FCVAR_NOTIFY);
	hAnnounceMode = CreateConVar("ff_announcer_announce_mode", "1", "Announce Mode: 1=Involved Only, 2=Allies, 3=Enemy Team Only, 4=All Players", FCVAR_SPONLY|FCVAR_NOTIFY);
	hAnnounceType = CreateConVar("ff_announcer_announce_type", "0", "Announce Type: 0=Chat Text, 1=Hint Box", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	hReadyCVar = FindConVar("director_ready_duration");
	
	bEnabled = hEnabled.BoolValue;
	iAnnounceMode = hAnnounceMode.IntValue;
	iAnnounceType = hAnnounceType.IntValue;
	
	AutoExecConfig(true, "ff_announcer");
	
	HookConVarChange(hEnabled, ApplyCVarChanges);
	HookConVarChange(hAnnounceMode, ApplyCVarChanges);
	HookConVarChange(hAnnounceType, ApplyCVarChanges);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_hurt_concise", OnPlayerHurtConcise, EventHookMode_Post);
}

public void ApplyCVarChanges(Handle cvar, const char[] oldValue, const char[] newValue)
{
	bEnabled = hEnabled.BoolValue;
	iAnnounceMode = hAnnounceMode.IntValue;
	iAnnounceType = hAnnounceType.IntValue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (FFTimer[i] != INVALID_HANDLE)
			{
				KillTimer(FFTimer[i]);
				FFTimer[i] = INVALID_HANDLE;
			}
		}
	}
}

public Action OnPlayerHurtConcise(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled || hReadyCVar.IntValue == 0)
	{
		return;
	}
	
	int attacker = event.GetInt("attackerentid");
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(attacker) || !IsSurvivor(victim))
	{
		return;
	}
	
	int damage = event.GetInt("dmg_health");
	
	if (FFActive[attacker])
	{
		DamageCache[attacker][victim] += damage;
		
		Handle announcePack;
		KillTimer(FFTimer[attacker]);
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, announcePack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(announcePack, attacker);
		WritePackCell(announcePack, GetClientUserId(victim));
	}
	else
	{
		FFActive[attacker] = true;
		
		DamageCache[attacker][victim] = damage;
		
		Handle firstAnnouncePack;
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, firstAnnouncePack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(firstAnnouncePack, attacker);
		WritePackCell(firstAnnouncePack, GetClientUserId(victim));
	}
}

public Action AnnounceFF(Handle timer, Handle packCreated)
{
	ResetPack(packCreated);
	
	int shooter = ReadPackCell(packCreated);
	int aimed = GetClientOfUserId(ReadPackCell(packCreated));
	
	if (!IsSurvivor(shooter) || !FFActive[shooter] || !IsSurvivor(aimed) || iAnnounceMode < 1)
	{
		KillTimer(FFTimer[shooter]);
		FFTimer[shooter] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
	
	if (DamageCache[shooter][aimed] == 0)
	{
		FFActive[shooter] = false;
		
		KillTimer(FFTimer[shooter]);
		FFTimer[shooter] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
	
	switch (iAnnounceType)
	{
		case 0:
		{
			switch (iAnnounceMode)
			{
				case 1:
				{
					if (shooter != aimed)
					{
						PrintToChat(shooter, "\x05[FF Announcer]\x01 You Gave \x04%d\x01 Damage To \x03%N\x01!", DamageCache[shooter][aimed], aimed);
						PrintToChat(aimed, "\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To You!", shooter, DamageCache[shooter][aimed]);
					}
					else
					{
						PrintToChat(shooter, "\x05[FF Announcer]\x01 You Gave \x04%d\x01 Damage To Yourself!", DamageCache[shooter][aimed]);
					}
				}
				case 2:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(shooter) || GetClientTeam(i) != GetClientTeam(aimed))
						{
							continue;
						}
						
						if (shooter == aimed)
						{
							PrintToChat(i, "\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To Self!", shooter, DamageCache[shooter][aimed]);
						}
						else
						{
							PrintToChat(i, "\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To \x03%N\x01!", shooter, DamageCache[shooter][aimed], aimed);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(shooter) || GetClientTeam(i) == GetClientTeam(aimed))
						{
							continue;
						}
						
						if (shooter == aimed)
						{
							PrintToChat(i, "\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To Self!", shooter, DamageCache[shooter][aimed]);
						}
						else
						{
							PrintToChat(i, "\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To \x03%N\x01!", shooter, DamageCache[shooter][aimed], aimed);
						}
					}
				}
				case 4:
				{
					if (shooter != aimed)
					{
						PrintToChatAll("\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To \x03%N\x01!", shooter, DamageCache[shooter][aimed], aimed);
					}
					else
					{
						PrintToChatAll("\x05[FF Announcer]\x03 %N\x01 Gave \x04%d\x01 Damage To Self!", shooter, DamageCache[shooter][aimed]);
					}
				}
			}
		}
		case 1:
		{
			switch (iAnnounceMode)
			{
				case 1:
				{
					if (shooter != aimed)
					{
						PrintHintText(shooter, "[FF Announcer] You Gave %d Damage To %N!", DamageCache[shooter][aimed], aimed);
						PrintHintText(aimed, "[FF Announcer] %N Gave %d Damage To You!", shooter, DamageCache[shooter][aimed]);
					}
					else
					{
						PrintHintText(shooter, "[FF Announcer] You Gave %d Damage To Yourself!", DamageCache[shooter][aimed]);
					}
				}
				case 2:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(shooter) || GetClientTeam(i) != GetClientTeam(aimed))
						{
							continue;
						}
						
						if (shooter == aimed)
						{
							PrintHintText(i, "[FF Announcer] %N Gave %d Damage To Self!", shooter, DamageCache[shooter][aimed]);
						}
						else
						{
							PrintHintText(i, "[FF Announcer] %N Gave %d Damage To %N!", shooter, DamageCache[shooter][aimed], aimed);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(shooter) || GetClientTeam(i) == GetClientTeam(aimed))
						{
							continue;
						}
						
						if (shooter == aimed)
						{
							PrintHintText(i, "[FF Announcer] %N Gave %d Damage To Self!", shooter, DamageCache[shooter][aimed]);
						}
						else
						{
							PrintHintText(i, "[FF Announcer] %N Gave %d Damage To %N!", shooter, DamageCache[shooter][aimed], aimed);
						}
					}
				}
				case 4:
				{
					if (shooter != aimed)
					{
						PrintHintTextToAll("[FF Announcer] %N Gave %d Damage To %N!", shooter, DamageCache[shooter][aimed], aimed);
					}
					else
					{
						PrintHintTextToAll("[FF Announcer] %N Gave %d Damage To Self!", shooter, DamageCache[shooter][aimed]);
					}
				}
			}
		}
	}
	DamageCache[shooter][aimed] = 0;
	
	FFActive[shooter] = false;
	
	KillTimer(FFTimer[shooter]);
	FFTimer[shooter] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

