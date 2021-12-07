#include <sourcemod>
#define PLUGIN_VERSION "0.0.3.ffs.please.work"
public Plugin:myinfo =
{
        name = "AdminConnectmsg",
        author = "R-Hehl",
        description = "Shows players connecting admins",
        version = PLUGIN_VERSION,
        url = "http://www.compactaim.de/"
};
public OnPluginStart()
{
        // Create the rest of the cvar's
        CreateConVar("sm_admin_conmsg_version", PLUGIN_VERSION, "Admin Connect MSG Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnClientPostAdminCheck(client)
{
        new flags = GetUserFlagBits(client) & (ADMFLAG_RESERVATION | ADMFLAG_BAN | ADMFLAG_ROOT);
        if(flags)
                PrintCenterTextAll("%s %N connected!", (flags == ADMFLAG_RESERVATION ? "Donator" : "Admin"), client);
}