#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

new Handle:hVisibleChick = INVALID_HANDLE;
new bool:visibleChicken = false;

public Plugin:myinfo =
{
	name = "Chicken C4",
	author = "Mitch.",
	description = "CHICKEN C4 WAT.",
	version = PLUGIN_VERSION,
	url = "http://snbx.info/"
};

public OnPluginStart()
{
	hVisibleChick = CreateConVar("sm_chickc4_visible", "0", "Set to 1 for the chicken to be visible.");
	HookConVarChange(hVisibleChick, OnCvarChanged);
	AutoExecConfig();
	
	CreateConVar("sm_chickenc4_version", PLUGIN_VERSION, "Chicken C4 Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);	
	HookEvent("bomb_planted", BomPlanted_Event);
}
public Action:BomPlanted_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new c4 = -1;
	c4 = FindEntityByClassname(c4, "planted_c4");
	if(c4 != -1) {
		new chicken = CreateEntityByName("chicken");
		if(chicken != -1) {
			new player = GetClientOfUserId(GetEventInt(event, "userid"));
			decl Float:pos[3];
			GetEntPropVector(player, Prop_Data, "m_vecOrigin", pos);
			
			DispatchSpawn(chicken);
			SetEntProp(chicken, Prop_Data, "m_takedamage", 0);
			SetEntProp(chicken, Prop_Send, "m_fEffects", 0);
			pos[2] -= 15.0;
			TeleportEntity(chicken, pos, NULL_VECTOR, NULL_VECTOR);
			TeleportEntity(c4, NULL_VECTOR, Float:{0.0, 0.0, 0.0}, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(c4, "SetParent", chicken, c4, 0);
			if(visibleChicken) {
				pos[2] += 15.0;
				TeleportEntity(chicken, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
			} else {
				SetEntityRenderMode(chicken, RENDER_NONE);
			}
		}
	}
	return Plugin_Continue;
}

public OnCvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	visibleChicken = !StrEqual(newVal, "0", false);
}