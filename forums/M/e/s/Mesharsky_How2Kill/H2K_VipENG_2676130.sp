/*	Copyright (C) 2019 Mesharsky
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

/*================ Updates ================

~ Version "0.1" >> First release.
~ Version "0.2" >> New Syntax Rewrite.
~ Version "0.3" >> Fixed events.
~ Version "0.4" >> Added cvars.
~ Version "0.5" >> More Cvars + More fixes.
~ Version "0.6" >> Fixed an error when the gun menu was showing on the 1st round (HalfTime).
~ Version "0.7" >> Fixed RoundEnd Events.
~ Version "0.8" >> Added welcome and leave message for vip. // USUNIĘTE
~ Version "0.9" >> Added [VIP] tag in the cvar.
~ Version "1.0" >> Added cvar for doublejump.
~ Version "1.1" >> Added new cvars and fixed doublejump.
~ Version "1.2" >> Grenades are not respawning 2 times at the new round.
~ Version "1.3" >> Removed useless free vip from x to x hour.
~ Version "1.4" >> A lot of new features and fixes.
~ Version "1.5" >> Fixes
~ Version "1.6" >> Removed useless translations and added English language for allied lads..
~ Version "1.7" >> Fix error  [SM] Exception reported: Client 1 is not connected :).

TODO:

~ KeyValue guns menu (I am very lazy so i don't know when i will do that :))

==============================================

//AHH LOVE
http://images6.fanpop.com/image/photos/36600000/Rias-Gremory-image-rias-gremory-36601369-1920-1080.png

*/

/* << Includy >> */
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/* << Define >> */
#define PLUGIN_NAME "[CSGO] Advanced VIP System for CSGO Servers"
#define PLUGIN_DESCRIPTION "[CSGO] Avanced VIP System for CSGO Servers"
#define PLUGIN_AUTHOR "Mesharsky"
#define PLUGIN_VERSION "1.7"

#define VIP_PREFIX " ★ \x02[VIP]\x04"

/* << Pragma >> */
#pragma newdecls required
#pragma semicolon 1

/* << Macro >> */
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\if(IsClientInGame(%1))
	
/* << ConVary >> */
ConVar g_cvVipFlag;
ConVar g_Cvar_Kevlar_Helmet_1_round;
ConVar g_CvarChatMessages;
ConVar g_CvarVipsOnline;
ConVar g_CvarVipWelcome;
ConVar g_CvarVipLeave;
ConVar g_CvarVipHudMessages;
ConVar g_CvarVipHP;
ConVar g_CvarMaxHP;
ConVar g_CvarVipHeadShotHP;
ConVar g_CvarVipKillHP;
ConVar g_CvarVipMovmentSpeed;
ConVar g_CvarVipGravity;
ConVar g_CvarVipArmor;
ConVar g_CvarVipHelmet;
ConVar g_CvarGrenadesRound;
ConVar g_CvarHEGranat;
ConVar g_CvarFlashGranat;
ConVar g_CvarSmokeGranat;
ConVar g_CvarDecoyGranat;
ConVar g_CvarHealGranat;
ConVar g_CvarIncGranat;
ConVar g_CvarMolotovGranat;
ConVar g_CvarTaGranat;
ConVar g_CvarVipStartMoney;
ConVar g_CvarVipBombPlantedMoney;
ConVar g_CvarVipBombDefusedMoney;
ConVar g_CvarVipHeadShotMoney;
ConVar g_CvarVipKillMoney;
ConVar g_CvarVipKillKnifeMoney;
ConVar g_CvarVipRoundWinMoney;
ConVar g_CvarTagTabela;
ConVar g_CvarVipTagTabela;
ConVar g_CvarDoubleJump;
ConVar g_CvarPistolMenu;
ConVar g_CvarRundaPistolMenu;

/* << Inty >> */
int RoundCount = 0;
int g_iaGrenadeOffsets[] =  { 15, 17, 16, 14, 18, 17 };

