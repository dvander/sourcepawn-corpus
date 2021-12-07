#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define VERSION "1.5.3" 
#define sName "\x01[\x04LaserAim\x01]"
#define sCom "\x04!settings"

#define SpritesPath "materials/sprites/laser/laser_dot_"

new Handle:hCVarEnable, bool:bCVarEnable,
	Handle:hCVarMessage, bool:bCVarMessage,
	Handle:hCVarDefColour, iCVarDefColour,
	Handle:hCVarAll, bool:bCVarAll,
	Handle:hCVarTrans, iCVarTrans,
	Handle:hCVarLife, Float:fCVarLife,
	Handle:hCVarWidth, Float:fCVarWidth,
	Handle:hCVarDotWidth, Float:fCVarDotWidth,
	Handle:laser_aim_cookie;

new iAimPref[MAXPLAYERS+1],
	hBeam = -1,
	iFOV,
	iPlayerFOV,
	bool:bBeam,
	String:sPlayerWeapon[15];

new pref,
	Float:fPlayerViewOrigin[3],
	Float:fPlayerViewDestination[3],
	Float:percentage,
	Float:f_newPlayerViewOrigin[3],
	iColor[4];

#define NUM_COLORS 9
new hDot[NUM_COLORS];
new cColor[] = {'r', 'o', 'y', 'g', 'c', 'b', 'p', 'w'};
new String:sColorName[][] = {
"Red",
"Orange",
"Yellow",
"Green",
"Cyan",
"Blue",
"Purple",
"White",
"Switch off"
};
new aColor[][4] = {
{255, 0, 0, 63},
{255, 127, 0, 63},
{255, 255, 0, 63},
{0, 255, 0, 63},
{0, 127, 255, 63},
{0, 0, 255, 63},
{255, 0, 255, 63},
{255, 255, 255, 63},
{0, 0, 0, 0}
};

public Plugin:myinfo =
{
	name = "[NMRiH] Laser Aim",
	author = "Leonardo (rewrited by Grey83)",
	description = "Creates a laser dot every time a firearm in the hands of the player",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=253367"
};

