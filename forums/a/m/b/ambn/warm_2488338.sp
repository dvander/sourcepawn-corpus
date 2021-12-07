#include <sourcemod>
#define CFGLive "live.cfg"
#define CFGWarm "warmup.cfg"
public OnPluginStart()
{
	RegAdminCmd("sm_live", Command_live, ADMFLAG_ROOT);
	RegAdminCmd("sm_warmup", Command_warmup, ADMFLAG_ROOT);
}
public Action Command_live(int client, int args)
{
	ServerCommand("exec %s", CFGLive);
}
public Action Command_warmup(int client, int args)
{
	ServerCommand("exec %s", CFGWarm);
}
