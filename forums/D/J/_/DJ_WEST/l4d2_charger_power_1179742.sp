/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"
#define TEAM_INFECTED 3
#define CLASS_CHARGER 6
#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER	(1<<2)
#define PROP_TRUCK (1<<3)
#define PUSH_COUNT "m_iHealth"

new Handle:g_h_CvarChargerPower, Handle:g_h_CvarChargerCarry, Handle:g_h_CvarMessageType, Handle:g_h_CvarObjects, Handle:g_h_CvarPushLimit, Handle:g_h_CvarRemoveObject,
	Handle:g_h_CvarChargerDamage

public Plugin:myinfo = 
{
	name = "Charger Power",
	author = "DJ_WEST",
	description = "Allows charger to move objects (containers, cars, trucks) by hitting them when using own ability",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

public OnPluginStart()
{
	decl String:s_Game[12], Handle:h_Version
	
	GetGameFolderName(s_Game, sizeof(s_Game))
	if (!StrEqual(s_Game, "left4dead2"))
		SetFailState("Charger Power supports Left 4 Dead 2 only!")
	
	LoadTranslations("charger_power.phrases")
	
	h_Version = CreateConVar("charger_power_version", PLUGIN_VERSION, "Charger Power version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_h_CvarChargerPower = CreateConVar("l4d2_charger_power", "500.0", "Charger hit power", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 5000.0)
	g_h_CvarChargerCarry = CreateConVar("l4d2_charger_power_carry", "1", "Can move objects if charger carry the player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_h_CvarMessageType = CreateConVar("l4d2_charger_power_message_type", "3", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0)
	g_h_CvarObjects = CreateConVar("l4d2_charger_power_objects", "15", "Can move objects this type (1 - car, 2 - car alarm, 4 - container, 8 - truck)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 15.0)
	g_h_CvarPushLimit = CreateConVar("l4d2_charger_power_push_limit", "3", "How many times object can be moved", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 100.0)
	g_h_CvarRemoveObject = CreateConVar("l4d2_charger_power_remove", "0", "Remove moved object after some time (in seconds)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0)
	g_h_CvarChargerDamage = CreateConVar("l4d2_charger_power_damage", "10", "Additional damage to charger from moving objects", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0)

	HookEvent("charger_charge_end", EventChargeEnd)
	HookEvent("player_spawn", EventPlayerSpawn)

	SetConVarString(h_Version, PLUGIN_VERSION)
}

public Action:EventChargeEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, Float:f_Origin[3], Float:f_Angles[3], Float:f_EndOrigin[3], Float:f_Velocity[3],
		Handle:h_Trace, Handle:h_Pack, i_Target, String:s_ClassName[16], Float:f_Power, String:s_ModelName[64],
		i_Type, i_PushCount, i_Health, i_Damage, i_RemoveTime
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
		
	if (!GetConVarInt(g_h_CvarChargerCarry) && GetEntProp(i_Client, Prop_Send, "m_carryVictim") > 0)
		return Plugin_Handled

	GetClientAbsOrigin(i_Client, f_Origin)
	GetClientAbsAngles(i_Client, f_Angles)
	f_Origin[2] += 20.0

	h_Trace = TR_TraceRayFilterEx(f_Origin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Client)
		
	if (TR_DidHit(h_Trace))
	{
		i_Target = TR_GetEntityIndex(h_Trace)
		TR_GetEndPosition(f_EndOrigin, h_Trace)
			
		if (i_Target && IsValidEdict(i_Target) && GetVectorDistance(f_Origin, f_EndOrigin) <= 100.0)
		{
			if (GetEntityMoveType(i_Target) != MOVETYPE_VPHYSICS)
				return Plugin_Handled
				
			i_PushCount = GetEntProp(i_Target, Prop_Data, PUSH_COUNT)
			
			if (i_PushCount >= GetConVarInt(g_h_CvarPushLimit))
				return Plugin_Handled
				
			i_Type = GetConVarInt(g_h_CvarObjects)
				
			GetEdictClassname(i_Target, s_ClassName, sizeof(s_ClassName))
			GetEntPropString(i_Target, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName))
			
			if (StrEqual(s_ClassName, "prop_physics") || StrEqual(s_ClassName, "prop_car_alarm"))
			{
				if (StrEqual(s_ClassName, "prop_car_alarm") && !(i_Type & PROP_CAR_ALARM))
					return Plugin_Handled
				else if (StrContains(s_ModelName, "car") != -1 && !(i_Type & PROP_CAR) && !(i_Type & PROP_CAR_ALARM))
					return Plugin_Handled
				else if (StrContains(s_ModelName, "dumpster") != -1 && !(i_Type & PROP_CONTAINER))
					return Plugin_Handled
				else if (StrContains(s_ModelName, "forklift") != -1 && !(i_Type & PROP_TRUCK))
					return Plugin_Handled
					
				i_PushCount++
				SetEntProp(i_Target, Prop_Data, PUSH_COUNT, i_PushCount)

				GetAngleVectors(f_Angles, f_Velocity, NULL_VECTOR, NULL_VECTOR)
				f_Power = GetConVarFloat(g_h_CvarChargerPower)
				f_Velocity[0] *= f_Power
				f_Velocity[1] *= f_Power
				f_Velocity[2] *= f_Power
				TeleportEntity(i_Target, NULL_VECTOR, NULL_VECTOR, f_Velocity)
				
				h_Pack = CreateDataPack()
				WritePackCell(h_Pack, i_Target)
				WritePackFloat(h_Pack, f_EndOrigin[0])
				CreateTimer(0.5, CheckEntity, h_Pack)
				
				i_Damage = GetConVarInt(g_h_CvarChargerDamage)
				if (i_Damage)
				{
					i_Health = GetClientHealth(i_Client)
					i_Health -= i_Damage
					
					if (i_Health > 0) 
						SetEntityHealth(i_Client, i_Health)
					else
						ForcePlayerSuicide(i_Client)
				}
				
				i_RemoveTime = GetConVarInt(g_h_CvarRemoveObject)
				if (i_RemoveTime)
					CreateTimer(float(i_RemoveTime), RemoveEntity, i_Target, TIMER_FLAG_NO_MAPCHANGE) 
			}
		}
	}
	
	return Plugin_Continue
}

public Action:RemoveEntity(Handle:h_Timer, any:i_Ent)
{
	if (IsValidEnt(i_Ent))
		RemoveEdict(i_Ent)
}

public bool:TraceFilterClients(i_Entity, i_Mask, any:i_Data)
{
	if (i_Entity == i_Data)
		return false
		
	if (1 <= i_Entity <= MaxClients)
		return false
		
	return true
}

public Action:CheckEntity(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, Float:f_Origin[3], Float:f_LastOrigin, Handle:h_NewPack
	
	ResetPack(h_Pack, false)
	i_Ent = ReadPackCell(h_Pack)
	f_LastOrigin = ReadPackFloat(h_Pack)
	CloseHandle(h_Pack)
	
	if (IsValidEdict(i_Ent))
	{
		GetEntPropVector(i_Ent, Prop_Data, "m_vecOrigin", f_Origin)
		
		if (f_Origin[0] != f_LastOrigin)
		{
			h_NewPack = CreateDataPack()
			WritePackCell(h_NewPack, i_Ent)
			WritePackFloat(h_NewPack, f_Origin[0])
			CreateTimer(0.1, CheckEntity, h_NewPack)
		}
		else
			TeleportEntity(i_Ent, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0})
	}
}

public Action:EventPlayerSpawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	decl i_UserID, i_Client, Handle:h_Pack
	
	i_UserID = GetEventInt(h_Event, "userid")
	i_Client = GetClientOfUserId(i_UserID)
	
	if (IsClientInGame(i_Client) && !IsFakeClient(i_Client) && GetClientTeam(i_Client) == TEAM_INFECTED && GetInfectedClass(i_Client) == CLASS_CHARGER)
	{
		h_Pack = CreateDataPack()
		WritePackCell(h_Pack, i_Client)
		WritePackString(h_Pack, "Move objects")
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

stock GetInfectedClass(i_Client)
	return GetEntProp(i_Client, Prop_Send, "m_zombieClass")
	
stock IsValidEnt(i_Ent)
	return (IsValidEdict(i_Ent) && IsValidEntity(i_Ent))