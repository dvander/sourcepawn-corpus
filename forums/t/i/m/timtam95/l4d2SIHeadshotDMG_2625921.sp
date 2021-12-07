/*
Credits and thanks for code snippets go to alcybery and eyal282
https://forums.alliedmods.net/showthread.php?t=308401

and AtomicStryker
https://forums.alliedmods.net/showthread.php?p=1066911
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


static Handle:g_cvHeadShotDamageMultiplier = INVALID_HANDLE;
static bool:ignoreNextDamageDealt[MAXPLAYERS+1] = false;
String:DmgMultiplier[16] = "1.2";

public Plugin:myinfo =
{

    name = "Special Infected Head SHot Damage Multiplier",
    author = "timtam95",
    description = "Special Infected Head SHot Damage Multiplier",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"

};

public OnPluginStart() {

	g_cvHeadShotDamageMultiplier = CreateConVar("cv_hsdmg", "1.2", "Head SHot Damage Multiplier");
	HookConVarChange(g_cvHeadShotDamageMultiplier, UpdateConVarsHook);
	UpdateConVarsHook(g_cvHeadShotDamageMultiplier, "1.2", "1.2");

	HookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);

}

public UpdateConVarsHook(Handle:convar, String:oldValue[], String:newValue[]) {

	SetConVarFloat(g_cvHeadShotDamageMultiplier, StringToFloat(newValue));
	Format(DmgMultiplier, sizeof(DmgMultiplier), "%s", newValue);
	PrintToChatAll("Special Infected Headshot Damage Multiplier set to %s", DmgMultiplier);

}

public Action:HeadShotHook(Handle event, String:name[], bool dontBroadcast) {

	int hitgroup = GetEventInt(event, "hitgroup");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        int type = GetEventInt(event, "type");



	if (hitgroup == 1 && type != 8)   // 8 == death by fire...
        {

		if (!client || !attacker || ignoreNextDamageDealt[attacker]) return Plugin_Continue; // both must be valid players.


		float multiplier = GetConVarFloat(g_cvHeadShotDamageMultiplier);

		new dmg_health = GetEventInt(event, "dmg_health");	 // get the amount of damage done
		new eventhealth = GetEventInt(event, "health");	// get the health after damage as the event sees it
		int damagedelta;
		damagedelta = RoundToNearest((dmg_health * multiplier) - dmg_health);

		switch (damagedelta > 0)
		{
			case true:
			{
				applyDamage(damagedelta, client, attacker);
			}
			case false:
			{
				new health = eventhealth - damagedelta;
			
				if (health < 1)
				{
					damagedelta += (health - 1);
					health = 1;
				}
				
				SetEntityHealth(client, health);
				SetEventInt(event, "dmg_health", dmg_health + damagedelta); // for correct stats.
				SetEventInt(event, "health", health);
			}
		}
	}
	return Plugin_Continue;
}



static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.1, timer_stock_applyDamage, dataPack);
	ignoreNextDamageDealt[attacker] = true;
	CreateTimer(0.2, timer_resetStop, attacker);
}

public Action:timer_resetStop(Handle:timer, any:client)
{
	ignoreNextDamageDealt[client] = false;
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);   

	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (victim < 20 && IsClientInGame(victim))
	{
		GetClientEyePosition(victim, victimPos);
	}
	else if (IsValidEntity(victim))
	{
		GetEntityAbsOrigin(victim, victimPos);
	}
	else return;
	
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < 20 && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}


stock GetEntityAbsOrigin(entity, Float:origin[3])
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
		GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
		GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}


public OnEntityCreated(entity, const String:Classname[])
{
    if(StrEqual(Classname, "witch"))
    {
        SDKHook(entity, SDKHook_TraceAttack, Event_TraceAttack);
    }
}

public Action:Event_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{

    if(hitgroup == 1)
    {
        damage *= StringToFloat(DmgMultiplier);
        return Plugin_Changed;
    }

    return Plugin_Continue;

}

stock bool:IsWitch(iEntity) 
{ 
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity)) 
    { 
        decl String:strClassName[64]; 
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName)); 
        return StrEqual(strClassName, "witch"); 
    } 
    return false; 
}
