#pragma semicolon 1 

#include <sourcemod>
#include <sdktools>
#include <simplebuild>
#include <morecolors>

#define VERSION "1.2.2"

#define sUsage "{blue}sUsage{default}"
#define sError "{fullred}Error{default}"
#define sAdmin "{black}[{fullred}ADMIN{black}]{default}"
#define sTag "{black}[{purple}SB{black}]{default}"

#define MAX_ENTITIES 2048
#define MAX_QUED_PROPS 32
#define MAX_CONFIG_PROPS 640

new g_aColors[3][4];

new g_iHalo;
new g_iBeam;
new g_iProps;
new g_iPropLimit;
new g_iOwner[MAX_ENTITIES + 1];
new g_iPropCount[MAXPLAYERS + 1];
new g_iCopiedEnt[MAXPLAYERS + 1];
new g_iGrabbedEnt[MAXPLAYERS + 1];
new g_iPreviousColor[MAX_ENTITIES + 1][4];

new Float:g_fGrabOffset[MAXPLAYERS + 1][3];
new Float:g_fCopyOffset[MAXPLAYERS + 1][3];

new bool:g_bEnabled;
new bool:g_bLateLoad;
new bool:g_bLogging;
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bBuffer[MAXPLAYERS + 1];

new String:g_sAuthID[MAXPLAYERS + 1][64];
new String:g_sPropType[MAX_CONFIG_PROPS][64];
new String:g_sSpawnNames[MAX_CONFIG_PROPS][64];
new String:g_sPropDisplayNames[MAX_CONFIG_PROPS][64];
new String:g_sPropPaths[MAX_CONFIG_PROPS][PLATFORM_MAX_PATH];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hPropLimit = INVALID_HANDLE;
new Handle:g_hGrabTimer = INVALID_HANDLE;
new Handle:g_hCopyTimer = INVALID_HANDLE;
new Handle:g_hLogging = INVALID_HANDLE;
new Handle:g_hArray_Queue[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin:myinfo = { name = "Simple-Build", author = "Marcus", description = "A build mod that contains commands to control entities.",	version = VERSION, url = "http://www.sourcemod.com" };

//==========================================================================================
//							-| Plugin Forwards |-
//==========================================================================================

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SaveProps", Native_SaveProps);
	CreateNative("LoadProps", Native_LoadProps);
	
	CreateNative("SetOwner", Native_SetOwner);
	CreateNative("GetOwner", Native_GetOwner);

	CreateNative("SpawnEntity", Native_SpawnEntity);
	CreateNative("DissolveEntity", Native_DissolveEntity);
	
	g_bLateLoad = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_sb_version", VERSION, "This is the version of Simple-Build the server is running.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sv_sb_enabled", "1", "Toggles the features of Simple-Build On or Off. (0 = Off, 1 = On)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hPropLimit = CreateConVar("sv_sb_prop_limit", "100", "This sets the number of props players can spawn.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hLogging = CreateConVar("sv_sb_logging", "1", "Toggles the logging of admin actions. (0 = Off, 1 = On)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookConVarChange(g_hEnabled, OnSettingsChange);
	HookConVarChange(g_hPropLimit, OnSettingsChange);
	HookConVarChange(g_hLogging, OnSettingsChange);

	g_bEnabled = GetConVarBool(g_hEnabled);
	g_iPropLimit = GetConVarInt(g_hPropLimit);
	g_bLogging = GetConVarBool(g_hLogging);
	
	RegAdminCmd("sb_spawn",	Spawn_Prop,		0);
	RegAdminCmd("sb_create",	Create_Prop,		ADMFLAG_ROOT);
	
	RegAdminCmd("sb_remove",	Delete_Prop,	0);
	RegAdminCmd("sb_undo",	Undo_Prop,	0);
	
	RegAdminCmd("sb_owner",	Owner_Prop,	0);
	RegAdminCmd("sb_propinfo", Info_Prop, 0);
	
	RegAdminCmd("sb_move",	Move_Prop,		0);
	RegAdminCmd("sb_rotate",	Rotate_Prop,	0);
	RegAdminCmd("sb_straight",	Straight_Prop,		0);
	
	RegAdminCmd("sb_freeze",	Freeze_Prop,		0);
	RegAdminCmd("sb_unfreeze",	Unfreeze_Prop,		0);
	
	RegAdminCmd("sb_solid",	Solid_Prop,		0);
	
	RegAdminCmd("sb_axis", Command_Axis, 0);
	RegAdminCmd("sb_autobuild", Command_Stack, 0);

	RegAdminCmd("sb_alpha",	Alpha_Prop,		0);
	RegAdminCmd("sb_color",	Color_Prop,		0);
	
	RegAdminCmd("+move",	Grab_Prop,		0);
	RegAdminCmd("-move",	UnGrab_Prop,		0);
	RegAdminCmd("+copy",	Copy_Prop,		0);
	RegAdminCmd("-copy",	UnCopy_Prop,		0);
	
	RegAdminCmd("sb_save", Save_Prop, 0);
	RegAdminCmd("sb_load", Load_Prop, 0);
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients;i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				decl String:sAuth[64];
				
				GetClientAuthString(i, sAuth, sizeof(sAuth)-1);
				ReplaceString(sAuth, sizeof(sAuth)-1, ":", "-");
				FormatEx(g_sAuthID[i], sizeof(g_sAuthID[]), "%s", sAuth);		

				g_iPropCount[i] = 0;
				g_iCopiedEnt[i] = -1;
				g_iGrabbedEnt[i] = -1;
				
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
				
				AssignProps(i);
				g_hArray_Queue[i] = CreateArray();
			}
		}
	}
	
	g_aColors[0] = { 255, 0, 0, 200 };
	g_aColors[1] = { 0, 255, 0, 200 };
	g_aColors[2] = { 0, 0, 255, 200 };

	decl String:sPath[PLATFORM_MAX_PATH], String:sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/configs");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/logs");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves/%s", sMap);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);

	Load_Props();
}

public OnClientPutInServer(iClient)
{
	if (IsValidClient(iClient))
	{
		decl String:sAuth[64];
		GetClientAuthString(iClient, sAuth, sizeof(sAuth)-1);

		ReplaceString(sAuth, sizeof(sAuth)-1, ":", "-");
		FormatEx(g_sAuthID[iClient], sizeof(g_sAuthID[]), "%s", sAuth);
		
		g_iPropCount[iClient] = 0;
		g_iCopiedEnt[iClient] = -1;
		g_iGrabbedEnt[iClient] = -1;
		
		g_bAlive[iClient] = true;

		g_hArray_Queue[iClient] = CreateArray();
	}
}

