//
// SourceMod Script
//

//
// CHANGELOG:
// Version:
//	0.2.2 - fix bugs for css and l4d
//	0.2.1 - bug fix
//	0.2.0 - new CVAR sv_showhits_attacker for diable that attacker see his hits
//	      - runs now under css
//	0.1.9 - fix a bug that plugins always disabled (thanks FeuerSturm)
//	0.1.8 - add CVAR to enable/disble plugin
//	      - change color of attaker message
//	0.1.7 - fix bug that hitsgroups array out of bonce
//	0.1.6 - bug fix (wrong Target message)
//	0.1.5 - optimize chat message
//	0.1.4 - first release to community


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2.2"

new Handle:C_ShowhitsEnable = INVALID_HANDLE
new Handle:C_ShowhitsAttacker = INVALID_HANDLE
new bool:c_showhitsEnable;
new bool:c_showhitsAttacker;

/*gameMod
0 = DODS
1 = CSS
2 = L4D
*/
new gameMod = -1;

new String:hitgroups[8][]={"body","head", "upper chest", "waist", "left arm", "righte arm", "left Leg", "right leg"};

public Plugin:myinfo = 
{
	name = "showhits",
	author = "psychocoder",
	description = "show damage, name of attacker and distance if player hurt",
	version = PLUGIN_VERSION,
	url = "extreme.xrip.de"
}

public OnPluginStart()
{
	CreateConVar("showhits_version", PLUGIN_VERSION, "Show version of showhits", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	C_ShowhitsEnable = CreateConVar("sv_showhits", "1", "enable or disble the plugin (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	C_ShowhitsAttacker = CreateConVar("sv_showhits_attacker", "1", "enable or disble that attacker see hits that he made(0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	HookConVarChange(C_ShowhitsEnable, EnableChanged);
	HookConVarChange(C_ShowhitsAttacker, AttackerChanged);

	setGameMod();

	switch(gameMod)
	{
		case 0:
			HookEvent("player_hurt", PlayerHurtEvent_dods);
		case 1:
			HookEvent("player_hurt", PlayerHurtEvent_l4d_css);
		case 2:
			HookEvent("player_hurt", PlayerHurtEvent_l4d_css);
	}

	
	c_showhitsEnable=GetConVarBool(C_ShowhitsEnable);
	c_showhitsAttacker=GetConVarBool(C_ShowhitsAttacker);
}


public setGameMod()
{
	new String: game_description[64];
	GetGameDescription(game_description, 64, true);

	if (StrContains(game_description, "Counter-Strike", false) == 0)
		gameMod = 1;
	else if (StrContains(game_description, "Day of Defeat", false) == 0)
		gameMod = 0;
	else if (StrContains(game_description, "L4D", false) == 0) 
		gameMod = 2;

	//if game not detect
	if (gameMod == -1) 
	{
		new String: game_folder[64];
		GetGameFolderName(game_folder, 64);

		if (StrContains(game_folder, "cstrike", false) == 0) 
			gameMod = 1;
		else if (StrContains(game_folder, "dod", false) == 0) 
			gameMod = 0;
		else if (StrContains(game_folder, "left4dead", false) == 0) 
			gameMod = 2;		
	}
}

public OnEventShutdown()
{
	UnhookConVarChange(C_ShowhitsEnable, EnableChanged);
	switch(gameMod)
	{
		case 0:
			UnhookEvent("player_hurt", PlayerHurtEvent_dods);
		case 1:
			UnhookEvent("player_hurt", PlayerHurtEvent_l4d_css);
		case 2:
			UnhookEvent("player_hurt", PlayerHurtEvent_l4d_css);
	}
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_showhitsEnable=GetConVarBool(C_ShowhitsEnable);
}

public AttackerChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_showhitsAttacker=GetConVarBool(C_ShowhitsAttacker);
}

public PlayerHurtEvent_dods(Handle:event, const String:name[], bool:dontBroadcast)
{

	if(!c_showhitsEnable) //plugin diabled
		return;

	new client     = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client==0 || attacker==0)
		return;
	
	if (IsClientInGame(client) && IsClientInGame(attacker))
	{
		new String:clientName[64]
		new String:attackerName[64] 
		
		GetClientName(client, clientName, 64);
		GetClientName(attacker, attackerName, 64);
		new hitgroup = GetEventInt(event, "hitgroup")
		
		if((hitgroup >= 0) && (hitgroup <=7))
		{
			new damage   = GetEventInt(event, "damage")
		
		// Hitgroups
		// 0 = body (generic part for css)
		// 1 = Head
		// 2 = Upper Chest
		// 3 = Lower Chest
		// 4 = Left arm
		// 5 = Right arm
		// 6 = Left leg
		// 7 = Right Leg

			new Float:client_pos[3];
			new Float:attacker_pos[3];
			GetClientAbsOrigin(client,client_pos);
			GetClientAbsOrigin(attacker,attacker_pos);
			new Float:distance = GetVectorDistance(client_pos,attacker_pos,false);
			distance*=0.025;
		
			PrintToChat(client,"\x01\x05Attacker: %s\x01, %s %i dmg, %.2fm",attackerName,hitgroups[hitgroup],damage,distance);
			if(c_showhitsAttacker) PrintToChat(attacker,"\x01Target: %s\x01, %s %i dmg, %.2fm",clientName,hitgroups[hitgroup],damage,distance);
		}

	}

}

public PlayerHurtEvent_l4d_css(Handle:event, const String:name[], bool:dontBroadcast)
{

	if(!c_showhitsEnable) //plugin diabled
		return;

	new client     = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client==0 || attacker==0)
		return;
	
	if (IsClientInGame(client) && IsClientInGame(attacker))
	{
		new String:clientName[64]
		new String:attackerName[64] 
		
		GetClientName(client, clientName, 64);
		GetClientName(attacker, attackerName, 64);
		new hitgroup = GetEventInt(event, "hitgroup")
		
		if((hitgroup >= 0) && (hitgroup <=7))
		{
			new damage   = GetEventInt(event, "dmg_health")
			new damage_armor   = GetEventInt(event, "dmg_armor")
		
		// Hitgroups
		// 0 = body (generic part for css)
		// 1 = Head
		// 2 = Upper Chest
		// 3 = Lower Chest
		// 4 = Left arm
		// 5 = Right arm
		// 6 = Left leg
		// 7 = Right Leg

			new Float:client_pos[3];
			new Float:attacker_pos[3];
			GetClientAbsOrigin(client,client_pos);
			GetClientAbsOrigin(attacker,attacker_pos);
			new Float:distance = GetVectorDistance(client_pos,attacker_pos,false);
			distance*=0.025;
		
			PrintToChat(client,"\x01\x05Attacker: %s\x01, %s %i dmg, %i armor dmg, %.2fm",attackerName,hitgroups[hitgroup],damage,damage_armor,distance);
			if(c_showhitsAttacker) PrintToChat(attacker,"\x01Target: %s\x01, %s %i dmg, %i armor dmg, %.2fm",clientName,hitgroups[hitgroup],damage,damage_armor,distance);
		}

	}

}
 
