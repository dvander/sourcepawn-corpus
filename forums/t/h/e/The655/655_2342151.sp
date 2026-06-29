#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <sdkhooks>
#include <customweaponstf>
#include <655>//useless

#define PLUGIN_VERSION                "5.0"

public Plugin:myinfo =
{
    name           = "Beta655 Attribute",
    author         = "The655",//with help of Theray and Orion
    description    = "Custom Attribute",
    version        = PLUGIN_VERSION,
    url            = "steamcommunity.com/id/T_655/"
};

new bool:HasAttribute[2049];

new bool:BattalionWhileChargingDemoMan[2049];
new bool:DisciplinFag[2049];
new StickyCharge[2049];
new bool:UberNotoMed[2049];
new bool:MediMelody[2049];
new bool:RemoveNegTeam[2049];
new bool:TauntCond[2049];
new TauntCondID[2049];
new Float:TauntCondDur[2049];
new bool:ResOnAmountHit[2049];
new Float:ResOnAmountHitReq[2049];
new ResOnAmountHitTyp[2049] = {1, 3};//Thanks Orion
new Float:ResOnAmountHitDur[2049];
new bool:DamageBonusOnCondition[2049];
new DamageBonusOnConditionID[2049];
new Float:DamageBonusOnConditionAmount[2049];
new bool:DamageBonusOnClass[2049];
new DamageBonusOnClassID[2049];
new Float:DamageBonusOnClassAmount[2049];
new Float:HitDrunk[2049];
new Senthree[2049];
new Float:FireStab[2049];
new Float:Uncloak[2049];
new Float:SapperStun[2049];
new bool:MedShield[2049];
new MiniCritOverHeal[2049];
new bool:BonkCond[2049];
new BonkCondID[2049];
new Float:BonkCondDur[2049];
new Float:DarkBonkCondDur[2049];
new MinigunSpinCond[2049];



public OnPluginStart()
{
    for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		{
		OnClientPutInServer(i);
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(i, SDKHook_PreThink, OnClientPreThink);
		}
    }
    HookEvent("sticky_jump_landed", Event_stickyland);
    HookEvent("player_chargedeployed", Event_uberdeploy);
    HookEvent("player_builtobject", Event_build);
    HookEvent("player_sapped_object", Event_sapped);
    HookEvent("post_inventory_application", Event_resupply, EventHookMode_Pre);
}