public OnMapStart()
{	
	g_hGrabTimer = CreateTimer(0.1, Timer_Grab, _, TIMER_REPEAT); // Thank you Mitch
	g_hCopyTimer = CreateTimer(0.1, Timer_Copy, _, TIMER_REPEAT); // As always, you rock!

	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public OnMapEnd()
{
	if (g_hGrabTimer != INVALID_HANDLE) g_hGrabTimer = INVALID_HANDLE;

	if (g_hCopyTimer != INVALID_HANDLE) g_hCopyTimer = INVALID_HANDLE;
}

public OnClientDisconnect(iClient)
{
	for (new i = 0; i <= GetMaxEntities(); i++)
	{
		if (IsValidProp(i) && g_iOwner[i] == iClient)
		{
			decl String:sName[64];
			GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
			
			if (StrContains(sName, "SimpleBuild:") != -1)
			{
				DissolveEntity(i, "3");
			}
		}
	}

	if (g_hArray_Queue[iClient] != INVALID_HANDLE)
		ClearArray(g_hArray_Queue[iClient]);
}

public OnEntityDestroyed(iEntity)
{
	if (IsValidProp(iEntity) && iEntity > MaxClients)
	{
		decl String:sName[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sName, sizeof(sName));
		
		if (StrContains(sName, "SimpleBuild:") != -1)
		{
			g_iPropCount[g_iOwner[iEntity]] -= 1;
			g_iOwner[iEntity] = -1;
		}
	}
}

//==========================================================================================
//							-| Plugin CallBacks |-
//==========================================================================================

public OnSettingsChange(Handle:hCvar, const String:sOld[], const String:sNew[])
{
	if (hCvar == g_hEnabled) g_bEnabled = bool:StringToInt(sNew);
		else
	if (hCvar == g_hPropLimit) g_iPropLimit = StringToInt(sNew);
		else
	if (hCvar == g_hLogging) g_bLogging = bool:StringToInt(sNew);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
} 

//==========================================================================================
//							-| Plugin Commands |-
//==========================================================================================

public Action:Create_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}
	

	if (iArgs < 2)
	{
		CPrintToChat(iClient, "%s %s: m_create <entity classname> <model path>", sTag, sUsage);

		return Plugin_Handled;
	}
	
	if (g_iPropCount[iClient] >= g_iPropLimit)
	{
		CPrintToChat(iClient, "%s %s: You have reached the prop limit! [{cyan}%d{default}/{cyan}%d{default}]", sTag, sError, g_iPropCount[iClient], g_iPropLimit);

		return Plugin_Handled;
	}

	decl String:sArg[32], String:sArg2[PLATFORM_MAX_PATH];
	
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	SpawnEntity(iClient, sArg, sArg2);
	g_iPropCount[iClient]++;
	
	CPrintToChat(iClient, "%s You have manually spawned a prop. [{cyan}%d{default}/{cyan}%d{default}]!", sTag, g_iPropCount[iClient], g_iPropLimit);

	if (g_bLogging) LogCustom("%L: Spawned [%s] with model [%s]", iClient, sArg, sArg2);

	return Plugin_Handled;
}

public Action:Spawn_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}
	

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: m_spawn <propname> <frozen|god>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_iPropCount[iClient] >= g_iPropLimit)
	{
		CPrintToChat(iClient, "%s %s: You have reached the prop limit! [{cyan}%d{default}/{cyan}%d{default}]", sTag, sError, g_iPropCount[iClient], g_iPropLimit);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);
		return Plugin_Handled;
	}

	new bool:bGod, bool:bFrozen;

	if (iArgs >= 2)
	{
		decl String:sArg2[64];
		GetCmdArg(2, sArg2, sizeof(sArg2));

		if ((StrContains(sArg2, "god", false) == -1) && (StrContains(sArg2, "frozen", false) == -1))
		{
			CPrintToChat(iClient, "%s %s: Invalid spawn option: {green}%s{default}. Ignoring ...", sTag, sError, sArg2);

			bGod = false;
			bFrozen = false;
		} else
		{
			if (StrContains(sArg2, "god", false) != -1) bGod = true;

			if (StrContains(sArg2, "frozen", false) != -1) bFrozen = true;
		}
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.25, Timer_CoolDown, GetClientSerial(iClient));

	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));

	new bool:bSpawned = false;
				
	for (new i; i < g_iProps; i++)
	{
		if (!StrEqual(sArg, g_sSpawnNames[i])) continue;

		new iEnt = SpawnEntity(iClient, g_sPropType[i], g_sPropPaths[i]);
		
		g_iPropCount[iClient]++;
		bSpawned = true;
		
		if (iArgs >= 2)
		{
			if (bGod) SetEntProp(iEnt, Prop_Data, "m_takedamage", 0, 1);

			if (bFrozen) AcceptEntityInput(iEnt, "DisableMotion");
		}
		
		CPrintToChat(iClient, "%s You have spawned a prop. [{cyan}%d{default}/{cyan}%d{default}]", sTag, g_iPropCount[iClient], g_iPropLimit);

		break;
	}

	if (!bSpawned)
	{
		CPrintToChat(iClient, "%s %s: Invalid prop alias: {green}%s{default}!", sTag, sError, sArg);
	}
	
	return Plugin_Handled;
}

