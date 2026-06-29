#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("round_start", roundStart);
}

public Action:roundStart(Handle:event, const String:Name[], bool:dontBroadcast)
{
	new Max = GetMaxEntities();
	for(new i = 1; i <= Max; i++)
	{
		if(IsValidEdict(i))
		{
			decl String:name[90];
			GetEdictClassname(i, name, sizeof(name));
			
			if(StrContains(name, "button") != -1)
			{
				HookSingleEntityOutput(i, "OnPressed", Bloquear);
			}
		}
	}
}

public Bloquear(const String:output[], caller, activator, Float:delay)
{
	AcceptEntityInput(caller, "Lock");
	SetEntityRenderColor(caller, 255, 0, 0, 255);
}