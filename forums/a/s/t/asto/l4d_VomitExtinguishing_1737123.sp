#include <sourcemod>
#include <sdktools>
#define TEAM_INFECTED 3
#define CLASS_BOOMER 2
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.5"

new Handle:hVomit_Range;
new Float:gVomit_Range;
new Handle:hVomit_Duration;
new Float:gVomit_Duration;
new Handle:VomitTimer[MAXPLAYERS+1];
new Handle:hSplash_Enabled;
new Handle:hExtinguishRadius;
new Handle:g_h_CvarMessageType
new Float:gExtinguishRadius;
new bool:gSplash_Enabled;
new propinfoburn = -1;
new propinfoghost = -1;

public Plugin:myinfo = 

{
	name = "[L4D & L4D2] Vomit extinguishing",
	author = "Olj",
	description = "Vomit or boomer explosion can extinguish burning special infected",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{
                LoadTranslations("l4d_vomitextinguish.phrases")
		CreateConVar("l4d_ve_version", PLUGIN_VERSION, "Version of Vomit Extinguishing plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		hVomit_Duration = FindConVar("z_vomit_duration");
		hVomit_Range = FindConVar("z_vomit_range");
		hSplash_Enabled = CreateConVar("l4d_ve_splash_enabled", "1", " Enable/Disable boomer explosion to extinguish also ", CVAR_FLAGS);
		hExtinguishRadius = CreateConVar("l4d_ve_splash_radius", "200", "Extinguish radius of boomer explosion", CVAR_FLAGS);
                g_h_CvarMessageType = CreateConVar("l4d_ve_message_type", "3", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0)
		gExtinguishRadius = GetConVarFloat(hExtinguishRadius);
		gVomit_Duration = GetConVarFloat(hVomit_Duration);
		gVomit_Range = GetConVarFloat(hVomit_Range);
		gSplash_Enabled = GetConVarBool(hSplash_Enabled);
		HookEvent("ability_use", Vomit_Event);
		HookEvent("player_death", Splash_Event, EventHookMode_Pre);
                HookEvent("player_spawn", EventPlayerSpawn)
		HookConVarChange(hVomit_Range, Vomit_RangeChanged);
		HookConVarChange(hVomit_Duration, Vomit_DurationChanged);
		HookConVarChange(hSplash_Enabled, Splash_EnabledChanged);
		HookConVarChange(hExtinguishRadius, ExtinguishRadiusChanged);
		propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
		propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
		AutoExecConfig(true, "l4d_vomitextinguishing");
	}

public Action:EventPlayerSpawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, Handle:h_Pack
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (IsClientInGame(i_Client) && !IsFakeClient(i_Client) && GetClientTeam(i_Client) == TEAM_INFECTED && GetInfectedClass(i_Client) == CLASS_BOOMER)
	{
		h_Pack = CreateDataPack()
		WritePackCell(h_Pack, i_Client)
		WritePackString(h_Pack, "Vomit players")
		WritePackString(h_Pack, "+attack")
		CreateTimer(0.1, DisplayHint, h_Pack)
	}
}

public Action:DisplayHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Client
	
	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	
	if (GetConVarInt(g_h_CvarMessageType) == 3 && IsClientInGame(i_Client))
		ClientCommand(i_Client, "gameinstructor_enable 1")
		
	CreateTimer(0.3, DelayDisplayHint, h_Pack)
}

public Action:DelayDisplayHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Client, String:s_LanguageKey[16], String:s_Message[256], String:s_Bind[10]

	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	ReadPackString(h_Pack, s_LanguageKey, sizeof(s_LanguageKey))
	ReadPackString(h_Pack, s_Bind, sizeof(s_Bind))
	CloseHandle(h_Pack)
	
	switch (GetConVarInt(g_h_CvarMessageType))
	{
		case 1:
		{
			FormatEx(s_Message, sizeof(s_Message), "\x03[%t]\x01 %t.", "Information", s_LanguageKey)
			ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
			PrintToChat(i_Client, s_Message)
		}
		case 2: PrintHintText(i_Client, "%t", s_LanguageKey)
		case 3:
		{
			FormatEx(s_Message, sizeof(s_Message), "%t", s_LanguageKey)
			DisplayInstructorHint(i_Client, s_Message, s_Bind)
		}
	}
}

