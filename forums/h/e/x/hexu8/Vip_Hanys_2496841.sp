#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <colors>
#include <loghelper>
#include <sdkhooks>

#pragma semicolon 1

#define MAX_WEAPON_COUNT 32
#define SHOW_MENU -1
#define CS_TEAM_SPECTATOR	1
#define CS_TEAM_T 			2
#define CS_TEAM_CT			3

public Plugin:myinfo =
{
	name = "VIP Plugin by Hanys",
	author = "Hanys",
	description = "vip plugin by Hanys",
	version = "1.3.1",
	url = "http://hanys.dispark.pl"
};

new Handle:HP;
new Handle:Gravity;
new Handle:Speedy;
new Handle:Smokegrenade;
new Handle:Flashbang;
new Handle:Hegrenade;
new Handle:Molotov;
new Handle:Decoy;
new Handle:Tagrenade;
new Handle:Healthshot;
new Handle:Remove_grenade;
new Handle:Armorvalue;
new Handle:Bhashelmet;
new Handle:Defuser;
new Handle:Moneystart;
new Handle:Bombplanted;
new Handle:Bombdefused;
new Handle:Headshot_money;
new Handle:Headshot_hp;
new Handle:Kill_money;
new Handle:Kill_hp;
new Handle:Tagtable;
new Handle:Tagsay;
new Handle:Double_jump;
new Handle:Advertising;
new Handle:Menu_round;
new Handle:Menu_command;
new Handle:Menu_onspawn;

new g_PrimaryGunCount;
new g_SecondaryGunCount;
new String:g_PrimaryGuns[MAX_WEAPON_COUNT][32];
new String:g_SecondaryGuns[MAX_WEAPON_COUNT][32];
new bool:g_MenuOpen[MAXPLAYERS+1] = {false, ...};
new Handle:g_PrimaryMenu = INVALID_HANDLE;
new Handle:g_SecondaryMenu = INVALID_HANDLE;
new g_PlayerPrimary[MAXPLAYERS+1] = {-1, ...};
new g_PlayerSecondary[MAXPLAYERS+1] = {-1, ...};
new Rounds = 0;
new const g_iaGrenadeOffsets[] = {15, 17, 16, 14, 18, 17};