public Action:Delete_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.25, Timer_CoolDown, GetClientSerial(iClient));

	if (iArgs < 1)
	{
		new iEnt = GetClientAimTarget(iClient, false);

		if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

		if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

		decl String:sClass[32];
		GetEntityClassname(iEnt, sClass, sizeof(sClass));
		
		if (StrEqual(sClass, "player"))
		{
			ForcePlayerSuicide(iEnt);
			
			CPrintToChat(iEnt, "%s You were slayed!", sTag);
			CPrintToChat(iClient, "%s You have slayed {green}%s{default}!", sTag, iEnt);
			
			if (g_bLogging) LogCustom("\"%L\" slayed %N", iClient, iEnt);
		} else if (StrContains(sClass, "prop_physics") != -1)
		{
			WriteQue(iClient, iEnt);
			
			DissolveEntity(iEnt, "3");
			g_iPropCount[g_iOwner[iEnt]] -= 1;
			
			if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("%L deleted %L's prop.", iClient, g_iOwner[iEnt]);
		}
	} else
	{
		decl String:sArg[32];
		GetCmdArg(1, sArg, sizeof(sArg));

		new String:sTargetName[MAX_TARGET_LENGTH];
		new iTargetList[MAXPLAYERS], iTargetCount;
		new bool:bTranslate;
	 
		if ((iTargetCount = ProcessTargetString(sArg, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bTranslate)) <= 0)
		{
			ReplyToTargetError(iClient, iTargetCount);

			return Plugin_Handled;
		}
	 
		for (new i; i < iTargetCount; i++)
		{
			new Float:fDelay = 0.05;
			for (new x; x <= GetMaxEntities(); x++)
			{
				if (IsValidProp(x) && g_iOwner[x] == iTargetList[i])
				{
					decl String:sName[64];
					GetEntPropString(x, Prop_Data, "m_iName", sName, sizeof(sName));
					
					if (StrContains(sName, "SimpleBuild:") != -1)
					{
						CreateTimer(fDelay, Timer_Delete, x);
						g_iPropCount[iTargetList[i]] -= 1;

						fDelay += 0.05;
					}
				}
			}

			if (g_bLogging) LogCustom("\"%L\" deleted all of \"%L\"'s props.", iClient, iTargetList[i]);
		}

		CPrintToChatAll("%s %N has removed %s's props!", sTag, iClient, sTargetName);
	}

	return Plugin_Handled;
}
	
public Action:Undo_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iSize = GetArraySize(g_hArray_Queue[iClient]);

	if (iSize <= 0)
	{
		CPrintToChat(iClient, "%s %s: You do not have any props to undo!", sTag, sError);

		return Plugin_Handled;
	}

	new Handle:hPack = GetArrayCell(g_hArray_Queue[iClient], iSize - 1);
	
	ResetPack(hPack);
	
	new iSolid, iColor[3], iAlpha;
	new Float:fOrigin[3], Float:fAngles[3];
	new String:sModel[128], String:sAuth[64], String:sTarget[64];
	
	ReadPackString(hPack, sModel, sizeof(sModel));
	
	fOrigin[0] = ReadPackFloat(hPack);
	fOrigin[1] = ReadPackFloat(hPack);
	fOrigin[2] = ReadPackFloat(hPack);
	
	fAngles[0] = ReadPackFloat(hPack);
	fAngles[1] = ReadPackFloat(hPack);
	fAngles[2] = ReadPackFloat(hPack);
	
	iSolid = ReadPackCell(hPack);
	iColor[0] = ReadPackCell(hPack);
	iColor[1] = ReadPackCell(hPack);
	iColor[2] = ReadPackCell(hPack);
	iAlpha = ReadPackCell(hPack);
	
	new iEnt = CreateEntityByName("prop_physics_override");
	
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEnt, "targetname", sTarget);
	
	PrecacheModel(sModel, true);
	DispatchKeyValue(iEnt, "model", sModel);
	
	DispatchSpawn(iEnt);
	
	SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
	SetEntityRenderColor(iEnt, iColor[0], iColor[1], iColor[2], iAlpha);
	SetEntProp(iEnt, Prop_Send, "m_CollisionGroup", iSolid, 4, 0);

	g_iPropCount[iClient]++;
	g_iOwner[iEnt] = iClient;
	AcceptEntityInput(iEnt, "DisableMotion");

	RemoveFromArray(g_hArray_Queue[iClient], iSize - 1);
	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	
	CPrintToChat(iClient, "%s You have restored a deleted prop!", sTag);

	return Plugin_Handled;
}

public Action:Owner_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_owner <target>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl String:sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));

	new String:sTargetName[MAX_TARGET_LENGTH];
	new iTargetList[MAXPLAYERS], iTargetCount;
	new bool:bTranslate;
 
	if ((iTargetCount = ProcessTargetString(sArg, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, sTargetName, sizeof(sTargetName), bTranslate)) <= 0)
	{
		ReplyToTargetError(iClient, iTargetCount);

		return Plugin_Handled;
	}
		
	for (new i; i < iTargetCount; i++)
	{
		if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" changed ownership from \"%L\" to \"%L\".", iClient, g_iOwner[iEnt], iTargetList[i]);

		g_iOwner[iEnt] = iTargetList[i];

		g_iPropCount[iClient] -= 1;
		g_iPropCount[iTargetList[i]] += 1;

		CPrintToChat(iClient, "%s Changed prop owner to {green}%N{default}!", sTag, iTargetList[i]);
	}
	
	return Plugin_Handled;
}

public Action:Rotate_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_rotate <x> <y> <z>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}
			
	decl Float:fAngles[3], Float:fAngles2[3];
	decl String:sArg[5], String:sArg2[5], String:sArg3[5];

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));
	
	new iX = StringToInt(sArg);
	new iY = StringToInt(sArg2);
	new iZ = StringToInt(sArg3);

	GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fAngles);

	fAngles2[0] = (fAngles[0] += iX);
	fAngles2[1] = (fAngles[1] += iY);
	fAngles2[2] = (fAngles[2] += iZ);

	TeleportEntity(iEnt, NULL_VECTOR, fAngles2, NULL_VECTOR);
	
	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" rotated \"%L\"'s prop.", iClient, iEnt);

	return Plugin_Handled;
}

public Action:Move_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_move <x> <y> <z>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl Float:fOrigin[3], Float:fOrigin2[3];
	decl String:sArg[32], String:sArg2[32], String:sArg3[32];
	
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));
	
	new iX = StringToInt(sArg);
	new iY = StringToInt(sArg2);
	new iZ = StringToInt(sArg3);

	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fOrigin);

	fOrigin2[0] = (fOrigin[0] += iX);
	fOrigin2[1] = (fOrigin[1] += iY);
	fOrigin2[2] = (fOrigin[2] += iZ);

	TeleportEntity(iEnt, fOrigin2, NULL_VECTOR, NULL_VECTOR);
	
	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" moved \"%L\"'s prop.", iClient, iEnt);

	return Plugin_Handled;
}

public Action:Straight_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl Float:fAngles[3];

	fAngles[0] = 0.0;
	fAngles[1] = 0.0;
	fAngles[2] = 0.0;
			
	TeleportEntity(iEnt, NULL_VECTOR, fAngles, NULL_VECTOR);
	
	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" straightened \"%L\"'s prop.", iClient, g_iOwner[iEnt]);

	return Plugin_Handled;
}

