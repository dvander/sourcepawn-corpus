#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

new Handle:v_NameFreePrefix = INVALID_HANDLE;
new Handle:v_NameFreeSuffix = INVALID_HANDLE;

new Handle:v_NamePremiumPrefix = INVALID_HANDLE;
new Handle:v_NamePremiumSuffix = INVALID_HANDLE;

new bool:g_PluginChangedName[MAXPLAYERS+1] = false;

#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo = {
	name        = "[TF2] Free2BeRenamed",
	author      = "DarthNinja",
	description = "Automatically adds tags for premium and non-premium players.",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_free2rename_version", PLUGIN_VERSION, "Free2BeRenamed", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_NameFreePrefix = CreateConVar("sm_free_prefix", "[F2P]", "Prefix tag for free users");
	v_NameFreeSuffix = CreateConVar("sm_free_suffix", "", "Suffix tag for free users");
	
	v_NamePremiumPrefix = CreateConVar("sm_premium_prefix", "", "Prefix tag for premium users");
	v_NamePremiumSuffix = CreateConVar("sm_premium_suffix", "", "Suffix tag for premium users");
	
	HookEvent("player_changename", OnPlayerChangeName, EventHookMode_Post);
	
	AutoExecConfig(true, "Free2Rename");
}

public OnClientPostAdminCheck(client)
{	
	if (IsFakeClient(client))
		return;
		
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		decl String:Prefix[MAX_NAME_LENGTH];
		decl String:Suffix[MAX_NAME_LENGTH];
		GetConVarString(v_NameFreePrefix, Prefix, MAX_NAME_LENGTH);
		GetConVarString(v_NameFreeSuffix, Suffix, MAX_NAME_LENGTH);
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			decl String:NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%N%s", Prefix, client, Suffix);
			SetClientInfo(client, "name", NewName);
			g_PluginChangedName[client] = true;
		}
		return;
	}
	else
	{
		decl String:Prefix[MAX_NAME_LENGTH];
		decl String:Suffix[MAX_NAME_LENGTH];
		GetConVarString(v_NamePremiumPrefix, Prefix, MAX_NAME_LENGTH);
		GetConVarString(v_NamePremiumSuffix, Suffix, MAX_NAME_LENGTH);
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			decl String:NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%N%s", Prefix, client, Suffix);
			SetClientInfo(client, "name", NewName);
			g_PluginChangedName[client] = true;
		}
	}
	return;
}

public Action:Timer_Rename(Handle:timer, Handle:pack)
{
	decl String:NewName[MAX_NAME_LENGTH]
	ResetPack(pack);
	ReadPackString(pack, NewName, sizeof(NewName));
	new client = GetClientOfUserId(ReadPackCell(pack));
	
	if (client != 0)
	{
		SetClientInfo(client, "name", NewName);
	}
		
	return Plugin_Stop;
}


public OnPlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	//This plugin changed the players name, we can skip the rest of this.
	if (g_PluginChangedName[client])
	{
		g_PluginChangedName[client] = false;
		return;
	}
	
	decl String:Name[MAX_NAME_LENGTH];
	GetEventString(event, "newname", Name, sizeof(Name));
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		//Free player
		decl String:Prefix[MAX_NAME_LENGTH];
		decl String:Suffix[MAX_NAME_LENGTH];
		GetConVarString(v_NameFreePrefix, Prefix, MAX_NAME_LENGTH);
		GetConVarString(v_NameFreeSuffix, Suffix, MAX_NAME_LENGTH);
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			decl String:NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, Name, Suffix);
			g_PluginChangedName[client] = true;
			new Handle:pack;
			CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackString(pack, NewName);
			WritePackCell(pack, GetClientUserId(client));
		}
	}
	else
	{
		decl String:Prefix[MAX_NAME_LENGTH];
		decl String:Suffix[MAX_NAME_LENGTH];
		GetConVarString(v_NamePremiumPrefix, Prefix, MAX_NAME_LENGTH);
		GetConVarString(v_NamePremiumSuffix, Suffix, MAX_NAME_LENGTH);
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			decl String:NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, Name, Suffix);
			g_PluginChangedName[client] = true;
			new Handle:pack;
			CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackString(pack, NewName);
			WritePackCell(pack, GetClientUserId(client));
		}
	}
}