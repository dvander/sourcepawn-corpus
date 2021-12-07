#pragma semicolon 1
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <customweaponstf>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "beta 1"

public Plugin:myinfo = {
    name = "Custom Weapons 2: Khopesh Climber",
    author = "404: User Not Found",
    description = "Khopesh Climber for Custom Weapons 2",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=236242"
};

/* *** Attributes In This Plugin ***
-> "climb walls"
		This weapon allows players to climb walls simply by hitting them!
		Set the value for this to "1" to enable.
		This effect is best used on a melee weapon with a slight fire rate decrease.
		(Taken from FlaminSarge's Given Weapon plugin, originally coded by Mecha the Slag as part of Advanced Weaponiser)
*/

new bool:HasAttribute[2049];

new bool:ClimbWalls[2049];

public OnPluginStart()
{
	
}

public OnClientPutInServer(client)
{

}

public OnEntityDestroyed(Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	HasAttribute[Ent] = false;
	ClimbWalls[Ent] = false;
}

public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
	if (!StrEqual(plugin, "cw2_khopesh")) return Plugin_Continue;
	new Action:action;
	if (StrEqual(attrib, "climb walls"))
	{
		ClimbWalls[weapon] = true;
		action = Plugin_Handled;
	}
	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!HasAttribute[weapon]) return Plugin_Continue;	
	if (ClimbWalls[weapon])
	{
		decl String:classname[64];
		decl Float:vecClientEyePos[3];
		decl Float:vecClientEyeAng[3];
		GetClientEyePosition(client, vecClientEyePos);	 // Get the position of the player's eyes
		GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

		//Check for colliding entities
		TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

		if (!TR_DidHit(INVALID_HANDLE))
		{
			return Plugin_Handled;
		}

		new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(TRIndex, classname, sizeof(classname));
		if (!StrEqual(classname, "worldspawn")) return Plugin_Handled;

		decl Float:fNormal[3];
		TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
		GetVectorAngles(fNormal, fNormal);

		//PrintToChatAll("Normal: %f", fNormal[0]);

		if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return Plugin_Handled;
		if (fNormal[0] <= -30.0) return Plugin_Handled;

		decl Float:pos[3];
		TR_GetEndPosition(pos);
		new Float:distance = GetVectorDistance(vecClientEyePos, pos);

		//PrintToChatAll("Distance: %f", distance);
		if (distance >= 100.0) return Plugin_Handled;

		new Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = 600.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
		if (GetEntProp(client, Prop_Send, "m_nNumHealers") <= 0) return Plugin_Handled;
		for (new healer = 1; healer <= MaxClients; healer++)
		{
			if (!IsClientInGame(healer)) return Plugin_Handled;
			if (!IsPlayerAlive(healer)) return Plugin_Handled;
			new sec = GetPlayerWeaponSlot(healer, TFWeaponSlot_Secondary);
			GetEdictClassname(sec, classname, sizeof(classname));
			if (StrEqual(classname, "tf_weapon_medigun", false))	//it's a medigun
			{
				if (GetEntProp(sec, Prop_Send, "m_iItemDefinitionIndex") != 411 || client != GetEntPropEnt(sec, Prop_Send, "m_hHealingTarget"))
				{
					return Plugin_Continue;
				}	//#TF2AttribStuffs
				TeleportEntity(healer, NULL_VECTOR, NULL_VECTOR, fVelocity);
			}
		}
	}
	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}

stock bool:IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

stock ClearTimer(&Handle:Timer)
{
	if (Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}