/* << Boole >> */
bool g_bHudMessage[MAXPLAYERS + 1];


/* << Information about plugin >> */
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "http://steamcommunity.com/id/MesharskyH2K"
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_TagTable);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("announce_phase_end", ResetAfterTeamChange);
	HookEvent("cs_intermission", ResetAfterTeamChange);
	
	RegConsoleCmd("sm_vips", ShowOnlineVips);
	RegConsoleCmd("sm_vipy", ShowOnlineVips);
	RegConsoleCmd("sm_vipsay", Hud_Command);
	
	/* << ConVary >> */
	g_cvVipFlag = CreateConVar("vip_flag", "o", "Required flag for the Vip player (Leave empty so all the players will have VIP).");
	
	g_CvarChatMessages = CreateConVar("vip_wiadomosci_chat", "1", "Do you want to show various messages on the chat, eg for killing?");
	g_Cvar_Kevlar_Helmet_1_round = CreateConVar("vip_disable_armor_and_helmet", "0", "Should we disable helmet and kevlar in the first round?");
	g_CvarVipsOnline = CreateConVar("vip_vipy_online", "1", "Do you want to turn on the VIPS ONLINE function?");
	g_CvarVipWelcome = CreateConVar("vip_przywitanie", "1", "Do you want to turn on the VIP WELCOME function?");
	g_CvarVipLeave = CreateConVar("vip_pozegnanie", "1", "Do you want to turn on the VIP FAREWELL function?");
	g_CvarVipHudMessages = CreateConVar("vip_hud_message", "1", "Do you allow the VIP to write in HUD?");
	g_CvarVipHP = CreateConVar("zycie_vip", "105", "How much health does vip should have for the start of the round?");
	g_CvarMaxHP = CreateConVar("zycie_max_vip", "130", "What is the maximum amount of health that the vip player can achieve?");
	g_CvarVipKillHP = CreateConVar("kill_hp_vip", "5", "How much health the VIP player should get for each kill?");
	g_CvarVipHeadShotHP = CreateConVar("hs_hp_vip", "10", "How much health should the VIP player get for the headshot?");
	g_CvarVipMovmentSpeed = CreateConVar("vip_predkosc_ruchu", "1.0", "Movement speed for the VIP player (1.0 - standard)");
	g_CvarVipGravity = CreateConVar("vip_grawitacja", "1.0", "Gravity for the VIP player (1.0- standard)");
	g_CvarVipArmor = CreateConVar("armor_vip", "100", "Vest points for the VIP player? (From 1 to 100)");
	g_CvarVipHelmet = CreateConVar("helm_vip", "1", "Is the VIP player supposed to  have a free helmet? (0/1)");
	g_CvarVipStartMoney = CreateConVar("vip_dodatkowe_Pieniadze", "0", "What is the amount of additional money for the start of a round that the VIP should get?");
	g_CvarVipKillMoney = CreateConVar("pieniadze_kill_vip", "200", "How much money should the VIP player get for the homicide?");
	g_CvarVipKillKnifeMoney = CreateConVar("pieniadze_kill_knife_vip", "200", "How much money the VIP player should get for killing by the knife?");
	g_CvarVipHeadShotMoney = CreateConVar("pieniadze_hs_vip", "500", "How much money should the VIP player get for the headshot?");
	g_CvarVipBombPlantedMoney = CreateConVar("pieniadze_podlozenie_vip", "1000", "How much money should the VIP player get for planting the bomb?");
	g_CvarVipBombDefusedMoney = CreateConVar("pieniadze_rozbrojenie_vip", "1000", "How much money should the VIP player get for defusing the bomb?");
	g_CvarVipRoundWinMoney = CreateConVar("pieniadze_wygranie_rundy", "500", "How much money should the VIP player get for winning the round?");
	g_CvarGrenadesRound = CreateConVar("vip_nades_round", "1", "From which round free grenades should be given?");
	g_CvarHEGranat = CreateConVar("vip_he", "1", "Should the VIP player get the Grenade HE for the start of a round?");
	g_CvarFlashGranat = CreateConVar("vip_flash", "1", "Should the vip player get the  flashbang for the start of a round?");
	g_CvarSmokeGranat = CreateConVar("vip_smoke", "1", "Should the VIP player get the smokegrenade for the start of a round?");
	g_CvarDecoyGranat = CreateConVar("vip_decoy", "0", "Should the VIP player get the decoy for the start of a round?");
	g_CvarHealGranat = CreateConVar("vip_heal", "0", "Should the VIP player get the medishot for the start of a round?");
	g_CvarIncGranat = CreateConVar("vip_inc", "0", "Should the VIP player get the fire grenade (CT) for the start of a round?");
	g_CvarMolotovGranat = CreateConVar("vip_molotov", "0", "Should the VIP player get the fire grenade (TT) for the start of a round?");
	g_CvarTaGranat = CreateConVar("vip_tactic", "0", "Should the VIP player get the ta-grenade for the start of a round?");
	g_CvarTagTabela = CreateConVar("vip_tag", "0", "Should the table have the tag for the VIP player?");
	g_CvarVipTagTabela = CreateConVar("sm_clantag", "[VIP]", "What kind of the tag should the VIP player have in the table");
	g_CvarDoubleJump = CreateConVar("double_jump", "1", "Is the VIP player supposed to have a double jump?");
	g_CvarPistolMenu = CreateConVar("vip_menu_broni", "1", "Is it necessary to have a weapon menu for the VIP player?");
	g_CvarRundaPistolMenu = CreateConVar("vip_runda_PistolMenu", "3", "From which round should be shown the weapon menu for the VIP player?");
	
	AutoExecConfig(true, "H2K_Vip_configuration");
}

