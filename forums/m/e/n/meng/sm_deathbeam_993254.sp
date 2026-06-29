#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "sm_deathbeam",
	author = "Meng",
	description = "death beam effect",
	version = "PLUGIN_VERSION",
	url = ""
}

new Handle:g_cvarprefdefault;
new Handle:g_cvarbeamduration;
new g_prefdefault;
new Float:g_beamduration;
new p_beampref[MAXPLAYERS+1];
new Handle:g_dbeamcookie;
new g_sprite;

public OnPluginStart()
{
	LoadTranslations("deathbeam.phrases");
	decl String:menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);

	CreateConVar("sm_deathbeam_version", PLUGIN_VERSION, "Death Beam Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarprefdefault = CreateConVar("sm_deathbeam_prefdefault", "1", "default client preference 0 - 6");
	g_cvarbeamduration = CreateConVar("sm_deathbeam_duration", "12", "seconds the beam lasts");
	g_dbeamcookie = RegClientCookie("dbeam-enable", "enabled setting", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, menutitle);

	HookEvent("player_death", EventPlayerDeath);
}

public OnConfigsExecuted()
{
	g_prefdefault = GetConVarInt(g_cvarprefdefault);
	g_beamduration = GetConVarFloat(g_cvarbeamduration);
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
}

public OnClientCookiesCached(client)
{
	decl String:pref[8];
	GetClientCookie(client, g_dbeamcookie, pref, sizeof(pref));
	if (StrEqual(pref, ""))
		p_beampref[client] = g_prefdefault;
	else
		p_beampref[client] = StringToInt(pref);
}

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		decl String:MenuItem[64];
		new Handle:prefmenu = CreateMenu(PrefMenuHandler);
		new currPref = p_beampref[client];
		Format(MenuItem, sizeof(MenuItem), "%t", "Death_Beam_Control");
		SetMenuTitle(prefmenu, MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Disabled", currPref == 0 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "0", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Red", currPref == 1 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "1", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Green", currPref == 2 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "2", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Blue", currPref == 3 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "3", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Orange", currPref == 4 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "4", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Purple", currPref == 5 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "5", MenuItem);
		Format(MenuItem, sizeof(MenuItem), "%t%t", "Random", currPref == 6 ? "(Selected)" : "space");
		AddMenuItem(prefmenu, "6", MenuItem);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		decl String:pref[8];
		GetMenuItem(prefmenu, item, pref, sizeof(pref));
		p_beampref[client] = StringToInt(pref);
		SetClientCookie(client, g_dbeamcookie, pref);
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_End)
		CloseHandle(prefmenu);
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new pref = p_beampref[victim];
	if (!IsFakeClient(victim) && pref)
	{
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		if (attacker && attacker != victim)
		{
			decl Float:victimOrigin[3], Float:attackerOrigin[3], color[4];
			GetClientEyePosition(victim, victimOrigin);
			GetClientEyePosition(attacker, attackerOrigin);
			switch (pref)
			{
				case 1: // red
					color = {255, 25, 15, 255};
				case 2: // green
					color = {75, 255, 75, 255};
				case 3: // blue
					color = {50, 75, 255, 255};
				case 4: // orange
					color = {255, 150, 25, 255};
				case 5: // purple
					color = {255, 125, 255, 255};
				case 6: // random
				{
					color[0] = GetRandomInt(25, 255);
					color[1] = GetRandomInt(25, 255);
					color[2] = GetRandomInt(25, 255);
					color[3] = 255;
				}
			}
			TE_SetupBeamPoints(victimOrigin, attackerOrigin, g_sprite, 0, 0, 0, g_beamduration, 3.0, 3.0, 7, 0.0, color, 0);
			TE_SendToClient(victim);
		}
	}
}