#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2.1"
#define SMG 2
#define RIFLE 5
#define HUNTING_RIFLE 6
#define SMG_SILENCED 7
#define RIFLE_DESERT 9
#define SNIPER_MILITARY 10
#define RIFLE_AK47 26
#define SMG_MP5 33
#define RIFLE_SG552 34
#define SNIPER_AWP 35
#define SNIPER_SCOUT 36

new bool:AllBotSet = false

public Plugin:myinfo = 
{
	name = "[L4D2] Weapon Unlock",
	author = "Crimson_Fox",
	description = "Unlocks the hidden CSS weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1041458"
}

public OnPluginStart()
{
	//Look up what game we're running,
	decl String:game[64]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	CreateConVar("l4d2_WeaponUnlock", PLUGIN_VERSION, "Weapon Unlock version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	//Initialize the hidden weapons so we can use them.
	InitializeWeapons()
	HookEvent("round_start", Event_RoundStart);
}

public InitializeWeapons()
{
	//Remember if sb_all_bot_team is enabled.
	if (GetConVarInt(FindConVar("sb_all_bot_team")) == 1) AllBotSet = true
	//Initialize the weapons by spawning a bot,
	SetConVarInt(FindConVar("sb_all_bot_team"), 1)
	ServerCommand("sb_add")
	//and giving it the hidden weapons after a slight delay.
	CreateTimer(0.1, InitializeWeaponsDelay)
}

public Action:InitializeWeaponsDelay(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetClientTeam(i) == 2)
		{
			new flags = GetCommandFlags("give")
			SetCommandFlags("give", flags & ~FCVAR_CHEAT)
			FakeClientCommand(i, "give weapon_rifle_sg552")
			RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0))
			FakeClientCommand(i, "give weapon_smg_mp5")
			RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0))
			FakeClientCommand(i, "give weapon_sniper_awp")
			RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0))
			FakeClientCommand(i, "give weapon_sniper_scout")
			RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0))
			SetCommandFlags("give", flags | FCVAR_CHEAT)
			SetConVarInt(FindConVar("sb_all_bot_team"), 0)
			//If all bot team was enabled, reenable it.
			if (AllBotSet == true) SetConVarInt(FindConVar("sb_all_bot_team"), 1)
			return
		}
	}
}

public OnMapStart()
{
	//Precache hidden weapon models to avoid crashes.
	PrecacheModel("models/v_models/v_rif_sg552.mdl");
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	PrecacheModel("models/v_models/v_smg_mp5.mdl");
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	PrecacheModel("models/v_models/v_snip_awp.mdl");
    PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	PrecacheModel("models/v_models/v_snip_scout.mdl");
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	
}
	
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, RoundWeaponCheck);
}
public Add_sg552(target)
{
	//Since there's a total of 4 rifles, there's a 1 in 4 chance that it could have been the sg552.
	if (GetRandomInt(1, 4) == 1)
	{
		//Create a weapon to use as reference for the model index.
		new i_ModelSource = CreateEntityByName("weapon_rifle_sg552")
		DispatchSpawn(i_ModelSource)
		//Change the target spawn point's weaponID and model.
		SetEntProp(target, Prop_Send, "m_weaponID", RIFLE_SG552)
		SetEntProp(target, Prop_Send, "m_nModelIndex", GetEntProp(i_ModelSource, Prop_Send, "m_nModelIndex"))
		//Delete the reference weapon. 
		AcceptEntityInput(i_ModelSource, "Kill")
	}
}

public Add_awp(target)
{
	//Since there's a total of 2 tier 2 sniper rifles, there's a 1 in 2 chance that it could have been the awp.
	if (GetRandomInt(1, 2) == 1)
	{
		//Create a weapon to use as reference for the model index.
		new i_ModelSource = CreateEntityByName("weapon_sniper_awp")
		DispatchSpawn(i_ModelSource)
		//Change the target spawn point's weaponID and model.
		SetEntProp(target, Prop_Send, "m_weaponID", SNIPER_AWP)
		SetEntProp(target, Prop_Send, "m_nModelIndex", GetEntProp(i_ModelSource, Prop_Send, "m_nModelIndex"))
		//Delete the reference weapon. 
		AcceptEntityInput(i_ModelSource, "Kill")
	}
}

public Add_scout(target)
{
	//Since there's a total of 2 tier 1 sniper rifles, there's a 1 in 2 chance that it could have been the scout.
	if (GetRandomInt(1, 2) == 1)
	{
		//Create a weapon to use as reference for the model index.
		new i_ModelSource = CreateEntityByName("weapon_sniper_scout")
		DispatchSpawn(i_ModelSource)
		//Change the target spawn point's weaponID and model.
		SetEntProp(target, Prop_Send, "m_weaponID", SNIPER_SCOUT)
		SetEntProp(target, Prop_Send, "m_nModelIndex", GetEntProp(i_ModelSource, Prop_Send, "m_nModelIndex"))
		//Delete the reference weapon. 
		AcceptEntityInput(i_ModelSource, "Kill")
	}
}

public Add_mp5(target)
{
	//Since there's a total of 3 submachine guns, there's a 1 in 3 chance that it could have been the mp5.
	if (GetRandomInt(1, 3) == 1)
	{
		//Create a weapon to use as reference for the model index.
		new i_ModelSource = CreateEntityByName("weapon_smg_mp5")
		DispatchSpawn(i_ModelSource)
		//Change the target spawn point's weaponID and model.
		SetEntProp(target, Prop_Send, "m_weaponID", SMG_MP5)
		SetEntProp(target, Prop_Send, "m_nModelIndex", GetEntProp(i_ModelSource, Prop_Send, "m_nModelIndex"))
		//Delete the reference weapon. 
		AcceptEntityInput(i_ModelSource, "Kill")
	}
}
public AddWeapons()
{
	//Search through the entities,
	new String:EdictClassName[128]
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			//and look for dynamic weapon spawns.
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrContains(EdictClassName, "weapon_spawn", false) != -1)
			{
				//If you find one then look up the weapon ID,
				new WeaponID = GetEntProp(i, Prop_Send, "m_weaponID")
				//and modify it as such:
				switch(WeaponID)
				{
					case RIFLE_AK47: Add_sg552(i);
					case SNIPER_MILITARY: Add_awp(i);
					case RIFLE_DESERT: Add_sg552(i);
					case SMG_SILENCED: Add_mp5(i);
					case HUNTING_RIFLE: Add_scout(i);
					case RIFLE: Add_sg552(i);
					case SMG: Add_mp5(i);					
				}
			}
		}
	}
}
public Action:RoundWeaponCheck(Handle:timer)
{
	if(GetTeamClientCount(2) > 0){
		AddWeapons();
	}else{
		CreateTimer(0.5, RoundWeaponCheck);
	}
}
