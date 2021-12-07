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

TODO:

~ Eating ASS.

==============================================

//Credits only for her no one else :)
http://images6.fanpop.com/image/photos/36600000/Rias-Gremory-image-rias-gremory-36601369-1920-1080.png

*/

/* << Includy >> */
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multi1v1>

/* << Define >> */
#define PLUGIN_NAME "[CSGO] Advanced VIP System for CSGO Servers (Splewis Arena)"
#define PLUGIN_DESCRIPTION "[CSGO] Avanced VIP System for CSGO Servers (Splewis Arena)"
#define PLUGIN_AUTHOR "Mesharsky"
#define PLUGIN_VERSION "0.1"

#define ARENAVIP_PREFIX " ★ \x02[VIP]\x04"

/* << Pragma >> */
#pragma newdecls required
#pragma semicolon 1

/* << Macro >> */
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)\if(IsClientInGame(%1))

/* << ConVary >> */
ConVar g_cvVipFlag;
ConVar g_cvVipUnlimitedAmmo;
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
ConVar g_CvarHEGranat;
ConVar g_CvarFlashGranat;
ConVar g_CvarSmokeGranat;
ConVar g_CvarDecoyGranat;
ConVar g_CvarHealGranat;
ConVar g_CvarIncGranat;
ConVar g_CvarMolotovGranat;
ConVar g_CvarTaGranat;
ConVar g_CvarTagTabela;
ConVar g_CvarDoubleJump;
ConVar g_CvarFreeVIP;
ConVar g_CvarVipFromHr;
ConVar g_CvarVipToHr;

/* << Inty >> */
int FreeVIP = 0;

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

public void OnAllPluginsLoaded()
{
	if (FindConVar("sm_multi1v1_version"))
		PrintToServer("[VIP-SYSTEM] Your VIP plugin is running with ARENA MODE, Enjoy! :)");
	else
		SetFailState("[VIP-SYSTEM-ERROR] Your server needs splewis arena mode plugin: https://github.com/splewis/csgo-multi-1v1");
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookEvent("weapon_fire", Event_WeaponReload);
	
	RegConsoleCmd("sm_vips", ShowOnlineVips);
	RegConsoleCmd("sm_vipy", ShowOnlineVips);
	RegConsoleCmd("sm_vipsay", Hud_Command);
	
	/* << ConVary >> */
	g_cvVipFlag = CreateConVar("arenavip_flag", "o", "Required flag for the Vip player (Leave empty so all the players will have VIP).");
	
	g_CvarVipsOnline = CreateConVar("arenavip_vipy_online", "1", "Do you want to turn on the VIPS ONLINE function?");
	g_CvarVipWelcome = CreateConVar("arenavip_przywitanie", "1", "Do you want to turn on the VIP WELCOME function?");
	g_CvarVipLeave = CreateConVar("arenavip_pozegnanie", "1", "Do you want to turn on the VIP FAREWELL function?");
	g_CvarVipHudMessages = CreateConVar("arenavip_hud_message", "1", "Do you allow the VIP to write in HUD?");
	g_CvarVipHP = CreateConVar("zycie_arenavip", "105", "How much health does vip should have for the start of the round?");
	g_CvarMaxHP = CreateConVar("zycie_max_arenavip", "130", "What is the maximum amount of health that the vip player can achieve?");
	g_CvarVipKillHP = CreateConVar("kill_hp_arenavip", "5", "How much health the VIP player should get for each kill?");
	g_CvarVipHeadShotHP = CreateConVar("hs_hp_arenavip", "10", "How much health should the VIP player get for the headshot?");
	g_CvarVipMovmentSpeed = CreateConVar("arenavip_predkosc_ruchu", "1.0", "Movement speed for the VIP player (1.0 - standard)");
	g_CvarVipGravity = CreateConVar("arenavip_grawitacja", "1.0", "Gravity for the VIP player (1.0- standard)");
	g_CvarVipArmor = CreateConVar("armor_arenavip", "100", "Vest points for the VIP player? (From 1 to 100)");
	g_CvarVipHelmet = CreateConVar("helm_arenavip", "1", "Is the VIP player supposed to  have a free helmet? (0/1)");
	g_CvarHEGranat = CreateConVar("arenavip_he", "1", "Should the VIP player get the Grenade HE for the start of a round?");
	g_CvarFlashGranat = CreateConVar("arenavip_flash", "1", "Should the vip player get the  flashbang for the start of a round?");
	g_CvarSmokeGranat = CreateConVar("arenavip_smoke", "1", "Should the VIP player get the smokegrenade for the start of a round?");
	g_CvarDecoyGranat = CreateConVar("arenavip_decoy", "0", "Should the VIP player get the decoy for the start of a round?");
	g_CvarHealGranat = CreateConVar("arenavip_heal", "0", "Should the VIP player get the medishot for the start of a round?");
	g_CvarIncGranat = CreateConVar("arenavip_inc", "0", "Should the VIP player get the fire grenade (CT) for the start of a round?");
	g_CvarMolotovGranat = CreateConVar("arenavip_molotov", "0", "Should the VIP player get the fire grenade (TT) for the start of a round?");
	g_CvarTaGranat = CreateConVar("arenavip_tactic", "0", "Should the VIP player get the ta-grenade for the start of a round?");
	g_CvarTagTabela = CreateConVar("arenavip_tag", "1", "Should the table have the tag for the VIP player?");
	g_CvarDoubleJump = CreateConVar("double_jump", "1", "Is the VIP player supposed to have a double jump?");
	
	g_CvarFreeVIP = CreateConVar("arenavip_od_danej_godziny", "1", "Should a FreeVIP for specific hours be enabled?");
	g_CvarVipFromHr = CreateConVar("arenavip_from_hr", "22", "From which hour should freevip start?");
	g_CvarVipToHr = CreateConVar("arenavip_to_hr", "8", "To which hour should be freevip assigned? (AM)");
	
	g_cvVipUnlimitedAmmo = CreateConVar("arenavip_unli_ammo", "0", "Should VIP get unlimited ammo?");
	
	AutoExecConfig(true, "H2K_VipConf_2.0_ArenaM");
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
		PrintToChatAll("%s %N has joined the game", ARENAVIP_PREFIX, client);
		PrintToChatAll("╚════════════════════════════════════════╝");
	}
}

