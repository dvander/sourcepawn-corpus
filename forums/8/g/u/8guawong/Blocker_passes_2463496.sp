#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define	DEBUGS			0
#define	BetaBuild		1

/*
	UseMoreColors замените 0 на 1, чтобы использовать библиотеку morecolors
	UseAdminMenu замените 1 на 0, чтобы НЕ использовать меню администратора в игре
*/
#define	UseMoreColors	0
#define	UseAdminMenu	1

#if UseMoreColors
	#include <morecolors>
#endif

#if UseAdminMenu
	#include <sdkhooks>
	#include <adminmenu>
	#undef REQUIRE_PLUGIN
	#define ADMIN_LEVEL		ADMFLAG_ROOT
#endif

#define PLUGIN_VERSION 	"1.2.5 - EN"

const  TEAM_ALL = 1;
const  TEAM_ONE = 2;
const  TEAM_TWO = 3;

new bool:b_late,
	bool:g_bIsLocked;
	
#include "blockerpasses\\stock.sp"
#include "blockerpasses\\natives.sp"	

#if UseAdminMenu
	new Handle:h_menu,
		Handle:h_hETitleMenu,
		Handle:h_PropsMenu,
		Handle:h_RoteMenu,
		Handle:h_ColorMenu,
		Handle:h_QuotaMenu;
#endif

new Handle:blocker_en, Handle:h_anonce, 
	bool:b_enabled, bool:b_anonce,
	Handle:Block_min_player, i_min_players, 
	Handle:h_printchat, bool:g_printchat,
	Handle:Block_accounting_teams, bool:acc_teams,
#if UseAdminMenu	
	Handle:blocker_game_m, bool:b_game_m,
#endif
	Handle:blocker_autosave, bool:b_autosave;
	
new Handle:kv_list, 
	Handle:data_props;

new String:s_MapName[64];
#if UseAdminMenu
	new	String:g_sPropList[64][256];
#endif

public Plugin:myinfo = 
{
	name = "English Blocker passes",
	author = ">>Satan<< - Translated By [W]atch [D]ogs",
	description = "Blocker passes on maps",
	version = PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	b_late = late;
	
	return APLRes_Success;
}