public void OnMapStart()
{
	RoundCount = 0;
}

public void OnClientPutInServer(int client)
{
	g_bHudMessage[client] = true;
}

public void OnClientPostAdminCheck(int client)
{
	if (g_CvarVipWelcome.BoolValue && IsPlayerVip(client))
	{
		PrintToChatAll("╔════════════════════════════════════════╗");
		PrintToChatAll("%s %N has joined the game", VIP_PREFIX, client);
		PrintToChatAll("╚════════════════════════════════════════╝");
	}
}

public void OnClientDisconnect(int client)
{
	if (g_CvarVipLeave.BoolValue && IsPlayerVip(client))
	{
		PrintToChatAll("╔════════════════════════════════════════╗");
		PrintToChatAll("%s %N left the game", VIP_PREFIX, client);
		PrintToChatAll("╚════════════════════════════════════════╝");
	}
}

public Action Hud_Command(int client, int args)
{
	if (!g_CvarVipHudMessages.BoolValue)
	{
		PrintToChat(client, "This function has been disabled by server administrator.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerVip(client))
	{
		PrintToChat(client, "Only VIP can use this command.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Use: sm_hudsay <text>");
		return Plugin_Handled;
	}
	
	char text[192];
	GetCmdArgString(text, sizeof(text));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetHudTextParams(0.35, 0.225, 10.0, 0, 255, 0, 1, 0, 2.5, 2.0); //You can edit it 4fun idgaf
			ShowHudText(i, 5, "VIP: %N say:\n%s", client, text);
		}
	}
	
	g_bHudMessage[client] = false;
	CreateTimer(120.0, Timer_EnableMessage, client);
	
	return Plugin_Handled;
}

public Action Timer_EnableMessage(Handle timer, any client)
{
	if (client)
		g_bHudMessage[client] = true;
}

