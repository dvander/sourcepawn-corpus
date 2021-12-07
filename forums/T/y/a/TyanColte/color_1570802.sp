#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <donator.inc>

#define PLUGIN_NAME "Donator: Skin Color"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION "0.0.0 (GNU/GPLv3)"
#define PLUGIN_URL ""
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

enum RGBA {
	Red = 0,
	Green,
	Blue // ,
	// Alpha
};

new g_Color[MAXPLAYERS+1][_:RGBA + 1];

#if 0
new String:g_ColorName[RGBA][] = {
	"Red",
	"Green",
	"Blue" // ,
	// "Alpha"
};
new RGBA:g_CurColor[MAXPLAYERS+1];
#else
new Handle:g_ColorList,
	Handle:g_Colors;
#endif

new g_DonatorItemID;

new bool:g_IsDonatorInterfaceLoaded = false;

public OnPluginStart() {
	for (new i = 0; i <= MAXPLAYERS; i++) {
		for (new j = 0; j < (_:RGBA + 1); j++) {
			g_Color[i][j] = 255;
		}
	}

	g_IsDonatorInterfaceLoaded = LibraryExists("donator.core");
	if (g_IsDonatorInterfaceLoaded) {
		OnDonatorInterfaceLoaded();
	}

	HookEventEx("player_spawn", Event_PlayerSpawn);

	g_ColorList = CreateArray(ByteCountToCells(64));
	g_Colors = CreateArray(4);

	decl rgba[4];

	#if 0
	#else
	rgba[3] = 255;
	PushArrayString(g_ColorList, "Black");
	rgba[0] = 0; rgba[1] = 0; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Red");
	rgba[0] = 255; rgba[1] = 0; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Green");
	rgba[0] = 0; rgba[1] = 255; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Blue");
	rgba[0] = 0; rgba[1] = 0; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Yellow");
	rgba[0] = 255; rgba[1] = 255; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Purple");
	rgba[0] = 255; rgba[1] = 0; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Cyan");
	rgba[0] = 0; rgba[1] = 255; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Orange");
	rgba[0] = 255; rgba[1] = 128; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Pink");
	rgba[0] = 255; rgba[1] = 0; rgba[2] = 128;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Olive");
	rgba[0] = 128; rgba[1] = 255; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Lime");
	rgba[0] = 0; rgba[1] = 255; rgba[2] = 128;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Violet");
	rgba[0] = 128; rgba[1] = 0; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Light Blue");
	rgba[0] = 0; rgba[1] = 128; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Silver");
	rgba[0] = 192; rgba[1] = 192; rgba[2] = 192;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Chocolate");
	rgba[0] = 210; rgba[1] = 105; rgba[2] = 30;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Saddle Brown");
	rgba[0] = 139; rgba[1] = 69; rgba[2] = 19;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Indigo");
	rgba[0] = 75; rgba[1] = 0; rgba[2] = 130;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Ghostwhite");
	rgba[0] = 248; rgba[1] = 248; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Thistle");
	rgba[0] = 216; rgba[1] = 191; rgba[2] = 216;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Alice Blue");
	rgba[0] = 240; rgba[1] = 248; rgba[2] = 255;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Steel Blue");
	rgba[0] = 70; rgba[1] = 130; rgba[2] = 180;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Teal");
	rgba[0] = 0; rgba[1] = 128; rgba[2] = 128;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Gold");
	rgba[0] = 255; rgba[1] = 215; rgba[2] = 0;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Tan");
	rgba[0] = 210; rgba[1] = 180; rgba[2] = 140;
	PushArrayArray(g_Colors, rgba);

	PushArrayString(g_ColorList, "Tomato");
	rgba[0] = 255; rgba[1] = 99; rgba[2] = 71;
	PushArrayArray(g_Colors, rgba);
	#endif
}

