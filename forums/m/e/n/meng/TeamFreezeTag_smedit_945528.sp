#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "0.1"

new bool:enabled;
new Switch;
new UserMsg:g_textmsg;
new bool:Frozen[MAXPLAYERS + 1];
new PlayerScore[MAXPLAYERS + 1];
new PlayerLevel[MAXPLAYERS + 1];
new total_ts;
new frozen_ts;
new total_cts;
new frozen_cts;
new Handle:score = INVALID_HANDLE;
new g_WeaponParent;
new PlayerHP;
new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;

public Plugin:myinfo = 
{
	name = "freezetag",
	author = "meng",
	version = "PLUGIN_VERSION",
	description = "friendly game of tag",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("teamfreezetag_version", PLUGIN_VERSION, "Team Freeze Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	PlayerHP = FindSendPropOffs("CCSPlayer", "m_iHealth");
	VelocityOffset_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	VelocityOffset_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	BaseVelocityOffset = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	g_textmsg = GetUserMessageId("TextMsg");
	HookUserMessage(g_textmsg, UserMessageHook, true);
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_hurt", EventTagged);
	HookEvent("player_jump", EventPlayerJump, EventHookMode_Pre);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	RegAdminCmd("sm_freezetag", OnOffSwitch, ADMFLAG_RCON);
}

public OnConfigsExecuted()
{
	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
}

public Action:ScoreBoard(Handle:timer)
{
	PrintHintTextToAll("Frozen Players: T- %i/%i CT- %i/%i", frozen_ts, total_ts, frozen_cts, total_cts);
}

public OnClientPostAdminCheck(client)
{
	if (enabled)
	{
		PlayerScore[client] = 0;
		PlayerLevel[client] = 0;
	}
}

public OnClientDisconnect_Post()
{
	if (enabled)
		CheckFrozen();
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (enabled)
	{
		decl String:message[256];
		BfReadString(bf, message, sizeof(message));
		if (StrContains(message, "teammate_attack") != -1)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:OnOffSwitch(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_freezetag <1/0>");
		return Plugin_Handled;
	}
	new String:power[8];
	GetCmdArg(1, power, sizeof(power));
	Switch = StringToInt(power);
	if (Switch)
	{
		enabled = true;
		if (score == INVALID_HANDLE)
		{
			score = CreateTimer(1.0, ScoreBoard, _, TIMER_REPEAT);
		}
		ServerCommand("mp_restartgame 1");
	}
	else if (!Switch)
	{
		enabled = false;
		if (score != INVALID_HANDLE)
		{
			KillTimer(score);
			score = INVALID_HANDLE;
		}
		new maxent = GetMaxEntities(), String:ent[64];
		for (new i = GetMaxClients(); i < maxent; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEdictClassname(i, ent, sizeof(ent));
				if (StrContains(ent, "func_bomb_target") != -1 ||
				StrContains(ent, "func_hostage_rescue") != -1 ||
				StrContains(ent, "func_buyzone") != -1)
				{
					AcceptEntityInput(i,"Enable");
				}
			}
		}
		ServerCommand("mp_restartgame 1");
	}
	return Plugin_Continue;
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new maxent = GetMaxEntities(), String:ent[64];
		for (new i = GetMaxClients(); i < maxent; i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i))
			{
				GetEdictClassname(i, ent, sizeof(ent));
				if (StrContains(ent, "weapon_") != -1 && 
				GetEntDataEnt2(i, g_WeaponParent) == -1)
				{
					RemoveEdict(i);
				}
				if (StrContains(ent, "func_bomb_target") != -1 ||
				StrContains(ent, "func_hostage_rescue") != -1 ||
				StrContains(ent, "func_buyzone") != -1)
				{
					AcceptEntityInput(i,"Disable");
				}
			}
		}
		PrintToChatAll("\x04Team FreezeTag Enabled! \x03Freeze All Enemies To Win The Round!!!");
		CheckFrozen();
	}
}

Setup(client)
{
	Frozen[client] = false;
	SetEntData(client, PlayerHP, 500);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	if (PlayerScore[client] < 0)
	{
		PlayerScore[client] = 0;
		SetEntProp(client, Prop_Data, "m_iFrags", 0);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_iFrags", PlayerScore[client]);
	}
	new wepIdx;
	for (new i = 0; i < 6; i++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_scout");
	if (PlayerLevel[client] == 0)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	else if (PlayerLevel[client])
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1);
	}
}

UnFreeze(client)
{
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_scout");
	SetEntityRenderColor(client, 255, 255, 255, 255);
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, client, _, _, 0.3);
	if (PlayerLevel[client] == 0)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	else if (PlayerLevel[client])
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1);
	}
	Frozen[client] = false;
	CheckFrozen();
}

Freeze(client)
{
	new knife = GetPlayerWeaponSlot(client, 2);
	new scout = GetPlayerWeaponSlot(client, 0);
	RemovePlayerItem(client, knife);
	RemoveEdict(knife);
	RemovePlayerItem(client, scout);
	RemoveEdict(scout);
	SetEntityRenderColor(client, 0, 112, 160, 112);
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, client, _, _, 0.3);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityGravity(client, 1.0);
	Frozen[client] = true;
	CheckFrozen();
}

