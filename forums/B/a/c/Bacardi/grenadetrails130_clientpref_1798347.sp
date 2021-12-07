/**
	Original  Grenade Trails 1.1 = https://forums.alliedmods.net/showthread.php?t=68057

	This 1.2
	- SDKHooks require
	- Cvar: gt_enables "1" // 0 = Disable, 1 = Enable, 2 = For admins
	- Admin override: "sm_grenade_trails" (adminflag "a" by default)

	This 1.3
	- support clientpref
	- Cvar: gt_enables "3" //
	1 = enable for non-admins
	2 = enable for admins
	4 = by clientprefs (!settings)
	8 = If 4 is specified, only admins by clientprefs (!settings)
	16 = exclude bots
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <clientprefs>


public Plugin:myinfo = 
{
	name = "Grenade Trails (clientpref)",
	description = "Adds a trail to grenades.",
	author = "Bacardi",
	version = "1.3",
	url = "https://forums.alliedmods.net/showthread.php?t=195944"
}

#define FragColor 	{225,0,0,225}
#define FlashColor 	{255,116,0,225}
#define SmokeColor	{0,225,0,225}

new g_iCvarMode;
new g_iBeamSpriteIndex;
new bool:g_bCanCheckGrenades;
new bool:g_bIsActive[MAXPLAYERS+1];

new Handle:g_hCookie;


public OnPluginStart()
{
	new Handle:cvar = CreateConVar("gt_enables", "3", "Grenade Trails\n1 = non-admins\n2 = admins\n4 = !settings\n8 = if 4 specific, admins only\n16 = exlude bots", FCVAR_NONE, true, 0.0, true, 31.0);
	g_iCvarMode = GetConVarInt(cvar);
	HookConVarChange(cvar, cvar_change);
	CloseHandle(cvar);

	LoadTranslations("common.phrases");

	g_hCookie = RegClientCookie("Grenade Trails-1.3-cookie", "Grenade trails cookie setting", CookieAccess_Protected);
	SetCookieMenuItem(CookieSelected, g_hCookie, "Grenade Trails");

	// Plugin reloaded ?
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public OnMapEnd()
{
	g_bCanCheckGrenades = false;
}

public OnMapStart()
{
	g_bCanCheckGrenades = true;
	g_iBeamSpriteIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public cvar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarMode = StringToInt(newValue);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	g_bIsActive[client] = false;

	if( !g_iCvarMode || !(g_iCvarMode & 3) ) // Disabled
	{
		return;
	}

	if( IsFakeClient(client) ) // Bots
	{
		if( g_iCvarMode & 1 && !(g_iCvarMode & 16) )
		{
			g_bIsActive[client] = true;
		}
		return;
	}

	new bool:haveaccess = CheckCommandAccess(client, "sm_grenade_trails", ADMFLAG_RESERVATION);

	if( g_iCvarMode & 1 && g_iCvarMode & 2 ) // everyone
	{
		g_bIsActive[client] = true;

		if( !(g_iCvarMode & 8) ) // everyone can use own settings
		{
			haveaccess = true;
		}
	}
	else
	{
		g_bIsActive[client] = haveaccess; // admins only

		if( g_iCvarMode & 1 ) // non-admins only
		{
			g_bIsActive[client] = !haveaccess;

			if( !(g_iCvarMode & 8) ) // non-admins only with settings
			{
				haveaccess = !haveaccess;
			}
		}
	}

	if( g_iCvarMode & 4 && haveaccess ) // Enable trails by clientprefs (!settings)
	{
		if( AreClientCookiesCached(client) )
		{
			new String:buffer[3];
			GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));

			if(StrEqual(buffer, NULL_STRING)) // Player first time on server
			{
				Format(buffer, sizeof(buffer), "1");
				SetClientCookie(client, g_hCookie, buffer);
			}

			g_bIsActive[client] = StringToInt(buffer) != 0;
		}
	}
}

public CookieSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%s : %T", buffer, g_bIsActive[client] ? "On":"Off", client);
	}
	else if(action == CookieMenuAction_SelectOption)
	{
		PrepareMenu(client);
	}
}

PrepareMenu(client)
{
	new Handle:menu = CreateMenu(GTMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem|MenuAction_Display);
	SetMenuTitle(menu, "Grenade Trails");
	AddMenuItem(menu, "0", "Off");
	AddMenuItem(menu, "1", "On");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public GTMenu(Handle:menu, MenuAction:action, param1, param2)
{
	static bool:haveaccess[MAXPLAYERS+1];

	switch(action)
	{
		case MenuAction_DrawItem:
		{
			haveaccess[param1] = CheckCommandAccess(param1, "sm_grenade_trails", ADMFLAG_RESERVATION);

			if( g_iCvarMode & 1 && g_iCvarMode & 2 )
			{
				if( !(g_iCvarMode & 8) ) // everyone
				{
					haveaccess[param1] = true;
				}
			}
			else if( g_iCvarMode & 1 && !(g_iCvarMode & 8) ) // non-admins only
			{
				haveaccess[param1] = !haveaccess[param1];
			}

			if( !(g_iCvarMode & 4) || !(g_iCvarMode & 3) || !haveaccess[param1] ) // disabled, no access
			{
				return ITEMDRAW_SPACER;
			}
			else if( _:g_bIsActive[param1] == param2 ) // current state
			{
				return ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_DisplayItem:
		{
			// Translate
			new String:dispBuf[50];
			GetMenuItem(menu, param2, "", 0, _, dispBuf, sizeof(dispBuf));
			Format(dispBuf, sizeof(dispBuf), "%T", dispBuf, param1);
			return RedrawMenuItem(dispBuf);
		}
		case MenuAction_Display:
		{
			new String:buffer[100];
			GetMenuTitle(menu, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer), "%s : %T", buffer, g_bIsActive[param1] ? "On":"Off", param1);

			if( !(g_iCvarMode & 4) || !(g_iCvarMode & 3) )
			{
				Format(buffer, sizeof(buffer), "%s\nThese settings not in use!", buffer);
			}
			else if( !haveaccess[param1] )
			{
				Format(buffer, sizeof(buffer), "%s\nAccess denied", buffer);
			}
			SetMenuTitle(menu, buffer);
		}
		case MenuAction_Select:
		{
			// Can still choose menu option using console cmd "menuselect" "1", lets recheck
			// Or cvar change in this moment before player choose option

			if( g_iCvarMode & 4 && (g_iCvarMode & 1 || g_iCvarMode & 2) )
			{
				haveaccess[param1] = CheckCommandAccess(param1, "sm_grenade_trails", ADMFLAG_RESERVATION);

				if( g_iCvarMode & 1 && g_iCvarMode & 2 )
				{
					if( !(g_iCvarMode & 8) ) // everyone
					{
						haveaccess[param1] = true;
					}
				}
				else if( g_iCvarMode & 1 && !(g_iCvarMode & 8) ) // non-admins only
				{
					haveaccess[param1] = !haveaccess[param1];
				}

				if( haveaccess[param1] )
				{
					new String:info[50];
					if( GetMenuItem(menu, param2, info, sizeof(info)) )
					{
						SetClientCookie(param1, g_hCookie, info);
						g_bIsActive[param1] = StringToInt(info) != 0;
						PrepareMenu(param1);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_Exit ) // Exit go back !settings
			{
				ShowCookieMenu(param1);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}

	return 0;
}


public OnEntityCreated(entity, const String:classname[])
{
	if( !g_iCvarMode || !(g_iCvarMode & 3) ) // Disabled
	{
		return;
	}

	if(g_bCanCheckGrenades && StrContains(classname, "_projectile", false) != -1)
	{
		new Handle:datapack = INVALID_HANDLE;
		CreateDataTimer(0.0, projectile, datapack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(datapack, entity);
		WritePackString(datapack, classname);
		ResetPack(datapack);
	}
}

public Action:projectile(Handle:timer, Handle:datapack)
{
	new entity = ReadPackCell(datapack);
	new m_hThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

	if(0 < m_hThrower <= MaxClients && g_bIsActive[m_hThrower])
	{
		new String:classname[30];
		ReadPackString(datapack, classname, sizeof(classname));

		if(StrContains(classname, "hegrenade", false) != -1)
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, FragColor);
			TE_SendToAll();
		}
		else if(StrContains(classname, "flashbang", false) != -1)
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, FlashColor);
			TE_SendToAll();
		}
		else // smokegrenade and rest grenades
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, SmokeColor);
			TE_SendToAll();	
		}
	}
}