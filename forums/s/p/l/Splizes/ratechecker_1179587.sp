#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "Rate Checker",
    author = "Splizes",
    description = "Checks the rates of all online players.",
    version = "0.0.1",
    url = ""
}

public OnPluginStart()
{
    RegAdminCmd("sm_rates", Cmd_Rate, ADMFLAG_GENERIC, "sm_rates - No parameters are required.")
}

public Action:Cmd_Rate(client,args)
{
    new String:interp[10],String:update[10],String:cmd[10],String:rate[10],String:cname[128]
    decl String:t_name[16], String:t_rate[16], String:t_updaterate[16], String:t_cmdrate[16], String:t_interp[16]
    t_name = "Name"
    t_rate = "Rate"
    t_updaterate = "Update Rate"
    t_cmdrate = "Cmdrate"
    t_interp = "Interp"
    
    PrintToConsole(client, "%-10.23s %-10.23s %-10.23s %-10.23s",t_name,t_rate,t_updaterate,t_cmdrate,t_interp)

    for(new i = 1; i <= MaxClients; i++) {
        if((IsClientInGame(i)) && (!IsFakeClient(i))) {
            GetClientName(i,cname,128)
            GetClientInfo(i, "cl_interp", interp, 9)
            GetClientInfo(i, "cl_updaterate", update, 9)
            GetClientInfo(i, "cl_cmdrate",cmd, 9)
            GetClientInfo(i, "rate", rate, 9)
            PrintToConsole(client,"%-30.23s %-10.23s %-10.23s %-10.23s %-10.23s",cname,rate,update,cmd,interp)
        }
    }
}
    