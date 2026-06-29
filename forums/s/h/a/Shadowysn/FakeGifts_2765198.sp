#define PLUGIN_NAME "[TF2] Fake Halloween Gifts"
#define PLUGIN_AUTHOR "DarthNinja, Shadowysn"
#define PLUGIN_DESC "Spawn fake gifts that act like ammo packs, or be a gift yourself!"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=141880"
#define PLUGIN_NAME_SHORT "Fake Halloween Gifts"
#define PLUGIN_NAME_TECH "fakegifts"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

#define GIFT "models/props_halloween/halloween_gift.mdl"
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

int g_FilteredEntity = -1;
float g_ClientPosition[MAXPLAYERS+1][3];
bool g_IsGift[MAXPLAYERS+1] = { false, ...};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	RegAdminCmd("sm_fakegift", FakeGift, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemegift", MakeMeAGift, ADMFLAG_CHEATS);
	
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	PrecacheModel(GIFT);
}

void EventInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (IsValidClient(client) && g_IsGift[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		g_IsGift[client] = false;
		PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: Your gift appearance has been removed!");
	}
}

Action FakeGift(int client, int args)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "Command must be used ingame!");
		return Plugin_Handled;
	}
	//TF_SpawnAmmopack(client, "item_ammopack_full", cmd);
	//TF_SpawnAmmopack(client, "item_ammopack_medium", cmd);
	TF_SpawnAmmopack(client, "item_ammopack_small", true);
	PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: You have spawned a fake gift!");

	return Plugin_Handled;
}

Action MakeMeAGift(int client, int args)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "Command must be used ingame!");
		return Plugin_Handled;
	}
	if (!IsPlayerAliveNotGhost(client)) return Plugin_Handled;
	
	switch (g_IsGift[client])
	{
		case false:
		{
			SetVariantString(GIFT);
			AcceptEntityInput(client, "SetCustomModel");
			SetVariantInt(1);
			AcceptEntityInput(client, "SetCustomModelRotates");
			Colorize(client, INVIS);
			
			SetEntProp(client, Prop_Data, "m_takedamage", 0);
			g_IsGift[client] = true;
			PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: You now look just like a gift!");
		}
		case true:
		{
			SetVariantString("");
			AcceptEntityInput(client, "SetCustomModel");
			Colorize(client, NORMAL);
			SetEntProp(client, Prop_Data, "m_takedamage", 2);
			g_IsGift[client] = false;
			PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: Your gift appearance has been removed!");
		}
	}
	
	return Plugin_Handled;
}

stock void TF_SpawnAmmopack(int client, const char[] name, bool cmd)
{
	float PlayerPosition[3];
	if (cmd)
		GetClientAbsOrigin(client, PlayerPosition);
	else
		PlayerPosition = g_ClientPosition[client];

	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		if (cmd)
		{
			float PlayerPosEx[3], PlayerAngle[3], PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

			Handle TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
			TR_GetEndPosition(PlayerPosition, TraceEx);
			CloseHandle(TraceEx);
		}

		float Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		Handle Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);

		float AmmoPos[3];
		TR_GetEndPosition(AmmoPos, Trace);
		CloseHandle(Trace);
		AmmoPos[2] += 4;

		int Ammopack = CreateEntityByName(name);
		DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchKeyValueVector(Ammopack, "origin", AmmoPos);
		
		DispatchKeyValue(Ammopack, "powerup_model", GIFT);
		if (DispatchSpawn(Ammopack))
		{
			int team = 0;
			SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team);
			
			if (HasEntProp(Ammopack, Prop_Send, "m_nModelIndexOverrides"))
			{
				int mdl_override_index = GetEntProp(Ammopack, Prop_Send, "m_nModelIndexOverrides", _, 0);
				SetEntProp(Ammopack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 1);
				SetEntProp(Ammopack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 2);
				SetEntProp(Ammopack, Prop_Send, "m_nModelIndexOverrides", mdl_override_index, _, 3);
			}
		}
	}
}

bool AmmopackTraceFilter(int ent, int contentMask)
{
	return (ent != g_FilteredEntity);
}

stock bool IsEntLimitReached()
{
	if (GetEntityCount() >= (GetMaxEntities()-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
		return true;
	}
	else
		return false;
}

/*
Credit to pheadxdll for invisibility code.
*/
void Colorize(int client, int color[4])
{	
	//Colorize the weapons
	//int m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");	
	static char classname[11];
	int type;
	TFClassType class = TF2_GetPlayerClass(client);
	
	for (int i = 0, weapon; i < 47; i += 4)
	{
		//weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (!RealValidEntity(weapon)) continue;
		
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (strcmp(classname, "tf_weapon_", false) == 0)
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	//Colorize the wearables, such as hats
	//SetWearablesRGBA_Impl( client, "tf_wearable_item", color );
	//SetWearablesRGBA_Impl( client, "tf_wearable_item_demoshield", color);
	SetWearablesInvis(client);
	
	//Colorize the player
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if (color[3] > 0)
	type = 1;
	
	InvisibleHideFixes(client, class, type);
	return;
}

void SetWearablesInvis(int client, bool hide = true)
{
	int ent = -1;
	while (RealValidEntity(ent = FindEntityByClassname(ent, "tf_wearable_item")))
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != client) continue;
		
		switch (hide)
		{
			case true: SetEntityRenderMode(ent, RENDER_NONE);
			case false: SetEntityRenderMode(ent, RENDER_NORMAL);
		}
	}
	ent = -1;
	while (RealValidEntity(ent = FindEntityByClassname(ent, "tf_wearable_item_demoshield")))
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != client) continue;
		
		switch (hide)
		{
			case true: SetEntityRenderMode(ent, RENDER_NONE);
			case false: SetEntityRenderMode(ent, RENDER_NORMAL);
		}
	}
	/*for (int i = 0; i <= 7; i++)
	{
		int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables", i);
		if (!RealValidEntity(ent)) return;
		switch (hide)
		{
			case true: SetEntityRenderMode(ent, RENDER_NONE);
			case false: SetEntityRenderMode(ent, RENDER_NORMAL);
		}
	}*/
}

/*void SetWearablesRGBA_Impl(int client, const char[] entClass, int color[4])
{
	int ent = -1;
	while (RealValidEntity(ent = FindEntityByClassname(ent, entClass)))
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
		{
			SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
			SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
		}
	}
}*/

void InvisibleHideFixes(int client, TFClassType class, int type)
{
	switch (class)
	{
		case TFClass_DemoMan:
		{
			int decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
			if (decapitations < 1) return;
			
			if (!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCondition(client, TFCond_DemoBuff);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCondition(client, TFCond_DemoBuff);
			}
		}
		case TFClass_Spy:
		{
			int disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
			if (!RealValidEntity(disguiseWeapon)) return;
			
			if (!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				int color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				int color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}


//This won't be required in the future as Sourcemod 1.4 already has this stuff
/*stock void TF2_AddCond(int client, int cond)
{
	Handle cvar = FindConVar("sv_cheats"); bool enabled = GetConVarBool(cvar); int flags = GetConVarFlags(cvar);
	if (!enabled)
	{
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	//FakeClientCommand(client, "isLoser");
	if (!enabled)
	{
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock void TF2_RemoveCond(int client, int cond)
{
	Handle cvar = FindConVar("sv_cheats"); bool enabled = GetConVarBool(cvar); int flags = GetConVarFlags(cvar);
	if (!enabled)
	{
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "removecond %i", cond);
	if (!enabled)
	{
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}*/

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }