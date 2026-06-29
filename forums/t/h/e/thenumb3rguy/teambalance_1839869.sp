#include <sourcemod>

public Plugin:myinfo = 
{
        name = "Team balance fix",
        author = "Hours Played, Inc.",
        description = "Fix for uneven teams",
        version = "1.1"
};

public OnPluginStart()
{
    HookConVarChange(FindConVar("mp_autoteambalance"), ValueChanged)
}

public ValueChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
     SetConVarInt(cvar, 0);
} 
		
		
	




		

