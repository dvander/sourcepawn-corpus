#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define VERSION "1.5.2_test" 
#define sName "\x01[\x04LaserAim\x01]"
#define sCom "\x04!settings"

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
	hDot, hDotB, hDotC, hDotG, hDotO, hDotP, hDotR, hDotW, hDotY,
	hBeam,
	iFOV,
	bool:bBeam;

public Plugin:myinfo =
{
	name = "[NMRiH] Laser Aim",
	author = "Leonardo (adapting & moding by Grey83)",
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
	if (hCVar == hCVarEnable)
	{
		bCVarEnable = bool:StringToInt(newValue);
	}
	else if (hCVar == hCVarMessage)
	{
		bCVarMessage = bool:StringToInt(newValue);
	}
	else if (hCVar == hCVarDefColour)
	{
		iCVarDefColour = StringToInt(newValue);
	}
	else if (hCVar == hCVarAll)
	{
		bCVarAll = bool:StringToInt(newValue);
	}
	else if (hCVar == hCVarTrans)
	{
		iCVarTrans = StringToInt(newValue);
	}
	else if (hCVar == hCVarLife)
	{
		fCVarLife = (StringToFloat(newValue)/10);
	}
	else if (hCVar == hCVarWidth)
	{
		fCVarWidth = StringToFloat(newValue);
	}
	else if (hCVar == hCVarDotWidth)
	{
		fCVarDotWidth = StringToFloat(newValue);
	}
}

public OnMapStart()
{
	hBeam = PrecacheModel("materials/sprites/laser/laser_beam.vmt", true);
	hDotB = PrecacheModel("materials/sprites/laser/laser_dot_b.vmt", true);
	hDotC = PrecacheModel("materials/sprites/laser/laser_dot_c.vmt", true);
	hDotG = PrecacheModel("materials/sprites/laser/laser_dot_g.vmt", true);
	hDotO = PrecacheModel("materials/sprites/laser/laser_dot_o.vmt", true);
	hDotP = PrecacheModel("materials/sprites/laser/laser_dot_p.vmt", true);
	hDotR = PrecacheModel("materials/sprites/laser/laser_dot_r.vmt", true);
	hDotW = PrecacheModel("materials/sprites/laser/laser_dot_w.vmt", true);
	hDotY = PrecacheModel("materials/sprites/laser/laser_dot_y.vmt", true);

	AddFileToDownloadsTable( "materials/sprites/laser/laser_beam.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_beam.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_b.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_b.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_c.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_c.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_g.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_g.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_o.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_o.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_p.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_p.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_r.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_r.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_w.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_w.vtf" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_y.vmt" );
	AddFileToDownloadsTable( "materials/sprites/laser/laser_dot_y.vtf" );
}

public OnClientCookiesCached(client)
{
	decl String:pref[8];
	GetClientCookie(client, laser_aim_cookie, pref, sizeof(pref));
	if (StrEqual(pref, ""))
		iAimPref[client] = iCVarDefColour;
	else
		iAimPref[client] = StringToInt(pref);
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
		Format(MenuItem, sizeof(MenuItem), "%t", "Laser_Aim_Control");
		SetMenuTitle(prefmenu, MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Red", currPref == 0 ? "(Selected)" : "none", currPref == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "0", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Orange", currPref == 1 ? "(Selected)" : "none", currPref == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "1", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Yellow", currPref == 2 ? "(Selected)" : "none", currPref == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "2", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Green", currPref == 3 ? "(Selected)" : "none", currPref == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "3", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Cyan", currPref == 4 ? "(Selected)" : "none", currPref == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "4", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Blue", currPref == 5 ? "(Selected)" : "none", currPref == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "5", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Magenta", currPref == 6 ? "(Selected)" : "none", currPref == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "6", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "White", currPref == 7 ? "(Selected)" : "none", currPref == 7 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "7", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Switch off", currPref == 8 ? "(Selected)" : "none", currPref == 8 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		AddMenuItem(prefmenu, "8", MenuItem);
		SetMenuPagination(prefmenu, MENU_NO_PAGINATION)
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		decl String:pref[8];
		GetMenuItem(prefmenu, item, pref, sizeof(pref));
		iAimPref[client] = StringToInt(pref);
		SetClientCookie(client, laser_aim_cookie, pref);
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_End)
		CloseHandle(prefmenu);
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			new String:sPlayerWeapon[32];
			GetClientWeapon(i, sPlayerWeapon, sizeof(sPlayerWeapon));

			if(bCVarEnable)
				if((StrContains(sPlayerWeapon, "fa_", true) == 0) || StrEqual("tool_flare_gun", sPlayerWeapon) || StrEqual("bow_deerhunter", sPlayerWeapon))
				{
					new iPlayerFOV;
					iPlayerFOV = GetEntData(i, iFOV);
					if (iPlayerFOV > 1) bBeam = true;
					else bBeam = false;
					CreateBeam(i);
				}
		}
	}
}

