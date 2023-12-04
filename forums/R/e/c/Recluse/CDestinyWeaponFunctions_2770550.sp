#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <events>

#pragma semicolon 1

public OnClientPutInServer(client)
{
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
    {
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action:Event_Death(Handle:Event, const String:strName[], bool DontBroadcast)
{
	new killer=GetClientOfUserId(GetEventInt(Event, "attacker"));
	new victim=GetClientOfUserId(GetEventInt(Event, "victim"));
	new client=GetClientOfUserId(GetEventInt(Event, "client"));
	if (victim != killer)
	{
		new CWeapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(CWeapon))
		{
			new Address:CrowdCon = TF2Attrib_GetByName(CWeapon, "obsolete ammo penalty");
			if(CrowdCon!=Address_Null)
			{
				CreateTimer(8.0, Timer_CrowdCon, CWeapon);
				TF2Attrib_SetByName(CWeapon, "damage bonus HIDDEN", 1.55);
				TF2Attrib_SetByName(CWeapon, "halloween fire rate bonus", 0.85);
			}
		}
		new Chaperone = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(Chaperone))
		{
			new Address:Roadborn = TF2Attrib_GetByName(Chaperone, "is commodity");
			if(Roadborn!=Address_Null)
			{
				CreateTimer(8.0, Timer_RoadBorn, Chaperone);
				TF2Attrib_SetByName(Chaperone, "headshot damage increase", 6.00);
				TF2Attrib_SetByName(Chaperone, "crit_dmg_falloff", 0.00);
				TF2Attrib_SetByName(Chaperone, "single wep deploy time decreased", 0.50);
				TF2Attrib_SetByName(Chaperone, "switch from wep deploy time decreased", 0.50);
				TF2Attrib_SetByName(Chaperone, "is australium item", 1.00);
				TF2Attrib_SetByName(Chaperone, "killstreak idleeffect", 4.00);
			}
		}
		new BaseWep = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(BaseWep))
		{
			new Address:CrowdControl = TF2Attrib_GetByName(BaseWep, "never craftable");
			if(CrowdControl!=Address_Null)
			{
				CreateTimer(5.0, Timer_CrowdControl, BaseWep);
				TF2Attrib_SetByName(BaseWep, "damage bonus HIDDEN", 1.70);
			}
		}
		new BaseWep1 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(BaseWep1))
		{
			new Address:FeedingFrenzy = TF2Attrib_GetByName(BaseWep1, "kill eater 3");
			if(FeedingFrenzy!=Address_Null)
			{
				CreateTimer(3.0, Timer_FeedingFrenzy, BaseWep1);
				TF2Attrib_SetByName(BaseWep1, "reload time increased hidden", 0.55);
			}
		}
		new Duality = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(Duality))
		{
			new Address:SlugActive = TF2Attrib_GetByName(Duality, "bot custom jump particle");
			if(SlugActive!=Address_Null)
			{
				CreateTimer(10.0, Timer_SlugMode, Duality);
				TF2Attrib_SetByName(Duality, "weapon spread bonus", 0.01);
				TF2Attrib_SetByName(Duality, "mod ammo per shot", 2.0);
				TF2Attrib_SetByName(Duality, "damage bonus HIDDEN", 1.40);
				TF2Attrib_SetByName(Duality, "airblast pushback scale", 1.20);
				TF2Attrib_SetByName(Duality, "fire rate penalty HIDDEN", 1.10);
				TF2Attrib_SetByName(Duality, "cannot delete", 1.0);
				TF2Attrib_SetByName(Duality, "killstreak idleeffect", 2.00);
				TF2Attrib_SetByName(Duality, "crit_dmg_falloff", 1.00);
			}
		}
		new Recluse = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		new Activator = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		new Secondary=GetPlayerWeaponSlot(killer,1);
		if (IsValidEntity(Recluse))
		{
			new Address:MasterOfArmsMinor = TF2Attrib_GetByName(Recluse, "force center wrap");
			if (MasterOfArmsMinor != Address_Null)
			{
				CreateTimer(5.0, Timer_MOAMinor, Recluse);
				TF2Attrib_SetByName(Recluse, "damage bonus HIDDEN", 1.45);
				TF2Attrib_SetByName(Recluse, "single wep deploy time decreased", 0.70);
			}
		}
		if (IsValidEntity(Activator))
		{
			new Address:MasterOfArmsMinor = TF2Attrib_GetByName(Secondary, "force center wrap");
			new Address:MasterOfArmsMajor = TF2Attrib_GetByName(Activator, "loot list name");
			if (MasterOfArmsMajor != Address_Null)
			{
				if (MasterOfArmsMinor != Address_Null)
				{
					CreateTimer(7.0, Timer_MOAMajor, Secondary);
					TF2Attrib_SetByName(Secondary, "damage bonus HIDDEN", 2.15);
					TF2Attrib_SetByName(Secondary, "single wep deploy time decreased", 0.40);
				}
			}
		}		
		new type = GetEventInt(Event, "customkill");
		if (type == 1)
		{
			new BaseWep2 = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(BaseWep2))
			{
				new Address:Outlaw = TF2Attrib_GetByName(BaseWep2, "item in slot 1");
				if(Outlaw!=Address_Null)
				{
					CreateTimer(3.0, Timer_Outlaw, BaseWep2);
					TF2Attrib_SetByName(BaseWep2, "reload time increased hidden", 0.40);
				}
			}
		}
	}			
	return Plugin_Changed;
}
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (hitgroup == 1)
	{
		new Chaperone = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(Chaperone))
		{
			new Address:ChapHeadshots = TF2Attrib_GetByName(Chaperone, "cannot delete");
			if(ChapHeadshots != Address_Null)
			{
				damagetype |= DMG_USE_HITLOCATIONS;
			}
		}
	}
	return Plugin_Changed;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		TeleportEntity(particle, damagePosition, NULL_VECTOR, NULL_VECTOR);
	}
	new melee=GetPlayerWeaponSlot(attacker,2);
	if (victim != attacker)
	{
		new BaseWep3 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(BaseWep3))
		{
			new Address:VorpalWep = TF2Attrib_GetByName(BaseWep3, "item in slot 3");
			if(VorpalWep != Address_Null)
			{
				if(TF2_IsPlayerInCondition(victim, TFCond_Overhealed))
				{
					TF2Attrib_SetByName(BaseWep3, "damage bonus HIDDEN", 1.40);
				}
				else(TF2_IsPlayerInCondition(victim, TFCond_Overhealed));
				{
					TF2Attrib_RemoveByName(BaseWep3, "damage bonus HIDDEN");
				}
			}
			new BaseWep6 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(BaseWep6))
			{
				new Address:OneTwoPunch = TF2Attrib_GetByName(BaseWep6, "item in slot 8");
				if(OneTwoPunch != Address_Null)
				{
					CreateTimer(1.0, Timer_OneTwoPunch, melee);
					TF2Attrib_SetByName(melee, "single wep deploy time decreased", 0.50);	
					TF2Attrib_SetByName(melee, "damage bonus HIDDEN", 3.00);
					TF2Attrib_SetByName(melee, "item slot criteria 8", 1.00);
				}
			}
			new BaseWep7 = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(BaseWep7))
			{
				new Address:OneTwoPunchStop = TF2Attrib_GetByName(BaseWep7, "item slot criteria 8");
				if(OneTwoPunchStop != Address_Null)
				{
					TF2Attrib_RemoveByName(melee, "single wep deploy time decreased");	
					TF2Attrib_RemoveByName(melee, "damage bonus HIDDEN");
					TF2Attrib_RemoveByName(melee, "item slot criteria 8");
				}
			}
		}
	}
	return Plugin_Changed;
}
public Action:Timer_RoadBorn(Handle:Timer, any:Chaperone)
{
	if(IsValidEntity(Chaperone))
	{
		TF2Attrib_SetByName(Chaperone, "headshot damage increase", 4.00);
		TF2Attrib_SetByName(Chaperone, "crit_dmg_falloff", 1.00);
		TF2Attrib_SetByName(Chaperone, "single wep deploy time decreased", 1.00);
		TF2Attrib_SetByName(Chaperone, "switch from wep deploy time decreased", 0.50);
		TF2Attrib_SetByName(Chaperone, "is australium item", 0.00);
		TF2Attrib_SetByName(Chaperone, "killstreak idleeffect", 7.00);
	}
	return Plugin_Changed;
}
public Action:Timer_CrowdCon(Handle:Timer, any:CWeapon)
{
	if(IsValidEntity(CWeapon))
	{
		TF2Attrib_SetByName(CWeapon, "damage bonus HIDDEN", 1.00);
		TF2Attrib_SetByName(CWeapon, "halloween fire rate bonus", 1.00);
	}
	return Plugin_Changed;
}
public Action:Timer_CrowdControl(Handle:Timer, any:BaseWep)
{
	if(IsValidEntity(BaseWep))
	{
		TF2Attrib_SetByName(BaseWep, "damage bonus HIDDEN", 1.00);
	}
	return Plugin_Changed;
}
public Action:Timer_FeedingFrenzy(Handle:Timer, any:BaseWep1)
{
	if(IsValidEntity(BaseWep1))
	{
		TF2Attrib_RemoveByName(BaseWep1, "reload time increased hidden");
	}
	return Plugin_Changed;
}
public Action:Timer_SlugMode(Handle:Timer, any:Duality)
{
	if(IsValidEntity(Duality))
	{
		TF2Attrib_SetByName(Duality, "weapon spread bonus", 0.70);
		TF2Attrib_RemoveByName(Duality, "mod ammo per shot");
		TF2Attrib_RemoveByName(Duality, "damage bonus HIDDEN");
		TF2Attrib_RemoveByName(Duality, "airblast pushback scale");
		TF2Attrib_RemoveByName(Duality, "fire rate penalty HIDDEN");
		TF2Attrib_RemoveByName(Duality, "cannot delete");
		TF2Attrib_SetByName(Duality, "killstreak idleeffect", 7.00);
		TF2Attrib_RemoveByName(Duality, "crit_dmg_falloff");
	}
	return Plugin_Changed;
}
public Action:Timer_Outlaw(Handle:Timer, any:BaseWep2)
{
	if(IsValidEntity(BaseWep2))
	{
		TF2Attrib_RemoveByName(BaseWep2, "reload time increased hidden");
	}
	return Plugin_Changed;
}
public Action:Timer_OneTwoPunch(Handle:Timer, any:melee)
{
	if(IsValidEntity(melee))
	{
		TF2Attrib_RemoveByName(melee, "single wep deploy time decreased");	
		TF2Attrib_RemoveByName(melee, "damage bonus HIDDEN");
		TF2Attrib_RemoveByName(melee, "item slot criteria 8");
	}
	return Plugin_Changed;
}
public Action:Timer_MOAMinor(Handle:Timer, any:Recluse)
{
	if(IsValidEntity(Recluse))
	{
		TF2Attrib_RemoveByName(Recluse, "damage bonus HIDDEN");
		TF2Attrib_RemoveByName(Recluse, "single wep deploy time decreased");
	}
	return Plugin_Changed;
}
public Action:Timer_MOAMajor(Handle:Timer, any:Secondary)
{
	if (IsValidEntity(Secondary))
	{
		TF2Attrib_RemoveByName(Secondary, "damage bonus HIDDEN");
		TF2Attrib_RemoveByName(Secondary, "single wep deploy time decreased");
	}
	return Plugin_Changed;
}