public OnPluginStart()
{
	CreateConVar("sm_vip_version", "1.3.2", "VIP Plugin by Hanys", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HP = CreateConVar("vip_hp_start", "100", "Ilosc HP na start rundy", FCVAR_NOTIFY);
	Gravity = CreateConVar("vip_gravity", "1.0", "Grawitacja (1.0 - standardowa)", FCVAR_PLUGIN);
	Speedy = CreateConVar("vip_speed", "1.0", "Szybkosc biegania (1.0 - standardowo)", FCVAR_PLUGIN);
	Smokegrenade = CreateConVar("vip_grenade_smokegrenade", "0", "Smoke na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Flashbang = CreateConVar("vip_grenade_flashbang", "0", "Flash na start rundy (0-2))", FCVAR_NOTIFY);
	Hegrenade = CreateConVar("vip_grenade_hegrenade", "0", "Granat na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Molotov = CreateConVar("vip_grenade_molotov", "0", "Molotov dla tt lub Incendiary dla ct na start rundy",FCVAR_NONE, true, 0.0, true, 1.0);
	Decoy = CreateConVar("vip_grenade_decoy", "0", "Decoy na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Tagrenade = CreateConVar("vip_grenade_tagrenade", "0", "Granat taktyczny na start rundy",FCVAR_NONE, true, 0.0, true, 1.0);
	Healthshot = CreateConVar("vip_grenade_healtshot", "0", "Apteczka na start rundy (0-4)", FCVAR_NOTIFY);
	Remove_grenade = CreateConVar("vip_grenade_remove", "0", "Na pocz¹tku rundy/respawn usuwa wszystkie granaty (Przydatne przy wypadaniu granatów", FCVAR_NONE, true, 0.0, true, 1.0);
	Armorvalue = CreateConVar("vip_armorvalue", "0", "Kamizelka na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Bhashelmet = CreateConVar("vip_bhashelmet", "0", "Kask na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Defuser = CreateConVar("vip_defuser", "0", "Zestaw do rozbrajania dla CT na start rundy", FCVAR_NONE, true, 0.0, true, 1.0);
	Moneystart = CreateConVar("vip_money_start", "0", "Ilosc $ na start rundy", FCVAR_NOTIFY);
	Bombplanted = CreateConVar("vip_bomb_planted", "0", "Ilosc $ za podlozenie bomby", FCVAR_NOTIFY);
	Bombdefused = CreateConVar("vip_bomb_defused", "0", "Ilosc $ za rozbrojenie bomby", FCVAR_NOTIFY);
	Headshot_money = CreateConVar("vip_headshot_money", "0", "Ilosc $ za Headshot", FCVAR_NOTIFY);
	Headshot_hp = CreateConVar("vip_headshot_hp", "0", "Ilosc HP za Headshot", FCVAR_NOTIFY);
	Kill_money = CreateConVar("vip_kill_money", "0", "Ilosc $ za fraga", FCVAR_NOTIFY);
	Kill_hp = CreateConVar("vip_kill_hp", "0", "Ilosc HP za fraga", FCVAR_NOTIFY);
	Tagtable = CreateConVar("vip_tag_table", "0", "Tag VIP w tabeli wynikow", FCVAR_NONE, true, 0.0, true, 1.0);
	Tagsay = CreateConVar("vip_tag_say", "0", "Tag VIP + kolorowy nick w say", FCVAR_NONE, true, 0.0, true, 1.0);
	Double_jump = CreateConVar("vip_double_jump", "0", "Podwojny skok", FCVAR_NONE, true, 0.0, true, 1.0);
	Advertising = CreateConVar("vip_advertising", "1", "Informacja o autorze pluginu", FCVAR_NONE, true, 0.0, true, 1.0);
	Menu_round = CreateConVar("vip_menu", "0", "Od ktorej rundy menu broni jest aktywne (0-menu broni nieaktywne)", FCVAR_NOTIFY);
	Menu_command = CreateConVar("vip_menu_command", "0", "Otwieranie menu broni po wpisaniu !bronie/!menu", FCVAR_NONE, true, 0.0, true, 1.0);
	Menu_onspawn = CreateConVar("vip_menu_onspawn", "0", "Wyswietlanie menu przy respawn (Start rundy)", FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig(true, "vip_hanys");
	CheckConfig("configs/vip_hanys_weapons.ini");
	
	RegConsoleCmd("say", Command_SendToAll);
	//RegConsoleCmd("say_team", Command_SendToTeam);
	RegConsoleCmd("sm_menu", Command_VipMenu);
	RegConsoleCmd("sm_bronie", Command_VipMenu);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("player_death",  Event_PlayerDeath);
	HookEvent("player_team", Event_TagTable);
	HookEvent("player_spawn", Event_TagTable);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("announce_phase_end", RestartRound);
	HookEvent("cs_intermission", RestartRound);
	
	CreateTimer(300.0, Timer_Advert, _, TIMER_REPEAT);
}

public OnPluginEnd()
{
	CancelMenu(g_PrimaryMenu);
	CheckCloseHandle(g_PrimaryMenu);
	CancelMenu(g_SecondaryMenu);
	CheckCloseHandle(g_SecondaryMenu);
}


public Action:Timer_Advert(Handle:timer)
{
	if (GetConVarBool(Advertising))
	{
	PrintToChatAll("\x01[\x04VIP\x01]\x04 Plugin VIP by Hanys");
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new money = GetEntProp(client, Prop_Send, "m_iAccount");
	new team = GetClientTeam(client);
	new g_HP = GetConVarInt(HP);
	new g_moneystart = GetConVarInt(Moneystart);
	new g_Flashbang = GetConVarInt(Flashbang);
	new g_Healthshot = GetConVarInt(Healthshot);
	
	if (client > 0 && IsPlayerAlive(client))
	{
		if (GetConVarBool(Remove_grenade)) StripNades(client);
		if (IsPlayerGenericAdmin(client))

		{
			SetEntityHealth(client, g_HP); //hp
			SetEntityGravity(client, GetConVarFloat(Gravity)); //grawitacja
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(Speedy)); //predkosc biegania
			if (GetConVarBool(Smokegrenade)) GivePlayerItem(client, "weapon_smokegrenade"); //smoke
			if (GetConVarBool(Flashbang))
			{
				for (new i = 1; i <= g_Flashbang; i++)
				GivePlayerItem(client, "weapon_flashbang");
			}
			if (GetConVarBool(Healthshot))
			{
				for (new i = 1; i <= g_Healthshot; i++)
				GivePlayerItem(client, "weapon_healthshot");
			}
			if (GetConVarBool(Hegrenade)) GivePlayerItem(client, "weapon_hegrenade"); //grenade
			if (GetConVarBool(Molotov) && team == CS_TEAM_T) GivePlayerItem(client, "weapon_molotov"); //molotov tt
			if (GetConVarBool(Molotov) && team == CS_TEAM_CT) GivePlayerItem(client, "weapon_incgrenade"); //Incendiary ct
			if (GetConVarBool(Decoy)) GivePlayerItem(client, "weapon_decoy"); //decoy
			if (GetConVarBool(Tagrenade)) GivePlayerItem(client, "weapon_tagrenade"); //Taktyczny
			SetEntProp(client, Prop_Send, "m_iAccount", money + g_moneystart); // plus $ na start
			if (GetConVarBool(Armorvalue)) SetEntProp(client, Prop_Send, "m_ArmorValue", 100); //kamizelka
			if (GetConVarBool(Bhashelmet)) SetEntProp(client, Prop_Send, "m_bHasHelmet", 1); //helm
			
			if(team == CS_TEAM_CT)
			{
				if (GetConVarBool(Defuser) && GetEntProp(client, Prop_Send, "m_bHasDefuser") == 0) GivePlayerItem(client, "item_defuser"); //kombinerki
	
			}
			CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
		}
	
	}
}
 
stock StripNades(client)
{
    while(RemoveWeaponBySlot(client, 3)){}
    for(new i = 0; i < 6; i++)
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}
stock bool:RemoveWeaponBySlot(client, iSlot)
{
    new iEntity = GetPlayerWeaponSlot(client, iSlot);
    if(IsValidEdict(iEntity)) {
        RemovePlayerItem(client, iEntity);
        AcceptEntityInput(iEntity, "Kill");
        return true;
    }
    return false;
} 

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new money = GetEntProp(client, Prop_Send, "m_iAccount");
	new g_bombplanted = GetConVarInt(Bombplanted);
	
	if (IsPlayerGenericAdmin(client))
	
	
	{
		SetEntProp(client, Prop_Send, "m_iAccount", money + g_bombplanted);//plus $ for Bomb Planted
		
		
	}
}

public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new money = GetEntProp(client, Prop_Send, "m_iAccount");
	new g_bombdefused = GetConVarInt(Bombdefused);
	
	if (IsPlayerGenericAdmin(client))
	
	
	{
		SetEntProp(client, Prop_Send, "m_iAccount", money + g_bombdefused); //plus $ for Bomb Defused
		
		
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new money = GetEntProp(attacker, Prop_Send, "m_iAccount");
	new health = GetEntProp(attacker, Prop_Send, "m_iHealth");
	new g_headshot_money = GetConVarInt(Headshot_money);
	new g_headshot_hp = GetConVarInt(Headshot_hp);
	new g_kill_money = GetConVarInt(Kill_money);
	new g_kill_hp = GetConVarInt(Kill_hp);
	
	new bool:headshot = GetEventBool(event, "headshot");
	if (IsPlayerGenericAdmin(attacker))
	
	
	{
		if(headshot)
		
		{
			SetEntProp(attacker, Prop_Send, "m_iAccount", money + g_headshot_money); //plus for hs
			SetEntProp(attacker, Prop_Send, "m_iHealth", health + g_headshot_hp); //plus hp for hs
			
			
		}
		else
		
		{
			SetEntProp(attacker, Prop_Send, "m_iAccount", money + g_kill_money); //plus for kill
			SetEntProp(attacker, Prop_Send, "m_iHealth", health + g_kill_hp); //plus hp for kill
			
			
		}
		
		
	}
}

public Action:Event_TagTable(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerGenericAdmin(client))
	
	
	{
		if (GetConVarBool(Tagtable)) CS_SetClientClanTag(client, "[VIP]");
		
		
	}
}

public Action:Command_SendToAll(client, args)
{
    if ((IsPlayerGenericAdmin(client)) && GetConVarBool(Tagsay))
    {
        new String:text[256];
        GetCmdArg(1, text, sizeof(text));
        
        if (text[0] == '/' || text[0] == '@' || text[0] == '!' || text[0] == 0 || IsChatTrigger())
        {
            return Plugin_Handled;
        }
        if(IsPlayerAlive(client) && GetClientTeam(client) != 1)
		{
        PrintToChatAll("\x01[\x04VIP\x01]\x05 %N: \x01%s", client, text);
		}
		else if(!IsPlayerAlive(client) && GetClientTeam(client) != 1)
		{
        PrintToChatAll("\x01*NIE ZYJE* [\x04VIP\x01]\x05 %N: \x01%s", client, text);
		}
		else if(!IsPlayerAlive(client) && GetClientTeam(client) == 1)
		{
        PrintToChatAll("\x01*OBSERWATOR* [\x04VIP\x01]\x05 %N: \x01%s", client, text);
		}
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Command_SendToTeam(client, args)
{
    if ((IsPlayerGenericAdmin(client)) && GetConVarBool(Tagsay))
    {
        new String:text[256];
        GetCmdArg(1, text, sizeof(text));
        
        if (text[0] == '/' || text[0] == '@' || text[0] == '!' || text[0] == 0 || IsChatTrigger())
        {
            return Plugin_Handled;
        }
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsClientConnected(i))
            {
                if (GetClientTeam(client) == GetClientTeam(i))
                {
                    if(GetClientTeam(client) == 2)
					{
						if(IsPlayerAlive(client))
						{
							PrintToChat(i, "\x01(Terrorysta) [\x04VIP\x01]\x05 %N \x01%s", client, text);
						}
						else if(!IsPlayerAlive(client))
						{
							PrintToChat(i, "\x01*NIE ZYJE*(Terrorysta) [\x04VIP\x01]\x05 %N \x01%s", client, text);
						}
						return Plugin_Handled;
					}
					else if(GetClientTeam(client) == 3)
					{
						if(IsPlayerAlive(client))
						{
						PrintToChat(i, "\x01(Antyterrorysta) [\x04VIP\x01]\x05 %N \x01%s", client, text);
						}
						else if(!IsPlayerAlive(client))
						{
						PrintToChat(i, "\x01*NIE ZYJE*(Antyterrorysta) [\x04VIP\x01]\x05 %N \x01%s", client, text);
						}
						return Plugin_Handled;
					}
					else if(GetClientTeam(client) == 1)
					{
						PrintToChat(i, "\x01[OBSERWATOR] [\x04VIP\x01]\x05 %N \x01%s", client, text);
						return Plugin_Handled;
					}
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((IsPlayerGenericAdmin(iClient)) && IsPlayerAlive(iClient) && GetConVarBool(Double_jump))
	
	
	{
		static g_fLastButtons[MAXPLAYERS+1], g_fLastFlags[MAXPLAYERS+1], g_iJumps[MAXPLAYERS+1], fCurFlags, fCurButtons;
		fCurFlags = GetEntityFlags(iClient);
		fCurButtons = GetClientButtons(iClient);
		if (g_fLastFlags[iClient] & FL_ONGROUND && !(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[iClient] & IN_JUMP) && fCurButtons & IN_JUMP) g_iJumps[iClient]++;
		else if(fCurFlags & FL_ONGROUND) g_iJumps[iClient] = 0;
		else if(!(g_fLastButtons[iClient] & IN_JUMP) && fCurButtons & IN_JUMP && g_iJumps[iClient] == 1)
		
		
		{
			g_iJumps[iClient]++;
			decl Float:vVel[3];
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vVel);
			vVel[2] = 250.0;
			TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vVel);
			
			
		}
		
		g_fLastFlags[iClient] = fCurFlags;
		g_fLastButtons[iClient] = fCurButtons;
		
		
	}
	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Rounds = Rounds + 1;
}

public Action:RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	Rounds = 0;
}

public OnClientPutInServer(client)
{
	g_MenuOpen[client]=false;

	g_PlayerPrimary[client] = SHOW_MENU;
	g_PlayerSecondary[client] = SHOW_MENU;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if (g_MenuOpen[client] && team == CS_TEAM_SPECTATOR)
	{
		CancelClientMenu(client);		// Delayed
		g_MenuOpen[client] = false;
	}
}

stock CheckConfig(const String:ini_file[])
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), ini_file);

	new timestamp = GetFileTime(file, FileTime_LastChange);

	if (timestamp == -1) SetFailState("\nCould not stat config file: %s.", file);

	InitializeMenus();
	if (ParseConfigFile(file))
	{
		FinalizeMenus();
	}
	
}

stock InitializeMenus()
{
	g_PrimaryGunCount=0;
	CheckCloseHandle(g_PrimaryMenu);
	g_PrimaryMenu = CreateMenu(MenuHandler_ChoosePrimary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_PrimaryMenu, "[VIP] Wybierz darmowa bron:");

	g_SecondaryGunCount=0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_SecondaryMenu, "[VIP] Wybierz darmowa bron:");
}