public Action:Freeze_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	new Float:fSpeed[3] = {0.0, 0.0, 0.0};

	AcceptEntityInput(iEnt, "DisableMotion");
	TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, fSpeed);

	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" froze \"%L\"'s prop.", iClient, g_iOwner[iEnt]);

	return Plugin_Handled;
}

public Action:Unfreeze_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	new Float:fSpeed[3] = {0.0, 0.0, 0.0};

	AcceptEntityInput(iEnt, "EnableMotion");
	TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, fSpeed);

	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" unfroze \"%L\"'s prop.", iClient, g_iOwner[iEnt]);

	return Plugin_Handled;
}

public Action:Solid_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}
			
	if (GetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 4, 0) == 0)
	{
		SetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 1);
		CPrintToChat(iClient, "%s Toggled solidity off for prop!", sTag);

		if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" toggled solidity off \"%L\"'s prop.", iClient, g_iOwner[iEnt]);
	} else if (GetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 4, 0) == 1)
	{
		SetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 0);
		CPrintToChat(iClient, "%s Toggled solidity on for prop!", sTag);

		if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" toggled solidity on \"%L\"'s prop.", iClient, g_iOwner[iEnt]);
	}
	
	return Plugin_Handled;
}

public Action:Alpha_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_alpha <amount>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl String:sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
	
	new iAmt = StringToInt(sArg), aColor[3];

	new iOffset = GetEntSendPropOffs(iEnt, "m_clrRender");
		 
	if (iOffset > 0) 
	{
		aColor[0] = GetEntData(iEnt, iOffset, 1);
		aColor[1] = GetEntData(iEnt, iOffset + 1, 1);
		aColor[2] = GetEntData(iEnt, iOffset + 2, 1);
	}

	SetEntityRenderColor(iEnt, aColor[0], aColor[1], aColor[2], iAmt <= 50 ? 50 : iAmt);
			
	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" changed alpha of \"%L\"'s prop.", iClient, g_iOwner[iEnt]);

	return Plugin_Handled;
}

public Action:Color_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_color <red> <green> <blue>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl String:sArg[64], String:sArg2[64], String:sArg3[64];
	
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));
	
	SetEntityRenderColor(iEnt, StringToInt(sArg), StringToInt(sArg2), StringToInt(sArg3), _);

	if (g_bLogging && g_iOwner[iEnt] != iClient) LogCustom("\"%L\" changed color of \"%L\"'s prop.", iClient, g_iOwner[iEnt]);
			
	return Plugin_Handled;
}

public Action:Save_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_save <savename>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));

	SaveProps(iClient, sArg);

	return Plugin_Handled;
}

public Action:Load_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		CPrintToChat(iClient, "%s %s: sb_load <savename>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	decl String:sArg[64];
	GetCmdArg(1, sArg, sizeof(sArg));

	LoadProps(iClient, sArg);

	return Plugin_Handled;
}

public Action:Info_Prop(iClient, args)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl String:sModel[256];
	
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	CPrintToChat(iClient, "%s Displaying information For Entity: {green}%d{default}", sTag, iEnt);
	CPrintToChat(iClient, "%s Entity Owner: {green}%N{default}", sTag, g_iOwner[iEnt]);
	CPrintToChat(iClient, "%s Entity ClassName: {green}%s{default}", sTag, sClass);
	CPrintToChat(iClient, "%s Entity Model: {green}%s{default}", sTag, sModel);

	return Plugin_Handled;
}

public Action:Grab_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl Float:fEntO[3], Float:fClientO[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fClientO);
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntO);

	g_iGrabbedEnt[iClient] = iEnt;

	g_fGrabOffset[iClient][0] = fEntO[0] - fClientO[0];
	g_fGrabOffset[iClient][1] = fEntO[1] - fClientO[1];
	g_fGrabOffset[iClient][2] = fEntO[2] - fClientO[2];

	SetEntityRenderFx(g_iGrabbedEnt[iClient], RENDERFX_DISTORT);
	SetEntityRenderColor(g_iGrabbedEnt[iClient], 0, 255, 0, 128);

	return Plugin_Handled;
}

public Action:UnGrab_Prop(iClient, iArgs)
{
	if (g_iGrabbedEnt[iClient] != -1 && IsValidProp(g_iGrabbedEnt[iClient]))
	{
		SetEntityRenderColor(g_iGrabbedEnt[iClient], g_iPreviousColor[g_iGrabbedEnt[iClient]][0], g_iPreviousColor[g_iGrabbedEnt[iClient]][1], g_iPreviousColor[g_iGrabbedEnt[iClient]][2], g_iPreviousColor[g_iGrabbedEnt[iClient]][3]);

		if (g_iPreviousColor[g_iGrabbedEnt[iClient]][0]  == 255)
			SetEntityRenderFx(g_iGrabbedEnt[iClient], RENDERFX_NONE);
		else
			SetEntityRenderMode(g_iGrabbedEnt[iClient], RENDER_TRANSALPHA);
		
		g_iGrabbedEnt[iClient] = -1;
	} else
	g_iGrabbedEnt[iClient] = -1;
	
	return Plugin_Handled;
}

public Action:Copy_Prop(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl Float:fEntO[3], Float:fClientO[3], Float:fAngles[3];
	decl String:sModel[128], String:sAuth[64], String:sTarget[64];
	
	new iEntity = CreateEntityByName("prop_physics_override");

	GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAngles);
	GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", fEntO);
	GetEntPropVector(iClient, Prop_Data, "m_vecOrigin", fClientO);
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEntity, "targetname", sTarget);
	
	DispatchKeyValue(iEntity, "model", sModel);
	
	if (GetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 4, 0) == 0) SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 0);
		else
	if (GetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 4, 0) == 1) SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 1);

	new aColor[4];
	new iOffset = GetEntSendPropOffs(iEnt, "m_clrRender");
		 
	if (iOffset > 0) 
	{
		aColor[0] = GetEntData(iEnt, iOffset, 1);
		aColor[1] = GetEntData(iEnt, iOffset + 1, 1);
		aColor[2] = GetEntData(iEnt, iOffset + 2, 1);
		aColor[3] = GetEntData(iEnt, iOffset + 3, 1);
	}

	SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
	SetEntityRenderColor(iEntity, aColor[0], aColor[1], aColor[2], aColor[3]);

	g_iPreviousColor[iEntity][0] = aColor[0];
	g_iPreviousColor[iEntity][1] = aColor[1];
	g_iPreviousColor[iEntity][2] = aColor[2];
	g_iPreviousColor[iEntity][3] = aColor[3];

	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "DisableMotion");
	
	TeleportEntity(iEntity, fEntO, fAngles, NULL_VECTOR);
	
	g_iPropCount[iClient]++;
	g_iOwner[iEntity] = iClient;
	g_iCopiedEnt[iClient] = iEntity;

	g_fCopyOffset[iClient][0] = fEntO[0] - fClientO[0];
	g_fCopyOffset[iClient][1] = fEntO[1] - fClientO[1];
	g_fCopyOffset[iClient][2] = fEntO[2] - fClientO[2];

	SetEntityRenderFx(g_iCopiedEnt[iClient], RENDERFX_DISTORT);
	SetEntityRenderColor(g_iCopiedEnt[iClient], 0, 0, 255, 128);

	return Plugin_Handled;
}

