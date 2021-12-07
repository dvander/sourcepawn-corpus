// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>

// ---- Defines ----------------------------------------------------------------
#define PLUGIN_VERSION	"1.0"
#define TRAILMAX 100
#define FLOOR_OFFSET 10.0

// ---- Variables --------------------------------------------------------------
new g_TrailCount;
new String:g_TrailName[TRAILMAX][PLATFORM_MAX_PATH];
new String:g_TrailFile[TRAILMAX][PLATFORM_MAX_PATH];
new g_TrailIndex[TRAILMAX];
new g_ShowTrail[MAXPLAYERS + 1];
new g_EntityTrail[MAXPLAYERS + 1] = {-1,...};
new bool:g_AdminCheck[MAXPLAYERS + 1] = {false, ...};
new Handle:g_TrailShowCookie = INVALID_HANDLE;
new String:g_strConfigFile[PLATFORM_MAX_PATH];


public Plugin:myinfo = 
{
	name = "[TF2] Player Trail ",
	author = "Classic",
	description = "Trails for TF2.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("teamplay_round_start", OnRoundStart);
	
	g_TrailShowCookie = RegClientCookie("TF2PlayerTrail", "Which Trail to use.", CookieAccess_Private);
	RegAdminCmd("sm_trail", Command_Trail, ADMFLAG_RESERVATION ,"Opens the trailEnt menu");
	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/PlayerTrail.cfg");
}


public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_ShowTrail[client] = 0;
		g_EntityTrail[client] = -1;
	}
		
	LoadConfig();
	decl String:szBuffer[128];
	for (new i = 0; i < g_TrailCount; i++)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", g_TrailFile[i]);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vtf", g_TrailFile[i]);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
	}
}

public OnClientConnected(client)
{
	g_ShowTrail[client] = 0;
	g_AdminCheck[client] = false;
}

public OnClientPostAdminCheck(client)
{
	g_AdminCheck[client] = true;
	if(AreClientCookiesCached(client))
		OnClientCookiesCached(client);
}

public OnClientCookiesCached(client)
{
	if(g_AdminCheck[client])
	{
		new String:szBuffer[256];
		GetClientCookie(client, g_TrailShowCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 0)
			g_ShowTrail[client] = StringToInt(szBuffer);
		else 
			g_ShowTrail[client] = 0;
	}	
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client 	= GetClientOfUserId(GetEventInt(event, "userid"));
	if(CheckCommandAccess(client,"sm_trail",ADMFLAG_RESERVATION,false))
		EquipTrail(client);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if(CheckCommandAccess(i,"sm_trail",ADMFLAG_RESERVATION,false))
			EquipTrail(i);		
	}
}

public LoadConfig()
{
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}
	
	new Handle:hKeyValues = CreateKeyValues("PlayerTrail");
	if(!FileToKeyValues(hKeyValues, g_strConfigFile))
	{
		SetFailState("Improper structure for configuration file %s!", g_strConfigFile);
		return;
	}
	
	
	new String:sIndex[8];
	for(new i = 0; i < TRAILMAX; i++)
	{
		strcopy(g_TrailName[i], sizeof(g_TrailName[]), "");
		strcopy(g_TrailFile[i], sizeof(g_TrailFile[]), "");
		g_TrailIndex[i] = -1;
	}
	
	g_TrailCount = 0;

	if(!KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("There isn't any sub-key on the file %s!", g_strConfigFile);
		return;
	}
	do
	{
		KvGetSectionName(hKeyValues,sIndex,sizeof(sIndex));
		g_TrailIndex[g_TrailCount] = StringToInt(sIndex);
		KvGetString(hKeyValues, "name", g_TrailName[g_TrailCount], sizeof(g_TrailName[]));
		KvGetString(hKeyValues, "material",	g_TrailFile[g_TrailCount], sizeof(g_TrailFile[]));
		
		g_TrailCount++;
	}
	while(KvGotoNextKey(hKeyValues));
	
	CloseHandle(hKeyValues);

	LogMessage("Loaded %i Trails from configuration file %s.", g_TrailCount, g_strConfigFile);

	decl String:trailBuffer[128];
	for (new i = 0; i < g_TrailCount; i++)
	{
		FormatEx(trailBuffer, sizeof(trailBuffer), "%s.vmt", g_TrailFile[i]);
		PrecacheGeneric(trailBuffer, true);
		AddFileToDownloadsTable(trailBuffer);
		FormatEx(trailBuffer, sizeof(trailBuffer), "%s.vtf", g_TrailFile[i]);
		PrecacheGeneric(trailBuffer, true);
		AddFileToDownloadsTable(trailBuffer);
	}
}


