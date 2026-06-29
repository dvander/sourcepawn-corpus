#include <sourcemod>
#include <sdktools>
#include <colors>

new g_WaitingTime;
new g_SlapingAmount;
new g_ExtraHealth;
new Float:g_IgniteTime;
new Float:g_GodModeTime;
new Float:g_SnailTime;
new Float:g_SnailMultiplier;
new Float:g_InvisibilityTime;
new Float:g_FreezeTime;
new Float:g_InstantTime;
new Float:g_SpeedTime;
new Float:g_SpeedMultiplier;
new Float:g_DrugTime;
new Float:g_AmmoTime;
new Float:g_BeaconTime;
new Float:g_GravityTime;
new Float:g_GravityMultiplier;

#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

new bool:IsRtdInUse;
new bool:AllowedToUse[MAXPLAYERS +1];
new bool:NeedTimer[MAXPLAYERS +1];
new bool:HasInstant[MAXPLAYERS +1];

new Handle: g_hTimer = INVALID_HANDLE;

new g_TimeLeft[MAXPLAYERS +1];
new g_Count;
new g_Health;
new g_ActiveOffset = 1896;
new g_ClipOffset = 1204;
new g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };
new g_BeamSprite;
new g_HaloSprite;
new g_Serial_Gen = 0;

new Float:g_Speed;
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

new redColor[4]	= {255, 75, 75, 255};
new greenColor[4] = {75, 255, 75, 255};
new blueColor[4] = {75, 75, 255, 255};
new greyColor[4] = {128, 128, 128, 255};

public Plugin:myinfo=
{
	name = "[CSS] Roll The Dice",
	author = "John B.",
	description = "_",
	version = "0.4",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	ReadConfig();

	RegConsoleCmd("say", Cmd_Chat);
	RegConsoleCmd("say_team", Cmd_Chat);

	CreateTimer(1.0, Timer_DoTimedActions, _, TIMER_REPEAT);

	g_ActiveOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	g_ClipOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
}