public Action:UnCopy_Prop(iClient, iArgs)
{
	if(g_iCopiedEnt[iClient] != -1 && IsValidProp(g_iCopiedEnt[iClient]))
	{
		SetEntityRenderColor(g_iCopiedEnt[iClient], g_iPreviousColor[g_iCopiedEnt[iClient]][0], g_iPreviousColor[g_iCopiedEnt[iClient]][1], g_iPreviousColor[g_iCopiedEnt[iClient]][2], g_iPreviousColor[g_iCopiedEnt[iClient]][3]);

		SetEntityRenderFx(g_iCopiedEnt[iClient], RENDERFX_NONE);

		g_iCopiedEnt[iClient] = -1;
	} else
	g_iCopiedEnt[iClient] = -1;
	
	return Plugin_Handled;
}

public Action:Command_Axis(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	decl Float:fClientO[3], Float:fClientX[3], Float:fClientY[3], Float:fClientZ[3];
	
	GetClientAbsOrigin(iClient, fClientO);
	GetClientAbsOrigin(iClient, fClientX);
	GetClientAbsOrigin(iClient, fClientY);
	GetClientAbsOrigin(iClient, fClientZ);
	
	fClientX[0] += 50;
	fClientY[1] += 50;
	fClientZ[2] += 50;
	
	TE_SetupBeamPoints(fClientO, fClientX, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_aColors[0], 10);
	TE_SendToClient(iClient, 0.0);

	TE_SetupBeamPoints(fClientO, fClientY, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_aColors[1], 10);
	TE_SendToClient(iClient, 0.0);

	TE_SetupBeamPoints(fClientO, fClientZ, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_aColors[2], 10);
	TE_SendToClient(iClient, 0.0);
	
	CPrintToChat(iClient, "%s Created 3D Axis. Red: X Green: Y Blue: Z", sTag);

	return Plugin_Handled;
}

public Action:Command_Stack(iClient, iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToChat(iClient, "%s %s: All features in this plugin have been disabled!", sTag, sError);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient))
	{
		CPrintToChat(iClient, "%s %s: You must be alive to use this command!", sTag, sError);

		return Plugin_Handled;
	}

	if (iArgs < 2)
	{
		CPrintToChat(iClient, "%s %s: sb_autobuild <amount> <x> <y> <z> <opt: unfrozen 0/1>", sTag, sUsage);

		return Plugin_Handled;
	}

	if (g_bBuffer[iClient])
	{
		CPrintToChat(iClient, "%s %s: Woah! Slow down there!", sTag, sError);

		return Plugin_Handled;
	}

	g_bBuffer[iClient] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(iClient));

	new iEnt = GetClientAimTarget(iClient, false);

	if (!RunCheck(iClient, iEnt)) return Plugin_Handled;

	if (!CanTargetProp(iClient, iEnt)) return Plugin_Handled;

	decl String:sClass[32];
	GetEntityClassname(iEnt, sClass, sizeof(sClass));
	
	if ((StrContains(sClass, "player") != -1))
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return Plugin_Handled;
	}

	decl String:sArg[5], String:sArg2[8], String:sArg3[8], String:sArg4[8], String:sArg5[8], Float:fOrigin[3];
	
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));
	GetCmdArg(4, sArg4, sizeof(sArg4));
	GetCmdArg(5, sArg5, sizeof(sArg5));

	if (StringToInt(sArg) > 5)
	{
		CPrintToChat(iClient, "%s %s: You can't autobuild more than 5 props at one time!", sTag, sError);
		return Plugin_Handled;
	} else if (StringToInt(sArg) == 0)
	{
		CPrintToChat(iClient, "%s %s: You can't autobuild 0 props!", sTag, sError);
		return Plugin_Handled;
	}

	fOrigin[0] = StringToFloat(sArg2);
	fOrigin[1] = StringToFloat(sArg3);
	fOrigin[2] = StringToFloat(sArg4);

	decl iFreeze;

	if (strlen(sArg5) <= 0 || StringToInt(sArg5) == 1)
	{
		iFreeze = 1;
	} else
	iFreeze = 0;

	new iCount, Float:fDelay = 0.05;

	while (iCount < StringToInt(sArg))
	{
		iCount++;

		new Handle:hDataPack;
		CreateDataTimer(fDelay, Timer_Stack, hDataPack);
		WritePackCell(hDataPack, iClient);
		WritePackCell(hDataPack, iEnt);
		WritePackCell(hDataPack, iFreeze);
		WritePackFloat(hDataPack, fOrigin[0] * iCount);
		WritePackFloat(hDataPack, fOrigin[1] * iCount);
		WritePackFloat(hDataPack, fOrigin[2] * iCount);

		fDelay += 0.05;
	}

	
	return Plugin_Handled;
}

//==========================================================================================
//							-| Plugin Timers |-
//==========================================================================================

public Action:Timer_Delete(Handle:hTimer, any:iEntity)
{
	DissolveEntity(iEntity, "3");
}