public OnPluginEnd() {
	if (g_IsDonatorInterfaceLoaded) {
		Donator_UnregisterMenuItem(g_DonatorItemID);
	}

	for (new i = 0, j; i <= MaxClients; i++) {
		for (j = 0; j < _:RGBA; j++) {
			if (g_Color[i][j] != 255) {
				SetEntityRenderProperties(i);
				break;
			}
		}
	}
}

public OnAllPluginsLoaded() {
	if (!g_IsDonatorInterfaceLoaded) {
		g_IsDonatorInterfaceLoaded = LibraryExists("donator.core");
		if (g_IsDonatorInterfaceLoaded) {
			OnDonatorInterfaceLoaded();
		}
	}
}

public OnClientConnected(client) {
	for (new i = 0; i < (_:RGBA + 1); i++) {
		g_Color[client][i] = 255;
	}
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "donator.core")) {
		g_IsDonatorInterfaceLoaded = true;
		OnDonatorInterfaceLoaded();
	}
}

public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "donator.core")) {
		g_IsDonatorInterfaceLoaded = false;
	}
}

OnDonatorInterfaceLoaded() {
	g_DonatorItemID = Donator_RegisterMenuItem("Change Skin Color", OnDonatorMenuSelection);
}

ShowMainMenu(client) {
	new Handle:menu = CreateMenu(MainMenuHandler);
#if 0
	// SetMenuTitle(menu, "Change Skin Color (r%i g%i b%i a%i):", g_Color[client][Red], g_Color[client][Green], g_Color[client][Blue], g_Color[client][Alpha]);
	SetMenuTitle(menu, "Change Skin Color (r%i g%i b%i):", g_Color[client][Red], g_Color[client][Green], g_Color[client][Blue]);
#else
	SetMenuTitle(menu, "Change Skin Color:");
#endif

#if 0
	decl String:info[4],
		String:item[16];
	for (new i = 0; i < _:RGBA; i++) {
		Format(info, sizeof(info), "%i", _:i);
		Format(item, sizeof(item), "%s (%i)", g_ColorName[i], g_Color[client][i]);
		AddMenuItem(menu, info, item);
	}
#else
	decl String:item[64];
	for (new i, size = GetArraySize(g_ColorList); i < size; i++) {
		GetArrayString(g_ColorList, i, item, sizeof(item));
		AddMenuItem(menu, "", item);
	}
#endif
	
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "reset", "Reset");

	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

#if 0
public MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		if (param2 >= 0 && RGBA:param2 < RGBA) {
			ShowColorMenu(param1, RGBA:param2);
		}
		else if (param2 == (_:RGBA + 1)) {
			for (new i = 0; i < _:RGBA; i++) {
				g_Color[param1][i] = 255;
			}
			ShowMainMenu(param1);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
#else
public MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[8];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "reset")) {
			g_Color[param1][0] = 255;
			g_Color[param1][1] = 255;
			g_Color[param1][2] = 255;
			g_Color[param1][3] = 255;
			SetEntityRenderColor(param1);
		}
		else {
			GetArrayArray(g_Colors, param2, g_Color[param1]);
			SetEntityRenderProperties(param1, g_Color[param1]);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
#endif

#if 0
ShowColorMenu(client, RGBA:color) {
	static items[6] = { 1, -1, 10, -10, 100, -100 };

	decl String:info[8],
		String:item[16];
	new Handle:menu = CreateMenu(ColorMenuHandler);
	SetMenuTitle(menu, "%s (%i)", g_ColorName[color], g_Color[client][color]); 
	for (new i = 0; i < 6; i++) {
		Format(info, sizeof(info), "%i", items[i]);
		Format(item, sizeof(item), "%s by %i", (items[i]>0?"Increase":"Decrease"), (items[i]>0?items[i]:-items[i]), (items[i]>0?(g_Color[client][color]<(256-items[i])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED):(g_Color[client][client]>(-1+items[i])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED)));
		AddMenuItem(menu, info, item);
	}
	// SetMenuExitBackButton(menu, true);
	g_CurColor[client] = color;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public ColorMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:info[8];
		GetMenuItem(menu, param2, info, sizeof(info));

		new amount = StringToInt(info);
		g_Color[param1][g_CurColor[param1]] += amount;
		if (g_Color[param1][g_CurColor[param1]] < 0) {
			g_Color[param1][g_CurColor[param1]] = 0;
		}
		else if (g_Color[param1][g_CurColor[param1]] > 255) {
			g_Color[param1][g_CurColor[param1]] = 255;
		}

		SetEntityRenderProperties(param1, g_Color[param1]);
		ShowColorMenu(param1, g_CurColor[param1]);
	}
	else if (action == MenuAction_End) {
		#if 0
		if (param1 == MenuEnd_ExitBack) {
			ShowMainMenu(param2);
		}
		#endif

		CloseHandle(menu);
	}
}
#endif

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && IsPlayerDonator(client)) {
		SetEntityRenderProperties(client, g_Color[client]);
	}
}

