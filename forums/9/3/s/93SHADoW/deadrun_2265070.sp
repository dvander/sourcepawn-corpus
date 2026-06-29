#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new bool:isBlockBuildables;
new Handle:KSpreeTimer[MAXPLAYERS+1];
new KSpreeCount[MAXPLAYERS+1];
new Handle:SeeTimer;
#define RESTORE_HUD		(1 << 0)
#define RESTORE_DMG		(1 << 1)
#define RESTORE_SPAWN	0
new need_restores[MAXPLAYERS+1];
new bool:no_damage[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "Freak Fortress 2: Dead Run Boss",
	author = "RainBolt Dash",
};

public OnPluginStart2()
{
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	return Plugin_Continue;
}

public Action:Timer_See(Handle:timer,any:index)
{
	static Float:pos[3];
	static Float:pos2[3];
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (Boss<1 || !IsPlayerAlive(Boss))
	{
		SeeTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos2); 
	if (GetVectorDistance(pos,pos2)<100)
	{
		new String:s[PLATFORM_MAX_PATH];
		if (FF2_RandomSound("sound_move",s,PLATFORM_MAX_PATH,index))
		{
			EmitSoundToAll(s);
			EmitSoundToAll(s);
		}
		else
		{
			SeeTimer = INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	pos[0]=pos2[0];
	pos[1]=pos2[1];
	pos[2]=pos2[2];
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	need_restores[client] = RESTORE_SPAWN;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || !IsValidEdict(client)) return Plugin_Continue;
	
	if (need_restores[client] & RESTORE_HUD)
	{
		FF2_SetFF2flags(client,FF2_GetFF2flags(client) & ~FF2FLAG_HUDDISABLED);
		need_restores[client] &= ~RESTORE_HUD;
	}
	if (need_restores[client] & RESTORE_DMG)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		need_restores[client] &= ~RESTORE_DMG;
	}
	
	new index=FF2_GetBossIndex(client);
	if (index == -1) return Plugin_Continue;
	if (!index && FF2_HasAbility(index,this_plugin_name,"deadrun_lines"))
		SeeTimer = CreateTimer(12.0,Timer_See,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (FF2_HasAbility(index,this_plugin_name,"deadrun_no_any_damage"))
	{	
		if (GetEntProp(client, Prop_Data, "m_takedamage") == 2)
			need_restores[client] |= RESTORE_DMG;
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
	}
	else
		no_damage[index]=FF2_HasAbility(index,this_plugin_name,"deadrun_no_damage");
	if (FF2_HasAbility(index,this_plugin_name,"deadrun_no_hud_for_all"))
	{	
		new flags;
		for (new client2 = 1; client2 <= MaxClients ; client2++)
		{
			flags = FF2_GetFF2flags(client2);
			if (!(flags & FF2FLAG_HUDDISABLED))
				need_restores[client2] |= RESTORE_HUD;
			FF2_SetFF2flags(client2,flags | FF2FLAG_HUDDISABLED);
		}
	}
	if (FF2_HasAbility(index,this_plugin_name,"deadrun_block_buildables"))
		isBlockBuildables = true;
	else
		isBlockBuildables = false;
	if (SeeTimer != INVALID_HANDLE)
		KillTimer(SeeTimer);
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker > 0 && attacker <= MaxClients)
	{
		new index = FF2_GetBossIndex(client);
		if (index != -1 && no_damage[index])
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsValidEdict(client))
		OnPlayerDeath(client,GetClientOfUserId(GetEventInt(event, "attacker")),GetEventBool(event, "feign_death"));
	return Plugin_Continue;
}

OnPlayerDeath(client,attacker,bool:fake = false)
{
	if (FF2_GetBossIndex(client)!=-1) return;
	new index=FF2_GetBossIndex(attacker);
	if (index == -1) return;
	if (!FF2_HasAbility(index,this_plugin_name,"deadrun_lines")) return;
	
	new String:s[PLATFORM_MAX_PATH];
	if (fake && FF2_RandomSound("sound_spy_invis",s,PLATFORM_MAX_PATH,index))
	{
		EmitSoundToAll(s);
		EmitSoundToAll(s);
		return;
	}	
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) && FF2_RandomSound("sound_kill_spy",s,PLATFORM_MAX_PATH,index))
	{
		EmitSoundToAll(s);
		EmitSoundToAll(s);
		return;
	}
	
	KSpreeCount[index]++;
	if (!KSpreeTimer[index])
		KSpreeTimer[index] = CreateTimer(3.0,Timer_KSpree,index);
	if (KSpreeCount[index] == 4) 
	{
		if (FF2_RandomSound("sound_kspree",s,PLATFORM_MAX_PATH,index))
		{
			EmitSoundToAll(s);
			EmitSoundToAll(s);
		}
		KSpreeCount[index] = 0;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (isBlockBuildables && TF2_GetPlayerClass(client) == TFClass_Engineer &&
		GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon") > GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) &&
		buttons & IN_ATTACK )
	{
		buttons&=~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}


public Action:Timer_KSpree(Handle:timer,any:index)
{
	KSpreeCount[index] = 0;
	KSpreeTimer[index] = INVALID_HANDLE;
	return Plugin_Continue;
}

public Action:FF2_OnLoadCharacterSet(&CharSetNum, String:CharSetName[] )
{
	new String:s[16];
	GetNextMap(s,16);
	if (!StrContains(s,"vsh_dr_") || !StrContains(s,"dr_") || !StrContains(s,"deadrun_"))
	{
		strcopy(CharSetName,32,"Dead Run");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}