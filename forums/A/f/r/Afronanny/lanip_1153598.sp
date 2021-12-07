#include <sourcemod>

new Handle:g_hCvarEnabled;
new Handle:g_hCvarRange;

new String:g_strIPRange[32];

new g_ServerIP[3];

public Plugin:myinfo = 
{
	name = "LAN IP Ban",
	author = "Afronanny",
	description = "Disallow ",
	version = "1.0",
	url = "http://lmgtfy.com/"
}

public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_lanip_enabled", "1", "Enable plugin");
	g_hCvarRange = CreateConVar("sm_lanip_range", "192.168.0", "Range to accept connections from");
	
	HookConVarChange(g_hCvarRange, ConVarChanged);
	ConVarChanged(g_hCvarRange, "", "192.168.0");
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (GetConVarBool(g_hCvarEnabled))
	{
		decl String:strIP[32];
		decl String:strBuffers[4][32];
		
		GetClientIP(client, strIP, sizeof(strIP));
		ExplodeString(strIP, ".", strBuffers, 4, 32);
		
		new ip1 = StringToInt(strBuffers[0]);
		new ip2 = StringToInt(strBuffers[1]);
		new ip3 = StringToInt(strBuffers[2]);
		//4th octet is not needed
		
		if (ip1 == g_ServerIP[0] && ip2 == g_ServerIP[1] && ip3 == g_ServerIP[2])
		{
			return true;
		} else {
			Format(rejectmsg, maxlen, "You cannot play on this server.");
			return false;
		}
	} else { 
		return true;
	}
	
	
}
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:g_strBuffers[3][32];
	
	strcopy(g_strIPRange, sizeof(g_strIPRange), newValue);
	ExplodeString(g_strIPRange, ".", g_strBuffers, 3, 32);
	g_ServerIP[0] = StringToInt(g_strBuffers[0]);
	g_ServerIP[1] = StringToInt(g_strBuffers[1]);
	g_ServerIP[2] = StringToInt(g_strBuffers[2]);
	
}
