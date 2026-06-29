#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define _DEBUG		0	// Set to 1 to have debug spew

#define PLUGIN_VERSION	"0.0.1.0"

new Handle:kv = INVALID_HANDLE;
new String:kv_file[PLATFORM_MAX_PATH];

new bool:Enabled = false;
new bool:PlayerHasForcedSkin[MAXPLAYERS + 1] = {false, ...};
new String:ForcedSkin[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

new Handle:ClientTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

public Plugin:myinfo = 
{
	name = "Forced Skin",
	author = "TnTSCS aKa ClarkKent",
	description = "Force players to have certain defined skin",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_fs_version", PLUGIN_VERSION, 
	"The version of 'Forced Skin'", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_fs_enabled", "1", 
	"Is Forced Skin enabled?", FCVAR_NONE, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	CloseHandle(hRandom);
	
	BuildPath(Path_SM, kv_file, PLATFORM_MAX_PATH, "configs/forced_skin.txt");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	kv = CreateKeyValues("Forced Skins");
	
	if (!FileToKeyValues(kv, kv_file))
	{
		SetFailState("Unable to open file %s", kv_file);
	}
}

public OnMapEnd()
{
	if (kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
		kv = INVALID_HANDLE;
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (Enabled && client != 0 && !IsFakeClient(client))
	{
		ForcedSkin[client][0] = '\0';
		
		if (ClientHasAssignedSkin(client, auth))
		{
			PlayerHasForcedSkin[client] = true;
		}
		else
		{
			PlayerHasForcedSkin[client] = false;
		}
	}
}

public OnClientDisconnect(client)
{
	if (IsClientConnected(client))
	{
		PlayerHasForcedSkin[client] = false;
		
		ForcedSkin[client][0] = '\0';
		
		ClearTimer(ClientTimer[client]);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!Enabled || client < 1 || client > MaxClients || !PlayerHasForcedSkin[client])
	{
		return;
	}
	
	// Timer to set skin
	if (IsModelPrecached(ForcedSkin[client]))
	{
		ClientTimer[client] = CreateTimer(0.1, Timer_ApplySkin, client);
	}
	else
	{
		LogError("Model for %L (%s) is not precached!!!", client, ForcedSkin[client]);
		PrintToChat(client, "\x03There's a problem with your model, let an admin know");
		PrintToChat(client, "Your assigned model: \x02%s", ForcedSkin[client]);
	}
}

public Action:Timer_ApplySkin(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	SetEntityModel(client, ForcedSkin[client]);
}

bool:ClientHasAssignedSkin(client, const String:auth[])
{
	#if _DEBUG
		LogMessage("Opening key value file to check for %L", client);
	#endif
	
	if (!KvGotoFirstSubKey(kv))
	{
		#if _DEBUG
			LogMessage("Unable to find any keys in the key value file");
		#endif
		
		return false;
	}
	
	decl String:model[PLATFORM_MAX_PATH];
	model[0] = '\0';
	
	decl String:steamid[50];
	steamid[0] = '\0';
	
	do
	{
		KvGetSectionName(kv, steamid, sizeof(steamid));
		
		if (StrEqual(steamid, auth))
		{
			KvGetString(kv, "path", model, sizeof(model));
			
			TrimString(model);
			
			#if _DEBUG
				LogMessage("Setting %s for %L.", model, client);
			#endif
			
			Format(ForcedSkin[client], sizeof(ForcedSkin[]), model);
			
			//CloseHandle(kv);
			
			return true;
		}
	} while (KvGotoNextKey(kv));
 
	//CloseHandle(kv);
	
	#if _DEBUG
		LogMessage("No skin defined for for %L", client);
	#endif
	
	return false;
}

public ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	Enabled = GetConVarBool(cvar);
}