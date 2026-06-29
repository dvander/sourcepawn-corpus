#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:v_EyeBossHPLevel2 = INVALID_HANDLE;
new Handle:v_EyeBossHPPlayer = INVALID_HANDLE;
new Handle:v_EyeBossHPLevel = INVALID_HANDLE;
new Handle:v_MerasmusBaseHP = INVALID_HANDLE;
new Handle:v_MerasmusHP_Per_Player = INVALID_HANDLE;

new Float:g_pos[3];

new g_NumClients;
new g_trackEntity = -1;
new g_healthBar = -1;
new g_iLetsChangeThisEvent = 0;

public Plugin:myinfo = 
{
	name = "Halloween Boss Spawner",
	author = "abrandnewday",
	description = "Enables the ability for admins to spawn Halloween bosses",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=165383"
}

public OnPluginStart()
{
	CreateConVar("bossspawnerdeluxe_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_hatman", Command_SpawnHatman, ADMFLAG_GENERIC, "Spawns the Horsemann - Usage: sm_hatman");
	RegAdminCmd("sm_eyeboss", Command_SpawnEyeBoss, ADMFLAG_GENERIC, "Spawns the MONOCULUS - Usage: sm_eyeboss <level>");
	RegAdminCmd("sm_merasmus", Command_SpawnMerasmus, ADMFLAG_GENERIC, "Spawns Merasmus - Usage: sm_merasmus <health>");
	RegAdminCmd("sm_zombie", Command_SpawnZombie, ADMFLAG_GENERIC, "Spawns a Zombie - Usage: sm_zombie");
	RegAdminCmd("sm_slayhatman", Command_SlayHatman, ADMFLAG_GENERIC, "Slays all Horsemenn on the map - Usage: sm_slayhatman");
	RegAdminCmd("sm_slayeyeboss", Command_SlayEyeBoss, ADMFLAG_GENERIC, "Slays all MONOCULUS' on the map - Usage: sm_slayeyeboss");
	RegAdminCmd("sm_slaymerasmus", Command_SlayMerasmus, ADMFLAG_GENERIC, "Slays all Merasmus' on the map - Usage: sm_slaymerasmus");
	RegAdminCmd("sm_slayzombie", Command_SlayZombie, ADMFLAG_GENERIC, "Slays all Zombies on the map - Usage: sm_slayzombie");

	v_EyeBossHPLevel2 = FindConVar("tf_eyeball_boss_health_at_level_2");
	v_EyeBossHPPlayer = FindConVar("tf_eyeball_boss_health_per_player");
	v_EyeBossHPLevel = FindConVar("tf_eyeball_boss_health_per_level");
	v_MerasmusBaseHP = FindConVar("tf_merasmus_health_base");
	v_MerasmusHP_Per_Player = FindConVar("tf_merasmus_health_per_player");
	
	HookEvent("eyeball_boss_summoned", Event_EyeBossSummoned, EventHookMode_Pre);
	HookEvent("merasmus_summoned", Event_MerasmusSummoned, EventHookMode_Pre);
}

public OnMapStart()
{
	PrecacheHatman();
	PrecacheEyeBoss();
	PrecacheMerasmus();
	FindHealthBar();
	g_HP = 0;
	g_NumClients = 0;
}

public OnClientConnected(client)
{
	if(!IsFakeClient(client))
	{
		g_NumClients++;
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{		
		g_NumClients--;
	}
}

public Action:Event_EyeBossSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iLetsChangeThisEvent != 0)
	{
		new Handle:hEvent = CreateEvent(name);
		if (hEvent == INVALID_HANDLE)
		{
			return Plugin_Handled;
		}
		
		SetEventInt(hEvent, "level", g_iLetsChangeThisEvent);
		FireEvent(hEvent);
		g_iLetsChangeThisEvent = 0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_MerasmusSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEffects();
}