public OnMapStart()
{
    new Loop;
    for (Loop = 0; Loop < sizeof(MiniCritAttacker); Loop++) 
	{
        PrecacheSound(MiniCritAttacker[Loop]);
    }
    for (Loop = 0; Loop < sizeof(CritTake); Loop++) 
	{
        PrecacheSound(CritTake[Loop]);
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
    SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
    if (!StrEqual(plugin, "the655")) return Plugin_Continue;
    new Action:action;
	
    if (StrEqual (attrib, "battl demo"))
    {
        BattalionWhileChargingDemoMan[weapon] = true;
        action = Plugin_Handled;
    }
	else if (StrEqual (attrib, "discp heavy"))
	{
		DisciplinFag[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "sticky charge"))
	{
		StickyCharge[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "med no uber"))
	{
		UberNotoMed[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "uber melody"))
	{
		MediMelody[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "remove debuff team"))
	{
		RemoveNegTeam[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "taunt cond"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));

		TauntCondID[weapon] = StringToInt(values[0]);
		TauntCondDur[weapon] = StringToFloat(values[1]);
		TauntCond[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "resist on amount hit"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));

		ResOnAmountHitReq[weapon] = StringToFloat(values[0]);
		ResOnAmountHitTyp[weapon] = StringToInt(values[1]);
		ResOnAmountHitDur[weapon] = StringToFloat(values[2]);
		ResOnAmountHit[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "dmg bonus on condition"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));

		DamageBonusOnConditionID[weapon] = StringToInt(values[0]);
		DamageBonusOnConditionAmount[weapon] = StringToFloat(values[1]);
		DamageBonusOnCondition[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "dmg bonus on class"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));

		DamageBonusOnClassID[weapon] = StringToInt(values[0]);
		DamageBonusOnClassAmount[weapon] = StringToFloat(values[1]);
		DamageBonusOnClass[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "hit drunk"))
	{
		HitDrunk[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "senthree"))
	{
		Senthree[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "stab burn"))
	{
		FireStab[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "uncloak set"))
	{
		Uncloak[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "sap stun"))
	{
		SapperStun[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "uber shield"))
	{
		MedShield[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "mini-crit cond"))
	{
		MiniCritOverHeal[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "bonk cond"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));

		BonkCondID[weapon] = StringToInt(values[0]);
		BonkCondDur[weapon] = StringToFloat(values[1]);
		BonkCond[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "invis bonk"))
	{
		DarkBonkCondDur[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual (attrib, "minigun cond"))
	{
		MinigunSpinCond[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}

	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
	return action;
}

public Action:Event_resupply(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (TF2_GetPlayerClass(client) == TFClassType:1 && TF2_IsPlayerInCondition(client, TFCond:64))
    {
		TF2_RemoveCondition(client, TFCond:64);
		DeleteParticle(iParticle);
	}
}

public Action:Event_stickyland(Handle:event, const String:name[], bool:dontBroadcast)
{
    new demo = GetClientOfUserId(GetEventInt(event, "userid"));

    new weapon;
    for (new i = 0; i <= 5; i++)
    {
        new j = GetPlayerWeaponSlot(demo, i);
        if (j == -1) continue;
        if (!HasAttribute[j]) continue;
        weapon = j;
        // Doesn't count wearable.
    }
    if (StickyCharge[weapon])
    {
		TF2_AddCondition(demo, TFCond:StickyCharge[weapon], 2.0);
	}
}

public Action:Event_uberdeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
    new medic = GetClientOfUserId(GetEventInt(event, "userid"));

    new weapon;
    for (new i = 0; i <= 5; i++)
    {
        new j = GetPlayerWeaponSlot(medic, i);
        if (j == -1) continue;
        if (!HasAttribute[j]) continue;
        weapon = j;
    }
    if (UberNotoMed[weapon])
    {
        TF2_RemoveCondition(medic, TFCond_Ubercharged);
    }
    if (MediMelody[weapon]) //Does not work like I wanted but it still do something.
    {
        TF2_AddCondition(medic, TFCond:55 , 8.0);
    }
    if (MedShield[weapon])
    {
        new shield = CreateEntityByName("entity_medigun_shield");
        if(shield != -1) 
        {
            SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", medic);  
            SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(medic));  
            SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(medic));  
            if (GetClientTeam(medic) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
            else if (GetClientTeam(medic) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
            SetEntPropFloat(medic, Prop_Send, "m_flRageMeter", 100.0);
            SetEntProp(medic, Prop_Send, "m_bRageDraining", 1);
            DispatchSpawn(shield);
        }
    }
}

public Action:Event_build(Handle:event, const String:name[], bool:dontBroadcast)
{
	new engineer = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = GetEventInt(event, "index");
	//new building = GetEventInt(event, "object");

	new weapon;
	for (new i = 0; i <= 5; i++)
	{
		new j = GetPlayerWeaponSlot(engineer, i);
		if (j == -1) continue;
		if (!HasAttribute[j]) continue;
		weapon = j;
	}
	if (Senthree[weapon])
	{
		SetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel", Senthree[weapon]);
	}
}