public Action GunsMenu(int client) // I will do configuration via KeyValues to it, but i actually dont think its that important.
{
	if (IsValidClient(client))
	{
		if (IsPlayerVip(client))
		{
			Menu menu = new Menu(MenuHandler1);
			menu.SetTitle("VIP : Choose your Gun");
			menu.AddItem("weapon_ak47", "AK-47");
			menu.AddItem("weapon_m4a1", "M4A4");
			menu.AddItem("weapon_m4a1_silencer", "M4A1-S");
			menu.AddItem("weapon_awp", "AWP");
			menu.AddItem("weapon_ssg08", "SCOUT");
			menu.AddItem("weapon_xm1014", "XM1014");
			menu.AddItem("weapon_famas", "FAMAS");
			menu.ExitButton = true;
			menu.Display(client, 15);
		}
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (IsPlayerAlive(client))
		{
			StripAllWeapons(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, info);
			PistolMenu(client);
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Action PistolMenu(int client)
{
	if (IsValidClient(client))
	{
		if (IsPlayerVip(client))
		{
			Menu menusec = new Menu(MenuHandler2);
			menusec.SetTitle("VIP : Choose Pistol");
			menusec.AddItem("weapon_deagle", "Deagle");
			menusec.AddItem("weapon_revolver", "R8 Revolver");
			menusec.AddItem("weapon_fiveseven", "Five-Seven");
			menusec.AddItem("weapon_tec9", "Tec-9");
			menusec.AddItem("weapon_cz75a", "CZ7a");
			menusec.AddItem("weapon_elite", "Dual Elites");
			menusec.AddItem("weapon_p250", "p250");
			menusec.ExitButton = true;
			menusec.Display(client, 15);
		}
	}
}

public int MenuHandler2(Menu menusec, MenuAction action, int client, int itemNum)
{
	
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menusec, itemNum, info, sizeof(info));
		
		if (IsPlayerAlive(client))
			GivePlayerItem(client, info);
	}
	else if (action == MenuAction_End)
		CloseHandle(menusec);
}

public Action Event_RoundStart(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") != 1)
		RoundCount = RoundCount + 1;
}

public Action ResetAfterTeamChange(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	RoundCount = 0;
}

public Action Event_PlayerSpawn(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return;
	
	if (IsPlayerVip(client))
	{
		SetEntityHealth(client, g_CvarVipHP.IntValue);
		if (g_Cvar_Kevlar_Helmet_1_round.BoolValue && RoundCount <= 1)
			return;
		else
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", g_CvarVipArmor.IntValue);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", g_CvarVipHelmet.IntValue);
		}
		
		SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + g_CvarVipStartMoney.IntValue);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_CvarVipMovmentSpeed.FloatValue);
		SetEntityGravity(client, g_CvarVipGravity.FloatValue);
		
		if (GetClientTeam(client) == CS_TEAM_CT && GetEntProp(client, Prop_Send, "m_bHasDefuser") == 0)
			GivePlayerItem(client, "item_defuser");
		
		if (RoundCount >= g_CvarGrenadesRound.IntValue)
		{
			if (g_CvarHEGranat.BoolValue)
				GivePlayerItem(client, "weapon_hegrenade");
			
			if (g_CvarFlashGranat.BoolValue)
				GivePlayerItem(client, "weapon_flashbang");
			
			if (g_CvarSmokeGranat.BoolValue)
				GivePlayerItem(client, "weapon_smokegrenade");
			
			if (g_CvarDecoyGranat.BoolValue)
				GivePlayerItem(client, "weapon_decoy");
			
			if (g_CvarHealGranat.BoolValue)
				GivePlayerItem(client, "weapon_healthshot");
			
			if (GetClientTeam(client) == CS_TEAM_CT && g_CvarIncGranat.BoolValue)
				GivePlayerItem(client, "weapon_incgrenade");
			
			if (GetClientTeam(client) == CS_TEAM_T && g_CvarMolotovGranat.BoolValue)
				GivePlayerItem(client, "weapon_molotov");
			
			if (g_CvarTaGranat.BoolValue)
				GivePlayerItem(client, "weapon_tagrenade");
		}
	}
	
	if (g_CvarPistolMenu.BoolValue && RoundCount >= g_CvarRundaPistolMenu.IntValue)
		GunsMenu(client);
}