public void OnClientDisconnect(int client)
{
	if (g_CvarVipLeave.BoolValue && IsPlayerVip(client))
	{
		PrintToChatAll("╔════════════════════════════════════════╗");
		PrintToChatAll("%s %N left the game", ARENAVIP_PREFIX, client);
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

public Action Event_RoundStart(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	if (g_CvarFreeVIP.BoolValue)
	{
		int from_hr = g_CvarVipFromHr.IntValue;
		int to_hr = g_CvarVipToHr.IntValue;
		
		if (from_hr || to_hr)
		{
			char string_hour[8];
			FormatTime(string_hour, sizeof(string_hour), "%H", GetTime());
			int hour = StringToInt(string_hour);
			
			if (from_hr > to_hr)
				FreeVIP = (hour >= from_hr || hour < to_hr) ? 1:0;
			else
				FreeVIP = (hour >= from_hr && hour < to_hr) ? 1:0;
		}
		else
			FreeVIP = 0;
	}
}

public void Multi1v1_AfterPlayerSetup(int client)
{
	int ArenaNum = Multi1v1_GetArenaNumber(client);
		
	if (IsPlayerVip(client))
	{
		char TagScoreboard[32];
		Format(TagScoreboard, sizeof(TagScoreboard), "Arena %i | VIP", ArenaNum);
		if (g_CvarTagTabela.BoolValue)
			CS_SetClientClanTag(client, TagScoreboard);
		
		SetEntityHealth(client, g_CvarVipHP.IntValue);
		
		SetEntProp(client, Prop_Send, "m_ArmorValue", g_CvarVipArmor.IntValue);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", g_CvarVipHelmet.IntValue);
		
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_CvarVipMovmentSpeed.FloatValue);
		SetEntityGravity(client, g_CvarVipGravity.FloatValue);
		
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
			int HP = GetClientHealth(attacker);
			
			if (headshot)
			{
				if (HP + g_CvarVipHeadShotHP.IntValue > g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, g_CvarMaxHP.IntValue);
				
				if (HP + g_CvarVipHeadShotHP.IntValue <= g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, HP + g_CvarVipHeadShotHP.IntValue);
			}
			else
			{
				if (HP + g_CvarVipKillHP.IntValue > g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, g_CvarMaxHP.IntValue);
				
				if (HP + g_CvarVipKillHP.IntValue <= g_CvarMaxHP.IntValue)
					SetEntityHealth(attacker, HP + g_CvarVipKillHP.IntValue);
			}
		}
	}
}

public Action Event_WeaponReload(Event hEvent, const char[] chName, bool bDontBroadcast)
{
	if (!g_cvVipUnlimitedAmmo.BoolValue)
		return;
	
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (!IsValidClient(client))
		return;
	
	char ClassN[32];
	GetEdictClassname(weapon, ClassN, sizeof(ClassN));
	
	if (IsPlayerVip(client) && IsPlayerAlive(client))
	{
		if (weapon > 0 && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)))
		{
			if (StrContains(ClassN, "weapon_", false) != -1)
			{
				SetEntProp(weapon, Prop_Send, "m_iClip1", 32);
				SetEntProp(weapon, Prop_Send, "m_iClip2", 32);
			}
		}
	}
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
		if (IsValidClient(i))
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

stock bool IsPlayerVip(int client)
{
	char flag[10];
	g_cvVipFlag.GetString(flag, sizeof(flag));
	
	if (GetUserFlagBits(client) & ReadFlagString(flag) || GetAdminFlag(GetUserAdmin(client), Admin_Root) || FreeVIP)
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