public Action:Timer_Grab(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && (g_iGrabbedEnt[i] != -1) && IsValidProp(g_iGrabbedEnt[i]))
		{
			decl Float:fEntO[3], Float:fClientO[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fClientO);
			
			fEntO[0] = fClientO[0] + g_fGrabOffset[i][0];
			fEntO[1] = fClientO[1] + g_fGrabOffset[i][1];
			fEntO[2] = fClientO[2] + g_fGrabOffset[i][2];
			
			TeleportEntity(g_iGrabbedEnt[i], fEntO, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:Timer_Copy(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && (g_iCopiedEnt[i] != -1) && IsValidProp(g_iCopiedEnt[i]))
		{
			decl Float:fEntO[3], Float:fClientO[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fClientO);
			
			fEntO[0] = fClientO[0] + g_fCopyOffset[i][0];
			fEntO[1] = fClientO[1] + g_fCopyOffset[i][1];
			fEntO[2] = fClientO[2] + g_fCopyOffset[i][2];
			
			TeleportEntity(g_iCopiedEnt[i], fEntO, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:Timer_Load(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new iClient = ReadPackCell(hPack);
	
	decl String:sbuffer[256], String:sBuffers[12][256], iColor[3];
	ReadPackString(hPack, sbuffer, sizeof(sbuffer));
	
	ExplodeString(sbuffer, " ", sBuffers, 12, 255);
	
	decl Float:fOrigin[3], Float:fAngles[3], String:sTarget[64], String:sAuth[64];
	
	new iEntity = CreateEntityByName("prop_physics_override");
	
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEntity, "targetname", sTarget);
	
	PrecacheModel(sBuffers[0]);
	DispatchKeyValue(iEntity, "model", sBuffers[0]);
	
	fOrigin[0] = StringToFloat(sBuffers[1]);
	fOrigin[1] = StringToFloat(sBuffers[2]);
	fOrigin[2] = StringToFloat(sBuffers[3]);
	
	fAngles[0] = StringToFloat(sBuffers[4]);
	fAngles[1] = StringToFloat(sBuffers[5]);
	fAngles[2] = StringToFloat(sBuffers[6]);
	
	iColor[0] = StringToInt(sBuffers[8]);
	iColor[1] = StringToInt(sBuffers[9]);
	iColor[2] = StringToInt(sBuffers[10]);
	
	g_iPreviousColor[iEntity][0] = iColor[0];
	g_iPreviousColor[iEntity][1] = iColor[1];
	g_iPreviousColor[iEntity][2] = iColor[2];
	g_iPreviousColor[iEntity][3] = StringToInt(sBuffers[11]);

	DispatchKeyValue(iEntity, "rendermode", "5");
	DispatchKeyValue(iEntity, "renderamt", sBuffers[11]);

	if (!DispatchSpawn(iEntity)) LogError("didn't spawn");

	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], StringToInt(sBuffers[11]));
	SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", StringToInt(sBuffers[7]), 4, 0);

	AcceptEntityInput(iEntity, "DisableMotion");
	
	g_iOwner[iEntity] = iClient;
	g_iPropCount[iClient] += 1;
	
	TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
}

public Action:Timer_CoolDown(Handle:hTimer, any:iBuffer)
{
	new iClient = GetClientFromSerial(iBuffer);

	if (g_bBuffer[iClient]) g_bBuffer[iClient] = false;
}

public Action:Timer_Stack(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);

	new iClient = ReadPackCell(hPack);
	new iEnt = ReadPackCell(hPack);
	new iFreeze = ReadPackCell(hPack);

	decl Float:fDegree[3];

	fDegree[0] = ReadPackFloat(hPack);
	fDegree[1] = ReadPackFloat(hPack);
	fDegree[2] = ReadPackFloat(hPack);
	
	decl iSolid;
	decl String:sClass[32], String:sModel[256], Float:fEntOrigin[3], Float:fEntAng[3], String:sTarget[64], String:sAuth[32];

	GetEdictClassname(iEnt, sClass, sizeof(sClass));
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fEntOrigin);
	GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fEntAng);
	GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	iSolid = GetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 4, 0);

	new iEntity = StrEqual(sClass, "prop_physics", false) ? CreateEntityByName("prop_physics_override") : CreateEntityByName(sClass);
	
	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEntity, "targetname", sTarget);

	DispatchKeyValue(iEntity, "model", sModel);
	DispatchKeyValue(iEntity, "rendermode", "5");

	if (!DispatchSpawn(iEntity)) LogError("didn't spawn");

	AddVectors(fEntOrigin, fDegree, fEntOrigin);

	new iOffset = GetEntSendPropOffs(iEnt, "m_clrRender"); // Thanks Panda!!!
		 
	if (iOffset > 0) 
	{
		new iColorR = GetEntData(iEnt, iOffset, 1);
		new iColorG = GetEntData(iEnt, iOffset + 1, 1);
		new iColorB = GetEntData(iEnt, iOffset + 2, 1);
		new iAlpha =  GetEntData(iEnt, iOffset + 3, 1);

		SetEntityRenderColor(iEntity, iColorR, iColorG, iColorB, iAlpha);

		g_iPreviousColor[iEntity][0] = iColorR;
		g_iPreviousColor[iEntity][1] = iColorG;
		g_iPreviousColor[iEntity][2] = iColorB;
		g_iPreviousColor[iEntity][3] = iAlpha;
	}
	
	SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", iSolid, 4, 0);

	if (iFreeze == 1)
		AcceptEntityInput(iEntity, "DisableMotion");
	else
		AcceptEntityInput(iEntity, "EnableMotion");

	
	TeleportEntity(iEntity, fEntOrigin, fEntAng, NULL_VECTOR);

	g_iPropCount[iClient] += 1;
	g_iOwner[iEntity] = iClient;
}

//==========================================================================================
//							-| Plugin Stocks |-
//==========================================================================================

stock Load_Props() // Originally, this was from TwistedPanda's BuildWars : It helped alot!!
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "simple-build/configs/simple_build_props.ini");

	new Handle:hKeyValue = CreateKeyValues("Simple-Build Props");
	if (FileToKeyValues(hKeyValue, sPath))
	{
		g_iProps = 0;

		KvGotoFirstSubKey(hKeyValue);
		do
		{
			KvGetString(hKeyValue, "display_name", g_sPropDisplayNames[g_iProps], sizeof(g_sPropDisplayNames));
			KvGetString(hKeyValue, "spawn_name", g_sSpawnNames[g_iProps], sizeof(g_sSpawnNames));
			
			KvGetString(hKeyValue, "path", g_sPropPaths[g_iProps], PLATFORM_MAX_PATH);
			KvGetString(hKeyValue, "type", g_sPropType[g_iProps], sizeof(g_sPropType));
			
			PrecacheModel(g_sPropPaths[g_iProps]);
			g_iProps++;
		}
		while (KvGotoNextKey(hKeyValue));
		CloseHandle(hKeyValue);
		
		PrintToServer("Simple-Build: Loaded %d props", g_iProps);
	} else
	{
		CloseHandle(hKeyValue);
		SetFailState("Simple-Build: Could not locate \"simple-build/configs/simple_build_props.in\"");
	}
}

