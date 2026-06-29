#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new Handle:double_item_on;

public Plugin:myinfo =
{
	name = "l4d2additemsbots",
	author = "sonnzy",
	description = "add survivor bots increase item count",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public OnPluginStart()
{
	double_item_on = CreateConVar("double_item_on", "1","double item supply is on|off",FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_addbot", CmdAddBot, ADMFLAG_ROOT);

	AutoExecConfig(true, "l4d2additemsbots")

	HookEvent("round_start", RoundStart, EventHookMode_Post);
}

public Action:CmdAddBot(client, args)
{
	new Handle:menu = CreateMenu(addbotmenu);
	SetMenuTitle(menu, "l4d2 clientaddbots menu");
	AddMenuItem(menu, "option0", "add survivor bot");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return;
}

public addbotmenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //adding a survivor bot
			{
				new survivorbot = CreateFakeClient("survivor bot");
				ChangeClientTeam(survivorbot,2);
				DispatchKeyValue(survivorbot,"classname","SurvivorBot");
				DispatchSpawn(survivorbot);
				//now to make a timer to kick the client
				CreateTimer(1.0, SurvivorKicker,survivorbot);
			}
		}
	}
}

public Action:SurvivorKicker(Handle:timer, any:value)
{
	KickClient(value,"survivor bot");
	return Plugin_Continue;
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(double_item_on) == 1)
	{
		CreateTimer(3.0, UpdateCounts, 0);
	}	
}

public Action:UpdateCounts(Handle:timer)
{

	// Increases map spawned entity count.
	UpdateEntCount("weapon_autoshotgun_spawn","17");
	UpdateEntCount("weapon_hunting_rifle_spawn","17");
	UpdateEntCount("weapon_pistol_spawn","17");
	UpdateEntCount("weapon_pistol_magnum_spawn","17");
	UpdateEntCount("weapon_pumpshotgun_spawn","17");
	UpdateEntCount("weapon_rifle_spawn","17");
	UpdateEntCount("weapon_rifle_ak47_spawn","17");
	UpdateEntCount("weapon_rifle_desert_spawn","17");
	UpdateEntCount("weapon_rifle_sg552_spawn","17");
	UpdateEntCount("weapon_shotgun_chrome_spawn","17");
	UpdateEntCount("weapon_shotgun_spas_spawn","17");
	UpdateEntCount("weapon_smg_spawn","17");
	UpdateEntCount("weapon_smg_mp5_spawn","17");
	UpdateEntCount("weapon_smg_silenced_spawn","17");
	UpdateEntCount("weapon_sniper_awp_spawn","17");
	UpdateEntCount("weapon_sniper_military_spawn","17");
	UpdateEntCount("weapon_sniper_scout_spawn","17");
	UpdateEntCount("weapon_rifle_m60_spawn", "8");
	UpdateEntCount("weapon_grenade_launcher_spawn", "8");
	UpdateEntCount("weapon_spawn", "17");    //random new l4d2 weapon

	UpdateEntCount("weapon_chainsaw_spawn", "8");
	UpdateEntCount("weapon_defibrillator_spawn", "8")
	UpdateEntCount("weapon_first_aid_kit_spawn", "8");
	UpdateEntCount("weapon_melee_spawn", "8");


	
	// pistol spawns come in two flavors stacks of 5, or multiple singles props
	UpdateEntCount("weapon_pistol_spawn", "16"); // defaults 1/4/5
	
	// StripAndChangeServerConVarInt("director_pain_pill_density", 12);  // default 6
	return Plugin_Handled;
	
}

public UpdateEntCount(const String:entname[], const String:count[])
{
	// LogAction(0, -1, "DEBUG:updateentcount");
	new edict_index = FindEntityByClassname(-1, entname);
	while(edict_index != -1)
	{
		DispatchKeyValue(edict_index, "count", count);
		edict_index = FindEntityByClassname(edict_index, entname);
	}
}