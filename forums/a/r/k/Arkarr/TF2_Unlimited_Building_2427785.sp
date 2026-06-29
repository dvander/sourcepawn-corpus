#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

#define OBJ_SENTRY		"obj_sentrygun"
#define OBJ_DISPENSER	"obj_dispenser"
#define OBJ_TELEPORTER	"obj_teleporter"

Handle SDKRemoveObject;
Handle ARRAY_Building;
Handle CVAR_LimitSentry;
Handle CVAR_LimitDispenser;
Handle CVAR_LimitTeleporter;
Handle CVAR_FLagRestriction;

bool InBuilding[MAXPLAYERS + 1];
bool PluginEnabled;

int BOTRED = -1;
int BOTBLU = -1;

public Plugin myinfo = 
{
	name = "[TF2] Unlimited Buildings", 
	author = PLUGIN_AUTHOR, 
	description = "Allow you to build more then one type of building", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	//Pelipoika stuff that I don't really want to mess with...
	Handle hConfig = LoadGameConfigFile("tf2.setbuilder");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); //CBaseObject 
	if ((SDKRemoveObject = EndPrepSDKCall()) == INVALID_HANDLE)SetFailState("Failed To create SDKCall for CTFPlayer::RemoveObject signature");
	delete hConfig;
	//End of Pelipoika stuff....
	
	CVAR_LimitSentry = CreateConVar("sm_ub_number_of_sentries", "9999", "How much a player can build sentries ?", _, true, 0.0);
	CVAR_LimitDispenser = CreateConVar("sm_ub_number_of_dispenser", "9999", "How much a player can build dispenser ?", _, true, 0.0);
	CVAR_LimitTeleporter = CreateConVar("sm_ub_number_of_teleporter", "9999", "How much a player can build teleporter ?", _, true, 0.0);
	CVAR_FLagRestriction = CreateConVar("sm_ub_flag_restriction", "", "Anyone who have at least one of those flag will be able to use build more buildings.", _, true, 0.0);
	
	AutoExecConfig(true, "TF2_UnlimitedBuildings");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	Handle botQuota = FindConVar("tf_bot_quota");
	HookConVarChange(botQuota, OnConVarChange);
	
	if (GetConVarInt(botQuota) < 2)
		SetConVarInt(botQuota, 2);
		
	ServerCommand("bot -team 1 -name SENTRY_RED");
	ServerCommand("bot -team 0 -name SENTRY_BLU");
	
	ARRAY_Building = CreateTrie();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public void OnMapEnd()
{
	BOTRED = -1;
	BOTBLU = -1;
}

public void OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) < 2)
		SetConVarInt(convar, 2);
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.5, TMR_GetBot, GetEventInt(event, "userid"));
}

public Action TMR_GetBot(Handle tmr, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client == 0)
		return Plugin_Stop;
	
	if (BOTBLU == client && TF2_GetClientTeam(BOTBLU) != TFTeam_Blue)
		TF2_ChangeClientTeam(BOTBLU, TFTeam_Blue);
	
	if (BOTRED == client && TF2_GetClientTeam(BOTRED) != TFTeam_Red)
		TF2_ChangeClientTeam(BOTRED, TFTeam_Red);
	
	return Plugin_Stop;
}

public void OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		if (BOTRED == -1)
			BOTRED = client;
		
		if (BOTBLU == -1 && BOTRED != client)
			BOTBLU = client;
	}
	
	if (BOTBLU != -1 && BOTRED != -1)
		PluginEnabled = true;
	
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnClientDisconnect(client)
{
	if (!PluginEnabled || !InBuilding[client])
		return;
	
	GetbackOwnership(client, OBJ_SENTRY);
	GetbackOwnership(client, OBJ_DISPENSER);
	GetbackOwnership(client, OBJ_TELEPORTER);
	InBuilding[client] = false;
	
	if(client == BOTBLU)
		BOTBLU = -1;
	if(client == BOTRED)
		BOTRED = -1;
}

