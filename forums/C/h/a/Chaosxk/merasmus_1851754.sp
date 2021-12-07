#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4.2"
#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MERASMUS "merasmus"

new Float:g_pos[3];
new g_spawned;

new Handle:g_Size;
new Handle:g_Glow;
new Handle:g_Respawn;
new Handle:g_Timer;
new Handle:tHandle;
new Handle:g_Method;
new Handle:g_xCoord;
new Handle:g_yCoord;
new Handle:g_zCoord;
new Handle:v_BaseHP = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;

new g_NumClients;
new g_count;
new g_HP;
new g_trackEntity = -1;
new g_healthBar = -1;

public Plugin:myinfo =
{
	name = "[TF2] Merasmus Spawner",
	author = "Tak (Chaosxk)",
	description = "RUN COWARDS! RUN!!!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_merasmus_version", PLUGIN_VERSION, "Version of this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_merasmus", Meras, ADMFLAG_GENERIC, "Spawns Meras!");
	RegAdminCmd("sm_meras", Meras, ADMFLAG_GENERIC, "Spawns Meras!");
	RegAdminCmd("sm_slaymeras", SlayMeras, ADMFLAG_GENERIC, "Slays Meras!");
	RegAdminCmd("sm_forcemeras", ForceMeras, ADMFLAG_GENERIC, "Force Meras to spawn on the last location!");
	RegAdminCmd("sm_getcoords", GetCoords, ADMFLAG_GENERIC, "Get the Coordinates.");
	
	g_Size = CreateConVar("sm_merasmus_resize", "1.0", "Size of Merasmus. Min = 0 Max = 10", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_Glow = CreateConVar("sm_merasmus_glow", "0.0", "Should Merasmus be glowing?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Respawn = CreateConVar("sm_merasmus_respawn", "1.0", "Should Merasmus respawn from the last location it was spawned?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Timer = CreateConVar("sm_merasmus_timer", "300.0", "What should the time to respawn be if sm_merasmus_respawn is enabled?");
	g_Method = CreateConVar("sm_merasmus_method", "1.0", "Specify which respawn method to choose. 1 = In-Game Method ; 0 = Coordinate Method");
	g_xCoord = CreateConVar("sm_merasmus_xcoord", "0.0", "Respawn X Coordinates.");
	g_yCoord = CreateConVar("sm_merasmus_ycoord", "0.0", "Respawn Y Coordinates.");
	g_zCoord = CreateConVar("sm_merasmus_zcoord", "0.0", "Respawn Z Coordinates.");
	
	HookConVarChange(g_Size, Convar_Size);
	HookConVarChange(g_Glow, Convar_Glow);
	HookConVarChange(g_Respawn, Convar_Respawn);
	HookConVarChange(g_Timer, Convar_Timer);
	HookConVarChange(g_Method, Convar_Method);
	HookConVarChange(g_xCoord, Convar_xCoords);
	HookConVarChange(g_yCoord, Convar_yCoords);
	HookConVarChange(g_zCoord, Convar_zCoords);
	
	HookEvent("merasmus_killed", merasmus_killed, EventHookMode_Pre);
	HookEvent("merasmus_escaped", merasmus_escaped);
	HookEvent("merasmus_summoned", merasmus_summoned, EventHookMode_Pre);
	
	v_BaseHP = FindConVar("tf_merasmus_health_base");
	v_HP_Per_Player = FindConVar("tf_merasmus_health_per_player");
	
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "merasmus");
}

public OnMapStart()
{
	PreCacheMe();
	FindHealthBar();
	g_HP = 0;
	g_count = 0;
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

public Action:merasmus_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Respawn))
	{
		g_count--;
		if(g_count == 0)
		{
			new Float:time = GetConVarFloat(g_Timer);
			tHandle = CreateTimer(time, Timer_Respawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("[SM] Merasmus will spawn respawn again in %0.0f seconds.", time);
		}
	}
}

public Action:merasmus_escaped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Respawn))
	{
		g_count--;
		if(g_count == 0)
		{
			new Float:time = GetConVarFloat(g_Timer);
			tHandle = CreateTimer(time, Timer_Respawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("[SM] Merasmus will respawn again in %0.0f seconds.", time);
		}
	}
}

public Action:merasmus_summoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_count++;
	ClearTimer(tHandle);
	SetEffects();
}

public Action:Timer_Respawn(Handle:timer)
{
	new HP = g_HP;
	
	if(GetEntityCount() >= GetMaxEntities()-32) return Plugin_Handled;
	
	new entity = CreateEntityByName(MERASMUS);
	
	if(!IsValidEntity(entity)) return Plugin_Handled;
	
	DispatchSpawn(entity);
	
	if(HP > -1)
	{
		SetEntProp(entity, Prop_Data, "m_iHealth", HP * 4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", HP * 4);
	}
	
	TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);	
	
	return Plugin_Continue;
}

public Convar_Size(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarFloat(g_Size) > 0.0)
	{
		PrintToServer("[SM] Merasmus size is set to %0.0f.", StringToFloat(newValue));
		SetEffects();
	}
	if(GetConVarFloat(g_Size) < 0.0 || GetConVarFloat(g_Size) == 0.0)
	{
		PrintToServer("[SM] Value must be greater than 0.");
		SetConVarFloat(g_Size, StringToFloat(oldValue));
	}
}

public Convar_Glow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarFloat(g_Glow) == 1)
	{
		PrintToServer("[SM] Merasmus is now glowing!");
	}
	if(GetConVarFloat(g_Glow) == 0)
	{
		PrintToServer("[SM] Merasmus is no longer glowing!");
	}
	SetEffects();
}

