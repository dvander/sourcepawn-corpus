#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[CSS] Hats
*	Author	:	SilverShot
*	Version	:	1.0
*	Descp	:	Attaches specified models to players above their head.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=153781

========================================================================================
	Change Log:

*	1.0
	- Initial Release.

======================================================================================*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <ToggleEffects>
#pragma semicolon			1

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define CHAT_TAG			"\x05[HATS]\x03 "
#define CONFIG_SPAWNS		"data/css_hats.cfg"
#define	MAX_HATS			64

new Handle:g_hCookie_HatSettings = INVALID_HANDLE;
new bool:g_bIsDonator[MAXPLAYERS+1];

static	Handle:g_hCvarMenu, Handle:g_hCvarOpaq, Handle:g_hMenu,
		String:g_sModels[MAX_HATS][64],
		String:g_sNames[MAX_HATS][64],
		Float:g_vAng[MAX_HATS][3],
		Float:g_vPos[MAX_HATS][3],
		g_iHatIndex[MAXPLAYERS+1],		// Player hat entity reference
		g_iSelected[MAXPLAYERS+1],		// The selected hat index (0 to MAX_HATS)
		g_iTarget[MAXPLAYERS+1],			// For admins to change clients hats
		bool:g_bHatView[MAXPLAYERS+1],	// Player view of hat on/off
		bool:g_bThird[MAXPLAYERS+1],		// Thirdperson view of hat on/off
		g_iCount;


public Plugin:myinfo =
{
	name = "[CS:S] Hats",
	author = "SilverShot modified by databomb",
	description = "Attaches specified models to players above their head.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=153781"
};

void:ReadConfigFile()
{
	new i, Handle:hFile = OpenConfig();
	decl String:sTemp[64];
	for( i = 0; i < MAX_HATS; i++ )
	{
		IntToString(i+1, sTemp, 8);
		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetString(hFile, "mod", sTemp, 64);
			KvGetVector(hFile, "ang", g_vAng[i]);
			KvGetVector(hFile, "loc", g_vPos[i]);

			TrimString(sTemp);
			if( strlen(sTemp) == 0 )
				break;

			if( FileExists(sTemp, true) )
			{
				g_iCount++;
				strcopy(g_sModels[i], 64, sTemp);
				KvGetString(hFile, "name", g_sNames[i], 64);
				if( strlen(g_sNames[i]) == 0 )
					GetHatName(g_sNames[i], i);
			}
			else
				LogError("Found the model '%s'", sTemp);

			KvRewind(hFile);
		}
	}
	CloseHandle(hFile);
}

