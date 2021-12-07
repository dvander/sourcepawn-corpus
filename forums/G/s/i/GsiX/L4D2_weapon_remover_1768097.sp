#include <sourcemod>
#include <sdktools>

#define MaxClients 32
#define PLUGIN_VERSION "1.0"
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE
#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY

#pragma semicolon 1

//plugin info
public Plugin:myinfo = 
{
	name		= " L4D2 Weapon Remover",
	author		= " GsiX ",
	description	= " Remove Item On Spawn On Map ",
	version		= PLUGIN_VERSION,
	url			= ""
}

//cvar handles
new Handle:WRenabled;
new Handle:removeAmmoUpgrades;
new Handle:removeChainsaws;
new Handle:removeLauncher;
new Handle:removeM60;
new Handle:removeLaser;
new Handle:removeHealthKit;
new Handle:removeMedKit;
new Handle:removeThrowable;
new Handle:removeT3;
new Handle:removeT2;
new Handle:removeT1;
new Handle:removeMelee;
new Handle:removeAmmoPile;
new Handle:itemGiverMed;
new Handle:itemGiverRandom;

//other handles
//new Float:Saferoom[3];

//plugin setup
public OnPluginStart()
{
	//require Left 4 Dead 2
	//decl String:Game[64];
	//GetGameFolderName(Game, sizeof(Game));
	//if(!StrEqual(Game, "left4dead2", false))
	//{
	//	SetFailState("This plugin only supports Left 4 Dead 2.");
	//}
	
	//register cvars
	WRenabled = CreateConVar("l4d2_WR_enabled", "1", "Enable Plugin.", FCVAR_PLUGIN);
	CreateConVar("l4d2_Weapon_Remover_Version", PLUGIN_VERSION, "Plugin Version.", FCVAR_PLUGIN);
	removeAmmoUpgrades = CreateConVar("l4d2_ammo_upgrades_remove_mp", "1", "remove upgrade explosive, incendiary ammo. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeChainsaws = CreateConVar("l4d2_chainsaw_remove_mp", "1", "Remove Chainsaws. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLauncher = CreateConVar("l4d2_launcher_remove_mp", "1", "Remove grenade launchers. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeM60 = CreateConVar("l4d2_m60_remove_mp", "1", "Remove M60 rifles. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeLaser = CreateConVar("l4d2_laser_remove_mp", "1", "Remove Laser Sights. (0=Disable, 1= Enable)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeHealthKit = CreateConVar("l4d2_healthkit_remove_mp", "1", "Remove all healt kit. eg. pain pills(0=Disable, 1= Enable)", FCVAR_PLUGIN); //not ready
	removeMedKit = CreateConVar("l4d2_Medkit_remove_mp", "0", "Remove all Med kit. (0=Disable, 1= Enable)", FCVAR_PLUGIN); //not ready
	removeAmmoPile = CreateConVar("l4d2_ammo_pile_remove_mp", "0", "Remove ammo pile. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeThrowable = CreateConVar("l4d2_throwable_remove_mp", "1", "Remove throwable item eg. molotov. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT3 = CreateConVar("l4d2_t3weapon_remove_mp", "1", "Remove all T3 weapon. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT2 = CreateConVar("l4d2_t2weapon_remove_mp", "1", "Remove all T2 weapon. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeT1 = CreateConVar("l4d2_t1weapon_remove_mp", "1", "Remove all T1 weapon. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	removeMelee = CreateConVar("l4d2_melee_remove_mp", "1", "Remove All Melee weapon. (0=Disable, 1= Enable)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	itemGiverMed = CreateConVar("l4d2_itemGiverMed_mp", "5", "Give MedKit to all player on round start. (0=Disable, 1 or above is qty. of items)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	itemGiverRandom = CreateConVar("l4d2_itemGiverRandom_mp", "1", "Give secondary weapon on round start. (0=Disable, 1 = enabled)",FCVAR_NOTIFY | FCVAR_PLUGIN);
	
	//create and execute config file under cfg/sourcemod
	AutoExecConfig(true, "l4d2_weapon_remover");
	
	//enable plugin if cvar is enabled
	if(GetConVarInt(WRenabled) == 1)
	{
		//event hooks
		HookEvent("round_start", executePlugin); //execute hardcore methods
		HookConVarChange(WRenabled, executePlugin2); //same as round start hook
		HookEvent("round_start", Event_RoundStart_supply, EventHookMode_Post);
	}
}

//HardCore hooks
public Action:executePlugin(Handle:event, const String:name[], bool:dontBroadcast)
{
	return executePluginRealism();
}

public executePlugin2(Handle:convar, const String:oldValue[], const String:newValue[])
{
	executePluginRealism();
}

//HardCore methods
Action:executePluginRealism()
{
	//replace or remove items
	new EntCount = GetEntityCount();
	new String:EdictName[128];
	
	for(new i = 0; i <= EntCount; i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, EdictName, sizeof(EdictName));
			//remove heal kits
			if(GetConVarInt(removeHealthKit) == 1)
			{
				if(StrContains(EdictName, "weapon_pain_pills", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_adrenaline", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_defibrillator", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove Med kits
			if(GetConVarInt(removeMedKit) == 1)
			{
				if(StrContains(EdictName, "weapon_first_aid_kit", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove explosive and incendiary ammo
			if(GetConVarInt(removeAmmoUpgrades) == 1)
			{
				if(StrContains(EdictName, "weapon_upgradepack_explosive", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_upgradepack_incendiary", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove ammo pile
			if(GetConVarInt(removeAmmoPile) == 1)
			{
				if(StrContains(EdictName, "weapon_ammo_spawn", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove chainsaws
			if(GetConVarInt(removeChainsaws) == 1)
			{
				if(StrContains(EdictName, "weapon_chainsaw", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove grenade launchers
			if(GetConVarInt(removeLauncher) == 1)
			{
				if(StrContains(EdictName, "weapon_grenade", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove m60 weapon
			if(GetConVarInt(removeM60) == 1)
			{
				if(StrContains(EdictName, "weapon_rifle_m60", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove throwable
			if(GetConVarInt(removeThrowable) == 1)
			{
				if(StrContains(EdictName, "weapon_pipe_bomb", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_molotov", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_vomitjar", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove T3 ewapon
			if(GetConVarInt(removeT3) == 1)
			{
				if(StrContains(EdictName, "weapon_sniper_awp", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_sniper_scout", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_shotgun_spas", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove T2 weapon
			if(GetConVarInt(removeT2) == 1)
			{
				if(StrContains(EdictName, "weapon_rifle", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_rifle_ak47", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_rifle_desert", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_autoshotgun", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_sniper_military", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_spawn", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}		
			
			//remove T1 weapon
			if(GetConVarInt(removeT1) == 1)
			{
				if(StrContains(EdictName, "weapon_hunting_rifle", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_shotgun_chrome", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_pumpshotgun", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_smg", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_smg_silenced", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_smg_mp5", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove Melee weapon
			if(GetConVarInt(removeMelee) == 1)
			{
				if(StrContains(EdictName, "weapon_fireaxe", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_frying_pan", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_machete", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_baseball_bat", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_crowbar", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_cricket_bat", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_katana", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_electric_guitar", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_hunting_knife", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_golfclub", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_riotshield", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_tonfa", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
				if(StrContains(EdictName, "weapon_melee", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
			
			//remove laser sights
			if(GetConVarInt(removeLaser) == 1)
			{
				if(StrContains(EdictName, "weapon_upgradepack_laser", false) != -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}
		}
	}
	return Plugin_Handled;
}
/////////////////////////////////////////////////////////////////////////////////
public Event_RoundStart_supply(Handle:event, const String:name[], bool:dontBroadcast)
{ 	
	CreateTimer(5.0, GiveSupplyDelay, DEFAULT_TIMER_FLAGS);
}

public Action:GiveSupplyDelay(Handle:timer, any:value)
{
	GiveMeItem();
}

GiveMeItem()
{
	new MedQty = GetConVarInt(itemGiverMed);
	for (new client = 1; client <= MaxClients; client++)
	{
		if ((IsClientInGame(client)) && (GetClientTeam(client)==2))
		{
			if (GetConVarInt(itemGiverMed) != 0)
			{
				for(new n = 1; n <= MedQty; n++)
				{
					GiveItem(client, "weapon_first_aid_kit");
				}
			}
			if (GetConVarInt(itemGiverRandom) == 1)
			{
				new weaponIndexZero = GetPlayerWeaponSlot(client, 0);
				new weaponIndexTwo = GetPlayerWeaponSlot(client, 2);
				new weaponIndexThree = GetPlayerWeaponSlot(client, 3);
				new weaponIndexFour = GetPlayerWeaponSlot(client, 4);
				if((weaponIndexZero == -1) && (weaponIndexTwo == -1) && (weaponIndexThree == -1) && (weaponIndexFour == -1))
				{				
					new itemRDM = GetRandomInt(0, 11);
					if(itemRDM==0) {
					GiveItem(client, "weapon_pistol");
					}
					else if(itemRDM==1) {
						GiveItem(client, "weapon_pistol_magnum");
					}
					else if(itemRDM==2) {
						GiveItem(client, "weapon_chainsaw");
					}
					else if(itemRDM==3) {
						GiveItem(client, "weapon_katana");
					}
					else if(itemRDM==4) {
						GiveItem(client, "weapon_baseball_bat");
					}
					else if(itemRDM==5) {
						GiveItem(client, "weapon_hunting_knife");
					}
					else if(itemRDM==6) {
						GiveItem(client, "weapon_machete");
					}
					else if(itemRDM==7) {
						GiveItem(client, "weapon_tonfa");
					}
					else if(itemRDM==8) {
						GiveItem(client, "weapon_fireaxe");
					}
					else if(itemRDM==9) {
						GiveItem(client, "weapon_crowbar");
					}
					else if(itemRDM==10) {
						GiveItem(client, "weapon_golfclub");
					}
					else {
						GiveItem(client, "weapon_riotshield");
					}
				}
			}			
		}
	}
	return 0;
}

GiveItem(Client, String:Item[64])
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "give %s", Item);
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}