public DonatorMenu:OnDonatorMenuSelection(client) {
	ShowMainMenu(client);
}

stock SetEntityRenderProperties(entity, color[4] = {255, 255, 255, 255}, RenderMode:mode = RENDER_NORMAL, extra = 7) {
	if (entity > 0 && entity <= MaxClients) {
		if (extra & 1) {
			#if 0
			new m_hMyWeapons = GetMyWeaponsOffset();

			for (new i = 0, weapon; i < 47; i += 4) {
				weapon = GetEntDataEnt2(entity, m_hMyWeapons + i);
		
				if (weapon > 0 && IsValidEdict(weapon)) {
					decl String:classname[64];
					if (GetEdictClassname(weapon, classname, sizeof(classname)) && StrContains(classname, "weapon") != 0) {
						SetEntityRenderMode(weapon, mode);
						SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
					}
				}
			}
			#else
			for (new i = 0, weapon = GetPlayerWeaponSlot(entity, i); weapon != -1; i++, weapon = GetPlayerWeaponSlot(entity, i)) {
				if (i != -1) {
					SetEntityRenderMode(weapon, mode);
					SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
				}
			}
			#endif
		}
		if (extra & 2) {
				SetTF2WearablesRenderProperties(entity, color, mode, "tf_wearable", "CTFWearable");
				SetTF2WearablesRenderProperties(entity, color, mode, "tf_wearable_demoshield", "CTFWearableDemoShield");
		}
		if ((extra & 7) && color[3] != 255) {
			if (mode == RENDER_NORMAL) {
				mode = RENDER_TRANSCOLOR;
			}
		}
	}

	SetEntityRenderMode(entity, mode);
	SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
}

stock GetGameType() {
	static ret = -1;

	if (ret == -1) {
		decl String:gamefolder[16];
		GetGameFolderName(gamefolder,sizeof(gamefolder));

		static String:game[][] = {
			"dods",
			"tf",
			"cstrike"
		};

		for (new i = 0; i < 3; i++) {
			if (StrEqual(gamefolder, game[i])) {
				return i + 1;
			}
		}

		if (ret == -1) {
			ret = 0;
		}
	}

	return ret;
}

stock GetMyWeaponsOffset() {
	static offset = -1;
	if (offset == -1 ) {
		decl String:buff[16];
		Format(buff, sizeof(buff), (GetGameType()==1?"CDODPlayer":"CBasePlayer"));
		offset = FindSendPropOffs(buff, "m_hMyWeapons");
	}

	return offset;
}

stock SetTF2WearablesRenderProperties(client, color[4] = {255, 255, 255, 255}, RenderMode:mode = RENDER_NORMAL, const String:entClass[], const String:serverClass[]) {
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, entClass)) != -1) {
		if (IsValidEntity(ent) && GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client) {
			SetEntityRenderMode(ent, mode);
			SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
		}
	}
}
