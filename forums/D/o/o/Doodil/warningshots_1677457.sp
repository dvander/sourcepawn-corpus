#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <cstrike> 
#include <sdktools>

#define VERSION "1.0"

new Handle:W_Weapon;
new Handle:W_HitAmount;
new Handle:W_Ratio;

new Handle:W_Array;

new shotAmount[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM Warning Shots[Rework]",
	author = "Doodil, Original Source by: Franc1sco Steam: franug",
	description = "Warning Shots for jail server",
	version = VERSION
};

public OnPluginStart()
{
	CreateConVar("sm_warningshots_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	W_Array = CreateArray(2,0);
	W_Ratio = CreateConVar("sm_warningshots_ratio","0.3","The ratio of warningshot weapons per player");
	W_Weapon = CreateConVar("sm_warningshots_weapon", "weapon_deagle", "warning weapon used");
	W_HitAmount = CreateConVar("sm_warningshots_hitamount", "3", "amount of hits that are warningshots");
	
	HookEvent("round_start",Event_RoundStart);
	HookEvent("round_end",Event_RoundEnd);
}

public numberOfCts()
{
	new number=0;
	for (new i=1;i<MaxClients+1;i++)
	{
		if (IsValidClient(i) && GetClientTeam(i)==CS_TEAM_CT)
		{
			number++;
		}
	}
	return number;
}

public Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	new size = GetArraySize(W_Array);
	for (new i=0;i<size;i++)
	{
		RemoveFromArray(W_Array,0);
	}
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	new random=0;
	new weapon=-1;
	new String:warning_weapon[32];
	GetConVarString(W_Weapon, warning_weapon, sizeof(warning_weapon));
	
	
	for (new i = 1;i<MaxClients+1;i++)
	{
		shotAmount[i]=0;
	}
	new weaponAmount =RoundToFloor(GetConVarFloat(W_Ratio) * numberOfCts());
	if (weaponAmount>numberOfCts())
	{
		weaponAmount = numberOfCts();
	}
	
	while (weaponAmount>0)
	{
		random = GetRandomInt(1,MaxClients);
		if(IsValidClient(random)&&GetClientTeam(random)==CS_TEAM_CT && shotAmount[random]==0)
		{
			weapon = GetPlayerWeaponSlot(random,CS_SLOT_SECONDARY);
			if (weapon != -1) 
			{
				CS_DropWeapon(random,weapon,true);
			}
			shotAmount[random]=GetConVarInt(W_HitAmount);
			GivePlayerItem(random,warning_weapon);
			weaponAmount--;
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, HookTraceAttack);
	SDKHook(client, SDKHook_WeaponDrop, HookWeaponDrop);
	SDKHook(client, SDKHook_WeaponCanUse, HookWeaponPickup);
}

public Action:HookWeaponPickup(client,weapon)
{
	new String:szWeapon[32];
	GetEdictClassname(weapon, szWeapon, sizeof(szWeapon));

	new String:warning_weapon[32];
	GetConVarString(W_Weapon, warning_weapon, sizeof(warning_weapon));

	if(!StrEqual(szWeapon, warning_weapon))
		return Plugin_Continue;
	
	new index = FindValueInArray(W_Array,weapon);
	if (index >= 0)
	{
		if (GetClientTeam(client)==CS_TEAM_T)
			return Plugin_Handled;
		
		if (GetClientTeam(client)==CS_TEAM_CT)
		{
			shotAmount[client]=GetArrayCell(W_Array,index,1);
			RemoveFromArray(W_Array,index);
		}
	}
	
	return Plugin_Continue;
}

public Action:HookWeaponDrop(client,weapon)
{
	new String:szWeapon[32];
	GetEdictClassname(weapon, szWeapon, sizeof(szWeapon));

	new String:warning_weapon[32];
	GetConVarString(W_Weapon, warning_weapon, sizeof(warning_weapon));

	if(!StrEqual(szWeapon, warning_weapon))
		return Plugin_Continue;

	if(GetClientTeam(client)==CS_TEAM_CT && shotAmount[client]>0)
	{
		new index = PushArrayCell(W_Array,weapon);
		SetArrayCell(W_Array,index,shotAmount[client],1);
		
		shotAmount[client]=0;
	}
	
	return Plugin_Continue;
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
		return false; 
	 
	return true; 
}

public Action:HookTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, HitGroup)
{
	   if(!attacker || !IsValidClient(attacker)) // invalid attacker
			  return Plugin_Continue;

	   if(!victim || !IsValidClient(victim)) // invalid victim
			  return Plugin_Continue;


	   if (GetClientTeam(attacker) != CS_TEAM_CT || GetClientTeam(victim) != CS_TEAM_T)
			  return Plugin_Continue;

	   new String:szWeapon[32];
	   GetClientWeapon(attacker, szWeapon, sizeof(szWeapon));

	   new String:warning_weapon[32];
	   GetConVarString(W_Weapon, warning_weapon, sizeof(warning_weapon));

	   if(!StrEqual(szWeapon, warning_weapon))
			  return Plugin_Continue;

	   if(HitGroup == 1) // headshot
			  return Plugin_Continue;

	   // nota: como es pagina inglesa tengo que publicarlo aqui en ingles por defecto :s (english translate: in this web is english for default)
	   //
	   //PrintToChat(victim, "\x04[SM_WarningShots] \x01El guardia \x03%N \x01 te ha dado un disparo de aviso!", attacker); // en español
	   //PrintToChat(attacker, "\x04[SM_WarningShots] \x01Has dado un disparo de aviso al prisionero \x03%N \x01!", victim); // en español
	   if (shotAmount[attacker]>0)
	   {
			PrintToChat(victim, "\x04[SM_WarningShots] \x01The guard \x03%N \x01 has given you a warning shot", attacker); // english
			PrintToChat(attacker, "\x04[SM_WarningShots] \x01You have given a warning shot to prisoner \x03%N \x01", victim); // english

			FakeClientCommand(victim, "drop");

			damage = 0.0;
			shotAmount[attacker]--;
			return Plugin_Changed;
		}
		
		return Plugin_Continue;
}
// me encanta scriptear :)
// y a ti no?