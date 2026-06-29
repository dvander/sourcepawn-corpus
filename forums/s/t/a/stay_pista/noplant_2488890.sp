#pragma semicolon 1

public Plugin:myinfo = {
	name		= "CS:GO NO-Plant",
	author		= "Pista",
	version     = "1.0",
	url         = "http://sourcemod.net"
};

new Handle:g_hEnabled =INVALID_HANDLE;
public OnPluginStart(){	
	g_hEnabled  = CreateConVar("sm_noplant_enabled","1","Enable/Disable bomb plant on the server.",FCVAR_NOTIFY|FCVAR_DONTRECORD,true,0.0,true,1.0);
	HookConVarChange(g_hEnabled , OnNpEnabledChanged);
}

public OnNpEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(!StrEqual(oldValue, newValue)) g_hEnabled = GetConVarBool(convar);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if (g_hEnabled  && ((buttons&IN_ATTACK) || (buttons&IN_USE))){
		new String:classname[64];
		GetClientWeapon(client, classname, sizeof(classname));
		
		if (StrEqual(classname, "weapon_c4")){
			buttons &= ~(IN_USE | IN_ATTACK);
		}
	}
}