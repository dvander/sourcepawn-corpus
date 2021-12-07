#pragma semicolon 1
#include <sourcemod>

public OnClientPostAdminCheck(client)
{
    QueryClientConVar(client, "cl_drawhud", QueryConVar);
}

public QueryConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
    if (strcmp(cvarValue, "0", false) == 0 || strcmp(cvarValue, "nosounds", false) == 0)
    {
        return;
    }
    
    PrintToConsole(client, "You have your cl_drawhud set to [%s], please change it to [0]", cvarValue);
    PrintToConsole(client, "You have your cl_drawhud set to [%s], please change it to [0]", cvarValue);
    PrintToConsole(client, "You have your cl_drawhud set to [%s], please change it to [0]", cvarValue);
    KickClient(client, "Your setting for cl_drawhud is wrong, please set it to 0");
    
    return;
}  