public Action Event_PlayerDeath(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (!IsValidClient(attacker))
		return;
	
	char weapon[64];
	GetEventString(hEvent, "weapon", weapon, sizeof(weapon));
	
	if (IsPlayerVip(attacker))
	{
		if (GetClientTeam(attacker) != GetClientTeam(victim))
		{
			bool headshot = hEvent.GetBool("headshot", false); //false - default.
			int PieniadzeGracza = GetEntProp(attacker, Prop_Send, "m_iAccount");
			int HP = GetClientHealth(attacker);
			
			if (headshot)
			{
				SetEntProp(attacker, Prop_Send, "m_iAccount", g_CvarVipHeadShotMoney.IntValue + PieniadzeGracza);
				
				if (HP + g_CvarVipHeadShotHP.IntValue > g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, g_CvarMaxHP.IntValue);
				
				if (HP + g_CvarVipHeadShotHP.IntValue <= g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, HP + g_CvarVipHeadShotHP.IntValue);
			}
			else
			{
				SetEntProp(attacker, Prop_Send, "m_iAccount", g_CvarVipKillMoney.IntValue + PieniadzeGracza);
				
				if (HP + g_CvarVipKillHP.IntValue > g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, g_CvarMaxHP.IntValue);
				
				if (HP + g_CvarVipKillHP.IntValue <= g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, HP + g_CvarVipKillHP.IntValue);
			}
			
			//if (StrEqual(weapon, "knife"))
			if (StrContains(weapon, "knife", false) != -1 || StrContains(weapon, "bayonet", false) != -1)
			{
				SetEntProp(attacker, Prop_Send, "m_iAccount", g_CvarVipKillKnifeMoney.IntValue + PieniadzeGracza);
				
				if (g_CvarChatMessages.BoolValue)
					PrintToChat(attacker, "%s As a VIP player you received %i$ for Knife kill.", VIP_PREFIX, g_CvarVipKillKnifeMoney.IntValue);
			}
		}
	}
}

public Action Event_BombPlanted(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	int PieniadzeGracza = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if (IsPlayerVip(client))
	{
		if (g_CvarChatMessages.BoolValue)
			PrintToChat(client, "%s As a VIP player you received %i$ for planting a Bomb.", VIP_PREFIX, g_CvarVipBombPlantedMoney.IntValue);
		
		SetEntProp(client, Prop_Send, "m_iAccount", g_CvarVipBombPlantedMoney.IntValue + PieniadzeGracza);
	}
}

public Action Event_BombDefused(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	int PieniadzeGracza = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if (IsPlayerVip(client))
	{
		if (g_CvarChatMessages.BoolValue)
			PrintToChat(client, "%s As a VIP player you received %i$ for defusing a Bomb.", VIP_PREFIX, g_CvarVipBombDefusedMoney.IntValue);
		
		SetEntProp(client, Prop_Send, "m_iAccount", g_CvarVipBombDefusedMoney.IntValue + PieniadzeGracza);
	}
}

public Action Event_RoundEnd(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int WygranaDruzyna = hEvent.GetInt("winner");
	
	for (int client = 1; client < MAXPLAYERS + 1; client++)
	{
		if(!IsValidClient(client))
			return;
		
		if (IsPlayerVip(client))
		{
			RemoveNades(client);
			
			if (GetClientTeam(client) == WygranaDruzyna)
				SetEntProp(client, Prop_Send, "m_iAccount", g_CvarVipRoundWinMoney.IntValue + GetEntProp(client, Prop_Send, "m_iAccount"));
		}
	}
}