public Action:Command_SpawnHatman(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	new entity = CreateEntityByName("headless_hatman");
	if(IsValidEntity(entity))
	{
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		CPrintToChat(client,"{unusual}[BOSS] {default}You spawned the {unusual}Horseless Headless Horsemann{default}!");
		LogAction(client, client, "\"%L\" spawned the Horsemann", client);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnEyeBoss(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}

	new entity = CreateEntityByName("eyeball_boss");

	if (IsValidEntity(entity))
	{
		new iLevel = 0;
		if (args == 1)
		{
			decl String:buffer[15];
			GetCmdArg(1, buffer, sizeof(buffer));
			iLevel = StringToInt(buffer);
		}

		DispatchSpawn(entity);
		CPrintToChat(client,"{unusual}[BOSS] {default}You spawned the {unusual}MONOCULUS!{default}");
		LogAction(client, client, "\"%L\" spawned the Monoculus", client);
		
		if (iLevel > 1)
		{
			new iBaseHP = GetConVarInt(v_EyeBossHPLevel2);		//def 17,000
			new iHPPerLevel = GetConVarInt(v_EyeBossHPLevel);		//def  3,000
			new iHPPerPlayer = GetConVarInt(v_EyeBossHPPlayer);	//def	400
			new iNumPlayers = GetClientCount(true);

			new iHP = iBaseHP;
			iHP = (iHP + ((iLevel - 2) * iHPPerLevel));
			if (iNumPlayers > 10)
			{
				iHP = (iHP + ((iNumPlayers - 10)*iHPPerPlayer));
			}

			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHP);
			SetEntProp(entity, Prop_Data, "m_iHealth", iHP);
			
			g_iLetsChangeThisEvent = iLevel;
		}
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnMerasmus(client, args)
{
	new String:sHealth[15], HP = -1;
	if(args == 1)
	{
		GetCmdArgString(sHealth, sizeof(sHealth));
		HP = StringToInt(sHealth);
	}
	
	new iBaseHP = GetConVarInt(v_MerasmusBaseHP);
	new iPlayer = GetConVarInt(v_MerasmusHP_Per_Player);
	if(args == 0)
	{
		HP = iBaseHP + (iPlayer*g_NumClients);
	}
	if(!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(args > 1)
	{
		CReplyToCommand(client, "{unusual}[BOSS] {default} Format: sm_merasmus <health>");
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	new entity = CreateEntityByName("merasmus");
	if(!IsValidEntity(entity))
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Couldn't spawn {unusual}MERASMUS!{default} for some reason.");
		return Plugin_Handled;
	}
	DispatchSpawn(entity);
	CPrintToChat(client,"{unusual}[BOSS] {default}You spawned {unusual}MERASMUS!{default}");
	LogAction(client, client, "\"%L\" spawned Merasmus", client);
	if(HP > -1)
	{
		SetEntProp(entity, Prop_Data, "m_iHealth", HP * 4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", HP * 4);
//		g_HP = HP;
	}
	
	TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
//	g_spawned = 1;
	
	return Plugin_Handled;
}

public Action:Command_SpawnZombie(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Could not find spawn point");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		CPrintToChat(client, "{unusual}[BOSS] {default}Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	new entity = CreateEntityByName("tf_zombie");
	if(IsValidEntity(entity))
	{
		DispatchSpawn(entity);
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		CPrintToChat(client,"{unusual}[BOSS] {default}You spawned a {unusual}Zombie{default}!");
		LogAction(client, client, "\"%L\" spawned a Zombie", client);
	}
	return Plugin_Handled;
}

public Action:Command_SlayHatman(client, args)
{
	if(IsValidClient(client))
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "headless_hatman")) != -1 && IsValidEntity(ent))
		{
			new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(ent, "Kill");
			CPrintToChat(client,"{unusual}[BOSS] {default}You've slayed the {unusual}Horseless Headless Horsemann{default}!");
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBoss(client, args)
{
	if(IsValidClient(client))
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "eyeball_boss")) != -1 && IsValidEntity(ent))
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(ent, "Kill");
			CPrintToChat(client,"{unusual}[BOSS] {default}You've slayed the {unusual}MONOCULUS!{default}");
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayMerasmus(client, args)
{
	if(IsValidClient(client))
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "merasmus")) != -1 && IsValidEntity(ent))
		{
			new Handle:g_Event = CreateEvent("merasmus_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(ent, "Kill");
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayZombie(client, args)
{
	if(IsValidClient(client))
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_zombie")) != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Kill");
			CPrintToChat(client,"{unusual}[BOSS] {default}You've slayed a {unusual}Zombie{default}!");
		}
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

FindHealthBar()
{
	g_healthBar = FindEntityByClassname(-1, "m_iBossHealthPercentageByte");
	
	if (g_healthBar == -1)
	{
		g_healthBar = CreateEntityByName("m_iBossHealthPercentageByte");
		if (g_healthBar != -1)
		{
			DispatchSpawn(g_healthBar);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "m_iBossHealthPercentageByte"))
	{
		g_healthBar = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, "merasmus"))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == -1)
	{
		return;
	}
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, "merasmus");
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, "merasmus");
		}
			
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
}

public OnMerasmusDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public UpdateDeathEvent(entity)
{
	if (IsValidEntity(entity))
	{
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		
		if(HP <= (maxHP * 0.75))
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
			if(HP <= -1)
			{
				SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
			}
		}
	}
}

public UpdateBossHealth(entity)
{
	if (g_healthBar == -1)
	{
		return;
	}
	
	new percentage;
	if (IsValidEntity(entity))
	{
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		
		if (HP <= 0)
		{
			percentage = 0;
		}
		else
		{
			percentage = RoundToCeil(float(HP) / (maxHP / 4) * 255);
		}
	}
	else
	{
		percentage = 0;
	}	
	SetEntProp(g_healthBar, Prop_Send, "m_iBossHealthPercentageByte", percentage);
}

stock SetEffects()
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "merasmus")) != -1 && IsValidEntity(i))
	{
		SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
		SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0.0);
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}

PrecacheHatman()
{
	PrecacheModel("models/bots/headless_hatman.mdl"); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("vo/halloween_boss/knight_alert.wav");
	PrecacheSound("vo/halloween_boss/knight_alert01.wav");
	PrecacheSound("vo/halloween_boss/knight_alert02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack01.wav");
	PrecacheSound("vo/halloween_boss/knight_attack02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack03.wav");
	PrecacheSound("vo/halloween_boss/knight_attack04.wav");
	PrecacheSound("vo/halloween_boss/knight_death01.wav");
	PrecacheSound("vo/halloween_boss/knight_death02.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
	PrecacheSound("vo/halloween_boss/knight_pain01.wav");
	PrecacheSound("vo/halloween_boss/knight_pain02.wav");
	PrecacheSound("vo/halloween_boss/knight_pain03.wav");
	PrecacheSound("vo/halloween_boss/knight_spawn.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
}

PrecacheEyeBoss()
{
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl");
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl");
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball04.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball05.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball06.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball07.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball08.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball09.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball10.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball11.wav");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("ui/halloween_boss_chosen_it.wav");
	PrecacheSound("ui/halloween_boss_defeated_fx.wav");
	PrecacheSound("ui/halloween_boss_defeated.wav");
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav");
	PrecacheSound("ui/halloween_boss_summoned_fx.wav");
	PrecacheSound("ui/halloween_boss_summoned.wav");
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
	PrecacheSound("ui/halloween_boss_escape.wav");
	PrecacheSound("ui/halloween_boss_escape_sixty.wav");
	PrecacheSound("ui/halloween_boss_escape_ten.wav");
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
}

PrecacheMerasmus()
{
	PrecacheModel("models/bots/merasmus/merasmus.mdl");
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl");
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl");
	PrecacheSound("vo/halloween_merasmus/sf12_appears01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_appears17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_attacks11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb26.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb32.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb33.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb34.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb35.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb36.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb37.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb38.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb39.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb40.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb41.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb42.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb44.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb45.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb46.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb47.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb48.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb49.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb50.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb51.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb52.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb53.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_headbomb54.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up32.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_held_up33.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_island04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_bcon_skullhat03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_combat_idle01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_combat_idle02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_defeated12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_found09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_grenades06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_headbomb_hit26.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal17.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_heal19.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles14.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles15.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles18.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles20.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles21.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles22.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles24.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles25.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles26.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles28.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles30.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles31.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles33.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles27.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles41.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles42.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles44.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles46.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles47.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles48.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles49.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving13.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_leaving16.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain01.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_pain05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack07.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_ranged_attack08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic02.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic03.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic04.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic05.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic06.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic08.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic09.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic10.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic11.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic12.wav");
	PrecacheSound("vo/halloween_merasmus/sf12_staff_magic13.wav");
}