

/**************************
 * L4D2 No Witch Crowning *
 **************************/


#define PLUGIN_VERSION "1.0.3"


#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3


new Handle:nwcMode = INVALID_HANDLE;
new Handle:nwcDebug = INVALID_HANDLE;
new Handle:witchHealth = INVALID_HANDLE;

new bool:witchInvincible = false;


public Plugin:myinfo = 
{
	name = "L4D2 No Witch Crowning",
	author = "MrNiceGuy",
	description = "Protect Witch from being crowned",
	version = PLUGIN_VERSION,
	url = ""
};


public OnPluginStart()
{
	nwcMode = CreateConVar("l4d2_nwc_enable", "1", "Protect Witch from being crowned");
	nwcDebug = CreateConVar("l4d2_nwc_debug", "0", "Print Debug Information to Chat");

	AutoExecConfig(true, "l4d2_no_witch_crowning");

	witchHealth = FindConVar("z_witch_health");

	HookEvent("infected_hurt", Event_infected_hurt, EventHookMode_Pre);
}


public Action:Event_infected_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(nwcMode) == 0) {
		return Plugin_Continue;
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetEventInt(event, "entityid");

	if (IsWitch(victim)) {
		if (GetClientTeam(attacker) == TEAM_SURVIVOR) {
			if (!witchInvincible && GetEntProp(victim, Prop_Data, "m_iHealth") >= GetConVarInt(witchHealth)) {
				if (GetConVarInt(nwcDebug) != 0) { PrintToChatAll("Witch hurt by Survivor - Starting Invincibility"); }
				witchInvincible = true;
				CreateTimer(2.0, SetVincible);
			}
		} else {
			if (GetConVarInt(nwcDebug) != 0) { PrintToChatAll("Witch hurt by Non-Survivor - Ignoring"); }
			SetEntProp(victim, Prop_Data, "m_iHealth", GetConVarInt(witchHealth) + GetEventInt(event, "amount"));
		}
		if (witchInvincible) {
			SetEntProp(victim, Prop_Data, "m_iHealth", GetConVarInt(witchHealth) - 1);
		}
		if (GetConVarInt(nwcDebug) != 0) { PrintToChatAll("Witch health is %d", GetEntProp(victim, Prop_Data, "m_iHealth")); }
	}

	return Plugin_Continue;
}


public Action:SetVincible(Handle:timer)
{
	if (GetConVarInt(nwcDebug) != 0) { PrintToChatAll("Ending Invincibility"); }
	witchInvincible = false;
}


IsWitch(entityid)
{
	if (entityid > 0 && IsValidEdict(entityid) && IsValidEntity(entityid)) {
		decl String:classname[32];
		GetEdictClassname(entityid, classname, sizeof(classname));
		if(StrEqual(classname, "witch")) {
			return true;
		}
	}

	return false;
}