public Action:Command_Trail(client,args)
{
	
	if(IsVoteInProgress())
	{
		PrintToChat(client,"[SM] There is a vote in progress.");
		return;
	}
	if(!AreClientCookiesCached(client)) 
	{
		PrintToChat(client,"[SM] Your cookies aren't cached yet");
		return;
	}
	if(!IsClientAuthorized(client)) 
	{
		PrintToChat(client,"[SM] You aren't Authorized yet");
		return;
	}

	new Handle:hMenu = CreateMenu(TrailSelected);
	SetMenuTitle(hMenu, "Player Trails:");
	SetMenuExitButton(hMenu, true);
	new count = 0;
	decl String:strBuffer[32];
	Format(strBuffer, sizeof(strBuffer),"Disable");
	if(g_ShowTrail[client] == 0)
		AddMenuItem(hMenu, "Disable", strBuffer,ITEMDRAW_DISABLED);
	else
		AddMenuItem(hMenu, "Disable", strBuffer);

	decl String:strTrailIndex[4];
	for(new i = 0; i < g_TrailCount; i++)
	{
		IntToString(i, strTrailIndex, sizeof(strTrailIndex));
		if (g_ShowTrail[client] == g_TrailIndex[i])
			AddMenuItem(hMenu, strTrailIndex, g_TrailName[i],ITEMDRAW_DISABLED);
		else
			AddMenuItem(hMenu, strTrailIndex, g_TrailName[i]);
		count++;
	}
	if(count == 0)
	{
		AddMenuItem(hMenu, "", "There isn't any trailEnt to equip.",ITEMDRAW_DISABLED);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public TrailSelected(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32],String:strSave[32];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		if(StrEqual(strBuffer, "Disable"))
		{
			g_ShowTrail[iParam1] = 0;
			IntToString(0,strSave,sizeof(strSave));
			PrintToChat(iParam1, "[SM] Disabled Player Trail");
		}
		else
		{
			new iTrailIndex = StringToInt(strBuffer);
			g_ShowTrail[iParam1] = g_TrailIndex[iTrailIndex];
			IntToString(g_TrailIndex[iTrailIndex],strSave,sizeof(strSave));
			PrintToChat(iParam1, "[SM] Trail selected : %s",g_TrailName[iTrailIndex]);	
			
		}
		SetClientCookie(iParam1, g_TrailShowCookie, strSave);
		EquipTrail(iParam1);
	}
}

public Action:OnPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillTrail(client);
}

EquipTrail(client)
{
	KillTrail(client);
	
	if(!IsPlayerAlive(client) || !IsClientInGame(client))
		return;
		
	if(g_ShowTrail[client] <= 0 )
		return;
		
	new trailIdx = GetTrailNumber(g_ShowTrail[client]);
	if(trailIdx == -1)
		return;
	
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return;
	
	new trailEnt = CreateEntityByName("env_spritetrail");
	
	if (!IsValidEntity(trailEnt))
		return;
	g_EntityTrail[client] = EntIndexToEntRef(trailEnt);
	new String:strTargetName[MAX_NAME_LENGTH];
	GetClientName(client, strTargetName, sizeof(strTargetName));

	DispatchKeyValue(client, "targetname", strTargetName);
	Format(strTargetName,sizeof(strTargetName),"clienttrail%d",client);
	DispatchKeyValue(client, "targetname", strTargetName);
	DispatchKeyValue(trailEnt, "parentname", strTargetName);
	DispatchKeyValueFloat(trailEnt, "lifetime", 1.0);
	DispatchKeyValueFloat(trailEnt, "endwidth", 15.0);
	DispatchKeyValueFloat(trailEnt, "startwidth", 6.0);
	
	decl String:trailMaterial[PLATFORM_MAX_PATH];
	Format(trailMaterial,PLATFORM_MAX_PATH,"%s.vmt",g_TrailFile[trailIdx]);
	DispatchKeyValue(trailEnt, "spritename", trailMaterial);
	DispatchKeyValue(trailEnt, "renderamt", "255");

	//DispatchKeyValue(trailEnt, "rendercolor", "255 255 255 255");
	DispatchKeyValue(trailEnt, "rendermode", "4");

	DispatchSpawn(trailEnt);

	new Float:Client_Origin[3];
	GetClientAbsOrigin(client,Client_Origin);
	Client_Origin[2] += FLOOR_OFFSET;

	TeleportEntity(trailEnt, Client_Origin, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(strTargetName);
	AcceptEntityInput(trailEnt, "SetParent"); 
	SetEntPropFloat(trailEnt, Prop_Send, "m_flTextureRes", 0.05);

	return;
}

KillTrail(client)
{
	new entity = EntRefToEntIndex(g_EntityTrail[client]);
	if (entity != -1 && entity != INVALID_ENT_REFERENCE)
		AcceptEntityInput(g_EntityTrail[client],"kill");

	g_EntityTrail[client] = -1;
}

public TF2_OnConditionAdded(client, TFCond:cond)
{
    if (cond == TFCond_Cloaked)
        KillTrail(client);
}
 
public TF2_OnConditionRemoved(client, TFCond:cond)
{
    if (cond == TFCond_Cloaked)
       EquipTrail(client);
}

public GetTrailNumber(index)
{
	for(new i = 0; i < g_TrailCount;i++)
		if(g_TrailIndex[i] == index)
			return i;
			
	return -1;

}
