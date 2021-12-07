#include <sourcemod>
#include <sendproxy>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "[ANY] Observer Obscurer",
    author = "Headline & Tak",
    description = "Forces client's m_hObserverTarget to 0",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2517262m"
}

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		SendProxy_Hook(i, "m_hObserverTarget", Prop_Int, PropHook_CallBack);
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
	
	SendProxy_Hook(client, "m_hObserverTarget", Prop_Int, PropHook_CallBack);
}

public Action PropHook_CallBack(int entity, const char[] propname, int &iValue, int element)
{
	if (entity != iValue)
		return Plugin_Continue;
		
	iValue = 0;
	return Plugin_Changed;
}