#include <sourcemod>
#include <sdktools>
#define Plugin_Version "1.0.1"

public Plugin:myinfo = { name = "AimName", author = "Artos", description = "AimName", version = Plugin_Version, url = "http://steamcommunity.com/groups/BeFriendTeam"};

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    static iPrevButtons[MAXPLAYERS+1];
    
    if (!(buttons & 64) && (iPrevButtons[client] & 64))
    {
        OnButtonUseReleased(client);
    }
    iPrevButtons[client] = buttons;
    return Plugin_Continue;
}

Action:OnButtonUseReleased(client)
{
		new target = GetClientAimTarget(client, true);
		if (target == -1)
		{
		return Plugin_Stop;
		}		
		new Float:client_pos[3], Float:target_pos[3];
		GetClientEyePosition(client, client_pos);
		GetClientEyePosition(target, target_pos);
		new Float:fDistance;
		fDistance = (GetVectorDistance(client_pos, target_pos)* 0.01905);
		decl String:name[64];
		GetClientName(target, name, sizeof(name));
		new team = GetClientTeam(client);
		new team2 = GetClientTeam(target);
		if (team == team2 && fDistance < 10)
		{
		PrintHintText(client, "name=%s", name);
		}
		return Plugin_Continue;
}