public Action:Event_sapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new spy = GetClientOfUserId(GetEventInt(event, "userid"));
	new engineer = GetClientOfUserId(GetEventInt(event, "ownerid"));
	//new building = GetEventInt(event, "object");

	new weapon;
	for (new i = 0; i <= 5; i++)
	{
		new j = GetPlayerWeaponSlot(spy, i);
		if (j == -1) continue;
		if (!HasAttribute[j]) continue;
		weapon = j;
	}
	if (SapperStun[weapon])
	{
		TF2_StunPlayer(engineer, SapperStun[weapon], 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, spy);
	}

}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	if (weapon == -1) return Plugin_Continue;
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	new Action:action;

	if(ResOnAmountHit[weapon] && damage >= ResOnAmountHitReq[weapon])
	{
		if (ResOnAmountHitTyp[weapon] == 1) TF2_AddCondition(attacker, TFCond_BulletImmune, ResOnAmountHitDur[weapon]);//Thanks Orion
		else if (ResOnAmountHitTyp[weapon] == 2) TF2_AddCondition(attacker, TFCond_BlastImmune, ResOnAmountHitDur[weapon]);
		else if (ResOnAmountHitTyp[weapon] == 3) TF2_AddCondition(attacker, TFCond_FireImmune, ResOnAmountHitDur[weapon]);
	}
	if (DamageBonusOnCondition[weapon] && TF2_IsPlayerInCondition(victim, TFCond:DamageBonusOnConditionID[weapon]))
	{
		damage *= DamageBonusOnConditionAmount[weapon];
		
		action = Plugin_Changed;
	}
	if (DamageBonusOnClass[weapon] && TF2_GetPlayerClass(victim) == TFClassType:DamageBonusOnClassID[weapon])
	{
		damage *= DamageBonusOnClassAmount[weapon];
		
		action = Plugin_Changed;
	}
	if (HitDrunk[weapon])
	{
		MakeDrunk(victim);
		CreateTimer(HitDrunk[weapon], HitDrunkTimer, victim);
	}
	if (FireStab[weapon] && damagecustom == TF_CUSTOM_BACKSTAB)
	{
		TF2_IgnitePlayer(victim, attacker);
		
		damage = FireStab[weapon];
		
		action = Plugin_Changed;
	}
	if (MiniCritOverHeal[weapon] && TF2_IsPlayerInCondition(victim, TFCond:MiniCritOverHeal[weapon]))
	{
		ApplyMinicrit(victim, attacker);
		damage *= 1.35;
		
		action = Plugin_Changed;
	}
	return action;
}
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1) return Plugin_Continue;
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	if (RemoveNegTeam[weapon])
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			TF2_RemoveCondition(victim, TFCond_Jarated);
			TF2_RemoveCondition(victim, TFCond_Bleeding);
			TF2_RemoveCondition(victim, TFCond_MarkedForDeath);
			TF2_RemoveCondition(victim, TFCond_Milked);
		}
	}
	return Plugin_Continue;
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	new weapon;
	for (new i = 0; i <= 5; i++)
	{
		new j = GetPlayerWeaponSlot(client, i);
		if (j == -1) continue;
		if (!HasAttribute[j]) continue;
		weapon = j;
		// Doesn't count wearable.
	}
	if (Uncloak[weapon] && condition == TFCond_Cloaked)
	{
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", Uncloak[weapon]);
	}
	if (DarkBonkCondDur[weapon] && condition == TFCond:64)
	{
		DeleteParticle(iParticle);
	}
}

