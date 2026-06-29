#include	<sdktools>
#define		AUTOLOAD_EXTENSIONS
#define		REQUIRE_EXTENSIONS
#include	<steamtools>

#pragma		semicolon	1
#pragma		newdecls	required

ConVar	v_NameFreePrefix,
		v_NameFreeSuffix,

		v_NamePremiumPrefix,
		v_NamePremiumSuffix;

bool	g_PluginChangedName[MAXPLAYERS+1] = false;

#define	PLUGIN_VERSION	"2.0.1"

public Plugin myinfo = {
	name        = "[TF2] Free2BeRenamed",
	author      = "DarthNinja, Updated to new syntax by Tk /id/Teamkiller324",
	description = "Automatically adds tags for premium and non-premium players.",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_free2rename_version", PLUGIN_VERSION, "Free2BeRenamed", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_NameFreePrefix = CreateConVar("sm_free_prefix", "[F2P]", "Prefix tag for free users");
	v_NameFreeSuffix = CreateConVar("sm_free_suffix", "", "Suffix tag for free users");
	
	v_NamePremiumPrefix = CreateConVar("sm_premium_prefix", "", "Prefix tag for premium users");
	v_NamePremiumSuffix = CreateConVar("sm_premium_suffix", "", "Suffix tag for premium users");
	
	HookEvent("player_changename", OnPlayerChangeName, EventHookMode_Post);
	
	AutoExecConfig(true, "Free2Rename");
}

public void OnClientPostAdminCheck(int client)
{	
	if (IsFakeClient(client))
		return;
		
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		char Prefix[MAX_NAME_LENGTH];
		char Suffix[MAX_NAME_LENGTH];
		v_NameFreePrefix.GetString(Prefix, MAX_NAME_LENGTH);
		v_NameFreeSuffix.GetString(Suffix, MAX_NAME_LENGTH);
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			char NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%N%s", Prefix, client, Suffix);
			SetClientInfo(client, "name", NewName);
			g_PluginChangedName[client] = true;
		}
		return;
	}
	else
	{
		char Prefix[MAX_NAME_LENGTH];
		char Suffix[MAX_NAME_LENGTH];
		v_NamePremiumPrefix.GetString(Prefix, sizeof(Prefix));
		v_NamePremiumSuffix.GetString(Suffix, sizeof(Suffix));
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			char NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%N%s", Prefix, client, Suffix);
			SetClientInfo(client, "name", NewName);
			g_PluginChangedName[client] = true;
		}
	}
	return;
}

Action Timer_Rename(Handle timer, DataPack pack)
{
	char NewName[MAX_NAME_LENGTH];
	pack.Reset();
	pack.ReadString(NewName, sizeof(NewName));
	int client = GetClientOfUserId(pack.ReadCell());
	
	if (client != 0)
	{
		SetClientInfo(client, "name", NewName);
	}
		
	return Plugin_Stop;
}


void OnPlayerChangeName(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
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
	
	char Name[MAX_NAME_LENGTH];
	event.GetString("newname", Name, sizeof(Name));
	
	if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
		//Free player
		char Prefix[MAX_NAME_LENGTH];
		char Suffix[MAX_NAME_LENGTH];
		v_NameFreePrefix.GetString(Prefix, sizeof(Prefix));
		v_NameFreeSuffix.GetString(Suffix, sizeof(Suffix));
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			char NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, Name, Suffix);
			g_PluginChangedName[client] = true;
			DataPack pack;
			CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteString(NewName);
			pack.WriteCell(GetClientUserId(client));
		}
	}
	else
	{
		char Prefix[MAX_NAME_LENGTH];
		char Suffix[MAX_NAME_LENGTH];
		v_NamePremiumPrefix.GetString(Prefix, sizeof(Prefix));
		v_NamePremiumSuffix.GetString(Suffix, sizeof(Suffix));
		
		if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
		{
			char NewName[MAX_NAME_LENGTH];
			FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, Name, Suffix);
			g_PluginChangedName[client] = true;
			DataPack pack;
			CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteString(NewName);
			pack.WriteCell(GetClientUserId(client));
		}
	}
}