

#include <sdkhooks>
#include <sdktools>

#define TEAM_ALLIES 2
#define TEAM_AXIS 3


// DOD:S,  8 is maximum capture points. Game crash over this limit.
#define MAX_CONTROL_POINTS 8

enum struct capture_area
{
	int m_nAlliesNumCap[MAX_CONTROL_POINTS];
	int m_nAxisNumCap[MAX_CONTROL_POINTS];
	int ref[MAX_CONTROL_POINTS];
}


public Plugin myinfo = 
{
	name = "[DOD:S] Ease flag capturing with few players",
	author = "Bacardi",
	description = "Less people in team can capture bigger flags",
	version = "1.0",
	url = "https://forums.alliedmods.net/showpost.php?p=2751882&postcount=22"
};







capture_area ca;

public void OnPluginStart()
{
	HookEventEx("dod_round_start", dod_round_start, EventHookMode_PostNoCopy);
}

public void dod_round_start(Event event, const char[] name, bool dontBroadcast)
{

	// Hook capture area and store area numcaps
	int entity = -1;
	int x = 0;
	while((entity = FindEntityByClassname(entity, "dod_capture_area")) != -1)
	{
		SDKHookEx(entity, SDKHook_StartTouchPost, StartTouchPost);
		
		ca.m_nAlliesNumCap[x] = GetEntProp(entity, Prop_Data, "m_nAlliesNumCap");
		ca.m_nAxisNumCap[x] 	= GetEntProp(entity, Prop_Data, "m_nAxisNumCap");
		ca.ref[x] = EntIndexToEntRef(entity);
		x++;
		
		if(x >= MAX_CONTROL_POINTS) break;
	}
}

public void StartTouchPost(int entity, int other)
{
	// pass client index only
	if(other < 1 || other > MaxClients) return;

	// check is flag multi cap (by team)
	
	int team = GetClientTeam(other);
	int numcap;
	
	for(int x = 0; x < MAX_CONTROL_POINTS; x++)
	{
		if(EntRefToEntIndex(ca.ref[x]) != entity) continue; // skip
		
		if(team == TEAM_ALLIES)
		{
			numcap = ca.m_nAlliesNumCap[x];
		}
		else if(team == TEAM_AXIS)
		{
			numcap = ca.m_nAxisNumCap[x];
		}

		if(numcap <= 1) return; // no multiple cappers
		
		// flag is multicap. Is there enough players in team ?

		int count;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != team) continue;
			
			count++;
		}
		
		// when not enough players to capture flag
		if(count < numcap)
		{
			if(team == TEAM_ALLIES)
			{
				if(GetEntProp(entity, Prop_Data, "m_nAlliesNumCap") != count)
				{
					SetEntProp(entity, Prop_Data, "m_nAlliesNumCap", count);
					PrintToChatAll("\x01\x04[SM] Because of few players in team, we ease capturing flag.");
				}
			}
			else if(team == TEAM_AXIS)
			{
				if(GetEntProp(entity, Prop_Data, "m_nAxisNumCap") != count)
				{
					SetEntProp(entity, Prop_Data, "m_nAxisNumCap", count);
					PrintToChatAll("\x01\x04[SM] Because of few players in team, we ease capturing flag.");
				}
			}
		}
		else // set back normal
		{
			if(team == TEAM_ALLIES)
			{
				SetEntProp(entity, Prop_Data, "m_nAlliesNumCap", ca.m_nAlliesNumCap[x]);
			}
			else if(team == TEAM_AXIS)
			{
				SetEntProp(entity, Prop_Data, "m_nAxisNumCap", ca.m_nAxisNumCap[x]);
			}
		}
		
		break;
	}
}