// ====================================================================================================
//					P L U G I N   S T A R T  /  E N D
// ====================================================================================================
public OnPluginStart()
{
	ReadConfigFile();
	
	if (g_iCount == 0)
	{
		SetFailState("No models wtf?!");
	}

	g_hMenu = CreateMenu(HatMenuHandler);
	for( new i = 0; i < g_iCount; i++ )
		AddMenuItem(g_hMenu, g_sModels[i], g_sNames[i]);
	SetMenuTitle(g_hMenu, "Select a Hat:");
	SetMenuExitButton(g_hMenu, true);

	g_hCvarMenu = CreateConVar(	"css_hats_menu",		"sz",				"Specify admin flags or blank to allow all players access to the hats menu.",					CVAR_FLAGS );
	g_hCvarOpaq = CreateConVar(	"css_hats_opaque",		"255", 			"How transparent or solid should the hats appear. 0=Translucent, 255=Opaque.",					CVAR_FLAGS, true, 0.0, true, 255.0 );
	CreateConVar(				"css_hats_version",		PLUGIN_VERSION,	"Hats plugin version.",	CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,		"css_hats");
	
	g_hCookie_HatSettings = RegClientCookie("Hats_Settings", "Stores all client hats settings.", CookieAccess_Protected);
	SetCookieMenuItem(CookieMenu_Hats, 0, "Player Hats");

	RegAdminCmd("sm_hat",		CmdHat,			0,				"Displays a menu of hats allowing players to change what they are wearing." );
	RegAdminCmd("sm_hats",     CmdHat,        0,          "Displays a menu of hats allowing players to change what they are wearing." );
	RegConsoleCmd("sm_hatshow",	CmdHatShow,						"Toggle to see or hide your own hat." );
	RegConsoleCmd("sm_hatview",	CmdHatShow,						"Toggle to see or hide your own hat." );
	RegAdminCmd("sm_hatc",		CmdHatClient,	ADMFLAG_ROOT,	"Brings up a player list to change their hats." );
	RegAdminCmd("sm_hatadd",	CmdHatAdd,		ADMFLAG_ROOT,	"Adds specified model to the config (must be the full model path)." );
	RegAdminCmd("sm_hatdel",	CmdHatDel,		ADMFLAG_ROOT,	"Removes a model from the config (either by index or partial name matching)." );
	RegAdminCmd("sm_hatlist",	CmdHatList,		ADMFLAG_ROOT,	"Displays a list of all the hat models (for use with sm_hatdel)." );
	RegAdminCmd("sm_hatsave",	CmdHatSave,		ADMFLAG_ROOT,	"Saves the hat position and angels to the hat config." );
	RegAdminCmd("sm_hatang",	CmdAng,			ADMFLAG_ROOT,	"Brings up a menu allowing you to adjust the hat angles (affects all hats/players)." );
	RegAdminCmd("sm_hatpos",	CmdPos,			ADMFLAG_ROOT,	"Brings up a menu allowing you to adjust the hat position (affects all hats/players)." );
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_Spawn);

	HookConVarChange(g_hCvarOpaq, CvarChangeOpac);

	for( new i = 1; i <= MaxClients; i++ )
	{
		g_bHatView[i] = false;		
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:s_AdminFlags[32];
	GetConVarString(g_hCvarMenu, s_AdminFlags, sizeof(s_AdminFlags));
	if (strlen(s_AdminFlags) > 0)
	{		
		if (GetUserFlagBits(client) & ReadFlagString(s_AdminFlags))
		{
			g_bIsDonator[client] = true;
		}
		else
		{
			g_bIsDonator[client] = false;
		}
	}
	// or else it's for everyone
	else
	{
		g_bIsDonator[client] = true;
	}
}

public CookieMenu_Hats(client, CookieMenuAction:selection, any:info, String:buffer[], maxlen)
{
	if (selection != CookieMenuAction_DisplayOption)
	{
		if (!g_bIsDonator[client])
		{
			PrintToChat(client, "\x04This menu is reserved for donators only!");
		}
		else
		{
			// launch regular hats menu
			DisplayMenu(g_hMenu, client, MENU_TIME_FOREVER);
		}
	}
}

public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		RemoveHat(i);
	}
}

// ====================================================================================================
//					O T H E R   B I T S
// ====================================================================================================
public OnMapStart()
{
	for( new i = 0; i < g_iCount; i++ )
	{
		PrecacheModel(g_sModels[i]);
	}
}

public OnClientAuthorized(client, const String:sSteamID[])
{
	g_bThird[client] = false;
}

Handle:OpenConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		SetFailState("Cannot find the file data/css_hats.cfg");

	new Handle:hFile = CreateKeyValues("models");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		SetFailState("Cannot load the file 'data/css_hats.cfg'");
	}
	return hFile;
}

SaveConfig(Handle:hFile)
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
}

GetHatName(String:sTemp[64], i)
{
	strcopy(sTemp, 64, g_sModels[i]);
	ReplaceString(sTemp, 64, "_", " ");
	new pos = FindCharInString(sTemp, '/', true) + 1;
	new len = strlen(sTemp) - pos - 3;
	strcopy(sTemp, len, sTemp[pos]);
}

