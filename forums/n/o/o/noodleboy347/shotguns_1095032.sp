//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

new Handle:cvar_enabled;
new Handle:cvar_pyro;
new Handle:cvar_pyro_mindmg;
new Handle:cvar_heavy;
new Handle:cvar_engineer;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = "[TF2] Shotgun Upgrades",
	author = "noodleboy347",
	description = "Gives players unique class shotguns.",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// C O N V A R S //
	CreateConVar("sm_shotgun_version", PLUGIN_VERSION, "Version of the plugin");
	cvar_enabled = CreateConVar("sm_shotgun_enable", "1", "Enables the Shotgun Upgrades plugin");
	cvar_pyro = CreateConVar("sm_shotgun_pyro", "1", "Pyro Shotgun: Incendiary Ammo");
	cvar_pyro_mindmg = CreateConVar("sm_shotgun_pyro_mindmg", "50", "Minimum amount of damage to ignite enemy");
	cvar_heavy = CreateConVar("sm_shotgun_heavy", "1", "Heavy Shotgun: Health boost");
	cvar_engineer = CreateConVar("sm_shotgun_engineer", "1", "Engineer Shotgun: Metal regeneration");
	
	
	// C O M M A N D S //
	RegConsoleCmd("shotguns", Command_Info);
	
	// H O O K S //
	HookEvent("player_hurt", Event_Hurt);
	
	// O T H E R //
	AutoExecConfig();
}

////////////////////////
//P L A Y E R  H U R T//
////////////////////////
public Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new hurt = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "damageamount");
	new weapon = GetEventInt(event, "weaponid");
	new health = GetClientHealth(client);
	if(client != 0 && client != hurt)
	{
		if(GetConVarInt(cvar_enabled) == 1 && GetConVarInt(cvar_engineer) && weapon == 12)
		{
			new metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12);
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12, metal + (damage / 2), 4, true);
		}
		if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_heavy) && weapon == 14 && health <= 450)
		{
			SetEntityHealth(client, health + (damage / 2));
		}
		if(GetConVarInt(cvar_enabled) && GetConVarInt(cvar_pyro) && weapon == 15 && damage >= GetConVarInt(cvar_pyro_mindmg))
		{
			TF2_IgnitePlayer(hurt, client);
		}
	}
}

////////////////////
//I N F O  M E N U//
////////////////////
public Action:Command_Info(client, args)
{
	new Handle:shotguninfo = CreatePanel();
	DrawPanelItem(shotguninfo, "Pyro: Incendiary Ammo");
	DrawPanelText(shotguninfo, "- Ignites enemies when shot for over 50 damage.");
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Engineer: Vaccuum Addon");
	DrawPanelText(shotguninfo, "- Steals metal from enemies when shot. Metal stolen is relevant to damage done.");
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Heavy: Sandvich Gun");
	DrawPanelText(shotguninfo, "- Steals enemy health when shot.");
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Exit");
	SendPanelToClient(shotguninfo, client, Panel_Info, 30);
	CloseHandle(shotguninfo);
	return Plugin_Handled;
}
public Panel_Info(Handle:menu, MenuAction:action, param1, param2)
{
	//Nothing
}