public Convar_Respawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarFloat(g_Respawn) == 1)
	{
		PrintToServer("[SM] Merasmus will now respawn!");
	}
	if(GetConVarFloat(g_Respawn) == 0)
	{
		PrintToServer("[SM] Merasmus will no longer respawn!");
	}
}

public Convar_Timer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarFloat(g_Timer) > 0.0)
	{
		PrintToServer("[SM] Merasmus will respawn every %0.0f seconds.", StringToFloat(newValue));
	}
	if(GetConVarFloat(g_Timer) < 0.0 || GetConVarFloat(g_Timer) == 0.0)
	{
		PrintToServer("[SM] Value must be greater than 0.");
		SetConVarFloat(g_Timer, StringToFloat(oldValue));
	}
}

public Convar_Method(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	if(!GetConVarBool(g_Respawn)) return;
	
	if(GetConVarFloat(g_Method) == 0.0 || GetConVarFloat(g_Method) == 1.0)
	{
		PrintToServer("[SM] Respawn Method has been changed to %0.0f.", StringToFloat(newValue));
	}
	if(GetConVarFloat(g_Method) < 0.0 || GetConVarFloat(g_Method) > 1.0)
	{
		PrintToServer("[SM] Invalid method, 1 = In-Game ; 2 = Coordinates.");
		SetConVarFloat(g_Method, StringToFloat(oldValue));
	}

}

public Convar_xCoords(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!GetConVarBool(g_Respawn)) return;
	PrintToServer("[SM] X-Coordinates have been changed to %f.", StringToFloat(newValue));
}

public Convar_yCoords(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!GetConVarBool(g_Respawn)) return;
	PrintToServer("[SM] X-Coordinates have been changed to %f.", StringToFloat(newValue));
}

public Convar_zCoords(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!GetConVarBool(g_Respawn)) return;
	PrintToServer("[SM] X-Coordinates have been changed to %f.", StringToFloat(newValue));
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Action:GetCoords(client, args)
{
	new Float:l_pos[3];
	GetClientEyePosition(client, l_pos);
	ReplyToCommand(client, "[SM] Your location is currently X = %0.0f, Y = %0.0f, Z = %0.0f", l_pos[0], l_pos[1], l_pos[2]);
	return Plugin_Handled;
}
public Action:SlayMeras(client, args)
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

public Action:ForceMeras(client, args)
{
	if(IsValidClient(client))
	{
		if(g_spawned == 0)
		{
			ReplyToCommand(client, "[SM] Last known location is unknown!");
			return Plugin_Handled;
		}
		new HP = g_HP;

		if(GetEntityCount() >= GetMaxEntities()-32) return Plugin_Handled;

		new entity = CreateEntityByName(MERASMUS);

		if(!IsValidEntity(entity)) return Plugin_Handled;

		DispatchSpawn(entity);

		if(HP > -1)
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", HP * 4);
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", HP * 4);
		}

		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		ClearTimer(tHandle);
	}
	return Plugin_Handled;
}

public Action:Meras(client, args)
{
	if(GetConVarBool(g_Method))
	{
		g_pos[2] -= 10.0;
		if(!IsValidClient(client))
		{
			ReplyToCommand(client, "[SM] Command is in-game only.");
			return Plugin_Handled;
		}
		if(!SetTeleportEndPoint(client))
		{
			PrintToChat(client, "[SM] Could not find spawn point.");
			return Plugin_Handled;
		}
	}
	
	if(!GetConVarBool(g_Method))
	{
		ReplyToCommand(client, "[SM] Merasmus has spawn on the position you specified!");
		g_pos[0] = GetConVarFloat(g_xCoord);
		g_pos[1] = GetConVarFloat(g_yCoord);
		g_pos[2] = GetConVarFloat(g_zCoord);
	}
	
	new String:sHealth[15], HP = -1;
	if(args == 1)
	{
		GetCmdArgString(sHealth, sizeof(sHealth));
		HP = StringToInt(sHealth);
	}
	
	new iBaseHP = GetConVarInt(v_BaseHP);
	new iPlayer = GetConVarInt(v_HP_Per_Player);
	if(args == 0)
	{
		HP = iBaseHP + (iPlayer*g_NumClients);
	}
	if(args > 1)
	{
		ReplyToCommand(client, "[SM] Format: sm_merasmus <health>");
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	new entity = CreateEntityByName(MERASMUS);
	if(!IsValidEntity(entity))
	{
		PrintToChat(client, "[SM] Couldn't spawn Merasmus, for some reason.");
		return Plugin_Handled;
	}
	DispatchSpawn(entity);
	if(HP > -1)
	{
		SetEntProp(entity, Prop_Data, "m_iHealth", HP * 4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", HP * 4);
		g_HP = HP;
	}
	
	TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	g_spawned = 1;
	
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
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

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

FindHealthBar()
{
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	
	if (g_healthBar == -1)
	{
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if (g_healthBar != -1)
		{
			DispatchSpawn(g_healthBar);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, HEALTHBAR_CLASS))
	{
		g_healthBar = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, MERASMUS))
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
		g_trackEntity = FindEntityByClassname(-1, MERASMUS);
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, MERASMUS);
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
			percentage = RoundToCeil(float(HP) / (maxHP / 4) * HEALTHBAR_MAX);
		}
	}
	else
	{
		percentage = 0;
	}	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

stock SetEffects()
{
	new i = -1;
	while ((i = FindEntityByClassname(i, MERASMUS)) != -1 && IsValidEntity(i))
	{
		SetEntPropFloat(i, Prop_Send, "m_flModelScale", GetConVarFloat(g_Size));
		SetEntProp(i, Prop_Send, "m_bGlowEnabled", GetConVarFloat(g_Glow));
	}
}

PreCacheMe()
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