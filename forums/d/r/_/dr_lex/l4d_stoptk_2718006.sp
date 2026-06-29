#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

char sg_file1[160];
char sg_file2[160];
char weapon[32];

float ig_TKPoints[MAXPLAYERS+1];

int ig_time_wp[MAXPLAYERS+1];
int ig_time_wp_turbo[MAXPLAYERS+1];
int ig_time_nospam[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D2] TK points",
	author = "dr_lex",
	description = "",
	version = "1.5.2",
	url = "https://steamcommunity.com/id/dr_lex/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_tk", CMD_Tk);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("finale_win", Event_MapTransition);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	
	BuildPath(Path_SM, sg_file1, sizeof(sg_file1)-1, "data/GagMuteBan.txt");
}

public void OnConfigsExecuted()
{
	char sBuf[12];
	
	FormatTime(sBuf, sizeof(sBuf)-1, "%Y-%U", GetTime());
	BuildPath(Path_SM, sg_file2, sizeof(sg_file2)-1, "data/%s_TK.txt", sBuf);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		CreateTimer(5.0, HxTimerClientPost, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action HxTimerClientPost(Handle timer, any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		LoadingBase(client);
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		UpDateTKPoints(client);
	}
}

public void HxEyeAngles(int &client, float dmg)
{
	float f1[3];
	GetClientEyeAngles(client, f1);
	f1[0] += dmg;
	f1[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, f1, NULL_VECTOR);
}

public Action CMD_Tk(int client, int args)
{
	if (client)
	{
		PrintToChat(client, "\x04[!tk]\x03 %f TK-points (10.0 TK-points = Ban)", ig_TKPoints[client]);
	}
	return Plugin_Handled;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = event.GetInt("attacker");
	if (iAttacker > 0)
	{
		int iUserid = event.GetInt("userid");
		if (iUserid > 0)
		{
			if (iAttacker != iUserid)
			{
				iAttacker = GetClientOfUserId(iAttacker);
				iUserid = GetClientOfUserId(iUserid);

				event.GetString("weapon", weapon, sizeof(weapon)-10);
				
				if (GetClientTeam(iAttacker) == 2)
				{
					if (!IsFakeClient(iUserid))
					{
						if (GetClientTeam(iUserid) == 2)
						{
							if (!IsPlayerBussy(iUserid))
							{
								if (StrEqual(weapon, "rifle", true))
								{
									HxEyeAngles(iAttacker, -5.0);
									ig_TKPoints[iAttacker] += 0.2;
									return Plugin_Continue;
								}
								
								if (StrEqual(weapon, "smg", true))
								{
									HxEyeAngles(iAttacker, -3.0);
									ig_TKPoints[iAttacker] += 0.1;
									return Plugin_Continue;
								}
								
								if (StrEqual(weapon, "pumpshotgun", true))
								{
									HxEyeAngles(iAttacker, -2.0);
									ig_TKPoints[iAttacker] += 0.1;
									return Plugin_Continue;
								}
								
								if (StrEqual(weapon, "autoshotgun", true))
								{
									HxEyeAngles(iAttacker, -3.0);
									ig_TKPoints[iAttacker] += 0.2;
									return Plugin_Continue;
								}
								
								if (StrEqual(weapon, "hunting_rifle", true))
								{
									HxEyeAngles(iAttacker, -2.0);
									ig_TKPoints[iAttacker] += 0.1;
									return Plugin_Continue;
								}
								
								if (event.GetInt("type") & 8)
								{
									ig_TKPoints[iAttacker] += 0.005;
								}
								
								if (ig_time_nospam[iAttacker] < GetTime())
								{
									ig_time_nospam[iAttacker] = GetTime() + 3;
									
									PrintToChat(iAttacker, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
									PrintToChat(iUserid, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
									CreateTimer(3.0, HxChat, iAttacker, TIMER_FLAG_NO_MAPCHANGE);
								}
								
								if (ig_TKPoints[iAttacker] > 10.0)
								{
									UpDateTKPoints(iAttacker);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action HxChat(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[client]);
	}
	return Plugin_Stop;
}

public Action Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(event.GetInt("userid"));
		if (iAttacker != iUserid)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (!IsFakeClient(iUserid))
				{
					if (GetClientTeam(iAttacker) == 2)
					{
						if (GetClientTeam(iUserid) == 2)
						{
							ig_TKPoints[iAttacker] += 0.5;

							if (ig_time_wp[iAttacker] < GetTime())
							{
								ig_time_wp[iAttacker] = GetTime() + 20;
							}
							else
							{
								ig_time_wp[iAttacker] = GetTime() + 20;
								if (ig_time_wp_turbo[iAttacker] < GetTime())
								{
									ig_time_wp_turbo[iAttacker] = GetTime() + 10;
									ig_TKPoints[iAttacker] += 1.0;
									PrintToChat(iAttacker, "\x04[!tk]\x03 +1.0 TK-points");
								}
								else
								{
									ig_time_wp_turbo[iAttacker] = GetTime() + 10;
									ig_TKPoints[iAttacker] += 2.0;
									PrintToChat(iAttacker, "\x04[!tk]\x03 +2.0 TK-points");
								}
							}
							
							PrintToChat(iAttacker, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
							PrintToChat(iAttacker, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iAttacker]);
							PrintToChat(iUserid, "\x04[!tk]\x03 %N \x04 attacked \x03 %N", iAttacker, iUserid);
							PrintToChat(iUserid, "\x04[!tk]\x05 %N \x03 %f TK-points", iAttacker, ig_TKPoints[iAttacker]);
							
							if (ig_TKPoints[iAttacker] > 10.0)
							{
								UpDateTKPoints(iAttacker);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (iAttacker)
	{
		int iUserid = GetClientOfUserId(GetEventInt(event, "userid"));
		if (iUserid > 0)
		{
			if (!IsFakeClient(iAttacker))
			{
				if (!IsFakeClient(iUserid))
				{
					if (GetClientTeam(iUserid) == 2)
					{
						if (iAttacker != iUserid)
						{
							ig_TKPoints[iAttacker] += 3.0;
							if (ig_TKPoints[iAttacker] > 10.0)
							{
								UpDateTKPoints(iAttacker);
							}
							PrintToChat(iAttacker, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iAttacker]);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	int iUserid = GetClientOfUserId(event.GetInt("userid"));

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				ig_TKPoints[iUserid] -= 1.0;
				if (ig_TKPoints[iUserid] < 0.0)
				{
					ig_TKPoints[iUserid] = 0.0;
				}

				PrintToChat(iUserid, "\x04[!tk]\x03 %f TK-points ", ig_TKPoints[iUserid]);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iSubject = GetClientOfUserId(event.GetInt("subject"));
	int iUserid = GetClientOfUserId(event.GetInt("userid"));

	if (iSubject != iUserid)
	{
		if (!IsFakeClient(iSubject))
		{
			if (!IsFakeClient(iUserid))
			{
				ig_TKPoints[iUserid] -= 0.3;
				if (ig_TKPoints[iUserid] < 0.0)
				{
					ig_TKPoints[iUserid] = 0.0;
				}
				
				PrintToChat(iUserid, "\x04[!tk]\x03 %f TK-points", ig_TKPoints[iUserid]);
			}
		}
	}
	return Plugin_Continue;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (GetClientTeam(i) == 2)
				{
					ig_TKPoints[i] -= 1.0;
					if (ig_TKPoints[i] < 0.0)
					{
						ig_TKPoints[i] = 0.0;
					}
					
					UpDateTKPoints(i);
				}
			}
		}
		i += 1;
	}
}

stock void LoadingBase(int client)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("data");
		if (hGM.ImportFromFile(sg_file2))
		{
			char s1[24];
			GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);
			
			if (hGM.JumpToKey(s1))
			{
				ig_TKPoints[client] = hGM.GetFloat("Autoban", 0.0);
			}
			else
			{
				ig_TKPoints[client] = 0.0;
			}
		}
		delete hGM;
	}
}

stock void UpDateTKPoints(int client)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("data");
		hGM.ImportFromFile(sg_file2);
		
		char s1[24];
		GetClientAuthId(client, AuthId_Steam2, s1, sizeof(s1)-1);

		hGM.JumpToKey(s1, true);
		
		if (ig_TKPoints[client] > 10.0)
		{
			ig_TKPoints[client] = 0.0;
			if (HxClientTimeBan(client))
			{
				PrintToChatAll("\x04[!tk]\x05 %d min ban:\x04 %N", 60*6, client);
				KickClient(client, "%d Min ban.", 60*6);
			}
		}
		
		if (ig_TKPoints[client] == 0.0)
		{
			hGM.DeleteThis();
		}
		else
		{
			hGM.SetFloat("Autoban", ig_TKPoints[client]);
		}

		hGM.Rewind();
		hGM.ExportToFile(sg_file2);
		delete hGM;
	}
}

stock int HxClientTimeBan(int client)
{
	if (client)
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_file1);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeBan = GetTime() + 60*60*24;
		
		hGM.SetString("Name", sName);
		hGM.SetNum("ban", iTimeBan);
		hGM.Rewind();
		hGM.ExportToFile(sg_file1);
		delete hGM;
		return 1;
	}
	return 0;
}

stock bool IsPlayerBussy(int client)
{
	if (IsPlayerIncapped(client))
	{
		return true;
	}
	if (IsSurvivorBussy(client))
	{
		return true;
	}
	return false;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	return false;
}

stock bool IsSurvivorBussy(int client)
{
	return GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 || GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 || (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0);
}