OnPrethink(client)
{
    new weapon;
    for (new i = 0; i <= 5; i++)
    {
        new j = GetPlayerWeaponSlot(client, i);
        if (j == -1) continue;
        if (!HasAttribute[j]) continue;
        weapon = j;
        // Doesn't count wearable.
    }
    if (BattalionWhileChargingDemoMan[weapon] && IsPlayerAlive(client))
    {
        if (TF2_IsPlayerInCondition(client, TFCond_Charging))
        {
            TF2_AddCondition(client, TFCond_DefenseBuffed, 999.0);
        }
        else
        {
            TF2_RemoveCondition(client, TFCond_DefenseBuffed);
        }
    }
    if (DisciplinFag[weapon] && IsPlayerAlive(client))
    {
        if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
        {
            TF2_AddCondition(client, TFCond_SpeedBuffAlly, 999.0);
        }
        else
        {
            TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
        }
    }
    if (TauntCond[weapon])
    {
        if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
        {
            TF2_AddCondition(client, TFCond:TauntCondID[weapon], TauntCondDur[weapon]);
        }
    }
    if (BonkCond[weapon] && TF2_IsPlayerInCondition(client, TFCond_Bonked))
	{
        TF2_RemoveCondition(client, TFCond_Bonked);
        TF2_AddCondition(client, TFCond:BonkCondID[weapon], BonkCondDur[weapon]);
    }
    if (DarkBonkCondDur[weapon] && TF2_IsPlayerInCondition(client, TFCond_Bonked))
    {
        TF2_RemoveCondition(client, TFCond_Bonked);
        TF2_AddCondition(client, TFCond:64, DarkBonkCondDur[weapon]);

        if (GetClientTeam(client) == _:TFTeam_Red) CreateParticle(client, "teleporter_red_exit", true);
        else if (GetClientTeam(client) == _:TFTeam_Blue) CreateParticle(client, "teleporter_blue_exit", true);
		
    }
    if (MinigunSpinCond[weapon] && IsPlayerAlive(client))
    {
        if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
        {
            TF2_AddCondition(client, TFCond:MinigunSpinCond[weapon], 999.0);
        }
        else
        {
            TF2_RemoveCondition(client, TFCond:MinigunSpinCond[weapon]);
        }
    }
}
//Timer
public Action:HitDrunkTimer(Handle:timer, any:victim)
{
	CureDrunk(victim);
}
public Action SpawnShieldInGame(Handle Timer, int shield) 
{ 
    // Spawn the shield in the game: 
    DispatchSpawn(shield); 
}
public Action:Test(Handle:timer, any:client)
{
	TF2_RemoveCondition(client, TFCond:64);
}
public Action:DeleteParticle(any)
{
    if (IsValidEdict(iParticle))
    {
        new String:classname[64];
        GetEdictClassname(iParticle, classname, sizeof(classname));
        
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(iParticle);
        }
    }
}
public OnEntityDestroyed(Ent)
{
    if (Ent <= 0 || Ent > 2048) return;
    HasAttribute[Ent] = false;
	
    BattalionWhileChargingDemoMan[Ent] = false;
    DisciplinFag[Ent] = false;
    StickyCharge[Ent] = 0;
    UberNotoMed[Ent] = false;
    MediMelody[Ent] = false;
    RemoveNegTeam[Ent] = false;
    TauntCond[Ent] = false;
    TauntCondID[Ent] = 0;
    TauntCondDur[Ent] = 0.0;
    ResOnAmountHit[Ent] = false;
    ResOnAmountHitReq[Ent] = 0.0;
    ResOnAmountHitTyp[Ent] = 0;
    ResOnAmountHitDur[Ent] = 0.0;
    DamageBonusOnCondition[Ent] = false;
    DamageBonusOnConditionID[Ent] = 0;
    DamageBonusOnConditionAmount[Ent] = 0.0;
    DamageBonusOnClass[Ent] = false;
    DamageBonusOnClassID[Ent] = 0;
    DamageBonusOnClassAmount[Ent] = 0.0;
    HitDrunk[Ent] = 0.0;
    Senthree[Ent] = 0;
    FireStab[Ent] = 0.0;
    Uncloak[Ent] = 0.0;
    SapperStun[Ent] = 0.0;
    MedShield[Ent] = false;
    MiniCritOverHeal[Ent] = 0;
    BonkCond[Ent] = false;
    BonkCondID[Ent] = 0;
    BonkCondDur[Ent] = 0.0;
    DarkBonkCondDur[Ent] = 0.0;
    MinigunSpinCond[Ent] = 0;
}