public EventPlayerJump(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (PlayerLevel[client] == 1)
		{
			SetEntityGravity(client, 0.9);
			/*new Float:finalvec[3];
			finalvec[0] = GetEntDataFloat(client,VelocityOffset_0)*0.2;
			finalvec[1] = GetEntDataFloat(client,VelocityOffset_1)*0.2;
			finalvec[2] = 10*50.0;
			SetEntDataVector(client, BaseVelocityOffset, finalvec, true);*/
		}
		if (PlayerLevel[client] == 2)
		{
			SetEntityGravity(client, 0.8);
			new Float:finalvec[3];
			finalvec[0] = GetEntDataFloat(client,VelocityOffset_0)*0.2;
			finalvec[1] = GetEntDataFloat(client,VelocityOffset_1)*0.2;
			finalvec[2] = 10*50.0;
			SetEntDataVector(client, BaseVelocityOffset, finalvec, true);
		}
	}
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (GetClientTeam(client) > 1)
			Setup(client);
	}
}

public EventTagged(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (enabled)
	{
		new tagged = GetClientOfUserId(GetEventInt(event,"userid"));
		new tagger = GetClientOfUserId(GetEventInt(event,"attacker"));
		if (tagger)
		{
			new taggedteam = GetClientTeam(tagged);
			new taggerteam = GetClientTeam(tagger);
			if (!Frozen[tagged] && taggedteam != taggerteam)
			{
				Freeze(tagged);
				if (PlayerScore[tagged] > 0)
				{
					PlayerScore[tagged] -= 1;
					SetEntProp(tagged, Prop_Data, "m_iFrags", PlayerScore[tagged]);
				}
				if (PlayerLevel[tagged] == 1 && PlayerScore[tagged] < 5)
				{
					PlayerLevel[tagged] = 0;
				}
				else if (PlayerLevel[tagged] == 2 && PlayerScore[tagged] < 10)
				{
					PlayerLevel[tagged] = 1;
				}
				PlayerScore[tagger]++;
				SetEntProp(tagger, Prop_Data, "m_iFrags", PlayerScore[tagger]);
				if (PlayerScore[tagger] >= 5 && PlayerLevel[tagger] < 1)
				{
					SetEntPropFloat(tagger, Prop_Data, "m_flLaggedMovementValue", 1.1);
					PlayerLevel[tagger] = 1;
					decl String:taggername[64];
					GetClientName(tagger, taggername, sizeof(taggername));
					PrintToChatAll("\x03%s is a Level 1 tagger!!!", taggername);
				}
				else if (PlayerScore[tagger] >= 10 && PlayerLevel[tagger] < 2)
				{
					SetEntPropFloat(tagger, Prop_Data, "m_flLaggedMovementValue", 1.2);
					PlayerLevel[tagger] = 2;
					decl String:taggername[64];
					GetClientName(tagger, taggername, sizeof(taggername));
					PrintToChatAll("\x03%s is a Level 2 tagger!!!", taggername);
				}
			}
			else if (Frozen[tagged] && taggedteam == taggerteam)
			{
				UnFreeze(tagged);
				PlayerScore[tagger]++;
				SetEntProp(tagger, Prop_Data, "m_iFrags", PlayerScore[tagger]);
				if (PlayerScore[tagger] >= 5 && PlayerLevel[tagger] < 1)
				{
					SetEntPropFloat(tagger, Prop_Data, "m_flLaggedMovementValue", 1.1);
					PlayerLevel[tagger] = 1;
					decl String:taggername[64];
					GetClientName(tagger, taggername, sizeof(taggername));
					PrintToChatAll("\x03%s is a Level 1 tagger!!!", taggername);
				}
				else if (PlayerScore[tagger] >= 10 && PlayerLevel[tagger] < 2)
				{
					SetEntPropFloat(tagger, Prop_Data, "m_flLaggedMovementValue", 1.2);
					PlayerLevel[tagger] = 2;
					decl String:taggername[64];
					GetClientName(tagger, taggername, sizeof(taggername));
					PrintToChatAll("\x03%s is a Level 2 tagger!!!", taggername);
				}
			}
		}
		SetEntData(tagged, PlayerHP, 500);
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (enabled)
		CheckFrozen();
}

CheckFrozen()
{
	total_ts = 0;
	frozen_ts = 0;
	total_cts = 0;
	frozen_cts = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			new team = GetClientTeam(i)
			if (team == 2)
				total_ts++;
			if (team == 2 && Frozen[i])
				frozen_ts++;
			if (team == 3)
				total_cts++;
			if (team == 3 && Frozen[i])
				frozen_cts++;
		}
	}
	WinCheck();
}

WinCheck()
{
	if (total_ts <= frozen_ts)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				FakeClientCommand(i,"kill");
			}
		}
	}
	else if (total_cts <= frozen_cts)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
			{
				FakeClientCommand(i,"kill");
			}
		}
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		new winner = GetEventInt(event, "winner");
		if (winner == 3)
			PrintToChatAll("\x03All Terrorists Have Been Frozen!!!");
		else if (winner == 2)
			PrintToChatAll("\x03All Counter-Terrorists Have Been Frozen!!!");
	}
}