IsValidClient(client)
{
	if( !client || !IsClientInGame(client) || (GetClientTeam(client) <= 1) || !IsPlayerAlive(client) )
		return false;
	return true;
}

// ====================================================================================================
//					C V A R   C H A N G E S
// ====================================================================================================
public CvarChangeOpac(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new ent, int = GetConVarInt(g_hCvarOpaq);
	for( new i = 1; i <= MaxClients; i++ )
	{
		ent = g_iHatIndex[i];
		if( IsValidClient(i) && ent && EntRefToEntIndex(ent) != -1 )
		{
			SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
			SetEntityRenderColor(ent, 255, 255, 255, int);
		}
	}
}



// ====================================================================================================
//					C O M M A N D S
// ====================================================================================================

// ====================================================================================================
//					sm_hatshow
// ====================================================================================================
public Action:CmdHatShow(client, args)
{
	new entity = g_iHatIndex[client];
	entity = EntRefToEntIndex(entity);
	if( entity == INVALID_ENT_REFERENCE )
	{
		ReplyToCommand(client, "%s\x04Warning: \x03No hat found!", CHAT_TAG);
		return Plugin_Handled;
	}

	g_bHatView[client] = !g_bHatView[client];
	if( !g_bHatView[client] )
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	else
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	ReplyToCommand(client, "%sPersonal hat view has been turned \x5%s", CHAT_TAG, g_bHatView[client] ? "on" : "off");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hat
// ====================================================================================================
public Action:CmdHat(client, args)
{

	decl String:sTemp[64];
	GetConVarString(g_hCvarMenu, sTemp, sizeof(sTemp));
	new flags = ReadFlagString(sTemp);

	if (!(GetUserFlagBits(client) & flags))
	{
		ReplyToCommand(client, "%sYou must be a donator to have hats!", CHAT_TAG);
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		if( strlen(sTemp) < 3 )
		{
			new index = StringToInt(sTemp);
			if( index < 1 || index >= (g_iCount + 1) )
				ReplyToCommand(client, "%sCannot find the hat index %d, values between 1 and %d", CHAT_TAG, index, g_iCount);
			else
			{
				RemoveHat(client);
				CreateHat(client, index-1);
			}
		}
		else
		{
			for( new i = 0; i < g_iCount; i++ )
			{
				ReplaceString(sTemp, sizeof(sTemp), " ", "_");
				if( StrContains(g_sModels[i], sTemp) != -1 )
				{
					RemoveHat(client);
					CreateHat(client, i);
					return Plugin_Handled;
				}
			}

			ReplyToCommand(client, "%sCannot find the hat '\x05%s\x03'.", CHAT_TAG, sTemp);
		}
	}
	else
		DisplayMenu(g_hMenu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public OnClientCookiesCached(client)
{
	decl String:sCookieSettings[32];
	
	GetClientCookie(client, g_hCookie_HatSettings, sCookieSettings, sizeof(sCookieSettings));
	if (StrEqual(sCookieSettings, ""))
	{
		// set defaults
	}
	else
	{
		g_iSelected[client] = StringToInt(sCookieSettings);
	}
}

public HatMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		new target = g_iTarget[client];
		if( target )
		{
			g_iTarget[client] = 0;
			target = GetClientOfUserId(target);
			if( IsValidClient(target) )
			{
				PrintToChat(client, "%sChanged hat on \x05%N\x03.", CHAT_TAG, target);
				RemoveHat(target);
				CreateHat(target, index);
			}
			else
				PrintToChat(client, "%sInvalid player selected.", CHAT_TAG);
			return;
		}
		else
		{
			RemoveHat(client);
			CreateHat(client, index);
			decl String:sBuffer[20];
			IntToString(index, sBuffer, sizeof(sBuffer));
			PrintToChat(client, "set cookie: %s", sBuffer);
			SetClientCookie(client, g_hCookie_HatSettings, sBuffer);
		}

		//DisplayMenu(g_hMenu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (index == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
}



// ====================================================================================================
//					A D M I N   C O M M A N D S
// ====================================================================================================

// ====================================================================================================
//					sm_hatc / sm_hatoffc
// ====================================================================================================
public Action:CmdHatClient(client, args)
{
	ShowPlayerList(client);
	return Plugin_Handled;
}

ShowPlayerList(client)
{
	if( client && IsClientInGame(client) )
	{
		decl String:sTempA[16], String:sTempB[MAX_NAME_LENGTH];
		new Handle:menu = CreateMenu(PlayerListHandler);

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
				GetClientName(i, sTempB, sizeof(sTempB));
				AddMenuItem(menu, sTempA, sTempB);
			}
		}

		SetMenuTitle(menu, "Select player to change hat:");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public PlayerListHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	else if( action == MenuAction_Select )
	{
		decl String:sTemp[32];
		GetMenuItem(menu, index, sTemp, sizeof(sTemp));
		new target = StringToInt(sTemp);
		target = GetClientOfUserId(target);
		if( IsValidClient(target) )
		{
			g_iTarget[client] = GetClientUserId(target);
			DisplayMenu(g_hMenu, client, MENU_TIME_FOREVER);
		}
	}
}

// ====================================================================================================
//					sm_hatadd
// ====================================================================================================
public Action:CmdHatAdd(client, args)
{
	if( args == 1 )
	{
		if( g_iCount < MAX_HATS )
		{
			decl String:sTemp[64], String:sKey[16];
			GetCmdArg(1, sTemp, 64);

			if( FileExists(g_sModels[g_iCount], true) )
			{
				strcopy(g_sModels[g_iCount], 64, sTemp);
				g_vAng[g_iCount] = NULL_VECTOR;
				g_vPos[g_iCount] = NULL_VECTOR;

				new Handle:hFile = OpenConfig();
				IntToString(g_iCount+1, sKey, 64);
				KvJumpToKey(hFile, sKey, true);
				KvSetString(hFile, "mod", sTemp);
				SaveConfig(hFile);
				CloseHandle(hFile);
				g_iCount++;
				ReplyToCommand(client, "%sAdded hat '\05%s\x03' %d/%d", CHAT_TAG, sTemp, g_iCount, MAX_HATS);
			}
			else
				ReplyToCommand(client, "%sCould not find the model '\05%s'. Not adding to config.", CHAT_TAG, sTemp);
		}
		else
		{
			ReplyToCommand(client, "%sReached maximum number of hats (%d)", CHAT_TAG, MAX_HATS);
		}
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatdel
// ====================================================================================================
public Action:CmdHatDel(client, args)
{
	if( args == 1 )
	{
		decl String:sTemp[64], String:sModel[64], String:sKey[16];
		new index, bool:bDeleted;

		GetCmdArg(1, sTemp,64);
		if( strlen(sTemp) < 3 )
		{
			index = StringToInt(sTemp);
			if( index < 1 || index >= (g_iCount + 1) )
			{
				ReplyToCommand(client, "%sCannot find the hat index %d, values between 1 and %d", CHAT_TAG, index, g_iCount);
				return Plugin_Handled;
			}
			index--;
			strcopy(sTemp, 64, g_sModels[index]);
		}
		else
		{
			index = 0;
		}

		new Handle:hFile = OpenConfig();

		for( new i = index; i < MAX_HATS; i++ )
		{
			Format(sKey, sizeof(sKey), "%d", i+1);
			if( KvJumpToKey(hFile, sKey) )
			{
				if( bDeleted )
				{
					Format(sKey, sizeof(sKey), "%d", i);
					KvSetSectionName(hFile, sKey);
					strcopy(g_sModels[i-1], 64, g_sModels[i]);
					strcopy(g_sNames[i-1], 64, g_sNames[i]);
					g_vAng[i-1] = g_vAng[i];
					g_vPos[i-1] = g_vPos[i];
				}
				else
				{
					KvGetString(hFile, "mod", sModel, 64);
					if( StrContains(sModel, sTemp) != -1 )
					{
						ReplyToCommand(client, "%sYou have deleted the hat '\x05%s\x03'", CHAT_TAG, sModel);
						KvDeleteKey(hFile, sTemp);
						RemoveMenuItem(g_hMenu, i);
						g_iCount--;
						bDeleted = true;
					}
				}
			}
			KvRewind(hFile);
			if( i == 63 )
			{
				if( bDeleted )
					SaveConfig(hFile);
				else
					ReplyToCommand(client, "%sCould not delete hat, did not find model '\x05%s\x03'", CHAT_TAG, sTemp);
			}
		}
		CloseHandle(hFile);
	}
	else
	{
		new index = g_iSelected[client];
		ReplyToCommand(client, "%sYou are wearing: \x05%s", CHAT_TAG, g_sNames[index]);
	}
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatlist
// ====================================================================================================
public Action:CmdHatList(client, args)
{
	for( new i = 0; i < g_iCount; i++ )
		ReplyToCommand(client, "%d) %s", i+1, g_sModels[i]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatsave
// ====================================================================================================
public Action:CmdHatSave(client, args)
{
	if( IsValidClient(client) )
	{
		new ent = g_iHatIndex[client];
		if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE )
		{
			new Handle:hFile = OpenConfig();
			new index = g_iSelected[client];

			decl String:sTemp[4];
			IntToString(index+1, sTemp, 4);
			if( KvJumpToKey(hFile, sTemp) )
			{
				decl Float:vAng[3], Float:vPos[3];
				GetEntPropVector(ent, Prop_Send, "m_angRotation", vAng);
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
				KvSetVector(hFile, "ang", vAng);
				KvSetVector(hFile, "loc", vPos);
				g_vAng[index] = vAng;
				g_vPos[index] = vPos;
				SaveConfig(hFile);
				PrintToChat(client, "%sSaved '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			else
			{
				PrintToChat(client, "%s\x04Warning: \x03Could not save '\x05%s\x03' hat origin and angles.", CHAT_TAG, g_sModels[index]);
			}
			CloseHandle(hFile);
		}
	}

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_hatang
// ====================================================================================================
public Action:CmdAng(client, args)
{
	ShowAngMenu(client);
	return Plugin_Handled;
}

ShowAngMenu(client)
{
	if( !IsValidClient(client) )
	{
		ReplyToCommand(client, "%sYou do not have access to this command!", CHAT_TAG);
		return;
	}

	new Handle:menu = CreateMenu(AngMenuHandler);

	AddMenuItem(menu, "", "X + 10.0");
	AddMenuItem(menu, "", "Y + 10.0");
	AddMenuItem(menu, "", "Z + 10.0");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 10.0");
	AddMenuItem(menu, "", "Y - 10.0");
	AddMenuItem(menu, "", "Z - 10.0");

	SetMenuTitle(menu, "Set hat angle.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowAngMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowAngMenu(client);

			new Float:vAng[3], ent;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					ent = g_iHatIndex[i];
					if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE )
					{
						GetEntPropVector(ent, Prop_Send, "m_angRotation", vAng);
						if( index == 0 ) vAng[0] += 10.0;
						else if( index == 1 ) vAng[1] += 10.0;
						else if( index == 2 ) vAng[2] += 10.0;
						else if( index == 4 ) vAng[0] -= 10.0;
						else if( index == 5 ) vAng[1] -= 10.0;
						else if( index == 6 ) vAng[2] -= 10.0;
						TeleportEntity(ent, NULL_VECTOR, vAng, NULL_VECTOR);
					}
				}
			}
			PrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
		}
	}
}

// ====================================================================================================
//					sm_hatpos
// ====================================================================================================
public Action:CmdPos(client, args)
{
	ShowPosMenu(client);
	return Plugin_Handled;
}

ShowPosMenu(client)
{
	if( !IsValidClient(client) )
	{
		ReplyToCommand(client, "%sYou do not have access to this command!", CHAT_TAG);
		return;
	}

	new Handle:menu = CreateMenu(PosMenuHandler);

	AddMenuItem(menu, "", "X + 0.5");
	AddMenuItem(menu, "", "Y + 0.5");
	AddMenuItem(menu, "", "Z + 0.5");
	AddMenuItem(menu, "", "");
	AddMenuItem(menu, "", "X - 0.5");
	AddMenuItem(menu, "", "Y - 0.5");
	AddMenuItem(menu, "", "Z - 0.5");

	SetMenuTitle(menu, "Set hat position.");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
		CloseHandle(menu);
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowPosMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( IsValidClient(client) )
		{
			ShowPosMenu(client);

			new Float:vPos[3], ent;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsValidClient(i) )
				{
					ent = g_iHatIndex[i];
					if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE )
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
						if( index == 0 ) vPos[0] += 0.5;
						else if( index == 1 ) vPos[1] += 0.5;
						else if( index == 2 ) vPos[2] += 0.5;
						else if( index == 4 ) vPos[0] -= 0.5;
						else if( index == 5 ) vPos[1] -= 0.5;
						else if( index == 6 ) vPos[2] -= 0.5;
						TeleportEntity(ent, vPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			PrintToChat(client, "%sNew hat origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
		}
	}
}



// ====================================================================================================
//					E V E N T S
// ====================================================================================================

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for( new i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( !client || (GetClientTeam(client) != 2 && GetClientTeam(client) != 3) )
		return;

	RemoveHat(client);
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);
	
	PrintToServer("donator %d index %d", g_bIsDonator[client], g_iSelected[client]);
	if (g_bIsDonator[client] && (g_iSelected[client] >= 0))
	{
		RemoveHat(client);
		CreateTimer(0.5, tmrDelayCreate, clientID);
	}
}

public Action:tmrDelayCreate(Handle:timer, any:clientID)
{
	new client = GetClientOfUserId(clientID);
	if( IsValidClient(client) )
	{
		PrintToChat(client, "spawned hat id %d", g_iSelected[client]);
		CreateHat(client, g_iSelected[client]);
	}
}


// ====================================================================================================
//					H A T   S T U F F
// ===================================================================================================
RemoveHat(client)
{
	new ent = g_iHatIndex[client];
	g_iHatIndex[client] = 0;

	if( ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE )
		AcceptEntityInput(ent, "kill");
}

CreateHat(client, index = -1)
{
	if((g_iHatIndex[client] != 0 && EntRefToEntIndex(g_iHatIndex[client]) != INVALID_ENT_REFERENCE) || !IsValidClient(client) )
		return;

	new i;
	if( index == -1 ) // Random hat
		i = GetRandomInt(0, g_iCount -1);
	else if( index == -2 ) // Previous hat
		i = g_iSelected[client];
	else // Specified hat
		i = index;

	new entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, g_sModels[i]);
		PrintToChat(client, "%sYou are now wearing the \x05[%s] \x03hat.", CHAT_TAG, g_sNames[i]);
		DispatchSpawn(entity);

		decl String:sTemp[64];
		Format(sTemp, sizeof(sTemp), "hat%d%d", entity, client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "SetParent", entity, entity, 0);
		SetVariantString("forward");
		AcceptEntityInput(entity, "SetParentAttachment");
		TeleportEntity(entity, g_vPos[i], g_vAng[i], NULL_VECTOR);

		if( GetConVarInt(g_hCvarOpaq) )
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, GetConVarInt(g_hCvarOpaq));
		}

		g_iSelected[client] = i;
		g_iHatIndex[client] = EntIndexToEntRef(entity);
		if( !g_bHatView[client] )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if (!ShowClientEffects(client))
	{
		return Plugin_Handled;
	}
	new hat = g_iHatIndex[client];
	if( hat && EntRefToEntIndex(hat) == entity )
		return Plugin_Handled;
	return Plugin_Continue;
}