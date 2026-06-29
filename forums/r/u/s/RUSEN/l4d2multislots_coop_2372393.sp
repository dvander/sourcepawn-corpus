#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#define CVAR_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY


new Handle:hMaxSurvivors;
bool TeleportReady;

public Plugin:myinfo =
{
	name = "L4D2 MultiSlots",
	description = "Handles bots in a 4+ coop game.",
	author = "SwiftReal, MI 5",
	version = "3.7.8",
	url = "N/A"
};

public OnPluginStart()
{
	CreateConVar("multislots_version", "3.7.8", "L4D2 MultiSlots version", 270656, false, 0.0, false, 0.0);
	SetConVarString(FindConVar("multislots_version"), "3.7.8", false, false);
	hMaxSurvivors = CreateConVar("l4d2_multislots_max_survivors", "24", "Maximum amount of survivors allowed", CVAR_FLAGS, true, 4.0, true, 25.0);
	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join survivors.", 0);
	RegAdminCmd("sm_afkspect", Spec, ADMFLAG_ROOT);
	HookEvent("player_activate", ePlayerActivate);
	HookEvent("bot_player_replace", bot_player_replace);
	HookEvent("finale_vehicle_leaving", eFinaleVehicleLeaving);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_first_spawn", eplayer_first_spawn);

	AutoExecConfig(true, "multislots", "sourcemod");
}

public OnMapStart()
{
	TweakSettings();
	TeleportReady = false;
	CreateTimer(60.0, TimerUnblockTeleport);
}

public Action:TimerUnblockTeleport(Handle:timer)
{
	TeleportReady = true;
	return Plugin_Stop;
}

public Action:Spec(client, args)
{
	if (client)
	{
		ChangeClientTeam(client, 1);
	}
	return Plugin_Handled;
}

public Action:JoinTeam(client, args)
{

	if(!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) == 3 || IsFakeClient(client))
		return Plugin_Handled;

	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == 2)
		{
			if(IsPlayerAlive(client))
			{
				PrintHintText(client, "You are already a survivor.");
				return Plugin_Handled;
			}
			else
			{
				if(!IsPlayerAlive(client))
				{
				PrintHintText(client, "You are dead. Rescue is comming soon.");
				return Plugin_Handled;
				}
			}
		}

		if(IsClientIdle(client))
		{
			PrintHintText(client, "Press left mouse to join the game.");
			return Plugin_Handled;
		}

		if(TotalFreeBots() == 0)
			{
				SpawnFakeClient();
				CreateTimer(1.5, Timer_AutoJoinTeamPA, client); 
			}

		else
			{
				TakeOverBot(client, false);
			}

	}
	return Plugin_Handled;
}

public ePlayerActivate(Handle:event, String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client)
	{
		if (GetClientTeam(client) != 2 && !IsFakeClient(client) && !IsClientIdle(client) && GetClientTeam(client) != 3)
		{
			CreateTimer(GetRandomFloat(5.5, 10.5) * 1.0, Timer_AutoJoinTeamPA, client);
		}
	}
}

public bot_player_replace(Handle:event, String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if (!client || !IsClientInGame(client) || !IsClientConnected(client) || GetClientTeam(client) != 2 || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
	
	if (TeleportReady)
	{
		CreateTimer(11.0, Timer_CheckClient, client);
	}
}

public eplayer_first_spawn(Handle:event, String:name[], bool:dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client || !IsClientInGame(client) || !IsClientConnected(client) || GetClientTeam(client) != 2 || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
	
	if (TeleportReady)
	{
		CreateTimer(10.0, Timer_CheckClient, client);
	}
}

public eFinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	new edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
		{
			float pos[3];
			GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
			for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i))
						{
							if (!IsFakeClient(i))
								{
									if((GetClientTeam(i) == 2) && IsPlayerAlive(i))
										{
											TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
										}
								}
						}
				}
		}
}

public Action:Timer_AutoJoinTeamPA(Handle:timer, any:client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == 3)
		return Plugin_Stop;

	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == 2)
		{
			return Plugin_Stop;
		}
		if(IsClientIdle(client))
		{
			return Plugin_Stop;
		}
		JoinTeam(client, 0);
	}
	return Plugin_Continue;
}

public evtBotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(GetClientTeam(bot) == 2 && client)
		{
			CreateTimer(2.0, Timer_KickNoNeededBot, bot, TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action:Timer_KickNoNeededBot(Handle:timer, any:bot)
{
	if((TotalSurvivors() <= 4))
		return Plugin_Stop;

	if(IsClientConnected(bot) && IsClientInGame(bot))
	{
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));

		if(StrEqual(BotName, "FakeClient", true))
			return Plugin_Stop;

		if(!HasIdlePlayer(bot) && GetClientTeam(bot) == 2)
		{
			KickClient(bot, "Kicking No Needed Bot");
		}
		else if (HasIdlePlayer(bot) && GetClientTeam(bot) == 2)
		{
			CreateTimer(8.0, Timer_KickBot, bot, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

public Action:Timer_KickBot(Handle:timer, any:bot)
{
	if(IsClientConnected(bot) && IsClientInGame(bot))
	{
		if(GetClientTeam(bot) == 2)
		{
			KickClient(bot, "Kicking No Needed Bot");
		}
	}
	return Plugin_Stop;
}

public Action:Timer_KickFakeBot(Handle:timer, any:userid)
{
	new fakeclient = GetClientOfUserId(userid);
	if (fakeclient && IsClientConnected(fakeclient) && IsClientInGame(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");
	}
	return Plugin_Stop;
}

public Action:Timer_CheckClient(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && client != i)
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(5.0, Mortal, client);
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(5.0, Mortal, i);
				float pos[3] = 0.0;
				GetClientAbsOrigin(i, pos);
				TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
				return Plugin_Stop;
				
			}
		}
	}

	return Plugin_Stop;
}

public Action:Mortal(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

stock TweakSettings()
{
	new Handle:hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 24.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, GetConVarInt(hMaxSurvivors));
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
}

TakeOverBot(client, bool:completely)
{
	if (!IsClientInGame(client) || !IsClientConnected(client) || GetClientTeam(client) == 2 || IsFakeClient(client))
		return;

	new bot = FindBotToTakeOver();
	if (bot==0)
	{
		PrintHintText(client, "There are no survivor bots to take over.");
		return;
	}
	
	static Handle:hSetHumanSpec;
	if (!hSetHumanSpec)
	{
		new Handle:hGameConf = LoadGameConfigFile("multislots");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	}
	static Handle:hTakeOverBot;
	if (!hTakeOverBot)
	{
		new Handle:hGameConf = LoadGameConfigFile("multislots");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
	}
	if (completely)
	{
		SDKCall(hSetHumanSpec, bot, client);
		SDKCall(hTakeOverBot, client, true);
	}
	else
	{
		SDKCall(hSetHumanSpec, bot, client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	}
	return;
}

FindBotToTakeOver()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !HasIdlePlayer(i))
			{
				return i;
			}
		}
	}
	return 0;
}

SpawnFakeClient()
{
	new fakeclient = CreateFakeClient("FakeClient");
	bool fakeclientKicked;

	if (fakeclient)
	{
		ChangeClientTeam(fakeclient, 2);
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			if (DispatchSpawn(fakeclient) == true)
			{
				CreateTimer(0.1, Timer_KickFakeBot, GetClientUserId(fakeclient), 1);
				fakeclientKicked = true;
			}
		}
		if (fakeclientKicked)
		{
			KickClient(fakeclient, "Kicking FakeClient");
		}
		else
		{
			KickClient(fakeclient, "Kicking FakeClient: error");
		}
	}
	return fakeclientKicked;
}

stock TotalSurvivors()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
			if (GetClientTeam(i) == 2)
			{
				count++;
			}
	}
	return count;
}

stock TotalFreeBots()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				if (!HasIdlePlayer(i))
				{
					count++;
				}
			}
		}
	}
	return count;
}

bool:HasIdlePlayer(bot)
{
	if (IsValidEntity(bot))
	{
		char sClass[64];
		new PropFieldType:proptype;
		if (IsClientConnected(bot) && IsClientInGame(bot))
		{
			if (GetClientTeam(bot) == 2 && IsPlayerAlive(bot))
			{
				GetEntityNetClass(bot, sClass, 64);
				if (IsFakeClient(bot) && FindSendPropInfo(sClass, "m_humanSpectatorUserID", proptype) > 0)
				{
					int idler = GetClientOfUserId(GetEntProp(bot, PropType:0, "m_humanSpectatorUserID"));
					if (idler)
					{
						if (IsClientInGame(idler) && !IsFakeClient(idler) && GetClientTeam(idler) == 1)
						{
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

bool:IsClientIdle(client)
{
	if (IsValidEntity(client))
	{
		char sClass[64];
		new PropFieldType:proptype;
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					GetEntityNetClass(i, sClass, 64);
					if (IsFakeClient(i) && FindSendPropInfo(sClass, "m_humanSpectatorUserID", proptype) > 0)
					{
						int idler = GetClientOfUserId(GetEntProp(i, PropType:0, "m_humanSpectatorUserID"));
						if (client == idler)
						{
							if (IsClientInGame(idler) && !IsFakeClient(idler) && GetClientTeam(idler) == 1)
							{
								return true;
							}
						}
					}
				}
			}
		}
	}
	return false;
}