public Action:CreateBeam(any:client)
{
	new pref = iAimPref[client];
	new Float:fPlayerViewOrigin[3];
	GetClientAbsOrigin(client, fPlayerViewOrigin);
	if(GetClientButtons(client) & IN_DUCK)
		fPlayerViewOrigin[2] += 28;
	else
		fPlayerViewOrigin[2] += 60;

	new Float:fPlayerViewDestination[3];
	GetPlayerEye(client, fPlayerViewDestination);

	new Float:distance = GetVectorDistance( fPlayerViewOrigin, fPlayerViewDestination );

	new Float:percentage = 0.4 / ( distance / 100 );

	new Float:f_newPlayerViewOrigin[3];
	f_newPlayerViewOrigin[0] = fPlayerViewOrigin[0] + ( ( fPlayerViewDestination[0] - fPlayerViewOrigin[0] ) * percentage );
	f_newPlayerViewOrigin[1] = fPlayerViewOrigin[1] + ( ( fPlayerViewDestination[1] - fPlayerViewOrigin[1] ) * percentage ) - 0.08;
	f_newPlayerViewOrigin[2] = fPlayerViewOrigin[2] + ( ( fPlayerViewDestination[2] - fPlayerViewOrigin[2] ) * percentage );

	new color[4];
	switch (pref)
	{
		case 0: // Red
			{
				color = {255, 0, 0, iCVarTrans};
				hDot = hDotR
			}
		case 1: // Orange
			{
				color = {255, 127, 0, iCVarTrans};
				hDot = hDotO
			}
		case 2: // Yellow
			{
				color = {255, 255, 0, iCVarTrans};
				hDot = hDotY
			}
		case 3: // Green
			{
				color = {0, 255, 0, iCVarTrans};
				hDot = hDotG
			}
		case 4: // Cyan
			{
				color = {0, 127, 255, iCVarTrans};
				hDot = hDotC
			}
		case 5: // Blue
			{
				color = {0, 0, 255, iCVarTrans};
				hDot = hDotB
			}
		case 6: // Magenta
			{
				color = {255, 0, 255, iCVarTrans};
				hDot = hDotP
			}
		case 7: // White
			{
				color = {255, 255, 255, iCVarTrans};
				hDot = hDotW
			}
		case 8: // none
			{
				color = {0, 0, 0, 0};
				hDot = hDotW
			}
	}

	switch (pref)
	{
		case 8: // AIM switched off
			{
			}
		default: // AIM switched on
			{
				TE_SetupGlowSprite( fPlayerViewDestination, hDot, fCVarLife, fCVarDotWidth, color[3] );
				if(bCVarAll)
				{
					TE_SendToAll();
					if(bBeam)
					{
						TE_SetupBeamPoints( f_newPlayerViewOrigin, fPlayerViewDestination, hBeam, 0, 0, 0, fCVarLife, fCVarWidth, 0.0, 1, 0.0, color, 0 );
						TE_SendToAll();
					}
				}
				else
				{
					TE_SendToClient(client);
					if(bBeam)
					{
						TE_SetupBeamPoints( f_newPlayerViewOrigin, fPlayerViewDestination, hBeam, 0, 0, 0, fCVarLife, fCVarWidth, 0.0, 1, 0.0, color, 0 );
						TE_SendToClient(client);
					}
				}
			}
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