stock bool:IsValidClient(client) 
{
    if ((1 <= client <= MaxClients) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}

stock bool:IsValidProp(entity)
{
	if (entity > 0 && IsValidEntity(entity))
    {
		return true;
	}
	return false;
}

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

stock RunCheck(iClient, iEnt)
{
	if (IsValidEntity(iEnt) && iEnt != -1)
	{
		new String:sClass[32];
		GetEntityClassname(iEnt, sClass, sizeof(sClass));
		
		if (StrContains(sClass, "prop_physics") != -1 || StrContains(sClass, "player") != -1)
		{
			return true;
		} else
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);
		return false;
	} else
	CPrintToChat(iClient, "%s %s: You are not looking at anything!", sTag, sError);

	return false;
}

stock CanTargetProp(iClient, iEnt)
{
	if (!IsValidClient(iClient)) return false;

	if (iEnt == -1) return false;

	if (!CanUserTarget(iClient, g_iOwner[iEnt]) && g_iOwner[iEnt] != iClient)
	{
		CPrintToChat(iClient, "%s %s: You cannot target that entity!", sTag, sError);

		return false;
	}

	return true;
}

/*
stock CheckOwnership(client, entity)
{
	decl String:sClass[64];
	GetEntityClassname(entity, sClass, sizeof(sClass));
		
	if (GetAdmin(client) == AL_None)
	{
		if ((StrContains(sClass, "player") != -1))
		{
			return false;
		}
	} else 
	
	if ((StrContains(sClass, "player") != -1))
	{
		return true;
	} else
	
	if(entity < MaxClients || entity > MAX_ENTITIES)
		return false;

	if (g_iOwner[entity] == client)
	{
		return true;
	} else
	
	if (GetAdmin(client) == AL_Root)
	{
		return true;
	} else if (GetAdmin(g_iOwner[entity]) == AL_None)
	{
		if (GetAdmin(client) == AL_Admin || GetAdmin(client) == AL_Admin2)
		{
			return true;
		}
	} else if (GetAdmin(g_iOwner[entity]) == AL_Admin)
	{
		if (GetAdmin(client) == AL_Admin)
		{
			return false;
		} else if (GetAdmin(client) == AL_Admin2)
		{
			return false;
		}
	} else if (GetAdmin(g_iOwner[entity]) == AL_Admin2)
	{
		if (GetAdmin(client) == AL_Admin)
		{
			return true;
		} else if (GetAdmin(client) == AL_Admin2)
		{
			return false;
		}
	}
	return false;
} */

stock AssignProps(iClient)
{
	if (IsValidClient(iClient))
	{
		decl String:sAuth[64];
		GetClientAuthString(iClient, sAuth, sizeof(sAuth));
		
		for (new i; i <= GetMaxEntities(); i++)
		{
			if (IsValidProp(i))
			{
				decl String:sName[64];
				GetEntPropString(i, Prop_Data, "m_iName", sName, sizeof(sName));
				
				if (StrContains(sName, sAuth) != -1)
				{
					g_iOwner[i] = iClient;
					g_iPropCount[iClient] += 1;
				}
			}
		}
	}
}

stock WriteQue(iClient, iEntity)
{
	if (IsValidProp(iClient))
	{
		new iSize = GetArraySize(g_hArray_Queue[iClient]);

		if (iSize == MAX_QUED_PROPS) RemoveFromArray(g_hArray_Queue[iClient], 0);
		
		new Handle:hPack = CreateDataPack();
		
		decl String:sModel[128];
		decl Float:fOrigin[3], Float:fAngles[3];

		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOrigin);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fAngles);
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		WritePackString(hPack, sModel);
		
		WritePackFloat(hPack, fOrigin[0]);
		WritePackFloat(hPack, fOrigin[1]);
		WritePackFloat(hPack, fOrigin[2]);
		
		WritePackFloat(hPack, fAngles[0]);
		WritePackFloat(hPack, fAngles[1]);
		WritePackFloat(hPack, fAngles[2]);

		WritePackCell(hPack, GetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 4, 0));
		
		new iOffset = GetEntSendPropOffs(iEntity, "m_clrRender");

		if (iOffset > 0) 
		{
			WritePackCell(hPack, GetEntData(iEntity, iOffset, 1));
			WritePackCell(hPack, GetEntData(iEntity, iOffset + 1, 1));
			WritePackCell(hPack, GetEntData(iEntity, iOffset + 2, 1));
			WritePackCell(hPack, GetEntData(iEntity, iOffset + 3, 1));
		}
		
		PushArrayCell(g_hArray_Queue[iClient], hPack);
	}
}

stock LogCustom(const String:format[], any:...)
{
	new Handle:hFile;
	decl String:sBuffer[512], String:sName[PLATFORM_MAX_PATH], String:sPath[PLATFORM_MAX_PATH], String:sTime[64];
	
	VFormat(sBuffer, 512, format, 2);
	
	FormatTime(sTime, sizeof(sTime), "%m_%Y");
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/logs/%s", sTime);
	if(!DirExists(sPath))
        CreateDirectory(sPath, 511);
		
	FormatTime(sTime, sizeof(sTime), "%m_%Y/%m_%d_%Y");
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/logs/%s", sTime);
	if(!DirExists(sPath))
        CreateDirectory(sPath, 511);

	BuildPath(Path_SM, sName, sizeof(sName), "simple-build/logs/%s/simple_build_logs.txt", sTime);
	hFile = OpenFile(sName, "a+");
	
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y %H:%M:%S");
	WriteFileLine(hFile, "%s  %s", sTime, sBuffer);
	
	FlushFile(hFile);
	CloseHandle(hFile);
}

//==========================================================================================
//							-| Plugin Natives |-
//==========================================================================================

