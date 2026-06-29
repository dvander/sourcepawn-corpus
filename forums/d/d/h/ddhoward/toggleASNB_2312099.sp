public OnPluginStart() { 
    RegAdminCmd("sm_nb", Command_NB, ADMFLAG_ROOT); 
} 

public Action Command_NB(int client, int args) { 
    static ConVar cvar; 
    if (cvar == null) cvar = FindConVar("sm_antistucknoblock"); 
    if (cvar != null) {
		cvar.BoolValue = !cvar.BoolValue;
		PrintCenterTextAll("sm_antistucknoblock was turned %s", cvar.BoolValue ? "on" : "off");
	}
}