public Action Event_TagTable(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	char TagTabela[128];
	g_CvarVipTagTabela.GetString(TagTabela, sizeof(TagTabela));
	
	if (IsPlayerVip(client) && g_CvarTagTabela.BoolValue)
		CS_SetClientClanTag(client, TagTabela);
	
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsPlayerVip(client) && IsPlayerAlive(client) && g_CvarDoubleJump.BoolValue)
	{
		static int g_fLastButtons[MAXPLAYERS + 1], g_fLastFlags[MAXPLAYERS + 1], g_iJumps[MAXPLAYERS + 1], fCurFlags, fCurButtons;
		fCurFlags = GetEntityFlags(client);
		fCurButtons = GetClientButtons(client);
		if (g_fLastFlags[client] & FL_ONGROUND && !(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)g_iJumps[client]++;
		else if (fCurFlags & FL_ONGROUND)g_iJumps[client] = 0;
		else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP && g_iJumps[client] == 1)
		{
			g_iJumps[client]++;
			float vVel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
			vVel[2] = 250.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		}
		
		g_fLastFlags[client] = fCurFlags;
		g_fLastButtons[client] = fCurButtons;
	}
	return Plugin_Continue;
}

public Action ShowOnlineVips(int client, int args)
{
	if (!g_CvarVipsOnline.BoolValue)
	{
		PrintToChat(client, "This function has been disabled by server administrator.");
		return Plugin_Handled;
	}
	
	int iCount = 0;
	
	Menu menu = new Menu(Menu_Handler);
	
	menu.SetTitle("Vip players that are currently on the server");
	
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if (IsPlayerVip(i) && IsClientInGame(i))
			{
				char format[128];
				char cid[16];
				char name[MAX_NAME_LENGTH + 1];
			
				IntToString(i, cid, sizeof cid);
				GetClientName(i, name, sizeof name);
			
				Format(format, sizeof format, "[VIP] » %s", name);
				menu.AddItem(cid, format, ITEMDRAW_DISABLED);
				iCount++;
			}	
		}
	}
	
	if (iCount == 0)
	{
		menu.AddItem("ITEMDRAW_DISABLED", "Oops, it looks like there are no online players having VIP service.");
	}
	
	menu.ExitButton = true;
	menu.Display(client, 0);
	
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}

stock void StripAllWeapons(int client)
{
	int iEnt;
	for (int i = 0; i <= 2; i++)
	{
		while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iEnt);
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}

stock void RemoveNades(int client)
{
	while (RemoveWeaponBySlot(client, 3)) {  }
	for (int i = 0; i < 6; i++)
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}

stock bool RemoveWeaponBySlot(int client, int iSlot)
{
	int iEntity = GetPlayerWeaponSlot(client, iSlot);
	
	if (IsValidEdict(iEntity))
	{
		RemovePlayerItem(client, iEntity);
		AcceptEntityInput(iEntity, "Kill");
		return true;
	}
	return false;
}

stock bool IsPlayerVip(int client)
{
    char flag[10];
    g_cvVipFlag.GetString(flag, sizeof(flag));
 
    if (GetUserFlagBits(client) & ReadFlagString(flag))
        return true;
    return false;
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsClientReplay(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}
 
/* © 2019 Coded with ❤ for Rias		  */
/* © 2019 Coded with ❤ for Akame			 */
/* © 2019 Coded with ❤ for Est		   */
/* © 2019 Coded with ❤ for Yoshino	   */
/* © 2019 Coded with ❤ for Koneko			*/
/* © 2019 Coded with ❤ for Erina			 */
/* © 2019 Coded with ❤ for Megumi			*/
/* © 2019 Coded with ❤ for Akeno			 */
/* © 2019 Coded with ❤ for Mero		  */
/* © 2019 Coded with ❤ for Papi		  */
/* © 2019 Coded with ❤ for Suu		   */
/* © 2019 Coded with ❤ for Lilith			*/
/* © 2019 Coded with ❤ for Mitsuha	   */
/* © 2019 Coded with ❤ for Matsuzaka	 */
/* © 2019 Coded with ❤ for Maki		  */
/* © 2019 Coded with ❤ for Alice			 */
/* © 2019 Coded with ❤ for Konno Yuuki   (*) Arigato! :< */