stock FinalizeMenus()
{
	AddMenuItem(g_PrimaryMenu, "FF", "None");
	AddMenuItem(g_SecondaryMenu, "FF", "None");
}

bool:ParseConfigFile(const String:file[]) {

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

new g_configLevel;
public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	g_configLevel++;
	if (g_configLevel==2)
	{
		if (StrEqual("PrimaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);
		else if (StrEqual("SecondaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);
	}
	else SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public SMCResult:Config_UnknownKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	SetFailState("\nDidn't recognize configuration: Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes) {
	if (g_PrimaryGunCount>=MAX_WEAPON_COUNT) SetFailState("\nToo many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_PrimaryGuns[g_PrimaryGunCount], sizeof(g_PrimaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_PrimaryGunCount++);
	AddMenuItem(g_PrimaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if (g_SecondaryGunCount>=MAX_WEAPON_COUNT) SetFailState("\nToo many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_SecondaryGuns[g_SecondaryGunCount], sizeof(g_SecondaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_SecondaryGunCount++);
	AddMenuItem(g_SecondaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser)
{
	g_configLevel--;
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed)
{
	if (failed) SetFailState("\nPlugin error");
}

public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Display) g_MenuOpen[param1] = true;
	else if (action == MenuAction_Select)
	{
		new client = param1;
		new team = GetClientTeam(client);
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon = StringToInt(weapon_id, 16);

		g_PlayerPrimary[client] = weapon;
		if (team > CS_TEAM_SPECTATOR) GivePrimary(client);

		DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		g_MenuOpen[param1] = false;
		if (param2 == MenuCancel_Exit)	// CancelClientMenu sends MenuCancel_Interrupted reason
		{
			if (g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Display) g_MenuOpen[param1] = true;
	else if (action == MenuAction_Select)
	{
		new client = param1;
		new team = GetClientTeam(client);
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon = StringToInt(weapon_id, 16);

		g_PlayerSecondary[client] = weapon;
		if (team > CS_TEAM_SPECTATOR) GiveSecondary(client);
	}
	else if (action == MenuAction_Cancel) g_MenuOpen[param1] = false;
}

public Action:Event_HandleSpawn(Handle:timer, any:user)
{
	new client = GetClientOfUserId(user);
	new g_menu_round = GetConVarInt(Menu_round);
	if (!client) return;

	if (GetConVarBool(Menu_onspawn) && Rounds >= g_menu_round > 0 )
	{
		if (g_PlayerPrimary[client]==SHOW_MENU && g_PlayerSecondary[client]==SHOW_MENU)
		{
			if (g_PrimaryMenu != INVALID_HANDLE) DisplayMenu(g_PrimaryMenu, client, MENU_TIME_FOREVER);
			else if (g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			GivePrimary(client);
			GiveSecondary(client);
		}
	}
}

stock GivePrimary(client)
{
	new weapon = g_PlayerPrimary[client];
	RemoveWeaponBySlot(client, 0);
	if (weapon >= 0 && weapon < g_PrimaryGunCount) GivePlayerItem(client, g_PrimaryGuns[weapon]);
}

stock GiveSecondary(client)
{
	new weapon = g_PlayerSecondary[client];
	RemoveWeaponBySlot(client, 1);
	if (weapon >= 0 && weapon < g_SecondaryGunCount) GivePlayerItem(client, g_SecondaryGuns[weapon]);
}

public Action:Command_VipMenu(client, args)
{
	new g_menu_round = GetConVarInt(Menu_round);
	if (IsPlayerGenericAdmin(client))
	{
		if (IsClientInGame(client) && Rounds >= g_menu_round > 0 && GetConVarBool(Menu_command))
		{
			if (g_PrimaryMenu != INVALID_HANDLE) DisplayMenu(g_PrimaryMenu, client, MENU_TIME_FOREVER);
			else if (g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
		}
	}
	return Plugin_Continue;
}

stock CheckCloseHandle(&Handle:handle)
{
	if (handle != INVALID_HANDLE)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}


stock min(a, b) {return (a<b) ? a:b;}
stock max(a, b) {return (a>b) ? a:b;}

/*
@param client id

return bool
*/
bool:IsPlayerGenericAdmin(client)
{
	if (!CheckCommandAccess(client, "sm_vip", 0, true)) return false;	
	{
		return true;

	}
}