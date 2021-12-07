//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

new Handle:cvar_enabled;
new Handle:cvar_pyro;
new Handle:cvar_pyro_mindmg;
new Handle:cvar_heavy;
new Handle:cvar_engineer;
new Handle:cvar_soldier;
new Handle:cvar_soldier_mindmg;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = "[TF2] Shotgun Upgrades",
	author = "noodleboy347, edit by Deathreus",
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
	CreateConVar("sm_shotgun_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
	cvar_enabled = CreateConVar("sm_shotgun_enable", "1", "Enables the Shotgun Upgrades plugin", _, true, 0.0, true, 1.0);
	cvar_pyro = CreateConVar("sm_shotgun_pyro", "1", "Enable Pyro Shotgun: Incendiary Ammo?", _, true, 0.0, true, 1.0);
	cvar_pyro_mindmg = CreateConVar("sm_shotgun_pyro_mindmg", "40", "Minimum amount of damage to ignite enemy");
	cvar_heavy = CreateConVar("sm_shotgun_heavy", "1", "Enable Heavy Shotgun: Health boost?", _, true, 0.0, true, 1.0);
	cvar_engineer = CreateConVar("sm_shotgun_engineer", "1", "Enable Engineer Shotgun: Metal regeneration?", _, true, 0.0, true, 1.0);
	cvar_soldier = CreateConVar("sm_shotgun_soldier", "1", "Enable Soldier Shotgun: Explosive Rounds?", _, true, 0.0, true, 1.0);
	cvar_soldier_mindmg = CreateConVar("sm_shotgun_soldier_mindmg", "65", "Minimum amount of damage to create the explosion");
	
	
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
public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new hurt = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, "damageamount");
	new weapon = GetEventInt(event, "weaponid");
	if(!GetConVarBool(cvar_enabled))
		return Plugin_Continue;

	if(client != 0 && client != hurt)
	{
		new health = GetClientHealth(client);
		if(!IsValidClient(client))
			return Plugin_Continue;

		if(GetConVarInt(cvar_engineer) && weapon == 12)
		{
			new metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12);
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 12, metal + (damage / 2), 4, true);
		}
		if(GetConVarInt(cvar_heavy) && weapon == 14 && health <= 450)
		{
			SetEntityHealth(client, health + (damage / 2));
		}
		if(GetConVarInt(cvar_pyro) && weapon == 15 && damage >= GetConVarInt(cvar_pyro_mindmg))
		{
			TF2_IgnitePlayer(hurt, client);
		}
		if(GetConVarInt(cvar_soldier) && weapon == 13 && damage >= GetConVarInt(cvar_soldier_mindmg))
		{
			new proj;
			decl Float:pos[3];

			GetEntPropVector(hurt, Prop_Send, "m_vecOrigin", pos);
			for(new i=0; i<5; i++)
			{
				proj = CreateEntityByName("env_explosion");  
				DispatchKeyValueFloat(proj, "DamageForce", 180.0);

				SetEntProp(proj, Prop_Data, "m_iMagnitude", 45, 4);
				SetEntProp(proj, Prop_Data, "m_iRadiusOverride", 120, 4);
				SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", client);

				DispatchSpawn(proj);
				TeleportEntity(proj, pos, NULL_VECTOR, NULL_VECTOR);

				AcceptEntityInput(proj, "Explode");
				AcceptEntityInput(proj, "Kill");
			}
		}
	}
	return Plugin_Continue;
}

////////////////////
//I N F O  M E N U//
////////////////////
public Action:Command_Info(client, args)
{
	new String:info1[128], String:info2[128];
	Format(info1, sizeof(info1), "- Ignites enemies when shot for over %i damage.", GetConVarInt(cvar_pyro_mindmg));
	Format(info2, sizeof(info2), "- Creates a small explosion when shot for over %i damage", GetConVarInt(cvar_soldier_mindmg));
	new Handle:shotguninfo = CreatePanel();
	DrawPanelItem(shotguninfo, "Pyro: Incendiary Ammo");
	DrawPanelText(shotguninfo, info1);
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Engineer: Vaccuum Addon");
	DrawPanelText(shotguninfo, "- Steals metal from enemies when shot. Metal stolen is relevant to damage done.");
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Heavy: Sandvich Gun");
	DrawPanelText(shotguninfo, "- Steals enemy health when shot.");
	DrawPanelText(shotguninfo, " ");
	DrawPanelItem(shotguninfo, "Soldier: Explosive Rounds");
	DrawPanelText(shotguninfo, info2);
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

stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}