public DisplayInstructorHint(i_Client, String:s_Message[256], String:s_Bind[])
{
	decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack
	
	i_Ent = CreateEntityByName("env_instructor_hint")
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client)
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
	DispatchKeyValue(i_Client, "targetname", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_timeout", "5")
	DispatchKeyValue(i_Ent, "hint_range", "0.01")
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
	DispatchKeyValue(i_Ent, "hint_caption", s_Message)
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind)
	DispatchSpawn(i_Ent)
	AcceptEntityInput(i_Ent, "ShowHint")
	
	h_RemovePack = CreateDataPack()
	WritePackCell(h_RemovePack, i_Client)
	WritePackCell(h_RemovePack, i_Ent)
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack)
}
	
public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client
	
	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	i_Ent = ReadPackCell(h_Pack)
	CloseHandle(h_Pack)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent)
	
	ClientCommand(i_Client, "gameinstructor_enable 0")
		
	DispatchKeyValue(i_Client, "targetname", "")
		
	return Plugin_Continue
}

public GetInfectedClass(i_Client)
	return GetEntProp(i_Client, Prop_Send, "m_zombieClass")

public ExtinguishRadiusChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gExtinguishRadius = GetConVarFloat(hExtinguishRadius);
	}			
	
public Splash_EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gSplash_Enabled = GetConVarBool(hSplash_Enabled);
	}			
	
public Vomit_RangeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gVomit_Range = GetConVarFloat(hVomit_Range);
	}			

public Vomit_DurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gVomit_Duration = GetConVarFloat(hVomit_Duration);
	}			
	
public Action:Splash_Event(Handle:event, const String:name[], bool:dontBroadcast)
	{
		if (!gSplash_Enabled) return Plugin_Continue;
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if ((victim==0)||(!IsClientConnected(victim))||(!IsClientInGame(victim))) return Plugin_Continue;
		if ((GetClientTeam(victim)!=3)||(IsGhost(victim))) return Plugin_Continue;
		decl String:model[128];
		GetClientModel(victim, model, sizeof(model));
		if (StrContains(model, "boomer", false)!=-1 || StrContains(model, "boomette", false)!=-1)
			{
				new Float:Boomer_Position[3];
				GetClientAbsOrigin(victim,Boomer_Position);
				for (new target = 1; target <=MaxClients; target++)
					{
						if ((IsValidClient(target))&&(GetClientTeam(target)==3)&&(IsPlayerBurning(target)))
							{
								new Float:Target_Position[3];
								GetClientAbsOrigin(target, Target_Position);
								new SplashDistance = RoundToNearest(GetVectorDistance(Target_Position, Boomer_Position));
								if (SplashDistance<gExtinguishRadius)
									{
										ExtinguishEntity(target);
									}
							}
					}
			}
		return Plugin_Continue;
	}
	
public Vomit_Event(Handle:event, const String:name[], bool:dontBroadcast)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid")); //we get client
		if ((!IsValidClient(client))||(GetClientTeam(client)!=3)) return; //must be valid infected
		decl String:model[128];
		GetClientModel(client, model, sizeof(model));
		if (StrContains(model, "boomer", false)!=-1 || StrContains(model, "boomette", false)!=-1)
			{
				VomitTimer[client] = CreateTimer(0.1, VomitTimerFunction, any:client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				CreateTimer(gVomit_Duration,KillingVomitTimer, any:client,TIMER_FLAG_NO_MAPCHANGE);
			}
	}

public Action:VomitTimerFunction(Handle:timer, any:client)
	{
		if ((!IsValidClient(client))||(GetClientTeam(client)!=3))
			{
				VomitTimer[client] = INVALID_HANDLE;
				return Plugin_Stop;
			}
		new target = GetClientAimTarget(client, true);
		if ((target == -1) || (target == -2)) return Plugin_Continue;
		if ((!IsValidClient(target))||(GetClientTeam(target)!=3)) return Plugin_Continue;
		if (!IsPlayerBurning(target)) return Plugin_Continue;
		new Float:boomer_position[3];
		new Float:target_position[3];
		GetClientAbsOrigin(client,boomer_position);
		GetClientAbsOrigin(target,target_position);
		new distance = RoundToNearest(GetVectorDistance(boomer_position, target_position));
		if ((distance<gVomit_Range)&&(IsPlayerBurning(target)))
			{
				ExtinguishEntity(target);
			}
		return Plugin_Continue;
	}

public Action:KillingVomitTimer(Handle:timer, any:client)
	{
		if (VomitTimer[client] != INVALID_HANDLE)
			{
				KillTimer(VomitTimer[client]);	
				VomitTimer[client] = INVALID_HANDLE;
			}
	}


bool:IsPlayerBurning(client)
{
	if (!IsValidClient(client)) return false;
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning>0) return true;
	
	else return false;
}

bool:IsGhost(client)
{
	new isghost = GetEntData(client, propinfoghost, 1);
	
	if (isghost == 1) return true;
	else return false;
}

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}
