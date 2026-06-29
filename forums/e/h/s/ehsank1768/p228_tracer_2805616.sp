
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Awp Traces",
	author = "Danyas & maniek23",
	description = "Script which makes AWP sniper rifle to leave nice looking bullet traces",
	version = "1.1"
}

new tracer_fx;

public OnPluginStart()
{
	HookEvent("weapon_fire", Event_OnWeaponFire);
}

public OnMapStart()
{
	tracer_fx = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:silent)
{
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
 	if (StrEqual(weapon, "p228", false))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		decl Float:EyePosition[3], Float:EyeAngles[3], Float:pos[3], Float:clientpos[3]; 
		GetClientEyePosition(client, EyePosition);
		GetClientEyeAngles(client, EyeAngles);
		TR_GetEndPosition(pos, TR_TraceRayFilterEx(EyePosition, EyeAngles, MASK_SOLID, RayType_Infinite, wS_GetLookPos_Filter, client));
		GetClientEyePosition(client, clientpos);
		TE_SetupBeamPoints(clientpos, pos, tracer_fx,0,0,0,1.0,1.0,1.0,0,0.0,{255, 0, 0, 255},1);
		TE_SendToAll();
		TE_SetupBeamPoints(pos, clientpos, tracer_fx,0,0,0,0.0,0.0,0.0,0,0.0,{255, 0, 0, 255},6);
		TE_SendToAll();
	}
}

public bool:wS_GetLookPos_Filter(ent, mask, any:client)
{ 
	return client != ent;
}