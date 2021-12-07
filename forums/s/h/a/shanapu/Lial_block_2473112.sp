#include <sourcemod>
#include <myjailbreak>
#include <mystocks>
int g_iCollisionOffset;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	g_iCollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public Action Event_RoundStart(Handle event, char [] name, bool dontBroadcast)
{
	if(!IsEventDayRunning())
	{
		LoopValidClients(i, true, true)
		{
			SetEntData(i, g_iCollisionOffset, 5, 4, true);
		}
		SetCvar("mp_solid_teammates", 1);
	}
}