public OnPluginStart()
{
	LoadTranslations("nmrih_laser_aim.phrases");
	decl String:menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);
	AutoExecConfig(true, "nmrih_laser_aim");

	CreateConVar("nmrih_laser_aim_version", VERSION, "[NMRiH] Laser Aim  plugin's version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY);
	hCVarEnable = CreateConVar("sm_laser_aim_on", "1", "1 turns the plugin on, 0 is off", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0 );
	hCVarMessage = CreateConVar("sm_laser_aim_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	hCVarDefColour = CreateConVar("sm_laser_aim_default", "0", "Default client colour preference (0 - 8)", FCVAR_NONE, true, 0.0, true, 8.0);
	hCVarAll = CreateConVar("sm_laser_aim2all", "1", "The player can see: 1- all lasers, 0 - only their own lasers", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	hCVarTrans = CreateConVar("sm_laser_aim_alpha", "63", "Amount of transparency", FCVAR_NONE, true, 0.0, true, 255.0 );
	hCVarLife = CreateConVar("sm_laser_aim_life", "0.6", "Life of the dot", FCVAR_NONE, true, 0.51, true, 1.0 );
	hCVarWidth = CreateConVar("sm_laser_aim_width", "0.4", "Width of the beam", FCVAR_NONE, true, 0.1);
	hCVarDotWidth = CreateConVar("sm_laser_aim_dot_width", "0.1", "Width of the dot", FCVAR_NONE, true, 0.1);

	laser_aim_cookie = RegClientCookie("laser_aim_enable", "enabled setting", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, menutitle);

	bCVarEnable = GetConVarBool(hCVarEnable);
	bCVarMessage = GetConVarBool(hCVarMessage);
	iCVarDefColour = GetConVarInt(hCVarDefColour);
	bCVarAll = GetConVarBool(hCVarAll);
	iCVarTrans = GetConVarInt(hCVarTrans);
	fCVarLife = (GetConVarFloat(hCVarLife)/10);
	fCVarWidth = GetConVarFloat(hCVarWidth);
	fCVarDotWidth = GetConVarFloat(hCVarDotWidth);

	HookConVarChange(hCVarEnable, OnConVarChange);
	HookConVarChange(hCVarMessage, OnConVarChange);
	HookConVarChange(hCVarDefColour, OnConVarChange);
	HookConVarChange(hCVarAll, OnConVarChange);
	HookConVarChange(hCVarTrans, OnConVarChange);
	HookConVarChange(hCVarLife, OnConVarChange);
	HookConVarChange(hCVarWidth, OnConVarChange);
	HookConVarChange(hCVarDotWidth, OnConVarChange);

	iFOV = FindSendPropOffs("CBasePlayer","m_iFOV");
}

public OnConVarChange(Handle:hCVar, const String:oldValue[], const String:newValue[])
{
	if (hCVar == hCVarEnable) bCVarEnable = bool:StringToInt(newValue);
	else if (hCVar == hCVarMessage) bCVarMessage = bool:StringToInt(newValue);
	else if (hCVar == hCVarDefColour) iCVarDefColour = StringToInt(newValue);
	else if (hCVar == hCVarAll) bCVarAll = bool:StringToInt(newValue);
	else if (hCVar == hCVarTrans) iCVarTrans = StringToInt(newValue);
	else if (hCVar == hCVarLife) fCVarLife = (StringToFloat(newValue)/10);
	else if (hCVar == hCVarWidth) fCVarWidth = StringToFloat(newValue);
	else if (hCVar == hCVarDotWidth) fCVarDotWidth = StringToFloat(newValue);
}

public OnMapStart()
{
	new Handle:gameConfig = LoadGameConfigFile("funcommands.games");
	new String:buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) hBeam = PrecacheModel(buffer);

	decl String:VMTpath[PLATFORM_MAX_PATH];
	VMTpath[0] = '\0';
	decl String:VTFpath[PLATFORM_MAX_PATH];
	VTFpath[0] = '\0';
	for (new i = 0; i < NUM_COLORS-1; i++)
	{
		Format(VMTpath, PLATFORM_MAX_PATH, "%s%c.vmt", SpritesPath, cColor[i]);
		Format(VTFpath, PLATFORM_MAX_PATH, "%s%c.vtf", SpritesPath, cColor[i]);
		hDot[i] = PrecacheModel(VMTpath, true);
		AddFileToDownloadsTable(VMTpath);
		AddFileToDownloadsTable(VTFpath);
	}
}

public OnClientCookiesCached(client)
{
	decl String:sPref[8];
	GetClientCookie(client, laser_aim_cookie, sPref, sizeof(sPref));
	if (StrEqual(sPref, "")) iAimPref[client] = iCVarDefColour;
	else iAimPref[client] = StringToInt(sPref);
}

public OnClientPostAdminCheck(client)
{
 	if (bCVarEnable && bCVarMessage) PrintToChat(client, "%s %t %s", sName, "Welcome Message", sCom);
}

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		decl String:MenuItem[64];
		new Handle:prefmenu = CreateMenu(PrefMenuHandler);
		new currPref = iAimPref[client];
		Format(MenuItem, sizeof(MenuItem), "%T", "Laser_Aim_Control", client);
		SetMenuTitle(prefmenu, MenuItem);
		new String:sNum[2];
		for (new i = 0; i < NUM_COLORS; i++)
		{
			Format(MenuItem, sizeof(MenuItem), "%T%T", sColorName[i], client, currPref == i ? "(Selected)" : "none", client);
			IntToString(i, sNum, 2);
			AddMenuItem(prefmenu, sNum, MenuItem, currPref == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
#if NUM_COLORS < 10
		SetMenuPagination(prefmenu, MENU_NO_PAGINATION);
#endif
		SetMenuExitButton(prefmenu, true);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		decl String:sPref[8];
		GetMenuItem(prefmenu, item, sPref, sizeof(sPref));
		iAimPref[client] = StringToInt(sPref);
		SetClientCookie(client, laser_aim_cookie, sPref);
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_End) CloseHandle(prefmenu);
}

public OnGameFrame()
{
	if(bCVarEnable)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && iAimPref[i] != NUM_COLORS-1)
			{
				GetClientWeapon(i, sPlayerWeapon, sizeof(sPlayerWeapon));

				if((StrContains(sPlayerWeapon, "fa_", true) == 0) || (StrContains(sPlayerWeapon, "tool_flare_gun", true) == 0) || (StrContains(sPlayerWeapon, "bow_deerhunter", true) == 0))
				{
					iPlayerFOV = GetEntData(i, iFOV);
					if (iPlayerFOV > 1) bBeam = true;
					else bBeam = false;
					CreateBeam(i);
				}
			}
		}
	}
}

public Action:CreateBeam(any:client)
{
	pref = iAimPref[client];
	GetClientAbsOrigin(client, fPlayerViewOrigin);
	if(GetClientButtons(client) & IN_DUCK) fPlayerViewOrigin[2] += 28;
	else fPlayerViewOrigin[2] += 60;

	GetPlayerEye(client, fPlayerViewDestination);

	percentage = 0.4 / (GetVectorDistance( fPlayerViewOrigin, fPlayerViewDestination) / 100);

	f_newPlayerViewOrigin[0] = fPlayerViewOrigin[0] + ( ( fPlayerViewDestination[0] - fPlayerViewOrigin[0] ) * percentage );
	f_newPlayerViewOrigin[1] = fPlayerViewOrigin[1] + ( ( fPlayerViewDestination[1] - fPlayerViewOrigin[1] ) * percentage ) - 0.08;
	f_newPlayerViewOrigin[2] = fPlayerViewOrigin[2] + ( ( fPlayerViewDestination[2] - fPlayerViewOrigin[2] ) * percentage );

	iColor = aColor[pref];
	iColor[3] = iCVarTrans;

	TE_SetupGlowSprite( fPlayerViewDestination, hDot[pref], fCVarLife, fCVarDotWidth, iCVarTrans);
	if(bCVarAll) TE_SendToAll();
	else TE_SendToClient(client);

	if(hBeam > -1 && bBeam)
	{
		TE_SetupBeamPoints( f_newPlayerViewOrigin, fPlayerViewDestination, hBeam, 0, 0, 0, fCVarLife, fCVarWidth, 0.0, 1, 0.0, iColor, 0 );
		if(bCVarAll) TE_SendToAll();
		else TE_SendToClient(client);
	}

	return Plugin_Continue;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients();
}