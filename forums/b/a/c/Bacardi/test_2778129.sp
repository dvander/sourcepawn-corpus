

enum
{
	noactiondefuse = 0,
	begindefuse,
	abortdefuse,
	defused
}

#include <sdktools>

public void OnPluginStart()
{
	HookEvent("bomb_begindefuse", bomb_begindefuse);
	HookEvent("bomb_abortdefuse", bomb_abortdefuse);
	HookEvent("bomb_defused", bomb_defused);
	HookEvent("round_start", round_start);
}

public void bomb_begindefuse(Event event, const char[] name, bool dontBroadcast)
{
	DataPack data = new DataPack();
	data.WriteCell(begindefuse);
	data.WriteCell(event.GetInt("userid"));
	RequestFrame(DefuseEvents, data);
}
public void bomb_abortdefuse(Event event, const char[] name, bool dontBroadcast)
{
	DataPack data = new DataPack();
	data.WriteCell(abortdefuse);
	data.WriteCell(event.GetInt("userid"));
	RequestFrame(DefuseEvents, data);
}
public void bomb_defused(Event event, const char[] name, bool dontBroadcast)
{
	DataPack data = new DataPack();
	data.WriteCell(defused);
	data.WriteCell(event.GetInt("userid"));
	RequestFrame(DefuseEvents, data);
}
public void round_start(Event event, const char[] name, bool dontBroadcast)
{
	DataPack data = new DataPack();
	data.WriteCell(noactiondefuse);
	data.WriteCell(0);
	RequestFrame(DefuseEvents, data);
}



public void DefuseEvents(DataPack data)
{
	data.Reset();

	int event = data.ReadCell();
	int client = GetClientOfUserId(data.ReadCell());

	delete data;
	
	static float midpoint = 0.0;
	static bool reachedmidpoint = false;


	//PrintToServer("m_iProgressBarDuration %i\nm_flProgressBarStartTime %f",
	//	GetEntProp(client, Prop_Send, "m_iProgressBarDuration"),
	//	GetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime"));

	//PrintToServer("m_flDefuseLength %f\nm_flDefuseCountDown %f",
	//	GetEntPropFloat(entity, Prop_Send, "m_flDefuseLength"),
	//	GetEntPropFloat(entity, Prop_Send, "m_flDefuseCountDown"));


	//PrintToServer("gametime %f\n\n", GetGameTime());

	switch(event)
	{
		case begindefuse:
		{
			// if player have not reach to midpoint, update new midpoint
			if(!reachedmidpoint)
			{
				midpoint = float(GetEntProp(client, Prop_Send, "m_iProgressBarDuration")) / 2.0;
				midpoint = GetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime") + midpoint;
				return;
			}

			int entity = FindEntityByClassname(-1, "planted_c4");

			if(entity == -1)
				return;

			float half = float(GetEntProp(client, Prop_Send, "m_iProgressBarDuration")) / 2.0;
			float halfdefuse = GetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime") - half;
			
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", halfdefuse);
			
			float countdown = GetEntPropFloat(entity, Prop_Send, "m_flDefuseCountDown") - half;
			SetEntPropFloat(entity, Prop_Send, "m_flDefuseCountDown", countdown);

		}
		case abortdefuse:
		{
			if(!reachedmidpoint)
			{
				reachedmidpoint = midpoint <= GetGameTime();
				
				if(reachedmidpoint && client)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
						{
							PrintToChat(i, " \x04[CT] Player %N reached to half defuse!", client);
						}
					}
				}
			}
		}
		default:
		{
			reachedmidpoint = false;
		}
	}
}