public OnMapStart()
{
	IsRtdInUse = false;
	g_hTimer = INVALID_HANDLE;

	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
	PrecacheSound("buttons/blip1.wav", true);

	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnClientPutInServer(client)
{
	AllowedToUse[client] = true;
	NeedTimer[client] = false;
	HasInstant[client] = false;

	g_TimeLeft[client] = 0;
}

public Action:Cmd_Chat(client, args)
{
	if(client <= 0)
	{
		return Plugin_Handled;
	}

	new team = GetClientTeam(client);
	
	decl String:ChatMsg[16];
	GetCmdArg(1, ChatMsg, sizeof(ChatMsg));

	if(team == 2 || team == 3)
	{
		if(IsClientConnected(client) && IsPlayerAlive(client))
		{
			if(StrEqual(ChatMsg, "rtd") && IsRtdInUse)
			{
				CPrintToChatEx(client, client, "{green}[RTD] {default}Rtd is used by an other player, please wait...");

				return Plugin_Handled;
			}
			else if(StrEqual(ChatMsg, "rtd") && !AllowedToUse[client])
			{
				decl String:sTimeLeft[8];
				IntToString(g_TimeLeft[client], sTimeLeft, sizeof(sTimeLeft));
				CPrintToChatEx(client, client, "{green}[RTD] {default}You have to wait {olive}%s seconds{default}...", sTimeLeft);

				return Plugin_Handled;
			}
			else if(StrEqual(ChatMsg, "rtd") && AllowedToUse[client] && !IsRtdInUse)
			{
				IsRtdInUse = true;
				SelectAction(client);
				AllowedToUse[client] = false;
				g_TimeLeft[client] = g_WaitingTime;

				return Plugin_Handled;
 			}
		}
	}
	else if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if(StrEqual(ChatMsg, "rtd"))
		{
			CPrintToChatEx(client, client, "{green}[RTD] {default}You have to be alive to use rtd");
	
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_DoTimedActions(Handle:timer)
{
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && NeedTimer[i])
		{
			if(g_TimeLeft[i] > 1)
			{
				g_TimeLeft[i]--;
			}
			else if(g_TimeLeft[i] <= 1)
			{
				AllowedToUse[i] = true;
				NeedTimer[i] = false;
			}
		}
	}

	return Plugin_Continue;
}

stock ReadConfig()
{
	new String:sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/css_rtd.txt");

	new Handle:kv = CreateKeyValues("Config");
	FileToKeyValues(kv, sConfigFile);
	
	if(!FileExists(sConfigFile))
	{
		LogError("[RTD] Plugin couldn't find config file, so it's using the default values");
	}
	
	g_WaitingTime = RoundFloat(KvGetFloat(kv, "waiting_time", 90.0));
	g_SlapingAmount = KvGetNum(kv, "slaping_amount", 30);
	g_ExtraHealth = KvGetNum(kv, "extra_health", 50);
	g_IgniteTime = KvGetFloat(kv, "ignite_time", 10.0);
	g_GodModeTime = KvGetFloat(kv, "godmode_time", 15.0);
	g_SnailTime = KvGetFloat(kv, "snail_time", 15.0);
	g_SnailMultiplier = KvGetFloat(kv, "snail_multiplier", 0.3);
	g_InvisibilityTime = KvGetFloat(kv, "invisibility_time", 15.0);
	g_FreezeTime = KvGetFloat(kv, "freeze_time", 15.0);
	g_InstantTime =	KvGetFloat(kv, "instant_time", 15.0);
	g_SpeedTime = KvGetFloat(kv, "speed_time", 15.0);
	g_SpeedMultiplier = KvGetFloat(kv, "speed_multiplier", 1.5);
	g_DrugTime = KvGetFloat(kv, "drug_time", 15.0);
	g_AmmoTime = KvGetFloat(kv, "ammo_time", 20.0);
	g_BeaconTime = KvGetFloat(kv, "beacon_time", 15.0);
	g_GravityTime = KvGetFloat(kv, "gravity_time", 20.0);
	g_GravityMultiplier = KvGetFloat(kv, "gravity_multiplier", 0.4);
	
	CloseHandle(kv);
}

stock SelectAction(client)
{
	new randomint = GetRandomInt(0, 13);

	switch(randomint)
	{
		case 0: Slap_Player(client);
		case 1: Set_Health(client);
		case 2: Burn_Player(client);
		case 3: Set_GodMode(client);
		case 4: Snail_Player(client);
		case 5: Invisible_Player(client);
		case 6: Freeze_Player(client);
		case 7: Instant_Kills(client);
		case 8: Slay_Player(client);
		case 9: Speed_Player(client);
		case 10: Drug_Player(client);
		case 11: Ammo_Player(client);
		case 12: Beacon_Player(client);
		case 13: Gravity_Player(client);
	}
}

stock Slap_Player(client)
{
	SlapPlayer(client, g_SlapingAmount, true);

	decl String:sSlapingAmount[8];
	IntToString(g_SlapingAmount, sSlapingAmount, sizeof(sSlapingAmount));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}got slaped by {olive}%s hps", client, sSlapingAmount);

	IsRtdInUse = false;
	NeedTimer[client] = true;
}

stock Set_Health(client)
{
	new health = GetClientHealth(client);
	SetEntityHealth(client, health + g_ExtraHealth);

	decl String:sHealthPoints[8];
	IntToString(g_ExtraHealth, sHealthPoints, sizeof(sHealthPoints));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}got healed by {olive}%s hps", client, sHealthPoints);

	IsRtdInUse = false;
	NeedTimer[client] = true;
}

public Action:Timer_Ignite(Handle:timer, any:client)
{
	IsRtdInUse = false;
	NeedTimer[client] = true;

	return Plugin_Handled;
}

stock Burn_Player(client)
{
	new rounded = RoundFloat(g_IgniteTime)

	decl String:sIgniteTime[8];
	IntToString(rounded, sIgniteTime, sizeof(sIgniteTime));
	
	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}was {olive}set on fire {default}for {olive}%s seconds", client , sIgniteTime);

	IgniteEntity(client, g_IgniteTime, false, 0.0, false);

	CreateTimer(g_IgniteTime, Timer_Ignite, client);
}

