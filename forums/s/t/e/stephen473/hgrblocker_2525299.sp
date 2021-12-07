
#include <sourcemod>
#include <multicolors>
#include <sdktools>

ConVar g_Enabled, g_Time, g_Tag, g_Message;
char plugintag[56];
Handle iTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "HGR StandbyTime",
	author = "Hardy(stephen473) rewritten on MrZeonai's",
	description = "Block HGR on roundstart for desired time",
	version = "1.0",
	url = "steamcommunity.com/id/kHardy"
}

public void OnPluginStart()
{
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 
    g_Enabled = CreateConVar("sm_hgr_standby_plugin_enable", "1", "Enable plugin? 1 = yes 0 = no");
    g_Time = CreateConVar("sm_hgr_standby_time", "15" ,"How many seconds on round start will hgr take to open?");
    g_Tag = CreateConVar("sm_hgr_standby_plugin_tag", "SM", "Plugin tag(dont put [])");
    g_Message = CreateConVar("sm_hgr_standby_plugin_messages", "1", "Show messages when hgr closed/opened. 1 = yes 0 = no");
    GetConVarString(g_Tag, plugintag, sizeof(plugintag));
    AutoExecConfig(true, "hgr_standbytime");
}
 

public Action OnRoundStart(Event event, const String:name[], bool dontBroadcast) 
{
	if(g_Enabled)
	{
		if (iTimer != INVALID_HANDLE)
		{
			KillTimer(iTimer);
			iTimer = INVALID_HANDLE;
		}
		
		iTimer = CreateTimer(GetConVarFloat(g_Time), openhgr);
		SetCvar("sm_hgr_hook_enable", 0);
		SetCvar("sm_hgr_grab_enable", 0);
		SetCvar("sm_hgr_rope_enable", 0);
	
		if (GetConVarBool(g_Message))
		{	
    		for (int i = 1; i <= MaxClients; i++)
   	 		{
        		if(IsClientInGame(i) && IsPlayerAlive(i))
        		{
           	 		if (CheckCommandAccess(i, "+hook", ADMFLAG_GENERIC))
            		{			
						CPrintToChat(i, "{darkred}[%s] {default}Hook,Grab,Rope closed for 15 sec!", plugintag);
					}
				}
			}
		}	
	}		
}

public Action openhgr(Handle timer)
{
	iTimer = INVALID_HANDLE;	
	
	SetCvar("sm_hgr_hook_enable", 1);
	SetCvar("sm_hgr_grab_enable", 1);
	SetCvar("sm_hgr_rope_enable", 1);
	
	if (GetConVarBool(g_Message))
	{
    	for (int i = 1; i <= MaxClients; i++)
   	 	{
        	if(IsClientInGame(i) && IsPlayerAlive(i))
        	{
           	 	if (CheckCommandAccess(i, "+hook", ADMFLAG_GENERIC))
            	{
					CPrintToChat(i, "{darkred}[%s] {default}Hook,Grab,Rope Active now!", plugintag);        		    		
            	}
        	}
    	}		
	}
}

stock void SetCvar(char cvarName[64], int value) // credits to shanapu
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null) return;
	
	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
	
	SetConVarInt(IntCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}