public Native_SpawnEntity(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	new len, len2;
	GetNativeStringLength(2, len);
	GetNativeStringLength(3, len2);
	
	new String:sType[len+1], String:sModel[len2+1];
	GetNativeString(2, sType, len+1);
	GetNativeString(3, sModel, len2+1);
	
	if (len <= 0)
	{ return len; }
	
	decl Float:fOrigin[3], Float:fAngles[3];
	decl String:sAuth[64], String:sTarget[128];
	
	GetClientAbsAngles(client, fAngles);
	GetCollisionPoint(client, fOrigin);

	fOrigin[2] = (fOrigin[2] + 4);

	GetClientAuthString(client, sAuth, sizeof(sAuth));
	
	new iEntity = CreateEntityByName(sType);
	
	Format(sTarget, sizeof(sTarget), "SimpleBuild:%s", sAuth);
	DispatchKeyValue(iEntity, "targetname", sTarget);
	
	PrecacheModel(sModel);
	DispatchKeyValue(iEntity, "model", sModel);

	g_iPreviousColor[iEntity][0] = 255;
	g_iPreviousColor[iEntity][1] = 255;
	g_iPreviousColor[iEntity][2] = 255;
	g_iPreviousColor[iEntity][3] = 255;

	if (DispatchSpawn(iEntity))
	{
		SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
		
		g_iOwner[iEntity] = client;
		TeleportEntity(iEntity, fOrigin, fAngles, NULL_VECTOR);
		
		return iEntity;
	} else
	return -1;
}

public Native_DissolveEntity(Handle:plugin, numParams)
{	
	new entity = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	new String:sType[len+1];
	GetNativeString(2, sType, len+1);
	
	if (len <= 0)
	{ return; }

	decl String:targetname[128];
	
	Format(targetname, sizeof(targetname), "dissolvetarget%f%f", GetGameTime(), GetRandomFloat());
	DispatchKeyValue(entity, "targetname", targetname);
	
	new dissolver = CreateEntityByName("env_entity_dissolver");
	
	DispatchKeyValue(dissolver, "dissolvetype", sType);
	DispatchKeyValue(dissolver, "target", targetname);
	AcceptEntityInput(dissolver, "Dissolve");
	
	AcceptEntityInput(dissolver, "Kill");
}

public Native_SaveProps(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	new String:sName[len+1];
	GetNativeString(2, sName, len+1);
	
	if (len <= 0)
	{ return; }
	
	decl String:FileName[PLATFORM_MAX_PATH], String:sPath[PLATFORM_MAX_PATH], String:sMap[256];
	new iProps = 0;

	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves/%s", sMap);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);

	BuildPath(Path_SM, sPath, sizeof(sPath), "simple-build/saves/%s/%s", sMap, g_sAuthID[client]);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
		
	BuildPath(Path_SM, FileName, sizeof(FileName), "simple-build/saves/%s/%s/%s.txt", sMap, g_sAuthID[client], sName);
	if (FileExists(FileName, true))
	{
		DeleteFile(FileName);
		CPrintToChat(client, "%s Save already exists: \x04%s\x01 ... Overriding old save ...", sTag, sName);
	}
	
	for (new i = 0; i < GetMaxEntities(); i++)
	{
		if (IsValidEntity(i) && g_iOwner[i] == client)
		{
			decl String:sTName[64];
			GetEntPropString(i, Prop_Data, "m_iName", sTName, sizeof(sTName));
			
			if (StrContains(sTName, "SimpleBuild:") != -1)
			{
				decl String:sModel[128], String:sBuffers[12][128], Float:fOrigin[3], Float:fAngles[3], String:SaveBuffer[255];
				
				GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin);
				GetEntPropVector(i, Prop_Send, "m_angRotation", fAngles);
				
				IntToString(RoundFloat(fOrigin[0]), sBuffers[1], 32);   
				IntToString(RoundFloat(fOrigin[1]), sBuffers[2], 32);
				IntToString(RoundFloat(fOrigin[2]), sBuffers[3], 32);
				
				sBuffers[0] = sModel;
				IntToString((GetEntProp(i, Prop_Send, "m_CollisionGroup", 4, 0)), sBuffers[7], 128);
				
				IntToString(RoundFloat(fAngles[0]), sBuffers[4], 32);
				IntToString(RoundFloat(fAngles[1]), sBuffers[5], 32);
				IntToString(RoundFloat(fAngles[2]), sBuffers[6], 32);
				
				new offset = GetEntSendPropOffs(i, "m_clrRender"); // Thanks Panda!!!
		 
				if (offset > 0) 
				{
					IntToString((GetEntData(i, offset, 1)), sBuffers[8], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 1, 1)), sBuffers[9], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 2, 1)), sBuffers[10], sizeof(sBuffers));
					IntToString((GetEntData(i, offset + 3, 1)), sBuffers[11], sizeof(sBuffers));
				}
			
				ImplodeStrings(sBuffers, 12, " ", SaveBuffer, 255);
				
				decl String:buffer[512];
				
				VFormat(buffer, sizeof(buffer), SaveBuffer, 2);
				
				new Handle:_hFile = OpenFile(FileName, "a+");
				
				WriteFileLine(_hFile, "%s", buffer);
				
				FlushFile(_hFile);
				CloseHandle(_hFile);
				
				iProps++;
			}
		}
	}
	
	CPrintToChat(client, "%s Saving %i props under alias: \x04%s\x01", sTag, iProps, sName);
}

public Native_LoadProps(Handle:plugin, numParams)
{	
	new client = GetNativeCell(1);
	new len;
	GetNativeStringLength(2, len);
	
	new String:sName[len+1];
	GetNativeString(2, sName, len+1);
	
	if (len <= 0)
	{ return; }
	
	decl String:FileName[PLATFORM_MAX_PATH], String:sMap[256];

	GetCurrentMap(sMap, sizeof(sMap));

	new Handle:_hFile, Float:fDelay = 0.10, iProps = 0;
	decl String:_sFileBuffer[512];

	BuildPath(Path_SM, FileName, sizeof(FileName), "simple-build/saves/%s/%s/%s.txt", sMap, g_sAuthID[client], sName);

	if (FileExists(FileName, true))
	{
		_hFile = OpenFile(FileName, "r");
		
		while (ReadFileLine(_hFile, _sFileBuffer, sizeof(_sFileBuffer)))
		{
			new Handle:hTemp;
			CreateDataTimer(fDelay, Timer_Load, hTemp);
			
			WritePackCell(hTemp, client);
			WritePackString(hTemp, _sFileBuffer);
			
			iProps++, fDelay += 0.10;
		}
		
		FlushFile(_hFile);
		CloseHandle(_hFile);
		
		CPrintToChat(client, "%s Loading %i props from alias: \x04%s\x01", sTag, iProps, sName);
	} else
	CPrintToChat(client, "%s %s That save alias does not exist for this map: \x04%s\x01", sTag, sError, sName);
}

public Native_GetOwner(Handle:plugin, numParams)
{
	new entity = GetNativeCell(1);
	
	return g_iOwner[entity];
}

public Native_SetOwner(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new entity = GetNativeCell(2);
	
	g_iOwner[entity] = client;
	
	return;
}