public Action:Timer_GodMode(Handle:timer, any:client)
{
	new Float:float_settimes = g_GodModeTime / 0.1;
	new settimes = RoundFloat(float_settimes);

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			SetEntityHealth(client, 500);
			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			SetEntityHealth(client, g_Health);
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Set_GodMode(client)
{
	new rounded = RoundFloat(g_GodModeTime);
	g_Health = GetClientHealth(client);
	
	decl String:sGodModeTime[8];
	IntToString(rounded, sGodModeTime, sizeof(sGodModeTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has {olive}godmode {default}for {olive}%s seconds", client, sGodModeTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(0.1, Timer_GodMode, client, TIMER_REPEAT);
	}
}

public Action:Timer_Snail(Handle:time, any:client)
{
	new Float:float_settimes = g_SnailTime / 0.1;
	new settimes = RoundFloat(float_settimes);

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_SnailMultiplier);
			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Speed);
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Snail_Player(client)
{
	new rounded = RoundFloat(g_SnailTime);
	g_Speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");

	decl String:sSnailTime[8];
	IntToString(rounded, sSnailTime, sizeof(sSnailTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}will be a {olive}snail {default}for {olive}%s seconds", client, sSnailTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(0.1, Timer_Snail, client, TIMER_REPEAT);
	}
}

public Action:Timer_Invisibility(Handle:timer, any:client)
{
	SetEntityRenderMode(client, RENDER_NORMAL);

	IsRtdInUse = false;
	NeedTimer[client] = true;

	return Plugin_Handled;
}

stock Invisible_Player(client)
{
	new rounded = RoundFloat(g_InvisibilityTime);

	decl String:sInvisTime[8];
	IntToString(rounded, sInvisTime, sizeof(sInvisTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}will be {olive}invisible {default}for {olive}%s seconds", client, sInvisTime);

	SetEntityRenderMode(client, RENDER_NONE);

	CreateTimer(g_InvisibilityTime, Timer_Invisibility, client);
}

public Action:Timer_Freeze(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 255);

	IsRtdInUse = false;
	NeedTimer[client] = true;

	return Plugin_Handled;
}

stock Freeze_Player(client)
{
	new rounded = RoundFloat(g_FreezeTime);

	decl String:sFreezeTime[8];
	IntToString(rounded, sFreezeTime, sizeof(sFreezeTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}is {olive}frozen {default}for {olive}%s seconds", client, sFreezeTime);

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, client, SNDLEVEL_RAIDSIREN);

	CreateTimer(g_FreezeTime, Timer_Freeze, client);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(HasInstant[attacker])
	{
		SlapPlayer(victim, 500, true);
	}

	return Plugin_Continue;
}

public Action:Timer_Instant(Handle:timer, any:client)
{
	HasInstant[client] = false;
	UnhookEvent("player_hurt", Event_PlayerHurt);

	IsRtdInUse = false;
	NeedTimer[client] = true;

	return Plugin_Handled;
}

stock Instant_Kills(client)
{
	new rounded = RoundFloat(g_InstantTime);

	decl String:sInstantTime[8];
	IntToString(rounded, sInstantTime, sizeof(sInstantTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has {olive}instant kills {default}for {olive}%s seconds", client, sInstantTime);

	HasInstant[client] = true;
	HookEvent("player_hurt", Event_PlayerHurt);

	CreateTimer(g_InstantTime, Timer_Instant, client);
}

stock Slay_Player(client)
{
	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}got {olive}slayed", client);

	SlapPlayer(client, 500, true);

	IsRtdInUse = false;
	NeedTimer[client] = true;
}

public Action:Timer_Speed(Handle:time, any:client)
{
	new Float:float_settimes = g_SpeedTime / 0.1;
	new settimes = RoundFloat(float_settimes);

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_SpeedMultiplier);
			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Speed);
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Speed_Player(client)
{
	new rounded = RoundFloat(g_SpeedTime);
	g_Speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");

	decl String:sSpeedTime[8];
	IntToString(rounded, sSpeedTime, sizeof(sSpeedTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has {olive}extra speed {default}for {olive}%s seconds", client, sSpeedTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(0.1, Timer_Speed, client, TIMER_REPEAT);
	}
}

public Action:Timer_Drug(Handle:timer, any:client)
{
	new Float:float_settimes = g_DrugTime / 1.0;
	new settimes = RoundFloat(float_settimes);

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
	
			new Float:angs[3];
			GetClientEyeAngles(client, angs);
	
			angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
			TeleportEntity(client, pos, angs, NULL_VECTOR);	

			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);

			new Float:angs[3];
			GetClientEyeAngles(client, angs);

			angs[2] = 0.0

			TeleportEntity(client, pos, angs, NULL_VECTOR);
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Drug_Player(client)
{
	new rounded = RoundFloat(g_DrugTime);
	
	decl String:sDrugTime[8];
	IntToString(rounded, sDrugTime, sizeof(sDrugTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}will be {olive}drugged {default}for {olive}%s seconds", client, sDrugTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);
	}
}

public Action:Timer_Ammo(Handle:timer, any:client)
{
	new Float:float_settimes = g_AmmoTime / 1.0;
	new settimes = RoundFloat(float_settimes);
	new entity = GetEntDataEnt2(client, g_ActiveOffset);

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			if(IsValidEntity(entity))
			{
				SetEntData(entity, g_ClipOffset, 50, 4, true);
			}

			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Ammo_Player(client)
{
	new rounded = RoundFloat(g_AmmoTime);
	
	decl String:sAmmoTime[8];
	IntToString(rounded, sAmmoTime, sizeof(sAmmoTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has {olive}infinite ammo {default}for {olive}%s seconds", client, sAmmoTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(1.0, Timer_Ammo, client, TIMER_REPEAT);
	}
}

public Action:Timer_Beacon(Handle:timer, any:value)
{
	new Float:float_settimes = g_BeaconTime / 1.0;
	new settimes = RoundFloat(float_settimes);
	new client = value & 0x7f;
	new serial = value >> 7;

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Count < settimes)
		{
			if(g_BeaconSerial[client] == serial)
			{
				new team = GetClientTeam(client);

				new Float:vec[3];
				GetClientAbsOrigin(client, vec);
				vec[2] += 10;

				TE_SetupBeamRingPoint(vec, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
				TE_SendToAll();

				if (team == 2)
				{
					TE_SetupBeamRingPoint(vec, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
				}
				else if (team == 3)
				{
					TE_SetupBeamRingPoint(vec, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
				}
				else
				{
					TE_SetupBeamRingPoint(vec, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
				}
	
				TE_SendToAll();
		
				GetClientEyePosition(client, vec);
				EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
			}

			g_Count++;
		}
		else if(g_Count >= settimes)
		{
			IsRtdInUse = false;
			NeedTimer[client] = true;
			KillTimer(g_hTimer)
			g_hTimer = INVALID_HANDLE;
		}
	}
	else
	{
		IsRtdInUse = false;
		KillTimer(g_hTimer)
		g_hTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

stock Beacon_Player(client)
{
	new rounded = RoundFloat(g_BeaconTime);

	decl String:sBeaconTime[8];
	IntToString(rounded, sBeaconTime, sizeof(sBeaconTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has a {olive}beacon {default}for {olive}%s seconds", client, sBeaconTime);

	g_Count = 0;

	if(g_hTimer == INVALID_HANDLE)
	{
		g_hTimer = CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
	}
}

public Action:Timer_Gravity(Handle:timer, any:client)
{
	SetEntityGravity(client, 1.0);

	IsRtdInUse = false;
	NeedTimer[client] = true;

	return Plugin_Handled;
}

stock Gravity_Player(client)
{
	new rounded = RoundFloat(g_GravityTime);

	decl String:sGravityTime[8];
	IntToString(rounded, sGravityTime, sizeof(sGravityTime));

	CPrintToChatAllEx(client, "{green}[RTD] {default}Player {teamcolor}%N {default}has {olive}low gravity {default}for {olive}%s seconds", client, sGravityTime);

	SetEntityGravity(client, g_GravityMultiplier);

	CreateTimer(g_GravityTime, Timer_Gravity, client);
}