public OnPluginStart() 
{
	#if UseAdminMenu
		h_hETitleMenu 	= CreateMenu(MenuPropMenuHandler);
		SetMenuTitle(h_hETitleMenu, "| English Blocker Passes |");
		SetMenuExitBackButton(h_hETitleMenu, true);
		
		AddMenuItem(h_hETitleMenu, "PropsMenu", 	"Props Menu");
		AddMenuItem(h_hETitleMenu, "ColorMenu", 	"Colors Menu");
		AddMenuItem(h_hETitleMenu, "QuotaMenu", 	"Quota Menu");
		AddMenuItem(h_hETitleMenu, "SaveProps", 	"Save Props");
		AddMenuItem(h_hETitleMenu, 	"", 		"", ITEMDRAW_SPACER);
		AddMenuItem(h_hETitleMenu, "LockAll", 		"Load | All Props");
		AddMenuItem(h_hETitleMenu, "UnLockAll", 	"UnLoad | All Props");
		
		h_RoteMenu = CreateMenu(PropRoteMenuHandle);
		SetMenuTitle(h_RoteMenu, "| Rotate Menu |");
		SetMenuExitBackButton(h_RoteMenu, true);
		
		AddMenuItem(h_RoteMenu, "RotateX+45", "Rotate +45° on axis X");
		AddMenuItem(h_RoteMenu, "RotateX-45", "Rotate -45° on axis X");
		AddMenuItem(h_RoteMenu, "RotateY+45", "Rotate +45° on axis Y");
		AddMenuItem(h_RoteMenu, "RotateY-45", "Rotate -45° on axis Y");
		AddMenuItem(h_RoteMenu, "RotateZ+45", "Rotate +45° on axis Z");
		AddMenuItem(h_RoteMenu, "RotateZ-45", "Rotate -45° on axis Z");
		
		h_ColorMenu = CreateMenu(MenuPropColorHandler);
		SetMenuTitle(h_ColorMenu, "| Colors Menu |");
		SetMenuExitBackButton(h_ColorMenu, true);	
		
		AddMenuItem(h_ColorMenu, "color1", "Red");
		AddMenuItem(h_ColorMenu, "color2", "Green");
		AddMenuItem(h_ColorMenu, "color3", "Blue");
		AddMenuItem(h_ColorMenu, "color4", "Yellow");
		AddMenuItem(h_ColorMenu, "color5", "Blue");
		AddMenuItem(h_ColorMenu, "color6", "Pink\n ");
		AddMenuItem(h_ColorMenu, "color7", "Invisible (25%)");
		AddMenuItem(h_ColorMenu, "color8", "Invisible (100%)");
		
		h_QuotaMenu = CreateMenu(MenuPropQuotaHandler);
		SetMenuTitle(h_QuotaMenu, "| Quota Menu |");
		SetMenuExitBackButton(h_QuotaMenu, true);
		AddMenuItem(h_QuotaMenu, "++", "+1");
		AddMenuItem(h_QuotaMenu, "--", "-1");
		AddMenuItem(h_QuotaMenu, "5", "5");
		AddMenuItem(h_QuotaMenu, "8", "8");
		AddMenuItem(h_QuotaMenu, "10", "10");
		AddMenuItem(h_QuotaMenu, "12", "12");
		AddMenuItem(h_QuotaMenu, "14", "14");
		AddMenuItem(h_QuotaMenu, "16", "16");
		AddMenuItem(h_QuotaMenu, "18", "18");
		AddMenuItem(h_QuotaMenu, "20", "20");
		AddMenuItem(h_QuotaMenu, "24", "24");
		AddMenuItem(h_QuotaMenu, "28", "28");
		AddMenuItem(h_QuotaMenu, "32", "32");
		AddMenuItem(h_QuotaMenu, "64", "64");
	#endif
	
	blocker_en = CreateConVar("sm_bp_enable", 					"1", 	"1|0 Enable / Disable the plugin", _, true, 0.0, true, 1.0);
	b_enabled = GetConVarBool(blocker_en);
	HookConVarChange(blocker_en, OnConVarChanged);
	
	h_anonce = CreateConVar("sm_bp_anonce", 					"1", 	"1|0 Enable / Disable message about the status of the lock plug", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	b_anonce = GetConVarBool(h_anonce);
	HookConVarChange(h_anonce, OnConVarChanged);
	
	h_printchat = CreateConVar("sm_bp_amode", 					"1", 	"Message Display Type (0 - HUD, 1 - Chat)", _, true, 0.0, true, 1.0);
	g_printchat = GetConVarBool(h_printchat);
	HookConVarChange(h_printchat, OnConVarChanged);
	
	Block_min_player = CreateConVar("sm_bp_minplayer", 			"10", 	"The minimum number of players for the machine. removal of all processes, blocking passage", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	i_min_players = GetConVarInt(Block_min_player);
	HookConVarChange(Block_min_player, OnConVarChanged);
	
	Block_accounting_teams = CreateConVar("sm_bp_onlyct", 		"0", 	"1|0 Enable / Disable counting only the players of the CT team for the decision on blocking", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	acc_teams = GetConVarBool(Block_accounting_teams);
	HookConVarChange(Block_accounting_teams, OnConVarChanged);
	
	blocker_autosave = CreateConVar("sm_bp_autosave", 			"0", 	"1|0 Enable / Disable automatic saving props at the end of each round,", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	b_autosave = GetConVarBool(blocker_autosave);
	HookConVarChange(blocker_autosave, OnConVarChanged);
	
	#if UseAdminMenu
		blocker_game_m = CreateConVar("sm_bp_enableadmmenu",	"1",	"1|0 Enable / Disable the plugin management menu in the game",  _, true, 0.0, true, 1.0);
		b_game_m = GetConVarBool(blocker_game_m);
		HookConVarChange(blocker_game_m, OnConVarChanged);
	#endif
	
	AutoExecConfig(true, "Blocker");
	LoadTranslations("blocker_passes.phrases"); 

	data_props = CreateArray();
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	#if UseAdminMenu
		RegAdminCmd("sm_bpmenu", CommandAdminPasses, ADMFLAG_ROOT);
	#endif
	RegAdminCmd("sm_getaimpos", CommandGetPoss, ADMFLAG_ROOT);
	
	if (b_late){
		PreloadConfigs();
		b_late = false;
	}
	
	#if UseAdminMenu
		new Handle:topmenu;
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)){
			OnAdminMenuReady(topmenu);
		}
	#endif
}

public OnMapStart() 
{
	PreloadConfigs();
	
	#if UseAdminMenu
		LoadPropsMenu();
	#endif
	
	decl String:buffer[32];
	#if BetaBuild
		Format(buffer, sizeof(buffer), "blocker_passes_beta_%s", PLUGIN_VERSION);
	#else
		Format(buffer, sizeof(buffer), "blocker_passes_%s", PLUGIN_VERSION);
	#endif
	
	AddServerTag(buffer);
}

public OnMapEnd()
{
	CloseHandle(kv_list);
}

public OnPostThink(client)
{
	decl String:buffer[64], String:sBuffer[128];
	
	new entity = GetClientAimTarget2(client, false);
	
	if (entity > MaxClients){
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if (StrContains(buffer, "BpModelId", true) != -1)
		{
			decl String:outBuffer[2][8];
			ExplodeString(buffer, "_", outBuffer, 2, 16, false);
			Format(sBuffer, sizeof(sBuffer), "The quota for this object: %s", outBuffer[1]);
			//PrintHudText(client, sBuffer);
			PrintToChat(client, sBuffer);
		}
	}

}

void:PreloadConfigs()
{
	GetCurrentMap(s_MapName, sizeof(s_MapName));
	
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/blocker_passes/");
	
	if (!DirExists(path)){
		CreateDirectory(path, 511);
	}
	
	kv_list = CreateKeyValues("blocker_passes");
	BuildPath(Path_SM, path, sizeof(path), "data/blocker_passes/%s.txt", s_MapName);
	FileToKeyValues(kv_list, path);
}

#if UseAdminMenu
	public Action:CommandAdminPasses(client, args)
	{
		if (b_game_m){
			DisplayTopMenu(h_menu, client, TopMenuPosition_LastCategory);
		}
		
		return Plugin_Handled;
	}
#endif

public Action:CommandGetPoss(client, args)
{
	decl Float:g_fOrigin[3];
	GetClientEyePosition(client, g_fOrigin);
	
	if(TR_DidHit(INVALID_HANDLE)){
		TR_GetEndPosition(g_fOrigin, INVALID_HANDLE);
		PrintToChat(client, "\x04[SM]\x04 Position: \x01%-.1f\x04; \x01%-.1f\x04; \x01%-.1f\x04.", g_fOrigin[0], g_fOrigin[1], g_fOrigin[2]);
	}
	
	return Plugin_Handled;
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == blocker_en){
		b_enabled = bool:StringToInt(newValue);
	}else if (convar == h_anonce){
		b_anonce = bool:StringToInt(newValue);
	}else if (convar == h_printchat){
		g_printchat = bool:StringToInt(newValue);
	}else if (convar == Block_min_player){
		i_min_players = StringToInt(newValue);
	}else if (convar == Block_accounting_teams){
		acc_teams = bool:StringToInt(newValue);
	}else if (convar == blocker_autosave){
		b_autosave = bool:StringToInt(newValue);	
	}
#if UseAdminMenu	
	else if (convar == blocker_game_m){
		b_game_m = bool:StringToInt(newValue);	
	}
#endif
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!b_enabled){
		return 0;
	}
	
	ClearArray(data_props);
	
	new clients = GetRealClientCount(acc_teams ? TEAM_TWO : TEAM_ALL);
	
	if (clients < i_min_players){
		
		g_bIsLocked = true;
		SpawnBlocks(GetRealClientCount(acc_teams ? TEAM_TWO : TEAM_ALL));
		
		if (!b_anonce){
			return 0;
		}
			
		if (acc_teams){
			switch(g_printchat){
				case 0:{
					PrintCenterTextAll("%t", "Blocked due to lack of CT"); 
				}
				case 1:{
					#if UseMoreColors
						CPrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "Blocked due to lack of CT");
					#else
						PrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "Blocked due to lack of CT");
					#endif
				}
			}
		}else{
			switch(g_printchat){
				case 0:{
					PrintCenterTextAll("%t", "Blocked due to lack of CT");
				}
				case 1:{
					#if UseMoreColors
						CPrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "Block Because of the user");
					#else
						PrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "Block Because of the user");
					#endif
				}
			}
		}
	}else{
		
		g_bIsLocked = false;
		
		if (!b_anonce){
			return 0;
		}
			
		switch(g_printchat){
			case 0:{
				PrintCenterTextAll("%t", "UnBlock B");
			}
			case 1:{
				#if UseMoreColors
					CPrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "UnBlock B");
				#else
					PrintToChatAll("\x05[SM Blocker Passes]\x01 %t", "UnBlock B");
				#endif
			}
		}
	}
	
	return 0;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_autosave){
		SaveAllProps(0);
	}
	
	return 0;
}

