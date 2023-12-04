#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define INFO_NAME "Left 4 Dead 2 Cheat Survivor Bot"
#define INFO_AUTHOR "Randerion"
#define INFO_DESCRIPTION "Modify Survivor bot Ability."
#define INFO_VERSION "0.1a"
#define INFO_URL "https://steamcommunity.com/id/HaoJun0823/"

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

new WeaponReload[MAXPLAYERS+1];
new WeaponReloadCount;

new Handle:SurvivorBotHealthMul=INVALID_HANDLE;
new Handle:SurvivorBotInfiniteAmmo=INVALID_HANDLE;
new Handle:SurvivorBotWeaponSpeedMul=INVALID_HANDLE;
new Handle:SurvivorBotMeleeSpeedMul=INVALID_HANDLE;
new Handle:SurvivorBotMoveSpeedMul=INVALID_HANDLE;
new Handle:SurvivorBotGravity=INVALID_HANDLE;

public Plugin:myinfo=
{
	name = INFO_NAME,
	author = INFO_AUTHOR,
	description = INFO_DESCRIPTION,
	version = INFO_VERSION,
	url = INFO_URL
};

public OnPluginStart()
{

	AutoExecConfig(true, "l4d2_cheat_survivor_bot");

	SurvivorBotHealthMul = CreateConVar("randerion_l4d2_survivor_bot_health_mul","2.0","Set survivor robot's life multiple.(default:1.0;more:>1.0;less:<1.0)",0,true,0.01);
	SurvivorBotInfiniteAmmo = CreateConVar("randerion_l4d2_survivor_bot_infinite_ammo","1","When the value is 1, make survivor robot have infinite ammo.(on:1;off:0)",0,true,0.0);
	SurvivorBotWeaponSpeedMul = CreateConVar("randerion_l4d2_survivor_bot_weapon_speed_mul","0.5","Set survivor robot's weapon shot speed.(default:1.0;faster:<1.0;slower:>1.0)",0,true,0.0);
	SurvivorBotMeleeSpeedMul = CreateConVar("randerion_l4d2_survivor_bot_melee_speed_mul","0.5","Set survivor robot's melee attack speed.(default:1.0;faster:<1.0;slower:>1.0)",0,true,0.0);
	SurvivorBotMoveSpeedMul = CreateConVar("randerion_l4d2_survivor_bot_move_speed_mul","1.25","Set survivor robot's move speed multiple.(default:1.0;faster:>1.0;slower:<1.0)",0,true,0.1);
	SurvivorBotGravity = CreateConVar("randerion_l4d2_survivor_bot_gravity","1.0","Set survivor robot's gravity.(default:1.0;lighter:<1.0;heavier:>1.0)",0,true,0.0);
	
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("weapon_fire",WeaponFire);
	HookEvent("player_first_spawn",PlayerFirstSpawn);
	
}

public Action:PlayerFirstSpawn(Handle:event, String:event_name[], bool:dontBroadcast){
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsFakeClient(client))
    {
	
	//PrintToChat(client,"[CheatBot]%s %s has been enabled.\nCreate by %s.",INFO_NAME,INFO_VERSION,INFO_AUTHOR);
	//PrintToChat(client,"\nSurvivor Bot Status:\nHealth:%d\nWeapon Speed:%.2f%%\nMelee Speed:%.2f%%\nMove Speed:%.2f%%\nGravity:%.2f\n",100*GetConVarInt(SurvivorBotHealthMul),1.0/GetConVarFloat(SurvivorBotWeaponSpeedMul)*100,1.0/GetConVarFloat(SurvivorBotMeleeSpeedMul)*100,100*GetConVarFloat(SurvivorBotMoveSpeedMul),GetConVarFloat(SurvivorBotGravity));
	if(GetConVarInt(SurvivorBotInfiniteAmmo)==1)
	{
		//PrintToChat(client,"Survivor Bot have infinite ammo.");
	}else
	{
		//PrintToChat(client,"Survivor Bot don't have infinite ammo.");
	}
	}
	//PrintToChat(client,"[CheatBot]Have Fun:)");
	return Plugin_Continue;
	
}

public OnGameFrame()
{

	if(WeaponReloadCount>0){

	
	
	decl ent;
	
	for(new i = 0; i < WeaponReloadCount; i++)
	{
		ent = WeaponReload[i];
		if(IsValidEdict(ent) && IsValidEntity(ent))
		{
			decl String:entclass[65];
			GetEdictClassname(ent, entclass, sizeof(entclass));
			
			if(StrContains(entclass, "weapon")>=0)
			{
				new Float:Mul = GetConVarFloat(SurvivorBotWeaponSpeedMul);
				if(StrContains(entclass, "melee")>=0){
					Mul = GetConVarFloat(SurvivorBotMeleeSpeedMul);
				}
				
				SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", Mul);
				new Float:ETime = GetGameTime();
				new Float:time = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack") - ETime)*Mul;
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", time + ETime);
				time = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack") - ETime)*Mul;
				SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", time + ETime);
				CreateTimer(time, NormalWeaponSpeed, ent);
			}
		}
	}
	
	WeaponReloadCount=0;
	
	}
}

public Action:NormalWeaponSpeed(Handle:timer, any:ent)
{
	KillTimer(timer);
	timer = INVALID_HANDLE;

	if(IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if(StrContains(entclass, "weapon")>=0)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 1.0);
		}
	}
	return Plugin_Handled;
}




public Action:PlayerSpawn(Handle:event,String:event_name[],bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(IsFakeClient(target) && GetClientTeam(target) == TEAM_SURVIVORS){
		
		SetEntProp(target,Prop_Data,"m_iMaxHealth",RoundToNearest(GetEntProp(target,Prop_Data,"m_iMaxHealth")*GetConVarFloat(SurvivorBotHealthMul)));
		SetEntProp(target,Prop_Data,"m_iHealth",RoundToNearest(GetEntProp(target,Prop_Data,"m_iHealth")*GetConVarFloat(SurvivorBotHealthMul)));
	
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue",GetEntPropFloat(target,Prop_Data,"m_flLaggedMovementValue")*GetConVarFloat(SurvivorBotMoveSpeedMul));
		SetEntityGravity(target, GetConVarFloat(SurvivorBotGravity));

	
	}

	return Plugin_Continue;

}

public Action:WeaponFire(Handle:event,String:event_name[],bool:dontBroadcast)
{


	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(target) && GetClientTeam(target) == TEAM_SURVIVORS){
		new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		
		if(ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")>=0)
			{
				
				WeaponReload[WeaponReloadCount] = ent;
				WeaponReloadCount++;
			}else if(ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")<0))
		{
			
				WeaponReload[WeaponReloadCount] = ent;
				WeaponReloadCount++;
			
				if(GetConVarInt(SurvivorBotInfiniteAmmo) == 1){
					SetEntProp(ent, Prop_Send, "m_iClip1", GetEntProp(ent, Prop_Send, "m_iClip1")+1);
				}
			
			
			
		}
	
	}
	
	return Plugin_Continue;
	
}	
