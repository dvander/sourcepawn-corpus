#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_NAME "No Admin Config"
#define PLUGIN_AUTHOR "Avo"
#define PLUGIN_DESCRIPTION "Change configuration with or without admins"
#define PLUGIN_VERSION "1.0"

new Handle:g_hCVarEnabled = INVALID_HANDLE;
new Handle:g_hCVarAdminFlag = INVALID_HANDLE;
new Handle:g_hCVarCfgWith = INVALID_HANDLE;
new Handle:g_hCVarCfgWithout = INVALID_HANDLE;
new Handle:g_hCVarInform = INVALID_HANDLE;

new bool:g_bCVarEnabled = true;
new g_bsCVarAdminFlag = 0;
new String:g_szCVarCfgWith[64];
new String:g_szCVarCfgWithout[64];
new bool:g_bCVarInform = false;

enum NAC_STATUS
{
	NAC_UNKNOWN,
	NAC_WITH,
	NAC_WITHOUT
}
new NAC_STATUS:g_eNacStatus = NAC_STATUS:NAC_UNKNOWN;

new bool:g_abIsAdmin[MAXPLAYERS+1];
new g_iNbAdmins = 0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.teamvec.fr/"
}

public OnPluginStart()
{
	g_hCVarEnabled = CreateConVar( "noadminconfig_enabled", "1", "Enable No Admin Config" );
	CreateConVar("noadminconfig_version", PLUGIN_VERSION, "No Admin Config version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	if( GetConVarInt( g_hCVarEnabled ) != 0 )
	{
		g_hCVarAdminFlag = CreateConVar("noadminconfig_adminflag", "k", "Admin Flags to watch (could be several)", FCVAR_PLUGIN);
		g_hCVarCfgWith = CreateConVar("noadminconfig_cfg_with", "sourcemod/noadminconfig_with.cfg", "Config file to execute with admins (empty to disable)", FCVAR_PLUGIN);
		g_hCVarCfgWithout = CreateConVar("noadminconfig_cfg_without", "sourcemod/noadminconfig_without.cfg", "Config file to execute without admins (empty to disable)", FCVAR_PLUGIN);
		g_hCVarInform = CreateConVar("noadminconfig_inform", "0", "Inform non-admins of config change", FCVAR_PLUGIN);
	
		AutoExecConfig(true, "noadminconfig");

		g_eNacStatus = NAC_STATUS:NAC_UNKNOWN;
			
		LoadTranslations("common.phrases");
		LoadTranslations("noadminconfig.phrases");
	
		PrintToServer("SourceMod No Admin Config %s has been loaded successfully.", PLUGIN_VERSION);
		
		GetConVars();
		
		CheckAllClients();
	}
}
    
public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
  GetConVars();
}

public OnConfigsExecuted()
{
  GetConVars();
}

GetConVars()
{
	g_bCVarEnabled = GetConVarBool(g_hCVarEnabled);
	decl String:szAdminFlag[AdminFlags_TOTAL];
	GetConVarString(g_hCVarAdminFlag, szAdminFlag, sizeof(szAdminFlag));
	g_bsCVarAdminFlag = ReadFlagString(szAdminFlag);
	GetConVarString(g_hCVarCfgWith, g_szCVarCfgWith, sizeof(g_szCVarCfgWith));
	GetConVarString(g_hCVarCfgWithout, g_szCVarCfgWithout, sizeof(g_szCVarCfgWithout));
	g_bCVarInform = GetConVarBool(g_hCVarInform);
}

public OnClientPostAdminCheck(client)
{
	if (!g_bCVarEnabled)
		return true;	
	
	switch (g_eNacStatus)
	{
		case (NAC_STATUS:NAC_UNKNOWN):
		{
			CheckAllClients();
		}
		case (NAC_STATUS:NAC_WITH):
		{
			if (IsClientAdmin(client))
			{
				g_abIsAdmin[client] = true;
				g_iNbAdmins++;
			}
			else
			{
				g_abIsAdmin[client] = false;
			}
		}
		case (NAC_STATUS:NAC_WITHOUT):
		{
			if (IsClientAdmin(client))
			{
				g_abIsAdmin[client] = true;
				g_iNbAdmins++;
				ChangeNacStatus(NAC_STATUS:NAC_WITH);
			}
			else
			{
				g_abIsAdmin[client] = false;
			}
		}
	}
	return true;
}

public OnClientDisconnect_Post(client)
{
	if (!g_bCVarEnabled)
		return true;	
	
	switch (g_eNacStatus)
	{
		case (NAC_STATUS:NAC_UNKNOWN):
		{
			CheckAllClients();
		}
		case (NAC_STATUS:NAC_WITH):
		{
			if (g_abIsAdmin[client])
			{
				g_abIsAdmin[client] = false;
				g_iNbAdmins--;
				if (g_iNbAdmins == 0)
					ChangeNacStatus(NAC_STATUS:NAC_WITHOUT);
			}
		}
	}
	return true;
}

CheckAllClients()
{
	g_iNbAdmins = 0;
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			if( !IsFakeClient(i) && IsClientAdmin(i) )
			{
				g_abIsAdmin[i] = true;
				g_iNbAdmins++;
				ChangeNacStatus(NAC_STATUS:NAC_WITH);
			}
			else
			{
				g_abIsAdmin[i] = false;
			}
		}
	}
	if (g_iNbAdmins == 0)
		ChangeNacStatus(NAC_STATUS:NAC_WITHOUT);
}

bool:IsClientAdmin(client)
{
	return ( GetAdminFlags(GetUserAdmin(client), AdmAccessMode:Access_Effective) & g_bsCVarAdminFlag ) != 0;
}

ChangeNacStatus(NAC_STATUS:status)
{
	if (g_eNacStatus == status)
		return;
	
	g_eNacStatus = status;
	
	switch (g_eNacStatus)
	{
		case (NAC_STATUS:NAC_WITH):
		{
			if (!StrEqual(g_szCVarCfgWith, ""))
			{
				ServerCommand("exec %s", g_szCVarCfgWith);
				SendInformMessage("Cfg With Enabled");
			}
		}
		case (NAC_STATUS:NAC_WITHOUT):
		{
			if (!StrEqual(g_szCVarCfgWithout, ""))
			{
				ServerCommand("exec %s", g_szCVarCfgWithout);
				SendInformMessage("Cfg Without Enabled");
			}
		}
	}
}

SendInformMessage(String:message[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (g_bCVarInform || g_abIsAdmin[i]))
		{
			PrintToChat(i, "\x01\x0B\x04[NoAdminConfig] \x01%t", message);
		}	
	}
}