public Action OnWeaponSwitch(client, weapon)
{
	//	Some people might use PDA without being engineer, loose performance for more fun :D !
	//	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	//		return Plugin_Continue;
	
	if (!PluginEnabled)
		return Plugin_Continue;
		
	if(!IsValidEdict(weapon))
		return Plugin_Continue;
	
	char strFlags[40];
	GetConVarString(CVAR_FLagRestriction, strFlags, sizeof(strFlags));
	int flags = ReadFlagString(strFlags);
	if (!(GetUserFlagBits(client) & flags == flags))
		return Plugin_Continue;
	
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (StrEqual(sWeapon, "tf_weapon_pda_engineer_build"))
	{
		if (IsEntLimitReached())
			return Plugin_Continue;
		
		if (GetConVarInt(CVAR_LimitSentry) > CountBuilding(client, OBJ_SENTRY))
		{
			RemoveOwnership(client, OBJ_SENTRY);
			InBuilding[client] = true;
		}
		
		if (GetConVarInt(CVAR_LimitDispenser) > CountBuilding(client, OBJ_DISPENSER))
		{
			RemoveOwnership(client, OBJ_DISPENSER);
			InBuilding[client] = true;
		}
		
		if (GetConVarInt(CVAR_LimitTeleporter) > CountBuilding(client, OBJ_TELEPORTER))
		{
			RemoveOwnership(client, OBJ_TELEPORTER);
			InBuilding[client] = true;
		}
	}
	else if (InBuilding[client] && !StrEqual(sWeapon, "tf_weapon_builder"))
	{
		GetbackOwnership(client, OBJ_SENTRY);
		GetbackOwnership(client, OBJ_DISPENSER);
		GetbackOwnership(client, OBJ_TELEPORTER);
		InBuilding[client] = false;
	}
	
	return Plugin_Continue;
}

stock void RemoveOwnership(client, char[] buildingType)
{
	char id[45];
	int index = -1;
	while ((index = FindEntityByClassname(index, buildingType)) != -1)
	{
		if (GetEntPropEnt(index, Prop_Send, "m_hBuilder") == client)
		{
			Format(id, sizeof(id), "ID#%i", index);
			SetTrieValue(ARRAY_Building, id, client);
			if (TF2_GetClientTeam(client) == TFTeam_Blue)
				SetBuilder(index, BOTBLU);
			else
				SetBuilder(index, BOTRED);
		}
	}
}

stock void GetbackOwnership(client, char[] buildingType)
{
	char id[45];
	int clientID;
	int index = -1;
	while ((index = FindEntityByClassname(index, buildingType)) != -1)
	{
		Format(id, sizeof(id), "ID#%i", index);
		if (GetTrieValue(ARRAY_Building, id, clientID))
		{
			if (clientID == client)
				SetBuilder(index, client);
		}
	}
}

stock int CountBuilding(client, char[] buildingType)
{
	char id[45];
	int clientID;
	int count = 0;
	int index = -1;
	while ((index = FindEntityByClassname(index, buildingType)) != -1)
	{
		Format(id, sizeof(id), "ID#%i", index);
		if (GetTrieValue(ARRAY_Building, id, clientID) || GetEntPropEnt(index, Prop_Send, "m_hBuilder") == client)
			count++;
	}
	return count;
}

//Black magic sutff
stock void SetBuilder(int obj, int client)
{
	int iBuilder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	bool bMiniBuilding = GetEntProp(obj, Prop_Send, "m_bMiniBuilding") || GetEntProp(obj, Prop_Send, "m_bDisposableBuilding");
	
	//Especially this part.
	if (iBuilder > 0 && iBuilder <= MaxClients && IsClientInGame(iBuilder))
		SDKCall(SDKRemoveObject, iBuilder, obj);
	
	SetEntPropEnt(obj, Prop_Send, "m_hBuilder", -1);
	AcceptEntityInput(obj, "SetBuilder", client);
	SetEntPropEnt(obj, Prop_Send, "m_hBuilder", client);
	
	if (client != 0)
	{
		SetVariantInt(GetClientTeam(client));
		AcceptEntityInput(obj, "SetTeam");
		
		SetEntProp(obj, Prop_Send, "m_nSkin", bMiniBuilding ? GetClientTeam(client):GetClientTeam(client) - 2);
	}
}

//Thanks to DarthNinja
stock bool IsEntLimitReached()
{
	if (GetEntityCount() >= (GetMaxEntities() - 30))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
		return true;
	}
	else
	{
		return false;
	}
} 