public OnEntityDestroyed(entity)
{
	new index = -1;
	
	if ((index = FindValueInArray(data_props, entity)) != -1){
		RemoveFromArray(data_props, index);
	}
}

#if UseAdminMenu
	public OnAdminMenuReady(Handle:topmenu)
	{
		if (h_menu == topmenu || !b_game_m){
			return;
		}
		
		h_menu = topmenu;
		
		new TopMenuObject:blocker_passes = FindTopMenuCategory(h_menu, "blocker_passes");
			
		if (blocker_passes == INVALID_TOPMENUOBJECT){
			blocker_passes = AddToTopMenu(h_menu, "blocker_passes", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT, "sm_blocker_passes", ADMIN_LEVEL);
		}
				
		AddToTopMenu(h_menu, "sm_bp_save", TopMenuObject_Item, blocker_passes_Save, blocker_passes, "sm_bp_save", ADMIN_LEVEL);
		AddToTopMenu(h_menu,"sm_bp_props", TopMenuObject_Item, blocker_passes_Props, blocker_passes, "sm_bp_props", ADMIN_LEVEL);
		AddToTopMenu(h_menu, "sm_bp_plsettings", TopMenuObject_Item, blocker_passes_Settings, blocker_passes, "sm_bp_plsettings", ADMIN_LEVEL);
	}

	public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
	{
		switch(action){
			case TopMenuAction_DisplayTitle:{
				Format(buffer, maxlength, "[EN] Blocker Passes");
			}
			case TopMenuAction_DisplayOption:{
				Format(buffer, maxlength, "[EN] Blocker Passes");
			}
		}
		
		return 0;
	}

	public blocker_passes_Settings(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
	{
		switch (action){
			case TopMenuAction_DisplayOption :{
				Format(buffer, maxlength, "Settings"); 
			}
			case TopMenuAction_SelectOption :{
				ShowSettingsMenu(param);
			}
		}
		
		return 0;
	}

	public blocker_passes_Props(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
	{
		switch (action){
			case TopMenuAction_DisplayOption :{
				Format(buffer, maxlength, "Main Menu");
			}
			case TopMenuAction_SelectOption :{
				DisplayMenu(h_hETitleMenu, param, MENU_TIME_FOREVER);
			}
		}
		
		return 0;
	}

	public blocker_passes_Save(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
	{
		switch (action){
			case TopMenuAction_DisplayOption :{
				Format(buffer, maxlength, "Save Props");
			}
			case TopMenuAction_SelectOption :{
				SaveAllProps(param);
			}
		}
		
		return 0;
	}

	void:ShowSettingsMenu(client)
	{
		decl String:buffer[64];
		
		new Handle:menu = CreateMenu(MenuSettingsHandler);
		SetMenuTitle(menu, "Settings");
		SetMenuExitBackButton(menu, true);
		
		Format(buffer, sizeof(buffer), "Plugin Enabled: %s", b_enabled ? "ON" : "OFF");
		AddMenuItem(menu, "Enable", buffer);
		
		Format(buffer, sizeof(buffer), "Accounting For All Players: %s", acc_teams ? "OFF" : "ON");
		AddMenuItem(menu, "Acc_Team", buffer);
		
		Format(buffer, sizeof(buffer), "Plugin Announce: %s", b_anonce ? "ON" : "OFF");
		AddMenuItem(menu, "Anonce", buffer);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);

	}

	public MenuSettingsHandler(Handle:menu, MenuAction:action, param1, param2)
	{
		switch (action){
			case MenuAction_End:{
				CloseHandle(menu);
			}
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					if (h_menu != INVALID_HANDLE)
						DisplayTopMenu(h_menu, param1, TopMenuPosition_LastCategory);
				}
			}
			case MenuAction_Select :{
			
				decl String:s_Type[32];
				GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
				
				if (StrEqual(s_Type, "Enable", false)){
					b_enabled = !b_enabled;
				}else if (StrEqual(s_Type, "Acc_Team", false)){
					acc_teams = !acc_teams;
				}else if (StrEqual(s_Type, "Anonce", false)){
					b_anonce = !b_anonce;
				}
				
				ShowSettingsMenu(param1);
			}
		}
		
		return 0;
	}

	public MenuPropMenuHandler(Handle:menu, MenuAction:action, param1, param2)
	{
		switch (action){
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					if (h_menu != INVALID_HANDLE)
						DisplayTopMenu(h_menu, param1, TopMenuPosition_LastCategory);
				}
			}
			case MenuAction_Select :{
			
				decl String:s_Type[32];
				GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
				
				if (StrEqual(s_Type, "PropsMenu", false)){
					DisplayMenu(h_PropsMenu, param1, MENU_TIME_FOREVER);
				}else if (StrEqual(s_Type, "ColorMenu", false)){
					DisplayMenu(h_ColorMenu, param1, MENU_TIME_FOREVER);
				}else if (StrEqual(s_Type, "QuotaMenu", false)){
					SDKHook(param1, SDKHookType:5, OnPostThink);
					DisplayMenu(h_QuotaMenu, param1, MENU_TIME_FOREVER);
				}else if (StrEqual(s_Type, "SaveProps", false)){
					SaveAllProps(param1);
				}else if (StrEqual(s_Type, "LockAll", false)){
					SpawnBlocks(0);
					g_bIsLocked = true;
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				}else if (StrEqual(s_Type, "UnLockAll", false)){
					new i, size;
					
					size = GetArraySize(data_props);
					
					while (i < size){
						DeleteProp(GetArrayCell(data_props, i));
						i++;
					}
					g_bIsLocked = false;
					
					DisplayMenu(menu, param1, MENU_TIME_FOREVER);
				}
				
			}
		}
		
		return 0;
	}

	public PropMenuHandler(Handle:menu, MenuAction:action, param1, param2)
	{
		switch (action){
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					DisplayMenu(h_hETitleMenu, param1, MENU_TIME_FOREVER);
				}
			}
			case MenuAction_Select :{
			
				decl String:info[64];
				GetMenuItem(menu, param2, info, sizeof(info));
				
				new ent = -1, index = -1, index2 = StringToInt(info);
				
				decl Float:g_fOrigin[3], Float:g_fAngles[3];
				
				GetClientEyePosition(param1, g_fOrigin);
				GetClientEyeAngles(param1, g_fAngles);
				TR_TraceRayFilter(g_fOrigin, g_fAngles, MASK_SOLID, RayType_Infinite, Trace_FilterPlayers, param1);
				
				if(TR_DidHit(INVALID_HANDLE)){
				
					TR_GetEndPosition(g_fOrigin, INVALID_HANDLE);
					TR_GetPlaneNormal(INVALID_HANDLE, g_fAngles);
					GetVectorAngles(g_fAngles, g_fAngles);
					g_fAngles[0] += 90.0;
					
					if (!strcmp(info, "rote")){
						DisplayMenu(h_RoteMenu, param1, MENU_TIME_FOREVER);
						return 0;
					}else if (!strcmp(info, "remove")){
						if ((ent = GetClientAimTarget(param1, false)) > MaxClients){
							if ((index = FindValueInArray(data_props, ent)) != -1){
								RemoveFromArray(data_props, index);
								DeleteProp(ent);
								PrintHintText(param1, "Prop removed!");
							}
						}else{
							PrintToChat(param1, "\x05[SM Blocker Passes]\x01 Invalid object!");
						}
					}else{
						CreateEntity(g_fOrigin, g_fAngles, g_sPropList[index2], i_min_players);
						PrintHintText(param1, "Props Successfully Installed!");
					}
					DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
				}
			}
		}
		
		return 0;
	}

	public PropRoteMenuHandle(Handle:menu, MenuAction:action, client, param2)
	{
		switch (action){
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					DisplayMenu(h_PropsMenu, client, MENU_TIME_FOREVER);
				}
			}
			case MenuAction_Select :{
			
				decl String:info[64];
				GetMenuItem(menu, param2, info, sizeof(info));
				
				decl Float:RotateVec[3];
				new entity = GetClientAimTarget2(client, false);
				
				if (entity > MaxClients){
				
					GetEntPropVector(entity, Prop_Send, "m_angRotation", RotateVec);
					
					if (StrEqual(info, "RotateX+45")){
						RotateVec[0] = RotateVec[0] + 45.0;
					}else if (StrEqual(info, "RotateX-45")){
						RotateVec[0] = RotateVec[0] - 45.0;
					}else if (StrEqual(info, "RotateY+45")){
						RotateVec[1] = RotateVec[1] + 45.0;
					}else if (StrEqual(info, "RotateY-45")){
						RotateVec[1] = RotateVec[1] - 45.0;
					}else if (StrEqual(info, "RotateZ+45")){
						RotateVec[2] = RotateVec[2] + 45.0;
					}else if (StrEqual(info, "RotateZ-45")){
						RotateVec[2] = RotateVec[2] - 45.0;
					}
					
					TeleportEntity(entity, NULL_VECTOR, RotateVec, NULL_VECTOR);	
				}
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
		}
		
		return 0;
	}

	public MenuPropColorHandler(Handle:menu, MenuAction:action, param1, param2)
	{
		switch (action){
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					if (h_menu != INVALID_HANDLE){
						DisplayMenu(h_hETitleMenu, param1, MENU_TIME_FOREVER);
					}
				}
			}
			case MenuAction_Select :{
			
				decl String:s_Type[10];
				GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
				
				new ent = -1;
				
				if ((ent = GetClientAimTarget(param1, false)) > MaxClients){
					if (!strcmp(s_Type, "color1")){
						SetEntityRenderColor(ent, 255, 0, 0, 255);
					}else if (!strcmp(s_Type, "color2")){
						SetEntityRenderColor(ent, 0, 255, 0, 255);
					}else if (!strcmp(s_Type, "color3")){
						SetEntityRenderColor(ent, 0, 0, 255, 255);
					}else if (!strcmp(s_Type, "color4")){
						SetEntityRenderColor(ent, 255, 255, 0, 255);
					}else if (!strcmp(s_Type, "color5")){
							SetEntityRenderColor(ent, 0, 255, 255, 255);
					}else if (!strcmp(s_Type, "color6")){
						SetEntityRenderColor(ent, 255, 0, 255, 255);
					}else if (!strcmp(s_Type, "color7")){
						SetEntityRenderColor(ent, 255, 255, 255, 50);
					}else if (!strcmp(s_Type, "color8")){
						SetEntityRenderColor(ent, 255, 255, 255, 0);
					}
				}
				
				DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		
		return 0;
	}
	
	public MenuPropQuotaHandler(Handle:menu, MenuAction:action, param1, param2)
	{
		switch (action){
			case MenuAction_Cancel :{
				if (param2 == MenuCancel_ExitBack){
					SDKUnhook(param1, SDKHookType:5, OnPostThink);
					DisplayMenu(h_hETitleMenu, param1, MENU_TIME_FOREVER);
				}
			}
			
			case MenuAction_Select :{
			
				decl String:s_Type[12];
				GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
				
				new ent = -1, Quota;
				if ((ent = GetClientAimTarget(param1, false)) > MaxClients){
				
					decl String:buffer[32];
					GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
					
					if (StrContains(buffer, "BpModelId", true) != -1){
						if (!StrEqual(s_Type, "++", false) && !StrEqual(s_Type, "--", false)){
							Quota = StringToInt(s_Type);
							Format(buffer, sizeof(buffer), "BpModelId%d_%d", ent, Quota);
							DispatchKeyValue(ent, "targetname", buffer);
						}
						else{
							
							decl String:outBuffer[2][8];
							ExplodeString(buffer, "_", outBuffer, 2, 16);
							
							if (StrEqual(s_Type, "++", false)){
								Quota = StringToInt(outBuffer[1]) + 1;
							}
							else if (StrEqual(s_Type, "--", false)){
								Quota = StringToInt(outBuffer[1]) - 1;
							}
							
							Format(buffer, sizeof(buffer), "BpModelId%d_%d", ent, Quota);
							DispatchKeyValue(ent, "targetname", buffer);
						}
					}
				}
				
				DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		
		return 0;
	}
#endif
	
void:SpawnBlocks(const clients)
{
	decl Float:pos[3], Float:ang[3], entity, color[4];
	decl String:buffer[16], String:Models[256], String:s_text[256], UnLockNum;
	
	if (KvGotoFirstSubKey(kv_list)){
		do{
			KvGetVector(kv_list, "Position", pos);
			KvGetVector(kv_list, "Angles", ang);
			KvGetString(kv_list, "Model", Models, sizeof(Models));
			KvGetString(kv_list, "Text", s_text, sizeof(s_text));
			KvGetString(kv_list, "Colors", buffer, sizeof(buffer));
			
			UnLockNum = KvGetNum(kv_list, "UnLockNum", i_min_players);
			
			StringToColor(buffer, color);
			
			if (UnLockNum > clients){
				if (strlen(s_text) > 2){
					ReplaceString(s_text, sizeof(s_text), "{default}", "\x01", false);
					ReplaceString(s_text, sizeof(s_text), "{teamcolor}", "\x02", false);
					ReplaceString(s_text, sizeof(s_text), "{lightgreen}", "\x03", false);
					ReplaceString(s_text, sizeof(s_text), "{green}", "\x04", false);
					ReplaceString(s_text, sizeof(s_text), "{darkgreen}", "\x05", false);
					
					#if UseMoreColors
						CPrintToChatAll(s_text);
					#else
						PrintToChatAll(s_text);
					#endif
				}
				
				if ((entity = CreateEntity(pos, ang, Models, UnLockNum)) != -1){
					SetEntityColor(entity, color);
				}
			}
		} while (KvGotoNextKey(kv_list));
	}
	
	KvRewind(kv_list);
}

CreateEntity(const Float:pos[3], const Float:ang[3], const String:g_szModel[], const iMinPlayer)
{
	new entity = CreateEntityByName("prop_dynamic_override");
	
	if (entity == -1){
		return -1;
	}
	
	if (!IsModelPrecached(g_szModel)){
		PrecacheModel(g_szModel);
	}
	
	decl String:buffer[32];
	Format(buffer, sizeof(buffer), "BpModelId%d_%d", entity, iMinPlayer);
	
	SetEntityModel(entity, g_szModel);
	DispatchKeyValue(entity, "targetname", buffer);
	DispatchKeyValue(entity, "Solid", "6");
	DispatchSpawn(entity);
	
	TeleportEntity(entity, pos, ang, NULL_VECTOR);
	
	PushArrayCell(data_props, entity);
	
	return entity;
}

public bool:Trace_FilterPlayers(entity, contentsMask, any:data)
{
	if(entity != data && entity > MaxClients){
		return true;
	}
	return false;
}

public bool:TRFilter_AimTarget(entity, mask, any:client)
{
    return (entity != client);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client)
{
	return ((entity > MaxClients) || !entity);
}

GetRealClientCount(const team)
{
	new clients = 0;
	
	for (new i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && IsPlayerAlive(i)){
			if (team > TEAM_ALL) {
				if (GetClientTeam(i) == team){
					clients++;
				}else{
					continue;
				}
			}else{
				clients++;
			}
		}
	}
	
	return clients;
}

void:Kv_Clear(Handle:kvhandle)
{
	KvRewind(kvhandle);
	
	if (KvGotoFirstSubKey(kvhandle)){
		do{
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		}
		while (KvGotoFirstSubKey(kvhandle));
	}
	KvRewind(kvhandle);
	
	return;
}

void:SaveAllProps(client)
{
	Kv_Clear(kv_list);
	
	new index = 1;
	new String:buffer_modelsname[PLATFORM_MAX_PATH], String:buffer_2[64], String:colors[16], color[4], Float:pos[3], Float:ang[3], ent;
			
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/blocker_passes/%s.txt", s_MapName);
		
	for (new i = 0; i < GetArraySize(data_props); i++){
		
		ent = GetArrayCell(data_props, i);
		
		if (ent > MaxClients && IsValidEdict(ent)){
			
			GetEntPropString(ent, Prop_Data, "m_ModelName", buffer_modelsname, sizeof(buffer_modelsname));
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
			GetEntityRenderColor2(ent, color);
			ColorToString(color, colors, sizeof(colors));
			
			IntToString(index, buffer_2, sizeof(buffer_2));
			KvJumpToKey(kv_list, buffer_2, true);
			
			KvSetVector(kv_list, "Position", pos);
			KvSetVector(kv_list, "Angles", ang);
			KvSetString(kv_list, "Model", buffer_modelsname);
			KvSetString(kv_list, "colors", colors);
			KvSetString(kv_list, "Text", "");
			
			#if UseAdminMenu
				decl String:buffer[32], String:outBuffer[2][8];
				GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
				ExplodeString(buffer, "_", outBuffer, 2, 16, false);
				KvSetNum(kv_list, "UnLockNum", StringToInt(outBuffer[1]));
			#else
				KvSetNum(kv_list, "UnLockNum", i_min_players);
			#endif	
			
			KvRewind(kv_list);
			
			index++;
		}
	}
	
	KeyValuesToFile(kv_list, path);
	
	if (client == 0){
		return;
	}
	PrintHintText(client, "Positions\nSuccessfully saved.\nTotal %d Props!", index - 1);
	
	#if UseAdminMenu
		DisplayTopMenu(h_menu, client, TopMenuPosition_LastCategory);
	#endif
	
	return;
}
#if UseAdminMenu
	void:DeleteProp(entity)
	{
		decl String:dname[16];
		Format(dname, sizeof(dname), "dis_%d", entity);
		DispatchKeyValue(entity, "targetname", dname);
		new diss = CreateEntityByName("env_entity_dissolver");
		DispatchKeyValue(diss, "dissolvetype", "3");
		DispatchKeyValue(diss, "target", dname);
		AcceptEntityInput(diss, "Dissolve");
		AcceptEntityInput(diss, "kill");
		
		return;
	}
	
	void:LoadPropsMenu()
	{
		h_PropsMenu = CreateMenu(PropMenuHandler);
		SetMenuTitle(h_PropsMenu, "| Props Menu |");
		SetMenuExitButton(h_PropsMenu, true);
		SetMenuExitBackButton(h_PropsMenu, true);
		
		decl String:file[255];
		new Handle:kv = CreateKeyValues("Props");
		BuildPath(Path_SM, file, sizeof(file), "data/blocker_passes/props_menu.txt");
		FileToKeyValues(kv, file);
		new menu_items = 0;
		new reqmenuitems = 4;
		
		if (KvGotoFirstSubKey(kv)){
			new index = 0;
			decl String:buffer[255];
			decl String:bufferindex[5];
			do{
				KvGetString(kv, "model", g_sPropList[index], 256);
				
				PrecacheModel(g_sPropList[index]);
				
				KvGetSectionName(kv, buffer, sizeof(buffer));
				IntToString(index, bufferindex, sizeof(bufferindex));
				AddMenuItem(h_PropsMenu, bufferindex, buffer);
				index++;
				menu_items++;
				if (menu_items == reqmenuitems)
				{
					menu_items = 0;
					AddMenuItem(h_PropsMenu, "", 	"", ITEMDRAW_SPACER);
					AddMenuItem(h_PropsMenu, "rote", 	"[Rotate Prop]");
					AddMenuItem(h_PropsMenu, "remove", 	"[Remove Prop]");
				}
			}
			while (KvGotoNextKey(kv));
		}
		CloseHandle(kv);
		
		return;
	}
#endif