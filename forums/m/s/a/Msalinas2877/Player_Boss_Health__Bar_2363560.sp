#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegAdminCmd("sm_toggle_healthbar", Command_Toggle, ADMFLAG_KICK, "Toggles a boss health bar on a player/filter");
}
 
public Action Command_Toggle(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_toggle_healthbar <name>");
		return Plugin_Handled;
	}
 
	char name[32];
        int target = -1;
	GetCmdArg(1, name, sizeof(name));
 
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		char other[32];
		GetClientName(i, other, sizeof(other));
		if (StrEqual(name, other))
		{
			target = i;
		}
	}
 
	if (target == -1)
	{
		PrintToConsole(client, "Could not find any player with the name: \"%s\"", name);
		return Plugin_Handled;
	}
 
	if (GetEntProp(target, Prop_Send, "m_bUseBossHealthBar") == 1);
  {
    SetEntProp(target, Prop_Send, "m_bUseBossHealthBar", 0);
  }
  else
  {
    SetEntProp(target, Prop_Send, "m_bUseBossHealthBar", 1);
  }
 
	return Plugin_Handled;
}