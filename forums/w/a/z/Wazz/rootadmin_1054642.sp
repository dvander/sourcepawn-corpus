#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION            "1.0.0.0"

public Plugin:myinfo =
{
    name = "Root Admin",
    author = "Wazz",
    description = "Removes all other admin's access while a root admin is on the server",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

new g_iRootAdminCount ;

public OnPluginStart()
{    
    CreateConVar("sm_rootadmin_version", PLUGIN_VERSION, "Root Admin Access Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
    g_iRootAdminCount = 0;
}

public OnClientPostAdminCheck(client)
{  
    CreateTimer(1.0, AdminCheck, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:AdminCheck(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

    if (IsRootAdmin(client))
    {
        g_iRootAdminCount ++;
        
        if (g_iRootAdminCount == 1)
        {
            for (new i=1; i<=MaxClients; i++)
            {
                if (IsClientInGame(i) && !IsRootAdmin(i))
                {
                    RemoveAdmin(GetUserAdmin(i));
                }
            }
        }
    }
    else if (!IsRootAdmin(client))
    {
        if (g_iRootAdminCount > 0)
        {
            RemoveAdmin(GetUserAdmin(client));
        }
    }

    return Plugin_Handled;
}

public OnClientDisconnect(client)
{
    if (IsRootAdmin(client))
    {
        g_iRootAdminCount --;
        
        if (g_iRootAdminCount == 0)
        {
            DumpAdminCache(AdminCache_Groups, true);
            DumpAdminCache(AdminCache_Admins, true);
        }
    }
}

/*    
    Returns: 
    1 if the client is a root admin
    0 if the client is an admin but does not have root access
    -1 if the client is not an admin.
*/
stock IsRootAdmin(client)
{
    new flags = GetUserFlagBits(client);

    if (flags & ADMFLAG_ROOT)
    {
        return 1;
    }
    
    return flags==0?-1:0;
}